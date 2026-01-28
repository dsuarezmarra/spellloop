extends Node
class_name ItemTestRunner

# Signals
signal test_started(item_name)
signal test_finished(item_name, success, details)
signal all_tests_completed(report_path)

# Dependencies
const ScenarioRunner_Ref = preload("res://scripts/debug/item_validation/ScenarioRunner.gd")
const ReportWriter_Ref = preload("res://scripts/debug/item_validation/ReportWriter.gd")
const NumericOracle_Ref = preload("res://scripts/debug/item_validation/NumericOracle.gd")

const MechanicalOracle_Ref = preload("res://scripts/debug/item_validation/MechanicalOracle.gd")

const FULL_MATRIX_ENABLED = false # Toggle for Phase 4

# Configuration
var max_tests = -1 # -1 for all
var current_test_index = 0
var test_queue = []
var results = []

# Nodes
var report_writer: ReportWriter
var scenario_runner: ScenarioRunner
var numeric_oracle: NumericOracle
var mechanical_oracle: MechanicalOracle
var attack_manager: AttackManager
var player_stats_mock: PlayerStats

# References to Databases
# upgrade_database.gd, weapon_database.gd, weapon_fusion_manager.gd are AutoLoads or Global Classes

func _ready():
	if not OS.is_debug_build():
		queue_free()
		return
		
	report_writer = ReportWriter.new()
	add_child(report_writer)
	
	scenario_runner = ScenarioRunner.new()
	add_child(scenario_runner)
	
	numeric_oracle = NumericOracle.new()
	add_child(numeric_oracle)
	
	mechanical_oracle = MechanicalOracle.new()
	add_child(mechanical_oracle)

func start_suite(categories: Array = [], limit: int = -1):
	print("[ItemTestRunner] Starting Test Suite...")
	# Override limit if Full Matrix is disabled
	if not FULL_MATRIX_ENABLED and limit == -1:
		print("[ItemTestRunner] FULL MATRIX DISABLED. Running PILOT batch only (25 items).")
		max_tests = 25
	else:
		max_tests = limit
		
	results = []
	current_test_index = 0
	
	# Discovery Phase
	var items = _discover_items(categories)
	print("[ItemTestRunner] Discovered %d items." % items.size())
	
	# Build Applicability Matrix & Test Queue
	test_queue = _build_test_queue(items)
	
	if max_tests > 0:
		if test_queue.size() > max_tests:
			test_queue.resize(max_tests)
			
	print("[ItemTestRunner] Scheduled %d tests." % test_queue.size())
	
	# Start Execution
	_run_next_test()

func run_sanity_check():
	print("[ItemTestRunner] Running Sanity Check (5 items)...")
	start_suite([], 5)

func _discover_items(categories: Array) -> Array:
	var items = []
	
	# 1. UPGRADES (Defensive, Utility, Offensive - if exposed)
	if categories.is_empty() or "UPGRADES" in categories:
		if UpgradeDatabase:
			_append_dictionary_items(items, UpgradeDatabase.DEFENSIVE_UPGRADES, "DEFENSIVE")
			_append_dictionary_items(items, UpgradeDatabase.UTILITY_UPGRADES, "UTILITY")
			# Check if conditional/cursed are exposed
			if "CURSED_UPGRADES" in UpgradeDatabase:
				_append_dictionary_items(items, UpgradeDatabase.CURSED_UPGRADES, "CURSED")
	
	# 2. WEAPONS
	if categories.is_empty() or "WEAPONS" in categories:
		if WeaponDatabase:
			_append_dictionary_items(items, WeaponDatabase.WEAPONS, "WEAPON")
	
	# 3. FUSIONS
	if categories.is_empty() or "FUSIONS" in categories:
		if WeaponDatabase:
			_append_dictionary_items(items, WeaponDatabase.FUSIONS, "FUSION")
		
	return items

func _append_dictionary_items(target_list: Array, source_dict: Dictionary, type: String):
	for key in source_dict:
		var item = source_dict[key].duplicate(true)
		if not "id" in item: item["id"] = key
		item["_type"] = type
		target_list.append(item)

func _build_test_queue(items: Array) -> Array:
	var queue = []
	for item in items:
		# APPLICABILITY MATRIX LOGIC
		
		# Define standard test weapons to verify against
		var _test_weapons = ["ice_wand"] # Default
		
		# Specialized testing based on item type
		if item["_type"] == "WEAPON" or item["_type"] == "FUSION":
			# Test the weapon itself
			queue.append({
				"item": item,
				"target_weapon": item["id"],
				"is_self_test": true,
				"scenario": "mechanical_verification"
			})
		else:
			# It's an upgrade. Test applicability.
			# For now, we test against a standard weapon to verify stats.
			queue.append({
				"item": item,
				"target_weapon": "ice_wand", # Can be expanded to test against multiple types
				"is_self_test": false,
				"scenario": "numeric_verification"
			})
			
	return queue

func _run_next_test():
	if current_test_index >= test_queue.size():
		_finish_suite()
		return
		
	var test_case = test_queue[current_test_index]
	current_test_index += 1
	
	var item_id = test_case["item"]["id"]
	test_started.emit(item_id)
	
	# 1. SETUP Environment
	var env = scenario_runner.setup_environment()
	attack_manager = env.get_node("AttackManager")
	player_stats_mock = env.get_node("PlayerStats")
	var mock_player = env.get_node("MockPlayer")
	
	# Initialize Managers
	if attack_manager.has_method("initialize"):
		attack_manager.initialize(mock_player)
		
	# Setup Mechanical Oracle
	if mechanical_oracle:
		mechanical_oracle.start_listening()
	
	var classification = _classify_item(test_case["item"])
	test_case["scope"] = classification
	
	# === SCOPE-BASED EXECUTION ===
	var success = true
	var failures = []
	var subtests = []
	
	# WEAPON / FUSION SCOPE
	if classification in ["WEAPON_SPECIFIC", "GLOBAL_WEAPON", "FUSION_SPECIFIC"]:
		# Add weapon
		var weapon_id = test_case["target_weapon"]
		attack_manager.add_weapon_by_id(weapon_id)
		var weapon = attack_manager.get_weapon_by_id(weapon_id)
		
		# Baseline
		var post_add_stats = attack_manager.get_weapon_full_stats(weapon)
		
		# Apply Item (if not self-test)
		if not test_case.get("is_self_test", false):
			if classification == "GLOBAL_WEAPON":
				attack_manager.apply_global_upgrade(test_case["item"])
			elif classification == "WEAPON_SPECIFIC":
				attack_manager.apply_weapon_upgrade(weapon_id, test_case["item"])
		
		# Get Expected Stats
		var final_stats = attack_manager.get_weapon_full_stats(weapon)
		var expected_damage = final_stats.get("damage_final", 10.0)
		
		# Spawn Dummy
		var dummy = scenario_runner.spawn_dummy_enemy(Vector2(100, 0)) # Right in front
		mechanical_oracle.track_enemy(dummy)
		
		# FIRE!
		if weapon.has_method("perform_attack"):
			weapon.perform_attack(mock_player, player_stats_mock) # Fire once
		
		# Wait for projectile travel/impact
		await get_tree().create_timer(0.5).timeout
		
		# VERIFY (Mechanical)
		var mech_res = mechanical_oracle.verify_damage_event(expected_damage, 0.05) # 5% tolerance
		if not mech_res["passed"]:
			success = false
			var fail_msg = mech_res["reason"]
			failures.append(fail_msg)
			
		subtests.append({
			"type": "mechanical_damage", 
			"res": mech_res,
			"details": {
				"baseline_damage_expected": expected_damage,
				"mechanical_damage_actual": mech_res.get("actual", 0.0),
				"delta_percent": mech_res.get("delta_percent", 0.0),
				"weapon_id": weapon_id,
				"projectile_type": weapon.get("projectile_type") if "projectile_type" in weapon else "UNKNOWN", 
				"divergence_hint": "Check AttackManager calc vs Projectile damage init" if not success else "None"
			}
		})
		
		# Detailed Report Entry
		result_data["expected_damage"] = expected_damage
		result_data["actual_damage"] = mech_res.get("actual", 0.0)
		result_data["weapon_id"] = weapon_id

	# PLAYER SCOPE
	elif classification == "PLAYER_ONLY":
		# Apply upgrade
		# In real game, LevelUpPanel applies this to PlayerStats directly or via managers.
		# Here we assume PlayerStats (mock) has keys or we use a helper.
		# Since PlayerStats.gd is complex, we might skip full player mechanical verif for Pilot 
		# and just stick to Numeric if no easy way to mock damage taken.
		# For Pilot: Just verify Numeric on PlayerStats dictionary if possible.
		pass
		
	# UNKNOWN / INVALID
	else:
		pass # Skip or flag

	# Record Result
	var result_data = {
		"item_id": item_id,
		"scope": classification,
		"success": success,
		"failures": failures,
		"subtests": subtests
	}
	
	scenario_runner.teardown_environment()
	results.append(result_data)
	test_finished.emit(item_id, success, str(failures))
	
	await get_tree().create_timer(0.01).timeout
	_run_next_test()

func _classify_item(item: Dictionary) -> String:
	# Simple classification based on item keys/effects
	if item.get("_type") == "WEAPON": return "WEAPON_SPECIFIC"
	if item.get("_type") == "FUSION": return "FUSION_SPECIFIC"
	if item.get("category") == "defensive": return "PLAYER_ONLY"
	# Heuristic for global weapon
	var effects = item.get("effects", [])
	for eff in effects:
		var stat = eff.get("stat", "")
		if stat in ["damage_mult", "area_mult", "cooldown_mult"]:
			return "GLOBAL_WEAPON"
	return "PLAYER_ONLY" # Default fallback

func _record_failure(test_case, reason):
	results.append({
		"item_id": test_case["item"]["id"],
		"success": false,
		"failures": [reason]
	})

func _finish_suite():
	print("[ItemTestRunner] Suite Finished. Generating Report...")
	var path = report_writer.generate_report(results)
	all_tests_completed.emit(path)
	print("[ItemTestRunner] Report saved to: %s" % path)

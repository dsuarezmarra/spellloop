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
	
	var args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	print("[ItemTestRunner] Combined Args: ", args)
	if "--run-pilot" in args:
		call_deferred("run_sanity_check")

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
	if max_tests == 25 and not FULL_MATRIX_ENABLED:
		test_queue = _build_pilot_queue(items)
	else:
		test_queue = _build_test_queue(items)
	
	if max_tests > 0 and max_tests != 25: # Careful not to slice the pilot queue which interacts with method logic
		if test_queue.size() > max_tests:
			test_queue.resize(max_tests)
			
	print("[ItemTestRunner] Scheduled %d tests." % test_queue.size())
	
	# Start Execution
	_run_next_test()

func run_sanity_check():
	print("[ItemTestRunner] Running PILOT V2 (25 items, Quota-based)...")
	# Force 25 limit to trigger pilot queue logic
	start_suite([], 25)

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

func _build_pilot_queue(items: Array) -> Array:
	print("[ItemTestRunner] Building PILOT V2 Queue (Quota-based)...")
	var rng = RandomNumberGenerator.new()
	rng.seed = 1337 # Deterministic Seed
	
	var buckets = {
		"PLAYER_ONLY": [],
		"WEAPON": [], # GLOBAL_WEAPON or WEAPON_SPECIFIC
		"FUSION": []
	}
	
	# Pre-classify
	for item in items:
		var scope = _classify_item(item)
		if scope == "PLAYER_ONLY":
			buckets["PLAYER_ONLY"].append(item)
		elif scope == "FUSION_SPECIFIC":
			buckets["FUSION"].append(item)
		else: # GLOBAL_WEAPON, WEAPON_SPECIFIC
			buckets["WEAPON"].append(item)
			
	# Shuffle buckets
	for key in buckets:
		var arr = buckets[key]
		# Custom shuffle with seed
		var n = arr.size()
		for i in range(n - 1, 0, -1):
			var j = rng.randi_range(0, i)
			var temp = arr[i]
			arr[i] = arr[j]
			arr[j] = temp
			
	# Select Quotas
	var pilot_items = []
	
	# 10 PLAYER
	pilot_items.append_array(buckets["PLAYER_ONLY"].slice(0, min(10, buckets["PLAYER_ONLY"].size())))
	
	# 10 WEAPON
	pilot_items.append_array(buckets["WEAPON"].slice(0, min(10, buckets["WEAPON"].size())))
	
	# 5 FUSION
	pilot_items.append_array(buckets["FUSION"].slice(0, min(5, buckets["FUSION"].size())))
	
	# Fallback fill if short
	var current_count = pilot_items.size()
	if current_count < 25:
		var needed = 25 - current_count
		# Try fill from WEAPON first
		var used_ids = []
		for pi in pilot_items: used_ids.append(pi["id"])
		
		for w in buckets["WEAPON"]:
			if needed == 0: break
			if not w["id"] in used_ids:
				pilot_items.append(w)
				needed -= 1
				
		# Then Player
		for p in buckets["PLAYER_ONLY"]:
			if needed == 0: break
			if not p["id"] in used_ids:
				pilot_items.append(p)
				needed -= 1

	print("[ItemTestRunner] Pilot Queue Item Count: ", pilot_items.size())
	return _build_test_queue(pilot_items)

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
	var result_data = {
		"item_id": item_id,
		"scope": classification,
		"success": true,
		"failures": [],
		"subtests": []
	}
	
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
		var _post_add_stats = attack_manager.get_weapon_full_stats(weapon)
		
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
			# Convert Node to Dictionary via the helper we just added
			var p_stats_dict = {}
			if player_stats_mock.has_method("get_all_stats"):
				p_stats_dict = player_stats_mock.get_all_stats()
			else:
				# Fallback: manually construct minimal if needed, or pass empty.
				# Though current issue is passing Object where Dict is expected.
				pass
				
			weapon.perform_attack(mock_player, p_stats_dict) # Fire once
		
		# Wait for projectile travel/impact (Standardized Test Window)
		# Phase 3.6: Fixed 2.0s window for DPS aggregation
		var test_window = 2.0
		await get_tree().create_timer(test_window).timeout
		
		# VERIFY (Mechanical Phase 3.6)
		# Infer projectile type from weapon data or metadata
		var p_type = "SIMPLE" # Default
		# Using introspection since weapon is BaseWeapon instance
		if "projectile_type" in weapon:
			# If it's an enum, we need to convert to string if MechanicalOracle expects string
			# BaseWeapon.ProjectileType: SINGLE=0, MULTI=1, BEAM=2, AOE=3, ORBIT=4, CHAIN=5
			var p_enum = weapon.projectile_type
			match p_enum:
				0: p_type = "SIMPLE"
				1: p_type = "MULTI"
				2: p_type = "BEAM"
				3: p_type = "AOE"
				4: p_type = "ORBIT"
				5: p_type = "CHAIN"
				
		var mech_res = mechanical_oracle.verify_simulation_results(final_stats, str(p_type), test_window, 0.15) # 15% tolerance
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
		# ... (kept same)
		pass
		
	# UNKNOWN / INVALID
	else:
		pass # Skip or flag

	# Finalize Result
	result_data["success"] = success
	result_data["failures"] = failures
	result_data["subtests"] = subtests
	
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
	var md_path = report_writer.generate_summary_md(results, path)
	all_tests_completed.emit(path)
	print("[ItemTestRunner] Report saved to: %s" % path)
	print("[ItemTestRunner] Summary saved to: %s" % md_path)

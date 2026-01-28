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

# Configuration
var max_tests = -1 # -1 for all
var current_test_index = 0
var test_queue = []
var results = []

# Nodes
var report_writer: ReportWriter
var scenario_runner: ScenarioRunner
var numeric_oracle: NumericOracle
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

func start_suite(categories: Array = [], limit: int = -1):
	print("[ItemTestRunner] Starting Test Suite...")
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
	
	# Link PlayerStats
	if player_stats_mock.has_method("initialize"):
		# PlayerStats doesn't seem to have initialize in the file I read, 
		# but it does have player_ref variable.
		player_stats_mock.player_ref = mock_player
		player_stats_mock.attack_manager = attack_manager
		
	# Link AttackManager to PlayerStats (legacy way if needed)
	if attack_manager.has_method("set_player_stats"): # Check if exists
		pass
	
	# 2. ADD WEAPON
	var weapon_id = test_case["target_weapon"]
	attack_manager.add_weapon_by_id(weapon_id)
	var weapon = attack_manager.get_weapon_by_id(weapon_id)
	
	if not weapon:
		_record_failure(test_case, "Failed to add weapon: %s" % weapon_id)
		_run_next_test()
		return

	# 3. BASELINE Stats
	var baseline_stats = attack_manager.get_weapon_full_stats(weapon)
	
	# 4. APPLY Item
	var item = test_case["item"]
	if test_case["is_self_test"]:
		# For weapons, we just verify they exist and have stats, effectively done by add_weapon
		pass 
	else:
		# Apply upgrade
		if item["_type"] in ["DEFENSIVE", "UTILITY", "CURSED"]:
			# These typically go to PlayerStats or GlobalWeaponStats
			# AttackManager methods handle global upgrades
			attack_manager.apply_global_upgrade(item)
			
	# 5. ACTUAL Stats
	var after_stats = attack_manager.get_weapon_full_stats(weapon)
	
	# 6. VERIFY Numeric
	var result_data = {
		"item_id": item_id,
		"target": weapon_id,
		"success": true,
		"failures": [],
		"subtests": []
	}
	
	if not test_case["is_self_test"]:
		var oracle_res = numeric_oracle.verify_changes(item, baseline_stats, after_stats, "WEAPON")
		if not oracle_res["passed"]:
			result_data["success"] = false
			result_data["failures"] = oracle_res["failures"]
		result_data["subtests"] = oracle_res["subtests"]
	
	# 7. VERIFY Mechanical (If passed numeric or is self-test)
	if result_data["success"]:
		# TODO: Run Scenario for X seconds
		pass
		
	# TEARDOWN is handled by ScenarioRunner ref or next setup
	scenario_runner.teardown_environment()
	
	results.append(result_data)
	test_finished.emit(item_id, result_data["success"], str(result_data.get("failures", [])))
	
	# Delay
	await get_tree().create_timer(0.01).timeout
	_run_next_test()

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

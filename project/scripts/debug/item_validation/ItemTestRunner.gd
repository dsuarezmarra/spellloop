extends Node
class_name ItemTestRunner

# Signals
signal test_started(item_name)
signal test_finished(item_name, success, details)
signal all_tests_completed(report_path)

# Dependencies
const ScenarioRunner_Ref = preload("res://scripts/debug/item_validation/ScenarioRunner.gd")
const ReportWriter_Ref = preload("res://scripts/debug/item_validation/ReportWriter.gd")

# Configuration
var max_tests = -1 # -1 for all
var current_test_index = 0
var test_queue = []
var results = []

# Nodes
var report_writer: ReportWriter
var scenario_runner: ScenarioRunner

func _ready():
	if not OS.is_debug_build():
		queue_free()
		return
		
	report_writer = ReportWriter.new()
	add_child(report_writer)
	
	scenario_runner = ScenarioRunner.new()
	add_child(scenario_runner)

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

func _discover_items(categories: Array) -> Array:
	var items = []
	
	# UpgradeDatabase
	# Accessing static constants directly from the script class, assuming they are accessible.
	# Godot 4 static access: ClassName.CONSTANT
	
	if categories.is_empty() or "UPGRADES" in categories:
		_append_dictionary_items(items, UpgradeDatabase.DEFENSIVE_UPGRADES, "DEFENSIVE")
		_append_dictionary_items(items, UpgradeDatabase.UTILITY_UPGRADES, "UTILITY")
		_append_dictionary_items(items, UpgradeDatabase.OFFENSIVE_UPGRADES, "OFFENSIVE")
		
	if categories.is_empty() or "WEAPONS" in categories:
		_append_dictionary_items(items, WeaponDatabase.WEAPONS, "WEAPON")
		
	if categories.is_empty() or "FUSIONS" in categories:
		_append_dictionary_items(items, WeaponDatabase.FUSIONS, "FUSION")
		
	return items

func _append_dictionary_items(target_list: Array, source_dict: Dictionary, type: String):
	for key in source_dict:
		var item = source_dict[key].duplicate()
		# Ensure ID exists
		if not "id" in item:
			item["id"] = key
		item["_test_source_type"] = type
		target_list.append(item)

func _build_test_queue(items: Array) -> Array:
	var queue = []
	for item in items:
		# Basic applicability logic
		# For now, we just create a generic test case for each item
		# Later this will be smarter (matrix)
		
		var test_case = {
			"item": item,
			"target_weapon": "ice_wand", # Default test weapon
			"scenario": "basic_dps"
		}
		
		# Specific logic for WEAPON/FUSION to test their own projectiles
		if item["_test_source_type"] in ["WEAPON", "FUSION"]:
			test_case["target_weapon"] = item["id"]
			test_case["is_weapon_test"] = true
			
		queue.append(test_case)
	return queue

func _run_next_test():
	if current_test_index >= test_queue.size():
		_finish_suite()
		return
		
	var test_case = test_queue[current_test_index]
	current_test_index += 1
	
	test_started.emit(test_case["item"]["id"])
	
	# Execute Test
	# Logic to run scenario
	scenario_runner.run_scenario(test_case, _on_scenario_completed)

func _on_scenario_completed(result: Dictionary):
	results.append(result)
	test_finished.emit(result["item_id"], result["success"], result["details"])
	
	# Little delay to not freeze UI
	await get_tree().create_timer(0.05).timeout
	_run_next_test()

func _finish_suite():
	print("[ItemTestRunner] Suite Finished. Generating Report...")
	var path = report_writer.generate_report(results)
	all_tests_completed.emit(path)
	print("[ItemTestRunner] Report saved to: %s" % path)

func run_sanity_check():
	print("[ItemTestRunner] Running Sanity Check (5 items)...")
	results = []
	current_test_index = 0
	test_queue = []
	
	# Manually select 5 items covering different types
	var targets = ["ice_wand", "wind_blade", "light_beam", "earth_spike", "arcane_orb"]
	
	for id in targets:
		# Fetch from WeaponDatabase
		if WeaponDatabase.WEAPONS.has(id):
			var item = WeaponDatabase.WEAPONS[id].duplicate()
			# Ensure ID
			if not "id" in item: item["id"] = id
			item["_test_source_type"] = "WEAPON"
			
			test_queue.append({
				"item": item,
				"target_weapon": id,
				"is_weapon_test": true,
				"scenario": "sanity_check"
			})
	
	print("[ItemTestRunner] Scheduled %d sanity tests." % test_queue.size())
	_run_next_test()

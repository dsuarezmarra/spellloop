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

const FULL_MATRIX_ENABLED = true # Toggle for Phase 4

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

# Metadata for Reporting
var empty_reason: String = ""
var start_time_ms: int = 0
var is_measure_mode: bool = false
var git_commit: String = "unknown"
var test_seed: int = 1337

# References to Databases
# upgrade_database.gd, weapon_database.gd, weapon_fusion_manager.gd are AutoLoads or Global Classes

func _ready():
	print("[ItemTestRunner] _ready reached.")
	var hb = FileAccess.open("ready_check.txt", FileAccess.WRITE)
	hb.store_string("READY AT " + Time.get_datetime_string_from_system())
	hb.close()
	
	report_writer = ReportWriter_Ref.new()
	add_child(report_writer)
	
	scenario_runner = ScenarioRunner_Ref.new()
	add_child(scenario_runner)
	
	numeric_oracle = NumericOracle_Ref.new()
	add_child(numeric_oracle)
	
	mechanical_oracle = MechanicalOracle_Ref.new()
	add_child(mechanical_oracle)
	
	var args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	print("[ItemTestRunner] Args: ", args)
	
	if "--measure-only" in args:
		is_measure_mode = true
		print("[ItemTestRunner] MEASURE mode enabled.")
		
	# Try to get git commit
	var commit_output = []
	var err = OS.execute("git", ["rev-parse", "--short", "HEAD"], commit_output)
	if err == 0 and commit_output.size() > 0:
		git_commit = commit_output[0].strip_edges()
	if "--run-pilot" in args:
		print("[ItemTestRunner] Pilot mode detected.")
		call_deferred("run_sanity_check")
	elif "--run-full" in args:
		print("[ItemTestRunner] Full Matrix mode detected.")
		var batch_size = -1
		var offset = 0
		for arg in args:
			if arg.begins_with("--batch-size="):
				batch_size = arg.split("=")[1].to_int()
			if arg.begins_with("--offset="):
				offset = arg.split("=")[1].to_int()
		call_deferred("start_suite", [], batch_size, offset)

func start_suite(categories: Array = [], limit: int = -1, offset: int = 0):
	run_id = "run_" + str(str(Time.get_unix_time_from_system()).hash())
	start_time_ms = Time.get_ticks_msec()
	print("[ItemTestRunner] Starting Test Suite %s (Batch Size: %d, Offset: %d)..." % [run_id, limit, offset])
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
	discovery_count = items.size()
	print("[ItemTestRunner] Discovered %d items." % discovery_count)
	
	if discovery_count == 0:
		empty_reason = "No items discovered in categories: %s" % str(categories)
		print("[ItemTestRunner] ERROR: %s" % empty_reason)
		_finish_suite()
		return
	
	# Build Applicability Matrix & Test Queue
	if max_tests == 25 and not FULL_MATRIX_ENABLED:
		test_queue = _build_pilot_queue(items)
	else:
		test_queue = _build_test_queue(items)
	
	# 3. Batching Logic
	if offset > 0:
		if offset < test_queue.size():
			test_queue = test_queue.slice(offset)
		else:
			test_queue = []
			
	if limit > 0:
		if test_queue.size() > limit:
			test_queue.resize(limit)
			
	scheduled_count = test_queue.size()
	if scheduled_count == 0:
		empty_reason = "Scheduled tests count is 0 (offset %d, limit %d, total items %d)" % [offset, limit, discovery_count]
		print("[ItemTestRunner] ERROR: %s" % empty_reason)
		_finish_suite()
		return
		
	print("[ItemTestRunner] Scheduled %d tests (starting from offset %d)." % [scheduled_count, offset])
	
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
		mechanical_oracle.is_measure_mode = is_measure_mode
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
	
	# Phase 5: 3x execution for median (Noise Control)
	var iteration_results = []
	for i in range(3):
		var iter_res = await _execute_test_iteration(test_case, env, classification)
		iteration_results.append(iter_res)
		# Reset between iterations
		mechanical_oracle.start_listening()
	
	# Select Median based on actual_damage
	iteration_results.sort_custom(func(a, b): return a["actual_damage"] < b["actual_damage"])
	var final_iter_res = iteration_results[1] # Index 1 is median of 3
	
	# Finalize Result
	result_data["success"] = final_iter_res["success"]
	result_data["failures"] = final_iter_res["failures"]
	result_data["subtests"] = final_iter_res["subtests"]
	result_data["expected_damage"] = final_iter_res["expected_damage"]
	result_data["actual_damage"] = final_iter_res["actual_damage"]
	result_data["weapon_id"] = final_iter_res.get("weapon_id", "")
	if is_measure_mode and "measurements" in final_iter_res:
		result_data["measurements"] = final_iter_res["measurements"]
	
	scenario_runner.teardown_environment()
	results.append(result_data)
	test_finished.emit(item_id, result_data["success"], str(result_data["failures"]))
	
	await get_tree().create_timer(0.01).timeout
	_run_next_test()

func _execute_test_iteration(test_case: Dictionary, env: Node, classification: String) -> Dictionary:
	var mock_player = env.get_node("MockPlayer")
	var item_id = test_case["item"]["id"]
	var iter_result = {
		"success": true,
		"failures": [],
		"subtests": [],
		"actual_damage": 0.0,
		"expected_damage": 0.0
	}
	
	# Clean any previous dummies
	for dummy in get_tree().get_nodes_in_group("test_dummy"):
		dummy.queue_free()
	await get_tree().process_frame
	
	# WEAPON / FUSION SCOPE
	if classification in ["WEAPON_SPECIFIC", "GLOBAL_WEAPON", "FUSION_SPECIFIC"]:
		var weapon_id = test_case["target_weapon"]
		var weapon = attack_manager.get_weapon_by_id(weapon_id)
		if not weapon: # Re-add if missing
			attack_manager.add_weapon_by_id(weapon_id)
			weapon = attack_manager.get_weapon_by_id(weapon_id)
			
		var final_stats = attack_manager.get_weapon_full_stats(weapon)
		var expected_damage = final_stats.get("damage_final", 10.0)
		var weapon_range = final_stats.get("range", 100.0)
		
		# Infer projectile type
		var p_type = "SIMPLE" 
		if "projectile_type" in weapon:
			match int(weapon.projectile_type):
				0: p_type = "SIMPLE"
				1: p_type = "MULTI"
				2: p_type = "BEAM"
				3: p_type = "AOE"
				4: p_type = "ORBIT"
				5: p_type = "CHAIN"
		
		# Spawn Dummies
		if p_type == "CHAIN":
			# Spawn 3 dummies to measure bounces
			for d_idx in range(3):
				var pos = Vector2(100 + (d_idx * 50), 0)
				var dummy = scenario_runner.spawn_dummy_enemy(pos)
				mechanical_oracle.track_enemy(dummy)
		elif p_type == "AOE":
			# Spawn 2 dummies in AOE area
			var dummy1 = scenario_runner.spawn_dummy_enemy(Vector2(50, 0))
			var dummy2 = scenario_runner.spawn_dummy_enemy(Vector2(-50, 0))
			mechanical_oracle.track_enemy(dummy1)
			mechanical_oracle.track_enemy(dummy2)
		else:
			var spawn_pos = Vector2(100, 0)
			if p_type == "ORBIT": spawn_pos = Vector2(weapon_range, 0)
			var dummy = scenario_runner.spawn_dummy_enemy(spawn_pos)
			mechanical_oracle.track_enemy(dummy)
		
		# FIRE!
		if weapon.has_method("perform_attack"):
			var p_stats_dict = player_stats_mock.get_all_stats() if player_stats_mock.has_method("get_all_stats") else {}
			weapon.perform_attack(mock_player, p_stats_dict)
		
		var test_window = 2.0
		await get_tree().create_timer(test_window).timeout
		
		var mech_res = mechanical_oracle.verify_simulation_results(final_stats, str(p_type), test_window, 0.15)
		
		iter_result["success"] = (mech_res.get("result_code", "PASS") != "BUG")
		if not mech_res["passed"]:
			iter_result["failures"].append(mech_res["reason"])
			
		iter_result["subtests"].append({"type": "mechanical_damage", "res": mech_res})
		iter_result["expected_damage"] = mech_res.get("expected", 0.0)
		iter_result["actual_damage"] = mech_res.get("actual", 0.0)
		iter_result["weapon_id"] = weapon_id
		if "measurements" in mech_res:
			iter_result["measurements"] = mech_res["measurements"]

	return iter_result

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
	print("[ItemTestRunner] Suite Finished. Checking for results...")
	
	if results.is_empty():
		var reason = empty_reason if empty_reason != "" else "No tests were executed (stopped early or crashed)."
		print("[ItemTestRunner] ERROR: %s - Skipping report generation." % reason)
		get_tree().quit()
		return

	var duration = Time.get_ticks_msec() - start_time_ms
	var metadata = {
		"run_id": run_id,
		"started_at": Time.get_datetime_string_from_system(),
		"git_commit": git_commit,
		"duration_ms": duration,
		"test_seed": test_seed,
		"is_measure_mode": is_measure_mode,
		"FULL_MATRIX_ENABLED": FULL_MATRIX_ENABLED,
		"batch_index": current_test_index - results.size(), # Approximate offset
		"batch_size": max_tests,
		"discovered_items_count": discovery_count,
		"scheduled_tests_count": scheduled_count,
		"empty_reason": empty_reason
	}

	print("[ItemTestRunner] Generating Report for %d results..." % results.size())
	var path = report_writer.generate_report(results, metadata)
	var md_path = report_writer.generate_summary_md(results, path, metadata)
	all_tests_completed.emit(path)
	print("[ItemTestRunner] Report saved to: %s" % path)
	print("[ItemTestRunner] Summary saved to: %s" % md_path)
	
	# Always quit when finished in batch mode
	get_tree().quit()

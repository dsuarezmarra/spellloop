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
# Changed to var for robust loading
var StatusEffectOracle_Ref 

const MechanicalOracle_Ref = preload("res://scripts/debug/item_validation/MechanicalOracle.gd")
const ContractOracle_Ref = preload("res://scripts/debug/item_validation/ContractOracle.gd")
const SideEffectDetector_Ref = preload("res://scripts/debug/item_validation/SideEffectDetector.gd")

const FULL_MATRIX_ENABLED = true # Toggle for Phase 4

# Configuration
var max_tests = -1 # -1 for all
var current_test_index = 0
var test_queue = []
var results = []
var _exiting: bool = false  # Flag to prevent new operations during exit

# Nodes
var report_writer: ReportWriter
var scenario_runner: ScenarioRunner
var numeric_oracle: NumericOracle
var mechanical_oracle: MechanicalOracle
var status_oracle: StatusEffectOracle
var contract_oracle: ContractOracle
var side_effect_detector: SideEffectDetector
var attack_manager: AttackManager
var player_stats_mock: PlayerStats

# Contract Validation Mode
var strict_contract_mode: bool = true  # Enable strict contract validation

# ═══════════════════════════════════════════════════════════════════════════════
# RNG DETERMINISTA - Task 3
# ═══════════════════════════════════════════════════════════════════════════════
var deterministic_seed: bool = true  # When true, force fixed seed for reproducibility
var test_seed: int = 1337  # Seed used when deterministic_seed=true

# ═══════════════════════════════════════════════════════════════════════════════
# SIMULACIÓN DE EVENTOS - Task 2
# ═══════════════════════════════════════════════════════════════════════════════
var event_simulation_enabled: bool = true  # Enable event simulation for on_hit, on_kill, etc.
var simulated_hits: int = 10  # Number of on_hit events to simulate
var simulated_kills: int = 5  # Number of on_kill events to simulate
var simulated_time_seconds: float = 60.0  # Time to simulate for per_minute effects
var simulated_pickups: int = 3  # Number of on_pickup events to simulate

# Items that require specific events to test properly
# Key = item_id, Value = array of required events
var _event_requirements: Dictionary = {}

# ═══════════════════════════════════════════════════════════════════════════════
# DEBUG INSTRUMENTATION - Verifies harness fixes are working
# ═══════════════════════════════════════════════════════════════════════════════
var DEBUG_HARNESS_FIX: bool = false  # Set to true to enable verbose fix verification logs
var _debug_attack_mgr_fires_during_test: int = 0  # Counter for any fires during disabled window
var _debug_tracked_enemies_at_clear: int = 0  # Number of enemies being disconnected

# ═══════════════════════════════════════════════════════════════════════════════
# QA PHYSICS & SIMULATION CONFIG (T1-T3)
# ═══════════════════════════════════════════════════════════════════════════════
var USE_PHYSICS_FRAMES: bool = true  # T2: Use physics_frame instead of Timer for test window
var QA_SIMULATE_DAMAGE: bool = false  # T3: Fallback mode that bypasses physics collision
var DEBUG_PHYSICS: bool = false  # T1: Log physics frame count and collision diagnostics
var PHYSICS_FPS: int = 60  # Assumed physics tick rate for frame calculation

# Metadata for Reporting
var empty_reason: String = ""
var start_time_ms: int = 0
var is_measure_mode: bool = false
var git_commit: String = "unknown"
var run_id: String = ""
var discovery_count: int = 0
var scheduled_count: int = 0

# References to Databases
# upgrade_database.gd, weapon_database.gd, weapon_fusion_manager.gd are AutoLoads or Global Classes

func _ready():
	print("[ItemTestRunner] _ready reached.")
	
	# Robust Load of StatusEffectOracle
	StatusEffectOracle_Ref = load("res://scripts/debug/item_validation/StatusEffectOracle.gd")
	if not StatusEffectOracle_Ref:
		push_error("[ItemTestRunner] CRITICAL: Failed to load StatusEffectOracle.gd")
		var writer = ReportWriter_Ref.new()
		add_child(writer) # Need to add child to use? No, static helper usually, but let's see implementation.
		# Actually ReportWriter methods are instance methods in the current context.
		var fail_res = [{
			"item_id": "CRITICAL_FAILURE",
			"success": false,
			"failures": ["StatusEffectOracle.gd failed to load (Parse Error or Missing File)"],
			"subtests": []
		}]
		writer.generate_report(fail_res, {"error": "script_load_failure"})
		writer.generate_summary_md(fail_res, "user://test_reports/FATAL_ERROR.jsonl", {"error": "script_load_failure"})
		get_tree().quit(1)
		return

	seed(test_seed) # Task 3: Deterministic RNG (configurable via deterministic_seed flag)
	if deterministic_seed:
		print("[ItemTestRunner] Deterministic RNG enabled with seed: %d" % test_seed)
	else:
		# Use random seed based on time
		var random_seed = Time.get_ticks_usec()
		seed(random_seed)
		test_seed = random_seed
		print("[ItemTestRunner] Random RNG enabled with seed: %d" % test_seed)
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
    
	status_oracle = StatusEffectOracle_Ref.new()
	add_child(status_oracle)
	
	contract_oracle = ContractOracle_Ref.new()
	add_child(contract_oracle)
	
	side_effect_detector = SideEffectDetector_Ref.new()
	add_child(side_effect_detector)
	
	var args = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	print("[ItemTestRunner] Args: ", args)
	
	# ═══════════════════════════════════════════════════════════════════════════
	# INTEGRITY CHECK
	# ═══════════════════════════════════════════════════════════════════════════
	print("[ItemTestRunner] Running Structure Integrity Check...")
	var validation_result = StructureValidator.validate_integrity()
	if not validation_result.passed:
		print("[ItemTestRunner] FATAL: Integrity violation detected!")
		for err in validation_result.errors:
			print(err)
		# Force exit with error code
		print("Exiting due to integrity violations.")
		get_tree().quit(1)
		return
	print("[ItemTestRunner] Integrity check passed. (%d items, %d unique IDs)" % [
		validation_result.stats.total_items, validation_result.stats.unique_ids
	])
	
	if "--measure-only" in args:
		is_measure_mode = true
		print("[ItemTestRunner] MEASURE mode enabled.")
		
	# Try to get git commit
	var commit_output = []
	var err = OS.execute("git", ["rev-parse", "--short", "HEAD"], commit_output)
	if err == 0 and commit_output.size() > 0:
		git_commit = commit_output[0].strip_edges()
	var is_scope_run = false
	var scope_filter_arg = ""
	
	for arg in args:
		if arg == "--run-scope":
			is_scope_run = true
		elif arg.begins_with("--run-scope="):
			is_scope_run = true
			scope_filter_arg = arg.split("=")[1]
		elif arg.begins_with("--scope="):
			scope_filter_arg = arg.split("=")[1]

	if "--run-pilot" in args:
		print("[ItemTestRunner] Pilot mode detected.")
		call_deferred("run_sanity_check")
	elif "--run-status-pilot" in args:
		call_deferred("run_status_pilot")
	elif "--run-full-cycle" in args:
		print("[ItemTestRunner] FULL CYCLE mode detected - Testing ALL items by scope.")
		call_deferred("run_full_cycle")
	elif is_scope_run:
		print("[ItemTestRunner] Scope-filtered mode: %s" % scope_filter_arg)
		call_deferred("run_by_scope", scope_filter_arg)
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

func run_status_pilot():
	print("[ItemTestRunner] Running STATUS Verification Pilot...")
	var target_ids = [
		"fire_wand", "ice_wand", "lightning_wand", "arcane_orb", 
		"light_beam", "wind_blade", "earth_spike", "nature_staff", 
		"shadow_dagger", "void_pulse"
	]
	
	var items = []
	# Find these items in WeaponDatabase
	for id in target_ids:
		if id in WeaponDatabase.WEAPONS:
			var item = WeaponDatabase.WEAPONS[id].duplicate(true)
			item["_type"] = "WEAPON"
			items.append(item)
		else:
			print("WARNING: Item %s not found in WeaponDatabase!" % id)
			
	test_queue = _build_test_queue(items)
	run_id = "status_pilot_" + str(Time.get_unix_time_from_system())
	start_time_ms = Time.get_ticks_msec()
	scheduled_count = test_queue.size()
	results = []
	current_test_index = 0
	
	print("[ItemTestRunner] Scheduled %d status verification tests." % scheduled_count)
	_run_next_test()

## ================== FULL CYCLE MODE ==================
## Runs ALL items organized by scope for comprehensive validation

func run_full_cycle():
	"""
	Execute a complete test cycle of all 143+ items organized by scope.
	Generates a comprehensive report showing which items work/fail per category.
	"""
	run_id = "full_cycle_" + str(str(Time.get_unix_time_from_system()).hash())
	start_time_ms = Time.get_ticks_msec()
	results = []
	current_test_index = 0
	
	# Discover ALL items
	var all_items = _discover_items([])
	discovery_count = all_items.size()
	print("[ItemTestRunner] FULL CYCLE: Discovered %d total items." % discovery_count)
	
	# Classify and organize by scope
	var scope_buckets = {
		"PLAYER_ONLY": [],
		"GLOBAL_WEAPON": [],
		"WEAPON_SPECIFIC": [],
		"FUSION_SPECIFIC": []
	}
	
	for item in all_items:
		var scope = _classify_item(item)
		if scope in scope_buckets:
			scope_buckets[scope].append(item)
		else:
			scope_buckets["PLAYER_ONLY"].append(item)
	
	# Print scope breakdown
	print("[ItemTestRunner] === SCOPE BREAKDOWN ===")
	for scope in scope_buckets:
		print("  %s: %d items" % [scope, scope_buckets[scope].size()])
	
	# Build unified test queue with scope metadata
	test_queue = []
	for scope in ["WEAPON_SPECIFIC", "FUSION_SPECIFIC", "GLOBAL_WEAPON", "PLAYER_ONLY"]:
		var scope_items = scope_buckets[scope]
		var scope_tests = _build_test_queue(scope_items)
		for t in scope_tests:
			t["_scope_tag"] = scope
		test_queue.append_array(scope_tests)
	
	scheduled_count = test_queue.size()
	print("[ItemTestRunner] FULL CYCLE: Scheduled %d tests across all scopes." % scheduled_count)
	
	_run_next_test()

func run_by_scope(scope_filter: String):
	"""
	Run tests only for items matching a specific scope.
	Valid scopes: PLAYER_ONLY, GLOBAL_WEAPON, WEAPON_SPECIFIC, FUSION_SPECIFIC
	"""
	run_id = "scope_%s_%s" % [scope_filter.to_lower(), str(Time.get_unix_time_from_system()).hash()]
	start_time_ms = Time.get_ticks_msec()
	results = []
	current_test_index = 0
	
	var all_items = _discover_items([])
	discovery_count = all_items.size()
	
	# Filter by scope
	var filtered_items = []
	for item in all_items:
		var scope = _classify_item(item)
		if scope == scope_filter:
			filtered_items.append(item)
	
	if filtered_items.is_empty():
		empty_reason = "No items found for scope: %s" % scope_filter
		print("[ItemTestRunner] ERROR: %s" % empty_reason)
		_finish_suite()
		return
	
	print("[ItemTestRunner] SCOPE [%s]: Found %d items (of %d total)." % [scope_filter, filtered_items.size(), discovery_count])
	
	test_queue = _build_test_queue(filtered_items)
	scheduled_count = test_queue.size()
	
	print("[ItemTestRunner] Scheduled %d tests for scope %s." % [scheduled_count, scope_filter])
	_run_next_test()


func _discover_items(categories: Array) -> Array:
	var items = []
	
	# ═══════════════════════════════════════════════════════════════════════════
	# 1. PLAYER UPGRADES (UpgradeDatabase)
	# ═══════════════════════════════════════════════════════════════════════════
	if categories.is_empty() or "UPGRADES" in categories:
		if UpgradeDatabase:
			_append_dictionary_items(items, UpgradeDatabase.DEFENSIVE_UPGRADES, "DEFENSIVE")
			_append_dictionary_items(items, UpgradeDatabase.UTILITY_UPGRADES, "UTILITY")
			_append_dictionary_items(items, UpgradeDatabase.OFFENSIVE_UPGRADES, "OFFENSIVE")
			_append_dictionary_items(items, UpgradeDatabase.CURSED_UPGRADES, "CURSED")
			_append_dictionary_items(items, UpgradeDatabase.UNIQUE_UPGRADES, "UNIQUE")
	
	# ═══════════════════════════════════════════════════════════════════════════
	# 2. WEAPON UPGRADES (WeaponUpgradeDatabase)
	# ═══════════════════════════════════════════════════════════════════════════
	if categories.is_empty() or "WEAPON_UPGRADES" in categories:
		if WeaponUpgradeDatabase:
			_append_dictionary_items(items, WeaponUpgradeDatabase.GLOBAL_UPGRADES, "WEAPON_GLOBAL")
			_append_dictionary_items(items, WeaponUpgradeDatabase.SPECIFIC_UPGRADES, "WEAPON_SPECIFIC_UPG")
			_append_dictionary_items(items, WeaponUpgradeDatabase.WEAPON_SPECIFIC_UPGRADES, "WEAPON_ONLY_UPG")
	
	# ═══════════════════════════════════════════════════════════════════════════
	# 3. WEAPONS
	# ═══════════════════════════════════════════════════════════════════════════
	if categories.is_empty() or "WEAPONS" in categories:
		if WeaponDatabase:
			_append_dictionary_items(items, WeaponDatabase.WEAPONS, "WEAPON")
	
	# ═══════════════════════════════════════════════════════════════════════════
	# 4. FUSIONS
	# ═══════════════════════════════════════════════════════════════════════════
	if categories.is_empty() or "FUSIONS" in categories:
		if WeaponDatabase:
			_append_dictionary_items(items, WeaponDatabase.FUSIONS, "FUSION")
	
	# ═══════════════════════════════════════════════════════════════════════════
	# 5. CHARACTERS (CharacterDatabase)
	# ═══════════════════════════════════════════════════════════════════════════
	if categories.is_empty() or "CHARACTERS" in categories:
		if CharacterDatabase:
			_append_dictionary_items(items, CharacterDatabase.CHARACTERS, "CHARACTER")
	
	# ═══════════════════════════════════════════════════════════════════════════
	# 6. ENEMIES (EnemyDatabase - 4 Tiers)
	# ═══════════════════════════════════════════════════════════════════════════
	if categories.is_empty() or "ENEMIES" in categories:
		if EnemyDatabase:
			_append_dictionary_items(items, EnemyDatabase.TIER_1_ENEMIES, "ENEMY_T1")
			_append_dictionary_items(items, EnemyDatabase.TIER_2_ENEMIES, "ENEMY_T2")
			_append_dictionary_items(items, EnemyDatabase.TIER_3_ENEMIES, "ENEMY_T3")
			_append_dictionary_items(items, EnemyDatabase.TIER_4_ENEMIES, "ENEMY_T4")
		
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
		var item_type = item.get("_type", "")
		
		# Specialized testing based on item type
		if item_type == "WEAPON" or item_type == "FUSION":
			# Test the weapon itself
			queue.append({
				"item": item,
				"target_weapon": item["id"],
				"is_self_test": true,
				"scenario": "mechanical_verification"
			})
		elif item_type == "CHARACTER":
			# Test character stats and passive validation
			queue.append({
				"item": item,
				"target_weapon": item.get("starting_weapon", "ice_wand"),
				"is_self_test": true,
				"scenario": "character_verification"
			})
		elif item_type in ["ENEMY_T1", "ENEMY_T2", "ENEMY_T3", "ENEMY_T4"]:
			# Test enemy stats and behavior validation
			queue.append({
				"item": item,
				"target_weapon": "ice_wand",
				"is_self_test": true,
				"scenario": "enemy_verification"
			})
		elif item_type in ["WEAPON_GLOBAL", "WEAPON_SPECIFIC_UPG", "WEAPON_ONLY_UPG"]:
			# Weapon upgrades - test against ice_wand
			queue.append({
				"item": item,
				"target_weapon": "ice_wand",
				"is_self_test": false,
				"scenario": "weapon_upgrade_verification"
			})
		else:
			# Player upgrades - test applicability
			queue.append({
				"item": item,
				"target_weapon": "ice_wand",
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
		"FUSION": [],
		"CHARACTER": [],
		"ENEMY": [],
		"WEAPON_UPGRADE": []
	}
	
	# Pre-classify
	for item in items:
		var scope = _classify_item(item)
		match scope:
			"PLAYER_ONLY": buckets["PLAYER_ONLY"].append(item)
			"FUSION_SPECIFIC": buckets["FUSION"].append(item)
			"CHARACTER": buckets["CHARACTER"].append(item)
			"ENEMY": buckets["ENEMY"].append(item)
			"GLOBAL_WEAPON": buckets["WEAPON_UPGRADE"].append(item)
			_: buckets["WEAPON"].append(item) # WEAPON_SPECIFIC, etc
			
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
			
	# Select Quotas (total ~35 items for pilot)
	var pilot_items = []
	
	# 8 PLAYER
	pilot_items.append_array(buckets["PLAYER_ONLY"].slice(0, min(8, buckets["PLAYER_ONLY"].size())))
	
	# 8 WEAPON
	pilot_items.append_array(buckets["WEAPON"].slice(0, min(8, buckets["WEAPON"].size())))
	
	# 5 FUSION
	pilot_items.append_array(buckets["FUSION"].slice(0, min(5, buckets["FUSION"].size())))
	
	# 5 WEAPON_UPGRADE
	pilot_items.append_array(buckets["WEAPON_UPGRADE"].slice(0, min(5, buckets["WEAPON_UPGRADE"].size())))
	
	# 3 CHARACTER
	pilot_items.append_array(buckets["CHARACTER"].slice(0, min(3, buckets["CHARACTER"].size())))
	
	# 6 ENEMY (mix of tiers)
	pilot_items.append_array(buckets["ENEMY"].slice(0, min(6, buckets["ENEMY"].size())))
	
	# Fallback fill if short
	var current_count = pilot_items.size()
	if current_count < 35:
		var needed = 35 - current_count
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
	if _exiting:
		return
		
	if current_test_index >= test_queue.size():
		_finish_suite()
		return
	
	# Micro-pause every 10 tests to let physics settle
	if current_test_index > 0 and current_test_index % 10 == 0:
		print("[ItemTestRunner] Progress: %d/%d tests completed..." % [current_test_index, test_queue.size()])
		await get_tree().process_frame
		await get_tree().process_frame
		if _exiting: return
		
	var test_case = test_queue[current_test_index]
	current_test_index += 1
	
	var item_id = test_case["item"]["id"]
	print("[ItemTestRunner] [%d/%d] Testing: %s" % [current_test_index, test_queue.size(), item_id])
	test_started.emit(item_id)
	
	# 1. SETUP Environment (now async due to cleanup)
	var env = await scenario_runner.setup_environment()
	if _exiting or not env:
		print("[ItemTestRunner] WARNING: Environment setup failed or exiting for %s" % item_id)
		return
		
	attack_manager = env.get_node_or_null("AttackManager")
	player_stats_mock = env.get_node_or_null("PlayerStats")
	var mock_player = env.get_node_or_null("MockPlayer")
	var global_weapon_stats = env.get_node_or_null("GlobalWeaponStats")
	
	if not attack_manager or not player_stats_mock or not mock_player:
		_record_failure(test_case, "Environment setup failed - missing nodes")
		await get_tree().process_frame
		_run_next_test()
		return
	
	# CRITICAL: Connect PlayerStats to its dependencies for weapon stat routing
	# Without this, weapon stats (damage_mult, attack_speed_mult, etc.) won't reach GlobalWeaponStats
	if player_stats_mock and global_weapon_stats:
		player_stats_mock.global_weapon_stats = global_weapon_stats
	if player_stats_mock and attack_manager:
		player_stats_mock.attack_manager = attack_manager
	
	# Initialize Managers
	if attack_manager.has_method("initialize"):
		attack_manager.initialize(mock_player)
	
	# Reset PlayerStats to baseline before each test
	if player_stats_mock:
		# Call _reset_stats directly (available in all PlayerStats)
		if player_stats_mock.has_method("_reset_stats"):
			player_stats_mock._reset_stats()
		elif player_stats_mock.has_method("reset_to_defaults"):
			player_stats_mock.reset_to_defaults()
		elif player_stats_mock.has_method("reset"):
			player_stats_mock.reset()
		elif player_stats_mock.has_method("initialize_from_character"):
			# Use generic character as reset
			player_stats_mock.initialize_from_character("default")
		
	# Setup Mechanical Oracle
	if mechanical_oracle:
		mechanical_oracle.is_measure_mode = is_measure_mode
		mechanical_oracle.start_listening()
		
	if status_oracle:
		status_oracle.start_listening()
		status_oracle.set_strict_mode(strict_contract_mode)
	
	# Setup Side Effect Detector for contract validation
	if side_effect_detector and strict_contract_mode:
		side_effect_detector.start_monitoring(mock_player, global_weapon_stats)
	
	# Infer Contract from Item Definition
	var item_contract = {}
	if contract_oracle and strict_contract_mode:
		item_contract = contract_oracle.infer_contract(test_case["item"])
	
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
	
	# Phase 5: Execution iterations for noise control
	# PLAYER_ONLY items don't need multiple iterations (no combat variance)
	var num_iterations = 1 if classification == "PLAYER_ONLY" else 3
	var iteration_results = []
	for i in range(num_iterations):
		# Reset oracles at START of each iteration (not after)
		mechanical_oracle.start_listening()
		status_oracle.start_listening()
		
		# Reset weapon cooldown to ensure it can fire each iteration
		if classification in ["WEAPON_SPECIFIC", "GLOBAL_WEAPON", "FUSION_SPECIFIC"]:
			var weapon_id = test_case.get("target_weapon", "")
			if weapon_id and attack_manager:
				var weapon = attack_manager.get_weapon_by_id(weapon_id)
				if weapon:
					weapon.ready_to_fire = true
					weapon.current_cooldown = 0.0
					if DEBUG_PHYSICS:
						print("[DEBUG_PHYSICS] Iteration %d/%d - Reset cooldown for %s" % [i + 1, num_iterations, weapon_id])
		
		# Reset PlayerStats between iterations to avoid accumulation
		if i > 0 and classification == "PLAYER_ONLY" and player_stats_mock:
			if player_stats_mock.has_method("_reset_stats"):
				player_stats_mock._reset_stats()
		
		var iter_res = await _execute_test_iteration(test_case, env, classification)
		iteration_results.append(iter_res)
	
	# Select Median based on actual_damage (or first if single iteration)
	var final_iter_res = iteration_results[0]
	if num_iterations == 3:
		iteration_results.sort_custom(func(a, b): return a.get("actual_damage", 0.0) < b.get("actual_damage", 0.0))
		final_iter_res = iteration_results[1] # Index 1 is median of 3
	
	# === CONTRACT VALIDATION (Phase 6) ===
	if strict_contract_mode and contract_oracle:
		# Stop side effect detector and collect data
		if side_effect_detector:
			side_effect_detector.stop_monitoring()
		
		# Build baseline and actual states from test results
		var baseline_state = {}
		var actual_state = {}
		var status_data = {}
		var damage_data = {}
		
		if side_effect_detector:
			baseline_state = side_effect_detector.player_state_before
			actual_state = side_effect_detector.player_state_after
		
		# Get status data from status oracle
		if status_oracle:
			var status_report = status_oracle.get_detailed_report()
			status_data["applied"] = []
			for entry in status_report:
				status_data["applied"].append(entry.get("effect", ""))
		
		# Get damage data from iteration result
		# Keys must match what ContractOracle._validate_damage expects
		damage_data = {
			"actual": final_iter_res.get("actual_damage", 0.0),
			"expected": final_iter_res.get("expected_damage", 0.0)
		}
		
		# Validate against contract
		var contract_result = contract_oracle.validate_contract(
			item_contract, baseline_state, actual_state, status_data, damage_data
		)
		
		# Add contract validation to subtests (ensure subtests exists)
		if not "subtests" in final_iter_res:
			final_iter_res["subtests"] = []
		final_iter_res["subtests"].append({
			"type": "contract_validation",
			"contract": item_contract,
			"result": contract_result
		})
		
		# If contract validation failed, mark test as failed
		if not contract_result["passed"]:
			final_iter_res["success"] = false
			for violation in contract_result["violations"]:
				final_iter_res["failures"].append(
					"CONTRACT: %s - Expected: %s, Actual: %s" % [
						violation.get("detail", "unknown"),
						str(violation.get("expected", "?")),
						str(violation.get("actual", "?"))
					]
				)
		
		# Check for side effects (potential bugs)
		if side_effect_detector:
			var declared_effects = {
				"stats": item_contract.get("stat_effects", {}).keys(),
				"statuses": item_contract.get("status_effects", []),
				"damage_types": ["normal"] if item_contract.get("damage_type", "") == "" else [item_contract.get("damage_type", "normal")],
				"affects_player": item_contract.get("target_scope", "") == "player",
				"affects_enemies": item_contract.get("target_scope", "") in ["enemy", "aoe", ""]
			}
			var side_effect_report = side_effect_detector.detect_side_effects(declared_effects)
			
			final_iter_res["subtests"].append({
				"type": "side_effect_detection",
				"result": side_effect_report
			})
			
			if side_effect_report["has_side_effects"]:
				# Side effects may indicate bugs
				if side_effect_report["severity"] == "critical":
					final_iter_res["success"] = false
					final_iter_res["failures"].append("BUG: %s" % side_effect_report["summary"])
				elif side_effect_report["severity"] == "major":
					final_iter_res["failures"].append("SIDE_EFFECT: %s" % side_effect_report["summary"])
	
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
	
	# Use process_frame instead of create_timer to avoid SceneTreeTimer leak on quit
	await get_tree().process_frame
	if _exiting: return
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
	
	# Clean any previous dummies - use call_deferred to avoid physics callback errors
	for dummy in get_tree().get_nodes_in_group("test_dummy"):
		dummy.call_deferred("queue_free")
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame to ensure deferred calls complete
	
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
				status_oracle.track_enemy(dummy)
		elif p_type == "AOE":
			# Spawn 2 dummies in AOE area
			var dummy1 = scenario_runner.spawn_dummy_enemy(Vector2(50, 0))
			var dummy2 = scenario_runner.spawn_dummy_enemy(Vector2(-50, 0))
			mechanical_oracle.track_enemy(dummy1)
			mechanical_oracle.track_enemy(dummy2)
			status_oracle.track_enemy(dummy1)
			status_oracle.track_enemy(dummy2)
		else:
			var spawn_pos = Vector2(100, 0)
			# T5: ORBIT weapons - spawn dummy INSIDE the orbital radius (70% of weapon_range)
			# This ensures the orbital projectiles actually pass through the dummy
			if p_type == "ORBIT":
				var orbital_radius = weapon_range * 0.7  # Typical orbital radius is smaller than weapon range
				spawn_pos = Vector2(orbital_radius, 0)
				if DEBUG_PHYSICS:
					print("[DEBUG_PHYSICS] ORBIT dummy spawned at radius %.1f (weapon_range=%.1f)" % [orbital_radius, weapon_range])
			var dummy = scenario_runner.spawn_dummy_enemy(spawn_pos)
			mechanical_oracle.track_enemy(dummy)
			status_oracle.track_enemy(dummy)
		
		# CRITICAL FIX: Disable AttackManager auto-fire during manual test
		# The AttackManager._process() would fire weapons automatically, causing duplicate hits
		var was_active = false
		if attack_manager and "is_active" in attack_manager:
			was_active = attack_manager.is_active
			attack_manager.is_active = false
			if DEBUG_HARNESS_FIX:
				print("[DEBUG_HARNESS_FIX] AttackManager.is_active: %s -> false (DISABLED for test)" % str(was_active))
		
		# FIRE!
		var p_stats_dict = {}
		if weapon.has_method("perform_attack"):
			p_stats_dict = player_stats_mock.get_all_stats() if player_stats_mock.has_method("get_all_stats") else {}
			if DEBUG_HARNESS_FIX:
				print("[DEBUG_HARNESS_FIX] Manual fire: weapon.perform_attack() called for %s" % item_id)
			weapon.perform_attack(mock_player, p_stats_dict)
			
		# Merge Player Stats into Final Stats for Oracle (so it sees burn_chance etc.)
		final_stats.merge(p_stats_dict, true)
		
		# Task 1: Dynamic Window
		var test_window = 1.0 # Default for SIMPLE/MULTI/CHAIN
		match p_type:
			"AOE": test_window = 1.2
			"BEAM": test_window = 1.5
			"ORBIT": test_window = 2.0
			
		# Extended window for DoTs
		if final_stats.get("burn_chance", 0) > 0 or final_stats.get("bleed_chance", 0) > 0:
			test_window = max(test_window, 2.0)
		
		# T2: USE PHYSICS FRAMES instead of Timer for reliable collision detection in headless
		if USE_PHYSICS_FRAMES:
			var physics_frames_needed = int(test_window * PHYSICS_FPS)
			if DEBUG_PHYSICS:
				print("[DEBUG_PHYSICS] Starting physics frame loop: %d frames (%.2fs at %d FPS)" % [
					physics_frames_needed, test_window, PHYSICS_FPS])
				print("[DEBUG_PHYSICS] Dummy position: %s, MockPlayer position: %s" % [
					str(_get_first_dummy_position()), str(mock_player.global_position)])
			
			var frames_processed = 0
			for i in range(physics_frames_needed):
				if _exiting:
					break
				await get_tree().physics_frame
				frames_processed += 1
				
				# Check for hits every 10 frames for debug
				if DEBUG_PHYSICS and i % 10 == 0 and i > 0:
					print("[DEBUG_PHYSICS] Frame %d/%d - Hits: %d, Damage: %.1f" % [
						i, physics_frames_needed, 
						mechanical_oracle.captured_events["hits"],
						mechanical_oracle.captured_events["total_damage"]])
			
			if DEBUG_PHYSICS:
				print("[DEBUG_PHYSICS] Loop complete. Processed %d physics frames. Final hits: %d" % [
					frames_processed, mechanical_oracle.captured_events["hits"]])
		else:
			# Legacy Timer-based approach (fallback, may not work in headless)
			var test_timer = Timer.new()
			test_timer.one_shot = true
			test_timer.wait_time = test_window
			add_child(test_timer)
			test_timer.start()
			await test_timer.timeout
			test_timer.queue_free()
		
		# Restore AttackManager state
		if attack_manager and "is_active" in attack_manager:
			if DEBUG_HARNESS_FIX:
				print("[DEBUG_HARNESS_FIX] Test window complete. Hits counted: %d" % mechanical_oracle.captured_events["hits"])
				print("[DEBUG_HARNESS_FIX] AttackManager.is_active: false -> %s (RESTORED)" % str(was_active))
			attack_manager.is_active = was_active
		
		if _exiting: 
			return iter_result
		
		# Capture final state
		mechanical_oracle.stop_listening()
		status_oracle.stop_listening()
		
		var mech_res = mechanical_oracle.verify_simulation_results(final_stats, str(p_type), test_window, 0.15)
		
		# STATUS VERIFICATION
		var status_results = []
		var main_effect = final_stats.get("effect", "none")
		
		# Check for Burn
		if main_effect == "burn" or final_stats.get("burn_chance", 0) > 0:
			var expected_burn = final_stats.get("burn_damage", 3.0)
			# If implicitly defined by effect value
			if main_effect == "burn": expected_burn = final_stats.get("effect_value", 3.0)
			
			var res = status_oracle.verify_status_strict("burn", {"damage": expected_burn})
			status_results.append({"status": "burn", "res": res})
			
		# Check for Freeze
		if main_effect == "freeze" or final_stats.get("freeze_chance", 0) > 0:
			var res = status_oracle.verify_status_strict("freeze", {"amount": 1.0})
			status_results.append({"status": "freeze", "res": res})
			
		# Check for Slow (if not frozen, often implicit or separate)
		if main_effect == "slow" or final_stats.get("slow_chance", 0) > 0:
			# Slow amount varies, usually 0.5 or from stat
			var res = status_oracle.verify_status_strict("slow", {}) 
			status_results.append({"status": "slow", "res": res})
			
		# Check for Bleed
		if main_effect == "bleed" or final_stats.get("bleed_chance", 0) > 0:
			var res = status_oracle.verify_status_strict("bleed", {"damage": final_stats.get("bleed_damage", 2.0)})
			status_results.append({"status": "bleed", "res": res})
			
		# Check for Stun
		if main_effect == "stun":
			var res = status_oracle.verify_status_strict("stun", {})
			status_results.append({"status": "stun", "res": res})

		# Check for Blind
		if main_effect == "blind":
			var res = status_oracle.verify_status_strict("blind", {})
			status_results.append({"status": "blind", "res": res})

		
		iter_result["success"] = (mech_res.get("result_code", "PASS") != "BUG")
		
		# Validate Status Results
		for s_res in status_results:
			if not s_res["res"].get("passed", true):
				iter_result["success"] = false
				iter_result["failures"].append("Status Fail [%s]: %s" % [s_res["status"], s_res["res"].get("reason", "unknown")])
			iter_result["subtests"].append({"type": "status_verification", "status": s_res["status"], "res": s_res["res"]})

		# Attach detailed per-instance status logs
		iter_result["status_details"] = status_oracle.get_detailed_report()

		if not mech_res.get("passed", true):
			iter_result["failures"].append(mech_res.get("reason", "unknown mechanical failure"))
			
		iter_result["subtests"].append({"type": "mechanical_damage", "res": mech_res})
		iter_result["expected_damage"] = mech_res.get("expected", 0.0)
		iter_result["actual_damage"] = mech_res.get("actual", 0.0)
		iter_result["weapon_id"] = weapon_id
		if "measurements" in mech_res:
			iter_result["measurements"] = mech_res["measurements"]
			
		return iter_result

	# PLAYER SCOPE - Apply upgrade and verify stat changes
	if classification == "PLAYER_ONLY":
		# Get the item definition
		var item_data = test_case["item"]
		var effects = item_data.get("effects", [])
		
		# Capture baseline state before applying upgrade
		# The SideEffectDetector already captured this in start_monitoring()
		
		# Apply the upgrade to player stats
		if player_stats_mock and player_stats_mock.has_method("apply_upgrade"):
			player_stats_mock.apply_upgrade(item_data)
		elif player_stats_mock and player_stats_mock.has_method("apply_upgrade_by_id"):
			player_stats_mock.apply_upgrade_by_id(item_id)
		elif player_stats_mock and player_stats_mock.has_method("apply_effects"):
			player_stats_mock.apply_effects(effects)
		else:
			# Manual fallback: Apply each effect directly
			for effect in effects:
				var stat_name = effect.get("stat", "")
				var value = effect.get("value", 0)
				var operation = effect.get("operation", "add")
				
				if stat_name and player_stats_mock:
					# Try to apply via set_stat method
					if player_stats_mock.has_method("modify_stat"):
						player_stats_mock.modify_stat(stat_name, value, operation)
					elif player_stats_mock.has_method("add_modifier"):
						player_stats_mock.add_modifier(stat_name, value, operation)
					elif stat_name in player_stats_mock:
						# Direct property access fallback
						var current = player_stats_mock.get(stat_name)
						if operation == "add":
							player_stats_mock.set(stat_name, current + value)
						elif operation == "multiply":
							player_stats_mock.set(stat_name, current * value)
		
		# Wait a frame for any deferred property updates
		await get_tree().process_frame
		
		# Verification is handled by ContractOracle in the calling code
		# which will capture the new state via SideEffectDetector.stop_monitoring()
		
	return iter_result

func _classify_item(item: Dictionary) -> String:
	# Classification based on item type
	var item_type = item.get("_type", "")
	
	# Direct type mappings
	match item_type:
		"WEAPON": return "WEAPON_SPECIFIC"
		"FUSION": return "FUSION_SPECIFIC"
		"CHARACTER": return "CHARACTER"
		"ENEMY_T1", "ENEMY_T2", "ENEMY_T3", "ENEMY_T4": return "ENEMY"
		"WEAPON_GLOBAL": return "GLOBAL_WEAPON"
		"WEAPON_SPECIFIC_UPG": return "WEAPON_SPECIFIC"
		"WEAPON_ONLY_UPG": return "WEAPON_SPECIFIC"
		"DEFENSIVE", "UTILITY", "CURSED", "UNIQUE": return "PLAYER_ONLY"
		"OFFENSIVE": 
			# Offensive upgrades may affect weapons or player
			var effects = item.get("effects", [])
			for eff in effects:
				var stat = eff.get("stat", "")
				if stat in ["damage_mult", "area_mult", "cooldown_mult", "projectile_speed"]:
					return "GLOBAL_WEAPON"
			return "PLAYER_ONLY"
	
	# Fallback heuristics
	if item.get("category") == "defensive": return "PLAYER_ONLY"
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

# ═══════════════════════════════════════════════════════════════════════════════
# CONTRACT VALIDATION HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

func _build_observed_behavior(iter_result: Dictionary, test_case: Dictionary) -> Dictionary:
	"""
	Builds the observed behavior dictionary from test results.
	This is compared against the inferred contract.
	"""
	var observed = {
		"stat_changes": {},
		"status_effects_applied": [],
		"damage_dealt": 0.0,
		"enemies_hit": 0,
		"special_behaviors": []
	}
	
	# Extract damage from mechanical oracle results
	observed["damage_dealt"] = iter_result.get("actual_damage", 0.0)
	
	# Extract status effects from status oracle
	if status_oracle:
		var status_report = status_oracle.get_detailed_report()
		for entry in status_report:
			observed["status_effects_applied"].append({
				"name": entry.get("effect", ""),
				"duration": entry.get("expected_duration", 0),
				"ticks": entry.get("ticks", 0),
				"total_damage": entry.get("total_damage", 0.0),
				"params": entry.get("params", {})
			})
			observed["enemies_hit"] = max(observed["enemies_hit"], 1)
	
	# Extract stat changes from side effect detector
	if side_effect_detector:
		var all_events = side_effect_detector.get_all_events()
		for event in all_events.get("stat_change_events", []):
			var stat_name = event.get("stat", "")
			observed["stat_changes"][stat_name] = {
				"delta": event.get("delta", 0),
				"old_value": event.get("old_value", 0),
				"new_value": event.get("new_value", 0)
			}
	
	# Count enemies hit from subtests
	for subtest in iter_result.get("subtests", []):
		if subtest.get("type") == "mechanical_damage":
			var mech_res = subtest.get("res", {})
			observed["enemies_hit"] = max(observed["enemies_hit"], mech_res.get("enemies_damaged", 0))
	
	return observed

# ═══════════════════════════════════════════════════════════════════════════════
# SIMULACIÓN DE EVENTOS - Task 2
# Simula on_hit, on_kill, on_pickup, time_passed para testear items condicionales
# ═══════════════════════════════════════════════════════════════════════════════

## Detecta qué eventos requiere un item para funcionar
func _detect_required_events(item: Dictionary) -> Array:
	var required = []
	var desc = item.get("description", "").to_lower()
	var effects = item.get("effects", [])
	
	# Inferir de descripción
	if "matar" in desc or "kill" in desc or "al eliminar" in desc:
		required.append("on_kill")
	if "impactar" in desc or "golpear" in desc or "al atacar" in desc or "on hit" in desc:
		required.append("on_hit")
	if "recoger" in desc or "pickup" in desc:
		required.append("on_pickup")
	if "por minuto" in desc or "cada segundo" in desc or "per minute" in desc:
		required.append("time_passed")
	if "recibir daño" in desc or "al ser golpeado" in desc:
		required.append("on_damage_taken")
	
	# Inferir de efectos
	for effect in effects:
		var stat = effect.get("stat", "")
		if "on_hit" in stat or "on_kill" in stat:
			if "on_kill" in stat and not "on_kill" in required:
				required.append("on_kill")
			if "on_hit" in stat and not "on_hit" in required:
				required.append("on_hit")
	
	# Cache para futuras referencias
	var item_id = item.get("id", "")
	if item_id != "":
		_event_requirements[item_id] = required
	
	return required

## Simula eventos on_hit para un item
func simulate_on_hit(count: int, env: Node, item: Dictionary = {}) -> Dictionary:
	var result = {
		"event_type": "on_hit",
		"count": count,
		"triggered": 0,
		"effects_observed": []
	}
	
	if not event_simulation_enabled:
		return result
	
	var mock_player = env.get_node_or_null("MockPlayer")
	if not mock_player:
		result["error"] = "MockPlayer not found"
		return result
	
	# Simular N impactos
	for i in range(count):
		# Emitir señal de hit si existe
		if mock_player.has_signal("on_hit_dealt"):
			mock_player.emit_signal("on_hit_dealt", {
				"damage": 10.0,
				"target": null,
				"crit": false,
				"iteration": i
			})
			result["triggered"] += 1
		elif mock_player.has_method("_on_hit_dealt"):
			mock_player._on_hit_dealt(10.0, null, false)
			result["triggered"] += 1
		
		# Pequeña espera para procesar
		await get_tree().process_frame
	
	return result

## Simula eventos on_kill para un item
func simulate_on_kill(count: int, env: Node, item: Dictionary = {}) -> Dictionary:
	var result = {
		"event_type": "on_kill",
		"count": count,
		"triggered": 0,
		"effects_observed": []
	}
	
	if not event_simulation_enabled:
		return result
	
	var mock_player = env.get_node_or_null("MockPlayer")
	if not mock_player:
		result["error"] = "MockPlayer not found"
		return result
	
	# Simular N kills
	for i in range(count):
		if mock_player.has_signal("on_enemy_killed"):
			mock_player.emit_signal("on_enemy_killed", {
				"enemy_type": "test_dummy",
				"xp_value": 10,
				"iteration": i
			})
			result["triggered"] += 1
		elif mock_player.has_method("_on_enemy_killed"):
			mock_player._on_enemy_killed("test_dummy", 10)
			result["triggered"] += 1
		
		await get_tree().process_frame
	
	return result

## Simula recoger items/XP
func simulate_on_pickup(count: int, env: Node, item: Dictionary = {}) -> Dictionary:
	var result = {
		"event_type": "on_pickup",
		"count": count,
		"triggered": 0,
		"effects_observed": []
	}
	
	if not event_simulation_enabled:
		return result
	
	var mock_player = env.get_node_or_null("MockPlayer")
	if not mock_player:
		result["error"] = "MockPlayer not found"
		return result
	
	for i in range(count):
		if mock_player.has_signal("on_item_picked"):
			mock_player.emit_signal("on_item_picked", {
				"item_type": "xp_orb",
				"value": 5,
				"iteration": i
			})
			result["triggered"] += 1
		
		await get_tree().process_frame
	
	return result

## Simula paso del tiempo para efectos per_minute
func simulate_time_passed(seconds: float, env: Node, item: Dictionary = {}) -> Dictionary:
	var result = {
		"event_type": "time_passed",
		"seconds": seconds,
		"triggered": false,
		"stat_before": {},
		"stat_after": {}
	}
	
	if not event_simulation_enabled:
		return result
	
	var mock_player = env.get_node_or_null("MockPlayer")
	if not mock_player:
		result["error"] = "MockPlayer not found"
		return result
	
	# Capturar stats antes
	if mock_player.has_method("get_all_stats"):
		result["stat_before"] = mock_player.get_all_stats().duplicate()
	
	# Simular el paso del tiempo
	if mock_player.has_method("_process_game_time"):
		mock_player._process_game_time(seconds)
		result["triggered"] = true
	elif mock_player.has_signal("game_time_updated"):
		mock_player.emit_signal("game_time_updated", seconds)
		result["triggered"] = true
	
	# Esperar procesamiento
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Capturar stats después
	if mock_player.has_method("get_all_stats"):
		result["stat_after"] = mock_player.get_all_stats().duplicate()
	
	return result

## Verifica si un test debe ser SKIPPED por falta de eventos
func _should_skip_for_events(item: Dictionary) -> Dictionary:
	var skip_info = {
		"should_skip": false,
		"reason": "",
		"required_events": []
	}
	
	if not event_simulation_enabled:
		var required = _detect_required_events(item)
		if not required.is_empty():
			skip_info["should_skip"] = true
			skip_info["required_events"] = required
			skip_info["reason"] = "Event simulation disabled. Required events: %s" % str(required)
	
	return skip_info

func _exit_run():
	print("[ItemTestRunner] Exiting...")
	_exiting = true  # Signal all async operations to abort
	_cleanup()
	# Wait for cleanup to propagate (freed nodes)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit()

func _cleanup():
	# Kill any active timers first (prevents GDScriptFunctionState leaks)
	for child in get_children():
		if child is Timer:
			child.stop()
			child.queue_free()
	
	if scenario_runner and is_instance_valid(scenario_runner):
		scenario_runner.teardown_environment()
		scenario_runner.queue_free()
	
	# Clear Oracle data by cycling listening state
	if mechanical_oracle and is_instance_valid(mechanical_oracle):
		mechanical_oracle.stop_listening()
		mechanical_oracle.queue_free()
	
	if status_oracle and is_instance_valid(status_oracle):
		status_oracle.stop_listening()
		status_oracle.queue_free()
	
	if numeric_oracle and is_instance_valid(numeric_oracle):
		numeric_oracle.queue_free()
		
	if report_writer and is_instance_valid(report_writer):
		report_writer.queue_free()
		
	# Clean up weapons properly before freeing AttackManager
	if attack_manager and is_instance_valid(attack_manager):
		if attack_manager.has_method("reset_for_new_game"):
			attack_manager.reset_for_new_game()
		attack_manager.queue_free()

func _finish_suite():
	print("[ItemTestRunner] Suite Finished. Checking for results...")
	
	if results.is_empty():
		var reason = empty_reason if empty_reason != "" else "No tests were executed (stopped early or crashed)."
		print("[ItemTestRunner] ERROR: %s - Skipping report generation." % reason)
		_exit_run()
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
		"executed_tests_count": results.size(),
		"empty_reason": empty_reason
	}

	print("[ItemTestRunner] Generating Report for %d results..." % results.size())
	var path = report_writer.generate_report(results, metadata)
	var md_path = report_writer.generate_summary_md(results, path, metadata)
	
	# Generate Full Cycle report if it's a full cycle run
	if run_id.begins_with("full_cycle_") or run_id.begins_with("scope_"):
		var fc_path = report_writer.generate_full_cycle_report(results, metadata)
		print("[ItemTestRunner] Full Cycle Report saved to: %s" % fc_path)
	
	# Generate Contract Validation report if strict mode is enabled
	if strict_contract_mode:
		metadata["strict_contract_mode"] = true
		var cv_path = report_writer.generate_contract_validation_report(results, metadata)
		print("[ItemTestRunner] Contract Validation Report saved to: %s" % cv_path)
	
	all_tests_completed.emit(path)
	print("[ItemTestRunner] Report saved to: %s" % path)
	print("[ItemTestRunner] Summary saved to: %s" % md_path)
	print("[ItemTestRunner] Final Stats: Scheduled=%d, Executed=%d, Time=%dms" % [scheduled_count, results.size(), duration])
	
	_exit_run()

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS (T1 Diagnostics)
# ═══════════════════════════════════════════════════════════════════════════════

func _get_first_dummy_position() -> Vector2:
	"""Get position of first test dummy for debug logging."""
	var dummies = get_tree().get_nodes_in_group("test_dummy")
	if dummies.size() > 0:
		return dummies[0].global_position
	return Vector2.ZERO

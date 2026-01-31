extends SceneTree

# UpgradesAuditRunner.gd
# Validates all upgrades correctly modify PlayerStats.
# Run with: godot --headless -s scripts/tests/runners/UpgradesAuditRunner.gd

var _results = []
var _total_tests = 0
var _passed_tests = 0
var _failed_tests = 0

# Sample upgrades to test (representative of each category)
const UPGRADES_TO_TEST = [
	{"id": "health_1", "stat": "max_health", "expected_change": 10, "operation": "add"},
	{"id": "regen_1", "stat": "health_regen", "expected_change": 1.0, "operation": "add"},
	{"id": "armor_1", "stat": "armor", "expected_change": 3, "operation": "add"},
	{"id": "dodge_1", "stat": "dodge_chance", "expected_change": 0.05, "operation": "add"},
	{"id": "speed_1", "stat": "move_speed_bonus", "expected_change": 0.08, "operation": "add"},
	{"id": "xp_boost_1", "stat": "xp_mult", "expected_change": 0.10, "operation": "add"},
	{"id": "pickup_1", "stat": "pickup_radius_mult", "expected_change": 0.20, "operation": "add"},
	{"id": "crit_1", "stat": "crit_chance", "expected_change": 0.05, "operation": "add"},
	{"id": "crit_damage_1", "stat": "crit_damage", "expected_change": 0.15, "operation": "add"},
	{"id": "cooldown_1", "stat": "cooldown_mult", "expected_change": -0.05, "operation": "add"},
]

func _init():
	print("📦 Upgrades Audit Runner Starting...")
	print("=" * 60)
	
	await _run_all_tests()
	
	_print_report()
	quit(_failed_tests > 0)

func _run_all_tests():
	# Load UpgradeDatabase
	var UpgradeDB = load("res://scripts/data/UpgradeDatabase.gd")
	var PlayerStatsScript = load("res://scripts/core/PlayerStats.gd")
	
	if not UpgradeDB:
		print("❌ FATAL: Could not load UpgradeDatabase")
		_failed_tests += 1
		return
	
	if not PlayerStatsScript:
		print("❌ FATAL: Could not load PlayerStats")
		_failed_tests += 1
		return
	
	print("\n🔍 Testing upgrade applications...")
	
	for test in UPGRADES_TO_TEST:
		_total_tests += 1
		
		var upgrade_id = test.id
		var expected_stat = test.stat
		var expected_change = test.expected_change
		var operation = test.operation
		
		# Find upgrade in database
		var upgrade_data = _find_upgrade(UpgradeDB, upgrade_id)
		
		if not upgrade_data:
			_log_result(upgrade_id, "SKIP", "Not found in database")
			continue
		
		# Create fresh PlayerStats
		var stats = PlayerStatsScript.new()
		stats.add_to_group("player_stats")
		root.add_child(stats)
		
		await process_frame
		
		# Get initial value
		var initial_value = 0.0
		if stats.has_method("get_stat"):
			initial_value = stats.get_stat(expected_stat)
		
		# Apply upgrade
		if stats.has_method("apply_upgrade"):
			stats.apply_upgrade(upgrade_data)
		else:
			_log_result(upgrade_id, "SKIP", "PlayerStats.apply_upgrade not found")
			stats.queue_free()
			continue
		
		await process_frame
		
		# Get new value
		var new_value = 0.0
		if stats.has_method("get_stat"):
			new_value = stats.get_stat(expected_stat)
		
		# Calculate actual change
		var actual_change = new_value - initial_value
		
		# Verify
		var tolerance = 0.001
		var change_correct = false
		
		if operation == "add":
			change_correct = abs(actual_change - expected_change) < tolerance
		elif operation == "multiply":
			# For multiply, check the final value matches expected multiplier
			var expected_final = initial_value * expected_change
			change_correct = abs(new_value - expected_final) < tolerance
		
		if change_correct:
			_passed_tests += 1
			_log_result(upgrade_id, "PASS", 
				"%s: %.2f -> %.2f (Δ%.2f)" % [expected_stat, initial_value, new_value, actual_change])
		else:
			_failed_tests += 1
			_log_result(upgrade_id, "FAIL", 
				"%s: expected Δ%.2f, got Δ%.2f" % [expected_stat, expected_change, actual_change])
		
		# Cleanup
		stats.queue_free()
		await process_frame

func _find_upgrade(UpgradeDB, upgrade_id: String) -> Dictionary:
	"""Search all upgrade categories for the given ID."""
	
	# Check defensive upgrades
	if "DEFENSIVE_UPGRADES" in UpgradeDB:
		if UpgradeDB.DEFENSIVE_UPGRADES.has(upgrade_id):
			return UpgradeDB.DEFENSIVE_UPGRADES[upgrade_id]
	
	# Check utility upgrades
	if "UTILITY_UPGRADES" in UpgradeDB:
		if UpgradeDB.UTILITY_UPGRADES.has(upgrade_id):
			return UpgradeDB.UTILITY_UPGRADES[upgrade_id]
	
	# Check offensive upgrades
	if "OFFENSIVE_UPGRADES" in UpgradeDB:
		if UpgradeDB.OFFENSIVE_UPGRADES.has(upgrade_id):
			return UpgradeDB.OFFENSIVE_UPGRADES[upgrade_id]
	
	# Check cursed upgrades  
	if "CURSED_UPGRADES" in UpgradeDB:
		if UpgradeDB.CURSED_UPGRADES.has(upgrade_id):
			return UpgradeDB.CURSED_UPGRADES[upgrade_id]
	
	# Try get_upgrade_by_id if available
	if UpgradeDB.has_method("get_upgrade_by_id"):
		return UpgradeDB.get_upgrade_by_id(upgrade_id)
	
	return {}

func _log_result(upgrade_id: String, status: String, message: String):
	var icon = "✅" if status == "PASS" else "❌" if status == "FAIL" else "⏭️"
	var log_line = "%s [%s] %s: %s" % [icon, status, upgrade_id, message]
	print(log_line)
	_results.append({
		"upgrade": upgrade_id,
		"status": status,
		"message": message
	})

func _print_report():
	print("\n" + "=" * 60)
	print("📋 UPGRADES AUDIT REPORT")
	print("=" * 60)
	print("Total Tests: %d" % _total_tests)
	print("Passed: %d" % _passed_tests)
	print("Failed: %d" % _failed_tests)
	print("Skip: %d" % (_total_tests - _passed_tests - _failed_tests))
	
	if _failed_tests > 0:
		print("\n❌ FAILED UPGRADES:")
		for r in _results:
			if r.status == "FAIL":
				print("  - %s: %s" % [r.upgrade, r.message])
	
	# Save report
	var report_path = "res://upgrade_audit_report.md"
	var file = FileAccess.open(report_path, FileAccess.WRITE)
	if file:
		file.store_string("# Upgrades Audit Report\n\n")
		file.store_string("**Date**: %s\n\n" % Time.get_datetime_string_from_system())
		file.store_string("| Upgrade | Status | Details |\n")
		file.store_string("|---------|--------|----------|\n")
		for r in _results:
			var icon = "✅" if r.status == "PASS" else "❌" if r.status == "FAIL" else "⏭️"
			file.store_string("| %s | %s %s | %s |\n" % [r.upgrade, icon, r.status, r.message])
		file.store_string("\n**Result**: %d/%d passed\n" % [_passed_tests, _total_tests])
		print("\n📄 Report saved to: %s" % report_path)
	
	print("=" * 60)
	if _failed_tests > 0:
		print("❌ AUDIT FAILED - Some upgrades do not apply correctly!")
	else:
		print("✅ AUDIT PASSED - All upgrades apply correctly!")

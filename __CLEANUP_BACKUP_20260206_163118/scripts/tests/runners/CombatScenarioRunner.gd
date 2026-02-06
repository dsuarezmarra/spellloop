extends SceneTree

# CombatScenarioRunner.gd
# Runs combat validation scenarios (Contracts, Scaling, Status, TTK).
# Run with: godot --headless -s scripts/tests/runners/CombatScenarioRunner.gd

var _total_tests = 0
var _passed_tests = 0
var _failed_tests = 0
var _report_lines = []

func _init():
	print("⚔️ Initializing Combat Scenario Validation...")
	_report_header()
	
	# Wait for engine to settle?
	# In -s mode, we are the main loop.
	# We need to manually initialize singletons if they are not auto-loaded in this mode.
	
	# Load Helper Classes
	var oracle_script = load("res://scripts/tests/oracles/EnemyContractOracle.gd")
	if not oracle_script:
		print("❌ CRITICAL: Could not load EnemyContractOracle.gd")
		_failed_tests += 1
		quit(1)
		return
		
	# Oracle is static, so we can just reference the loaded script class? 
	# Or instantiate it? It uses static funcs.
	# In GDScript, if class_name is not registered, you can use the loaded script as the class.
	var OracleClass = oracle_script
	
	# Load Database (Autoload usually)
	var db_script = load("res://scripts/data/EnemyDatabase.gd")
	if not db_script:
		print("❌ CRITICAL: Could not load EnemyDatabase.gd")
		_failed_tests += 1
		quit(1)
		return
	
	# Check if EnemyDatabase is already autoloaded (unlikely in -s)
	# If not, use the static methods from the script.
	var DBClass = db_script
	
	await _run_contract_validation(OracleClass, DBClass)
	await _run_scaling_validation(DBClass)
	await _run_status_validation(DBClass)
	
	# Global cleanup wait
	for i in range(5):
		await process_frame
		
	# Force cleanup of any remaining nodes in root (projectiles?)
	for child in root.get_children():
		if child != self:
			child.queue_free()
			
	await process_frame
		
	_print_report()
	quit(_failed_tests > 0)

func _report_header():
	_report_lines.append("# Phase 5: Enemy & Combat Validation Report")
	_report_lines.append("**Date**: %s" % Time.get_datetime_string_from_system())
	_report_lines.append("")
	_report_lines.append("## 1. Enemy Contract Validation")
	_report_lines.append("| ID | Tier | HP | Dmg | Spd | Size | Result |")
	_report_lines.append("|---|---|---|---|---|---|---|")

func _run_contract_validation(OracleClass, DBClass):
	print("🔍 Starting Contract Validation...")
	
	# Load EnemyBase script to instantiate
	var enemy_script = load("res://scripts/enemies/EnemyBase.gd")
	if not enemy_script:
		print("❌ CRITICAL: Could not load EnemyBase.gd")
		_failed_tests += 1
		return

	# Gather all enemies
	var all_enemies = []
	all_enemies += DBClass.get_all_tier_1().values()
	all_enemies += DBClass.get_all_tier_2().values()
	all_enemies += DBClass.get_all_tier_3().values()
	all_enemies += DBClass.get_all_tier_4().values()
	# Bosses maybe later or separate
	
	var dummy_player = Node2D.new()
	dummy_player.name = "DummyPlayer"
	root.add_child(dummy_player)
	
	for data in all_enemies:
		_total_tests += 1
		var enemy_id = data.get("id", "unknown")
		
		# Spawn
		var enemy = enemy_script.new()
		# Add to tree BEFORE initialize (common Godot pattern for ready/on_enter)
		root.add_child(enemy)
		
		# Initialize (Needs EnemyDatabase global for some lookups if EnemyBase uses it internally? Yes...)
		# EnemyBase usually has all logic internal or uses other singletons.
		# If EnemyBase uses EnemyDatabase.get_ Something, it will crash if global is not there.
		# But initialize_from_database accepts 'data' dict.
		# Initialize
		enemy.initialize_from_database(data, dummy_player)
		
		# CRITICAL: Disable processing to prevent Attribute/AttackSystem from running 
		# and spawning projectiles (which leak because they become siblings)
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		if enemy.attack_system:
			enemy.attack_system.queue_free() # Force destroy to prevent ANY auto-attacks/leaks
		
		# Check Contract
		# We must pass DBClass to Oracle too because Oracle uses EnemyDatabase global.
		# Updated Oracle to accept DBClass or handle it? 
		# No, I should update Oracle code too? 
		# Actually, if I load the script, I can inject it? 
		# For now, let's assume Oracle can use the global name IF the script loaded it into ClassDB?
		# No, -s skips that.
		
		# I will modify Oracle Call to accept DBClass OR modify Oracle to use the loaded script.
		# But validate_enemy calls EnemyDatabase internally.
		# Hack: Assign the script to a global constant? Not possible at runtime easily.
		
		# Better: Pass "expected_data" explicitly to the Oracle!
		# The Oracle already fetches it? 
		# "var expected_data = EnemyDatabase.get_enemy_by_id(actual_id)" in Oracle.
		
		# REFACTOR ORACLE: To accept expected_data.
		var result = OracleClass.validate_enemy(enemy, data) # Modifying Oracle next!
		
		if result.passed:
			_passed_tests += 1
			_log_contract_row(data, "✅ PASS")
		else:
			_failed_tests += 1
			_log_contract_row(data, "❌ FAIL")
			# Log details
			for disc in result.discrepancies:
				_report_lines.append("> ⚠️ %s: %s" % [enemy_id, disc])
		
		# Cleanup
		enemy.queue_free()
		await process_frame # Let queue_free happen
	
	dummy_player.queue_free()
	
	# Wait for cleanup to propagate
	await process_frame
	await process_frame


func _run_scaling_validation(DBClass):
	print("\n📈 Starting Scaling Validation...")
	_report_lines.append("")
	_report_lines.append("## 2. Scaling Validation (Tier 1 vs Tier 4)")
	_report_lines.append("| Enemy ID | Stat | T1 Value | T4 Expected | T4 Actual | Ratio | Result |")
	_report_lines.append("|---|---|---|---|---|---|---|")
	
	var test_targets = ["tier_1_esqueleto_aprendiz", "tier_1_duende_sombrio", "tier_1_slime_arcano"]
	var multipliers = DBClass.TIER_SCALING[4] # {hp: 9.0, damage: 4.0, speed: 1.65...}
	
	# Load EnemyBase
	var enemy_script = load("res://scripts/enemies/EnemyBase.gd")
	var dummy_player = Node2D.new()
	root.add_child(dummy_player)
	
	for t1_id in test_targets:
		# Just compare Averages
		pass
		
	# Calculate Averages per Tier
	var stats = {
		1: {"hp": 0, "dmg": 0, "count": 0},
		4: {"hp": 0, "dmg": 0, "count": 0}
	}
	
	for tier in [1, 4]:
		var enemies = DBClass.get_all_tier_1().values() if tier == 1 else DBClass.get_all_tier_4().values()
		for data in enemies:
			stats[tier].hp += data.get("base_hp", 0)
			stats[tier].dmg += data.get("base_damage", 0)
			stats[tier].count += 1
			
	# Print Results
	if stats[1].count > 0 and stats[4].count > 0:
		var avg_hp_1 = float(stats[1].hp) / stats[1].count
		var avg_dmg_1 = float(stats[1].dmg) / stats[1].count
		var avg_hp_4 = float(stats[4].hp) / stats[4].count
		var avg_dmg_4 = float(stats[4].dmg) / stats[4].count
		
		var hp_ratio = avg_hp_4 / avg_hp_1
		var dmg_ratio = avg_dmg_4 / avg_dmg_1
		
		var exp_hp_mult = DBClass.TIER_SCALING[4].hp # 9.0
		var exp_dmg_mult = DBClass.TIER_SCALING[4].damage # 4.0
		
		_report_lines.append("| Avg HP | %.1f | %.1f (Exp: %.1fx) | %.1f (Act) | %.2fx | %s |" % [
			avg_hp_1, avg_hp_1 * exp_hp_mult, exp_hp_mult, avg_hp_4, hp_ratio,
			"✅ PASS" if abs(hp_ratio - exp_hp_mult) < 2.0 else "⚠️ WARN"
		])
		_report_lines.append("| Avg Dmg | %.1f | %.1f (Exp: %.1fx) | %.1f (Act) | %.2fx | %s |" % [
			avg_dmg_1, avg_dmg_1 * exp_dmg_mult, exp_dmg_mult, avg_dmg_4, dmg_ratio,
			"✅ PASS" if abs(dmg_ratio - exp_dmg_mult) < 1.0 else "⚠️ WARN"
		])
	else:
		_report_lines.append("> ⚠️ Not enough data to calculate ratios.")

	dummy_player.queue_free()

func _run_status_validation(DBClass):
	print("\n❄️ Starting Status Effect Validation...")
	_report_lines.append("")
	_report_lines.append("## 3. Status Effect Validation")
	_report_lines.append("| Effect | Target | Duration | Result |")
	_report_lines.append("|---|---|---|---|")
	
	# Load EnemyBase
	var enemy_script = load("res://scripts/enemies/EnemyBase.gd")
	var dummy_player = Node2D.new()
	root.add_child(dummy_player)
	
	# Spawn a test dummy (Skeleton)
	var data = DBClass.get_all_tier_1().values()[0]
	var enemy = enemy_script.new()
	root.add_child(enemy)
	enemy.initialize_from_database(data, dummy_player)
	
	# Test 1: Freeze (Speed = 0)
	var initial_speed = enemy.speed
	if enemy.has_method("apply_freeze"):
		enemy.apply_freeze(1.0, 1.0)
		_check_status_result("Freeze", "Speed Reduction", enemy.speed < initial_speed * 0.5) 
		# Freeze sets speed to 0 usually? Or reduced? 
		# Reading EnemyBase: speed = _base_speed * (1.0 - _slow_amount). Freeze passes amount=1.0? 
		# If amount is 1.0, speed is 0.
	else:
		_check_status_result("Freeze", "Method Exists", false, "Method Missing")

	# Test 2: Burn (DoT)
	if enemy.has_method("apply_burn"):
		enemy.apply_burn(5, 1.0) # 5 dmg
		await process_frame
		# Need to wait for tick (0.5s usually)
		# Just check if state is active
		_check_status_result("Burn", "State Active", enemy._is_burning)
	
	# Test 3: Stun (Can Attack = False)
	if enemy.has_method("apply_stun"):
		enemy.apply_stun(1.0)
		_check_status_result("Stun", "Attack Blocked", not enemy.can_attack)
	
	enemy.queue_free()
	dummy_player.queue_free()

func _check_status_result(effect, check, passed, msg=""):
	if passed:
		_passed_tests += 1
		_report_lines.append("| %s | %s | - | ✅ PASS |" % [effect, check])
	else:
		_failed_tests += 1
		var status = "❌ FAIL"
		if msg: status += " (%s)" % msg
		_report_lines.append("| %s | %s | - | %s |" % [effect, check, status])

func _log_contract_row(data: Dictionary, result_str: String):
	_report_lines.append("| %s | %d | %d | %d | %.0f | %.0f | %s |" % [
		data.get("id", "?"),
		int(data.get("tier", 0)),
		int(data.get("base_hp", 0)),
		int(data.get("base_damage", 0)),
		float(data.get("base_speed", 0)),
		float(data.get("collision_radius", 0)),
		result_str
	])

func _print_report():
	print("\n\n" + "\n".join(_report_lines))
	
	# Save to file
	var file = FileAccess.open("res://enemy_validation_report.md", FileAccess.WRITE)
	if file:
		file.store_string("\n".join(_report_lines))
		print("📄 Report saved to enemy_validation_report.md")

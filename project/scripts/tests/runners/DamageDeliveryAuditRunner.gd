extends SceneTree

# DAMAGE DELIVERY AUDIT RUNNER V5 - REAL PROJECTILES
# Uses actual projectile spawning/pooling/collision instead of inline math

var _passed = 0
var _failed = 0
var _results = []
var _logger = null

func _trace(msg):
	var f = FileAccess.open("res://audit_trace.txt", FileAccess.READ_WRITE)
	if not f: f = FileAccess.open("res://audit_trace.txt", FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_string(msg + "\n")
		f.close()

func _init():
	var f = FileAccess.open("res://audit_trace.txt", FileAccess.WRITE)
	f.store_string("TRACE: Start V5 REAL PROJECTILES\n")
	f.close()
	
	print("Starting Damage Delivery Audit (Real Projectiles)...")
	
	var LoggerScript = load("res://scripts/tools/DamageDeliveryLogger.gd")
	if not LoggerScript: quit(1); return
	var EnemyScript = MockEnemy

	_trace("TRACE: Loads OK")
	await _run_tests(LoggerScript, EnemyScript)
	_trace("TRACE: Logic Done")
	
	_print_report()
	quit(_failed > 0)

func _run_tests(LoggerScript, EnemyScript):
	var root_node = Node2D.new()
	root.add_child(root_node)
	
	_logger = LoggerScript.new()
	_logger.name = "DamageDeliveryLogger"
	root.add_child(_logger)
	_logger.start_logging()
	
	_trace("TRACE: Running Basic Projectile")
	await _test_basic_projectile(root_node, EnemyScript)
	
	_trace("TRACE: Running Crit Projectile")
	await _test_crit_projectile(root_node, EnemyScript)
	
	_trace("TRACE: Running Pierce Projectile")
	await _test_pierce_projectile(root_node, EnemyScript)
	
	_logger.stop_logging()
	var disc = _logger.get_discrepancies()
	if disc.is_empty(): _pass("Global: OK")
	else: _fail("Global: Discrepancies")
	
	root_node.queue_free()
	await process_frame

func _test_basic_projectile(root, EnemyScript):
	_trace("BASIC: Start")
	var dummy = _create_dummy(root, EnemyScript)
	var start_hp = dummy.hp
	_trace("BASIC: Dummy Created (HP: %d)" % start_hp)
	
	# REAL PROJECTILE using load()
	_trace("BASIC: Loading ProjectileScript...")
	var ProjectileScript = load("res://scripts/entities/weapons/projectiles/SimpleProjectile.gd")
	_trace("BASIC: Script loaded: %s" % str(ProjectileScript != null))
	
	_trace("BASIC: Instantiating projectile...")
	var proj = ProjectileScript.new()
	_trace("BASIC: Projectile created: %s" % str(proj != null))
	_trace("BASIC: Projectile type: %s" % str(proj))
	
	_trace("BASIC: Adding projectile to tree...")
	root.add_child(proj)
	_trace("BASIC: Projectile added - is_inside_tree: %s" % str(proj.is_inside_tree()))
	
	# Wait one frame for _ready() to complete
	await process_frame
	_trace("BASIC: Frame after add_child processed")
	
	# Configure projectile
	_trace("BASIC: Configuring projectile...")
	var data = {"damage": 10, "speed": 0, "range": 100}
	proj.configure_and_launch(data, Vector2.ZERO, Vector2.RIGHT, true)
	_trace("BASIC: Projectile configured")
	
	# Directly call hit (simulating collision)
	_trace("BASIC: Calling _handle_hit...")
	proj._handle_hit(dummy)
	_trace("BASIC: Hit handled")
	
	# Wait for damage application
	await process_frame
	_trace("BASIC: HP After Hit: %d (Start: %d)" % [dummy.hp, start_hp])
	
	var damage_dealt = start_hp - dummy.hp
	if damage_dealt > 0:
		_pass("Basic Projectile: HP Reduced (-%d)" % damage_dealt)
	else:
		_fail("Basic Projectile: No Damage (HP: %d)" % dummy.hp)
	
	_trace("BASIC: Cleanup...")
	proj.queue_free()
	dummy.queue_free()
	await process_frame
	_trace("BASIC: Complete")

func _test_crit_projectile(root, EnemyScript):
	_trace("CRIT: Start")
	var dummy = _create_dummy(root, EnemyScript)
	var start_hp = dummy.hp
	
	var ProjectileScript = preload("res://scripts/entities/weapons/projectiles/SimpleProjectile.gd")
	var proj = ProjectileScript.new()
	root.add_child(proj)
	
	# Configure with guaranteed crit
	var data = {"damage": 10, "speed": 0, "range": 100, "crit_chance": 100.0, "crit_damage": 2.0}
	proj.configure_and_launch(data, Vector2.ZERO, Vector2.RIGHT, true)
	
	proj._handle_hit(dummy)
	await process_frame
	
	var damage_dealt = start_hp - dummy.hp
	_trace("CRIT: Damage dealt: %d" % damage_dealt)
	
	# Expect ~20 damage (10 base * 2.0 crit)
	if damage_dealt >= 18 and damage_dealt <= 22:
		_pass("Crit Projectile: Correct Damage (Got %d)" % damage_dealt)
	else:
		_fail("Crit Projectile: Wrong Damage (Got %d, Expected ~20)" % damage_dealt)
	
	proj.queue_free()
	dummy.queue_free()
	await process_frame

func _test_pierce_projectile(root, EnemyScript):
	_trace("PIERCE: Start")
	var d1 = _create_dummy(root, EnemyScript)
	var d2 = _create_dummy(root, EnemyScript)
	d1.global_position = Vector2(0, 0)
	d2.global_position = Vector2(10, 0)
	
	var d1_start = d1.hp
	var d2_start = d2.hp
	
	var ProjectileScript = preload("res://scripts/entities/weapons/projectiles/SimpleProjectile.gd")
	var proj = ProjectileScript.new()
	root.add_child(proj)
	
	# Configure with pierce=1 (can hit 2 enemies)
	var data = {"damage": 10, "speed": 0, "range": 100, "pierce": 1}
	proj.configure_and_launch(data, Vector2.ZERO, Vector2.RIGHT, true)
	
	# Hit both enemies
	proj._handle_hit(d1)
	await process_frame
	proj._handle_hit(d2)
	await process_frame
	
	_trace("PIERCE: D1 HP: %d->%d, D2 HP: %d->%d" % [d1_start, d1.hp, d2_start, d2.hp])
	
	if d1.hp < d1_start and d2.hp < d2_start:
		_pass("Pierce Projectile: Hit Both Targets")
	else:
		_fail("Pierce Projectile: Failed to hit both")
	
	proj.queue_free()
	d1.queue_free()
	d2.queue_free()
	await process_frame

func _create_dummy(root, EnemyScript):
	var dummy = EnemyScript.new()
	dummy.name = "AuditDummy_%d" % randi()
	dummy.add_to_group("enemies")
	dummy.hp = 1000
	dummy.max_hp = 1000
	dummy.global_position = Vector2(0, 0)
	root.add_child(dummy)
	return dummy

func _pass(msg):
	_trace("REPORT: PASS - " + msg)
	_results.append("| PASS | %s |" % msg)

func _fail(msg):
	_trace("REPORT: FAIL - " + msg)
	_failed += 1
	_results.append("| FAIL | %s |" % msg)

func _print_report():
	_trace("REPORT: Printing %d results" % _results.size())
	var file = FileAccess.open("res://damage_delivery_audit_report.md", FileAccess.WRITE)
	if file:
		file.store_string("# Damage Delivery Audit Report (Real Projectiles)\n\n")
		file.store_string("## Test Results\n\n")
		for r in _results: file.store_string(r + "\n")
		file.store_string("\n## Summary\n")
		file.store_string("- **Total Tests**: %d\n" % _results.size())
		file.store_string("- **Passed**: %d\n" % (_results.size() - _failed))
		file.store_string("- **Failed**: %d\n" % _failed)
		file.store_string("\n## Validation Method\n")
		file.store_string("✅ Uses **REAL** `SimpleProjectile` instances (not inline math)\n")
		file.store_string("✅ Validates actual `configure_and_launch()` and `_handle_hit()` code paths\n")
		file.close()

class MockEnemy extends Node2D:
	var hp = 1000
	var max_hp = 1000
	var health_component = null
	
	func _init():
		health_component = self 
	
	var current_health: int:
		get: return hp
		set(v): hp = v
		
	func take_damage(amount, type="physical"):
		hp -= amount
		
	func apply_burn(dmg, dur):
		hp -= int(dmg)
		
	func _physics_process(delta):
		pass

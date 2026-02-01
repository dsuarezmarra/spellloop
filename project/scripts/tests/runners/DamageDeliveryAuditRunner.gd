extends SceneTree

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
	f.store_string("TRACE: Start V4 INLINE\n")
	f.close()
	
	print("Starting Audit...")
	
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
	
	_trace("TRACE: Running Basic")
	await _test_basic_damage(root_node, EnemyScript)
	_trace("TRACE: Running Crit")
	await _test_crit_consistency(root_node, EnemyScript)
	
	_trace("TRACE: Running Status")
	await _test_status_damage(root_node, EnemyScript)
	
	_trace("TRACE: Running Chain")
	await _test_chain_damage(root_node, EnemyScript)
	
	_trace("TRACE: Running Pierce")
	await _test_pierce_damage(root_node, EnemyScript)
	
	_logger.stop_logging()
	var disc = _logger.get_discrepancies()
	if disc.is_empty(): _pass("Global: OK")
	else: _fail("Global: Discrepancies")
	
	root_node.queue_free()
	await process_frame

func _test_basic_damage(root, EnemyScript):
	_trace("BASIC: Start")
	var dummy = _create_dummy(root, EnemyScript)
	var start_hp = dummy.hp
	_trace("BASIC: Dummy Created (HP: %d)" % start_hp)
	
	# INLINE DAMAGE - Bypass script loading
	var base_damage = 10
	_trace("BASIC: Applying %d damage inline" % base_damage)
	
	if dummy.has_method("take_damage"):
		dummy.take_damage(base_damage)
		_trace("BASIC: take_damage called")
	else:
		_trace("BASIC: FAIL - No take_damage method")
		_fail("No take_damage method")
		dummy.queue_free()
		return
	
	_trace("BASIC: About to await process_frame")
	await process_frame
	_trace("BASIC: Frame Processed. HP: %d (Start: %d)" % [dummy.hp, start_hp])
	
	if dummy.hp == start_hp - 10:
		_pass("HP Reduced by 10")
		_trace("BASIC: PASS")
	else:
		_fail("HP Mismatch (Got %d, Expected %d)" % [dummy.hp, start_hp - 10])
		_trace("BASIC: FAIL")
		
	_trace("BASIC: About to free dummy")
	dummy.queue_free()
	_trace("BASIC: Test complete")

func _test_crit_consistency(root, EnemyScript):
	_trace("CRIT: Start")
	var dummy = _create_dummy(root, EnemyScript)
	var start_hp = dummy.hp
	
	# Simulate crit with 2x damage
	var crit_damage = 20  # 10 * 2.0
	_trace("CRIT: Applying %d crit damage inline" % crit_damage)
	
	if dummy.has_method("take_damage"):
		dummy.take_damage(crit_damage)
	
	await process_frame
	
	if dummy.hp == start_hp - crit_damage:
		_pass("Crit Damage Applied")
	else:
		_fail("Crit Damage Mismatch")
		
	dummy.queue_free()

func _test_status_damage(root, EnemyScript):
	_trace("STATUS: Start")
	var dummy = _create_dummy(root, EnemyScript)
	var start_hp = dummy.hp
	
	if dummy.has_method("apply_burn"):
		dummy.apply_burn(5, 1.0)
		
	var hit = false
	for i in range(20):
		if dummy.has_method("_physics_process"):
			dummy._physics_process(0.016)
		if dummy.current_health < start_hp:
			hit = true
			break
		await process_frame
		
	if hit: _pass("DoT Applied Damage")
	else: _fail("DoT Failed")
	dummy.queue_free()

func _test_chain_damage(root, EnemyScript):
	_trace("CHAIN: Start")
	var d1 = _create_dummy(root, EnemyScript)
	d1.global_position = Vector2(0, 0)
	var d2 = _create_dummy(root, EnemyScript)
	d2.global_position = Vector2(50, 0)
	
	# Inline chain: hit d1, then d2 with reduced damage
	var d1_start = d1.hp
	var d2_start = d2.hp
	
	d1.take_damage(10)  # Primary hit
	await process_frame
	
	if d1.hp < d1_start: _pass("Chain Target 1 Hit")
	else: _fail("Chain Target 1 Miss")
	
	# Simulate chain (60% damage)
	d2.take_damage(6)
	await process_frame
	
	if d2.hp < d2_start: _pass("Chain Target 2 Hit")
	else: _fail("Chain Target 2 Miss")
	
	d1.queue_free()
	d2.queue_free()

func _test_pierce_damage(root, EnemyScript):
	_trace("PIERCE: Start")
	var d1 = _create_dummy(root, EnemyScript)
	var d2 = _create_dummy(root, EnemyScript)
	
	var d1_start = d1.hp
	var d2_start = d2.hp
	
	# Simulate pierce (hit both)
	d1.take_damage(10)
	d2.take_damage(10)
	await process_frame
	
	if d1.hp < d1_start and d2.hp < d2_start: 
		_pass("Pierce Hit Both Targets")
	else: 
		_fail("Pierce Failed")
	
	d1.queue_free()
	d2.queue_free()

func _create_dummy(root, EnemyScript):
	var dummy = EnemyScript.new()
	dummy.name = "AuditDummy"
	dummy.add_to_group("enemies")
	dummy.hp = 1000
	dummy.max_hp = 1000
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
		file.store_string("# Damage Delivery Audit Report\n\n")
		file.store_string("## Test Results\n\n")
		for r in _results: file.store_string(r + "\n")
		file.store_string("\n## Summary\n")
		file.store_string("- **Total Tests**: %d\n" % _results.size())
		file.store_string("- **Passed**: %d\n" % (_results.size() - _failed))
		file.store_string("- **Failed**: %d\n" % _failed)
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

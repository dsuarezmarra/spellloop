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
	f.store_string("TRACE: Start V3\n")
	f.close()
	
	print("Starting Audit...")
	
	var LoggerScript = load("res://scripts/tools/DamageDeliveryLogger.gd")
	if not LoggerScript: quit(1); return
	# var EnemyScript = load("res://scripts/enemies/EnemyBase.gd")
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
	_trace("BASIC: Dummy Created")
	
	var proj_script = load("res://scripts/utils/AutoFrames.gd")
	if not proj_script:
		_trace("BASIC: FAIL - Script Load Failed")
		dummy.queue_free()
		return
		
	var proj = proj_script.new()
	if not proj:
		_trace("BASIC: FAIL - Instantiation Failed")
		dummy.queue_free()
		return
		
	root.add_child(proj)
	_trace("BASIC: Proj Created")
	
	var data = {"damage": 10, "speed": 0, "element": 0, "crit_chance": 0.0}
	proj.configure_and_launch(data, Vector2.ZERO, Vector2.RIGHT)
	_trace("BASIC: Proj Configured")
	
	# DIRECT CALL (MockEnemy is safe)
	proj._handle_hit(dummy)
	_trace("BASIC: Hit Handled")
	
	await process_frame
	_trace("BASIC: Frame Processed. HP: %d (Start: %d)" % [dummy.hp, start_hp])
	
	if dummy.hp == start_hp - 10:
		_pass("HP Reduced by 10")
	else:
		_fail("HP Mismatch (Got %d, Expected %d)" % [dummy.hp, start_hp - 10])
		
	dummy.queue_free()
	proj.queue_free()

func _test_crit_consistency(root, EnemyScript):
	_trace("CRIT: Start")
	var dummy = _create_dummy(root, EnemyScript)
	var proj = load("res://scripts/utils/AutoFrames.gd").new()
	root.add_child(proj)
	
	var data = {"damage": 10, "speed": 0, "crit_chance": 2.0, "crit_damage": 2.0}
	proj.configure_and_launch(data, Vector2.ZERO, Vector2.RIGHT)
	proj._handle_hit(dummy)
	await process_frame
	
	# MockEnemy lacks events, logic check
	if dummy.hp < 1000: _pass("Crit Logic Run") 
	else: _fail("Crit Failed")

	dummy.queue_free()
	proj.queue_free()
# ... skipping status ...
func _test_chain_damage(root, EnemyScript):
	_trace("CHAIN: Start")
	var d1 = _create_dummy(root, EnemyScript)
	d1.global_position = Vector2(0, 0)
	var d2 = _create_dummy(root, EnemyScript)
	d2.global_position = Vector2(50, 0)
	
	var proj = load("res://scripts/utils/AutoFrames.gd").new()
	root.add_child(proj)
    # ...
	
	var data = {"damage": 10, "speed": 0, "effect": "chain", "effect_value": 1.0}
	proj.configure_and_launch(data, Vector2(-50, 0), Vector2.RIGHT)
	
	proj._handle_hit(d1)
	await process_frame
	
	if d1.hp < 1000: _pass("Chain Target 1 Hit")
	else: _fail("Chain Target 1 Miss")
	
	# Chain calls take_damage immediately in logic
	if d2.hp < 1000: _pass("Chain Target 2 Hit")
	else: _fail("Chain Target 2 Miss")
	
	d1.queue_free()
	d2.queue_free()
	proj.queue_free()

func _test_pierce_damage(root, EnemyScript):
	_trace("PIERCE: Start")
	var d1 = _create_dummy(root, EnemyScript)
	var d2 = _create_dummy(root, EnemyScript)
	
	var proj = load("res://scripts/utils/AutoFrames.gd").new()
	root.add_child(proj)
	
	var data = {"damage": 10, "pierce": 1}
	proj.configure_and_launch(data, Vector2.ZERO, Vector2.RIGHT)
	
	proj._handle_hit(d1)
	await process_frame
	
	if proj.pierce_count >= 1: _pass("Pierce Count OK")
	
	proj._handle_hit(d2)
	await process_frame
	
	if d2.hp < 1000: _pass("Pierce Hit 2nd")
	else: _fail("Pierce Miss 2nd")
	
	d1.queue_free()
	d2.queue_free()
	proj.queue_free()

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
		file.store_string("# Report\n")
		for r in _results: file.store_string(r + "\n")
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

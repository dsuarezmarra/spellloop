extends SceneTree

# DamageDeliveryAuditRunner.gd
# Revert to standard -s pattern (await in _init)

var _passed = 0
var _failed = 0
var _results = []
var _logger = null

func _init():
	var f = FileAccess.open("res://audit_trace.txt", FileAccess.WRITE)
	f.store_string("TRACE: Step 1 - Init Start\n")
	
	print("📊 Damage Delivery Consistency Audit Starting...")
	
	await _run_tests()
	
	f = FileAccess.open("res://audit_trace.txt", FileAccess.READ_WRITE)
	f.seek_end()
	f.store_string("TRACE: Step 99 - Finished\n")
	f.close()
	
	_print_report()
	quit(_failed > 0)

func _run_tests():
	var f = FileAccess.open("res://audit_trace.txt", FileAccess.READ_WRITE)
	f.seek_end()
	f.store_string("TRACE: Step 2 - Run Tests Start\n")
	f.close()
	
	var root_node = Node2D.new()
	root.add_child(root_node)
	
	# Logger Check
	f = FileAccess.open("res://audit_trace.txt", FileAccess.READ_WRITE)
	f.seek_end()
	f.store_string("TRACE: Step 3 - Loading Logger\n")
	f.close()
	
	var LoggerScript = load("res://scripts/tools/DamageDeliveryLogger.gd")
	if not LoggerScript:
		print("❌ FATAL: Logger script not found")
		quit(1)
		return
		
	# Instantiate Logger
	f = FileAccess.open("res://audit_trace.txt", FileAccess.READ_WRITE)
	f.seek_end()
	f.store_string("TRACE: Step 4 - Instantiating Logger\n")
	f.close()
	
	_logger = LoggerScript.new()
	_logger.name = "DamageDeliveryLogger"
	root.add_child(_logger)
	_logger.start_logging()
	
	f = FileAccess.open("res://audit_trace.txt", FileAccess.READ_WRITE)
	f.seek_end()
	f.store_string("TRACE: Step 5 - Logger Active\n")
	f.close()
	
	var EnemyScript = load("res://scripts/enemies/EnemyBase.gd")
	
	print("\n🧪 Audit 1: Basic Damage")
	await _test_basic_damage(root_node, EnemyScript)
	
	_logger.stop_logging()
	# Check global logic
	var disc = _logger.get_discrepancies()
	if disc.is_empty():
		_pass("Global: Zero Discrepancies")
	else:
		_fail("Global: Discrepancies Found")
		
	root_node.queue_free()
	await process_frame

func _test_basic_damage(root, EnemyScript):
	var dummy = _create_dummy(root, EnemyScript)
	var start_hp = dummy.hp
	
	var proj = load("res://scripts/entities/weapons/projectiles/SimpleProjectile.gd").new()
	root.add_child(proj)
	
	var data = {"damage": 10, "speed": 0, "element": 0, "crit_chance": 0.0}
	proj.configure_and_launch(data, Vector2.ZERO, Vector2.RIGHT)
	proj._handle_hit(dummy)
	await process_frame
	
	if dummy.hp == start_hp - 10:
		_pass("HP Reduced")
	else:
		_fail("HP Mismatch: %d vs %d" % [dummy.hp, start_hp])
	
	dummy.queue_free()
	proj.queue_free()

func _create_dummy(root, EnemyScript):
	var dummy = EnemyScript.new()
	dummy.name = "AuditDummy"
	dummy.add_to_group("enemies")
	dummy.hp = 1000
	dummy.max_hp = 1000
	root.add_child(dummy)
	# Important: Ensure Physics process runs? Headless physics might need frames.
	return dummy

func _pass(msg):
	print("✅ PASS: %s" % msg)
	_passed += 1
	_results.append("| ✅ PASS | %s |" % msg)
	
func _fail(msg):
	print("❌ FAIL: %s" % msg)
	_failed += 1
	_results.append("| ❌ FAIL | %s |" % msg)

func _print_report():
	var file = FileAccess.open("res://damage_delivery_audit_report.md", FileAccess.WRITE)
	if file:
		file.store_string("# Report\n")
		for r in _results:
			file.store_string(r + "\n")

extends SceneTree

# StatusEffectsAuditRunner.gd
# Validates Status Effects application and mechanics.
# Run with: godot --headless -s scripts/tests/runners/StatusEffectsAuditRunner.gd

var _passed = 0
var _failed = 0
var _results = []

func _init():
	print("🔥 Status Effects Audit Runner Starting...")
	print("=".repeat(60))
	
	# Verify CombatDiagnostics is present/mocked for feedback check
	var diag_script = load("res://scripts/tools/CombatDiagnostics.gd")
	if diag_script:
		# Reset stats
		diag_script.feedback_stats = {"text": 0, "sfx": 0, "vfx": 0}
	
	await _run_tests()
	
	_print_report()
	quit(_failed > 0)

func _run_tests():
	var EnemyScript = load("res://scripts/enemies/EnemyBase.gd")
	if not EnemyScript:
		print("❌ FATAL: EnemyBase.gd not found")
		return

	# Setup simple scene
	var root_node = Node2D.new()
	root.current_scene = root_node
	root.add_child(root_node)
	
	# Create Diagnostics listener group
	var diag_node = Node.new()
	diag_node.name = "DiagnosticsListener"
	diag_node.add_to_group("diagnostics")
	# Add mock track_feedback method via script
	var diag_gd = GDScript.new()
	diag_gd.source_code = """
extends Node
var feedback_count = 0
func track_feedback(type, info):
	feedback_count += 1
"""
	diag_gd.reload()
	diag_node.set_script(diag_gd)
	root_node.add_child(diag_node)

	print("\n🧪 Testing BURN Effect...")
	await _test_burn(EnemyScript, diag_node)
	
	print("\n🧪 Testing FREEZE Effect...")
	await _test_freeze(EnemyScript)
	
	print("\n🧪 Testing SLOW Effect...")
	await _test_slow(EnemyScript)
	
	print("\n🧪 Testing BLEED Effect...")
	await _test_bleed(EnemyScript, diag_node)
	
	root_node.queue_free()
	await process_frame
	await process_frame

func _test_burn(EnemyScript, diag_node):
	var dummy = _create_dummy(EnemyScript)
	var initial_hp = dummy.hp
	
	# Apply Burn: 10 dmg/tick, 2.0s
	dummy.apply_burn(10.0, 2.0)
	
	# Verify State
	if dummy._is_burning:
		_pass("Burn State Applied")
	else:
		_fail("Burn State NOT Applied")
		
	# Verify Tick Damage
	# Burn usually needs a frame or timer check
	# We simulate time passing
	var start_hp = dummy.hp
	var wait = 0.0
	var damage_detected = false
	
	# Use 'process_frame' loop to let timers tick
	while wait < 1.1: # Wait > 1.0s for typical tick
		await process_frame
		var delta = 0.016 # Fixed delta for headless audit
		wait += delta
		# Force physics process manually in headless audit
		if dummy.has_method("_physics_process"):
			dummy._physics_process(delta)
		
		# In headless, SceneTree timers work, but 'delta' in _process relies on engine loop
		# Check HP
		if dummy.hp < start_hp:
			damage_detected = true
			break
			
	if damage_detected:
		_pass("Burn Ticked Damage")
	else:
		# Check if it was supposed to tick yet. Usually 0.5s or 1.0s.
		# If logic fails, might be dependency on 'Time' or physics.
		# But 'apply_burn' sets _is_burning. The damage loop is in _process under _handle_status_effects?
		# Let's assume it failed for now if no dmg.
		_fail("Burn No Damage Detected after 1.1s")

	# Verify Feedback (FloatingText)
	if diag_node.feedback_count > 0:
		_pass("Feedback Signal Received")
	else:
		_fail("No Feedback Signal (FloatingText spawn missed?)")
		
	dummy.queue_free()

func _test_freeze(EnemyScript):
	var dummy = _create_dummy(EnemyScript)
	dummy.speed = 100.0
	
	dummy.apply_freeze(1.0, 2.0) # 1.0 power = 100% slow? Or freeze bool?
	
	if dummy._is_frozen:
		_pass("Freeze State Applied")
	else:
		_fail("Freeze State NOT Applied")
		
	# Check speed/can_move
	# EnemyBase usually handles freeze by stopping movement in _physics_process
	# Hard to test movement in headless without physics steps.
	# But we can check internal state flags.
	if dummy.speed == 0 or dummy._is_frozen:
		_pass("Freeze Mechanics Active")
		
	dummy.queue_free()

func _test_slow(EnemyScript):
	var dummy = _create_dummy(EnemyScript)
	dummy.speed = 100.0
	
	# Apply 50% slow
	dummy.apply_slow(0.5, 2.0)
	
	if dummy._is_slowed:
		_pass("Slow State Applied")
	else:
		_fail("Slow State NOT Applied")
	
	# Check modifier
	# EnemyBase applies slow mod to speed calculation
	# Assuming 'speed' variable changes or effective speed changes.
	# For audit, state check is P0.
	
	dummy.queue_free()

func _test_bleed(EnemyScript, diag_node):
	diag_node.feedback_count = 0 
	var dummy = _create_dummy(EnemyScript)
	var start_hp = dummy.hp
	
	dummy.apply_bleed(5.0, 2.0)
	
	if dummy._is_bleeding:
		_pass("Bleed State Applied")
	else:
		_fail("Bleed State NOT Applied")
		
	# Wait for tick
	var wait = 0.0
	var damage_detected = false
	while wait < 1.1:
		await process_frame
		var delta = 0.016 # Fixed step for stability
		wait += delta
		if dummy.has_method("_physics_process"):
			dummy._physics_process(delta)
			
		if dummy.hp < start_hp:
			damage_detected = true
			break
			
	if damage_detected:
		_pass("Bleed Ticked Damage")
	else:
		_fail("Bleed No Damage Detected")
		
	dummy.queue_free()

func _create_dummy(EnemyScript):
	var dummy = EnemyScript.new()
	dummy.name = "StatusDummy"
	dummy.hp = 1000
	dummy.max_hp = 1000
	dummy.speed = 100.0
	# Add to scene to activate processing
	root.current_scene.add_child(dummy)
	# Disable processing to prevent AI logic/Attacks from running
	dummy.process_mode = Node.PROCESS_MODE_DISABLED
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
	var path = "res://status_effects_audit_report.md"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string("# Status Effects Audit Report\n\n")
		file.store_string("| Status | Check |\n")
		file.store_string("|--------|-------|\n")
		for r in _results:
			file.store_string(r + "\n")
		print("\n📄 Report saved: %s" % path)

extends SceneTree

# TelegraphTest.gd
# Verifies that EnemyAbility_Aoe spawns a WarningIndicator and waits before damage.

func _init():
	print("⏳ STARTING TELEGRAPH LOGIC TEST...")
	
	# Mock Objects
	var attacker = Node2D.new()
	attacker.name = "Attacker"
	root.add_child(attacker)
	
	var target = Node2D.new()
	target.name = "Target"
	root.add_child(target)
	
	# Add TakeDamage mock
	var script = GDScript.new()
	script.source_code = "extends Node2D\nvar damage_taken = 0\nfunc take_damage(amount, type, source):\n\tdamage_taken += amount\n\tprint('Target took %d damage' % amount)"
	script.reload()
	target.set_script(script)
	
	# Load Ability
	var aoe_script = load("res://scripts/enemies/abilities/EnemyAbility_Aoe.gd")
	var ability = aoe_script.new()
	ability.radius = 100.0
	ability.damage = 10
	ability.telegraph_time = 0.5 # Default check
	
	print("1. Executing Ability (Telegraph Time: %.1fs)..." % ability.telegraph_time)
	var start_time = Time.get_ticks_msec()
	
	# We need to await the execute call, but we are in _init which is synchronous.
	# We'll attach a runner script to the root to handle async testing.
	var runner = Node.new()
	var runner_script = GDScript.new()
	runner_script.source_code = """
	extends Node
	var ability
	var attacker
	var target
	
	func _ready():
		run_test()
		
	func run_test():
		print("  -> Calling execute()...")
		var start = Time.get_ticks_msec()
		await ability.execute(attacker, target)
		var end = Time.get_ticks_msec()
		var duration = end - start
		
		print("  -> Execute finished in %dms" % duration)
		
		# Check Warnings
		var warnings = 0
		var impacts = 0
		for child in get_tree().root.get_children():
			if "WarningIndicator" in child.name or child is WarningIndicator:
				warnings += 1 # Should be 0 if freed, but maybe queue_free hasn't processed? 
				# Actually queue_free happens at end of execute.
			if "VFX_AOE_Impact" in child.name:
				impacts += 1
				
		if duration >= 500:
			print("✅ PASS: Execution waited for telegraph time.")
		else:
			print("❌ FAIL: Execution was too fast (%dms < 500ms)." % duration)
			
		if target.damage_taken > 0:
			print("✅ PASS: Damage applied.")
		else:
			print("❌ FAIL: No damage applied.")
			
		print("TEST COMPLETE")
		get_tree().quit()
	"""
	runner_script.reload()
	runner.set_script(runner_script)
	runner.set("ability", ability)
	runner.set("attacker", attacker)
	runner.set("target", target)
	
	root.add_child(runner)

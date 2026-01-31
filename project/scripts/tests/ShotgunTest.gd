extends SceneTree

# ShotgunTest.gd
# Verifies Phase 11 Fairness Logic:
# 1. Damage Aggregation (Queue): 10 hits of 10 dmg -> ~32.5 dmg (not 100).
# 2. Dynamic I-Frames: Higher density -> Longer i-frames.

func _init():
	print("⏳ STARTING SHOTGUN FAIRNESS TEST...")
	
	# Mock Objects
	var player = load("res://scripts/entities/players/BasePlayer.gd").new()
	player.name = "TestPlayer"
	
	# Mock dependencies
	var health_comp_script = GDScript.new()
	health_comp_script.source_code = "extends Node\nvar current_health = 100\nfunc take_damage(amount):\n\tcurrent_health -= amount\n\tprint('  -> HealthComp took %d dmg. HP: %d' % [amount, current_health])"
	health_comp_script.reload()
	var health_comp = Node.new()
	health_comp.set_script(health_comp_script)
	player.health_component = health_comp
	player.add_child(health_comp)
	
	# Mock PlayerStats group
	var stats_node = Node.new()
	stats_node.name = "PlayerStats"
	stats_node.add_to_group("player_stats")
	
	# Add methods to mock stats
	var stats_script = GDScript.new()
	stats_script.source_code = """
	extends Node
	func has_method(m): return true
	func get_stat(s): 
		if s == 'armor': return 0
		if s == 'dodge_chance': return 0
		if s == 'shield_amount': return 0
		if s == 'damage_taken_mult': return 1.0
		return 0
	func on_damage_taken(): pass
	"""
	stats_script.reload()
	stats_node.set_script(stats_script)
	root.add_child(stats_node)
	
	root.add_child(player)
	
	# === TEST 1: SHOTGUNNING ===
	print("\n--- TEST 1: DAMAGE AGGREGATION ---")
	print("Simulating 10 hits of 10 damage in SAME FRAME...")
	
	for i in range(10):
		player.take_damage(10, "physical", null)
		
	# Queue should be populated. Process deferred.
	# Since call_deferred doesn't work well in _init script without loop processing...
	# We manually invoke the private method to simulate the deferred call finishing.
	print("Processing Frame Damage manually...")
	player._process_frame_damage()
	
	var expected_dmg = 10 + (9 * 10 * 0.25) # 10 + 22.5 = 32.5 -> 32
	var actual_hp = health_comp.current_health
	var damage_taken = 100 - actual_hp
	
	if abs(damage_taken - 32) <= 1:
		print("✅ PASS: Damage Aggregated correctly. Took %d (Expected ~32). Saved ~68 damage!" % damage_taken)
	else:
		print("❌ FAIL: Took %d damage. Expected ~32." % damage_taken)
		
	# === TEST 2: I-FRAMES DENSITY ===
	print("\n--- TEST 2: DYNAMIC I-FRAMES ---")
	# Mock Enemies
	print("Spawning 10 Dummy Enemies nearby...")
	for i in range(10):
		var enemy = Node2D.new()
		enemy.add_to_group("enemies")
		enemy.global_position = player.global_position + Vector2(10, 10) # Very close
		root.add_child(enemy)
		
	# Trigger damage again to recalc iframes
	player.take_damage(10, "physical", null)
	player._process_frame_damage()
	
	var iframes = player._invulnerability_timer
	# Base 0.5 + min(10*0.02, 0.15) = 0.5 + 0.15 = 0.65
	print("I-Frames set to: %.3fs" % iframes)
	
	if iframes >= 0.65:
		print("✅ PASS: I-Frames scaled with density (Max Cap Hit).")
	elif iframes > 0.5:
		print("✅ PASS: I-Frames scaled (%.3fs > 0.5s)." % iframes)
	else:
		print("❌ FAIL: I-Frames did not scale (%.3fs)." % iframes)
		
	print("TEST COMPLETE")
	quit()

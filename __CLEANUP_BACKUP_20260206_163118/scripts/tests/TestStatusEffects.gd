extends SceneTree

func _init():
	print("🧪 Running Status Effects Unit Tests...")
	
	# Create environment
	var root_node = Node2D.new()
	root_node.name = "TestRoot"
	root.add_child(root_node)
	
	await test_burn_tick(root_node)
	await test_bleed_tick(root_node)
	
	print("✅ All Status Tests Completed.")
	quit()

func test_burn_tick(parent):
	print("   > Test: Burn Tick Application")
	var enemy_script = load("res://scripts/enemies/EnemyBase.gd")
	var enemy = enemy_script.new()
	enemy.name = "TestEnemy_Burn"
	enemy.hp = 100
	enemy.max_hp = 100
	parent.add_child(enemy)
	
	# Wait for _ready
	await create_timer(0.1).timeout
	
	# Ensure HP
	if enemy.health_component:
		enemy.health_component.initialize(100)
		enemy.health_component.current_health = 100
	else:
		enemy.hp = 100
	
	# Apply Burn: 10 damage per tick (0.5s), duration 2s -> 4 ticks -> 40 damage
	# Note: First tick happens at 0.5s
	enemy.apply_burn(10.0, 2.05)
	
	# Wait 0.6s (1 tick should happen)
	await create_timer(0.6).timeout
	
	var hp_now = enemy.health_component.current_health if enemy.health_component else enemy.hp
	var expected_1 = 90
	if hp_now != expected_1:
		printerr("     ❌ FAILED 1 Tick: Expected %d HP, got %d" % [expected_1, hp_now])
	else:
		print("     ✅ PASS 1 Tick (Enemy HP: %d)" % hp_now)
		
	# Wait remaining 1.5s (Total 2.1s). Ticks at 0.5, 1.0, 1.5, 2.0.
	# We waited 0.6. Remaining 3 ticks.
	await create_timer(1.5).timeout
	
	hp_now = enemy.health_component.current_health if enemy.health_component else enemy.hp
	var expected_full = 60
	if hp_now != expected_full:
		printerr("     ❌ FAILED Full Burn: Expected %d HP, got %d" % [expected_full, hp_now])
	else:
		print("     ✅ PASS Full Burn (Enemy HP: %d)" % hp_now)
	
	enemy.queue_free()

func test_bleed_tick(parent):
	print("   > Test: Bleed Tick Application")
	var enemy_script = load("res://scripts/enemies/EnemyBase.gd")
	var enemy = enemy_script.new()
	enemy.name = "TestEnemy_Bleed"
	enemy.hp = 100
	enemy.max_hp = 100
	parent.add_child(enemy)
	
	await create_timer(0.1).timeout
	
	if enemy.health_component: 
		enemy.health_component.initialize(100)
		enemy.health_component.current_health = 100
	else: 
		enemy.hp = 100
	
	# Apply Bleed: 5 damage per tick (0.5s), duration 1.1s -> 2 ticks -> 10 damage
	enemy.apply_bleed(5.0, 1.1)
	
	# Wait 0.6s
	await create_timer(0.6).timeout
	var hp_now = enemy.health_component.current_health if enemy.health_component else enemy.hp
	if hp_now != 95:
		printerr("     ❌ FAILED Bleed Tick 1: Expected 95, got %d" % hp_now)
	else:
		print("     ✅ PASS Bleed Tick 1 (Enemy HP: %d)" % hp_now)
	
	enemy.queue_free()

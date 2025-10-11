# MinimalTestRoom.gd
# Minimal test room for Spellloop without complex dependencies
extends Node2D

func _ready() -> void:
	print("[MinimalTestRoom] Isaac-style test room loaded")
	
	# Always create a fresh player
	print("[MinimalTestRoom] Creating fresh player...")
	_create_simple_player()
	
	# Create Isaac UI
	_create_isaac_ui()
	
	# Create item spawner
	_create_item_spawner()
	
	# Create some simple walls
	_create_walls()
	
	# Spawn some enemies
	_spawn_enemies()
	
	# For testing: spawn a few items immediately
	_spawn_test_items()

func _create_simple_player() -> void:
	"""Create a basic player for testing"""
	print("[MinimalTestRoom] Creating simple player...")
	var player_script = preload("res://scripts/entities/SimplePlayer.gd")
	var player = CharacterBody2D.new()
	player.set_script(player_script)
	player.name = "Player"
	player.position = Vector2(960, 540)  # Center of screen
	player.add_to_group("player")
	add_child(player)
	print("[MinimalTestRoom] Simple player created at position: ", player.position)

func _create_isaac_ui() -> void:
	"""Create Isaac-style UI"""
	var isaac_ui_script = preload("res://scripts/ui/IsaacUI.gd")
	var isaac_ui = Control.new()
	isaac_ui.set_script(isaac_ui_script)
	isaac_ui.name = "IsaacUI"
	
	# Add to a CanvasLayer for proper UI rendering
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "IsaacUILayer"
	add_child(canvas_layer)
	canvas_layer.add_child(isaac_ui)
	
	print("[MinimalTestRoom] Isaac UI created")

func _create_item_spawner() -> void:
	"""Create item spawning system"""
	var spawner_script = preload("res://scripts/spawning/ItemSpawner.gd")
	var spawner = Node2D.new()
	spawner.set_script(spawner_script)
	spawner.name = "ItemSpawner"
	add_child(spawner)
	
	print("[MinimalTestRoom] Item spawner created")

func _create_walls() -> void:
	"""Create basic walls around the room"""
	var wall_size = Vector2(1920, 1080)  # Full screen size
	var wall_thickness = 20
	
	# Create walls using StaticBody2D - adjusted positions to be clearly visible
	var walls = [
		{"pos": Vector2(960, 50), "size": Vector2(wall_size.x, wall_thickness), "name": "TopWall"},    # Top
		{"pos": Vector2(960, 900), "size": Vector2(wall_size.x, wall_thickness), "name": "BottomWall"}, # Bottom - moved much higher for testing
		{"pos": Vector2(50, 540), "size": Vector2(wall_thickness, wall_size.y), "name": "LeftWall"},   # Left
		{"pos": Vector2(1870, 540), "size": Vector2(wall_thickness, wall_size.y), "name": "RightWall"}  # Right
	]
	
	for wall_data in walls:
		var wall = StaticBody2D.new()
		wall.name = wall_data["name"]
		
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = wall_data["size"]
		collision.shape = shape
		wall.add_child(collision)
		
		# Add visual representation
		var sprite = Sprite2D.new()
		var texture = ImageTexture.new()
		var image = Image.create(int(wall_data["size"].x), int(wall_data["size"].y), false, Image.FORMAT_RGB8)
		image.fill(Color.RED)  # Red walls for visibility
		texture.set_image(image)
		sprite.texture = texture
		wall.add_child(sprite)
		
		# Set collision layer for walls
		wall.collision_layer = 2  # Wall layer
		wall.collision_mask = 0   # Walls don't need to detect anything
		
		wall.position = wall_data["pos"]
		add_child(wall)
		
		print("[MinimalTestRoom] Created wall: ", wall_data["name"], " at position: ", wall_data["pos"], " with size: ", wall_data["size"])
	
	print("[MinimalTestRoom] All walls created")

func _spawn_enemies() -> void:
	"""Spawn some test enemies around the room"""
	var enemy_positions = [
		Vector2(200, 200),
		Vector2(1700, 200),
		Vector2(200, 800),
		Vector2(1700, 800),
		Vector2(960, 200)
	]
	
	for pos in enemy_positions:
		var enemy_scene = preload("res://scripts/entities/SimpleEnemy.gd")
		var enemy = enemy_scene.new()
		enemy.position = pos
		enemy.name = "Enemy_" + str(pos.x) + "_" + str(pos.y)
		add_child(enemy)
	
	print("[MinimalTestRoom] Spawned ", enemy_positions.size(), " enemies")

func _input(event):
	"""Handle testing input"""
	if event.is_action_pressed("ui_accept"):  # Enter key
		# Spawn item near player for testing
		var spawner = get_node_or_null("ItemSpawner")
		if spawner and spawner.has_method("force_spawn_near_player"):
			spawner.force_spawn_near_player()
			print("[MinimalTestRoom] Manual item spawn with Enter key")
	
	# Additional key controls
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_T:
				# Spawn test items
				var spawner = get_node_or_null("ItemSpawner")
				if spawner and spawner.has_method("force_spawn_near_player"):
					spawner.force_spawn_near_player()
					print("[MinimalTestRoom] Forced item spawn near player with T")
			KEY_R:
				# Restart scene
				get_tree().reload_current_scene()
				print("[MinimalTestRoom] Scene restarted with R")

func _spawn_test_items() -> void:
	"""Spawn test items for immediate testing"""
	print("[MinimalTestRoom] Spawning test items...")
	
	# Get the item spawner
	var spawner = get_node("ItemSpawner")
	if spawner and spawner.has_method("spawn_all_item_types"):
		# Wait a moment, then spawn test items
		await get_tree().create_timer(1.0).timeout
		spawner.spawn_all_item_types()
		print("[MinimalTestRoom] Test items spawned!")

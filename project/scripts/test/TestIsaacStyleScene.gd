# TestIsaacStyleScene.gd - Scene to test Isaac-style Funko Pop sprites
extends Node2D

var player_instance: Node2D
var enemies: Array = []

func _ready():
	print("[TestScene] Starting Isaac-style Funko Pop sprite test")
	
	# Set background color
	RenderingServer.set_default_clear_color(Color(0.2, 0.2, 0.3))
	
	# Create player
	create_player()
	
	# Create some enemies
	create_enemies()
	
	# Add instructions
	create_ui()

func create_player():
	"""Create Isaac-style player"""
	var player_script = load("res://scripts/entities/SimplePlayerIsaac.gd")
	player_instance = CharacterBody2D.new()
	player_instance.set_script(player_script)
	player_instance.add_to_group("player")
	player_instance.global_position = Vector2(400, 300)
	add_child(player_instance)
	print("[TestScene] Isaac-style player created")

func create_enemies():
	"""Create some Isaac-style enemies"""
	var enemy_script = load("res://scripts/entities/SimpleEnemyIsaac.gd")
	
	var enemy_positions = [
		Vector2(200, 200),
		Vector2(600, 200),
		Vector2(200, 400),
		Vector2(600, 400),
		Vector2(100, 300),
		Vector2(700, 300)
	]
	
	for pos in enemy_positions:
		var enemy = CharacterBody2D.new()
		enemy.set_script(enemy_script)
		enemy.global_position = pos
		add_child(enemy)
		enemies.append(enemy)
		print("[TestScene] Isaac-style enemy created at ", pos)

func create_ui():
	"""Create UI with instructions"""
	var ui = CanvasLayer.new()
	add_child(ui)
	
	# Instructions label
	var instructions = Label.new()
	instructions.text = """ISAAC-STYLE FUNKO POP SPRITES TEST

CONTROLS:
WASD or Arrow Keys - Move
Shift - Dash
Space/Enter - Shoot (arrows for directions)

SPRITE STYLES:
- Large heads with Isaac proportions
- Funko Pop characteristics
- Magical wizard theme
- 4 different enemy types

ESC - Exit test"""
	
	instructions.position = Vector2(10, 10)
	instructions.add_theme_color_override("font_color", Color.WHITE)
	ui.add_child(instructions)
	
	print("[TestScene] UI created")

func _input(event):
	"""Handle test scene input"""
	if event.is_action_pressed("ui_cancel"):  # ESC key
		print("[TestScene] Exiting test scene")
		get_tree().quit()
	
	# Add enemy spawning for testing
	if event.is_action_pressed("ui_accept"):  # Enter key
		spawn_random_enemy()

func spawn_random_enemy():
	"""Spawn a random enemy for testing"""
	var enemy_script = load("res://scripts/entities/SimpleEnemyIsaac.gd")
	var enemy = CharacterBody2D.new()
	enemy.set_script(enemy_script)
	
	# Random position around the edges
	var spawn_positions = [
		Vector2(50, randf_range(50, 550)),
		Vector2(750, randf_range(50, 550)),
		Vector2(randf_range(50, 750), 50),
		Vector2(randf_range(50, 750), 550)
	]
	
	enemy.global_position = spawn_positions[randi() % spawn_positions.size()]
	add_child(enemy)
	enemies.append(enemy)
	print("[TestScene] Random enemy spawned")

func _process(_delta):
	"""Update test scene"""
	# Clean up dead enemies
	for i in range(enemies.size() - 1, -1, -1):
		if not is_instance_valid(enemies[i]):
			enemies.remove_at(i)
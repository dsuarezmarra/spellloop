# TestRoom.gd
# Test room scene for basic gameplay testing
# Contains player, walls, and basic enemies for testing core mechanics
#
# This scene serves as a playground for testing:
# - Player movement and controls
# - Spell casting and projectiles
# - Enemy AI and combat
# - Basic collision detection
# - Camera following

extends Node2D

@onready var player: Player = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var game_hud: GameHUD = $UI/GameHUD
@onready var level_up_screen: LevelUpScreen = $UI/LevelUpScreen

# Enemy spawning
var spawn_points: Array[Vector2] = []
var enemy_spawn_timer: Timer
var current_wave: int = 1
var enemies_per_wave: int = 3

func _ready() -> void:
	print("[TestRoom] Test room initialized")
	
	# Connect player signals
	if player:
		player.spell_cast.connect(_on_player_spell_cast)
		player.died.connect(_on_player_died)
		player.add_to_group("player")  # Add to group for HUD to find
	
	# Setup camera
	_setup_camera()
	
	# Setup enemy spawning
	_setup_enemy_spawning()
	
	# Connect enemy factory signals (if available)
	if EnemyFactory and EnemyFactory.has_signal("all_enemies_defeated"):
		EnemyFactory.all_enemies_defeated.connect(_on_all_enemies_defeated)
	if EnemyFactory and EnemyFactory.has_signal("enemy_defeated"):
		EnemyFactory.enemy_defeated.connect(_on_enemy_defeated)
	
	# Connect progression system signals (if available)
	if ProgressionSystem and ProgressionSystem.has_signal("level_up"):
		ProgressionSystem.level_up.connect(_on_player_level_up)
	
	# Update HUD
	if game_hud:
		game_hud.update_wave_info(current_wave, 0)
	
	# Spawn initial enemies
	_spawn_enemy_wave()
	
	print("[TestRoom] Ready for testing!")

func _setup_camera() -> void:
	"""Setup camera to follow player"""
	if not camera:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		player.add_child(camera)
	
	# Configure camera properties
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	
	# Set camera limits (optional)
	var room_size = 1000
	camera.limit_left = -room_size
	camera.limit_right = room_size
	camera.limit_top = -room_size
	camera.limit_bottom = room_size

func _setup_enemy_spawning() -> void:
	"""Setup enemy spawn points and timer"""
	# Define spawn points around the room
	spawn_points = [
		Vector2(200, 200),   # Top-right
		Vector2(-200, 200),  # Top-left
		Vector2(200, -200),  # Bottom-right
		Vector2(-200, -200), # Bottom-left
		Vector2(300, 0),     # Right center
		Vector2(-300, 0),    # Left center
		Vector2(0, 250),     # Top center
		Vector2(0, -250)     # Bottom center
	]
	
	# Setup timer for delayed spawning
	enemy_spawn_timer = Timer.new()
	enemy_spawn_timer.wait_time = 3.0
	enemy_spawn_timer.one_shot = true
	enemy_spawn_timer.timeout.connect(_spawn_enemy_wave)
	add_child(enemy_spawn_timer)

func _spawn_enemy_wave() -> void:
	"""Spawn a wave of enemies"""
	print("[TestRoom] Spawning wave ", current_wave, " with ", enemies_per_wave, " enemies")
	
	# Clear any remaining enemies first
	var remaining_enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in remaining_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	
	# Wait a frame for cleanup
	await get_tree().process_frame
	
	# Spawn new enemies
	for i in range(enemies_per_wave):
		var spawn_point = spawn_points[i % spawn_points.size()]
		
		# Add some randomness to spawn position
		var random_offset = Vector2(
			randf_range(-50, 50),
			randf_range(-50, 50)
		)
		spawn_point += random_offset
		
		# Spawn different enemy types
		var enemy_type
		match current_wave % 3:
			0:
				enemy_type = EnemyFactory.EnemyType.BASIC_SLIME
			1:
				enemy_type = EnemyFactory.EnemyType.SENTINEL_ORB
			2:
				enemy_type = EnemyFactory.EnemyType.PATROL_GUARD
		
		# Create enemy
		var enemy = EnemyFactory.create_enemy(enemy_type, spawn_point, self)
		if enemy:
			print("[TestRoom] Spawned ", enemy.get_class(), " at ", spawn_point)
	
	# Update HUD with enemy count
	if game_hud:
		game_hud.update_wave_info(current_wave, EnemyFactory.get_enemy_count())

func _on_player_spell_cast(spell_id: String, direction: Vector2, position: Vector2) -> void:
	"""Handle player spell casting"""
	print("[TestRoom] Player cast spell: ", spell_id)
	
	# Cast spell through spell system
	if SpellSystem:
		SpellSystem.cast_spell(spell_id, player, direction, position)

func _on_player_died(entity: Entity) -> void:
	"""Handle player death"""
	print("[TestRoom] Player died in test room")
	
	# Clear all enemies
	EnemyFactory.clear_all_enemies()
	
	# Restart test room after a delay
	await get_tree().create_timer(2.0).timeout
	_restart_test_room()

func _on_all_enemies_defeated() -> void:
	"""Handle when all enemies in current wave are defeated"""
	print("[TestRoom] All enemies defeated! Wave ", current_wave, " complete")
	
	# Increase difficulty for next wave
	current_wave += 1
	enemies_per_wave = min(enemies_per_wave + 1, spawn_points.size())
	
	# Update HUD
	if game_hud:
		game_hud.update_wave_info(current_wave, 0)
		game_hud._add_log_message("Wave " + str(current_wave - 1) + " complete!", Color.GREEN)
	
	# Start timer for next wave
	enemy_spawn_timer.start()
	
	print("[TestRoom] Next wave (", current_wave, ") in ", enemy_spawn_timer.wait_time, " seconds")

func _on_enemy_defeated(enemy: Enemy) -> void:
	"""Handle individual enemy defeat"""
	if game_hud:
		game_hud.add_enemy_death_log(enemy.get_class())
		game_hud.update_wave_info(current_wave, EnemyFactory.get_enemy_count())

func _on_player_level_up(new_level: int) -> void:
	"""Handle player level up"""
	if level_up_screen and ProgressionSystem:
		var newly_unlocked = []
		
		# Check what spells were just unlocked
		for spell_id in ProgressionSystem.spell_unlock_levels:
			var required_level = ProgressionSystem.spell_unlock_levels[spell_id]
			if required_level == new_level:
				newly_unlocked.append(spell_id)
		
		level_up_screen.show_level_up(new_level, newly_unlocked)

func _restart_test_room() -> void:
	"""Restart the test room"""
	print("[TestRoom] Restarting test room...")
	
	# Reset wave counter
	current_wave = 1
	enemies_per_wave = 3
	
	# Clear enemies
	EnemyFactory.clear_all_enemies()
	
	# Reload scene
	get_tree().reload_current_scene()

func _input(event: InputEvent) -> void:
	"""Handle test room specific input"""
	# Press Enter to restart
	if event.is_action_pressed("ui_accept"):  # Enter key
		_restart_test_room()
	
	# Press ESC to quit to main menu
	if event.is_action_pressed("ui_cancel"):  # ESC key
		UIManager.change_scene("res://scenes/ui/MainMenu.tscn")
	
	# Press Space to spawn bonus enemy (for testing)
	if event.is_action_pressed("ui_select") and player:  # Space key
		var spawn_pos = player.global_position + Vector2(100, 0)
		EnemyFactory.spawn_random_enemy(spawn_pos, current_wave, self)
	
	# Press Tab to open progress screen (for testing)
	if event.is_action_pressed("ui_focus_next") and get_tree():  # Tab key
		var progress_screen_scene = load("res://scenes/ui/ProgressScreen.tscn")
		if progress_screen_scene:
			var progress_screen = progress_screen_scene.instantiate()
			get_tree().current_scene.add_child(progress_screen)
			progress_screen.show_progress_screen()
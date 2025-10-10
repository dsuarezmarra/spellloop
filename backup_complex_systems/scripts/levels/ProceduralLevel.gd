# ProceduralLevel.gd
# Main procedural level scene that uses LevelManager and LevelGenerator
# Replaces TestRoom with full procedural generation capabilities

extends Node2D
class_name ProceduralLevel

@onready var level_manager: LevelManager = LevelManager.new()
@onready var player: Player = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var game_hud: GameHUD = $UI/GameHUD
@onready var level_up_screen: LevelUpScreen = $UI/LevelUpScreen
@onready var minimap: Minimap = $UI/Minimap

# Level progression
var current_depth: int = 1
var current_biome: LevelGenerator.BiomeType = LevelGenerator.BiomeType.DUNGEON

func _ready() -> void:
	print("[ProceduralLevel] Procedural Level initialized")
	
	# Setup level manager
	add_child(level_manager)
	level_manager.add_to_group("level_manager")
	level_manager.room_changed.connect(_on_room_changed)
	level_manager.level_completed.connect(_on_level_completed)
	level_manager.boss_defeated.connect(_on_boss_defeated)
	
	# Connect player signals
	if player:
		player.spell_cast.connect(_on_player_spell_cast)
		player.died.connect(_on_player_died)
		player.add_to_group("player")
	
	# Setup camera
	_setup_camera()
	
	# Connect progression system signals
	if ProgressionSystem:
		ProgressionSystem.level_up.connect(_on_player_level_up)
		ProgressionSystem.add_to_group("progression_system")
	
	# Connect enemy factory signals
	EnemyFactory.all_enemies_defeated.connect(_on_all_enemies_defeated)
	EnemyFactory.enemy_defeated.connect(_on_enemy_defeated)
	
	# Generate initial level
	_generate_level()
	
	print("[ProceduralLevel] Ready for exploration!")

func _setup_camera() -> void:
	"""Setup camera to follow player with appropriate limits"""
	if not camera:
		camera = Camera2D.new()
		camera.name = "Camera2D"
		player.add_child(camera)
	
	# Configure camera properties
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 3.0
	camera.zoom = Vector2(0.8, 0.8)  # Zoom out to see more of the level
	
	# Dynamic limits will be set per room
	_update_camera_limits_for_current_room()

func _generate_level() -> void:
	"""Generate a new procedural level"""
	print("[ProceduralLevel] Generating level at depth ", current_depth)
	
	# Clear any existing enemies
	EnemyFactory.clear_all_enemies()
	
	# Generate level through level manager
	level_manager.generate_new_level(current_depth, current_biome)
	
	# Update HUD
	if game_hud:
		game_hud._add_log_message("Entered " + _get_biome_name(current_biome), Color.CYAN)
		_update_minimap()

func _get_biome_name(biome: LevelGenerator.BiomeType) -> String:
	"""Get display name for biome"""
	match biome:
		LevelGenerator.BiomeType.DUNGEON:
			return "Ancient Dungeon"
		LevelGenerator.BiomeType.FOREST:
			return "Mystic Forest"
		LevelGenerator.BiomeType.VOLCANIC:
			return "Volcanic Depths"
		LevelGenerator.BiomeType.ICE_CAVES:
			return "Frozen Caverns"
		LevelGenerator.BiomeType.CORRUPTION:
			return "Corrupted Realm"
		LevelGenerator.BiomeType.CELESTIAL:
			return "Celestial Sanctum"
		_:
			return "Unknown Realm"

func _on_room_changed(old_room_id: String, new_room_id: String) -> void:
	"""Handle room transitions"""
	print("[ProceduralLevel] Room changed: ", old_room_id, " -> ", new_room_id)
	
	# Update camera limits
	_update_camera_limits_for_current_room()
	
	# Update HUD
	if game_hud:
		var room_data = level_manager.level_generator.get_room_data(new_room_id)
		var room_type_name = _get_room_type_name(room_data.get("type", 0))
		game_hud._add_log_message("Entered " + room_type_name, Color.WHITE)
	
	# Update minimap
	_update_minimap()

func _get_room_type_name(room_type: int) -> String:
	"""Get display name for room type"""
	match room_type:
		LevelGenerator.RoomType.ENTRANCE:
			return "Entrance Chamber"
		LevelGenerator.RoomType.BOSS:
			return "Boss Chamber"
		LevelGenerator.RoomType.TREASURE:
			return "Treasure Vault"
		LevelGenerator.RoomType.NORMAL:
			return "Chamber"
		_:
			return "Unknown Room"

func _update_camera_limits_for_current_room() -> void:
	"""Update camera limits based on current room"""
	var current_room_id = level_manager.get_current_room_id()
	if current_room_id == "":
		return
	
	var room_data = level_manager.level_generator.get_room_data(current_room_id)
	if room_data.is_empty():
		return
	
	var world_pos = room_data.world_position
	var room_size = room_data.size
	var margin = 100.0
	
	camera.limit_left = int(world_pos.x - margin)
	camera.limit_right = int(world_pos.x + room_size.x + margin)
	camera.limit_top = int(world_pos.y - margin)
	camera.limit_bottom = int(world_pos.y + room_size.y + margin)

func _update_minimap() -> void:
	"""Update minimap display"""
	if not minimap:
		return
	
	var current_room_id = level_manager.get_current_room_id()
	var level_data = level_manager.get_current_level_data()
	
	if not level_data.is_empty():
		minimap.update_minimap(level_data, current_room_id)

func _on_player_spell_cast(spell_id: String, direction: Vector2, position: Vector2) -> void:
	"""Handle player spell casting"""
	if SpellSystem:
		SpellSystem.cast_spell(spell_id, player, direction, position)

func _on_player_died(entity: Entity) -> void:
	"""Handle player death"""
	print("[ProceduralLevel] Player died in procedural level")
	
	# Clear all enemies
	EnemyFactory.clear_all_enemies()
	
	# Add death message
	if game_hud:
		game_hud._add_log_message("You have fallen... Press Enter to try again", Color.RED)
	
	# Restart level after delay
	await get_tree().create_timer(3.0).timeout
	_restart_level()

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

func _on_all_enemies_defeated() -> void:
	"""Handle when all enemies in current room are defeated"""
	var current_room_id = level_manager.get_current_room_id()
	level_manager.level_generator.mark_room_cleared(current_room_id)
	
	if game_hud:
		game_hud._add_log_message("Room cleared!", Color.GREEN)
	
	# Update minimap
	if minimap:
		minimap.mark_room_cleared(current_room_id)
	
	# Check if it was the boss room
	var room_data = level_manager.level_generator.get_room_data(current_room_id)
	if room_data.get("type") == LevelGenerator.RoomType.BOSS:
		_on_boss_defeated()

func _on_enemy_defeated(enemy: Enemy) -> void:
	"""Handle individual enemy defeat"""
	if game_hud:
		game_hud.add_enemy_death_log(enemy.get_class())

func _on_level_completed() -> void:
	"""Handle level completion"""
	print("[ProceduralLevel] Level completed!")
	
	if game_hud:
		game_hud._add_log_message("Level completed! Proceeding deeper...", Color.GOLD)
	
	# Advance to next level
	current_depth += 1
	
	# Change biome every few levels
	if current_depth % 3 == 1 and current_depth > 1:
		_advance_biome()
	
	# Generate new level
	await get_tree().create_timer(2.0).timeout
	_generate_level()

func _on_boss_defeated() -> void:
	"""Handle boss defeat"""
	print("[ProceduralLevel] Boss defeated!")
	
	if game_hud:
		game_hud._add_log_message("Boss defeated! Level complete!", Color.GOLD)
	
	# Give bonus XP for boss
	if ProgressionSystem:
		ProgressionSystem.gain_experience(100)
	
	# Complete the level
	level_completed.emit()
	_on_level_completed()

func _advance_biome() -> void:
	"""Advance to next biome"""
	var biome_progression = [
		LevelGenerator.BiomeType.DUNGEON,
		LevelGenerator.BiomeType.FOREST,
		LevelGenerator.BiomeType.VOLCANIC,
		LevelGenerator.BiomeType.ICE_CAVES,
		LevelGenerator.BiomeType.CORRUPTION,
		LevelGenerator.BiomeType.CELESTIAL
	]
	
	var current_index = biome_progression.find(current_biome)
	if current_index != -1 and current_index < biome_progression.size() - 1:
		current_biome = biome_progression[current_index + 1]
		
		if game_hud:
			game_hud._add_log_message("Entering " + _get_biome_name(current_biome), Color.MAGENTA)

func _restart_level() -> void:
	"""Restart current level"""
	print("[ProceduralLevel] Restarting level...")
	
	# Reset depth and biome for restart
	current_depth = 1
	current_biome = LevelGenerator.BiomeType.DUNGEON
	
	# Clear enemies
	EnemyFactory.clear_all_enemies()
	
	# Regenerate level
	_generate_level()

func _input(event: InputEvent) -> void:
	"""Handle level-specific input"""
	# Press Enter to restart (if dead)
	if event.is_action_pressed("ui_accept"):
		if not player or player.current_health <= 0:
			_restart_level()
	
	# Press ESC to quit to main menu
	if event.is_action_pressed("ui_cancel"):
		UIManager.change_scene("res://scenes/ui/MainMenu.tscn")
	
	# Press Tab to open progress screen
	if event.is_action_pressed("ui_focus_next"):
		var progress_screen_scene = load("res://scenes/ui/ProgressScreen.tscn")
		if progress_screen_scene:
			var progress_screen = progress_screen_scene.instantiate()
			get_tree().current_scene.add_child(progress_screen)
			progress_screen.show_progress_screen()
	
	# Press M for minimap toggle
	if event.is_action_pressed("ui_page_up"):  # Page Up key
		if minimap:
			minimap.visible = not minimap.visible
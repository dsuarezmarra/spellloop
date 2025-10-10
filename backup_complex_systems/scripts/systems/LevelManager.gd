# LevelManager.gd
# Manages the current level, room transitions, and dynamic content loading
# Handles room instantiation, player movement between rooms, and content streaming

extends Node
class_name LevelManager

signal room_changed(old_room_id: String, new_room_id: String)
signal level_completed()
signal boss_defeated()

@onready var level_generator: LevelGenerator = LevelGenerator.new()
@onready var room_container: Node2D = Node2D.new()

# Current level state
var current_level_data: Dictionary = {}
var current_room_id: String = ""
var instantiated_rooms: Dictionary = {}  # room_id -> room_scene
var player_reference: Player

# Room management
var room_transition_in_progress: bool = false
var active_room_radius: int = 1  # Load rooms within this radius

# Templates and prefabs
var room_scene_template: PackedScene
var wall_template: PackedScene

func _ready() -> void:
	# Setup level generator
	add_child(level_generator)
	level_generator.level_generated.connect(_on_level_generated)
	level_generator.room_entered.connect(_on_room_entered)
	
	# Setup room container
	room_container.name = "RoomContainer"
	add_child(room_container)
	
	# Load templates
	_load_room_templates()
	
	print("[LevelManager] Level Manager initialized")

func _load_room_templates() -> void:
	"""Load room templates and prefabs"""
	# Create basic room template if it doesn't exist
	if not ResourceLoader.exists("res://scenes/levels/RoomTemplate.tscn"):
		_create_room_template()
	
	# Load room template
	room_scene_template = load("res://scenes/levels/RoomTemplate.tscn")
	print("[LevelManager] Room templates loaded")

func _create_room_template() -> void:
	"""Create a basic room template scene"""
	# This will be created as a separate scene file
	print("[LevelManager] Room template will be created")

func generate_new_level(depth: int = 1, biome: LevelGenerator.BiomeType = LevelGenerator.BiomeType.DUNGEON) -> void:
	"""Generate and load a new level"""
	print("[LevelManager] Generating new level at depth ", depth)
	
	# Clear previous level
	_clear_current_level()
	
	# Generate new level
	current_level_data = level_generator.generate_level(depth, biome)

func _clear_current_level() -> void:
	"""Clear all instantiated rooms and level data"""
	# Remove all room instances
	for room_id in instantiated_rooms:
		var room_scene = instantiated_rooms[room_id]
		if is_instance_valid(room_scene):
			room_scene.queue_free()
	
	instantiated_rooms.clear()
	current_room_id = ""
	current_level_data.clear()
	
	print("[LevelManager] Level cleared")

func _on_level_generated(level_data: Dictionary) -> void:
	"""Handle level generation completion"""
	current_level_data = level_data
	
	# Find player
	player_reference = get_tree().get_first_node_in_group("player")
	
	# Start at entrance room
	var entrance_room_id = level_data.player_start
	if entrance_room_id != "":
		_transition_to_room(entrance_room_id, true)
	
	print("[LevelManager] Level loaded, starting at ", entrance_room_id)

func _transition_to_room(target_room_id: String, is_initial: bool = false) -> void:
	"""Transition player to specified room"""
	if room_transition_in_progress:
		return
	
	room_transition_in_progress = true
	
	var old_room_id = current_room_id
	current_room_id = target_room_id
	
	# Mark room as visited
	level_generator.mark_room_visited(target_room_id)
	
	# Load target room and adjacent rooms
	_load_room_area(target_room_id)
	
	# Position player in new room
	if player_reference and not is_initial:
		_position_player_in_room(target_room_id, old_room_id)
	elif player_reference and is_initial:
		_position_player_at_room_center(target_room_id)
	
	# Emit room change signal
	room_changed.emit(old_room_id, target_room_id)
	
	room_transition_in_progress = false
	
	print("[LevelManager] Transitioned to room ", target_room_id)

func _load_room_area(center_room_id: String) -> void:
	"""Load the specified room and adjacent rooms"""
	var rooms_to_load = [center_room_id]
	
	# Add connected rooms
	var connected_rooms = level_generator.get_connected_rooms(center_room_id)
	rooms_to_load.append_array(connected_rooms)
	
	# Load each room
	for room_id in rooms_to_load:
		if not instantiated_rooms.has(room_id):
			_instantiate_room(room_id)
	
	# Unload distant rooms
	_unload_distant_rooms(center_room_id)

func _instantiate_room(room_id: String) -> void:
	"""Create a room instance from room data"""
	var room_data = level_generator.get_room_data(room_id)
	if room_data.is_empty():
		print("[LevelManager] ERROR: No data for room ", room_id)
		return
	
	# Create room scene
	var room_scene = _create_room_scene(room_data)
	if not room_scene:
		print("[LevelManager] ERROR: Failed to create room scene for ", room_id)
		return
	
	# Position room in world
	room_scene.global_position = room_data.world_position
	room_scene.name = room_id
	
	# Add to container
	room_container.add_child(room_scene)
	instantiated_rooms[room_id] = room_scene
	
	# Populate room with content
	_populate_room_content(room_scene, room_data)
	
	print("[LevelManager] Instantiated room ", room_id)

func _create_room_scene(room_data: Dictionary) -> Node2D:
	"""Create a room scene based on room data"""
	var room_scene = Node2D.new()
	room_scene.name = room_data.id
	
	# Get biome config
	var biome_config = level_generator.get_biome_config(room_data.biome)
	
	# Create room background
	_create_room_background(room_scene, room_data, biome_config)
	
	# Create walls
	_create_room_walls(room_scene, room_data, biome_config)
	
	# Create transition areas
	_create_room_transitions(room_scene, room_data)
	
	return room_scene

func _create_room_background(room_scene: Node2D, room_data: Dictionary, biome_config: Dictionary) -> void:
	"""Create room floor/background"""
	var background = ColorRect.new()
	background.name = "Background"
	background.size = room_data.size
	background.color = biome_config.get("floor_color", Color.GRAY)
	background.z_index = -10
	
	room_scene.add_child(background)

func _create_room_walls(room_scene: Node2D, room_data: Dictionary, biome_config: Dictionary) -> void:
	"""Create room walls based on wall configuration"""
	var walls_container = Node2D.new()
	walls_container.name = "Walls"
	room_scene.add_child(walls_container)
	
	var wall_color = biome_config.get("wall_color", Color.DARK_GRAY)
	var wall_thickness = 50.0
	var room_size = room_data.size
	
	# Create walls based on configuration
	if room_data.walls.north:
		_create_wall_segment(walls_container, Vector2(0, -wall_thickness/2), Vector2(room_size.x, wall_thickness), wall_color)
	
	if room_data.walls.south:
		_create_wall_segment(walls_container, Vector2(0, room_size.y - wall_thickness/2), Vector2(room_size.x, wall_thickness), wall_color)
	
	if room_data.walls.west:
		_create_wall_segment(walls_container, Vector2(-wall_thickness/2, 0), Vector2(wall_thickness, room_size.y), wall_color)
	
	if room_data.walls.east:
		_create_wall_segment(walls_container, Vector2(room_size.x - wall_thickness/2, 0), Vector2(wall_thickness, room_size.y), wall_color)

func _create_wall_segment(parent: Node2D, position: Vector2, size: Vector2, color: Color) -> void:
	"""Create a single wall segment"""
	# Visual wall
	var wall_visual = ColorRect.new()
	wall_visual.position = position
	wall_visual.size = size
	wall_visual.color = color
	wall_visual.z_index = 5
	parent.add_child(wall_visual)
	
	# Collision wall
	var wall_body = StaticBody2D.new()
	wall_body.position = position + size / 2
	wall_body.collision_layer = 4  # Wall layer
	wall_body.collision_mask = 0
	
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = size
	collision_shape.shape = shape
	
	wall_body.add_child(collision_shape)
	parent.add_child(wall_body)

func _create_room_transitions(room_scene: Node2D, room_data: Dictionary) -> void:
	"""Create transition areas between connected rooms"""
	var transitions_container = Node2D.new()
	transitions_container.name = "Transitions"
	room_scene.add_child(transitions_container)
	
	# Create transition areas for each connected room
	for connected_room_id in room_data.connections:
		var transition_area = _create_transition_area(room_data.id, connected_room_id, room_data)
		if transition_area:
			transitions_container.add_child(transition_area)

func _create_transition_area(from_room_id: String, to_room_id: String, room_data: Dictionary) -> Area2D:
	"""Create a transition area between two rooms"""
	var area = Area2D.new()
	area.name = "Transition_" + to_room_id
	area.collision_layer = 0
	area.collision_mask = 1  # Player layer
	
	# Calculate transition position based on room connection
	var transition_pos = _calculate_transition_position(from_room_id, to_room_id)
	area.position = transition_pos
	
	# Create collision shape
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(100, 100)  # Standard transition size
	collision_shape.shape = shape
	area.add_child(collision_shape)
	
	# Connect signals
	area.body_entered.connect(_on_transition_area_entered.bind(to_room_id))
	
	return area

func _calculate_transition_position(from_room_id: String, to_room_id: String) -> Vector2:
	"""Calculate where transition area should be placed"""
	var from_room_data = level_generator.get_room_data(from_room_id)
	var to_room_data = level_generator.get_room_data(to_room_id)
	
	var from_pos = from_room_data.grid_position
	var to_pos = to_room_data.grid_position
	var direction = to_pos - from_pos
	
	var room_size = from_room_data.size
	
	# Position transition at edge of room
	if direction == Vector2i.UP:
		return Vector2(room_size.x / 2, 0)
	elif direction == Vector2i.DOWN:
		return Vector2(room_size.x / 2, room_size.y)
	elif direction == Vector2i.LEFT:
		return Vector2(0, room_size.y / 2)
	elif direction == Vector2i.RIGHT:
		return Vector2(room_size.x, room_size.y / 2)
	
	return Vector2(room_size.x / 2, room_size.y / 2)

func _populate_room_content(room_scene: Node2D, room_data: Dictionary) -> void:
	"""Populate room with enemies, pickups, and special features"""
	# Create content container
	var content_container = Node2D.new()
	content_container.name = "Content"
	room_scene.add_child(content_container)
	
	# Spawn enemies
	for enemy_data in room_data.enemies:
		_spawn_enemy_in_room(content_container, enemy_data, room_data)
	
	# Spawn pickups
	for pickup_type in room_data.pickups:
		_spawn_pickup_in_room(content_container, pickup_type, room_data)
	
	# Add special features
	for feature_type in room_data.special_features:
		_add_special_feature_to_room(content_container, feature_type, room_data)

func _spawn_enemy_in_room(container: Node2D, enemy_data: Dictionary, room_data: Dictionary) -> void:
	"""Spawn an enemy in the room"""
	var enemy_type_string = enemy_data.type
	var spawn_position = enemy_data.position - room_data.world_position  # Local position
	
	# Convert string to enum
	var enemy_type: EnemyFactory.EnemyType
	match enemy_type_string:
		"BasicSlime":
			enemy_type = EnemyFactory.EnemyType.BASIC_SLIME
		"SentinelOrb":
			enemy_type = EnemyFactory.EnemyType.SENTINEL_ORB
		"PatrolGuard":
			enemy_type = EnemyFactory.EnemyType.PATROL_GUARD
		_:
			enemy_type = EnemyFactory.EnemyType.BASIC_SLIME
	
	# Create enemy at absolute position
	var enemy = EnemyFactory.create_enemy(enemy_type, enemy_data.position, get_tree().current_scene)
	if enemy and enemy_data.get("is_boss", false):
		# Apply boss modifications
		enemy.max_health *= 3
		enemy.current_health = enemy.max_health
		enemy.attack_damage *= 2
		enemy.scale = Vector2(1.5, 1.5)

func _spawn_pickup_in_room(container: Node2D, pickup_type: String, room_data: Dictionary) -> void:
	"""Spawn a pickup item in the room"""
	# For now, create visual indicators
	var pickup = Node2D.new()
	pickup.name = pickup_type
	pickup.position = _get_random_spawn_position_in_room(room_data)
	
	# Add visual representation
	var sprite = Sprite2D.new()
	SpriteGenerator.apply_sprite_to_node(pickup, "pickup")
	container.add_child(pickup)

func _add_special_feature_to_room(container: Node2D, feature_type: String, room_data: Dictionary) -> void:
	"""Add special features to room"""
	match feature_type:
		"entrance_portal":
			_create_entrance_portal(container, room_data)
		"boss_arena":
			_create_boss_arena(container, room_data)
		"treasure_vault":
			_create_treasure_vault(container, room_data)

func _create_entrance_portal(container: Node2D, room_data: Dictionary) -> void:
	"""Create entrance portal visual"""
	var portal = Node2D.new()
	portal.name = "EntrancePortal"
	portal.position = room_data.size / 2
	
	var sprite = Sprite2D.new()
	SpriteGenerator.apply_sprite_to_node(portal, "pickup", Color.BLUE)
	portal.scale = Vector2(2.0, 2.0)
	
	container.add_child(portal)

func _create_boss_arena(container: Node2D, room_data: Dictionary) -> void:
	"""Create boss arena features"""
	var arena = Node2D.new()
	arena.name = "BossArena"
	container.add_child(arena)

func _create_treasure_vault(container: Node2D, room_data: Dictionary) -> void:
	"""Create treasure vault features"""
	var vault = Node2D.new()
	vault.name = "TreasureVault"
	container.add_child(vault)

func _get_random_spawn_position_in_room(room_data: Dictionary) -> Vector2:
	"""Get random position within room bounds (local coordinates)"""
	var margin = 100.0
	return Vector2(
		randf_range(margin, room_data.size.x - margin),
		randf_range(margin, room_data.size.y - margin)
	)

func _position_player_in_room(room_id: String, from_room_id: String) -> void:
	"""Position player appropriately when entering a room"""
	var room_data = level_generator.get_room_data(room_id)
	if room_data.is_empty():
		return
	
	# Calculate entry position based on where player came from
	var entry_position = room_data.world_position + room_data.size / 2  # Default to center
	
	if from_room_id != "":
		entry_position = _calculate_entry_position(room_id, from_room_id)
	
	player_reference.global_position = entry_position

func _position_player_at_room_center(room_id: String) -> void:
	"""Position player at room center"""
	var room_data = level_generator.get_room_data(room_id)
	if room_data.is_empty():
		return
	
	var center_position = room_data.world_position + room_data.size / 2
	player_reference.global_position = center_position

func _calculate_entry_position(to_room_id: String, from_room_id: String) -> Vector2:
	"""Calculate where player should enter the new room"""
	var to_room_data = level_generator.get_room_data(to_room_id)
	var from_room_data = level_generator.get_room_data(from_room_id)
	
	var to_pos = to_room_data.grid_position
	var from_pos = from_room_data.grid_position
	var direction = to_pos - from_pos
	
	var room_size = to_room_data.size
	var world_pos = to_room_data.world_position
	var margin = 100.0
	
	# Enter from opposite side
	if direction == Vector2i.UP:
		return world_pos + Vector2(room_size.x / 2, room_size.y - margin)
	elif direction == Vector2i.DOWN:
		return world_pos + Vector2(room_size.x / 2, margin)
	elif direction == Vector2i.LEFT:
		return world_pos + Vector2(room_size.x - margin, room_size.y / 2)
	elif direction == Vector2i.RIGHT:
		return world_pos + Vector2(margin, room_size.y / 2)
	
	return world_pos + room_size / 2

func _unload_distant_rooms(center_room_id: String) -> void:
	"""Unload rooms that are too far from current room"""
	var rooms_to_keep = [center_room_id]
	rooms_to_keep.append_array(level_generator.get_connected_rooms(center_room_id))
	
	for room_id in instantiated_rooms.keys():
		if not rooms_to_keep.has(room_id):
			var room_scene = instantiated_rooms[room_id]
			if is_instance_valid(room_scene):
				room_scene.queue_free()
			instantiated_rooms.erase(room_id)

func _on_transition_area_entered(body: Node2D, target_room_id: String) -> void:
	"""Handle player entering a transition area"""
	if body.is_in_group("player") and not room_transition_in_progress:
		_transition_to_room(target_room_id)

func _on_room_entered(room_id: String) -> void:
	"""Handle room entry events"""
	print("[LevelManager] Player entered room ", room_id)

func get_current_room_id() -> String:
	"""Get current room ID"""
	return current_room_id

func get_current_level_data() -> Dictionary:
	"""Get current level data"""
	return current_level_data
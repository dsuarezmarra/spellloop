# LevelGenerator.gd
# Procedural level generation system for creating diverse biomes and room layouts
# Handles room placement, connections, biome themes, and content population

extends Node
class_name LevelGeneratorManager

signal level_generated(level_data: Dictionary)
signal room_entered(room_id: String)
signal biome_changed(biome_type: BiomeType)

enum BiomeType {
	DUNGEON,
	FOREST,
	VOLCANIC,
	ICE_CAVES,
	CORRUPTION,
	CELESTIAL
}

enum RoomType {
	NORMAL,
	COMBAT,
	TREASURE,
	BOSS,
	ENTRANCE,
	EXIT,
	SECRET,
	SHOP
}

# Level generation parameters
@export var level_size: Vector2i = Vector2i(15, 15)  # Grid size
@export var min_rooms: int = 8
@export var max_rooms: int = 15
@export var room_size: Vector2 = Vector2(800, 600)
@export var corridor_width: float = 100.0

# Current level data
var current_level: Dictionary = {}
var current_biome: BiomeType = BiomeType.DUNGEON
var level_depth: int = 1
var rooms: Dictionary = {}  # room_id -> room_data
var room_connections: Dictionary = {}  # room_id -> [connected_room_ids]

# Biome configurations
var biome_configs = {
	BiomeType.DUNGEON: {
		"name": "Ancient Dungeon",
		"wall_color": Color(0.4, 0.3, 0.2),
		"floor_color": Color(0.6, 0.5, 0.4),
		"enemy_types": ["BasicSlime", "PatrolGuard"],
		"enemy_density": 1.0,
		"boss_type": "DungeonKeeper",
		"ambient_color": Color(0.8, 0.7, 0.6),
		"music_track": "dungeon_ambient"
	},
	BiomeType.FOREST: {
		"name": "Mystic Forest",
		"wall_color": Color(0.2, 0.4, 0.2),
		"floor_color": Color(0.3, 0.6, 0.3),
		"enemy_types": ["BasicSlime", "SentinelOrb"],
		"enemy_density": 0.8,
		"boss_type": "ForestGuardian",
		"ambient_color": Color(0.7, 0.9, 0.7),
		"music_track": "forest_ambient"
	},
	BiomeType.VOLCANIC: {
		"name": "Volcanic Depths",
		"wall_color": Color(0.6, 0.2, 0.1),
		"floor_color": Color(0.8, 0.3, 0.2),
		"enemy_types": ["SentinelOrb", "PatrolGuard"],
		"enemy_density": 1.3,
		"boss_type": "LavaGolem",
		"ambient_color": Color(1.0, 0.6, 0.4),
		"music_track": "volcanic_ambient"
	},
	BiomeType.ICE_CAVES: {
		"name": "Frozen Caverns",
		"wall_color": Color(0.6, 0.7, 0.9),
		"floor_color": Color(0.8, 0.85, 0.95),
		"enemy_types": ["BasicSlime", "SentinelOrb"],
		"enemy_density": 0.9,
		"boss_type": "IceWarden",
		"ambient_color": Color(0.8, 0.9, 1.0),
		"music_track": "ice_ambient"
	},
	BiomeType.CORRUPTION: {
		"name": "Corrupted Realm",
		"wall_color": Color(0.3, 0.1, 0.4),
		"floor_color": Color(0.4, 0.2, 0.5),
		"enemy_types": ["PatrolGuard", "SentinelOrb"],
		"enemy_density": 1.5,
		"boss_type": "CorruptionLord",
		"ambient_color": Color(0.7, 0.5, 0.8),
		"music_track": "corruption_ambient"
	},
	BiomeType.CELESTIAL: {
		"name": "Celestial Sanctum",
		"wall_color": Color(0.9, 0.9, 0.7),
		"floor_color": Color(1.0, 1.0, 0.9),
		"enemy_types": ["SentinelOrb"],
		"enemy_density": 0.7,
		"boss_type": "CelestialChampion",
		"ambient_color": Color(1.0, 1.0, 0.9),
		"music_track": "celestial_ambient"
	}
}

func _ready() -> void:
	print("[LevelGenerator] Level Generator initialized")

func generate_level(depth: int = 1, forced_biome: BiomeType = BiomeType.DUNGEON) -> Dictionary:
	"""Generate a complete level with rooms, connections, and content"""
	level_depth = depth
	current_biome = _select_biome_for_depth(depth) if forced_biome == BiomeType.DUNGEON and depth > 1 else forced_biome
	
	print("[LevelGenerator] Generating level ", depth, " - Biome: ", BiomeType.keys()[current_biome])
	
	# Clear previous level data
	rooms.clear()
	room_connections.clear()
	
	# Generate room layout
	var room_layout = _generate_room_layout()
	
	# Create room data
	_populate_rooms(room_layout)
	
	# Generate connections between rooms
	_generate_room_connections(room_layout)
	
	# Add special rooms
	_place_special_rooms()
	
	# Populate rooms with content
	_populate_room_content()
	
	# Create level data structure
	current_level = {
		"depth": level_depth,
		"biome": current_biome,
		"biome_name": biome_configs[current_biome].name,
		"rooms": rooms.duplicate(true),
		"connections": room_connections.duplicate(true),
		"player_start": _get_entrance_room_id(),
		"boss_room": _get_boss_room_id(),
		"generation_time": Time.get_time_string_from_system()
	}
	
	level_generated.emit(current_level)
	biome_changed.emit(current_biome)
	
	print("[LevelGenerator] Level generated with ", rooms.size(), " rooms")
	return current_level

func _select_biome_for_depth(depth: int) -> BiomeType:
	"""Select appropriate biome based on level depth"""
	match depth:
		1, 2, 3:
			return BiomeType.DUNGEON
		4, 5, 6:
			return BiomeType.FOREST
		7, 8, 9:
			return BiomeType.VOLCANIC
		10, 11, 12:
			return BiomeType.ICE_CAVES
		13, 14, 15:
			return BiomeType.CORRUPTION
		_:
			return BiomeType.CELESTIAL

func _generate_room_layout() -> Array[Vector2i]:
	"""Generate basic room positions on a grid"""
	var room_positions: Array[Vector2i] = []
	var grid_used: Dictionary = {}
	
	# Start with entrance at center
	var start_pos = Vector2i(level_size.x / 2, level_size.y / 2)
	room_positions.append(start_pos)
	grid_used[start_pos] = true
	
	# Generate rooms using random walk
	var target_rooms = randi_range(min_rooms, max_rooms)
	var attempts = 0
	var max_attempts = target_rooms * 5
	
	while room_positions.size() < target_rooms and attempts < max_attempts:
		attempts += 1
		
		# Pick a random existing room to branch from
		var branch_from = room_positions[randi() % room_positions.size()]
		
		# Try to place a new room adjacent to it
		var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		directions.shuffle()
		
		for direction in directions:
			var new_pos = branch_from + direction
			
			# Check bounds and availability
			if new_pos.x >= 0 and new_pos.x < level_size.x and \
			   new_pos.y >= 0 and new_pos.y < level_size.y and \
			   not grid_used.has(new_pos):
				
				room_positions.append(new_pos)
				grid_used[new_pos] = true
				break
	
	print("[LevelGenerator] Generated ", room_positions.size(), " room positions")
	return room_positions

func _populate_rooms(room_positions: Array[Vector2i]) -> void:
	"""Create room data for each position"""
	for i in range(room_positions.size()):
		var pos = room_positions[i]
		var room_id = "room_" + str(pos.x) + "_" + str(pos.y)
		
		var room_data = {
			"id": room_id,
			"grid_position": pos,
			"world_position": Vector2(pos.x * room_size.x, pos.y * room_size.y),
			"size": room_size,
			"type": RoomType.NORMAL,
			"biome": current_biome,
			"visited": false,
			"cleared": false,
			"enemies": [],
			"pickups": [],
			"special_features": [],
			"connections": [],
			"walls": _generate_room_walls(pos),
			"entry_points": []
		}
		
		rooms[room_id] = room_data

func _generate_room_walls(grid_pos: Vector2i) -> Dictionary:
	"""Generate wall configuration for a room"""
	return {
		"north": true,
		"south": true,
		"east": true,
		"west": true,
		"corners": true
	}

func _generate_room_connections(room_positions: Array[Vector2i]) -> void:
	"""Generate connections between adjacent rooms"""
	for pos in room_positions:
		var room_id = "room_" + str(pos.x) + "_" + str(pos.y)
		var connections = []
		
		# Check adjacent positions
		var adjacent_positions = [
			pos + Vector2i.UP,    # North
			pos + Vector2i.DOWN,  # South
			pos + Vector2i.LEFT,  # West
			pos + Vector2i.RIGHT  # East
		]
		
		for adj_pos in adjacent_positions:
			var adj_room_id = "room_" + str(adj_pos.x) + "_" + str(adj_pos.y)
			if rooms.has(adj_room_id):
				connections.append(adj_room_id)
				
				# Open walls between connected rooms
				_open_walls_between_rooms(pos, adj_pos)
		
		room_connections[room_id] = connections
		rooms[room_id].connections = connections

func _open_walls_between_rooms(pos1: Vector2i, pos2: Vector2i) -> void:
	"""Open walls between two connected rooms"""
	var room1_id = "room_" + str(pos1.x) + "_" + str(pos1.y)
	var room2_id = "room_" + str(pos2.x) + "_" + str(pos2.y)
	
	var direction = pos2 - pos1
	
	# Open appropriate walls
	if direction == Vector2i.UP:
		rooms[room1_id].walls.north = false
		rooms[room2_id].walls.south = false
	elif direction == Vector2i.DOWN:
		rooms[room1_id].walls.south = false
		rooms[room2_id].walls.north = false
	elif direction == Vector2i.LEFT:
		rooms[room1_id].walls.west = false
		rooms[room2_id].walls.east = false
	elif direction == Vector2i.RIGHT:
		rooms[room1_id].walls.east = false
		rooms[room2_id].walls.west = false

func _place_special_rooms() -> void:
	"""Designate special room types"""
	var room_ids = rooms.keys()
	
	if room_ids.is_empty():
		return
	
	# Entrance room (center)
	var entrance_pos = Vector2i(level_size.x / 2, level_size.y / 2)
	var entrance_id = "room_" + str(entrance_pos.x) + "_" + str(entrance_pos.y)
	if rooms.has(entrance_id):
		rooms[entrance_id].type = RoomType.ENTRANCE
	
	# Boss room (furthest from entrance)
	var boss_room_id = _find_furthest_room_from_entrance()
	if boss_room_id != "":
		rooms[boss_room_id].type = RoomType.BOSS
	
	# Treasure rooms (randomly select 1-2 rooms)
	var available_rooms = room_ids.filter(func(id): return rooms[id].type == RoomType.NORMAL)
	var treasure_count = min(2, available_rooms.size() / 4)
	
	for i in range(treasure_count):
		if available_rooms.size() > 0:
			var treasure_room = available_rooms[randi() % available_rooms.size()]
			rooms[treasure_room].type = RoomType.TREASURE
			available_rooms.erase(treasure_room)

func _find_furthest_room_from_entrance() -> String:
	"""Find the room furthest from the entrance"""
	var entrance_pos = Vector2i(level_size.x / 2, level_size.y / 2)
	var max_distance = 0
	var furthest_room = ""
	
	for room_id in rooms:
		var room_pos = rooms[room_id].grid_position
		var distance = entrance_pos.distance_to(room_pos)
		
		if distance > max_distance:
			max_distance = distance
			furthest_room = room_id
	
	return furthest_room

func _populate_room_content() -> void:
	"""Populate rooms with enemies, pickups, and features"""
	var biome_config = biome_configs[current_biome]
	
	for room_id in rooms:
		var room = rooms[room_id]
		
		match room.type:
			RoomType.ENTRANCE:
				_populate_entrance_room(room)
			RoomType.BOSS:
				_populate_boss_room(room, biome_config)
			RoomType.TREASURE:
				_populate_treasure_room(room)
			RoomType.NORMAL:
				_populate_normal_room(room, biome_config)

func _populate_entrance_room(room: Dictionary) -> void:
	"""Populate entrance room (safe area)"""
	room.enemies = []
	room.pickups = []
	room.special_features = ["entrance_portal"]

func _populate_boss_room(room: Dictionary, biome_config: Dictionary) -> void:
	"""Populate boss room with biome-specific boss"""
	var biome_name = _get_biome_name_for_variants()
	var boss_data = {}
	
	# Get boss data from enemy variants system
	if EnemyVariants:
		boss_data = EnemyVariants.get_boss_data(biome_name)
	
	# Fallback to basic boss if no variant available
	if boss_data.is_empty():
		boss_data = {"id": "dungeon_lord", "name": {"en": "Dungeon Lord"}}
	
	room.enemies = [{
		"variant_id": boss_data.get("id", "dungeon_lord"),
		"type": boss_data.get("id", "dungeon_lord"),  # Keep compatibility
		"position": room.world_position + room.size / 2,
		"is_boss": true,
		"variant_data": boss_data
	}]
	room.pickups = ["boss_chest"]
	room.special_features = ["boss_arena"]

func _populate_treasure_room(room: Dictionary) -> void:
	"""Populate treasure room"""
	room.enemies = []  # Safe treasure room
	room.pickups = ["treasure_chest", "spell_scroll", "health_potion"]
	room.special_features = ["treasure_vault"]

func _populate_normal_room(room: Dictionary, biome_config: Dictionary) -> void:
	"""Populate normal combat room with enemy variants"""
	var enemy_count = _calculate_enemy_count_for_room(biome_config)
	var biome_name = _get_biome_name_for_variants()
	
	# Get enemy variants for this biome
	var biome_enemies = []
	if EnemyVariants:
		biome_enemies = EnemyVariants.get_biome_enemies(biome_name)
	
	# Fallback to basic enemies if no variants available
	if biome_enemies.is_empty():
		biome_enemies = [{"id": "basic_slime"}, {"id": "sentinel_orb"}]
	
	# Generate enemies with variants
	for i in range(enemy_count):
		var enemy_variant = biome_enemies[randi() % biome_enemies.size()]
		var spawn_pos = _get_random_spawn_position_in_room(room)
		
		room.enemies.append({
			"variant_id": enemy_variant.get("id", "basic_slime"),
			"type": enemy_variant.get("id", "basic_slime"),  # Keep compatibility
			"position": spawn_pos,
			"is_boss": false,
			"variant_data": enemy_variant
		})
	
	# Add random pickups
	if randf() < 0.3:  # 30% chance for pickup
		var pickup_types = ["health_potion", "mana_crystal", "coin_pile"]
		room.pickups.append(pickup_types[randi() % pickup_types.size()])

func _get_biome_name_for_variants() -> String:
	"""Get biome name string for enemy variants system"""
	match current_biome:
		BiomeType.DUNGEON:
			return "dungeon"
		BiomeType.FOREST:
			return "forest"
		BiomeType.VOLCANIC:
			return "volcanic"
		BiomeType.ICE_CAVES:
			return "ice"
		BiomeType.CORRUPTION:
			return "corruption"
		BiomeType.CELESTIAL:
			return "celestial"
		_:
			return "dungeon"

func _calculate_enemy_count_for_room(biome_config: Dictionary) -> int:
	"""Calculate number of enemies for a room"""
	var base_count = 2 + (level_depth / 3)  # Increase with depth
	var density_multiplier = biome_config.enemy_density
	
	return max(1, int(base_count * density_multiplier))

func _get_random_spawn_position_in_room(room: Dictionary) -> Vector2:
	"""Get random spawn position within room bounds"""
	var margin = 100.0  # Keep enemies away from walls
	var min_pos = room.world_position + Vector2(margin, margin)
	var max_pos = room.world_position + room.size - Vector2(margin, margin)
	
	return Vector2(
		randf_range(min_pos.x, max_pos.x),
		randf_range(min_pos.y, max_pos.y)
	)

func get_current_level() -> Dictionary:
	"""Get current level data"""
	return current_level

func get_room_data(room_id: String) -> Dictionary:
	"""Get data for specific room"""
	return rooms.get(room_id, {})

func mark_room_visited(room_id: String) -> void:
	"""Mark a room as visited"""
	if rooms.has(room_id):
		rooms[room_id].visited = true
		room_entered.emit(room_id)

func mark_room_cleared(room_id: String) -> void:
	"""Mark a room as cleared of enemies"""
	if rooms.has(room_id):
		rooms[room_id].cleared = true

func get_connected_rooms(room_id: String) -> Array:
	"""Get list of rooms connected to given room"""
	return room_connections.get(room_id, [])

func _get_entrance_room_id() -> String:
	"""Get the entrance room ID"""
	for room_id in rooms:
		if rooms[room_id].type == RoomType.ENTRANCE:
			return room_id
	return ""

func _get_boss_room_id() -> String:
	"""Get the boss room ID"""
	for room_id in rooms:
		if rooms[room_id].type == RoomType.BOSS:
			return room_id
	return ""

func get_biome_config(biome_type: BiomeType = current_biome) -> Dictionary:
	"""Get configuration for specific biome"""
	return biome_configs.get(biome_type, {})
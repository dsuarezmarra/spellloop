extends Resource
class_name DungeonGenerator

# Configuración de generación
@export var min_rooms: int = 5
@export var max_rooms: int = 15
@export var treasure_room_chance: float = 0.15
@export var large_room_chance: float = 0.15

func generate_dungeon(seed: int = -1) -> Dictionary:
	if seed != -1:
		randi() # Resetear
	
	var dungeon_data = {
		"rooms": {},
		"start_room_pos": Vector2.ZERO,
		"end_rooms": [],
		"treasure_rooms": [],
		"connections": {},
		"seed": seed
	}
	
	# Generar estructura básica
	generate_rooms(dungeon_data)
	generate_connections(dungeon_data)
	place_special_rooms(dungeon_data)
	
	return dungeon_data

func generate_rooms(data: Dictionary):
	# Generar un dungeon simple de 3x3 para test
	data["start_room_pos"] = Vector2(1, 1)  # Centro
	
	# Crear rooms en un patrón
	var room_positions = [
		Vector2(1, 1),  # Start (centro)
		Vector2(0, 1),  # Izquierda
		Vector2(2, 1),  # Derecha
		Vector2(1, 0),  # Arriba
		Vector2(1, 2),  # Abajo
	]
	
	for pos in room_positions:
		var room = RoomData.new()
		if pos == data["start_room_pos"]:
			room.room_type = RoomData.RoomType.NORMAL
			room.is_visited = true
		else:
			room.room_type = RoomData.RoomType.NORMAL
		
		room.position = pos
		room.size = RoomData.RoomSize.SMALL
		data["rooms"][pos] = room

func generate_connections(data: Dictionary):
	# Conectar rooms adyacentes
	for pos in data["rooms"]:
		var connections = []
		
		# Verificar conexiones en 4 direcciones
		var directions = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
		for dir in directions:
			var neighbor_pos = pos + dir
			if neighbor_pos in data["rooms"]:
				connections.append(neighbor_pos)
		
		data["connections"][pos] = connections

func place_special_rooms(data: Dictionary):
	# Colocar rooms especiales
	var positions = data["rooms"].keys()
	
	# Una room de tesoro
	if positions.size() > 2:
		var treasure_pos = positions[2]  # Tercera room
		data["rooms"][treasure_pos].room_type = RoomData.RoomType.TREASURE
		data["treasure_rooms"].append(treasure_pos)
	
	# Una room final
	if positions.size() > 4:
		var end_pos = positions[4]  # Quinta room
		data["rooms"][end_pos].room_type = RoomData.RoomType.BOSS
		data["end_rooms"].append(end_pos)
extends Resource
class_name RoomData

# Tipos de room
enum RoomType {
	NORMAL,
	TREASURE,
	BOSS,
	SECRET,
	SHOP
}

# Tamaños de room
enum RoomSize {
	SMALL,
	LARGE
}

# Estado de la room
enum RoomState {
	LOCKED,
	UNLOCKED,
	COMPLETED
}

# Propiedades básicas
@export var room_type: RoomType = RoomType.NORMAL
@export var size: RoomSize = RoomSize.SMALL
@export var position: Vector2 = Vector2.ZERO

# Estado
@export var is_visited: bool = false
@export var is_cleared: bool = false
@export var is_locked: bool = false

# Conexiones (direcciones donde hay puertas)
@export var connections: Array[Vector2] = []
@export var blocked_doors: Array[Vector2] = []

# Contenido de la room
@export var enemy_count: int = 0
@export var max_enemies: int = 5
@export var has_treasure: bool = false
@export var treasure_rarity: String = "common"

# Dificultad
@export var difficulty_multiplier: float = 1.0
@export var floor_level: int = 1

func _init():
	# Configuración por defecto basada en el tipo
	setup_default_properties()

func setup_default_properties():
	match room_type:
		RoomType.NORMAL:
			max_enemies = randi_range(3, 6)
			has_treasure = randf() < 0.3  # 30% chance
			treasure_rarity = "common"
		
		RoomType.TREASURE:
			max_enemies = randi_range(1, 3)
			has_treasure = true
			treasure_rarity = "rare"
			is_locked = true
		
		RoomType.BOSS:
			max_enemies = 1
			has_treasure = true
			treasure_rarity = "epic"
			is_locked = true
		
		RoomType.SECRET:
			max_enemies = randi_range(2, 4)
			has_treasure = true
			treasure_rarity = "rare"
		
		RoomType.SHOP:
			max_enemies = 0
			has_treasure = false

func can_enter() -> bool:
	return not is_locked

func unlock():
	is_locked = false
	print("🔓 Room desbloqueada en %s" % str(position))

func lock():
	is_locked = true
	print("🔒 Room bloqueada en %s" % str(position))

func complete():
	is_cleared = true
	is_visited = true
	enemy_count = 0
	
	# Desbloquear rooms conectadas
	for connection in connections:
		if connection in blocked_doors:
			blocked_doors.erase(connection)
	
	print("✅ Room completada en %s" % str(position))

func reset():
	is_visited = false
	is_cleared = false
	enemy_count = max_enemies
	blocked_doors.clear()

func add_connection(direction: Vector2):
	if direction not in connections:
		connections.append(direction)

func block_door(direction: Vector2):
	if direction in connections and direction not in blocked_doors:
		blocked_doors.append(direction)

func unblock_door(direction: Vector2):
	if direction in blocked_doors:
		blocked_doors.erase(direction)

func is_door_blocked(direction: Vector2) -> bool:
	return direction in blocked_doors

func get_room_description() -> String:
	var desc = ""
	
	match room_type:
		RoomType.NORMAL:
			desc = "Una room normal con enemigos"
		RoomType.TREASURE:
			desc = "Una room de tesoro brillante"
		RoomType.BOSS:
			desc = "Una room de jefe intimidante"
		RoomType.SECRET:
			desc = "Una room secreta misteriosa"
		RoomType.SHOP:
			desc = "Una tienda con mercancías"
	
	if is_cleared:
		desc += " (completada)"
	elif is_locked:
		desc += " (bloqueada)"
	
	return desc

func get_color() -> Color:
	match room_type:
		RoomType.NORMAL:
			return Color.GRAY if is_cleared else Color.WHITE
		RoomType.TREASURE:
			return Color.GOLD if is_cleared else Color.YELLOW
		RoomType.BOSS:
			return Color.PURPLE if is_cleared else Color.RED
		RoomType.SECRET:
			return Color.CYAN if is_cleared else Color.BLUE
		RoomType.SHOP:
			return Color.GREEN
		_:
			return Color.WHITE
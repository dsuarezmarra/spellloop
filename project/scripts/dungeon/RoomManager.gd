extends Node
class_name RoomManager

signal room_entered(room_data)
signal room_cleared()
signal room_failed()

var current_room: RoomData
var current_room_position: Vector2
var dungeon_data: Dictionary

func setup_dungeon(data: Dictionary):
	dungeon_data = data

func enter_room(position: Vector2):
	if not dungeon_data or not position in dungeon_data.rooms:
		print("❌ Room inválida: %s" % str(position))
		return
	
	current_room_position = position
	current_room = dungeon_data.rooms[position]
	current_room.is_visited = true
	
	print("🚪 Entrando a room en %s (tipo: %s)" % [str(position), current_room.room_type])
	room_entered.emit(current_room)
	
	# Simular limpieza automática para test
	await get_tree().create_timer(1.0).timeout
	clear_current_room()

func clear_current_room():
	if current_room:
		current_room.is_cleared = true
		room_cleared.emit()

func try_move_to_room(direction: Vector2) -> bool:
	var new_position = current_room_position + direction
	
	if new_position in dungeon_data.connections.get(current_room_position, []):
		enter_room(new_position)
		return true
	
	return false
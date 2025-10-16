extends Node

# Señales del sistema de dungeon
signal room_entered(room_data)
signal room_cleared()
signal room_failed()
signal dungeon_completed()
signal dungeon_failed()

# Componentes del sistema
var dungeon_generator: DungeonGenerator
var room_manager: RoomManager
var reward_system: RewardSystem
var current_dungeon_data: Dictionary

# Estado del dungeon
var is_dungeon_active: bool = false
var current_seed: int = 0

func _ready():
	print("🏰 DungeonSystem iniciado")
	
	# Inicializar componentes
	dungeon_generator = DungeonGenerator.new()
	room_manager = RoomManager.new()
	reward_system = RewardSystem.new()
	
	add_child(room_manager)
	add_child(reward_system)
	
	# Conectar señales
	setup_signals()

func setup_signals():
	# Conectar señales del room manager
	if room_manager:
		room_manager.room_entered.connect(_on_room_entered)
		room_manager.room_cleared.connect(_on_room_cleared)
		room_manager.room_failed.connect(_on_room_failed)
	
	# Conectar señales del reward system
	if reward_system:
		reward_system.experience_gained.connect(_on_experience_gained)
		reward_system.item_obtained.connect(_on_item_obtained)

func start_new_dungeon(seed: int = -1) -> bool:
	print("🚀 Iniciando nuevo dungeon...")
	
	if seed == -1:
		current_seed = randi()
	else:
		current_seed = seed
	
	# Generar el dungeon
	current_dungeon_data = dungeon_generator.generate_dungeon(current_seed)
	
	if not current_dungeon_data:
		print("❌ Error al generar dungeon")
		return false
	
	# Configurar el room manager con el nuevo dungeon
	room_manager.setup_dungeon(current_dungeon_data)
	
	# Entrar a la primera room
	room_manager.enter_room(current_dungeon_data["start_room_pos"])
	
	is_dungeon_active = true
	print("✅ Dungeon iniciado con seed: %d" % current_seed)
	return true

func get_current_room():
	if room_manager:
		return room_manager.current_room
	return null

func get_dungeon_progress() -> Dictionary:
	if not current_dungeon_data:
		return {}
	
	var cleared_rooms = 0
	var total_rooms = current_dungeon_data["rooms"].size()
	
	for pos in current_dungeon_data["rooms"]:
		var room = current_dungeon_data["rooms"][pos]
		if room.is_cleared:
			cleared_rooms += 1
			cleared_rooms += 1
	
	return {
		"cleared_rooms": cleared_rooms,
		"total_rooms": total_rooms,
		"progress_percent": float(cleared_rooms) / float(total_rooms) * 100.0,
		"current_floor": 1
	}

func move_to_room(direction: Vector2) -> bool:
	if not room_manager:
		return false
	
	return room_manager.try_move_to_room(direction)

func complete_dungeon():
	if not is_dungeon_active:
		return
	
	print("🎉 ¡Dungeon completado!")
	
	# Calcular recompensas finales
	var final_reward = reward_system.calculate_dungeon_completion_reward(current_dungeon_data)
	
	# Guardar progreso
	if SaveManager:
		SaveManager.save_dungeon_completion(current_seed, final_reward)
	
	is_dungeon_active = false
	dungeon_completed.emit()

func fail_dungeon():
	if not is_dungeon_active:
		return
	
	print("💀 Dungeon fallido")
	is_dungeon_active = false
	dungeon_failed.emit()

func get_minimap_data() -> Dictionary:
	if not current_dungeon_data:
		return {}
	
	return {
		"rooms": current_dungeon_data["rooms"],
		"connections": current_dungeon_data["connections"],
		"current_position": room_manager.current_room_position if room_manager else Vector2.ZERO,
		"treasure_rooms": current_dungeon_data["treasure_rooms"],
		"end_rooms": current_dungeon_data["end_rooms"]
	}

# Manejadores de señales
func _on_room_entered(room_data):
	print("🚪 Entrando a room: %s en posición %s" % [room_data.room_type, str(room_manager.current_room_position)])
	room_entered.emit(room_data)

func _on_room_cleared():
	print("✅ Room completada")
	
	# Verificar si es una room de tesoro
	var current_pos = room_manager.current_room_position
	if current_pos in current_dungeon_data["treasure_rooms"]:
		reward_system.give_treasure_room_reward()
	
	# Verificar si es una room final
	if current_pos in current_dungeon_data["end_rooms"]:
		complete_dungeon()
	
	room_cleared.emit()

func _on_room_failed():
	print("❌ Room fallida")
	fail_dungeon()

func _on_experience_gained(amount: int):
	print("⭐ Experiencia ganada: %d" % amount)

func _on_item_obtained(item_data: Dictionary):
	print("🎁 Item obtenido: %s" % item_data.name)

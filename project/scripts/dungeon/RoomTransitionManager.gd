extends Node
class_name RoomTransitionManager

# Referencias principales
var current_room_scene: Node2D
var player: CharacterBody2D
var camera: Camera2D
var main_scene: Node2D

# Datos del dungeon
var dungeon_data: Dictionary
var current_room_position: Vector2

# Configuración de transición
const TRANSITION_DURATION = 0.5

# Señales
signal room_changed(new_room_position: Vector2)
signal transition_started()
signal transition_completed()

func _ready():
	print("🔄 RoomTransitionManager inicializado")

func initialize(dungeon_data_ref: Dictionary, player_ref: CharacterBody2D, camera_ref: Camera2D, scene_ref: Node2D):
	"""Inicializar el manager con referencias necesarias"""
	dungeon_data = dungeon_data_ref
	player = player_ref
	camera = camera_ref
	main_scene = scene_ref
	
	# Posicionar en room inicial
	current_room_position = dungeon_data.start_room_pos
	load_current_room()

func load_current_room():
	"""Cargar la room actual"""
	if not dungeon_data or not current_room_position in dungeon_data.rooms:
		print("❌ Error: Room no encontrada en posición %s" % current_room_position)
		return
	
	# Limpiar room anterior si existe
	if current_room_scene:
		current_room_scene.queue_free()
	
	# Crear nueva room scene
	var RoomSceneScript = preload("res://scripts/dungeon/RoomScene.gd")
	current_room_scene = Node2D.new()
	current_room_scene.script = RoomSceneScript
	main_scene.add_child(current_room_scene)
	
	# Inicializar con datos de la room
	var room_data = dungeon_data.rooms[current_room_position]
	current_room_scene.initialize_room(room_data, player)
	
	# Conectar señales
	current_room_scene.player_exit_room.connect(_on_player_exit_room)
	current_room_scene.room_cleared.connect(_on_room_cleared)
	
	# Configurar cámara
	setup_camera()
	
	# Emitir señal de cambio
	room_changed.emit(current_room_position)
	
	print("🚪 Room cargada: %s (tipo: %s)" % [current_room_position, room_data.room_type])

func _on_player_exit_room(direction: Vector2):
	"""Manejar salida del jugador de la room"""
	var new_room_position = current_room_position + direction
	
	# Verificar que la nueva room existe
	if not new_room_position in dungeon_data.rooms:
		print("⚠️ No hay room en dirección %s desde %s" % [direction, current_room_position])
		return
	
	# Verificar que la room está conectada
	var current_room_data = dungeon_data.rooms[current_room_position]
	if not direction in current_room_data.connections:
		print("⚠️ Room no conectada en dirección %s" % direction)
		return
	
	# Realizar transición
	transition_to_room(new_room_position, direction)

func transition_to_room(new_position: Vector2, entry_direction: Vector2):
	"""Realizar transición a nueva room"""
	transition_started.emit()
	
	# Actualizar posición actual
	current_room_position = new_position
	
	# Fade out (opcional, por ahora instantáneo)
	perform_transition_effect()
	
	# Cargar nueva room
	load_current_room()
	
	# Posicionar jugador en el lado opuesto de donde entró
	position_player_after_transition(entry_direction)
	
	transition_completed.emit()

func position_player_after_transition(entry_direction: Vector2):
	"""Posicionar jugador después de la transición"""
	if not player or not current_room_scene:
		return
	
	var room_bounds = current_room_scene.get_room_bounds()
	var new_position = Vector2()
	
	# Posicionar en el lado opuesto a la entrada
	match entry_direction:
		Vector2.UP:  # Entró por arriba, colocar abajo
			new_position = Vector2(room_bounds.position.x + room_bounds.size.x/2, 
								 room_bounds.position.y + room_bounds.size.y - 50)
		Vector2.DOWN:  # Entró por abajo, colocar arriba
			new_position = Vector2(room_bounds.position.x + room_bounds.size.x/2, 
								 room_bounds.position.y + 50)
		Vector2.LEFT:  # Entró por izquierda, colocar derecha
			new_position = Vector2(room_bounds.position.x + room_bounds.size.x - 50, 
								 room_bounds.position.y + room_bounds.size.y/2)
		Vector2.RIGHT:  # Entró por derecha, colocar izquierda
			new_position = Vector2(room_bounds.position.x + 50, 
								 room_bounds.position.y + room_bounds.size.y/2)
		_:  # Centro por defecto
			new_position = Vector2(room_bounds.position.x + room_bounds.size.x/2, 
								 room_bounds.position.y + room_bounds.size.y/2)
	
	player.position = new_position

func perform_transition_effect():
	"""Realizar efecto de transición (fade, slide, etc.)"""
	# Por ahora, transición instantánea
	# TODO: Implementar efectos visuales como fade in/out
	pass

func setup_camera():
	"""Configurar la cámara para la room actual"""
	if not camera or not current_room_scene:
		return
	
	# Centrar cámara en la room
	var room_center = Vector2(
		current_room_scene.ROOM_WIDTH / 2,
		current_room_scene.ROOM_HEIGHT / 2
	)
	
	camera.position = room_center
	camera.enabled = true

func get_current_room_data() -> RoomData:
	"""Obtener datos de la room actual"""
	if dungeon_data and current_room_position in dungeon_data.rooms:
		return dungeon_data.rooms[current_room_position]
	return null

func is_room_cleared() -> bool:
	"""Verificar si la room actual está completada"""
	var room_data = get_current_room_data()
	return room_data != null and room_data.is_cleared

func _on_room_cleared():
	"""Manejar completado de room"""
	print("🏆 Room %s completada!" % current_room_position)
	
	# Notificar al DungeonSystem
	if DungeonSystem:
		DungeonSystem._on_room_cleared()

func get_minimap_data() -> Dictionary:
	"""Obtener datos para el minimap"""
	return {
		"current_position": current_room_position,
		"rooms": dungeon_data.rooms,
		"connections": dungeon_data.connections
	}
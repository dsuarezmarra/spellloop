extends Node2D

# Referencias del sistema
var player: CharacterBody2D
var camera: Camera2D
var room_transition_manager: RoomTransitionManager
var minimap_ui: MinimapUI

func _ready():
	print("=== INICIANDO DUNGEON SCENE CON ROOMS ===")
	
	# Configurar la escena
	setup_scene()
	
	# Inicializar sistema de dungeons
	initialize_dungeon_system()
	
	# Configurar UI
	setup_ui()

func setup_scene():
	"""Configurar elementos básicos de la escena"""
	# Crear y configurar cámara
	camera = Camera2D.new()
	camera.name = "Camera2D"
	camera.enabled = true
	add_child(camera)
	
	# Crear jugador usando el script existente
	player = CharacterBody2D.new()
	player.name = "Player"
	player.script = preload("res://scripts/entities/Player.gd")
	
	# Añadir Sprite2D al jugador
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	player.add_child(sprite)
	
	# Añadir CollisionShape2D al jugador
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var capsule = CapsuleShape2D.new()
	capsule.radius = 16
	capsule.height = 32
	collision.shape = capsule
	player.add_child(collision)
	
	add_child(player)
	
	# Configurar cámara para seguir al jugador
	camera.add_child(player)
	
	print("✅ Escena configurada con Player y Camera")

func initialize_dungeon_system():
	"""Inicializar el sistema de dungeons"""
	if not DungeonSystem:
		print("❌ Error: DungeonSystem no disponible")
		return
	
	# Iniciar nuevo dungeon
	DungeonSystem.start_new_dungeon()
	
	# Crear room transition manager
	room_transition_manager = RoomTransitionManager.new()
	room_transition_manager.name = "RoomTransitionManager"
	add_child(room_transition_manager)
	
	# Inicializar con datos del dungeon
	var dungeon_data = DungeonSystem.get_minimap_data()
	room_transition_manager.initialize(dungeon_data, player, camera, self)
	
	# Conectar señales
	room_transition_manager.room_changed.connect(_on_room_changed)
	room_transition_manager.transition_started.connect(_on_transition_started)
	room_transition_manager.transition_completed.connect(_on_transition_completed)
	
	print("✅ Sistema de dungeons inicializado")

func setup_ui():
	"""Configurar interfaz de usuario"""
	# Crear minimap
	minimap_ui = MinimapUI.new()
	minimap_ui.name = "MinimapUI"
	add_child(minimap_ui)
	
	# Crear UI de información
	create_info_ui()
	
	print("✅ UI configurada")

func create_info_ui():
	"""Crear interfaz de información"""
	# Control principal para UI
	var ui_container = CanvasLayer.new()
	ui_container.name = "UI"
	add_child(ui_container)
	
	# Label de información
	var info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.position = Vector2(20, 20)
	info_label.size = Vector2(400, 150)
	info_label.text = "SPELLLOOP - DUNGEON SYSTEM\n\nControles:\n- WASD: Movimiento\n- Toca puertas verdes para cambiar room\n- Derrota enemigos para abrir puertas"
	info_label.add_theme_color_override("font_color", Color.WHITE)
	ui_container.add_child(info_label)
	
	# Label de estado de room
	var room_status_label = Label.new()
	room_status_label.name = "RoomStatusLabel"
	room_status_label.position = Vector2(20, 200)
	room_status_label.size = Vector2(300, 100)
	room_status_label.add_theme_color_override("font_color", Color.YELLOW)
	ui_container.add_child(room_status_label)
	
	update_room_status_ui()

func update_room_status_ui():
	"""Actualizar UI del estado de la room"""
	var ui = get_node_or_null("UI/RoomStatusLabel")
	if not ui or not room_transition_manager:
		return
	
	var room_data = room_transition_manager.get_current_room_data()
	if not room_data:
		return
	
	var status_text = "Room: %s\nTipo: %s\nCompletada: %s" % [
		room_transition_manager.current_room_position,
		get_room_type_name(room_data.room_type),
		"Sí" if room_data.is_cleared else "No"
	]
	
	ui.text = status_text

func get_room_type_name(room_type) -> String:
	"""Obtener nombre legible del tipo de room"""
	match room_type:
		RoomData.RoomType.NORMAL:
			return "Normal"
		RoomData.RoomType.TREASURE:
			return "Tesoro"
		RoomData.RoomType.BOSS:
			return "Jefe"
		RoomData.RoomType.SECRET:
			return "Secreto"
		RoomData.RoomType.SHOP:
			return "Tienda"
		_:
			return "Desconocido"

func _input(event):
	"""Manejar input del usuario"""
	if event.is_action_pressed("ui_cancel"):  # ESC
		get_tree().quit()

# Manejadores de señales del sistema de rooms
func _on_room_changed(new_room_position: Vector2):
	"""Manejar cambio de room"""
	print("🚪 Cambiado a room: %s" % new_room_position)
	update_room_status_ui()
	
	# Actualizar minimap
	if minimap_ui:
		minimap_ui.update_minimap_data()

func _on_transition_started():
	"""Manejar inicio de transición"""
	print("🔄 Iniciando transición de room...")

func _on_transition_completed():
	"""Manejar finalización de transición"""
	print("✅ Transición de room completada")
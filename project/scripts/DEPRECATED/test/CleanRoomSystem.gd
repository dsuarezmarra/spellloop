extends Node2D
class_name CleanRoomSystem

"""
🏗️ SISTEMA DE SALA LIMPIO Y ESCALABLE
====================================

Este sistema usa ScaleManager para escalado uniforme:
- Todos los elementos usan el mismo patrón de escalado
- Escalado automático y proporcional
- Mantenimiento centralizado
"""

# Variables dinámicas que se adaptan al viewport
var room_width: float
var room_height: float

# Z-indexes
const WALL_Z_INDEX = 10
const FLOOR_Z_INDEX = 5
const PLAYER_Z_INDEX = 20

# Referencias a componentes
var player: CharacterBody2D
var walls: Array = []
var doors: Array = []

func _ready():
	print("🏗️ === SISTEMA DE SALA LIMPIO ===")
	
	# Conectar señal de cambio de escala del singleton
	ScaleManager.scale_changed.connect(_on_scale_changed)
	
	setup_room()
	
	# Conectar señal para reescalar automáticamente cuando cambie el tamaño
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _on_scale_changed(new_scale: float):
	"""Responder a cambios de escala del ScaleManager"""
	print("🔄 Escala cambiada a: ", new_scale)
	_on_viewport_size_changed()

func _on_viewport_size_changed():
	"""Reescalar sala automáticamente cuando cambia el tamaño de ventana"""
	print("🔄 Tamaño de ventana cambió - Reescalando sala...")
	
	# Esperar un frame para que el viewport se actualice
	await get_tree().process_frame
	
	# Actualizar escala en el manager
	ScaleManager.update_scale()
	
	# Limpiar elementos existentes (excepto jugador)
	clear_room()
	
	# Recrear sala con nuevas dimensiones
	setup_room()

func clear_room():
	"""Limpiar todos los elementos de la sala excepto el jugador"""
	# Solo limpiar elementos que no sean el jugador
	for child in get_children():
		if child != player:
			child.queue_free()
	
	# Limpiar arrays
	walls.clear()
	doors.clear()
	
	print("🧹 Sala limpiada (jugador preservado)")

func setup_room():
	"""Configurar la sala usando ScaleManager singleton para escalado uniforme"""
	# Obtener dimensiones reales del viewport
	var viewport_size = get_viewport().get_visible_rect().size
	room_width = viewport_size.x
	room_height = viewport_size.y
	
	# Actualizar escala en el manager
	ScaleManager.calculate_scale()
	
	print("🖥️ Viewport detectado: ", viewport_size)
	print("📐 Usando ScaleManager - Escala: ", ScaleManager.get_scale())
	print("🔧 Debug: ", ScaleManager.debug_info())
	
	# Crear componentes en orden correcto con escalado uniforme
	create_floor()
	create_walls()
	
	# Solo crear player si no existe
	if not player:
		create_player()
	else:
		# Reescalar player existente
		update_player_scale()
	
	create_doors()
	
	print("✅ Sala configurada con escalado uniforme")
	print("🎮 CONTROLES DE TEST:")
	print("   • ESPACIO: Abrir/Cerrar todas las puertas")
	print("   • R/ESC: Reescalar sala manualmente")
	print("   • ENTER: Reescalar jugador manualmente")
	print("   • WASD: Mover jugador")

func create_floor():
	"""Crear suelo de arena usando ScaleManager"""
	print("🏖️ Creando suelo de arena...")
	
	# Usar ScaleManager para obtener posición y tamaño del suelo
	var floor_pos = ScaleManager.get_room_floor_offset()
	var floor_size = ScaleManager.get_room_floor_size(Vector2(room_width, room_height))
	
	# Usar TextureRect para mostrar la textura de arena
	var floor_rect = TextureRect.new()
	floor_rect.name = "Floor"
	floor_rect.position = floor_pos
	floor_rect.size = floor_size
	floor_rect.z_index = FLOOR_Z_INDEX
	
	# Crear textura de arena procedural
	var sand_texture = MagicWallTextures.create_sand_floor_texture(floor_size)
	if sand_texture:
		floor_rect.texture = sand_texture
		floor_rect.stretch_mode = TextureRect.STRETCH_KEEP
	else:
		# Fallback si falla la textura procedural
		floor_rect.texture = null
		var fallback_rect = ColorRect.new()
		fallback_rect.size = floor_size
		fallback_rect.color = Color(0.95, 0.88, 0.75, 1.0)  # Color arena clara
		fallback_rect.z_index = FLOOR_Z_INDEX
		add_child(fallback_rect)
		print("⚠️ Usando color fallback para el suelo")
		return
	
	add_child(floor_rect)
	print("✅ Suelo creado - Tamaño: ", floor_rect.size)

func create_walls():
	"""Crear paredes usando ScaleManager"""
	print("🧱 Creando paredes...")
	
	# Obtener grosor de pared del ScaleManager
	var wall_thickness = ScaleManager.get_wall_thickness()
	
	# Pared superior
	create_single_wall("top", Vector2(0, 0), Vector2(room_width, wall_thickness))
	
	# Pared inferior
	create_single_wall("bottom", Vector2(0, room_height - wall_thickness), Vector2(room_width, wall_thickness))
	
	# Pared izquierda
	create_single_wall("left", Vector2(0, 0), Vector2(wall_thickness, room_height))
	
	# Pared derecha
	create_single_wall("right", Vector2(room_width - wall_thickness, 0), Vector2(wall_thickness, room_height))
	
	print("✅ Paredes creadas: ", walls.size())

func create_single_wall(name: String, pos: Vector2, size: Vector2):
	"""Crear una pared individual con textura de ladrillos y colisión"""
	# Crear textura de ladrillos procedural
	var brick_texture = MagicWallTextures.create_magic_wall_texture(name, size)
	
	# Visual de la pared con textura
	var wall_sprite = Sprite2D.new()
	wall_sprite.name = "Wall_" + name
	wall_sprite.texture = brick_texture
	wall_sprite.position = pos + size/2  # Sprite2D se posiciona por el centro
	wall_sprite.z_index = WALL_Z_INDEX
	
	# Escalar texture para que coincida exactamente con el tamaño
	if brick_texture:
		var texture_size = brick_texture.get_size()
		var scale_x = size.x / texture_size.x
		var scale_y = size.y / texture_size.y
		wall_sprite.scale = Vector2(scale_x, scale_y)
	
	# Colisión de la pared
	var wall_body = StaticBody2D.new()
	wall_body.name = "WallCollision_" + name
	wall_body.position = pos + size/2  # Centrar en la pared
	
	var collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = size
	collision_shape.shape = rect_shape
	
	wall_body.add_child(collision_shape)
	
	# Añadir a la escena
	add_child(wall_sprite)
	add_child(wall_body)
	
	# Guardar referencia
	walls.append({"visual": wall_sprite, "collision": wall_body, "name": name})
	
	print("🧱 Pared '", name, "' creada en ", pos, " con tamaño ", size)

func create_player():
	"""Crear jugador con sistema simplificado"""
	print("🧙‍♂️ Creando jugador...")
	
	player = CharacterBody2D.new()
	player.name = "Player"
	player.z_index = PLAYER_Z_INDEX
	
	# Sprite del jugador
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = preload("res://sprites/wizard/wizard_down.png")
	# NO establecer escala aquí - se establecerá automáticamente por ScaleManager
	player.add_child(sprite)
	
	# Colisión del jugador
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"  # Nombre necesario para que Player.gd lo encuentre
	var circle = CircleShape2D.new()
	circle.radius = 26  # Radio base que será escalado por ScaleManager
	collision.shape = circle
	player.add_child(collision)
	
	# Posicionar en el centro
	player.position = Vector2(room_width/2, room_height/2)
	
	# Script básico de movimiento (esto llamará automáticamente a apply_correct_scale)
	player.script = load("res://scripts/entities/Player.gd")
	
	add_child(player)
	print("✅ Jugador creado en posición: ", player.position)

func update_player_position():
	"""Actualizar posición del jugador al centro cuando se reescala"""
	if player:
		player.position = Vector2(room_width/2, room_height/2)
		print("🏃 Jugador reposicionado en: ", player.position)

func update_player_scale():
	"""Reescalar el jugador usando ScaleManager"""
	if not player:
		return
		
	# Obtener escala del jugador del ScaleManager
	var player_scale = ScaleManager.get_player_scale()
	
	# Usar la nueva función update_scale del player para aplicar el escalado
	if player.has_method("update_scale"):
		player.update_scale(player_scale)
		print("🧙‍♂️ JUGADOR ESCALADO VIA FUNCIÓN: ", player_scale)
	else:
		# Fallback si el player no tiene la función update_scale
		if player.has_node("Sprite2D"):
			var sprite = player.get_node("Sprite2D")
			sprite.scale = Vector2(player_scale, player_scale)
			print("🧙‍♂️ JUGADOR ESCALADO DIRECTAMENTE: ", player_scale)
	
	print("🔍 DEBUG: ", ScaleManager.debug_info())
	
	# Reposicionar al centro
	player.position = Vector2(room_width/2, room_height/2)

func create_doors():
	"""Crear puertas usando ScaleManager"""
	print("🚪 Creando puertas...")
	
	# Obtener tamaño de puerta del ScaleManager
	var door_size = ScaleManager.get_door_size()
	
	# Puerta superior (sin rotación)
	create_single_door("top", Vector2(room_width/2 - door_size.x/2, 0), door_size, 0)
	
	# Puerta inferior (rotada 180 grados)
	create_single_door("bottom", Vector2(room_width/2 - door_size.x/2, room_height - door_size.y), door_size, 180)
	
	# Puerta izquierda (rotada 270 grados)
	create_single_door("left", Vector2(0, room_height/2 - door_size.y/2), door_size, 270)
	
	# Puerta derecha (rotada 90 grados)
	create_single_door("right", Vector2(room_width - door_size.x, room_height/2 - door_size.y/2), door_size, 90)
	
	print("✅ Puertas creadas: ", doors.size())

func create_single_door(name: String, pos: Vector2, size: Vector2, rotation_degrees: float):
	"""Crear una puerta individual con textura mágica y rotación"""
	# Crear textura de puerta mágica (cerrada inicialmente)
	var door_texture = MagicWallTextures.create_magic_door_texture(false, size)
	
	# Visual de la puerta
	var door_sprite = Sprite2D.new()
	door_sprite.name = "Door_" + name
	door_sprite.texture = door_texture
	door_sprite.position = pos + size/2  # Sprite2D se posiciona por el centro
	door_sprite.rotation_degrees = rotation_degrees  # Aplicar rotación
	door_sprite.z_index = WALL_Z_INDEX + 1  # Encima de paredes
	
	# Escalar textura para que coincida exactamente con el tamaño
	if door_texture:
		var texture_size = door_texture.get_size()
		var scale_x = size.x / texture_size.x
		var scale_y = size.y / texture_size.y
		door_sprite.scale = Vector2(scale_x, scale_y)
	
	add_child(door_sprite)
	doors.append({
		"visual": door_sprite, 
		"name": name, 
		"is_open": false, 
		"size": size,
		"rotation": rotation_degrees
	})
	
	print("🚪 Puerta '", name, "' creada en ", pos, " (rotación: ", rotation_degrees, "°)")

func get_room_info() -> Dictionary:
	"""Obtener información de la sala usando ScaleManager"""
	return {
		"width": room_width,
		"height": room_height,
		"wall_thickness": ScaleManager.get_wall_thickness(),
		"scale_factor": ScaleManager.get_scale(),
		"walls_count": walls.size(),
		"doors_count": doors.size(),
		"player_position": player.position if player else Vector2.ZERO,
		"scale_debug": ScaleManager.debug_info()
	}

func _input(event):
	"""Manejar controles de test"""
	if event.is_action_pressed("ui_accept"):  # ESPACIO
		toggle_all_doors()
	elif event.is_action_pressed("ui_cancel"):  # ESC o R
		# Forzar reescalado manual para test
		print("🔧 Reescalado manual activado")
		_on_viewport_size_changed()
	elif Input.is_action_just_pressed("ui_select"):  # ENTER
		# Test de reescalado de jugador
		if player:
			update_player_scale()
			print("🔧 Reescalado de jugador manual")

func toggle_all_doors():
	"""Abrir/cerrar todas las puertas para test"""
	if doors.is_empty():
		return
		
	# Determinar si abrir o cerrar basándose en la primera puerta
	var should_open = not doors[0].is_open
	
	for door_data in doors:
		if should_open and not door_data.is_open:
			open_door(door_data)
		elif not should_open and door_data.is_open:
			close_door(door_data)
	
	print("🚪 Puertas ", "abiertas" if should_open else "cerradas")

func open_door(door_data: Dictionary):
	"""Abrir una puerta específica"""
	if door_data.is_open:
		return
		
	# Crear nueva textura de puerta abierta (azul)
	var open_texture = MagicWallTextures.create_magic_door_texture(true, door_data.size)
	door_data.visual.texture = open_texture
	
	# Actualizar escala
	if open_texture:
		var texture_size = open_texture.get_size()
		var scale_x = door_data.size.x / texture_size.x
		var scale_y = door_data.size.y / texture_size.y
		door_data.visual.scale = Vector2(scale_x, scale_y)
	
	door_data.is_open = true

func close_door(door_data: Dictionary):
	"""Cerrar una puerta específica"""
	if not door_data.is_open:
		return
		
	# Crear nueva textura de puerta cerrada
	var closed_texture = MagicWallTextures.create_magic_door_texture(false, door_data.size)
	door_data.visual.texture = closed_texture
	
	# Actualizar escala
	if closed_texture:
		var texture_size = closed_texture.get_size()
		var scale_x = door_data.size.x / texture_size.x
		var scale_y = door_data.size.y / texture_size.y
		door_data.visual.scale = Vector2(scale_x, scale_y)
	
	door_data.is_open = false

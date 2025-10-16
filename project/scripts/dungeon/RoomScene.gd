extends Node2D
class_name RoomScene

# Dimensiones de la room (como en Isaac)
const ROOM_WIDTH = 1024.0
const ROOM_HEIGHT = 576.0
const WALL_THICKNESS = 64.0

# Referencias
@onready var player: CharacterBody2D
@onready var room_walls: Node2D
@onready var doors: Node2D
@onready var enemies_container: Node2D

# Datos de la room
var room_data: RoomData
var is_room_cleared: bool = false
var doors_locked: bool = true

# Señales
signal room_cleared
signal player_exit_room(direction: Vector2)

func _ready():
	setup_room()
	
func setup_room():
	# Crear contenedores si no existen
	if not room_walls:
		room_walls = Node2D.new()
		room_walls.name = "RoomWalls"
		add_child(room_walls)
	
	if not doors:
		doors = Node2D.new()
		doors.name = "Doors"
		add_child(doors)
		
	if not enemies_container:
		enemies_container = Node2D.new()
		enemies_container.name = "Enemies"
		add_child(enemies_container)

func initialize_room(data: RoomData, player_node: CharacterBody2D):
	"""Inicializar la room con datos específicos"""
	room_data = data
	player = player_node
	
	# Configurar room
	create_room_walls()
	create_doors()
	spawn_enemies()
	position_player()
	
	print("🚪 Room inicializada: %s en %s" % [room_data.room_type, room_data.position])

func create_room_walls():
	"""Crear paredes con colisión en el borde exterior absoluto"""
	# Limpiar paredes existentes
	for child in room_walls.get_children():
		child.queue_free()
	
	var wall_color = Color.DARK_GRAY
	
	# Crear cada pared individualmente con colisión en borde absoluto
	create_wall_absolute("top", wall_color)
	create_wall_absolute("bottom", wall_color) 
	create_wall_absolute("left", wall_color)
	create_wall_absolute("right", wall_color)

func create_wall_absolute(wall_type: String, color: Color):
	"""Crear una pared con colisión en el borde exterior absoluto"""
	var wall = StaticBody2D.new()
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	var visual = ColorRect.new()
	
	# Grosor de colisión ultra-fino
	var collision_thickness = 1.0
	
	# Configurar colisión y visual según el tipo de pared
	var collision_pos: Vector2
	var collision_size: Vector2
	var visual_pos: Vector2
	var visual_size: Vector2
	var wall_pos: Vector2
	
	match wall_type:
		"top":
			# Colisión en el borde superior absoluto (y=0)
			wall_pos = Vector2(0, 0)
			collision_pos = Vector2(ROOM_WIDTH/2, collision_thickness/2)
			collision_size = Vector2(ROOM_WIDTH, collision_thickness)
			# Visual centrado en la zona de pared superior
			visual_pos = Vector2(0, 22)  # 22px desde el borde para centrar en zona de 64px
			visual_size = Vector2(ROOM_WIDTH, 20)
			
		"bottom":
			# Colisión en el borde inferior absoluto (y=ROOM_HEIGHT)
			wall_pos = Vector2(0, ROOM_HEIGHT - collision_thickness)
			collision_pos = Vector2(ROOM_WIDTH/2, collision_thickness/2)
			collision_size = Vector2(ROOM_WIDTH, collision_thickness)
			# Visual centrado en la zona de pared inferior
			visual_pos = Vector2(0, -42)  # 42px hacia arriba desde el borde para centrar
			visual_size = Vector2(ROOM_WIDTH, 20)
			
		"left":
			# Colisión en el borde izquierdo absoluto (x=0)
			wall_pos = Vector2(0, 0)
			collision_pos = Vector2(collision_thickness/2, ROOM_HEIGHT/2)
			collision_size = Vector2(collision_thickness, ROOM_HEIGHT)
			# Visual centrado en la zona de pared izquierda
			visual_pos = Vector2(22, 0)  # 22px desde el borde para centrar en zona de 64px
			visual_size = Vector2(20, ROOM_HEIGHT)
			
		"right":
			# Colisión en el borde derecho absoluto (x=ROOM_WIDTH)
			wall_pos = Vector2(ROOM_WIDTH - collision_thickness, 0)
			collision_pos = Vector2(collision_thickness/2, ROOM_HEIGHT/2)
			collision_size = Vector2(collision_thickness, ROOM_HEIGHT)
			# Visual centrado en la zona de pared derecha
			visual_pos = Vector2(-42, 0)  # 42px hacia la izquierda desde el borde para centrar
			visual_size = Vector2(20, ROOM_HEIGHT)
	
	# Configurar colisión
	rect_shape.size = collision_size
	collision.shape = rect_shape
	collision.position = collision_pos
	
	# Configurar visual
	visual.size = visual_size
	visual.color = color
	visual.position = visual_pos
	visual.z_index = -10
	
	# Ensamblar pared
	wall.add_child(visual)
	wall.add_child(collision)
	wall.position = wall_pos
	wall.z_index = -10
	
	# Añadir a contenedor
	room_walls.add_child(wall)

func create_wall(pos: Vector2, size: Vector2, color: Color):
	"""Crear una pared con colisión solo en el borde exterior absoluto"""
	var wall = StaticBody2D.new()
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	var visual = ColorRect.new()
	
	# Colisión ultra-fina solo en el borde exterior (2 píxeles)
	var collision_thickness = 2.0
	var collision_size: Vector2
	var collision_pos: Vector2
	
	# Posicionar colisión en el borde EXTERIOR absoluto
	if size.x > size.y:  # Pared horizontal (superior/inferior)
		collision_size = Vector2(size.x, collision_thickness)
		if pos.y == 0:  # Pared superior - colisión en el borde superior (y=0)
			collision_pos = Vector2(size.x / 2, collision_thickness / 2)
		else:  # Pared inferior - colisión en el borde inferior (y=ROOM_HEIGHT)
			collision_pos = Vector2(size.x / 2, size.y - collision_thickness / 2)
	else:  # Pared vertical (izquierda/derecha)
		collision_size = Vector2(collision_thickness, size.y)
		if pos.x == 0:  # Pared izquierda - colisión en el borde izquierdo (x=0)
			collision_pos = Vector2(collision_thickness / 2, size.y / 2)
		else:  # Pared derecha - colisión en el borde derecho (x=ROOM_WIDTH)
			collision_pos = Vector2(size.x - collision_thickness / 2, size.y / 2)
	
	# Configurar colisión
	rect_shape.size = collision_size
	collision.shape = rect_shape
	collision.position = collision_pos
	
	# Visual de la pared (grosor medio, centrado en la zona)
	var visual_thickness = 20.0
	var visual_size: Vector2
	var visual_pos: Vector2
	
	if size.x > size.y:  # Pared horizontal
		visual_size = Vector2(size.x, visual_thickness)
		visual_pos = Vector2(0, (size.y - visual_thickness) / 2)  # Centrado en la zona
	else:  # Pared vertical
		visual_size = Vector2(visual_thickness, size.y)
		visual_pos = Vector2((size.x - visual_thickness) / 2, 0)  # Centrado en la zona
	
	# Configurar visual
	visual.size = visual_size
	visual.color = color
	visual.position = visual_pos
	visual.z_index = -10  # Pared por detrás del wizard
	
	# Añadir componentes
	wall.add_child(visual)
	wall.add_child(collision)
	wall.position = pos
	wall.z_index = -10  # Asegurar que la pared esté detrás
	
	# Añadir a las paredes
	room_walls.add_child(wall)

func create_doors():
	"""Crear puertas basadas en las conexiones de la room"""
	# Limpiar puertas existentes
	for child in doors.get_children():
		child.queue_free()
	
	if not room_data:
		return
	
	# Crear puertas en direcciones válidas
	var door_size = 60.0  # Puertas apropiadas para el nuevo sistema
	var door_directions = {
		Vector2.UP: Vector2(ROOM_WIDTH/2 - door_size/2, 0),
		Vector2.DOWN: Vector2(ROOM_WIDTH/2 - door_size/2, ROOM_HEIGHT - WALL_THICKNESS),
		Vector2.LEFT: Vector2(0, ROOM_HEIGHT/2 - door_size/2),
		Vector2.RIGHT: Vector2(ROOM_WIDTH - WALL_THICKNESS, ROOM_HEIGHT/2 - door_size/2)
	}
	
	for direction in room_data.connections:
		if direction in door_directions:
			create_door(door_directions[direction], direction, door_size)

func create_door(pos: Vector2, direction: Vector2, door_size_param: float = 60.0):
	"""Crear una puerta individual"""
	var door = Area2D.new()
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	var visual = ColorRect.new()
	
	# Configurar tamaño de puerta
	var door_size = Vector2(door_size_param, door_size_param)
	
	# Configurar colisión
	rect_shape.size = door_size
	collision.shape = rect_shape
	collision.position = door_size / 2
	
	# Configurar visual
	visual.size = door_size
	visual.color = Color.BROWN if doors_locked else Color.GREEN
	visual.position = Vector2.ZERO
	
	# Configurar door
	door.add_child(visual)
	door.add_child(collision)
	door.position = pos
	door.set_meta("direction", direction)
	
	# Conectar señal
	door.body_entered.connect(_on_door_entered)
	
	doors.add_child(door)

func _on_door_entered(body):
	"""Manejar entrada del jugador a una puerta"""
	if body == player and not doors_locked:
		var door = body.get_overlapping_areas()[0] if body.get_overlapping_areas().size() > 0 else null
		if door and door.has_meta("direction"):
			var direction = door.get_meta("direction")
			player_exit_room.emit(direction)

func spawn_enemies():
	"""Generar enemigos en la room"""
	# Limpiar enemigos existentes
	for child in enemies_container.get_children():
		child.queue_free()
	
	if not room_data or room_data.is_cleared:
		return
	
	# Spawnar enemigos basado en room_data
	for i in range(room_data.max_enemies):
		spawn_enemy()
	
	# Si hay enemigos, bloquear puertas
	if enemies_container.get_child_count() > 0:
		lock_doors()

func spawn_enemy():
	"""Spawnar un enemigo individual"""
	# Crear enemigo simple para test
	var enemy = CharacterBody2D.new()
	var EnemyScript = preload("res://scripts/entities/SpellloopEnemy.gd")
	enemy.script = EnemyScript
	
	# Añadir visual simple
	var visual = ColorRect.new()
	visual.size = Vector2(32, 32)
	visual.color = Color.RED
	visual.position = Vector2(-16, -16)
	enemy.add_child(visual)
	
	# Añadir colisión
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	collision.shape = shape
	enemy.add_child(collision)
	
	# Posición aleatoria dentro de la room (evitando paredes)
	var margin = 100
	var x = randf_range(margin, ROOM_WIDTH - margin)
	var y = randf_range(margin, ROOM_HEIGHT - margin)
	enemy.position = Vector2(x, y)
	
	# Conectar señal de muerte del enemigo si existe
	if enemy.has_signal("enemy_died"):
		enemy.enemy_died.connect(_on_enemy_died)
	
	enemies_container.add_child(enemy)

func _on_enemy_died():
	"""Manejar muerte de enemigo"""
	# Verificar si todos los enemigos están muertos
	await get_tree().process_frame  # Esperar a que se procese la eliminación
	
	if enemies_container.get_child_count() == 0:
		clear_room()

func clear_room():
	"""Limpiar la room (todos los enemigos derrotados)"""
	if is_room_cleared:
		return
		
	is_room_cleared = true
	room_data.is_cleared = true
	
	unlock_doors()
	room_cleared.emit()
	
	print("✅ Room completada!")

func lock_doors():
	"""Bloquear todas las puertas"""
	doors_locked = true
	update_door_visuals()

func unlock_doors():
	"""Desbloquear todas las puertas"""
	doors_locked = false
	update_door_visuals()

func update_door_visuals():
	"""Actualizar el aspecto visual de las puertas"""
	for door in doors.get_children():
		var visual = door.get_child(0) if door.get_child_count() > 0 else null
		if visual and visual is ColorRect:
			visual.color = Color.GREEN if not doors_locked else Color.BROWN

func position_player():
	"""Posicionar al jugador en el centro de la room"""
	if player:
		player.position = Vector2(ROOM_WIDTH/2, ROOM_HEIGHT/2)

func get_room_bounds() -> Rect2:
	"""Obtener los límites de la room"""
	return Rect2(Vector2(WALL_THICKNESS, WALL_THICKNESS), 
				Vector2(ROOM_WIDTH - WALL_THICKNESS*2, ROOM_HEIGHT - WALL_THICKNESS*2))

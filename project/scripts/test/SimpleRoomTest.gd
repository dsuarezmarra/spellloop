extends Node2D

var player: CharacterBody2D
var doors: Array = []  # Array para almacenar las puertas
var enemies_remaining: int = 3  # Número de enemigos simulados

func _ready():
	print("=== TEST SIMPLE ROOM SYSTEM ===")
	create_simple_test()

func create_simple_test():
	# Crear Player
	player = CharacterBody2D.new()
	player.script = preload("res://scripts/entities/Player.gd")
	
	# Sprite del player
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	player.add_child(sprite)
	
	# Colisión del player (circular como el original)
	var collision = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 26  # Mismo radio que el Player original
	collision.shape = circle
	player.add_child(collision)
	
	add_child(player)
	
	# Posicionar jugador
	player.position = Vector2(512, 288)
	player.z_index = 20  # Por encima de todo
	
	# Crear room simple
	create_simple_room()
	
	# Crear suelo de arena
	create_sand_floor()
	
	# Crear puertas mágicas
	create_magic_doors()
	
	# Mostrar instrucciones
	print("🎮 CONTROLES:")
	print("   • ESPACIO: Derrotar enemigo simulado")
	print("   • R: Cerrar puertas y reiniciar")
	print("   • Enemigos restantes: ", enemies_remaining)
	
	print("✅ Test simple configurado")

func create_simple_room():
	"""Crear una room simple para test con colisión optimizada"""
	print("🏗️ Creando sala con colisión en borde exterior")
	
	# Crear paredes con colisión ultra-fina en borde exterior
	create_optimized_wall("top")
	create_optimized_wall("bottom") 
	create_optimized_wall("left")
	create_optimized_wall("right")
	
	# Crear puertas (aberturas en las paredes)
	create_test_door(Vector2(480, 0), "ARRIBA")
	create_test_door(Vector2(480, 512), "ABAJO")

func create_sand_floor():
	"""Crear suelo de arena clara para toda el área de juego"""
	print("🏖️ Creando suelo de arena clara")
	
	# Crear nodo para el suelo
	var sand_floor = Node2D.new()
	var floor_visual = TextureRect.new()
	
	# Área del suelo (toda el área de juego interior)
	var floor_pos = Vector2(32, 32)  # Después de las paredes
	var floor_size = Vector2(960, 512)  # Área interior sin paredes
	
	# Crear textura de arena
	var sand_texture = MagicWallTextures.create_sand_floor_texture(floor_size)
	
	# Si falla la textura procedural, usar fallback
	if not sand_texture:
		print("⚠️ Usando textura de fallback para el suelo")
		sand_texture = create_sand_fallback_texture(floor_size)
	
	# Configurar visual del suelo
	floor_visual.texture = sand_texture
	floor_visual.size = floor_size
	floor_visual.position = Vector2(0, 0)  # Relativo al sand_floor node
	floor_visual.z_index = 1  # Por encima del fondo pero debajo de paredes
	floor_visual.stretch_mode = TextureRect.STRETCH_KEEP  # No repetir, mantener textura única
	
	# Debug: verificar que la textura se creó
	if sand_texture:
		print("🏖️ Textura de arena creada - Tamaño: ", sand_texture.get_size())
	else:
		print("❌ ERROR: No se pudo crear textura de arena")
	
	# Ensamblar suelo
	sand_floor.add_child(floor_visual)
	sand_floor.position = floor_pos
	sand_floor.z_index = 1  # Por encima del fondo
	
	add_child(sand_floor)
	print("✅ Suelo de arena creado - Área: ", floor_size, " en posición ", floor_pos)

func create_magic_doors():
	"""Crear puertas mágicas perfectamente alineadas con el grosor de pared (32px)"""
	print("🚪 Creando puertas mágicas perfectamente dimensionadas")
	
	# DIMENSIONES EXACTAS: Las puertas deben tener el EXACTO grosor de pared
	var wall_thickness = 32.0
	var door_width = wall_thickness        # Ancho = grosor de pared exacto
	var door_height = wall_thickness * 1.5 # Alto proporcionado (48px)
	
	# POSICIONES EXACTAS alineadas a los bordes exteriores
	# Puerta superior - en el borde superior (y=0) centrada horizontalmente
	create_single_door("top", 
		Vector2(512 - door_width/2, 0),  # Centrada en X, pegada arriba
		Vector2(door_width, door_height), 0)
	
	# Puerta derecha - en el borde derecho (x=1024-32) centrada verticalmente  
	create_single_door("right", 
		Vector2(1024 - wall_thickness, 288 - door_width/2),  # Pegada a la derecha, centrada en Y
		Vector2(door_height, door_width), 90)  # Rotada 90°
	
	# Puerta inferior - en el borde inferior (y=576-32) centrada horizontalmente
	create_single_door("bottom", 
		Vector2(512 - door_width/2, 576 - wall_thickness),  # Centrada en X, pegada abajo
		Vector2(door_width, door_height), 180)  # Rotada 180°
	
	# Puerta izquierda - en el borde izquierdo (x=0) centrada verticalmente
	create_single_door("left", 
		Vector2(0, 288 - door_width/2),  # Pegada a la izquierda, centrada en Y
		Vector2(door_height, door_width), 270)  # Rotada 270°
	
	print("✅ Puertas mágicas perfectamente alineadas creadas: ", doors.size())

func create_single_door(direction: String, pos: Vector2, size: Vector2, rotation_deg: float):
	"""Crear una puerta individual perfectamente posicionada"""
	var door = Node2D.new()
	var door_visual = TextureRect.new()
	
	# Crear textura de puerta cerrada inicialmente
	var door_texture = MagicWallTextures.create_magic_door_texture(false, size)
	
	# Configurar visual de la puerta
	door_visual.texture = door_texture
	door_visual.size = size
	door_visual.position = Vector2(-size.x/2, -size.y/2)  # Centrar en el pivot
	door_visual.z_index = 15  # Por encima de paredes
	
	# Configurar rotación
	door.rotation_degrees = rotation_deg
	
	# POSICIONAMIENTO PRECISO: El pivot debe estar en el centro de la puerta
	# pero la puerta debe estar perfectamente alineada en el borde
	var pivot_pos = pos
	
	match direction:
		"top":
			# Puerta superior: pivot en el centro inferior de la puerta
			pivot_pos = Vector2(pos.x + size.x/2, pos.y + size.y/2)
		"bottom":
			# Puerta inferior: pivot en el centro superior de la puerta  
			pivot_pos = Vector2(pos.x + size.x/2, pos.y + size.y/2)
		"left":
			# Puerta izquierda: pivot en el centro derecho de la puerta
			pivot_pos = Vector2(pos.x + size.x/2, pos.y + size.y/2)
		"right":
			# Puerta derecha: pivot en el centro izquierdo de la puerta
			pivot_pos = Vector2(pos.x + size.x/2, pos.y + size.y/2)
	
	# Ensamblar puerta
	door.add_child(door_visual)
	door.position = pivot_pos
	door.z_index = 15
	
	# Datos de la puerta para control
	var door_data = {
		"node": door,
		"visual": door_visual,
		"direction": direction,
		"size": size,
		"is_open": false,
		"rotation": rotation_deg
	}
	
	doors.append(door_data)
	add_child(door)
	
	print("🚪 Puerta ", direction, " creada en ", pos, " con rotación ", rotation_deg, "°")

func _input(event):
	"""Control de prueba - presionar ESPACIO para simular eliminar enemigo"""
	if event.is_action_pressed("ui_accept"):  # Tecla ESPACIO
		simulate_enemy_defeated()
	elif event.is_action_pressed("ui_cancel"):  # Tecla ESC (o R si está mapeada)
		close_all_doors()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		close_all_doors()

func simulate_enemy_defeated():
	"""Simular la derrota de un enemigo"""
	if enemies_remaining > 0:
		enemies_remaining -= 1
		print("👾 Enemigo derrotado! Enemigos restantes: ", enemies_remaining)
		
		if enemies_remaining == 0:
			print("🎉 ¡Todos los enemigos derrotados! Abriendo puertas...")
			open_all_doors()
		
func open_all_doors():
	"""Abrir todas las puertas cuando no quedan enemigos"""
	for door_data in doors:
		if not door_data.is_open:
			# Crear nueva textura de puerta abierta
			var open_texture = MagicWallTextures.create_magic_door_texture(true, door_data.size)
			door_data.visual.texture = open_texture
			door_data.is_open = true
			
			print("✨ Puerta ", door_data.direction, " abierta!")

func close_all_doors():
	"""Cerrar todas las puertas (para pruebas)"""
	for door_data in doors:
		if door_data.is_open:
			# Crear nueva textura de puerta cerrada
			var closed_texture = MagicWallTextures.create_magic_door_texture(false, door_data.size)
			door_data.visual.texture = closed_texture
			door_data.is_open = false
			
			print("🚪 Puerta ", door_data.direction, " cerrada!")
	
	# Reiniciar enemigos para otra prueba
	enemies_remaining = 3
	print("🔄 Enemigos reiniciados: ", enemies_remaining)

func create_optimized_wall(wall_type: String):
	"""Crear pared con colisión solo en borde exterior y texturas de ladrillos de castillo"""
	var wall = StaticBody2D.new()
	var collision = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	var visual = TextureRect.new()  # TextureRect para texturas de ladrillos
	
	# Grosor de colisión ultra-fino
	var collision_thickness = 1.0
	
	# Configurar según el tipo de pared
	var collision_pos: Vector2
	var collision_size: Vector2
	var visual_pos: Vector2
	var visual_size: Vector2
	var wall_pos: Vector2
	
	match wall_type:
		"top":
			# Colisión en el borde superior absoluto (y=0)
			wall_pos = Vector2(0, 0)
			collision_pos = Vector2(512, 0.5)  # Centro en x, borde en y
			collision_size = Vector2(1024, collision_thickness)
			# Visual con grosor reducido a la mitad (32 píxeles)
			visual_pos = Vector2(0, 0)  # Desde el borde mismo
			visual_size = Vector2(1024, 32)  # Grosor reducido a la mitad
			
		"bottom":
			# Colisión en el borde inferior absoluto (y=575)
			wall_pos = Vector2(0, 575)
			collision_pos = Vector2(512, 0.5)
			collision_size = Vector2(1024, collision_thickness)
			# Visual con grosor reducido a la mitad
			visual_pos = Vector2(0, -31)  # Ajustado para grosor reducido
			visual_size = Vector2(1024, 32)  # Grosor reducido a la mitad
			
		"left":
			# Colisión en el borde izquierdo absoluto (x=0)
			wall_pos = Vector2(0, 0)
			collision_pos = Vector2(0.5, 288)  # Borde en x, centro en y
			collision_size = Vector2(collision_thickness, 576)
			# Visual con grosor reducido a la mitad
			visual_pos = Vector2(0, 0)  # Desde el borde mismo
			visual_size = Vector2(32, 576)  # Grosor reducido a la mitad
			
		"right":
			# Colisión en el borde derecho absoluto (x=1023)
			wall_pos = Vector2(1023, 0)
			collision_pos = Vector2(0.5, 288)
			collision_size = Vector2(collision_thickness, 576)
			# Visual con grosor reducido a la mitad
			visual_pos = Vector2(-31, 0)  # Ajustado para grosor reducido
			visual_size = Vector2(32, 576)  # Grosor reducido a la mitad
	
	# Configurar colisión
	rect_shape.size = collision_size
	collision.shape = rect_shape
	collision.position = collision_pos
	
	# Crear textura de ladrillos de castillo
	var brick_texture = MagicWallTextures.create_magic_wall_texture(wall_type, visual_size)
	
	# Debug: verificar que la textura se creó correctamente
	if brick_texture:
		print("🧱 Textura de ladrillos creada para ", wall_type, " - Tamaño: ", brick_texture.get_size())
	else:
		print("❌ ERROR: No se pudo crear textura para ", wall_type)
		# Crear textura de fallback sólida
		brick_texture = create_fallback_texture(visual_size)
	
	# Configurar visual con textura de ladrillos
	visual.texture = brick_texture
	visual.size = visual_size
	visual.position = visual_pos
	visual.z_index = 10  # Por encima del suelo
	visual.stretch_mode = TextureRect.STRETCH_TILE  # Repetir textura si es necesario
	
	# Ensamblar pared
	wall.add_child(visual)
	wall.add_child(collision)
	wall.position = wall_pos
	wall.z_index = 10  # Por encima del suelo
	
	add_child(wall)
	print("✅ Pared de ladrillos ", wall_type, " creada - Grosor reducido: ", visual_size, " en posición ", visual_pos)

func create_fallback_texture(size: Vector2) -> ImageTexture:
	"""Crear textura de fallback simple"""
	var image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	image.fill(Color(0.6, 0.4, 0.2, 1.0))  # Color marrón simple
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func create_sand_fallback_texture(size: Vector2) -> ImageTexture:
	"""Crear textura de fallback simple para el suelo de arena"""
	var image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	image.fill(Color(0.9, 0.8, 0.65, 1.0))  # Color arena simple
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func create_test_door(pos: Vector2, label: String):
	"""Crear puerta de test"""
	var door = ColorRect.new()
	door.size = Vector2(64, 64)
	door.color = Color.GREEN
	door.position = pos
	door.z_index = -5  # Encima de paredes pero debajo del wizard
	add_child(door)
	
	# Label para la puerta
	var door_label = Label.new()
	door_label.text = label
	door_label.position = Vector2(10, 10)
	door_label.add_theme_color_override("font_color", Color.BLACK)
	door.add_child(door_label)
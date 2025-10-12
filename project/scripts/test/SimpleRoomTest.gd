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
	
	print("✅ Sala básica creada")

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
	"""Crear puertas mágicas perfectamente alineadas - COINCIDENCIA EXACTA con paredes"""
	print("🚪 Creando puertas con dimensiones EXACTAS de paredes")
	
	# DIMENSIONES EXACTAS de las paredes según create_optimized_wall
	var wall_thickness = 32.0  # Mismo grosor exacto que visual_size de paredes
	var door_base_width = wall_thickness    # 32px - coincidencia exacta
	var door_base_height = wall_thickness  # 32px - coincidencia exacta con grosor de pared
	
	# TODAS las puertas usan las mismas dimensiones base
	var door_size = Vector2(door_base_width, door_base_height)
	
	# POSICIONES EXACTAS - Coinciden con las posiciones visuales reales de las paredes
	# Puerta superior - Pared visual: Y=0 a Y=32, centro en Y=16
	create_single_door("top", 
		Vector2(512, 16),  # Centro horizontal de pantalla, centro vertical de pared superior
		door_size, 0)
	
	# Puerta derecha - Pared visual: X=992 a X=1024, centro en X=1008  
	create_single_door("right", 
		Vector2(1008, 288),  # Centro de pared derecha, centro vertical de pantalla
		door_size, 90)
	
	# Puerta inferior - Pared visual: Y=544 a Y=576, centro en Y=560
	create_single_door("bottom", 
		Vector2(512, 560),  # Centro horizontal de pantalla, centro vertical de pared inferior
		door_size, 180)
	
	# Puerta izquierda - Pared visual: X=0 a X=32, centro en X=16
	create_single_door("left", 
		Vector2(16, 288),  # Centro de pared izquierda, centro vertical de pantalla
		door_size, 270)
	
	print("✅ Puertas con coincidencia EXACTA de grosor creadas: ", doors.size())

func create_single_door(direction: String, pos: Vector2, size: Vector2, rotation_deg: float):
	"""Crear una puerta individual - TODAS IGUALES, solo rotadas"""
	var door = Node2D.new()
	var door_visual = Sprite2D.new()  # CAMBIAR A Sprite2D para control exacto de tamaño
	
	# Crear textura de puerta cerrada inicialmente - MISMA TEXTURA PARA TODAS
	var door_texture = MagicWallTextures.create_magic_door_texture(false, size)
	
	# Configurar visual de la puerta con Sprite2D
	door_visual.texture = door_texture
	# Calcular escala para que coincida exactamente con el tamaño deseado
	var texture_size = door_texture.get_size()
	var scale_x = size.x / texture_size.x
	var scale_y = size.y / texture_size.y
	door_visual.scale = Vector2(scale_x, scale_y)
	door_visual.z_index = 15  # Por encima de paredes
	
	print("🚪 DEBUG VISUAL: size=", size, " texture_size=", texture_size, " scale=", door_visual.scale)
	print("🚪 DEBUG POSICIÓN: pos=", pos, " door.position será=", pos)
	print("🚪 DEBUG COMPARACIÓN: Pared grosor=32px, Puerta ancho=", size.x, "px, Escala=", scale_x)
	
	# Configurar rotación - SIMPLE, sin cálculos complicados
	door.rotation_degrees = rotation_deg
	
	# Ensamblar puerta - POSICIÓN DIRECTA
	door.add_child(door_visual)
	door.position = pos  # Usar posición directamente
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
			
			# Actualizar escala para Sprite2D
			var texture_size = open_texture.get_size()
			var scale_x = door_data.size.x / texture_size.x
			var scale_y = door_data.size.y / texture_size.y
			door_data.visual.scale = Vector2(scale_x, scale_y)
			
			door_data.is_open = true
			
			print("✨ Puerta ", door_data.direction, " abierta!")

func close_all_doors():
	"""Cerrar todas las puertas (para pruebas)"""
	for door_data in doors:
		if door_data.is_open:
			# Crear nueva textura de puerta cerrada
			var closed_texture = MagicWallTextures.create_magic_door_texture(false, door_data.size)
			door_data.visual.texture = closed_texture
			
			# Actualizar escala para Sprite2D
			var texture_size = closed_texture.get_size()
			var scale_x = door_data.size.x / texture_size.x
			var scale_y = door_data.size.y / texture_size.y
			door_data.visual.scale = Vector2(scale_x, scale_y)
			
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
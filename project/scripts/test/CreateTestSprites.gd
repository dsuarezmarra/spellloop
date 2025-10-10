# CreateTestSprites.gd - Crea sprites de prueba programáticamente
extends Node2D

func _ready():
	print("🎨 CREANDO SPRITES DE PRUEBA PROGRAMÁTICOS")
	print("=========================================")
	
	create_test_sprites()

func create_test_sprites():
	# Crear sprites de prueba con colores diferentes para cada dirección
	var sprite_configs = [
		{
			"name": "wizard_down",
			"color": Color.BLUE,
			"direction": "DOWN",
			"position": Vector2(100, 100)
		},
		{
			"name": "wizard_up", 
			"color": Color.RED,
			"direction": "UP",
			"position": Vector2(250, 100)
		},
		{
			"name": "wizard_left",
			"color": Color.GREEN,
			"direction": "LEFT", 
			"position": Vector2(400, 100)
		},
		{
			"name": "wizard_right",
			"color": Color.YELLOW,
			"direction": "RIGHT",
			"position": Vector2(550, 100)
		}
	]
	
	for config in sprite_configs:
		create_and_save_sprite(config)

func create_and_save_sprite(config):
	print("🎨 Creando sprite: ", config.name)
	
	# Crear imagen de 64x64
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	
	# Rellenar con color base
	image.fill(config.color)
	
	# Añadir detalles para que parezca un mago
	add_wizard_details(image, config.color, config.direction)
	
	# Crear textura
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	
	# Crear sprite visual para mostrar
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.position = config.position
	sprite.scale = Vector2(2.0, 2.0)
	add_child(sprite)
	
	# Guardar como archivo PNG
	save_sprite_to_file(image, config.name)
	
	# Añadir etiqueta
	var label = Label.new()
	label.text = config.name + "\n" + config.direction
	label.position = config.position + Vector2(-30, 80)
	add_child(label)

func add_wizard_details(image: Image, base_color: Color, direction: String):
	# Añadir sombrero (parte superior)
	var hat_color = Color.PURPLE
	for y in range(5, 15):
		for x in range(20, 44):
			image.set_pixel(x, y, hat_color)
	
	# Añadir cara (centro)
	var skin_color = Color(1.0, 0.8, 0.6)  # Piel
	for y in range(15, 35):
		for x in range(25, 39):
			image.set_pixel(x, y, skin_color)
	
	# Añadir ojos
	image.set_pixel(28, 22, Color.BLACK)
	image.set_pixel(35, 22, Color.BLACK)
	
	# Añadir túnica (parte inferior)
	var robe_color = base_color.darkened(0.3)
	for y in range(35, 60):
		for x in range(20, 44):
			image.set_pixel(x, y, robe_color)
	
	# Detalles específicos según dirección
	match direction:
		"DOWN":
			# Bastón en la mano
			for y in range(25, 55):
				image.set_pixel(45, y, Color(0.6, 0.3, 0.1))  # Marrón
		"UP":
			# Vista de atrás - capucha
			for y in range(10, 25):
				for x in range(22, 42):
					image.set_pixel(x, y, hat_color)
		"LEFT":
			# Perfil izquierdo
			image.set_pixel(30, 22, Color.BLACK)  # Un ojo
		"RIGHT":
			# Perfil derecho  
			image.set_pixel(33, 22, Color.BLACK)  # Un ojo

func save_sprite_to_file(image: Image, filename: String):
	var path = "user://" + filename + "_test.png"
	var error = image.save_png(path)
	if error == OK:
		print("  ✅ Guardado en: ", path)
	else:
		print("  ❌ Error guardando: ", error)
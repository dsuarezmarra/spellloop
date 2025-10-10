# CreateValidPNGSprites.gd - Genera PNG válidos usando método más robusto
extends Node2D

func _ready():
	print("🎨 CREANDO PNG VÁLIDOS CON MÉTODO ROBUSTO")
	print("=======================================")
	
	create_valid_png_sprites()

func create_valid_png_sprites():
	var sprite_configs = [
		{
			"filename": "wizard_down.png",
			"color": Color(0.4, 0.2, 0.8, 1.0),  # Púrpura con alpha explícito
			"direction": "DOWN",
			"position": Vector2(100, 100)
		},
		{
			"filename": "wizard_up.png", 
			"color": Color(0.3, 0.1, 0.7, 1.0),  # Púrpura oscuro
			"direction": "UP",
			"position": Vector2(250, 100)
		},
		{
			"filename": "wizard_left.png",
			"color": Color(0.5, 0.3, 0.9, 1.0),  # Púrpura claro
			"direction": "LEFT", 
			"position": Vector2(400, 100)
		},
		{
			"filename": "wizard_right.png",
			"color": Color(0.45, 0.25, 0.85, 1.0), # Púrpura medio
			"direction": "RIGHT",
			"position": Vector2(550, 100)
		}
	]
	
	for config in sprite_configs:
		create_robust_sprite(config)

func create_robust_sprite(config):
	print("🎨 Generando PNG robusto: ", config.filename)
	
	# Crear imagen con especificaciones muy claras
	var size = 64
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Fondo completamente transparente
	for y in range(size):
		for x in range(size):
			image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	# Dibujar sprite con píxeles sólidos
	draw_solid_wizard(image, config.color, config.direction)
	
	# Crear textura para visualización
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	
	# Mostrar sprite en pantalla
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.position = config.position
	sprite.scale = Vector2(3.0, 3.0)  # Más grande para ver mejor
	add_child(sprite)
	
	# Etiqueta
	var label = Label.new()
	label.text = config.filename + "\n" + config.direction
	label.position = config.position + Vector2(-40, 110)
	add_child(label)
	
	# Guardar con método robusto
	save_robust_png(image, config.filename)

func draw_solid_wizard(image: Image, base_color: Color, direction: String):
	var size = image.get_width()
	var center_x = size / 2
	
	# Colores sólidos
	var hat_color = Color(0.5, 0.0, 0.5, 1.0)  # Púrpura sombrero
	var skin_color = Color(1.0, 0.9, 0.8, 1.0)  # Piel
	var eye_color = Color(0.0, 0.0, 0.0, 1.0)   # Ojos negros
	
	# Dibujar sombrero (triángulo en la parte superior)
	for y in range(5, 20):
		var width = 20 - (y - 5)  # Triángulo
		for x in range(center_x - width/2, center_x + width/2):
			if x >= 0 and x < size and y >= 0 and y < size:
				image.set_pixel(x, y, hat_color)
	
	# Dibujar cabeza (círculo)
	var head_center_y = 28
	var head_radius = 12
	for y in range(head_center_y - head_radius, head_center_y + head_radius):
		for x in range(center_x - head_radius, center_x + head_radius):
			if x >= 0 and x < size and y >= 0 and y < size:
				var dist = sqrt((x - center_x) * (x - center_x) + (y - head_center_y) * (y - head_center_y))
				if dist <= head_radius:
					image.set_pixel(x, y, skin_color)
	
	# Dibujar ojos
	image.set_pixel(center_x - 4, head_center_y - 2, eye_color)
	image.set_pixel(center_x + 4, head_center_y - 2, eye_color)
	image.set_pixel(center_x - 3, head_center_y - 2, eye_color)
	image.set_pixel(center_x + 3, head_center_y - 2, eye_color)
	
	# Dibujar túnica (rectángulo)
	for y in range(40, size - 5):
		for x in range(center_x - 18, center_x + 18):
			if x >= 0 and x < size and y >= 0 and y < size:
				image.set_pixel(x, y, base_color)
	
	# Detalles específicos por dirección
	match direction:
		"DOWN":
			# Añadir bastón
			for y in range(25, size - 10):
				if center_x + 20 < size:
					image.set_pixel(center_x + 20, y, Color(0.6, 0.3, 0.1, 1.0))
		"LEFT":
			# Perfil - solo un ojo
			image.set_pixel(center_x - 4, head_center_y - 2, Color(0, 0, 0, 0))  # Quitar ojo izquierdo
		"RIGHT":
			# Perfil - solo un ojo
			image.set_pixel(center_x + 4, head_center_y - 2, Color(0, 0, 0, 0))  # Quitar ojo derecho

func save_robust_png(image: Image, filename: String):
	# Obtener ruta absoluta del proyecto
	var project_path = ProjectSettings.globalize_path("res://sprites/wizard/")
	var full_path = project_path + filename
	
	# Guardar PNG
	var error = image.save_png(full_path)
	
	if error == OK:
		print("  ✅ PNG válido guardado: ", full_path)
		
		# Verificar que el archivo se creó correctamente
		if FileAccess.file_exists("res://sprites/wizard/" + filename):
			print("  ✅ Archivo verificado en Godot filesystem")
		else:
			print("  ❌ Archivo no detectado en Godot filesystem")
	else:
		print("  ❌ Error guardando PNG: ", error)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			print("🔄 Presiona Project → Reload Current Project")
			print("🧪 Luego ejecuta TestSpriteRobust.tscn")
			print("🎮 Si funciona, ejecuta IsaacSpriteViewer.tscn")
		elif event.keycode == KEY_SPACE:
			print("📊 Estado actual de archivos:")
			for filename in ["wizard_down.png", "wizard_up.png", "wizard_left.png", "wizard_right.png"]:
				var path = "res://sprites/wizard/" + filename
				if FileAccess.file_exists(path):
					print("  ✅ ", filename, " - Existe")
				else:
					print("  ❌ ", filename, " - No existe")
# FixSpriteLocation.gd - Corrige la ubicación de guardado de sprites
extends Node2D

func _ready():
	print("🔧 MOVIENDO SPRITES A UBICACIÓN CORRECTA")
	print("=======================================")
	
	# Primero, verificar si los sprites temporales existen
	var temp_files = [
		"user://wizard_down_test.png",
		"user://wizard_up_test.png",
		"user://wizard_left_test.png",
		"user://wizard_right_test.png"
	]
	
	var target_files = [
		"res://sprites/wizard/wizard_down.png",
		"res://sprites/wizard/wizard_up.png",
		"res://sprites/wizard/wizard_left.png",
		"res://sprites/wizard/wizard_right.png"
	]
	
	# Crear sprites directamente en la ubicación correcta
	create_sprites_in_project_folder()

func create_sprites_in_project_folder():
	print("📁 Creando sprites directamente en sprites/wizard/")
	
	var sprite_configs = [
		{
			"filename": "wizard_down.png",
			"color": Color(0.4, 0.2, 0.8),  # Púrpura
			"direction": "DOWN",
			"position": Vector2(100, 100)
		},
		{
			"filename": "wizard_up.png", 
			"color": Color(0.3, 0.1, 0.7),  # Púrpura oscuro
			"direction": "UP",
			"position": Vector2(250, 100)
		},
		{
			"filename": "wizard_left.png",
			"color": Color(0.5, 0.3, 0.9),  # Púrpura claro
			"direction": "LEFT", 
			"position": Vector2(400, 100)
		},
		{
			"filename": "wizard_right.png",
			"color": Color(0.45, 0.25, 0.85), # Púrpura medio
			"direction": "RIGHT",
			"position": Vector2(550, 100)
		}
	]
	
	for config in sprite_configs:
		create_and_save_sprite_correctly(config)

func create_and_save_sprite_correctly(config):
	print("🎨 Creando: ", config.filename)
	
	# Crear imagen de 64x64
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	
	# Fondo transparente
	image.fill(Color.TRANSPARENT)
	
	var base_color = config.color
	var hat_color = Color.PURPLE
	var skin_color = Color(1.0, 0.9, 0.8)
	
	# Dibujar mago simple
	# Túnica (cuerpo principal)
	for y in range(20, 60):
		for x in range(18, 46):
			image.set_pixel(x, y, base_color)
	
	# Cabeza
	for y in range(8, 25):
		for x in range(22, 42):
			var dist = sqrt((x - 32) * (x - 32) + (y - 16) * (y - 16))
			if dist < 10:
				image.set_pixel(x, y, skin_color)
	
	# Sombrero
	for y in range(2, 18):
		var width = max(1, 18 - y)
		for x in range(32 - width/2, 32 + width/2):
			if x >= 0 and x < 64:
				image.set_pixel(x, y, hat_color)
	
	# Ojos
	image.set_pixel(28, 14, Color.BLACK)
	image.set_pixel(36, 14, Color.BLACK)
	
	# Crear sprite visual para mostrar
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.position = config.position
	sprite.scale = Vector2(2.0, 2.0)
	add_child(sprite)
	
	# Guardar en la ubicación del proyecto
	var project_path = ProjectSettings.globalize_path("res://sprites/wizard/")
	var full_path = project_path + config.filename
	
	var error = image.save_png(full_path)
	if error == OK:
		print("  ✅ Guardado correctamente: res://sprites/wizard/", config.filename)
	else:
		print("  ❌ Error guardando: ", error)
	
	# Añadir etiqueta
	var label = Label.new()
	label.text = config.filename + "\n" + config.direction
	label.position = config.position + Vector2(-30, 80)
	add_child(label)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			print("🔄 Presiona Project → Reload Current Project")
			print("🧪 Luego ejecuta TestSpriteRobust.tscn")
			print("✅ Los sprites deberían cargar correctamente ahora")
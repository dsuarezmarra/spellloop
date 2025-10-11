# CreateWorkingSprites.gd - Generador simple y funcional de sprites
extends EditorScript

func _run():
	print("🎨 CREANDO SPRITES SIMPLES Y FUNCIONALES")
	print("=======================================")
	
	var sprite_dir = ProjectSettings.globalize_path("res://sprites/wizard/")
	
	# Crear sprites básicos pero funcionales
	create_simple_sprite("wizard_down.png", Color(0.4, 0.2, 0.8), sprite_dir)
	create_simple_sprite("wizard_up.png", Color(0.3, 0.1, 0.7), sprite_dir)
	create_simple_sprite("wizard_left.png", Color(0.5, 0.3, 0.9), sprite_dir)
	create_simple_sprite("wizard_right.png", Color(0.45, 0.25, 0.85), sprite_dir)
	
	print("✅ 4 sprites simples creados exitosamente")
	print("🔄 Ejecuta Project → Reload Current Project")
	print("🧪 Luego prueba TestSpriteRobust.tscn")

func create_simple_sprite(filename: String, color: Color, sprite_dir: String):
	print("🎨 Creando: ", filename)
	
	# Crear imagen simple de 64x64
	var size = 64
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Fondo transparente
	image.fill(Color.TRANSPARENT)
	
	# Dibujar un mago simple
	# Cuerpo principal (rectángulo)
	for y in range(20, size - 5):
		for x in range(15, size - 15):
			image.set_pixel(x, y, color)
	
	# Cabeza (círculo simple)
	var head_color = Color(1.0, 0.9, 0.8)  # Piel
	for y in range(5, 25):
		for x in range(20, size - 20):
			var dist = sqrt((x - size/2) * (x - size/2) + (y - 15) * (y - 15))
			if dist < 10:
				image.set_pixel(x, y, head_color)
	
	# Sombrero (triángulo simple)
	var hat_color = Color.PURPLE
	for y in range(0, 15):
		var width = max(1, 15 - y)
		for x in range(size/2 - width/2, size/2 + width/2):
			if x >= 0 and x < size:
				image.set_pixel(x, y, hat_color)
	
	# Ojos simples
	image.set_pixel(size/2 - 3, 12, Color.BLACK)
	image.set_pixel(size/2 + 3, 12, Color.BLACK)
	
	# Guardar archivo
	var full_path = sprite_dir + filename
	var error = image.save_png(full_path)
	
	if error == OK:
		print("  ✅ Guardado: ", full_path)
	else:
		print("  ❌ Error guardando: ", error)

# GenerateCompatibleSprites.gd - Genera sprites compatibles para reemplazar los problemáticos
extends EditorScript

func _run():
	print("🔧 GENERANDO SPRITES COMPATIBLES")
	print("================================")
	
	var sprite_dir = "res://sprites/wizard/"
	
	# Configuraciones para cada sprite
	var sprite_configs = [
		{
			"filename": "wizard_down.png",
			"color": Color(0.4, 0.2, 0.8),  # Púrpura
			"direction": "DOWN"
		},
		{
			"filename": "wizard_up.png", 
			"color": Color(0.3, 0.1, 0.7),  # Púrpura oscuro
			"direction": "UP"
		},
		{
			"filename": "wizard_left.png",
			"color": Color(0.5, 0.3, 0.9),  # Púrpura claro
			"direction": "LEFT"
		},
		{
			"filename": "wizard_right.png",
			"color": Color(0.45, 0.25, 0.85), # Púrpura medio
			"direction": "RIGHT"
		}
	]
	
	for config in sprite_configs:
		generate_sprite_file(config, sprite_dir)
	
	print("✅ Sprites compatibles generados")
	print("💡 Ejecuta Project → Reload Current Project")
	print("🧪 Luego prueba TestSpriteRobust.tscn de nuevo")

func generate_sprite_file(config: Dictionary, sprite_dir: String):
	print("🎨 Generando: ", config.filename)
	
	# Crear imagen más grande para mayor detalle
	var size = 128
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Fondo transparente
	image.fill(Color.TRANSPARENT)
	
	# Color base del mago
	var base_color = config.color
	var hat_color = Color.PURPLE
	var skin_color = Color(1.0, 0.9, 0.8)
	var robe_color = base_color
	
	# Dibujar el mago según la dirección
	match config.direction:
		"DOWN":
			draw_wizard_front(image, size, hat_color, skin_color, robe_color)
		"UP":
			draw_wizard_back(image, size, hat_color, robe_color)
		"LEFT":
			draw_wizard_side(image, size, hat_color, skin_color, robe_color, true)
		"RIGHT":
			draw_wizard_side(image, size, hat_color, skin_color, robe_color, false)
	
	# Guardar en la ubicación correcta
	var full_path = sprite_dir + config.filename
	var file_path = full_path.replace("res://", "")
	
	# Convertir la ruta para el sistema de archivos
	var system_path = ProjectSettings.globalize_path("res://") + file_path
	
	var error = image.save_png(system_path)
	if error == OK:
		print("  ✅ Guardado: ", full_path)
	else:
		print("  ❌ Error: ", error, " - ", system_path)

func draw_wizard_front(image: Image, size: int, hat_color: Color, skin_color: Color, robe_color: Color):
	var center = size / 2
	
	# Sombrero puntiagudo
	draw_triangle(image, Vector2(center, 10), Vector2(center-20, 40), Vector2(center+20, 40), hat_color)
	
	# Cara
	draw_circle(image, Vector2(center, 50), 15, skin_color)
	
	# Ojos
	image.set_pixel(center-5, 45, Color.BLACK)
	image.set_pixel(center+5, 45, Color.BLACK)
	
	# Barba
	draw_triangle(image, Vector2(center, 55), Vector2(center-8, 70), Vector2(center+8, 70), Color.WHITE)
	
	# Túnica
	draw_rectangle(image, Vector2(center-25, 70), Vector2(center+25, size-10), robe_color)
	
	# Bastón
	draw_line(image, Vector2(center+30, 60), Vector2(center+30, size-20), Color(0.6, 0.3, 0.1))
	draw_circle(image, Vector2(center+30, 55), 5, Color.YELLOW)

func draw_wizard_back(image: Image, size: int, hat_color: Color, robe_color: Color):
	var center = size / 2
	
	# Capucha
	draw_circle(image, Vector2(center, 35), 25, hat_color)
	
	# Túnica trasera
	draw_rectangle(image, Vector2(center-25, 60), Vector2(center+25, size-10), robe_color)

func draw_wizard_side(image: Image, size: int, hat_color: Color, skin_color: Color, robe_color: Color, facing_left: bool):
	var center = size / 2
	var x_offset = 10 if facing_left else -10
	
	# Sombrero de perfil
	draw_triangle(image, Vector2(center+x_offset, 15), Vector2(center-15+x_offset, 40), Vector2(center+15+x_offset, 40), hat_color)
	
	# Cara de perfil
	draw_circle(image, Vector2(center+x_offset, 50), 12, skin_color)
	
	# Ojo
	var eye_x = center + (3 if facing_left else -3) + x_offset
	image.set_pixel(eye_x, 45, Color.BLACK)
	
	# Túnica
	draw_rectangle(image, Vector2(center-20+x_offset, 65), Vector2(center+20+x_offset, size-10), robe_color)

func draw_circle(image: Image, center: Vector2, radius: int, color: Color):
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if x*x + y*y <= radius*radius:
				var px = int(center.x + x)
				var py = int(center.y + y)
				if px >= 0 and px < image.get_width() and py >= 0 and py < image.get_height():
					image.set_pixel(px, py, color)

func draw_rectangle(image: Image, top_left: Vector2, bottom_right: Vector2, color: Color):
	for y in range(int(top_left.y), int(bottom_right.y) + 1):
		for x in range(int(top_left.x), int(bottom_right.x) + 1):
			if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				image.set_pixel(x, y, color)

func draw_triangle(image: Image, p1: Vector2, p2: Vector2, p3: Vector2, color: Color):
	# Implementación simple de triángulo relleno
	var min_y = int(min(p1.y, min(p2.y, p3.y)))
	var max_y = int(max(p1.y, max(p2.y, p3.y)))
	
	for y in range(min_y, max_y + 1):
		var intersections = []
		
		# Encontrar intersecciones con los lados del triángulo
		check_line_intersection(p1, p2, y, intersections)
		check_line_intersection(p2, p3, y, intersections)
		check_line_intersection(p3, p1, y, intersections)
		
		intersections.sort()
		
		if intersections.size() >= 2:
			for x in range(int(intersections[0]), int(intersections[-1]) + 1):
				if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
					image.set_pixel(x, y, color)

func check_line_intersection(p1: Vector2, p2: Vector2, y: int, intersections: Array):
	if (p1.y <= y and y <= p2.y) or (p2.y <= y and y <= p1.y):
		if p2.y != p1.y:
			var x = p1.x + (y - p1.y) * (p2.x - p1.x) / (p2.y - p1.y)
			intersections.append(x)

func draw_line(image: Image, from: Vector2, to: Vector2, color: Color):
	var distance = from.distance_to(to)
	var steps = int(distance)
	
	for i in range(steps + 1):
		var t = float(i) / float(steps) if steps > 0 else 0.0
		var point = from.lerp(to, t)
		var x = int(point.x)
		var y = int(point.y)
		
		if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
			image.set_pixel(x, y, color)
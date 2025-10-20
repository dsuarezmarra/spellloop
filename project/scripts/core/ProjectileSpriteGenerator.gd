extends Node
# ProjectileSpriteGenerator.gd
# Genera sprites de proyectiles en tiempo de ejecución usando dibujado en canvas

class_name ProjectileSpriteGenerator

static func generate_all_projectile_sprites() -> bool:
	"""Genera todas las imágenes de proyectiles desde cero"""
	var projectiles = ["arcane_bolt", "dark_missile", "fireball", "ice_shard"]
	var colors = {
		"arcane_bolt": {"primary": Color("#9B59B6"), "accent": Color("#D7BDE2")},
		"dark_missile": {"primary": Color("#2C3E50"), "accent": Color("#566573")},
		"fireball": {"primary": Color("#E74C3C"), "accent": Color("#F8B88B")},
		"ice_shard": {"primary": Color("#5DADE2"), "accent": Color("#AED6F1")}
	}
	
	var base_path = "res://assets/sprites/projectiles/"
	var animations = ["Launch", "InFlight", "Impact"]
	var frame_count = 10
	
	for projectile in projectiles:
		for animation in animations:
			for frame in range(frame_count):
				var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
				image.fill(Color.TRANSPARENT)
				
				var color_data = colors[projectile]
				var primary = color_data["primary"]
				var accent = color_data["accent"]
				
				# Generar sprite según tipo de animación
				match animation:
					"Launch":
						_draw_launch_frame(image, primary, accent, frame, frame_count)
					"InFlight":
						_draw_inflight_frame(image, primary, accent, frame, frame_count)
					"Impact":
						_draw_impact_frame(image, primary, accent, frame, frame_count)
				
				# Guardar imagen
				var file_name = "%s_%s_%02d.png" % [animation, projectile, frame]
				var save_path = "%s%s/%s" % [base_path, projectile, file_name]
				
				var error = image.save_png(save_path)
				if error != OK:
					print_debug("❌ Error guardando %s: %d" % [save_path, error])
					return false
				else:
					print_debug("✅ Generado: %s" % save_path)
	
	return true

static func _draw_launch_frame(image: Image, primary: Color, accent: Color, frame: int, total: int) -> void:
	"""Dibuja frame de lanzamiento: energía expandiéndose desde el centro"""
	var center = Vector2(32, 32)
	var progress = float(frame) / total
	var max_radius = 20 + int(progress * 10)
	
	# Dibuja rayos radiales
	for angle in range(0, 360, 30):
		var angle_rad = deg_to_rad(angle)
		var start = center
		var end = center + Vector2(cos(angle_rad), sin(angle_rad)) * max_radius
		_draw_line(image, start, end, accent, 2)
	
	# Círculo central que crece
	_draw_circle(image, center, int(5 + progress * 8), primary)
	_draw_circle(image, center, int(3 + progress * 5), Color.WHITE)

static func _draw_inflight_frame(image: Image, primary: Color, accent: Color, frame: int, total: int) -> void:
	"""Dibuja frame en vuelo: proyectil con estela"""
	var center = Vector2(32, 32)
	var _progress = float(frame) / total
	
	# Estela trasera (gradual)
	var trail_positions = [
		center - Vector2(8, 0),
		center - Vector2(12, 0),
		center - Vector2(16, 0)
	]
	
	for i in range(trail_positions.size()):
		var alpha = 0.3 - (i * 0.1)
		var trail_color = Color(accent.r, accent.g, accent.b, alpha)
		_draw_circle(image, trail_positions[i], 4, trail_color)
	
	# Proyectil principal
	_draw_circle(image, center, 8, primary)
	_draw_circle(image, center + Vector2(2, 2), 5, accent)
	_draw_circle(image, center - Vector2(3, 1), 2, Color.WHITE)

static func _draw_impact_frame(image: Image, primary: Color, accent: Color, frame: int, total: int) -> void:
	"""Dibuja frame de impacto: explosión de partículas"""
	var center = Vector2(32, 32)
	var _progress = float(frame) / total
	var max_radius = int(_progress * 25)
	
	# Anillo de explosión
	_draw_circle_outline(image, center, max_radius, primary, 2)
	_draw_circle_outline(image, center, int(max_radius * 0.7), accent, 1)
	
	# Partículas radiales
	for angle in range(0, 360, 45):
		var angle_rad = deg_to_rad(angle)
		var particle_pos = center + Vector2(cos(angle_rad), sin(angle_rad)) * max_radius
		_draw_circle(image, particle_pos, 2, accent)

static func _draw_circle(image: Image, center: Vector2, radius: int, color: Color) -> void:
	"""Dibuja círculo relleno"""
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			if x*x + y*y <= radius*radius:
				var px = int(center.x) + x
				var py = int(center.y) + y
				if 0 <= px < 64 and 0 <= py < 64:
					image.set_pixel(px, py, color)

static func _draw_circle_outline(image: Image, center: Vector2, radius: int, color: Color, width: int) -> void:
	"""Dibuja contorno de círculo"""
	for angle in range(0, 360, 1):
		var angle_rad = deg_to_rad(angle)
		for w in range(width):
			var r = radius + w - int(width/2.0)
			if r > 0:
				var x = int(center.x + cos(angle_rad) * r)
				var y = int(center.y + sin(angle_rad) * r)
				if 0 <= x and x < 64 and 0 <= y and y < 64:
					image.set_pixel(x, y, color)

static func _draw_line(image: Image, from: Vector2, to: Vector2, color: Color, width: int) -> void:
	"""Dibuja línea usando algoritmo de Bresenham"""
	var dx = abs(to.x - from.x)
	var dy = abs(to.y - from.y)
	var x = from.x
	var y = from.y
	var x_step = 1 if to.x > from.x else -1
	var y_step = 1 if to.y > from.y else -1
	var width_half = int(width/2.0)
	
	if dx > dy:
		var err = dx / 2.0
		while x != to.x:
			for w in range(-width_half, width_half + 1):
				_set_pixel_safe(image, int(x), int(y + w), color)
			err -= dy
			if err < 0:
				y += y_step
				err += dx
			x += x_step
	else:
		var err = dy / 2.0
		while y != to.y:
			for w in range(-width_half, width_half + 1):
				_set_pixel_safe(image, int(x + w), int(y), color)
			err -= dx
			if err < 0:
				x += x_step
				err += dy
			y += y_step

static func _set_pixel_safe(image: Image, x: int, y: int, color: Color) -> void:
	"""Set pixel con límites de seguridad"""
	if x >= 0 and x < 64 and y >= 0 and y < 64:
		image.set_pixel(x, y, color)

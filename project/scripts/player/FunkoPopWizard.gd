# FunkoPopWizard.gd
# Creates an authentic Funko Pop style wizard sprite with animation system

extends RefCounted
class_name FunkoPopWizard

# Sistema de animación y direcciones
enum Direction { DOWN, UP, LEFT, RIGHT }
enum AnimFrame { IDLE, WALK1, WALK2 }

static func create_wizard_sprite(direction: Direction = Direction.DOWN, frame: AnimFrame = AnimFrame.IDLE) -> Texture2D:
	# Crear imagen más grande para el estilo Funko Pop auténtico
	var img = Image.create(96, 112, false, Image.FORMAT_RGBA8)
	
	# Fondo transparente
	img.fill(Color.TRANSPARENT)
	
	# Colores mejorados estilo Funko Pop auténtico
	var skin_color = Color(0.96, 0.87, 0.77)  # Tono piel más natural
	var robe_blue = Color(0.12, 0.22, 0.68)   # Azul más profundo y vibrante
	var gold_trim = Color(0.95, 0.87, 0.35)   # Dorado brillante
	var hat_purple = Color(0.35, 0.15, 0.75)  # Púrpura intenso
	var beard_white = Color(0.98, 0.98, 0.98) # Blanco puro
	var orb_glow = Color(0.7, 0.9, 1.0)       # Azul mágico
	var shadow_color = Color(0.0, 0.0, 0.0, 0.3) # Sombras sutiles
	
	# Ajustes de animación
	var head_offset_y = 0
	var body_offset_y = 0
	var arm_swing = 0
	var leg_offset = 0
	
	match frame:
		AnimFrame.WALK1:
			head_offset_y = -1
			body_offset_y = 1
			arm_swing = -2
			leg_offset = 2
		AnimFrame.WALK2:
			head_offset_y = 1
			body_offset_y = -1
			arm_swing = 2
			leg_offset = -2
	
	# CABEZA GRANDE estilo Funko Pop (proporción 1:2 cabeza:cuerpo)
	var head_x = 48
	var head_y = 32 + head_offset_y
	var head_radius = 26
	
	# Sombra sutil debajo de la cabeza
	_draw_ellipse_filled(img, head_x, head_y + 2, head_radius + 2, head_radius - 2, shadow_color)
	# Cabeza principal
	_draw_circle_filled(img, head_x, head_y, head_radius, skin_color)
	
	# OJOS GRANDES Y NEGROS (característica más distintiva de Funko Pop)
	var eye_size = 5
	var eye_left_x = head_x - 8
	var eye_right_x = head_x + 8
	var eye_y = head_y - 2
	
	# Ajustar dirección de la mirada
	match direction:
		Direction.LEFT:
			eye_left_x -= 2
			eye_right_x -= 2
		Direction.RIGHT:
			eye_left_x += 2
			eye_right_x += 2
	
	_draw_circle_filled(img, eye_left_x, eye_y, eye_size, Color.BLACK)
	_draw_circle_filled(img, eye_right_x, eye_y, eye_size, Color.BLACK)
	
	# Reflejos blancos en los ojos
	_draw_circle_filled(img, eye_left_x + 1, eye_y - 1, 2, Color.WHITE)
	_draw_circle_filled(img, eye_right_x + 1, eye_y - 1, 2, Color.WHITE)
	
	# SOMBRERO DE MAGO CON ESTRELLA Y GEMA
	var hat_base_y = head_y - head_radius + 5
	# Base circular del sombrero
	_draw_circle_filled(img, head_x, hat_base_y, 22, hat_purple)
	# Borde dorado del sombrero
	_draw_circle_outline(img, head_x, hat_base_y, 22, 2, gold_trim)
	
	# Punta cónica del sombrero
	_draw_triangle_filled(img, head_x, hat_base_y - 35, head_x - 15, hat_base_y - 5, head_x + 15, hat_base_y - 5, hat_purple)
	
	# Estrella dorada grande en el sombrero
	_draw_star(img, head_x, hat_base_y - 10, 6, gold_trim)
	# Gema púrpura en el centro de la estrella
	_draw_circle_filled(img, head_x, hat_base_y - 10, 3, Color(0.9, 0.1, 1.0))
	
	# BARBA BLANCA VOLUMINOSA
	var beard_y = head_y + 10
	# Bigote grueso
	_draw_rounded_rect_filled(img, head_x - 8, head_y + 5, 16, 4, beard_white)
	
	# Barba triangular más grande
	_draw_triangle_filled(img, head_x, beard_y + 25, head_x - 12, beard_y, head_x + 12, beard_y, beard_white)
	
	# Textura de la barba con líneas
	for i in range(3):
		var line_x = head_x - 6 + i * 6
		_draw_vertical_line(img, line_x, beard_y + 2, 20, 1, Color(0.9, 0.9, 0.9))
	
	# CUERPO PEQUEÑO (proporción Funko Pop auténtica)
	var body_x = head_x - 16
	var body_y = head_y + head_radius + 10 + body_offset_y
	var body_width = 32
	var body_height = 40
	
	# Sombra del cuerpo
	_draw_rounded_rect_filled(img, body_x + 2, body_y + 2, body_width, body_height, shadow_color)
	# Túnica azul principal
	_draw_rounded_rect_filled(img, body_x, body_y, body_width, body_height, robe_blue)
	
	# Detalles dorados elaborados en la túnica
	_draw_rounded_rect_outline(img, body_x, body_y, body_width, body_height, 3, gold_trim)
	
	# Patrones decorativos dorados
	_draw_horizontal_line(img, body_x + 4, body_y + 8, body_width - 8, 2, gold_trim)
	_draw_horizontal_line(img, body_x + 6, body_y + 16, body_width - 12, 2, gold_trim)
	_draw_vertical_line(img, head_x, body_y + 4, body_height - 8, 3, gold_trim)
	
	# Símbolos mágicos en la túnica
	_draw_small_star(img, body_x + 8, body_y + 12, 2, gold_trim)
	_draw_small_star(img, body_x + body_width - 8, body_y + 12, 2, gold_trim)
	
	# BRAZOS CON ANIMACIÓN
	var arm_left_x = body_x - 6
	var arm_right_x = body_x + body_width + 2
	var arm_y = body_y + 8
	var arm_length = 24
	
	# Ajustar swing de brazos según frame
	var left_arm_offset = arm_swing
	var right_arm_offset = -arm_swing
	
	# Brazo izquierdo
	_draw_rounded_rect_filled(img, arm_left_x, arm_y + left_arm_offset, 8, arm_length, robe_blue)
	_draw_rounded_rect_outline(img, arm_left_x, arm_y + left_arm_offset, 8, arm_length, 1, gold_trim)
	
	# Brazo derecho
	_draw_rounded_rect_filled(img, arm_right_x, arm_y + right_arm_offset, 8, arm_length, robe_blue)
	_draw_rounded_rect_outline(img, arm_right_x, arm_y + right_arm_offset, 8, arm_length, 1, gold_trim)
	
	# MANOS
	var hand_left_y = arm_y + arm_length + left_arm_offset
	var hand_right_y = arm_y + arm_length + right_arm_offset
	
	_draw_circle_filled(img, arm_left_x + 4, hand_left_y, 5, skin_color)
	_draw_circle_filled(img, arm_right_x + 4, hand_right_y, 5, skin_color)
	
	# ORBE MÁGICO EN LA MANO DERECHA (más elaborado)
	var orb_x = arm_right_x + 4
	var orb_y = hand_right_y - 4
	
	# Aura del orbe
	_draw_circle_filled(img, orb_x, orb_y, 8, Color(orb_glow.r, orb_glow.g, orb_glow.b, 0.3))
	# Orbe principal
	_draw_circle_filled(img, orb_x, orb_y, 6, orb_glow)
	# Núcleo brillante
	_draw_circle_filled(img, orb_x, orb_y, 4, Color(0.9, 0.95, 1.0))
	# Reflejo
	_draw_circle_filled(img, orb_x - 2, orb_y - 2, 2, Color.WHITE)
	
	# PIERNAS CON ANIMACIÓN DE CAMINAR
	var leg_y = body_y + body_height
	var leg_width = 10
	var leg_height = 20
	
	var leg_left_x = head_x - 8
	var leg_right_x = head_x + 2
	
	# Ajustar posición de piernas según la animación
	match direction:
		Direction.LEFT, Direction.RIGHT:
			if frame == AnimFrame.WALK1:
				leg_left_x += leg_offset
				leg_right_x -= leg_offset
			elif frame == AnimFrame.WALK2:
				leg_left_x -= leg_offset
				leg_right_x += leg_offset
	
	# Piernas
	_draw_rounded_rect_filled(img, leg_left_x, leg_y, leg_width, leg_height, robe_blue)
	_draw_rounded_rect_filled(img, leg_right_x, leg_y, leg_width, leg_height, robe_blue)
	
	# ZAPATOS PUNTIAGUDOS MÁGICOS
	var shoe_y = leg_y + leg_height
	_draw_rounded_rect_filled(img, leg_left_x - 2, shoe_y, 14, 6, Color(0.15, 0.1, 0.05))
	_draw_rounded_rect_filled(img, leg_right_x - 2, shoe_y, 14, 6, Color(0.15, 0.1, 0.05))
	
	# Puntas curvadas de los zapatos
	_draw_circle_filled(img, leg_left_x + 12, shoe_y + 3, 3, Color(0.15, 0.1, 0.05))
	_draw_circle_filled(img, leg_right_x + 12, shoe_y + 3, 3, Color(0.15, 0.1, 0.05))
	
	# EFECTOS MÁGICOS DINÁMICOS (más sparkles, ajustados al frame)
	var sparkle_offset = 0
	if frame == AnimFrame.WALK1:
		sparkle_offset = 3
	elif frame == AnimFrame.WALK2:
		sparkle_offset = -3
	
	_draw_sparkle(img, 15 + sparkle_offset, 25, Color(1.0, 1.0, 0.0))
	_draw_sparkle(img, 75 - sparkle_offset, 30, Color(0.8, 0.2, 1.0))
	_draw_sparkle(img, 25 + sparkle_offset, 50, Color(0.2, 1.0, 0.8))
	_draw_sparkle(img, 70 - sparkle_offset, 55, Color(1.0, 0.5, 0.2))
	_draw_sparkle(img, 20 + sparkle_offset, 80, Color(0.5, 0.8, 1.0))
	_draw_sparkle(img, 75 - sparkle_offset, 75, Color(1.0, 0.8, 0.2))
	
	# Rastro mágico del orbe
	for i in range(3):
		var trail_x = orb_x - (i + 1) * 4
		var trail_y = orb_y + i * 2
		var alpha = 0.7 - i * 0.2
		_draw_circle_filled(img, trail_x, trail_y, 3 - i, Color(orb_glow.r, orb_glow.g, orb_glow.b, alpha))
	
	var texture = ImageTexture.new()
	texture.set_image(img)
	return texture

# ============= FUNCIONES DE DIBUJO AUXILIARES =============

static func _draw_circle_filled(img: Image, x: int, y: int, radius: int, color: Color):
	for i in range(-radius, radius + 1):
		for j in range(-radius, radius + 1):
			if i * i + j * j <= radius * radius:
				var px = x + i
				var py = y + j
				if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
					img.set_pixel(px, py, color)

static func _draw_ellipse_filled(img: Image, x: int, y: int, width: int, height: int, color: Color):
	for i in range(-width, width + 1):
		for j in range(-height, height + 1):
			var dx = float(i) / float(width) if width > 0 else 0
			var dy = float(j) / float(height) if height > 0 else 0
			if dx * dx + dy * dy <= 1.0:
				var px = x + i
				var py = y + j
				if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
					img.set_pixel(px, py, color)

static func _draw_circle_outline(img: Image, x: int, y: int, radius: int, thickness: int, color: Color):
	for t in range(thickness):
		var r = radius + t
		for angle in range(0, 360, 2):
			var rad = deg_to_rad(angle)
			var px = x + int(cos(rad) * r)
			var py = y + int(sin(rad) * r)
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				img.set_pixel(px, py, color)

static func _draw_rounded_rect_filled(img: Image, x: int, y: int, width: int, height: int, color: Color):
	# Rectángulo principal
	for i in range(x + 2, x + width - 2):
		for j in range(y, y + height):
			if i >= 0 and i < img.get_width() and j >= 0 and j < img.get_height():
				img.set_pixel(i, j, color)
	
	# Lados verticales con esquinas redondeadas
	for j in range(y + 2, y + height - 2):
		for side in range(2):
			var px = x + side * (width - 1)
			if px >= 0 and px < img.get_width() and j >= 0 and j < img.get_height():
				img.set_pixel(px, j, color)

static func _draw_rounded_rect_outline(img: Image, x: int, y: int, width: int, height: int, thickness: int, color: Color):
	for t in range(thickness):
		# Líneas horizontales
		for i in range(x + 2, x + width - 2):
			var top_y = y + t
			var bottom_y = y + height - 1 - t
			if i >= 0 and i < img.get_width():
				if top_y >= 0 and top_y < img.get_height():
					img.set_pixel(i, top_y, color)
				if bottom_y >= 0 and bottom_y < img.get_height():
					img.set_pixel(i, bottom_y, color)
		
		# Líneas verticales
		for j in range(y + 2, y + height - 2):
			var left_x = x + t
			var right_x = x + width - 1 - t
			if j >= 0 and j < img.get_height():
				if left_x >= 0 and left_x < img.get_width():
					img.set_pixel(left_x, j, color)
				if right_x >= 0 and right_x < img.get_width():
					img.set_pixel(right_x, j, color)

static func _draw_triangle_filled(img: Image, x1: int, y1: int, x2: int, y2: int, x3: int, y3: int, color: Color):
	var min_y = min(y1, min(y2, y3))
	var max_y = max(y1, max(y2, y3))
	
	for y in range(min_y, max_y + 1):
		var intersections = []
		
		# Encontrar intersecciones con cada lado del triángulo
		var sides = [[x1, y1, x2, y2], [x2, y2, x3, y3], [x3, y3, x1, y1]]
		
		for side in sides:
			var sx1 = side[0]
			var sy1 = side[1] 
			var sx2 = side[2]
			var sy2 = side[3]
			
			if (sy1 <= y and y < sy2) or (sy2 <= y and y < sy1):
				if sy2 != sy1:
					var x = sx1 + (y - sy1) * (sx2 - sx1) / (sy2 - sy1)
					intersections.append(x)
		
		intersections.sort()
		
		# Rellenar entre intersecciones pares
		for i in range(0, intersections.size() - 1, 2):
			var start_x = int(intersections[i])
			var end_x = int(intersections[i + 1])
			for x in range(start_x, end_x + 1):
				if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
					img.set_pixel(x, y, color)

static func _draw_horizontal_line(img: Image, x: int, y: int, length: int, thickness: int, color: Color):
	for i in range(length):
		for t in range(thickness):
			var px = x + i
			var py = y + t
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				img.set_pixel(px, py, color)

static func _draw_vertical_line(img: Image, x: int, y: int, length: int, thickness: int, color: Color):
	for i in range(length):
		for t in range(thickness):
			var px = x + t
			var py = y + i
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				img.set_pixel(px, py, color)

static func _draw_star(img: Image, x: int, y: int, size: int, color: Color):
	# Estrella de 5 puntas más definida
	var points = []
	for i in range(10):
		var angle = deg_to_rad(i * 36 - 90)  # -90 para que apunte hacia arriba
		var radius = size if i % 2 == 0 else size * 0.4
		var px = x + int(cos(angle) * radius)
		var py = y + int(sin(angle) * radius)
		points.append([px, py])
	
	# Dibujar triángulos para formar la estrella
	for i in range(0, 10, 2):
		var p1 = points[i]
		var p2 = points[(i + 2) % 10]
		var p3 = points[(i + 4) % 10]
		_draw_triangle_filled(img, p1[0], p1[1], p2[0], p2[1], p3[0], p3[1], color)

static func _draw_small_star(img: Image, x: int, y: int, size: int, color: Color):
	# Estrella pequeña simple
	_draw_horizontal_line(img, x - size, y, size * 2 + 1, 1, color)
	_draw_vertical_line(img, x, y - size, size * 2 + 1, 1, color)
	# Diagonales
	for i in range(-size, size + 1):
		var px1 = x + i
		var py1 = y + i
		var px2 = x + i  
		var py2 = y - i
		if px1 >= 0 and px1 < img.get_width() and py1 >= 0 and py1 < img.get_height():
			img.set_pixel(px1, py1, color)
		if px2 >= 0 and px2 < img.get_width() and py2 >= 0 and py2 < img.get_height():
			img.set_pixel(px2, py2, color)

static func _draw_sparkle(img: Image, x: int, y: int, color: Color):
	# Sparkle en forma de cruz con destellos
	var offsets = [
		[0, -3], [0, 3], [-3, 0], [3, 0],  # Cruz principal
		[-2, -2], [2, 2], [-2, 2], [2, -2], # Diagonales
		[0, 0]  # Centro
	]
	
	for offset in offsets:
		var px = x + offset[0]
		var py = y + offset[1]
		if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
			img.set_pixel(px, py, color)

func _draw_circle_on_image(image: Image, center: Vector2, radius: int, color: Color):
	for x in range(max(0, center.x - radius), min(image.get_width(), center.x + radius + 1)):
		for y in range(max(0, center.y - radius), min(image.get_height(), center.y + radius + 1)):
			var distance = center.distance_to(Vector2(x, y))
			if distance <= radius:
				image.set_pixel(x, y, color)

func _draw_rounded_rect_on_image(image: Image, top_left: Vector2, bottom_right: Vector2, color: Color):
	for x in range(top_left.x, bottom_right.x + 1):
		for y in range(top_left.y, bottom_right.y + 1):
			# Simple rounded corners by skipping corner pixels
			var is_corner_x = (x <= top_left.x + 2 or x >= bottom_right.x - 2)
			var is_corner_y = (y <= top_left.y + 2 or y >= bottom_right.y - 2)
			
			if not (is_corner_x and is_corner_y):
				image.set_pixel(x, y, color)

func _draw_wizard_hat_on_image(image: Image, hat_color: Color, star_color: Color, gem_color: Color):
	# Hat brim (horizontal oval)
	_draw_oval_on_image(image, Vector2(40, 18), 26, 4, hat_color)
	
	# Hat cone (triangle with curve)
	for y in range(5, 19):
		var width = 24 - ((y - 5) * 1.5)
		var start_x = 40 - width / 2
		_draw_horizontal_line_on_image(image, Vector2(start_x, y), width, 1, hat_color)
	
	# Hat tip with curve
	_draw_circle_on_image(image, Vector2(40, 5), 2, hat_color)
	
	# Star on hat (bigger)
	_draw_enhanced_star_on_image(image, Vector2(40, 10), star_color)
	
	# Gem on hat brim
	_draw_circle_on_image(image, Vector2(40, 18), 2, gem_color)
	_draw_circle_on_image(image, Vector2(40, 18), 1, Color.WHITE)

func _draw_mustache_on_image(image: Image, color: Color):
	# Small mustache above beard
	_draw_horizontal_line_on_image(image, Vector2(35, 35), 10, 2, color)
	_draw_circle_on_image(image, Vector2(37, 36), 2, color)
	_draw_circle_on_image(image, Vector2(43, 36), 2, color)

func _draw_enhanced_beard_on_image(image: Image, color: Color):
	# Fuller triangular beard with texture
	for y in range(38, 48):
		var width = (y - 38) * 1.2 + 6
		var start_x = 40 - width / 2
		_draw_horizontal_line_on_image(image, Vector2(start_x, y), width, 1, color)
	
	# Beard texture lines
	for i in range(3):
		var line_y = 40 + i * 3
		_draw_horizontal_line_on_image(image, Vector2(37, line_y), 6, 1, Color(0.85, 0.85, 0.85))

func _draw_rounded_rect_outline(image: Image, top_left: Vector2, bottom_right: Vector2, color: Color, thickness: int):
	# Draw outline of rounded rectangle
	for t in range(thickness):
		# Top and bottom lines
		_draw_horizontal_line_on_image(image, Vector2(top_left.x + 3, top_left.y + t), bottom_right.x - top_left.x - 6, 1, color)
		_draw_horizontal_line_on_image(image, Vector2(top_left.x + 3, bottom_right.y - t), bottom_right.x - top_left.x - 6, 1, color)
		
		# Left and right lines
		for y in range(top_left.y + 3, bottom_right.y - 2):
			if top_left.x + t >= 0 and top_left.x + t < image.get_width():
				image.set_pixel(top_left.x + t, y, color)
			if bottom_right.x - t >= 0 and bottom_right.x - t < image.get_width():
				image.set_pixel(bottom_right.x - t, y, color)

func _draw_oval_on_image(image: Image, center: Vector2, width: int, height: int, color: Color):
	for x in range(center.x - width/2, center.x + width/2 + 1):
		for y in range(center.y - height/2, center.y + height/2 + 1):
			var dx = (x - center.x) / float(width/2)
			var dy = (y - center.y) / float(height/2)
			if dx*dx + dy*dy <= 1.0:
				if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
					image.set_pixel(x, y, color)

func _draw_enhanced_star_on_image(image: Image, center: Vector2, color: Color):
	# Larger, more detailed star
	var star_points = [
		Vector2(0, -6), Vector2(2, -2), Vector2(6, -2), Vector2(3, 1),
		Vector2(4, 6), Vector2(0, 3), Vector2(-4, 6), Vector2(-3, 1),
		Vector2(-6, -2), Vector2(-2, -2)
	]
	
	# Fill the star
	for i in range(0, star_points.size(), 2):
		var p1 = center + star_points[i]
		var p2 = center + star_points[(i + 2) % star_points.size()]
		_draw_thick_line_on_image(image, p1, p2, color, 2)
	
	# Star center
	_draw_circle_on_image(image, center, 2, color)

func _draw_thick_line_on_image(image: Image, from: Vector2, to: Vector2, color: Color, thickness: int):
	for t in range(thickness):
		for side in range(thickness):
			var offset = Vector2(t - thickness/2, side - thickness/2)
			_draw_line_on_image(image, from + offset, to + offset, color)

func _draw_enhanced_sparkles_on_image(image: Image):
	var sparkle_colors = [Color.CYAN, Color.YELLOW, Color.MAGENTA, Color.WHITE]
	var positions = [
		Vector2(15, 25), Vector2(65, 30), Vector2(10, 45), Vector2(70, 50),
		Vector2(8, 65), Vector2(72, 70), Vector2(12, 80), Vector2(68, 85),
		Vector2(20, 15), Vector2(60, 20)
	]
	
	for i in range(positions.size()):
		var color = sparkle_colors[i % sparkle_colors.size()]
		_draw_enhanced_sparkle_at(image, positions[i], color)

func _draw_enhanced_sparkle_at(image: Image, center: Vector2, color: Color):
	# Enhanced sparkle with multiple shapes
	var patterns = [
		[Vector2(0, -3), Vector2(0, 3), Vector2(-3, 0), Vector2(3, 0), Vector2(0, 0)],  # Cross
		[Vector2(-2, -2), Vector2(2, 2), Vector2(-2, 2), Vector2(2, -2), Vector2(0, 0)]   # X
	]
	
	var pattern = patterns[randi() % patterns.size()]
	for offset in pattern:
		var pos = center + offset
		if pos.x >= 0 and pos.x < image.get_width() and pos.y >= 0 and pos.y < image.get_height():
			image.set_pixel(pos.x, pos.y, color)

func _draw_beard_on_image(image: Image, color: Color):
	# Triangular beard
	for y in range(30, 40):
		var width = (y - 30) + 4
		var start_x = 32 - width / 2
		_draw_horizontal_line_on_image(image, Vector2(start_x, y), width, 1, color)

func _draw_horizontal_line_on_image(image: Image, start: Vector2, length: int, thickness: int, color: Color):
	for x in range(start.x, start.x + length):
		for t in range(thickness):
			var y = start.y + t
			if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
				image.set_pixel(x, y, color)

func _draw_star_on_image(image: Image, center: Vector2, color: Color):
	# Simple 5-point star
	var points = [
		Vector2(0, -4), Vector2(1, -1), Vector2(4, -1), Vector2(2, 1),
		Vector2(3, 4), Vector2(0, 2), Vector2(-3, 4), Vector2(-2, 1),
		Vector2(-4, -1), Vector2(-1, -1)
	]
	
	for i in range(0, points.size(), 2):
		var p1 = center + points[i]
		var p2 = center + points[(i + 2) % points.size()]
		_draw_line_on_image(image, p1, p2, color)

func _draw_line_on_image(image: Image, from: Vector2, to: Vector2, color: Color):
	var distance = from.distance_to(to)
	var steps = int(distance)
	
	for i in range(steps + 1):
		var t = float(i) / float(steps) if steps > 0 else 0.0
		var point = from.lerp(to, t)
		var x = int(point.x)
		var y = int(point.y)
		if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
			image.set_pixel(x, y, color)

func _draw_sparkles_on_image(image: Image):
	var sparkle_color = Color.CYAN
	var positions = [
		Vector2(10, 20), Vector2(54, 25), Vector2(8, 60), Vector2(56, 65),
		Vector2(5, 35), Vector2(58, 40)
	]
	
	for pos in positions:
		_draw_sparkle_at(image, pos, sparkle_color)

func _draw_sparkle_at(image: Image, center: Vector2, color: Color):
	# Simple cross-shaped sparkle
	var offsets = [Vector2(0, -2), Vector2(0, 2), Vector2(-2, 0), Vector2(2, 0), Vector2(0, 0)]
	for offset in offsets:
		var pos = center + offset
		if pos.x >= 0 and pos.x < image.get_width() and pos.y >= 0 and pos.y < image.get_height():
			image.set_pixel(pos.x, pos.y, color)
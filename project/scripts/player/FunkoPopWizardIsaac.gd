# FunkoPopWizardIsaac.gd
# Creates Isaac-style sprites with Funko Pop characteristics and magical theme

extends RefCounted
class_name FunkoPopWizardIsaac

# Sistema de animación y direcciones
enum Direction { DOWN, UP, LEFT, RIGHT }
enum AnimFrame { IDLE, WALK1, WALK2 }

# Isaac-style Funko Pop Mago - Rediseñado completamente
static func create_wizard_sprite(direction: Direction, frame: AnimFrame) -> ImageTexture:
	# Tamaño optimizado estilo Isaac
	var img = Image.create(48, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	# Colores del mago mágico
	var skin_color = Color(1.0, 0.9, 0.8)
	var robe_color = Color(0.2, 0.1, 0.7)  # Azul mágico profundo
	var hat_color = Color(0.15, 0.05, 0.5)  # Azul más oscuro
	var star_color = Color(1.0, 1.0, 0.3)  # Amarillo dorado
	var beard_color = Color(0.8, 0.8, 0.8)  # Gris claro
	var eye_color = Color.BLACK
	
	# Ajustes según el frame de animación
	var head_offset = 0
	var body_bounce = 0
	if frame == AnimFrame.WALK1:
		head_offset = 1
		body_bounce = 1
	elif frame == AnimFrame.WALK2:
		head_offset = -1
		body_bounce = -1
	
	# CABEZA (estilo Isaac + Funko Pop)
	var head_center_x = 24
	var head_center_y = 18 + head_offset
	var head_width = 26
	var head_height = 22
	
	# Forma de cabeza Isaac-style pero más cuadrada (Funko Pop)
	_draw_isaac_funko_head(img, head_center_x, head_center_y, head_width, head_height, skin_color)
	
	# OJOS FUNKO POP GRANDES
	var eye_y = head_center_y - 2
	var left_eye_x = head_center_x - 6
	var right_eye_x = head_center_x + 6
	
	# Ojos grandes circulares negros (característica Funko Pop)
	_draw_circle_filled(img, left_eye_x, eye_y, 4, Color.WHITE)
	_draw_circle_filled(img, right_eye_x, eye_y, 4, Color.WHITE)
	_draw_circle_filled(img, left_eye_x, eye_y, 3, eye_color)
	_draw_circle_filled(img, right_eye_x, eye_y, 3, eye_color)
	
	# Pequeño brillo en los ojos
	img.set_pixel(left_eye_x - 1, eye_y - 1, Color.WHITE)
	img.set_pixel(right_eye_x - 1, eye_y - 1, Color.WHITE)
	
	# SOMBRERO DE MAGO (estilo Isaac pero más blocky)
	_draw_wizard_hat_isaac_style(img, head_center_x, head_center_y - head_height/2 - 2, hat_color, star_color)
	
	# BARBA PEQUEÑA (característica de mago)
	var beard_y = head_center_y + head_height/2 - 4
	_draw_isaac_beard(img, head_center_x, beard_y, beard_color)
	
	# CUERPO PEQUEÑO (muy estilo Isaac)
	var body_center_x = head_center_x
	var body_center_y = 45 + body_bounce
	var body_width = 16
	var body_height = 14
	
	# Túnica mágica
	_draw_isaac_body(img, body_center_x, body_center_y, body_width, body_height, robe_color)
	
	# BRAZOS (muy simples estilo Isaac)
	_draw_isaac_arms(img, body_center_x, body_center_y, direction, frame, robe_color)
	
	# EFECTOS MÁGICOS SUTILES
	if frame != AnimFrame.IDLE:
		_draw_magic_sparkle(img, head_center_x + 12, head_center_y - 8, star_color)
		_draw_magic_sparkle(img, head_center_x - 10, head_center_y + 5, star_color)
	
	var texture = ImageTexture.new()
	texture.set_image(img)
	return texture

# Cabeza estilo Isaac con características Funko Pop
static func _draw_isaac_funko_head(img: Image, center_x: int, center_y: int, width: int, height: int, color: Color):
	# Forma ovalada con esquinas más cuadradas (mezcla Isaac + Funko Pop)
	for y in range(center_y - height/2, center_y + height/2):
		for x in range(center_x - width/2, center_x + width/2):
			var dx = float(x - center_x) / (width/2.0)
			var dy = float(y - center_y) / (height/2.0)
			
			# Ecuación elíptica modificada para ser más cuadrada
			var distance = dx*dx*0.8 + dy*dy*0.9
			if distance <= 1.0:
				if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
					img.set_pixel(x, y, color)

# Sombrero de mago estilo Isaac
static func _draw_wizard_hat_isaac_style(img: Image, center_x: int, top_y: int, hat_color: Color, star_color: Color):
	# Base del sombrero
	var base_width = 20
	var base_height = 4
	for y in range(top_y, top_y + base_height):
		for x in range(center_x - base_width/2, center_x + base_width/2):
			if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
				img.set_pixel(x, y, hat_color)
	
	# Parte cónica del sombrero
	var cone_height = 16
	for i in range(cone_height):
		var y = top_y - i
		var cone_width = max(2, base_width - i)
		for x in range(center_x - cone_width/2, center_x + cone_width/2):
			if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
				img.set_pixel(x, y, hat_color)
	
	# Estrella en la punta
	var star_y = top_y - cone_height + 2
	_draw_simple_star(img, center_x, star_y, star_color)

# Barba simple estilo Isaac
static func _draw_isaac_beard(img: Image, center_x: int, center_y: int, color: Color):
	# Barba muy simple y pequeña
	var beard_points = [
		Vector2(center_x - 3, center_y),
		Vector2(center_x - 2, center_y + 1),
		Vector2(center_x - 1, center_y + 2),
		Vector2(center_x, center_y + 3),
		Vector2(center_x + 1, center_y + 2),
		Vector2(center_x + 2, center_y + 1),
		Vector2(center_x + 3, center_y)
	]
	
	for point in beard_points:
		if point.x >= 0 and point.x < img.get_width() and point.y >= 0 and point.y < img.get_height():
			img.set_pixel(point.x, point.y, color)

# Cuerpo estilo Isaac
static func _draw_isaac_body(img: Image, center_x: int, center_y: int, width: int, height: int, color: Color):
	# Cuerpo ovalado muy simple
	for y in range(center_y - height/2, center_y + height/2):
		for x in range(center_x - width/2, center_x + width/2):
			var dx = float(x - center_x) / (width/2.0)
			var dy = float(y - center_y) / (height/2.0)
			
			if dx*dx + dy*dy <= 1.0:
				if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
					img.set_pixel(x, y, color)

# Brazos estilo Isaac
static func _draw_isaac_arms(img: Image, body_x: int, body_y: int, direction: Direction, frame: AnimFrame, color: Color):
	var arm_length = 6
	var arm_width = 3
	
	# Posición de brazos según dirección
	var left_arm_x = body_x - 8
	var right_arm_x = body_x + 8
	var arm_y = body_y - 2
	
	# Movimiento de brazos según frame
	var left_offset = 0
	var right_offset = 0
	if frame == AnimFrame.WALK1:
		left_offset = 1
		right_offset = -1
	elif frame == AnimFrame.WALK2:
		left_offset = -1
		right_offset = 1
	
	# Dibujar brazos simples
	for i in range(arm_width):
		for j in range(arm_length):
			# Brazo izquierdo
			var left_x = left_arm_x
			var left_y = arm_y + j + left_offset
			if left_x >= 0 and left_x < img.get_width() and left_y >= 0 and left_y < img.get_height():
				img.set_pixel(left_x, left_y, color)
			
			# Brazo derecho
			var right_x = right_arm_x
			var right_y = arm_y + j + right_offset
			if right_x >= 0 and right_x < img.get_width() and right_y >= 0 and right_y < img.get_height():
				img.set_pixel(right_x, right_y, color)

# Estrella simple
static func _draw_simple_star(img: Image, x: int, y: int, color: Color):
	var star_points = [
		Vector2(x, y - 2), Vector2(x - 1, y), Vector2(x - 2, y), 
		Vector2(x, y + 1), Vector2(x + 2, y), Vector2(x + 1, y)
	]
	
	for point in star_points:
		if point.x >= 0 and point.x < img.get_width() and point.y >= 0 and point.y < img.get_height():
			img.set_pixel(point.x, point.y, color)

# Círculo relleno
static func _draw_circle_filled(img: Image, center_x: int, center_y: int, radius: int, color: Color):
	for y in range(center_y - radius, center_y + radius + 1):
		for x in range(center_x - radius, center_x + radius + 1):
			var dx = x - center_x
			var dy = y - center_y
			if dx*dx + dy*dy <= radius*radius:
				if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
					img.set_pixel(x, y, color)

# Efectos mágicos
static func _draw_magic_sparkle(img: Image, x: int, y: int, color: Color):
	if x >= 1 and x < img.get_width() - 1 and y >= 1 and y < img.get_height() - 1:
		img.set_pixel(x, y, color)
		img.set_pixel(x + 1, y, color)
		img.set_pixel(x, y + 1, color)
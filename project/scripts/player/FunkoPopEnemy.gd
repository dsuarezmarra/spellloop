# FunkoPopEnemy.gd
# Creates Funko Pop style enemy sprites with animation system

extends RefCounted
class_name FunkoPopEnemy

enum EnemyType { GOBLIN, SKELETON, ORC, DEMON }
enum Direction { DOWN, UP, LEFT, RIGHT }
enum AnimFrame { IDLE, WALK1, WALK2 }

static func create_enemy_sprite(enemy_type: EnemyType, direction: Direction = Direction.DOWN, frame: AnimFrame = AnimFrame.IDLE) -> Texture2D:
	# Crear imagen para el estilo Funko Pop
	var img = Image.create(64, 80, false, Image.FORMAT_RGBA8)
	
	# Fondo transparente
	img.fill(Color.TRANSPARENT)
	
	# Ajustes de animación
	var head_offset_y = 0
	var body_offset_y = 0
	var arm_swing = 0
	var leg_offset = 0
	
	match frame:
		AnimFrame.WALK1:
			head_offset_y = -1
			body_offset_y = 1
			arm_swing = -1
			leg_offset = 1
		AnimFrame.WALK2:
			head_offset_y = 1
			body_offset_y = -1
			arm_swing = 1
			leg_offset = -1
	
	# Dibujar enemigo según el tipo
	match enemy_type:
		EnemyType.GOBLIN:
			_draw_goblin(img, direction, head_offset_y, body_offset_y, arm_swing, leg_offset)
		EnemyType.SKELETON:
			_draw_skeleton(img, direction, head_offset_y, body_offset_y, arm_swing, leg_offset)
		EnemyType.ORC:
			_draw_orc(img, direction, head_offset_y, body_offset_y, arm_swing, leg_offset)
		EnemyType.DEMON:
			_draw_demon(img, direction, head_offset_y, body_offset_y, arm_swing, leg_offset)
	
	var texture = ImageTexture.new()
	texture.set_image(img)
	return texture

static func _draw_goblin(img: Image, direction: Direction, head_offset_y: int, body_offset_y: int, arm_swing: int, leg_offset: int):
	# Colores del goblin
	var skin_green = Color(0.4, 0.7, 0.3)
	var loincloth_brown = Color(0.4, 0.2, 0.1)
	var eye_red = Color(0.8, 0.1, 0.1)
	var shadow_color = Color(0.0, 0.0, 0.0, 0.3)
	
	var head_x = 32
	var head_y = 20 + head_offset_y
	var head_radius = 16
	
	# Sombra de la cabeza
	_draw_ellipse_filled(img, head_x, head_y + 1, head_radius + 1, head_radius - 1, shadow_color)
	# Cabeza
	_draw_circle_filled(img, head_x, head_y, head_radius, skin_green)
	
	# Ojos grandes y rojos (estilo Funko Pop malvado)
	var eye_size = 3
	var eye_left_x = head_x - 5
	var eye_right_x = head_x + 5
	var eye_y = head_y - 2
	
	# Ajustar mirada según dirección
	match direction:
		Direction.LEFT:
			eye_left_x -= 1
			eye_right_x -= 1
		Direction.RIGHT:
			eye_left_x += 1
			eye_right_x += 1
	
	_draw_circle_filled(img, eye_left_x, eye_y, eye_size, eye_red)
	_draw_circle_filled(img, eye_right_x, eye_y, eye_size, eye_red)
	
	# Orejas puntiagudas
	_draw_triangle_filled(img, head_x - 12, head_y - 8, head_x - 18, head_y - 2, head_x - 15, head_y + 2, skin_green)
	_draw_triangle_filled(img, head_x + 12, head_y - 8, head_x + 18, head_y - 2, head_x + 15, head_y + 2, skin_green)
	
	# Cuerpo pequeño
	var body_x = head_x - 10
	var body_y = head_y + head_radius + 5 + body_offset_y
	var body_width = 20
	var body_height = 25
	
	# Sombra del cuerpo
	_draw_rounded_rect_filled(img, body_x + 1, body_y + 1, body_width, body_height, shadow_color)
	# Cuerpo
	_draw_rounded_rect_filled(img, body_x, body_y, body_width, body_height, skin_green)
	
	# Taparrabos
	_draw_rounded_rect_filled(img, body_x + 2, body_y + 15, body_width - 4, 12, loincloth_brown)
	
	# Brazos con animación
	var arm_left_x = body_x - 4
	var arm_right_x = body_x + body_width
	var arm_y = body_y + 5
	
	_draw_rounded_rect_filled(img, arm_left_x, arm_y + arm_swing, 5, 15, skin_green)
	_draw_rounded_rect_filled(img, arm_right_x, arm_y - arm_swing, 5, 15, skin_green)
	
	# Piernas con animación
	var leg_y = body_y + body_height
	var leg_left_x = head_x - 5
	var leg_right_x = head_x + 1
	
	if direction == Direction.LEFT or direction == Direction.RIGHT:
		leg_left_x += leg_offset
		leg_right_x -= leg_offset
	
	_draw_rounded_rect_filled(img, leg_left_x, leg_y, 6, 12, skin_green)
	_draw_rounded_rect_filled(img, leg_right_x, leg_y, 6, 12, skin_green)

static func _draw_skeleton(img: Image, direction: Direction, head_offset_y: int, body_offset_y: int, arm_swing: int, leg_offset: int):
	# Colores del esqueleto
	var bone_white = Color(0.95, 0.9, 0.85)
	var eye_glow = Color(0.2, 0.8, 1.0)
	var shadow_color = Color(0.0, 0.0, 0.0, 0.3)
	
	var head_x = 32
	var head_y = 20 + head_offset_y
	var head_radius = 15
	
	# Cabeza de hueso
	_draw_circle_filled(img, head_x, head_y, head_radius, bone_white)
	
	# Cuencas oculares grandes (estilo Funko Pop)
	var eye_size = 4
	var eye_left_x = head_x - 6
	var eye_right_x = head_x + 6
	var eye_y = head_y - 2
	
	_draw_circle_filled(img, eye_left_x, eye_y, eye_size, Color.BLACK)
	_draw_circle_filled(img, eye_right_x, eye_y, eye_size, Color.BLACK)
	
	# Brillos fantasmales en los ojos
	_draw_circle_filled(img, eye_left_x, eye_y, 2, eye_glow)
	_draw_circle_filled(img, eye_right_x, eye_y, 2, eye_glow)
	
	# Nariz de calavera
	_draw_triangle_filled(img, head_x, head_y + 2, head_x - 2, head_y + 6, head_x + 2, head_y + 6, Color.BLACK)
	
	# Cuerpo esquelético
	var body_x = head_x - 8
	var body_y = head_y + head_radius + 3 + body_offset_y
	var body_width = 16
	var body_height = 22
	
	_draw_rounded_rect_filled(img, body_x, body_y, body_width, body_height, bone_white)
	
	# Costillas
	for i in range(4):
		var rib_y = body_y + 4 + i * 4
		_draw_horizontal_line(img, body_x + 2, rib_y, body_width - 4, 1, Color(0.8, 0.75, 0.7))
	
	# Brazos huesudos
	var arm_left_x = body_x - 3
	var arm_right_x = body_x + body_width
	var arm_y = body_y + 3
	
	_draw_rounded_rect_filled(img, arm_left_x, arm_y + arm_swing, 4, 14, bone_white)
	_draw_rounded_rect_filled(img, arm_right_x, arm_y - arm_swing, 4, 14, bone_white)
	
	# Piernas huesudas
	var leg_y = body_y + body_height
	var leg_left_x = head_x - 4
	var leg_right_x = head_x + 1
	
	_draw_rounded_rect_filled(img, leg_left_x + leg_offset, leg_y, 5, 14, bone_white)
	_draw_rounded_rect_filled(img, leg_right_x - leg_offset, leg_y, 5, 14, bone_white)

static func _draw_orc(img: Image, direction: Direction, head_offset_y: int, body_offset_y: int, arm_swing: int, leg_offset: int):
	# Colores del orco
	var skin_dark_green = Color(0.2, 0.5, 0.2)
	var armor_metal = Color(0.4, 0.4, 0.5)
	var tusk_white = Color(0.95, 0.95, 0.9)
	var eye_red = Color(0.9, 0.2, 0.1)
	
	var head_x = 32
	var head_y = 18 + head_offset_y
	var head_radius = 18  # Más grande que el goblin
	
	# Cabeza grande del orco
	_draw_circle_filled(img, head_x, head_y, head_radius, skin_dark_green)
	
	# Ojos rojos amenazantes
	var eye_size = 4
	var eye_left_x = head_x - 6
	var eye_right_x = head_x + 6
	var eye_y = head_y - 3
	
	_draw_circle_filled(img, eye_left_x, eye_y, eye_size, eye_red)
	_draw_circle_filled(img, eye_right_x, eye_y, eye_size, eye_red)
	
	# Colmillos
	_draw_triangle_filled(img, head_x - 4, head_y + 5, head_x - 6, head_y + 10, head_x - 2, head_y + 8, tusk_white)
	_draw_triangle_filled(img, head_x + 4, head_y + 5, head_x + 6, head_y + 10, head_x + 2, head_y + 8, tusk_white)
	
	# Cuerpo robusto con armadura
	var body_x = head_x - 12
	var body_y = head_y + head_radius + 2 + body_offset_y
	var body_width = 24
	var body_height = 28
	
	# Armadura
	_draw_rounded_rect_filled(img, body_x + 2, body_y, body_width - 4, body_height, armor_metal)
	# Piel en los bordes
	_draw_rounded_rect_filled(img, body_x, body_y + 5, 3, body_height - 10, skin_dark_green)
	_draw_rounded_rect_filled(img, body_x + body_width - 3, body_y + 5, 3, body_height - 10, skin_dark_green)
	
	# Brazos musculosos
	var arm_left_x = body_x - 5
	var arm_right_x = body_x + body_width + 1
	var arm_y = body_y + 5
	
	_draw_rounded_rect_filled(img, arm_left_x, arm_y + arm_swing, 6, 18, skin_dark_green)
	_draw_rounded_rect_filled(img, arm_right_x, arm_y - arm_swing, 6, 18, skin_dark_green)
	
	# Piernas robustas
	var leg_y = body_y + body_height
	var leg_left_x = head_x - 6
	var leg_right_x = head_x + 2
	
	_draw_rounded_rect_filled(img, leg_left_x + leg_offset, leg_y, 7, 16, skin_dark_green)
	_draw_rounded_rect_filled(img, leg_right_x - leg_offset, leg_y, 7, 16, skin_dark_green)

static func _draw_demon(img: Image, direction: Direction, head_offset_y: int, body_offset_y: int, arm_swing: int, leg_offset: int):
	# Colores del demonio
	var skin_red = Color(0.7, 0.1, 0.1)
	var fire_orange = Color(1.0, 0.5, 0.0)
	var horn_black = Color(0.1, 0.1, 0.1)
	var eye_yellow = Color(1.0, 1.0, 0.2)
	
	var head_x = 32
	var head_y = 16 + head_offset_y
	var head_radius = 19  # El más grande
	
	# Cabeza demoníaca
	_draw_circle_filled(img, head_x, head_y, head_radius, skin_red)
	
	# Cuernos
	_draw_triangle_filled(img, head_x - 8, head_y - head_radius, head_x - 12, head_y - head_radius - 8, head_x - 6, head_y - head_radius + 2, horn_black)
	_draw_triangle_filled(img, head_x + 8, head_y - head_radius, head_x + 12, head_y - head_radius - 8, head_x + 6, head_y - head_radius + 2, horn_black)
	
	# Ojos ardientes
	var eye_size = 5
	var eye_left_x = head_x - 7
	var eye_right_x = head_x + 7
	var eye_y = head_y - 4
	
	_draw_circle_filled(img, eye_left_x, eye_y, eye_size, eye_yellow)
	_draw_circle_filled(img, eye_right_x, eye_y, eye_size, eye_yellow)
	
	# Efectos de fuego alrededor de los ojos
	_draw_sparkle(img, eye_left_x - 3, eye_y - 3, fire_orange)
	_draw_sparkle(img, eye_right_x + 3, eye_y - 3, fire_orange)
	
	# Cuerpo infernal
	var body_x = head_x - 14
	var body_y = head_y + head_radius + body_offset_y
	var body_width = 28
	var body_height = 32
	
	_draw_rounded_rect_filled(img, body_x, body_y, body_width, body_height, skin_red)
	
	# Marcas demoníacas
	_draw_vertical_line(img, head_x, body_y + 5, body_height - 10, 2, horn_black)
	_draw_horizontal_line(img, body_x + 6, body_y + 12, body_width - 12, 2, horn_black)
	
	# Brazos llameantes
	var arm_left_x = body_x - 6
	var arm_right_x = body_x + body_width + 1
	var arm_y = body_y + 6
	
	_draw_rounded_rect_filled(img, arm_left_x, arm_y + arm_swing, 7, 20, skin_red)
	_draw_rounded_rect_filled(img, arm_right_x, arm_y - arm_swing, 7, 20, skin_red)
	
	# Efectos de fuego en las manos
	_draw_sparkle(img, arm_left_x + 3, arm_y + 20 + arm_swing, fire_orange)
	_draw_sparkle(img, arm_right_x + 3, arm_y + 20 - arm_swing, fire_orange)
	
	# Piernas poderosas
	var leg_y = body_y + body_height
	var leg_left_x = head_x - 7
	var leg_right_x = head_x + 3
	
	_draw_rounded_rect_filled(img, leg_left_x + leg_offset, leg_y, 8, 18, skin_red)
	_draw_rounded_rect_filled(img, leg_right_x - leg_offset, leg_y, 8, 18, skin_red)

# ============= FUNCIONES DE DIBUJO AUXILIARES (COPIADAS DE FunkoPopWizard) =============

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
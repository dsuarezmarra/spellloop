# FunkoPopEnemyIsaac.gd
# Creates Isaac-style enemy sprites with Funko Pop characteristics and magical theme

extends RefCounted
class_name FunkoPopEnemyIsaac

enum EnemyType { GOBLIN_MAGE, SKELETON_WIZARD, DARK_SPIRIT, FIRE_IMP }
enum Direction { DOWN, UP, LEFT, RIGHT }
enum AnimFrame { IDLE, WALK1, WALK2 }

# Isaac-style Funko Pop Enemigos mágicos
static func create_enemy_sprite(enemy_type: EnemyType, direction: Direction, frame: AnimFrame) -> ImageTexture:
	# Tamaño Isaac-style
	var img = Image.create(40, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	# Colores según tipo de enemigo
	var colors = _get_enemy_colors(enemy_type)
	
	# Ajustes de animación
	var head_bob = 0
	var body_wobble = 0
	if frame == AnimFrame.WALK1:
		head_bob = 1
		body_wobble = 1
	elif frame == AnimFrame.WALK2:
		head_bob = -1
		body_wobble = -1
	
	# CABEZA estilo Isaac + Funko Pop
	var head_x = 20
	var head_y = 14 + head_bob
	var head_size = 18
	
	_draw_enemy_head(img, head_x, head_y, head_size, colors, enemy_type)
	
	# OJOS FUNKO POP
	_draw_enemy_eyes(img, head_x, head_y, colors, enemy_type)
	
	# CARACTERÍSTICAS ESPECIALES según tipo
	_draw_enemy_features(img, head_x, head_y, colors, enemy_type)
	
	# CUERPO pequeño estilo Isaac
	var body_x = head_x
	var body_y = 35 + body_wobble
	var body_width = 12
	var body_height = 10
	
	_draw_enemy_body(img, body_x, body_y, body_width, body_height, colors)
	
	# EFECTOS MÁGICOS
	if frame != AnimFrame.IDLE:
		_draw_enemy_magic_effect(img, head_x, head_y, colors, enemy_type)
	
	var texture = ImageTexture.new()
	texture.set_image(img)
	return texture

# Obtener colores por tipo de enemigo
static func _get_enemy_colors(enemy_type: EnemyType) -> Dictionary:
	match enemy_type:
		EnemyType.GOBLIN_MAGE:
			return {
				"skin": Color(0.4, 0.8, 0.3),      # Verde goblin
				"body": Color(0.6, 0.2, 0.8),      # Túnica púrpura
				"eyes": Color.RED,                  # Ojos rojos malvados
				"magic": Color(0.8, 0.2, 0.8),     # Magia púrpura
				"accent": Color(0.9, 0.9, 0.1)     # Detalles dorados
			}
		EnemyType.SKELETON_WIZARD:
			return {
				"skin": Color(0.9, 0.9, 0.9),      # Hueso blanco
				"body": Color(0.2, 0.2, 0.2),      # Túnica negra
				"eyes": Color(0.2, 0.8, 1.0),      # Ojos azul mágico
				"magic": Color(0.2, 0.8, 1.0),     # Magia azul
				"accent": Color(0.8, 0.8, 0.8)     # Detalles grises
			}
		EnemyType.DARK_SPIRIT:
			return {
				"skin": Color(0.3, 0.2, 0.5),      # Piel oscura espiritual
				"body": Color(0.1, 0.05, 0.2),     # Túnica muy oscura
				"eyes": Color(1.0, 0.3, 0.8),      # Ojos rosado brillante
				"magic": Color(0.8, 0.2, 0.6),     # Magia rosa oscura
				"accent": Color(0.5, 0.2, 0.5)     # Detalles morados
			}
		EnemyType.FIRE_IMP:
			return {
				"skin": Color(0.8, 0.3, 0.2),      # Piel roja
				"body": Color(0.6, 0.1, 0.1),      # Túnica roja oscura
				"eyes": Color(1.0, 0.8, 0.0),      # Ojos amarillo fuego
				"magic": Color(1.0, 0.5, 0.0),     # Magia naranja
				"accent": Color(1.0, 1.0, 0.2)     # Detalles amarillos
			}
		_:
			return _get_enemy_colors(EnemyType.GOBLIN_MAGE)

# Dibujar cabeza del enemigo
static func _draw_enemy_head(img: Image, center_x: int, center_y: int, size: int, colors: Dictionary, enemy_type: EnemyType):
	# Forma de cabeza según tipo
	match enemy_type:
		EnemyType.SKELETON_WIZARD:
			# Cabeza más angular para esqueleto
			_draw_square_head(img, center_x, center_y, size, colors.skin)
		_:
			# Cabeza ovalada para otros
			_draw_oval_head(img, center_x, center_y, size, colors.skin)

# Dibujar ojos
static func _draw_enemy_eyes(img: Image, center_x: int, center_y: int, colors: Dictionary, enemy_type: EnemyType):
	var eye_y = center_y - 2
	var left_eye_x = center_x - 4
	var right_eye_x = center_x + 4
	
	# Tamaño de ojos según tipo
	var eye_size = 3
	if enemy_type == EnemyType.DARK_SPIRIT:
		eye_size = 4  # Ojos más grandes para espíritu
	
	# Base blanca
	_draw_circle_filled(img, left_eye_x, eye_y, eye_size, Color.WHITE)
	_draw_circle_filled(img, right_eye_x, eye_y, eye_size, Color.WHITE)
	
	# Pupila de color
	_draw_circle_filled(img, left_eye_x, eye_y, eye_size - 1, colors.eyes)
	_draw_circle_filled(img, right_eye_x, eye_y, eye_size - 1, colors.eyes)
	
	# Brillo
	img.set_pixel(left_eye_x - 1, eye_y - 1, Color.WHITE)
	img.set_pixel(right_eye_x - 1, eye_y - 1, Color.WHITE)

# Características especiales
static func _draw_enemy_features(img: Image, center_x: int, center_y: int, colors: Dictionary, enemy_type: EnemyType):
	match enemy_type:
		EnemyType.GOBLIN_MAGE:
			# Orejas puntiagudas
			_draw_goblin_ears(img, center_x, center_y, colors.skin)
		EnemyType.SKELETON_WIZARD:
			# Cavidades nasales
			_draw_skull_features(img, center_x, center_y, colors.accent)
		EnemyType.DARK_SPIRIT:
			# Aura oscura
			_draw_spirit_aura(img, center_x, center_y, colors.accent)
		EnemyType.FIRE_IMP:
			# Cuernos pequeños
			_draw_imp_horns(img, center_x, center_y, colors.accent)

# Cuerpo del enemigo
static func _draw_enemy_body(img: Image, center_x: int, center_y: int, width: int, height: int, colors: Dictionary):
	# Cuerpo ovalado simple
	for y in range(center_y - height/2, center_y + height/2):
		for x in range(center_x - width/2, center_x + width/2):
			var dx = float(x - center_x) / (width/2.0)
			var dy = float(y - center_y) / (height/2.0)
			
			if dx*dx + dy*dy <= 1.0:
				if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
					img.set_pixel(x, y, colors.body)

# Efectos mágicos
static func _draw_enemy_magic_effect(img: Image, center_x: int, center_y: int, colors: Dictionary, enemy_type: EnemyType):
	# Partículas mágicas simples
	var positions = [
		Vector2(center_x + 8, center_y - 5),
		Vector2(center_x - 7, center_y + 3),
		Vector2(center_x + 2, center_y - 8)
	]
	
	for pos in positions:
		_draw_magic_particle(img, pos.x, pos.y, colors.magic)

# Funciones auxiliares

static func _draw_oval_head(img: Image, center_x: int, center_y: int, size: int, color: Color):
	var width = size
	var height = size * 0.8
	
	for y in range(center_y - height/2, center_y + height/2):
		for x in range(center_x - width/2, center_x + width/2):
			var dx = float(x - center_x) / (width/2.0)
			var dy = float(y - center_y) / (height/2.0)
			
			if dx*dx + dy*dy <= 1.0:
				if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
					img.set_pixel(x, y, color)

static func _draw_square_head(img: Image, center_x: int, center_y: int, size: int, color: Color):
	var half_size = size / 2
	for y in range(center_y - half_size, center_y + half_size):
		for x in range(center_x - half_size, center_x + half_size):
			if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
				img.set_pixel(x, y, color)

static func _draw_circle_filled(img: Image, center_x: int, center_y: int, radius: int, color: Color):
	for y in range(center_y - radius, center_y + radius + 1):
		for x in range(center_x - radius, center_x + radius + 1):
			var dx = x - center_x
			var dy = y - center_y
			if dx*dx + dy*dy <= radius*radius:
				if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
					img.set_pixel(x, y, color)

static func _draw_goblin_ears(img: Image, center_x: int, center_y: int, color: Color):
	# Orejas puntiagudas a los lados
	var ear_points_left = [
		Vector2(center_x - 9, center_y - 3),
		Vector2(center_x - 11, center_y - 5),
		Vector2(center_x - 9, center_y - 1)
	]
	var ear_points_right = [
		Vector2(center_x + 9, center_y - 3),
		Vector2(center_x + 11, center_y - 5),
		Vector2(center_x + 9, center_y - 1)
	]
	
	for point in ear_points_left + ear_points_right:
		if point.x >= 0 and point.x < img.get_width() and point.y >= 0 and point.y < img.get_height():
			img.set_pixel(point.x, point.y, color)

static func _draw_skull_features(img: Image, center_x: int, center_y: int, color: Color):
	# Cavidad nasal simple
	img.set_pixel(center_x, center_y + 1, color)
	img.set_pixel(center_x, center_y + 2, color)

static func _draw_spirit_aura(img: Image, center_x: int, center_y: int, color: Color):
	# Puntos de aura alrededor
	var aura_points = [
		Vector2(center_x - 10, center_y - 8),
		Vector2(center_x + 10, center_y - 6),
		Vector2(center_x - 8, center_y + 8),
		Vector2(center_x + 9, center_y + 7)
	]
	
	for point in aura_points:
		if point.x >= 0 and point.x < img.get_width() and point.y >= 0 and point.y < img.get_height():
			img.set_pixel(point.x, point.y, color)

static func _draw_imp_horns(img: Image, center_x: int, center_y: int, color: Color):
	# Cuernos pequeños en la frente
	var horn_points = [
		Vector2(center_x - 3, center_y - 8),
		Vector2(center_x - 2, center_y - 9),
		Vector2(center_x + 2, center_y - 9),
		Vector2(center_x + 3, center_y - 8)
	]
	
	for point in horn_points:
		if point.x >= 0 and point.x < img.get_width() and point.y >= 0 and point.y < img.get_height():
			img.set_pixel(point.x, point.y, color)

static func _draw_magic_particle(img: Image, x: int, y: int, color: Color):
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, color)
		# Pequeña cruz de partícula
		if x > 0: img.set_pixel(x - 1, y, color)
		if x < img.get_width() - 1: img.set_pixel(x + 1, y, color)
		if y > 0: img.set_pixel(x, y - 1, color)
		if y < img.get_height() - 1: img.set_pixel(x, y + 1, color)
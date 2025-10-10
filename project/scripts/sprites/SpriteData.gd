# sprite_data.gd - Datos de sprites como arrays de bytes
extends RefCounted
class_name SpriteData

# Datos de sprites basados en las imágenes del usuario
# Cada sprite es 64x64 píxeles RGBA

static func get_wizard_down_data() -> PackedByteArray:
	"""Datos del sprite wizard_down basado en imagen 1 del usuario"""
	var data = PackedByteArray()
	
	# Crear imagen 64x64 RGBA (64*64*4 = 16384 bytes)
	for y in range(64):
		for x in range(64):
			var color = get_pixel_color_down(x, y)
			data.append_array(PackedByteArray([
				int(color.r * 255),
				int(color.g * 255), 
				int(color.b * 255),
				int(color.a * 255)
			]))
	
	return data

static func get_wizard_left_data() -> PackedByteArray:
	"""Datos del sprite wizard_left basado en imagen 2 del usuario"""
	var data = PackedByteArray()
	
	for y in range(64):
		for x in range(64):
			var color = get_pixel_color_left(x, y)
			data.append_array(PackedByteArray([
				int(color.r * 255),
				int(color.g * 255),
				int(color.b * 255), 
				int(color.a * 255)
			]))
	
	return data

static func get_wizard_up_data() -> PackedByteArray:
	"""Datos del sprite wizard_up basado en imagen 3 del usuario"""
	var data = PackedByteArray()
	
	for y in range(64):
		for x in range(64):
			var color = get_pixel_color_up(x, y)
			data.append_array(PackedByteArray([
				int(color.r * 255),
				int(color.g * 255),
				int(color.b * 255),
				int(color.a * 255)
			]))
	
	return data

static func get_wizard_right_data() -> PackedByteArray:
	"""Datos del sprite wizard_right basado en imagen 4 del usuario"""
	var data = PackedByteArray()
	
	for y in range(64):
		for x in range(64):
			var color = get_pixel_color_right(x, y)
			data.append_array(PackedByteArray([
				int(color.r * 255),
				int(color.g * 255),
				int(color.b * 255),
				int(color.a * 255)
			]))
	
	return data

# Funciones de píxeles para wizard_down (imagen 1: frente)
static func get_pixel_color_down(x: int, y: int) -> Color:
	# Colores basados en tu imagen
	var skin = Color(1.0, 0.92, 0.8)
	var hat = Color(0.2, 0.5, 0.9)
	var hat_band = Color(0.15, 0.2, 0.6)
	var beard = Color.WHITE
	var robe = Color(0.2, 0.5, 0.9)
	var belt = Color(0.4, 0.25, 0.1)
	var staff = Color(0.4, 0.25, 0.1)
	var orb = Color(0.3, 0.7, 1.0)
	var boots = Color(0.1, 0.1, 0.1)
	var star = Color.WHITE
	var eye = Color.BLACK
	
	# Dibujar sprite basado en tu imagen de frente
	
	# Sombrero (parte superior)
	if y >= 5 and y <= 25:
		if in_ellipse(x, y, 32, 15, 16, 10):
			# Estrellas en el sombrero
			if (x >= 20 and x <= 24 and y >= 8 and y <= 12) or \
			   (x >= 28 and x <= 32 and y >= 6 and y <= 10) or \
			   (x >= 36 and x <= 40 and y >= 10 and y <= 14):
				return star
			return hat
		# Banda del sombrero
		elif y >= 18 and y <= 22 and x >= 18 and x <= 46:
			return hat_band
	
	# Punta del sombrero
	if y >= 2 and y <= 15 and x >= 25 and x <= 39:
		if in_triangle(x, y, 32, 2, 12):
			return hat
	
	# Cabeza
	if in_ellipse(x, y, 32, 23, 14, 12):
		# Ojos
		if (x >= 24 and x <= 30 and y >= 18 and y <= 24) or \
		   (x >= 34 and x <= 40 and y >= 18 and y <= 24):
			if in_ellipse(x, y, 27, 21, 3, 3) or in_ellipse(x, y, 37, 21, 3, 3):
				return eye
		return skin
	
	# Barba
	if in_ellipse(x, y, 32, 34, 10, 8):
		return beard
	
	# Túnica
	if in_ellipse(x, y, 32, 51, 12, 9):
		return robe
	
	# Cinturón
	if y >= 48 and y <= 52 and x >= 24 and x <= 40:
		return belt
	
	# Bolsas del cinturón
	if in_ellipse(x, y, 23, 54, 3, 4) or in_ellipse(x, y, 41, 54, 3, 4):
		return belt
	
	# Bastón
	if x >= 46 and x <= 50 and y >= 28 and y <= 52:
		return staff
	
	# Orbe del bastón
	if in_ellipse(x, y, 48, 25, 5, 5):
		return orb
	
	# Botas
	if in_ellipse(x, y, 30, 60, 4, 3) or in_ellipse(x, y, 36, 60, 4, 3):
		return boots
	
	# Estrella flotante
	if x >= 46 and x <= 50 and y >= 6 and y <= 10:
		return Color(0.8, 0.9, 1.0)
	
	return Color.TRANSPARENT

# Funciones auxiliares similares para left, up, right
static func get_pixel_color_left(x: int, y: int) -> Color:
	# Implementación similar pero en perfil izquierda
	return get_pixel_color_down(x, y)  # Placeholder - usamos down por ahora

static func get_pixel_color_up(x: int, y: int) -> Color:
	# Implementación similar pero mirando arriba
	return get_pixel_color_down(x, y)  # Placeholder - usamos down por ahora

static func get_pixel_color_right(x: int, y: int) -> Color:
	# Implementación similar pero desde espaldas
	return get_pixel_color_down(x, y)  # Placeholder - usamos down por ahora

# Funciones geométricas auxiliares
static func in_ellipse(x: int, y: int, cx: int, cy: int, rx: int, ry: int) -> bool:
	var dx = x - cx
	var dy = y - cy
	return (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) <= 1.0

static func in_triangle(x: int, y: int, cx: int, cy: int, size: int) -> bool:
	return abs(x - cx) <= size - abs(y - cy) and y >= cy

static func create_texture_from_data(data: PackedByteArray) -> ImageTexture:
	"""Crear textura desde datos de bytes"""
	var image = Image.create_from_data(64, 64, false, Image.FORMAT_RGBA8, data)
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture
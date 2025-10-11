# SpriteLoaderInMemory.gd - Cargador de sprites en memoria (sin archivos)
extends RefCounted
class_name SpriteLoaderInMemory

enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

enum AnimFrame {
	IDLE,
	WALK1,
	WALK2
}

# Cache de texturas en memoria
static var memory_textures = {}

static func load_wizard_sprite(direction: Direction, frame: AnimFrame = AnimFrame.IDLE) -> ImageTexture:
	"""Carga un sprite del mago generado en memoria"""
	
	var cache_key = str(direction) + "_" + str(frame)
	
	# Verificar cache
	if cache_key in memory_textures:
		return memory_textures[cache_key]
	
	# Generar sprite en memoria
	var texture = generate_wizard_sprite_in_memory(direction, frame)
	
	# Guardar en cache
	memory_textures[cache_key] = texture
	
	print("[SpriteLoaderInMemory] ✅ Sprite generado en memoria: ", Direction.keys()[direction])
	return texture

static func generate_wizard_sprite_in_memory(direction: Direction, frame: AnimFrame) -> ImageTexture:
	"""Genera un sprite de mago completamente en memoria"""
	
	var size = 64
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Fondo transparente
	image.fill(Color.TRANSPARENT)
	
	# Colores del mago según la dirección
	var colors = get_wizard_colors(direction)
	
	# Dibujar el mago
	draw_wizard_in_memory(image, colors, direction, size)
	
	# Crear textura
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	
	return texture

static func get_wizard_colors(direction: Direction) -> Dictionary:
	"""Obtiene los colores del mago según la dirección"""
	
	var base_colors = {
		Direction.DOWN: Color(0.4, 0.2, 0.8, 1.0),   # Púrpura
		Direction.UP: Color(0.3, 0.1, 0.7, 1.0),     # Púrpura oscuro
		Direction.LEFT: Color(0.5, 0.3, 0.9, 1.0),   # Púrpura claro
		Direction.RIGHT: Color(0.45, 0.25, 0.85, 1.0) # Púrpura medio
	}
	
	return {
		"robe": base_colors[direction],
		"hat": Color(0.5, 0.0, 0.5, 1.0),    # Púrpura sombrero
		"skin": Color(1.0, 0.9, 0.8, 1.0),   # Piel
		"eyes": Color(0.0, 0.0, 0.0, 1.0),   # Ojos
		"staff": Color(0.6, 0.3, 0.1, 1.0)   # Bastón
	}

static func draw_wizard_in_memory(image: Image, colors: Dictionary, direction: Direction, size: int):
	"""Dibuja un mago en la imagen en memoria"""
	
	var center_x = size / 2
	
	# Sombrero (triángulo)
	for y in range(5, 20):
		var width = 20 - (y - 5)
		for x in range(center_x - width/2, center_x + width/2):
			if x >= 0 and x < size:
				image.set_pixel(x, y, colors.hat)
	
	# Cabeza (círculo)
	var head_center_y = 28
	var head_radius = 12
	for y in range(head_center_y - head_radius, head_center_y + head_radius):
		for x in range(center_x - head_radius, center_x + head_radius):
			if x >= 0 and x < size and y >= 0 and y < size:
				var dist = sqrt((x - center_x) * (x - center_x) + (y - head_center_y) * (y - head_center_y))
				if dist <= head_radius:
					image.set_pixel(x, y, colors.skin)
	
	# Ojos según dirección
	match direction:
		Direction.DOWN, Direction.UP:
			# Ambos ojos visibles
			image.set_pixel(center_x - 4, head_center_y - 2, colors.eyes)
			image.set_pixel(center_x + 4, head_center_y - 2, colors.eyes)
		Direction.LEFT:
			# Solo ojo derecho visible
			image.set_pixel(center_x + 2, head_center_y - 2, colors.eyes)
		Direction.RIGHT:
			# Solo ojo izquierdo visible
			image.set_pixel(center_x - 2, head_center_y - 2, colors.eyes)
	
	# Túnica (rectángulo)
	for y in range(40, size - 5):
		for x in range(center_x - 18, center_x + 18):
			if x >= 0 and x < size:
				image.set_pixel(x, y, colors.robe)
	
	# Detalles específicos por dirección
	if direction == Direction.DOWN:
		# Bastón para dirección DOWN
		for y in range(25, size - 10):
			if center_x + 20 < size:
				image.set_pixel(center_x + 20, y, colors.staff)
		# Orbe del bastón
		if center_x + 20 < size:
			image.set_pixel(center_x + 20, 22, Color.YELLOW)
			image.set_pixel(center_x + 21, 22, Color.YELLOW)

# Función de compatibilidad con el sistema anterior
static func is_memory_mode_enabled() -> bool:
	return true

static func get_sprite_for_direction(direction_string: String) -> ImageTexture:
	"""Interfaz de compatibilidad con nombres de string"""
	
	var dir_map = {
		"DOWN": Direction.DOWN,
		"UP": Direction.UP,
		"LEFT": Direction.LEFT,
		"RIGHT": Direction.RIGHT
	}
	
	if direction_string in dir_map:
		return load_wizard_sprite(dir_map[direction_string])
	else:
		return load_wizard_sprite(Direction.DOWN)
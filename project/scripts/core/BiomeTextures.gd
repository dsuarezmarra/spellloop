# BiomeTextures.gd
# REDISEÑO COMPLETO: Teselas 64x64, contraste radical, mosaico CLARAMENTE visible

extends Node

class_name BiomeTextures

enum BiomeType {
	SAND,
	FOREST,
	ICE,
	FIRE,
	ABYSS
}

# Caché de texturas para evitar regenerar constantemente
var texture_cache: Dictionary = {}
const CACHE_MAX_SIZE = 50

# NUEVO: Teselas más grandes = MÁS VISIBLES a escala 5120x5120
# 512x512 ÷ 64x64 = 8x8 grid (en lugar de 16x16)
const TEXTURE_SIZE = 512
const TILE_SIZE = 64  # CAMBIO CRÍTICO: 32 → 64 (teselas 2x más grandes)

func _ready():
	print("[BiomeTextures] 🎨 REDISEÑO: Teselas 64x64, contraste radical")

func get_biome_at_position(world_pos: Vector2) -> int:
	var noise = FastNoiseLite.new()
	noise.seed = 12345
	noise.frequency = 0.0002
	var val = noise.get_noise_2d(world_pos.x, world_pos.y)
	if val < -0.6:
		return BiomeType.ABYSS
	elif val < -0.2:
		return BiomeType.ICE
	elif val < 0.2:
		return BiomeType.SAND
	elif val < 0.6:
		return BiomeType.FOREST
	else:
		return BiomeType.FIRE

func get_biome_color(biome_type: int) -> Color:
	"""Color primario del bioma"""
	var colors = [
		Color(0.956, 0.816, 0.247, 1.0),  # SAND - Amarillo
		Color(0.157, 0.682, 0.376, 1.0),  # FOREST - Verde
		Color(0.365, 0.682, 0.882, 1.0),  # ICE - Azul
		Color(0.906, 0.302, 0.235, 1.0),  # FIRE - Rojo
		Color(0.102, 0.0, 0.2, 1.0)        # ABYSS - Púrpura oscuro
	]
	return colors[clamp(biome_type, 0, 4)]

func get_biome_dark_color(biome_type: int) -> Color:
	"""Color MUY OSCURO (sombra) - CONTRASTE RADICAL"""
	var colors = [
		Color(0.506, 0.333, 0.063, 1.0),    # SAND - Marrón muy oscuro
		Color(0.059, 0.318, 0.157, 1.0),    # FOREST - Verde muy oscuro
		Color(0.106, 0.255, 0.451, 1.0),    # ICE - Azul muy oscuro
		Color(0.506, 0.098, 0.063, 1.0),    # FIRE - Rojo muy oscuro
		Color(0.051, 0.0, 0.102, 1.0)       # ABYSS - Púrpura muy oscuro
	]
	return colors[clamp(biome_type, 0, 4)]

func get_biome_bright_color(biome_type: int) -> Color:
	"""Color MUY CLARO (highlight) - CONTRASTE RADICAL"""
	var colors = [
		Color(1.0, 0.922, 0.427, 1.0),      # SAND - Amarillo muy claro
		Color(0.235, 0.906, 0.498, 1.0),    # FOREST - Verde muy claro
		Color(0.498, 0.902, 1.0, 1.0),      # ICE - Azul muy claro
		Color(1.0, 0.498, 0.427, 1.0),      # FIRE - Rojo muy claro
		Color(0.5, 0.2, 0.8, 1.0)           # ABYSS - Púrpura muy claro
	]
	return colors[clamp(biome_type, 0, 4)]

func get_biome_name(biome_type: int) -> String:
	var names = ["Arena", "Bosque", "Hielo", "Fuego", "Abismo"]
	return names[clamp(biome_type, 0, 4)]

func generate_chunk_texture_enhanced(chunk_pos: Vector2i, chunk_size: int = 512) -> ImageTexture:
	"""Generar textura de chunk con MOSAICO CLARAMENTE VISIBLE"""
	
	# Crear clave de caché
	var cache_key = "%s_%d" % [chunk_pos, chunk_size]
	if cache_key in texture_cache:
		return texture_cache[cache_key]
	
	# Generar textura base
	var biome_type = get_biome_at_position(Vector2(chunk_pos) * chunk_size)
	var texture = _generate_mosaic_texture(biome_type, chunk_pos)
	
	# Guardar en caché (con límite)
	if texture_cache.size() >= CACHE_MAX_SIZE:
		var first_key = texture_cache.keys()[0]
		texture_cache.erase(first_key)
	texture_cache[cache_key] = texture
	
	return texture

func _generate_mosaic_texture(biome_type: int, chunk_pos: Vector2i) -> ImageTexture:
	"""Generar textura mosaico con CONTRASTE RADICAL entre tiles"""
	
	var image = Image.create(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	var primary_color = get_biome_color(biome_type)
	var dark_color = get_biome_dark_color(biome_type)
	var bright_color = get_biome_bright_color(biome_type)
	
	# Llenar fondo con color primario
	image.fill(primary_color)
	
	# Generar patrón mosaico con MÁS VARIEDAD
	var noise = FastNoiseLite.new()
	noise.seed = hash(chunk_pos) & 0xFFFF
	noise.frequency = 0.05
	
	# Dibujar tiles del mosaico (64x64 cada uno, solo 8x8 tiles)
	var tile_y = 0
	while tile_y < TEXTURE_SIZE:
		var tile_x = 0
		while tile_x < TEXTURE_SIZE:
			# Usar ruido para determinar variante del tile (5 variantes para máxima diversidad)
			var noise_val = noise.get_noise_2d(float(tile_x) / 64.0, float(tile_y) / 64.0)
			var tile_variant = int((noise_val + 1.0) * 2.5) % 5
			
			# Seleccionar color del tile
			var tile_color = primary_color
			match tile_variant:
				0:
					tile_color = primary_color
				1:
					tile_color = dark_color
				2:
					tile_color = bright_color
				3:
					# Intermedio entre primario y oscuro
					tile_color = Color(
						lerp(primary_color.r, dark_color.r, 0.5),
						lerp(primary_color.g, dark_color.g, 0.5),
						lerp(primary_color.b, dark_color.b, 0.5),
						1.0
					)
				4:
					# Intermedio entre primario y claro
					tile_color = Color(
						lerp(primary_color.r, bright_color.r, 0.5),
						lerp(primary_color.g, bright_color.g, 0.5),
						lerp(primary_color.b, bright_color.b, 0.5),
						1.0
					)
			
			# Dibujar tile con bordes 3D PRONUNCIADOS
			_draw_mosaic_tile(image, tile_x, tile_y, TILE_SIZE, tile_color, dark_color, bright_color)
			
			tile_x += TILE_SIZE
		tile_y += TILE_SIZE
	
	# Crear textura
	var texture = ImageTexture.create_from_image(image)
	return texture

func _draw_mosaic_tile(image: Image, x: int, y: int, size: int, tile_color: Color, shadow_color: Color, highlight_color: Color) -> void:
	"""Dibujar un tile individual con BORDES 3D PRONUNCIADOS"""
	
	# Llenar tile con color base
	for py in range(y, min(y + size, TEXTURE_SIZE)):
		for px in range(x, min(x + size, TEXTURE_SIZE)):
			image.set_pixel(px, py, tile_color)
	
	# SOMBRA: Borde izquierdo y superior (8 píxeles de ancho = MÁS VISIBLE)
	var border_width = 8
	for i in range(0, min(border_width, size)):
		# Borde izquierdo
		if x + i < TEXTURE_SIZE:
			for j in range(size):
				if y + j < TEXTURE_SIZE:
					image.set_pixel(x + i, y + j, shadow_color)
		
		# Borde superior
		if y + i < TEXTURE_SIZE:
			for j in range(size):
				if x + j < TEXTURE_SIZE:
					image.set_pixel(x + j, y + i, shadow_color)
	
	# HIGHLIGHT: Borde derecha e inferior (8 píxeles de ancho = MÁS VISIBLE)
	for i in range(0, min(border_width, size)):
		# Borde derecho
		var right_x = x + size - 1 - i
		if right_x >= x and right_x < TEXTURE_SIZE:
			for j in range(size):
				if y + j < TEXTURE_SIZE:
					image.set_pixel(right_x, y + j, highlight_color)
		
		# Borde inferior
		var bottom_y = y + size - 1 - i
		if bottom_y >= y and bottom_y < TEXTURE_SIZE:
			for j in range(size):
				if x + j < TEXTURE_SIZE:
					image.set_pixel(x + j, bottom_y, highlight_color)
	
	# DIVISOR CENTRAL: Línea sutil en medio del tile (para más definición)
	var mid_color = Color(
		tile_color.r * 0.9,
		tile_color.g * 0.9,
		tile_color.b * 0.9,
		1.0
	)
	
	# Línea vertical central
	var mid_x = x + size / 2
	if mid_x < TEXTURE_SIZE:
		for j in range(size):
			if y + j < TEXTURE_SIZE:
				image.set_pixel(mid_x, y + j, mid_color)
	
	# Línea horizontal central
	var mid_y = y + size / 2
	if mid_y < TEXTURE_SIZE:
		for j in range(size):
			if x + j < TEXTURE_SIZE:
				image.set_pixel(x + j, mid_y, mid_color)

func generate_chunk_texture(chunk_pos: Vector2i, chunk_size: int = 512) -> ImageTexture:
	"""Wrapper compatible"""
	return generate_chunk_texture_enhanced(chunk_pos, chunk_size)

func clear_cache() -> void:
	"""Limpiar caché de texturas"""
	texture_cache.clear()
	print("[BiomeTextures] 🗑️ Caché limpiado")

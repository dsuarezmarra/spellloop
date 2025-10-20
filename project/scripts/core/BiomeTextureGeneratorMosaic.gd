# BiomeTextureGeneratorMosaic.gd
# Genera texturas tipo MOSAICO para biomas
# Reemplaza el patrón de bandas con texturas más visuales

extends Node

class_name BiomeTextureGeneratorMosaic

# Mapa de colores por bioma
var BIOME_COLORS = {
	0: {  # Hierba (Verde)
		"primary": Color("#27AE60"),     # Verde oscuro
		"light": Color("#52BE80"),       # Verde claro
		"accent": Color("#1E8449"),      # Verde más oscuro
		"highlight": Color("#F1F8E9")    # Blanco verdoso
	},
	1: {  # Fuego (Rojo/Naranja)
		"primary": Color("#E74C3C"),     # Rojo brillante
		"light": Color("#FADBD8"),       # Rosa claro
		"accent": Color("#A93226"),      # Rojo oscuro
		"highlight": Color("#FDEBD0")    # Naranja claro
	},
	2: {  # Hielo (Azul/Cyan)
		"primary": Color("#5DADE2"),     # Azul cielo
		"light": Color("#AED6F1"),       # Azul claro
		"accent": Color("#2874A6"),      # Azul oscuro
		"highlight": Color("#D6EAF8")    # Azul muy claro
	},
	3: {  # Arena (Amarillo/Beige)
		"primary": Color("#F4D03F"),     # Amarillo arena
		"light": Color("#F9E79F"),       # Beige claro
		"accent": Color("#D68910"),      # Naranja oscuro
		"highlight": Color("#FEFEF5")    # Blanco arena
	},
	4: {  # Nieve (Blanco/Gris)
		"primary": Color("#ECF0F1"),     # Blanco nieve
		"light": Color("#FDFEFE"),       # Blanco puro
		"accent": Color("#95A5A6"),      # Gris
		"highlight": Color("#FFFFFF")    # Blanco
	},
	5: {  # Ceniza (Gris/Negro)
		"primary": Color("#34495E"),     # Gris oscuro
		"light": Color("#7F8C8D"),       # Gris claro
		"accent": Color("#2C3E50"),      # Gris más oscuro
		"highlight": Color("#BDC3C7")    # Gris muy claro
	},
	6: {  # Abismo (Negro/Púrpura)
		"primary": Color("#1A0033"),     # Púrpura muy oscuro
		"light": Color("#4A235A"),       # Púrpura oscuro
		"accent": Color("#6C3483"),      # Púrpura
		"highlight": Color("#D7BDE2")    # Púrpura claro
	}
}

static func generate_mosaic_texture(biome_index: int, seed_val: int = 0) -> ImageTexture:
	"""
	Genera una textura tipo mosaico para un bioma
	biome_index: 0-6 (Hierba, Fuego, Hielo, Arena, Nieve, Ceniza, Abismo)
	"""
	var generator = BiomeTextureGeneratorMosaic.new()
	var colors = generator.BIOME_COLORS.get(biome_index, generator.BIOME_COLORS[0])
	
	var image = Image.create(160, 160, false, Image.FORMAT_RGBA8)
	
	# Llenar fondo
	image.fill(colors["primary"])
	
	# Generar patrón mosaico
	var tile_size = 20  # Tamaño de cada tile del mosaico
	var noise = FastNoiseLite.new()
	noise.seed = seed_val + biome_index * 1000
	noise.frequency = 0.1
	
	for y in range(0, 160, tile_size):
		for x in range(0, 160, tile_size):
			# Determinar variante de tile (1-4 tipos diferentes)
			var noise_val = noise.get_noise_2d(float(x) / 20.0, float(y) / 20.0)
			var tile_variant = int((noise_val + 1.0) * 2.0) % 3  # 0, 1, o 2
			
			var tile_color = colors["light"] if tile_variant == 0 else colors["primary"]
			if tile_variant == 2:
				tile_color = colors["accent"]
			
			# Dibujar tile
			_draw_tile(image, x, y, tile_size, tile_color, colors["highlight"])
	
	var texture = ImageTexture.create_from_image(image)
	return texture

static func _draw_tile(image: Image, x: int, y: int, size: int, color: Color, accent: Color) -> void:
	"""Dibuja un tile de mosaico con bordes"""
	# Llenar tile
	for py in range(y, min(y + size, 160)):
		for px in range(x, min(x + size, 160)):
			image.set_pixel(px, py, color)
	
	# Bordes oscuros (da efecto 3D)
	for i in range(size):
		# Borde izquierdo
		if x + i < 160:
			var darken = Color(color.r * 0.7, color.g * 0.7, color.b * 0.7, 1.0)
			if y + i < 160:
				image.set_pixel(x, y + i, darken)
		
		# Borde superior
		if y + i < 160:
			var darken = Color(color.r * 0.7, color.g * 0.7, color.b * 0.7, 1.0)
			if x + i < 160:
				image.set_pixel(x + i, y, darken)
	
	# Highlight en esquina (efecto brillante)
	if x + 2 < 160 and y + 2 < 160:
		image.set_pixel(x + 2, y + 2, accent)
		image.set_pixel(x + 3, y + 2, accent)
		image.set_pixel(x + 2, y + 3, accent)

static func generate_biome_texture_enhanced(biome_index: int, _seed_val: int = 0) -> ImageTexture:
	"""
	Versión alternativa: generador ULTRA-RÁPIDO (<10ms)
	Simplemente 4-5 opciones de patrón por bioma
	"""
	var generator = BiomeTextureGeneratorMosaic.new()
	var colors = generator.BIOME_COLORS.get(biome_index, generator.BIOME_COLORS[0])
	
	var image = Image.create(160, 160, false, Image.FORMAT_RGBA8)
	
	# Patrón simple: stripes verticales alternadas
	for x in range(0, 160, 16):
		var use_light = int(x / 16.0) % 2 == 0
		var color = colors["light"] if use_light else colors["primary"]
		
		for y in range(160):
			image.set_pixel(x + (y % 4), y, color if y % 8 < 4 else colors["accent"])
	
	# Llenar espacios
	for y in range(0, 160, 20):
		for x in range(0, 160, 20):
			if randf_range(0, 1.0) > 0.6:
				# Pequeños detalles
				var detail_color = colors["highlight"] if randf_range(0, 1.0) > 0.5 else colors["accent"]
				for dy in range(2):
					for dx in range(2):
						if x + dx < 160 and y + dy < 160:
							image.set_pixel(x + dx, y + dy, detail_color)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

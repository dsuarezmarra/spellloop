extends Node
class_name BiomeTextureGeneratorV2

"""
Generador de texturas de bioma mejorado
Crea texturas de imagen reales procedurales en lugar de nodos visuales
Esto es más eficiente y se ve mejor
"""

enum BiomeType { GRASSLAND, DESERT, SNOW, LAVA, ARCANE_WASTES, FOREST }

const BIOME_NAMES = {
	BiomeType.GRASSLAND: "grassland",
	BiomeType.DESERT: "desert",
	BiomeType.SNOW: "snow",
	BiomeType.LAVA: "lava",
	BiomeType.ARCANE_WASTES: "arcane_wastes",
	BiomeType.FOREST: "forest",
}

var noise: FastNoiseLite = FastNoiseLite.new()

func _ready() -> void:
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.05
	print("[BiomeTextureGeneratorV2] ✅ Initialized")

func generate_biome_texture(biome_type: int, world_seed: int) -> ImageTexture:
	"""Generar textura procedural para un bioma"""
	var width = 1024
	var height = 1024
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	noise.seed = world_seed
	
	for y in range(height):
		for x in range(width):
			var pixel_color = _get_biome_pixel_color(biome_type, x, y, width, height)
			image.set_pixel(x, y, pixel_color)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

func _get_biome_pixel_color(biome_type: int, x: int, y: int, width: int, height: int) -> Color:
	"""Obtener color de píxel para bioma"""
	var n = noise.get_noise_2d(float(x), float(y))
	n = (n + 1.0) / 2.0  # Normalizar a 0-1
	
	match biome_type:
		BiomeType.GRASSLAND:
			return _grassland_color(n, x, y, width, height)
		BiomeType.DESERT:
			return _desert_color(n, x, y, width, height)
		BiomeType.SNOW:
			return _snow_color(n, x, y, width, height)
		BiomeType.LAVA:
			return _lava_color(n, x, y, width, height)
		BiomeType.ARCANE_WASTES:
			return _arcane_color(n, x, y, width, height)
		BiomeType.FOREST:
			return _forest_color(n, x, y, width, height)
	
	return Color.WHITE

func _grassland_color(n: float, _x: int, _y: int, _w: int, _h: int) -> Color:
	"""Tonos verdes para prado"""
	# Base verde
	var base = Color(0.34, 0.68, 0.35, 1.0)
	
	# Variación con ruido
	var dark_grass = Color(0.2, 0.45, 0.2, 1.0)
	var light_grass = Color(0.5, 0.8, 0.4, 1.0)
	
	if n < 0.3:
		return dark_grass
	elif n < 0.6:
		return base.lerp(dark_grass, n)
	else:
		return base.lerp(light_grass, n)

func _desert_color(n: float, _x: int, _y: int, _w: int, _h: int) -> Color:
	"""Tonos de arena para desierto"""
	var base = Color(0.87, 0.78, 0.6, 1.0)
	var dark_sand = Color(0.75, 0.65, 0.45, 1.0)
	var light_sand = Color(0.95, 0.88, 0.75, 1.0)
	
	if n < 0.3:
		return dark_sand
	elif n < 0.6:
		return base.lerp(dark_sand, n)
	else:
		return base.lerp(light_sand, n)

func _snow_color(n: float, _x: int, _y: int, _w: int, _h: int) -> Color:
	"""Tonos de nieve para glaciar"""
	var base = Color(0.95, 0.95, 1.0, 1.0)
	var ice_blue = Color(0.7, 0.85, 1.0, 1.0)
	var light_snow = Color(1.0, 1.0, 1.0, 1.0)
	
	if n < 0.3:
		return ice_blue
	elif n < 0.6:
		return base.lerp(ice_blue, n)
	else:
		return base.lerp(light_snow, n)

func _lava_color(n: float, _x: int, _y: int, _w: int, _h: int) -> Color:
	"""Tonos de lava para volcán"""
	var base = Color(0.4, 0.1, 0.05, 1.0)
	var dark_lava = Color(0.2, 0.05, 0.02, 1.0)
	var hot_lava = Color(0.8, 0.2, 0.05, 1.0)
	
	if n < 0.3:
		return dark_lava
	elif n < 0.6:
		return base.lerp(dark_lava, n)
	else:
		return base.lerp(hot_lava, n)

func _arcane_color(n: float, _x: int, _y: int, _w: int, _h: int) -> Color:
	"""Tonos mágicos para tierra arcana"""
	var base = Color(0.6, 0.3, 0.8, 1.0)
	var dark_arcane = Color(0.4, 0.15, 0.6, 1.0)
	var bright_arcane = Color(0.8, 0.4, 1.0, 1.0)
	
	if n < 0.3:
		return dark_arcane
	elif n < 0.6:
		return base.lerp(dark_arcane, n)
	else:
		return base.lerp(bright_arcane, n)

func _forest_color(n: float, _x: int, _y: int, _w: int, _h: int) -> Color:
	"""Tonos verdes oscuros para bosque"""
	var base = Color(0.15, 0.35, 0.15, 1.0)
	var dark_forest = Color(0.08, 0.2, 0.08, 1.0)
	var light_forest = Color(0.25, 0.45, 0.25, 1.0)
	
	if n < 0.3:
		return dark_forest
	elif n < 0.6:
		return base.lerp(dark_forest, n)
	else:
		return base.lerp(light_forest, n)

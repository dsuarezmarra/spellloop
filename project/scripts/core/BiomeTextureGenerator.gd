# OBSOLETE-SCRIPT: este script parece no usarse actualmente. Verificar antes de eliminar.
# Originalmente: BiomeTextureGenerator.gd - Generador de texturas procedurales v1
# Razón: Reemplazado por BiomeTextureGeneratorV2.gd (versión mejorada)

# BiomeTextureGenerator.gd
# Generador de texturas/tonos procedurales para biomas
# Utiliza ruido Perlin/simplex para asignación de biomas

extends Node

class_name BiomeTextureGenerator

enum BiomeType {
	SAND,
	FOREST,
	ICE,
	FIRE,
	ABYSS
}

const BIOME_COLORS = {
	BiomeType.SAND: Color(0.87, 0.78, 0.6, 1.0),
	BiomeType.FOREST: Color(0.4, 0.6, 0.3, 1.0),
	BiomeType.ICE: Color(0.8, 0.9, 1.0, 1.0),
	BiomeType.FIRE: Color(1.0, 0.4, 0.0, 1.0),
	BiomeType.ABYSS: Color(0.1, 0.05, 0.15, 1.0)
}

var noise_seed: int = 12345
var noise_scale: float = 0.01  # Escala del ruido Perlin
var biome_transition_smoothness: float = 0.3

func _ready() -> void:
	print("[BiomeTextureGenerator] Inicializado")

func get_biome_at_position(world_pos: Vector2) -> int:
	"""Obtener tipo de bioma en posición del mundo usando ruido Perlin"""
	var noise = FastNoiseLite.new()
	noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = noise_scale
	
	# Obtener valor de ruido (-1.0 a 1.0)
	var noise_value = noise.get_noise_2d(world_pos.x, world_pos.y)
	
	# Mapear valor de ruido a tipo de bioma
	if noise_value < -0.6:
		return BiomeType.ABYSS
	elif noise_value < -0.2:
		return BiomeType.ICE
	elif noise_value < 0.2:
		return BiomeType.SAND
	elif noise_value < 0.6:
		return BiomeType.FOREST
	else:
		return BiomeType.FIRE

func get_biome_color(biome_type: int) -> Color:
	"""Obtener color base del bioma"""
	if BIOME_COLORS.has(biome_type):
		return BIOME_COLORS[biome_type]
	return BIOME_COLORS[BiomeType.SAND]

func get_biome_name(biome_type: int) -> String:
	"""Obtener nombre del bioma"""
	match biome_type:
		BiomeType.SAND:
			return "Arena"
		BiomeType.FOREST:
			return "Bosque"
		BiomeType.ICE:
			return "Hielo"
		BiomeType.FIRE:
			return "Fuego"
		BiomeType.ABYSS:
			return "Abismo"
		_:
			return "Desconocido"

func generate_chunk_texture(chunk_pos: Vector2i, chunk_size: int = 512) -> ImageTexture:
	"""Generar textura procedural para un chunk con blending de biomas"""
	var image = Image.create(chunk_size, chunk_size, false, Image.FORMAT_RGBA8)
	var noise = FastNoiseLite.new()
	noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = noise_scale
	
	var chunk_world_pos = Vector2(chunk_pos) * chunk_size
	
	for x in range(chunk_size):
		for y in range(chunk_size):
			var world_x = chunk_world_pos.x + x
			var world_y = chunk_world_pos.y + y
			
			# Obtener ruido para variación de color
			var noise_value = noise.get_noise_2d(world_x, world_y)
			
			# Obtener bioma y color base
			var biome_type = get_biome_at_position(Vector2(world_x, world_y))
			var biome_color = get_biome_color(biome_type)
			
			# Aplicar variación de ruido para agregar detalle
			var variance = (noise_value - 0.5) * biome_transition_smoothness
			var final_color = biome_color + Color(variance, variance * 0.8, variance * 0.6, 0)
			final_color = final_color.clamp()
			
			image.set_pixel(x, y, final_color)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

func generate_blended_texture(chunk_pos: Vector2i, chunk_size: int = 512, blend_radius: int = 2) -> ImageTexture:
	"""Generar textura con blending suave entre biomas"""
	var image = Image.create(chunk_size, chunk_size, false, Image.FORMAT_RGBA8)
	var noise = FastNoiseLite.new()
	noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = noise_scale
	
	var chunk_world_pos = Vector2(chunk_pos) * chunk_size
	
	for x in range(chunk_size):
		for y in range(chunk_size):
			var world_x = chunk_world_pos.x + x
			var world_y = chunk_world_pos.y + y
			var world_pos = Vector2(world_x, world_y)
			
			# Obtener múltiples muestras de bioma alrededor
			var biome_colors = []
			var biome_distances = []
			
			for dx in range(-blend_radius, blend_radius + 1):
				for dy in range(-blend_radius, blend_radius + 1):
					var sample_pos = world_pos + Vector2(dx, dy) * 50.0
					var biome = get_biome_at_position(sample_pos)
					var color = get_biome_color(biome)
					var distance = Vector2(dx, dy).length()
					
					biome_colors.append(color)
					biome_distances.append(distance)
			
			# Blending ponderado por distancia
			var blended_color = Color(0, 0, 0, 0)
			var weight_sum = 0.0
			
			for i in range(biome_colors.size()):
				var weight = 1.0 / (biome_distances[i] + 0.1)
				blended_color += biome_colors[i] * weight
				weight_sum += weight
			
			if weight_sum > 0:
				blended_color /= weight_sum
			
			# Aplicar variación de ruido
			var noise_value = noise.get_noise_2d(world_x, world_y)
			var variance = (noise_value - 0.5) * 0.1
			blended_color = blended_color + Color(variance, variance, variance, 0)
			blended_color = blended_color.clamp()
			
			image.set_pixel(x, y, blended_color)
	
	var texture = ImageTexture.create_from_image(image)
	return texture


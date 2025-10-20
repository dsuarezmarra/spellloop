# OBSOLETE-SCRIPT: este script parece no usarse actualmente. Verificar antes de eliminar.
# Originalmente: BiomeTextureGeneratorEnhanced.gd - Generador mejorado
# Razón: Reemplazado por BiomeTextureGeneratorV2.gd (versión final seleccionada)

# BiomeTextureGeneratorEnhanced.gd
extends Node

class_name BiomeTextureGeneratorEnhanced

enum BiomeType {
	SAND,
	FOREST,
	ICE,
	FIRE,
	ABYSS
}

func _ready():
	print("[BiomeTextureGeneratorEnhanced] Inicializado")

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
	var colors = [
		Color(0.956, 0.816, 0.247, 1.0),
		Color(0.157, 0.682, 0.376, 1.0),
		Color(0.365, 0.682, 0.882, 1.0),
		Color(0.906, 0.302, 0.235, 1.0),
		Color(0.102, 0.0, 0.2, 1.0)
	]
	return colors[clamp(biome_type, 0, 4)]

func get_biome_name(biome_type: int) -> String:
	var names = ["Arena", "Bosque", "Hielo", "Fuego", "Abismo"]
	return names[clamp(biome_type, 0, 4)]

func generate_chunk_texture_enhanced(chunk_pos: Vector2i, chunk_size: int = 512) -> ImageTexture:
	var image = Image.create(chunk_size, chunk_size, false, Image.FORMAT_RGBA8)
	var chunk_world_pos = Vector2(chunk_pos) * chunk_size
	var center_pos = chunk_world_pos + Vector2(chunk_size / 2.0, chunk_size / 2.0)
	
	var biome_type = get_biome_at_position(center_pos)
	var base_color = get_biome_color(biome_type)
	image.fill(base_color)
	
	var texture = ImageTexture.create_from_image(image)
	print("[BiomeTextureGeneratorEnhanced] Chunk %s generado" % [chunk_pos])
	return texture

func generate_chunk_texture(chunk_pos: Vector2i, chunk_size: int = 512) -> ImageTexture:
	return generate_chunk_texture_enhanced(chunk_pos, chunk_size)

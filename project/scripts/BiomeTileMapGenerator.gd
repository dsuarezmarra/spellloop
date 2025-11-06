extends Node2D
class_name BiomeTileMapGenerator

"""
🗺️ GENERADOR PROCEDURAL DE BIOMAS CON TILEMAP
===============================================

Genera chunks de biomas usando TileMap con transiciones automáticas.
Reemplaza al antiguo sistema de chunks con texturas grandes.

USO:
- Se integra con InfiniteWorldManager
- Genera chunks de tiles en lugar de texturas grandes
- Transiciones suaves automáticas entre biomas
"""

signal chunk_generated(chunk_pos: Vector2i)
signal chunk_removed(chunk_pos: Vector2i)

# Referencias
@export var tilemap: TileMapLayer
@export var chunk_size: int = 32  # 32×32 tiles = 2048×2048 pixels

# Configuración de ruido
var noise: FastNoiseLite
var moisture_noise: FastNoiseLite

# Biomas (ID según TileSet terrain)
enum BiomeType {
	GRASSLAND = 0,
	DESERT = 1,
	FOREST = 2,
	ARCANE_WASTES = 3,
	LAVA = 4,
	SNOW = 5
}

# Chunks activos
var active_chunks: Dictionary = {}  # Vector2i → bool

func _ready():
	_setup_noise()
	print("✓ BiomeTileMapGenerator inicializado")

func _setup_noise():
	"""Configurar generadores de ruido para biomas"""

	# Ruido principal para selección de biomas
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = randi()
	noise.frequency = 0.008  # Biomas grandes
	noise.fractal_octaves = 3

	# Ruido de humedad para variación
	moisture_noise = FastNoiseLite.new()
	moisture_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	moisture_noise.seed = randi() + 1000
	moisture_noise.frequency = 0.012

	print("✓ Ruido configurado - Seed: %d" % noise.seed)

func generate_chunk(chunk_pos: Vector2i):
	"""Generar un chunk de tiles en la posición dada"""

	if active_chunks.has(chunk_pos):
		return  # Ya existe

	var start_time = Time.get_ticks_msec()

	# Calcular posición en tiles
	var start_x = chunk_pos.x * chunk_size
	var start_y = chunk_pos.y * chunk_size

	# Array para set_cells_terrain_connect (más eficiente)
	var cells_data = []  # [{pos: Vector2i, terrain: int}, ...]

	# Generar cada tile del chunk
	for local_y in range(chunk_size):
		for local_x in range(chunk_size):
			var tile_x = start_x + local_x
			var tile_y = start_y + local_y

			# Determinar bioma para este tile
			var biome = _get_biome_at_position(tile_x, tile_y)

			cells_data.append({
				"pos": Vector2i(tile_x, tile_y),
				"terrain": biome
			})

	# Aplicar todos los tiles del chunk de una vez
	_apply_terrain_cells(cells_data)

	active_chunks[chunk_pos] = true

	var elapsed = Time.get_ticks_msec() - start_time
	print("✓ Chunk generado en %dms: %s (%d tiles)" % [elapsed, chunk_pos, cells_data.size()])

	chunk_generated.emit(chunk_pos)

func _get_biome_at_position(tile_x: int, tile_y: int) -> int:
	"""Determinar qué bioma corresponde a esta posición de tile"""

	# Obtener valores de ruido (-1.0 a 1.0)
	var main_noise = noise.get_noise_2d(tile_x, tile_y)
	var moisture = moisture_noise.get_noise_2d(tile_x, tile_y)

	# Normalizar a 0.0-1.0
	var height = (main_noise + 1.0) / 2.0
	var wet = (moisture + 1.0) / 2.0

	# Mapa de biomas basado en altura y humedad
	# Similar a Terraria/Minecraft

	if height < 0.25:
		# Zonas bajas
		if wet > 0.6:
			return BiomeType.FOREST  # Bosque pantanoso
		else:
			return BiomeType.GRASSLAND  # Pradera

	elif height < 0.5:
		# Zonas medias
		if wet > 0.7:
			return BiomeType.FOREST  # Bosque denso
		elif wet < 0.3:
			return BiomeType.DESERT  # Desierto
		else:
			return BiomeType.GRASSLAND  # Pradera

	elif height < 0.75:
		# Zonas altas
		if wet > 0.6:
			return BiomeType.ARCANE_WASTES  # Páramo mágico
		else:
			return BiomeType.SNOW  # Nieve

	else:
		# Zonas muy altas
		if wet > 0.5:
			return BiomeType.LAVA  # Volcánico
		else:
			return BiomeType.SNOW  # Tundra helada

	return BiomeType.GRASSLAND  # Fallback

func _apply_terrain_cells(cells_data: Array):
	"""Aplicar tiles con terrains automáticos"""

	if not tilemap:
		printerr("✗ No hay TileMapLayer asignado")
		return

	# En Godot 4.5, set_cells_terrain_connect requiere:
	# Parámetros: layer (int), cells (Array[Vector2i]), terrain_set (int), terrain (int), ignore_empty (bool)

	# Preparar array de posiciones
	var positions: Array[Vector2i] = []
	for cell in cells_data:
		positions.append(cell.pos)

	# Aplicar terrain a todas las celdas del chunk de una vez
	# Nota: todas las celdas del mismo chunk usan el mismo terrain
	if cells_data.size() > 0:
		var first_terrain = cells_data[0].terrain
		# set_cells_terrain_connect en Godot 4.5: (layer, cells, terrain_set, terrain)
		tilemap.set_cells_terrain_connect(0, positions, 0, first_terrain)

func remove_chunk(chunk_pos: Vector2i):
	"""Eliminar un chunk para liberar memoria"""

	if not active_chunks.has(chunk_pos):
		return
	# Calcular posición en tiles
	var start_x = chunk_pos.x * chunk_size
	var start_y = chunk_pos.y * chunk_size
	# Eliminar todos los tiles del chunk
	# erase_cell en Godot 4.5: (layer, position)
	for local_y in range(chunk_size):
		for local_x in range(chunk_size):
			var pos = Vector2i(start_x + local_x, start_y + local_y)
			tilemap.erase_cell(0, pos) Solo layer 0 por defecto + local_x, start_y + local_y)
			tilemap.erase_cell(0, pos)

	active_chunks.erase(chunk_pos)

	print("✓ Chunk eliminado: %s" % chunk_pos)
	chunk_removed.emit(chunk_pos)

func get_biome_at_world_position(world_pos: Vector2) -> int:
	"""Obtener bioma en coordenadas del mundo"""
	var tile_pos = tilemap.local_to_map(world_pos)
	return _get_biome_at_position(tile_pos.x, tile_pos.y)

func clear_all_chunks():
	"""Limpiar todos los chunks (útil para reset)"""
	for chunk_pos in active_chunks.keys():
		remove_chunk(chunk_pos)
	active_chunks.clear()
	print("✓ Todos los chunks eliminados")

func get_active_chunk_count() -> int:
	"""Número de chunks activos"""
	return active_chunks.size()

func regenerate_with_new_seed(new_seed: int = -1):
	"""Regenerar mundo con nueva semilla"""
	if new_seed == -1:
		new_seed = randi()

	noise.seed = new_seed
	moisture_noise.seed = new_seed + 1000

	# Regenerar chunks existentes
	var chunks_to_regen = active_chunks.keys()
	clear_all_chunks()

	for chunk_pos in chunks_to_regen:
		generate_chunk(chunk_pos)

	print("✓ Mundo regenerado con seed: %d" % new_seed)

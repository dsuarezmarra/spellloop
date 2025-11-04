extends Node2D
class_name BiomeDecoratorsManager

"""
🌿 GESTOR DE DECORADORES PARA SISTEMA TILEMAP
==============================================

Coloca decoradores (rocas, plantas, etc.) sobre el TileMap
con fade automático cerca de bordes entre biomas.

CARACTERÍSTICAS:
- Detección de distancia a borde de bioma
- Alpha fade suave en transiciones
- Densidad configurable por bioma
- Seeding para reproducibilidad
"""

signal decorators_updated(chunk_pos: Vector2i)

# Referencias
@export var tilemap_generator: BiomeTileMapGenerator
@export var decorators_root: Node2D
@export var fade_distance: int = 3  # Tiles de distancia para fade

# Decoradores por chunk
var chunk_decorators: Dictionary = {}  # Vector2i → Array[Node2D]

# Configuración de decoradores por bioma
const DECOR_CONFIG = {
	0: {  # GRASSLAND
		"density": 0.15,
		"textures": [
			"res://assets/textures/biomes/Grassland/decor1.png",
			"res://assets/textures/biomes/Grassland/decor2.png",
			"res://assets/textures/biomes/Grassland/decor3.png",
			"res://assets/textures/biomes/Grassland/decor4.png",
			"res://assets/textures/biomes/Grassland/decor5.png"
		],
		"scale_range": Vector2(0.8, 1.2)
	},
	1: {  # DESERT
		"density": 0.12,
		"textures": [
			"res://assets/textures/biomes/Desert/decor1.png",
			"res://assets/textures/biomes/Desert/decor2.png",
			"res://assets/textures/biomes/Desert/decor3.png",
			"res://assets/textures/biomes/Desert/decor4.png",
			"res://assets/textures/biomes/Desert/decor5.png"
		],
		"scale_range": Vector2(0.7, 1.0)
	},
	2: {  # FOREST
		"density": 0.20,
		"textures": [
			"res://assets/textures/biomes/Forest/decor1.png",
			"res://assets/textures/biomes/Forest/decor2.png",
			"res://assets/textures/biomes/Forest/decor3.png",
			"res://assets/textures/biomes/Forest/decor4.png",
			"res://assets/textures/biomes/Forest/decor5.png"
		],
		"scale_range": Vector2(1.0, 1.5)
	},
	3: {  # ARCANE_WASTES
		"density": 0.10,
		"textures": [
			"res://assets/textures/biomes/ArcaneWastes/decor1.png",
			"res://assets/textures/biomes/ArcaneWastes/decor2.png",
			"res://assets/textures/biomes/ArcaneWastes/decor3.png",
			"res://assets/textures/biomes/ArcaneWastes/decor4.png",
			"res://assets/textures/biomes/ArcaneWastes/decor5.png"
		],
		"scale_range": Vector2(0.9, 1.3)
	},
	4: {  # LAVA
		"density": 0.08,
		"textures": [
			"res://assets/textures/biomes/Lava/decor1.png",
			"res://assets/textures/biomes/Lava/decor2.png",
			"res://assets/textures/biomes/Lava/decor3.png",
			"res://assets/textures/biomes/Lava/decor4.png",
			"res://assets/textures/biomes/Lava/decor5.png"
		],
		"scale_range": Vector2(0.8, 1.1)
	},
	5: {  # SNOW
		"density": 0.13,
		"textures": [
			"res://assets/textures/biomes/Snow/decor1.png",
			"res://assets/textures/biomes/Snow/decor2.png",
			"res://assets/textures/biomes/Snow/decor3.png",
			"res://assets/textures/biomes/Snow/decor4.png",
			"res://assets/textures/biomes/Snow/decor5.png"
		],
		"scale_range": Vector2(0.8, 1.2)
	}
}

func _ready():
	if not decorators_root:
		decorators_root = Node2D.new()
		decorators_root.name = "DecoratorsRoot"
		decorators_root.z_index = -96
		add_child(decorators_root)
	
	# Conectar con generador
	if tilemap_generator:
		tilemap_generator.chunk_generated.connect(_on_chunk_generated)
		tilemap_generator.chunk_removed.connect(_on_chunk_removed)
	
	print("✓ BiomeDecoratorsManager inicializado")

func _on_chunk_generated(chunk_pos: Vector2i):
	"""Generar decoradores cuando se crea un chunk"""
	await get_tree().process_frame  # Esperar a que el TileMap esté listo
	generate_decorators_for_chunk(chunk_pos)

func _on_chunk_removed(chunk_pos: Vector2i):
	"""Eliminar decoradores cuando se elimina un chunk"""
	remove_decorators_for_chunk(chunk_pos)

func generate_decorators_for_chunk(chunk_pos: Vector2i):
	"""Generar decoradores para un chunk"""
	
	if chunk_decorators.has(chunk_pos):
		return  # Ya existen
	
	var start_time = Time.get_ticks_msec()
	var decorators = []
	
	# Seed basado en posición del chunk
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(Vector2(chunk_pos.x * 1000 + chunk_pos.y, chunk_pos.y * 1000 + chunk_pos.x))
	
	# Calcular rango de tiles del chunk
	var chunk_size = tilemap_generator.chunk_size
	var start_x = chunk_pos.x * chunk_size
	var start_y = chunk_pos.y * chunk_size
	
	# Iterar cada tile del chunk
	for local_y in range(chunk_size):
		for local_x in range(chunk_size):
			var tile_x = start_x + local_x
			var tile_y = start_y + local_y
			
			# Obtener bioma de este tile
			var biome = tilemap_generator._get_biome_at_position(tile_x, tile_y)
			
			# Verificar si colocar decorador (según densidad)
			var config = DECOR_CONFIG.get(biome)
			if not config:
				continue
			
			if rng.randf() > config.density:
				continue  # No colocar aquí
			
			# Calcular distancia a borde de bioma
			var border_distance = _get_distance_to_biome_border(tile_x, tile_y, biome)
			
			# Si está muy cerca del borde, skip o reduce alpha
			if border_distance == 0:
				continue  # En el borde exacto, no colocar
			
			# Crear decorador
			var decor = _create_decorator(tile_x, tile_y, biome, border_distance, rng, config)
			if decor:
				decorators_root.add_child(decor)
				decorators.append(decor)
	
	chunk_decorators[chunk_pos] = decorators
	
	var elapsed = Time.get_ticks_msec() - start_time
	print("✓ Decoradores generados en %dms: %s (%d elementos)" % [elapsed, chunk_pos, decorators.size()])
	
	decorators_updated.emit(chunk_pos)

func _create_decorator(tile_x: int, tile_y: int, biome: int, border_distance: int, rng: RandomNumberGenerator, config: Dictionary) -> Sprite2D:
	"""Crear un sprite decorador"""
	
	var sprite = Sprite2D.new()
	
	# Seleccionar textura aleatoria
	var texture_path = config.textures[rng.randi() % config.textures.size()]
	sprite.texture = load(texture_path)
	
	if not sprite.texture:
		sprite.queue_free()
		return null
	
	# Posición en mundo (centro del tile + offset aleatorio)
	var tile_size = 64  # Tamaño de tile
	var world_x = tile_x * tile_size + tile_size / 2
	var world_y = tile_y * tile_size + tile_size / 2
	
	# Offset aleatorio dentro del tile
	var offset_x = rng.randf_range(-tile_size * 0.3, tile_size * 0.3)
	var offset_y = rng.randf_range(-tile_size * 0.3, tile_size * 0.3)
	
	sprite.position = Vector2(world_x + offset_x, world_y + offset_y)
	
	# Escala aleatoria
	var scale_range = config.scale_range
	var scale = rng.randf_range(scale_range.x, scale_range.y)
	sprite.scale = Vector2(scale, scale)
	
	# Rotación aleatoria
	sprite.rotation = rng.randf_range(0, TAU)
	
	# Alpha fade según distancia a borde
	var alpha = _calculate_border_fade(border_distance)
	sprite.modulate.a = alpha
	
	# Z-index
	sprite.z_index = -96
	
	return sprite

func _get_distance_to_biome_border(tile_x: int, tile_y: int, current_biome: int) -> int:
	"""
	Calcular distancia mínima a un tile de otro bioma.
	Retorna número de tiles hasta el borde más cercano.
	"""
	var min_distance = fade_distance + 1
	
	# Verificar tiles vecinos en un radio
	for dy in range(-fade_distance, fade_distance + 1):
		for dx in range(-fade_distance, fade_distance + 1):
			if dx == 0 and dy == 0:
				continue
			
			var check_x = tile_x + dx
			var check_y = tile_y + dy
			
			var neighbor_biome = tilemap_generator._get_biome_at_position(check_x, check_y)
			
			if neighbor_biome != current_biome:
				# Calcular distancia euclidiana
				var dist = sqrt(dx * dx + dy * dy)
				min_distance = min(min_distance, dist)
	
	return int(min_distance)

func _calculate_border_fade(distance: int) -> float:
	"""Calcular alpha según distancia a borde"""
	if distance >= fade_distance:
		return 1.0  # Lejos del borde, opaco
	
	# Fade suave: 0.0 en borde, 1.0 en fade_distance
	var normalized = float(distance) / float(fade_distance)
	return clamp(normalized * normalized, 0.0, 1.0)  # Curva cuadrática

func remove_decorators_for_chunk(chunk_pos: Vector2i):
	"""Eliminar decoradores de un chunk"""
	
	if not chunk_decorators.has(chunk_pos):
		return
	
	var decorators = chunk_decorators[chunk_pos]
	for decor in decorators:
		if is_instance_valid(decor):
			decor.queue_free()
	
	chunk_decorators.erase(chunk_pos)
	print("✓ Decoradores eliminados: %s" % chunk_pos)

func clear_all_decorators():
	"""Limpiar todos los decoradores"""
	for chunk_pos in chunk_decorators.keys():
		remove_decorators_for_chunk(chunk_pos)
	chunk_decorators.clear()
	print("✓ Todos los decoradores eliminados")

func get_decorator_count() -> int:
	"""Número total de decoradores activos"""
	var count = 0
	for decorators in chunk_decorators.values():
		count += decorators.size()
	return count

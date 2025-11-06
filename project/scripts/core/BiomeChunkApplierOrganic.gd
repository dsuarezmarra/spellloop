# BiomeChunkApplierOrganic.gd
# Aplicador de texturas para chunks ORGÁNICOS con múltiples biomas Voronoi
# Reemplazo completo del sistema antiguo BiomeChunkApplier.gd

extends Node
class_name BiomeChunkApplierOrganic

"""
🌍 BIOME CHUNK APPLIER ORGANIC - Sistema Multi-Bioma Voronoi
============================================================

Responsabilidades:
- Aplicar texturas base y decoraciones a chunks con MÚLTIPLES biomas
- Detectar qué bioma corresponde a cada posición usando BiomeGeneratorOrganic
- Crear tiles inteligentes de texturas base
- Colocar decorados específicos por bioma
- Aplicar dithering en BORDES ENTRE BIOMAS (no en bordes de chunk)

Diferencias con sistema antiguo:
- UN chunk puede tener MÚLTIPLES biomas (no solo uno)
- Las texturas se aplican por región Voronoi (no por chunk completo)
- Dithering entre REGIONES de biomas (bordes orgánicos)
"""

# ========== CONFIGURACIÓN ==========
@export var config_path: String = "res://assets/textures/biomes/biome_textures_config.json"
@export var tile_resolution: int = 512  # Resolución de cada tile de textura (px)
@export var decor_density_global: float = 1.0  # Multiplicador global de densidad
@export var decor_scale_min: float = 0.25  # Escala mínima de decoraciones (25% del tamaño original)
@export var decor_scale_max: float = 3.0   # Escala máxima de decoraciones (300% del tamaño original)
@export var dithering_enabled: bool = true
@export var dithering_width: int = 16  # Ancho de zona de transición entre biomas (px)
@export var debug_mode: bool = true

# ========== DATOS INTERNOS ==========
var _config: Dictionary = {}
var _biome_generator: Node = null  # Referencia a BiomeGeneratorOrganic

# ========== SEÑALES ==========
signal biome_textures_applied(chunk_pos: Vector2i, biomes_count: int)

func _ready() -> void:
	print("[BiomeChunkApplierOrganic] ✓ Inicializando (multi-bioma Voronoi)...")
	_load_config()
	print("[BiomeChunkApplierOrganic] ✓ Config cargado. Biomas disponibles: %d" % _config.get("biomes", []).size())

# ========== CARGAR CONFIGURACIÓN ==========
func _load_config() -> void:
	"""Cargar JSON de configuración de biomas"""
	if not ResourceLoader.exists(config_path):
		printerr("[BiomeChunkApplierOrganic] ✗ Config NO encontrado: %s" % config_path)
		return

	var file = FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		printerr("[BiomeChunkApplierOrganic] ✗ No se pudo abrir: %s" % config_path)
		return

	var json_string = file.get_as_text()
	var json = JSON.new()
	var parse_error = json.parse(json_string)

	if parse_error != OK:
		printerr("[BiomeChunkApplierOrganic] ✗ JSON parse error: %s" % json.get_error_message())
		return

	_config = json.get_data()

	if debug_mode:
		print("[BiomeChunkApplierOrganic] ✓ Config cargado exitosamente")

# ========== APLICAR BIOMA A CHUNK ==========
func apply_biome_to_chunk(chunk_node: Node2D, cx: int, cy: int) -> void:
	"""
	Aplicar texturas y decoraciones a un chunk que puede contener MÚLTIPLES biomas.

	PROCESO:
	1. Obtener referencia a BiomeGeneratorOrganic
	2. Dividir chunk en grid de tiles (ej: 30×30 tiles de 500×500 px)
	3. Para cada tile, detectar bioma dominante
	4. Aplicar textura base correspondiente
	5. Colocar decoraciones según bioma en cada posición
	6. Aplicar dithering en bordes entre biomas

	Args:
		chunk_node: Nodo del chunk (Node2D)
		cx, cy: Coordenadas del chunk en grid
	"""

	# Obtener referencia al generador orgánico
	if _biome_generator == null:
		_biome_generator = _find_biome_generator(chunk_node)
		if _biome_generator == null:
			printerr("[BiomeChunkApplierOrganic] ✗ No se encontró BiomeGeneratorOrganic")
			return

	# Dimensiones del chunk
	const CHUNK_WIDTH = 15000
	const CHUNK_HEIGHT = 15000
	var chunk_world_x = cx * CHUNK_WIDTH
	var chunk_world_y = cy * CHUNK_HEIGHT

	# Crear contenedor para texturas
	var biome_layer = Node2D.new()
	biome_layer.name = "BiomeLayerOrganic"
	biome_layer.z_index = -100  # Muy atrás
	chunk_node.add_child(biome_layer)

	# Aplicar sistema de tiles con múltiples biomas
	var biomes_detected = _apply_multi_biome_tiles(
		biome_layer,
		chunk_world_x,
		chunk_world_y,
		CHUNK_WIDTH,
		CHUNK_HEIGHT
	)

	# Aplicar decoraciones específicas por bioma
	_apply_biome_specific_decorations(
		biome_layer,
		chunk_world_x,
		chunk_world_y,
		CHUNK_WIDTH,
		CHUNK_HEIGHT,
		biomes_detected
	)

	# Aplicar dithering en bordes entre biomas
	if dithering_enabled:
		_apply_voronoi_dithering(
			biome_layer,
			chunk_world_x,
			chunk_world_y,
			CHUNK_WIDTH,
			CHUNK_HEIGHT
		)

	# Guardar metadatos
	chunk_node.set_meta("biome_system", "organic_voronoi")
	chunk_node.set_meta("biomes_detected", biomes_detected)

	if debug_mode:
		var biome_names = []
		for biome_id in biomes_detected.keys():
			biome_names.append(_get_biome_name_by_id(biome_id))
		print("[BiomeChunkApplierOrganic] ✓ Chunk (%d,%d) aplicado con %d biomas: %s" % [
			cx, cy, biomes_detected.size(), biome_names
		])

	biome_textures_applied.emit(Vector2i(cx, cy), biomes_detected.size())

# ========== APLICAR TILES MULTI-BIOMA ==========
func _apply_multi_biome_tiles(
	parent: Node2D,
	chunk_world_x: float,
	chunk_world_y: float,
	chunk_width: int,
	chunk_height: int
) -> Dictionary:
	"""
	Aplicar texturas base dividiendo el chunk en tiles y detectando bioma por tile.

	ESTRATEGIA:
	- Dividir chunk en grid de tiles (ej: 30×30 = 900 tiles)
	- Cada tile de 500×500 px
	- Detectar bioma en el centro de cada tile
	- Crear sprite con textura correspondiente

	Returns:
		Dictionary {biome_id: tile_count} con estadísticas de biomas presentes
	"""

	var tile_size = tile_resolution  # 512 px por tile
	var tiles_x = ceili(float(chunk_width) / tile_size)  # ~30 tiles
	var tiles_y = ceili(float(chunk_height) / tile_size)  # ~30 tiles

	var biomes_count = {}  # Estadísticas de biomas

	if debug_mode:
		print("[BiomeChunkApplierOrganic] 🎨 Aplicando %d×%d tiles (total: %d)" % [
			tiles_x, tiles_y, tiles_x * tiles_y
		])

	# Para cada tile del grid
	for ty in range(tiles_y):
		for tx in range(tiles_x):
			# Calcular posición mundial del centro del tile
			var tile_world_x = chunk_world_x + (tx * tile_size) + (tile_size / 2.0)
			var tile_world_y = chunk_world_y + (ty * tile_size) + (tile_size / 2.0)

			# Detectar bioma en esta posición
			var biome_type = _biome_generator.get_biome_at_world_position(tile_world_x, tile_world_y)

			# Contar biomas
			if not biomes_count.has(biome_type):
				biomes_count[biome_type] = 0
			biomes_count[biome_type] += 1

			# Cargar textura del bioma
			var texture = _load_biome_base_texture(biome_type)
			if texture == null:
				continue

			# Crear sprite para este tile
			var sprite = Sprite2D.new()
			sprite.name = "BiomeTile_%d_%d" % [tx, ty]
			sprite.texture = texture
			sprite.centered = true

			# Posición del tile (esquina superior izquierda + centro)
			sprite.position = Vector2(
				tx * tile_size + tile_size / 2.0,
				ty * tile_size + tile_size / 2.0
			)

			# Escalar para llenar tile completo
			var texture_size = texture.get_size()
			sprite.scale = Vector2(
				tile_size / texture_size.x,
				tile_size / texture_size.y
			)

			sprite.z_index = -100
			parent.add_child(sprite)

	if debug_mode:
		print("[BiomeChunkApplierOrganic] ✓ Tiles aplicados. Biomas detectados:")
		for biome_id in biomes_count.keys():
			var biome_name = _get_biome_name_by_id(biome_id)
			var percentage = (biomes_count[biome_id] * 100.0) / (tiles_x * tiles_y)
			print("  - %s: %d tiles (%.1f%%)" % [biome_name, biomes_count[biome_id], percentage])

	return biomes_count

# ========== APLICAR DECORACIONES POR BIOMA ==========
func _apply_biome_specific_decorations(
	parent: Node2D,
	chunk_world_x: float,
	chunk_world_y: float,
	chunk_width: int,
	chunk_height: int,
	biomes_present: Dictionary
) -> void:
	"""
	Colocar decoraciones específicas según el bioma en cada posición.

	ESTRATEGIA:
	- Generar posiciones aleatorias dentro del chunk
	- Detectar bioma en cada posición
	- Cargar decoración aleatoria del bioma correspondiente
	- Colocar sprite con variación de escala/color
	
	IMPORTANTE - DECORACIONES:
	- ✅ Escala variable: x0.25 a x3.0 del tamaño original (configurable)
	- ❌ NUNCA rotar: rotation = 0 siempre (se verían mal rotadas)
	- ✅ Variación de color sutil para diversidad visual
	"""

	# Calcular número de decoraciones según densidad
	var base_decor_count = 50  # Base: 50 decoraciones por chunk
	var total_decors = int(base_decor_count * decor_density_global)

	# RNG determinístico por chunk
	var chunk_rng = RandomNumberGenerator.new()
	var chunk_seed = hash(Vector2i(chunk_world_x / 15000, chunk_world_y / 15000))
	chunk_rng.seed = chunk_seed

	var decors_by_biome = {}  # Contador por bioma

	for i in range(total_decors):
		# Posición aleatoria dentro del chunk
		var local_x = chunk_rng.randf_range(0, chunk_width)
		var local_y = chunk_rng.randf_range(0, chunk_height)
		var world_x = chunk_world_x + local_x
		var world_y = chunk_world_y + local_y

		# Detectar bioma en esta posición
		var biome_type = _biome_generator.get_biome_at_world_position(world_x, world_y)

		# Contar decoraciones por bioma
		if not decors_by_biome.has(biome_type):
			decors_by_biome[biome_type] = 0
		decors_by_biome[biome_type] += 1

		# Cargar decoración aleatoria del bioma
		var decor_texture = _load_random_biome_decor(biome_type, chunk_rng)
		if decor_texture == null:
			continue

		# Crear sprite de decoración
		var sprite = Sprite2D.new()
		sprite.name = "BiomeDecor_%d" % i
		sprite.texture = decor_texture
		sprite.centered = true
		sprite.position = Vector2(local_x, local_y)

		# Escala variable uniforme (x0.25 a x3.0 del tamaño original)
		# IMPORTANTE: NO rotar nunca (rotation = 0), solo escalar
		var scale_factor = chunk_rng.randf_range(decor_scale_min, decor_scale_max)
		sprite.scale = Vector2(scale_factor, scale_factor)  # Escala uniforme
		sprite.rotation = 0.0  # NUNCA rotar decoraciones (se verían mal)

		# Variación de color sutil para variedad visual
		sprite.modulate = Color(
			chunk_rng.randf_range(0.9, 1.1),
			chunk_rng.randf_range(0.9, 1.1),
			chunk_rng.randf_range(0.9, 1.1),
			chunk_rng.randf_range(0.85, 0.95)
		)

		sprite.z_index = -96  # Encima de base, debajo de personajes
		parent.add_child(sprite)

	if debug_mode:
		print("[BiomeChunkApplierOrganic] ✓ %d decoraciones colocadas:" % total_decors)
		for biome_id in decors_by_biome.keys():
			var biome_name = _get_biome_name_by_id(biome_id)
			print("  - %s: %d decors" % [biome_name, decors_by_biome[biome_id]])

# ========== APLICAR DITHERING VORONOI ==========
func _apply_voronoi_dithering(
	parent: Node2D,
	chunk_world_x: float,
	chunk_world_y: float,
	chunk_width: int,
	chunk_height: int
) -> void:
	"""
	Aplicar dithering en los BORDES ENTRE BIOMAS (no en bordes de chunk).

	ESTRATEGIA:
	- Detectar píxeles cercanos a bordes de biomas
	- Aplicar patrón Bayer para mezclar texturas
	- Crear transición suave y orgánica

	NOTA: Implementación simplificada por ahora
	TODO: Implementar dithering real con shader o compositing
	"""

	# Por ahora, sistema simplificado: aplicar capa de transición suave
	# El dithering real se implementará en versión futura con shaders

	if debug_mode:
		print("[BiomeChunkApplierOrganic] ⚠️ Dithering Voronoi (simplificado)")

	# TODO: Implementar dithering Voronoi completo
	pass

# ========== UTILIDADES ==========

func _find_biome_generator(chunk_node: Node2D) -> Node:
	"""Encontrar BiomeGeneratorOrganic en el árbol"""
	var root = chunk_node.get_tree().root
	return root.find_child("BiomeGeneratorOrganic", true, false)

func _get_biome_name_by_id(biome_id: int) -> String:
	"""Obtener nombre del bioma por ID"""
	const BIOME_NAMES = {
		0: "Grassland",
		1: "Desert",
		2: "Snow",
		3: "Lava",
		4: "ArcaneWastes",
		5: "Forest",
	}
	return BIOME_NAMES.get(biome_id, "Unknown")

func _load_biome_base_texture(biome_type: int) -> Texture2D:
	"""Cargar textura base de un bioma específico"""
	var biome_name = _get_biome_name_by_id(biome_type)
	var texture_path = "res://assets/textures/biomes/%s/base.png" % biome_name

	if not ResourceLoader.exists(texture_path):
		printerr("[BiomeChunkApplierOrganic] ✗ Textura no encontrada: %s" % texture_path)
		return null

	return load(texture_path) as Texture2D

func _load_random_biome_decor(biome_type: int, rng: RandomNumberGenerator) -> Texture2D:
	"""Cargar decoración aleatoria de un bioma específico"""
	var biome_name = _get_biome_name_by_id(biome_type)

	# Seleccionar aleatoriamente entre decor1-decor5
	var decor_num = rng.randi_range(1, 5)
	var texture_path = "res://assets/textures/biomes/%s/decor%d.png" % [biome_name, decor_num]

	if not ResourceLoader.exists(texture_path):
		# Intentar con decor1 como fallback
		texture_path = "res://assets/textures/biomes/%s/decor1.png" % biome_name
		if not ResourceLoader.exists(texture_path):
			return null

	return load(texture_path) as Texture2D

func get_biome_at_position(cx: int, cy: int) -> Dictionary:
	"""
	Compatibilidad con sistema antiguo (no usado en sistema orgánico).
	En sistema orgánico, cada POSICIÓN tiene su bioma, no cada chunk.
	"""
	return {}

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
- Crear tiles inteligentes (256px) que siguen las regiones Voronoi
- Los bordes orgánicos aparecen NATURALMENTE al seguir el patrón Voronoi
- Colocar decorados específicos por bioma

Sistema de tiles mejorado:
- Tiles de 512×512 px (balance óptimo entre rendimiento y calidad visual)
- ~30×30 = 900 tiles por chunk (15000×15000 px)
- Cada tile detecta bioma en su centro
- Los bordes irregulares se forman AUTOMÁTICAMENTE
- Sin dithering artificial (no es necesario)

Diferencias con sistema antiguo:
- UN chunk puede tener MÚLTIPLES biomas (no solo uno)
- Las texturas se aplican por región Voronoi (no por chunk completo)
- Bordes orgánicos naturales sin procesamiento adicional
"""

# ========== CONFIGURACIÓN ==========
@export var config_path: String = "res://assets/textures/biomes/biome_textures_config.json"
@export var tile_resolution: int = 256  # Tiles de 256px (bordes más suaves)
@export var decor_density_global: float = 1.0  # Multiplicador global de densidad
@export var border_decor_multiplier: float = 4.0  # Multiplicador de decoraciones en tiles de borde (4x más denso)
@export var debug_mode: bool = true

# ========== DATOS INTERNOS ==========
var _config: Dictionary = {}
var _biome_generator: Node = null  # Referencia a BiomeGeneratorOrganic
var _biome_animation_offsets: Dictionary = {}  # Frame inicial por bioma (sincronización global)

# ========== SEÑALES ==========
signal biome_textures_applied(chunk_pos: Vector2i, biomes_count: int)

func _ready() -> void:
	print("[BiomeChunkApplierOrganic] ✓ Inicializando (multi-bioma Voronoi)...")
	_load_config()
	print("[BiomeChunkApplierOrganic] ✓ Config cargado. Biomas disponibles: %d" % _config.get("biomes", []).size())
	_initialize_biome_animation_offsets()

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

func _initialize_biome_animation_offsets() -> void:
	"""
	Inicializar offsets de animación por bioma para sincronización global.
	Cada bioma tendrá un frame inicial fijo que se aplica a TODOS sus tiles.
	"""
	# Frame inicial aleatorio pero consistente por bioma
	_biome_animation_offsets[BiomeGeneratorOrganic.BIOME_GRASSLAND] = randi() % 100
	_biome_animation_offsets[BiomeGeneratorOrganic.BIOME_FOREST] = randi() % 100
	_biome_animation_offsets[BiomeGeneratorOrganic.BIOME_DESERT] = randi() % 100
	_biome_animation_offsets[BiomeGeneratorOrganic.BIOME_SNOW] = randi() % 100
	_biome_animation_offsets[BiomeGeneratorOrganic.BIOME_LAVA] = randi() % 100
	_biome_animation_offsets[BiomeGeneratorOrganic.BIOME_SWAMP] = randi() % 100
	_biome_animation_offsets[BiomeGeneratorOrganic.BIOME_ARCANE_WASTES] = randi() % 100
	
	if debug_mode:
		print("[BiomeChunkApplierOrganic] ✓ Offsets de animación por bioma inicializados")

# ========== APLICAR BIOMA A CHUNK ==========
func apply_biome_to_chunk(chunk_node: Node2D, cx: int, cy: int) -> void:
	"""
	Aplicar texturas y decoraciones a un chunk que puede contener MÚLTIPLES biomas.

	PROCESO:
	1. Obtener referencia a BiomeGeneratorOrganic
	2. Dividir chunk en grid de tiles (ej: ~60×60 tiles de 256×256 px)
	3. Para cada tile, detectar bioma dominante en su centro
	4. Aplicar textura base correspondiente
	5. Los bordes orgánicos aparecen NATURALMENTE porque cada tile sigue Voronoi
	6. Colocar decoraciones según bioma en cada posición

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

	ESTRATEGIA MEJORADA:
	- Tiles más pequeños (256px) siguen mejor las curvas Voronoi
	- ~60×60 = 3600 tiles por chunk (manejable, no crea lag)
	- Cada tile detecta bioma en su centro
	- Los bordes orgánicos aparecen NATURALMENTE sin dithering

	Returns:
		Dictionary {biome_id: tile_count} con estadísticas de biomas presentes
	"""

	var tile_size = tile_resolution  # 256 px por tile
	var tiles_x = ceili(float(chunk_width) / tile_size)  # ~59 tiles
	var tiles_y = ceili(float(chunk_height) / tile_size)  # ~59 tiles

	var biomes_count = {}  # Estadísticas de biomas
	var tile_biome_map = {}  # Mapa de biomas por tile [Vector2i(tx,ty)] -> biome_type

	if debug_mode:
		print("[BiomeChunkApplierOrganic] 🎨 Aplicando %d×%d tiles (total: %d)" % [
			tiles_x, tiles_y, tiles_x * tiles_y
		])

	# FASE 1: Aplicar tiles y construir mapa de biomas
	for ty in range(tiles_y):
		for tx in range(tiles_x):
			# Calcular posición mundial del centro del tile
			var tile_world_x = chunk_world_x + (tx * tile_size) + (tile_size / 2.0)
			var tile_world_y = chunk_world_y + (ty * tile_size) + (tile_size / 2.0)

			# Detectar bioma en esta posición
			var biome_type = _biome_generator.get_biome_at_world_position(tile_world_x, tile_world_y)
			
			# Guardar en mapa para detección de bordes
			tile_biome_map[Vector2i(tx, ty)] = biome_type

			# Contar biomas
			if not biomes_count.has(biome_type):
				biomes_count[biome_type] = 0
			biomes_count[biome_type] += 1

			# Crear nodo de textura base (animada o estática)
			var tile_node = _create_biome_base_tile_node(biome_type)
			if tile_node == null:
				continue

			# Configurar propiedades comunes (Sprite2D o AnimatedSprite2D)
			tile_node.name = "BiomeTile_%d_%d" % [tx, ty]
			tile_node.centered = true

			# Posición del tile (esquina superior izquierda + centro)
			tile_node.position = Vector2(
				tx * tile_size + tile_size / 2.0,
				ty * tile_size + tile_size / 2.0
			)

			# Escalar para llenar tile completo
			var texture_size: Vector2
			if tile_node is AnimatedSprite2D:
				# Para AnimatedSprite2D, obtener tamaño del frame actual
				var frames = tile_node.sprite_frames
				if frames != null and frames.has_animation("default"):
					var frame_texture = frames.get_frame_texture("default", 0)
					if frame_texture != null:
						texture_size = frame_texture.get_size()
					else:
						texture_size = Vector2(512, 512)  # Fallback
				else:
					texture_size = Vector2(512, 512)  # Fallback
			else:
				# Para Sprite2D, obtener tamaño de la textura
				texture_size = tile_node.texture.get_size()
			
			tile_node.scale = Vector2(
				tile_size / texture_size.x,
				tile_size / texture_size.y
			)

			tile_node.z_index = -100
			parent.add_child(tile_node)

	# FASE 2: Detectar tiles de borde y aplicar decoraciones extra
	var border_tiles = _detect_border_tiles(tile_biome_map, tiles_x, tiles_y)
	
	if debug_mode:
		print("[BiomeChunkApplierOrganic] 🔍 Bordes detectados: %d tiles en transición" % border_tiles.size())
	
	# Aplicar decoraciones densas en bordes
	_apply_border_decorations(parent, border_tiles, tile_biome_map, tile_size, chunk_world_x, chunk_world_y)

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
	"""

	# Calcular número de decoraciones según densidad
	var base_decor_count = 120  # Base: 120 decoraciones por chunk (antes 50, aumentado para más densidad)
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

		# Crear nodo de decoración (estática o animada)
		var decor_node = _create_random_biome_decor_node(biome_type, chunk_rng)
		if decor_node == null:
			continue

		# Configurar decoración
		decor_node.name = "BiomeDecor_%d" % i
		decor_node.position = Vector2(local_x, local_y)

		# Escala aleatoria variable (0.5x a 3.0x del tamaño base)
		var scale_factor = chunk_rng.randf_range(0.5, 3.0)
		decor_node.scale = Vector2(scale_factor, scale_factor)
		
		# Flip horizontal aleatorio (50% probabilidad) para dar variedad
		if chunk_rng.randf() > 0.5:
			decor_node.scale.x *= -1.0

		# Variación de color sutil
		decor_node.modulate = Color(
			chunk_rng.randf_range(0.9, 1.1),
			chunk_rng.randf_range(0.9, 1.1),
			chunk_rng.randf_range(0.9, 1.1),
			chunk_rng.randf_range(0.85, 0.95)
		)

		decor_node.z_index = -96  # Encima de base, debajo de personajes
		parent.add_child(decor_node)

	if debug_mode:
		print("[BiomeChunkApplierOrganic] ✓ %d decoraciones colocadas:" % total_decors)
		for biome_id in decors_by_biome.keys():
			var biome_name = _get_biome_name_by_id(biome_id)
			print("  - %s: %d decors" % [biome_name, decors_by_biome[biome_id]])

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

func _create_biome_base_tile_node(biome_type: int) -> Node2D:
	"""
	Crear nodo de textura base (animada o estática) para un bioma específico.
	Prioridad: Sprite sheet animado → PNG estático (variante a/b) → Fallback antiguo
	Retorna AnimatedSprite2D o Sprite2D según disponibilidad
	
	IMPORTANTE: Las animaciones se sincronizan por bioma (todos los tiles del mismo
	bioma tienen el mismo frame inicial para patrón consistente).
	"""
	var biome_name = _get_biome_name_by_id(biome_type)
	var biome_lower = biome_name.to_lower()
	
	# PRIORIDAD 1: Intentar cargar sprite sheet animado
	# Detectar sprite sheets con patrón: {biome}_base_animated_sheet_fN_SIZE.png
	var base_path = "res://assets/textures/biomes/%s/base/%s_base_animated" % [biome_name, biome_lower]
	var animated_node = AutoFrames.load_sprite(base_path)
	
	if animated_node != null:
		if animated_node is AnimatedSprite2D:
			animated_node.play("default")
			
			# SINCRONIZACIÓN POR BIOMA: Todos los tiles del mismo bioma comparten frame inicial
			var biome_offset = _biome_animation_offsets.get(biome_type, 0)
			var frame_count = animated_node.sprite_frames.get_frame_count("default")
			if frame_count > 0:
				animated_node.frame = biome_offset % frame_count
			
			# Velocidad fija (sin variación) para mantener sincronización
			animated_node.speed_scale = 1.0
			
			return animated_node
		else:
			# Es Sprite2D estático (solo 1 frame)
			return animated_node
	
	# PRIORIDAD 2: Textura estática con variante a/b (formato nuevo)
	var variant = ["a", "b"][randi() % 2]
	var texture_path = "res://assets/textures/biomes/%s/base/%s_base_%s_256.png" % [biome_name, biome_lower, variant]
	
	if ResourceLoader.exists(texture_path):
		var sprite = Sprite2D.new()
		sprite.texture = load(texture_path) as Texture2D
		return sprite
	
	# PRIORIDAD 3: Fallback formato antiguo base.png
	texture_path = "res://assets/textures/biomes/%s/base.png" % biome_name
	if ResourceLoader.exists(texture_path):
		var sprite = Sprite2D.new()
		sprite.texture = load(texture_path) as Texture2D
		return sprite
	
	printerr("[BiomeChunkApplierOrganic] ✗ Textura base no encontrada para bioma: %s" % biome_name)
	return null

func _load_random_biome_decor(biome_type: int, rng: RandomNumberGenerator) -> Texture2D:
	"""
	Cargar decoración aleatoria de un bioma específico.
	OBSOLETO: Usar _create_random_biome_decor_node() para soporte de animaciones.
	Mantenido por compatibilidad temporal.
	"""
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

func _create_random_biome_decor_node(biome_type: int, rng: RandomNumberGenerator) -> Node2D:
	"""
	Crear nodo de decoración (estática o animada) de un bioma específico.
	Soporta tanto PNG estáticos como spritesheets animados.
	
	Convención de nombres:
	- Estáticos: decorN_static_X.png (ej: lava_crack_static_a.png)
	- Animados: decorN_sheet_fF_SIZE.png (ej: lava_spout_sheet_f8_256.png)
	
	Returns:
	- Sprite2D para decoraciones estáticas
	- AnimatedSprite2D para decoraciones animadas
	- null si no se encuentra ninguna decoración
	"""
	var biome_name = _get_biome_name_by_id(biome_type)
	var biome_lower = biome_name.to_lower()
	var decor_folder = "res://assets/textures/biomes/%s/decor/" % biome_name
	
	# Buscar decoraciones disponibles (estáticas y animadas)
	var available_decors = []
	
	# Buscar spritesheets animados (cualquier cantidad de frames y tamaño)
	# Patrones: {biome}_decor{N}_sheet_f{frames}_{size}.png
	for i in range(1, 11):  # Buscar hasta decor10
		for frames in [4, 6, 7, 8, 10, 12, 16]:  # Soportar múltiples cantidades de frames
			for size in [128, 256, 512]:  # Soportar múltiples tamaños
				var sheet_path = "%s%s_decor%d_sheet_f%d_%d.png" % [
					decor_folder, biome_lower, i, frames, size
				]
				if ResourceLoader.exists(sheet_path):
					available_decors.append(sheet_path)
	
	# Buscar decoraciones estáticas (con variantes a, b, c)
	for i in range(1, 11):  # Buscar hasta decor10
		for variant in ["a", "b", "c"]:
			var static_path = "%s%s_decor%d_static_%s.png" % [
				decor_folder, biome_lower, i, variant
			]
			if ResourceLoader.exists(static_path):
				available_decors.append(static_path)
	
	# Fallback: buscar formato antiguo (decorN.png)
	if available_decors.is_empty():
		for i in range(1, 6):
			var legacy_path = "res://assets/textures/biomes/%s/decor%d.png" % [biome_name, i]
			if ResourceLoader.exists(legacy_path):
				available_decors.append(legacy_path)
	
	# Si no hay decoraciones, retornar null
	if available_decors.is_empty():
		if debug_mode:
			push_warning("⚠️ [BiomeChunkApplier] No se encontraron decoraciones para %s" % biome_name)
		return null
	
	# Seleccionar decoración aleatoria
	var selected_decor = available_decors[rng.randi() % available_decors.size()]
	
	# Crear nodo usando DecorFactory
	var decor_node = DecorFactory.make_decor(selected_decor, 10.0)
	
	return decor_node

# ========== SISTEMA DE DETECCIÓN DE BORDES ==========

func _detect_border_tiles(tile_biome_map: Dictionary, tiles_x: int, tiles_y: int) -> Array:
	"""
	Detectar tiles que están en los bordes entre biomas.
	Un tile es "borde" si algún vecino (arriba, abajo, izquierda, derecha) tiene diferente bioma.
	
	Returns: Array de Vector2i con coordenadas (tx, ty) de tiles de borde
	"""
	var border_tiles = []
	
	for ty in range(tiles_y):
		for tx in range(tiles_x):
			var current_pos = Vector2i(tx, ty)
			var current_biome = tile_biome_map.get(current_pos)
			
			if current_biome == null:
				continue
			
			# Revisar vecinos (4 direcciones: arriba, abajo, izq, der)
			var neighbors = [
				Vector2i(tx, ty - 1),  # Arriba
				Vector2i(tx, ty + 1),  # Abajo
				Vector2i(tx - 1, ty),  # Izquierda
				Vector2i(tx + 1, ty),  # Derecha
			]
			
			var is_border = false
			for neighbor_pos in neighbors:
				var neighbor_biome = tile_biome_map.get(neighbor_pos)
				if neighbor_biome != null and neighbor_biome != current_biome:
					is_border = true
					break
			
			if is_border:
				border_tiles.append(current_pos)
	
	return border_tiles

func _apply_border_decorations(
	parent: Node2D,
	border_tiles: Array,
	tile_biome_map: Dictionary,
	tile_size: int,
	chunk_world_x: float,
	chunk_world_y: float
) -> void:
	"""
	Aplicar decoraciones extra en tiles de borde para camuflar transiciones.
	Usa border_decor_multiplier (ej: 4.0 = 4x más decoraciones en bordes).
	"""
	
	# RNG determinístico
	var border_rng = RandomNumberGenerator.new()
	border_rng.seed = hash(Vector2(chunk_world_x, chunk_world_y)) + 12345
	
	# Número de decoraciones por tile de borde
	var decors_per_border_tile = int(border_decor_multiplier * 2)  # ej: 4.0 * 2 = 8 decoraciones/tile
	
	var total_border_decors = 0
	
	for tile_pos in border_tiles:
		var tx = tile_pos.x
		var ty = tile_pos.y
		var biome_type = tile_biome_map.get(tile_pos)
		
		if biome_type == null:
			continue
		
		# Colocar múltiples decoraciones en este tile de borde
		for i in range(decors_per_border_tile):
			# Posición aleatoria dentro del tile
			var local_x = (tx * tile_size) + border_rng.randf_range(0, tile_size)
			var local_y = (ty * tile_size) + border_rng.randf_range(0, tile_size)
			
			# Crear nodo de decoración (estática o animada)
			var decor_node = _create_random_biome_decor_node(biome_type, border_rng)
			if decor_node == null:
				continue
			
			# Configurar decoración de borde
			decor_node.name = "BorderDecor_%d_%d_%d" % [tx, ty, i]
			decor_node.position = Vector2(local_x, local_y)
			
			# Escala aleatoria variable (0.5x a 3.0x del tamaño base)
			var scale_factor = border_rng.randf_range(0.5, 3.0)
			decor_node.scale = Vector2(scale_factor, scale_factor)
			
			# Flip horizontal aleatorio (50% probabilidad) para dar variedad
			if border_rng.randf() > 0.5:
				decor_node.scale.x *= -1.0
			
			# Variación de color y alpha
			decor_node.modulate = Color(
				border_rng.randf_range(0.85, 1.15),
				border_rng.randf_range(0.85, 1.15),
				border_rng.randf_range(0.85, 1.15),
				border_rng.randf_range(0.7, 0.9)  # Más transparentes
			)
			
			decor_node.z_index = -95  # Encima de decoraciones normales
			parent.add_child(decor_node)
			
			total_border_decors += 1
	
	if debug_mode:
		print("[BiomeChunkApplierOrganic] 🎨 %d decoraciones de borde colocadas (x%.1f densidad)" % [
			total_border_decors, border_decor_multiplier
		])

func get_biome_at_position(cx: int, cy: int) -> Dictionary:
	"""
	Compatibilidad con sistema antiguo (no usado en sistema orgánico).
	En sistema orgánico, cada POSICIÓN tiene su bioma, no cada chunk.
	"""
	return {}

# InfiniteWorldManager.gd
# Sistema de generación dinámica de regiones orgánicas infinitas
# - Regiones de forma irregular y tamaño variable (1.5x-3x pantalla)
# - Hasta 12 regiones simultáneas con formas fluidas
# - Caché persistente optimizado para formas complejas
# - Blending visual entre biomas adyacentes
# - Generación asíncrona determinística basada en semilla

extends Node2D
class_name InfiniteWorldManager

signal region_generated(region_id: Vector2i)
signal region_loaded_from_cache(region_id: Vector2i)
signal _biome_transition_detected(from_biome: String, to_biome: String)

# ========== CONFIGURACIÓN DE REGIONES ==========
@export var base_region_size: float = 2000.0 # Tamaño base (aprox 1x pantalla)
@export var region_size_variance: float = 0.5 # Variación de tamaño (±50%)
@export var max_active_regions: int = 12 # Máximo de regiones cargadas
@export var visibility_radius: float = 4000.0 # Radio de carga de regiones
@export var unload_radius: float = 6000.0 # Radio de descarga de regiones

# ========== COMPATIBILIDAD CON CHUNKS ==========
@export var chunk_width: float = 1000.0 # Ancho de chunks (compatibilidad con ItemManager)
@export var chunk_height: float = 1000.0 # Alto de chunks (compatibilidad con ItemManager)

# ========== CONTROL DE REGIONES ==========
var active_regions: Dictionary = {} # Key: Vector2i (region_id), Value: Node2D (region_root)
var current_region_id: Vector2i = Vector2i(0, 0)
var region_loading_queue: Array[Vector2i] = []

# ========== REFERENCIAS DEL SISTEMA ==========
var player_ref: Node = null
var regions_root: Node2D = null # Contenedor de todas las regiones
var chunks_root: Node2D = null # Contenedor para chunks (compatibilidad)
var active_chunks: Dictionary = {} # Compatibilidad con sistema de chunks
var organic_shape_generator: Node = null
var biome_generator: Node = null
var region_cache_manager: Node = null # Renombrado de chunk_cache_manager
var biome_region_applier: Node = null # Aplicador de regiones y texturas
var organic_texture_blender: Node = null # Nuevo sistema de blending

# ========== SISTEMA DE POSICIÓN VIRTUAL ==========
var player_virtual_position: Vector2 = Vector2.ZERO # Posición virtual del jugador
var world_offset: Vector2 = Vector2.ZERO # Offset acumulado del mundo

# ========== ESTADO Y CONTROL ==========
var is_generating_regions: bool = false
var generation_frame_budget: int = 2 # Máx regiones generadas por frame
var world_seed: int = 12345
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# ========== DEBUG Y RENDIMIENTO ==========
var debug_mode: bool = true
var show_region_boundaries: bool = false
var performance_stats: Dictionary = {
	"regions_generated": 0,
	"regions_cached": 0,
	"blend_operations": 0
}

func _ready() -> void:
	"""Inicializar el gestor de mundo de regiones orgánicas"""
	print("[InfiniteWorldManager] 🌊 Inicializando sistema de regiones orgánicas...")

	# Configurar RNG con semilla del mundo
	rng.seed = world_seed

	# Cargar todos los componentes del sistema orgánico
	_load_organic_shape_generator()
	_load_biome_generator()
	_load_region_cache_manager()
	_load_biome_region_applier()
	_load_organic_texture_blender()

	# Conectar referencias entre componentes
	_connect_system_references()

	# Configurar procesamiento continuo
	set_process(true)

	print("[InfiniteWorldManager] ✅ Sistema orgánico inicializado - Semilla: %d" % world_seed)

func _connect_system_references() -> void:
	"""Conectar referencias entre componentes del sistema después de la carga"""
	if biome_region_applier and organic_texture_blender:
		# Pasar la referencia directamente si BiomeRegionApplier tiene método para ello
		if biome_region_applier.has_method("set_organic_texture_blender"):
			biome_region_applier.set_organic_texture_blender(organic_texture_blender)
			print("[InfiniteWorldManager] 🔗 Referencias del sistema conectadas")
		else:
			print("[InfiniteWorldManager] ⚠️ BiomeRegionApplier no tiene método de conexión")

func _load_organic_shape_generator() -> void:
	"""Cargar el generador de formas orgánicas"""
	var OrganicShapeGeneratorClass = load("res://scripts/core/OrganicShapeGenerator.gd")
	organic_shape_generator = OrganicShapeGeneratorClass.new()
	organic_shape_generator.name = "OrganicShapeGenerator"
	organic_shape_generator.base_region_size = base_region_size
	organic_shape_generator.size_variance = region_size_variance
	add_child(organic_shape_generator)
	organic_shape_generator.initialize(world_seed)
	print("[InfiniteWorldManager] 🌊 OrganicShapeGenerator cargado")

func _load_biome_generator() -> void:
	"""Cargar el generador de biomas (reescrito para regiones orgánicas)"""
	if ResourceLoader.exists("res://scripts/core/BiomeGenerator.gd"):
		var bg_script = load("res://scripts/core/BiomeGenerator.gd")
		if bg_script:
			biome_generator = bg_script.new()
			biome_generator.name = "BiomeGenerator"
			add_child(biome_generator)
			print("[InfiniteWorldManager] 🌿 BiomeGenerator cargado")

func _load_region_cache_manager() -> void:
	"""Cargar el gestor de caché de regiones (reutiliza ChunkCacheManager)"""
	if ResourceLoader.exists("res://scripts/core/ChunkCacheManager.gd"):
		var rcm_script = load("res://scripts/core/ChunkCacheManager.gd")
		if rcm_script:
			region_cache_manager = rcm_script.new()
			region_cache_manager.name = "RegionCacheManager"
			add_child(region_cache_manager)
			print("[InfiniteWorldManager] 💾 RegionCacheManager cargado")

func _load_biome_region_applier() -> void:
	"""Cargar el aplicador de texturas para regiones orgánicas"""
	if ResourceLoader.exists("res://scripts/core/BiomeRegionApplier.gd"):
		var bra_script = load("res://scripts/core/BiomeRegionApplier.gd")
		if bra_script:
			biome_region_applier = bra_script.new()
			biome_region_applier.name = "BiomeRegionApplier"
			add_child(biome_region_applier)
			print("[InfiniteWorldManager] 🎨 BiomeRegionApplier cargado")

func _load_organic_texture_blender() -> void:
	"""Cargar el sistema de blending entre biomas"""
	if ResourceLoader.exists("res://scripts/core/OrganicTextureBlender.gd"):
		var otb_script = load("res://scripts/core/OrganicTextureBlender.gd")
		if otb_script:
			organic_texture_blender = otb_script.new()
			organic_texture_blender.name = "OrganicTextureBlender"
			add_child(organic_texture_blender)
			# Inicializar con la semilla del mundo
			organic_texture_blender.initialize(world_seed)
			print("[InfiniteWorldManager] 🌈 OrganicTextureBlender cargado e inicializado")

func initialize(player: Node) -> void:
	"""Inicializar sistema de regiones orgánicas con referencia al jugador"""
	player_ref = player

	# Inicializar posición virtual del jugador en el centro del mundo
	player_virtual_position = Vector2.ZERO
	world_offset = Vector2.ZERO

	# Determinar región inicial del jugador
	current_region_id = _world_pos_to_region_id(player_virtual_position)

	# Generar regiones iniciales alrededor del jugador
	_update_regions_around_player()

	print("[InfiniteWorldManager] 🎮 Sistema de regiones orgánicas inicializado (región inicial: %s)" % current_region_id)

func set_regions_root(root: Node2D) -> void:
	"""Establecer la referencia al nodo raíz de regiones"""
	regions_root = root
	print("[InfiniteWorldManager] 📁 regions_root establecido: %s" % regions_root.name)

# Método de compatibilidad para no romper código existente
func set_chunks_root(root: Node2D) -> void:
	"""Método de compatibilidad - redirige a set_regions_root"""
	chunks_root = root
	set_regions_root(root)

func _process(_delta: float) -> void:
	"""Verificar si el jugador ha cambiado de región y gestionar carga/descarga"""
	if not player_ref or not is_instance_valid(player_ref):
		return

	# Usar posición virtual del jugador (el mundo se mueve, jugador permanece en 0,0)
	var new_region_id = _world_pos_to_region_id(player_virtual_position)

	# Si el jugador cambió de región, actualizar regiones activas
	if new_region_id != current_region_id:
		current_region_id = new_region_id
		_update_regions_around_player()

		if debug_mode:
			print("[InfiniteWorldManager] � Jugador movió a región: %s (pos virtual: %s)" % [new_region_id, player_virtual_position])

	# Procesar cola de generación de regiones (máx por frame)
	await _process_region_loading_queue()

func _world_pos_to_region_id(world_pos: Vector2) -> Vector2i:
	"""Convertir posición mundial a ID de región"""
	if not organic_shape_generator:
		# Fallback usando tamaño base de región
		var rx = int(floor(world_pos.x / base_region_size))
		var ry = int(floor(world_pos.y / base_region_size))
		return Vector2i(rx, ry)

	return organic_shape_generator.get_region_at_position(world_pos)

func _region_id_to_world_pos(region_id: Vector2i) -> Vector2:
	"""Convertir ID de región a posición central aproximada"""
	# Estimación basada en grid regular (se refinará con la región real)
	return Vector2(region_id.x * base_region_size, region_id.y * base_region_size)

func _update_regions_around_player() -> void:
	"""Actualizar regiones orgánicas: generar nuevas, descargar lejanas"""
	if is_generating_regions:
		if debug_mode:
			print("[InfiniteWorldManager] ⏸️ Generación de regiones en progreso...")
		return

	# Determinar regiones necesarias dentro del radio de visibilidad
	var regions_to_keep: Array[Vector2i] = []
	var regions_to_generate: Array[Vector2i] = []

	# Buscar regiones en área circular alrededor del jugador
	var search_radius = int(ceil(visibility_radius / base_region_size)) + 1

	for dx in range(-search_radius, search_radius + 1):
		for dy in range(-search_radius, search_radius + 1):
			var region_id = current_region_id + Vector2i(dx, dy)
			var region_center = _region_id_to_world_pos(region_id)
			var distance = player_virtual_position.distance_to(region_center)

			# Mantener regiones dentro del radio de visibilidad
			if distance <= visibility_radius:
				regions_to_keep.append(region_id)

				# Marcar para generación si no existe
				if not active_regions.has(region_id):
					regions_to_generate.append(region_id)

	# Agregar regiones a la cola de generación
	for region_id in regions_to_generate:
		if not region_loading_queue.has(region_id):
			region_loading_queue.append(region_id)

	# Descargar regiones fuera del radio
	_unload_distant_regions(regions_to_keep)

	if debug_mode and (regions_to_generate.size() > 0 or regions_to_keep.size() != active_regions.size()):
		print("[InfiniteWorldManager] 🔄 Regiones activas: %d | Cola: %d | Mantener: %d" % [
			active_regions.size(), region_loading_queue.size(), regions_to_keep.size()
		])

func _process_region_loading_queue() -> void:
	"""Procesar cola de carga de regiones (limitado por frame budget)"""
	if region_loading_queue.is_empty() or is_generating_regions:
		return

	is_generating_regions = true
	var regions_processed = 0

	while not region_loading_queue.is_empty() and regions_processed < generation_frame_budget:
		var region_id = region_loading_queue.pop_front()
		await _generate_or_load_region(region_id)
		regions_processed += 1

		# Ceder control al motor entre regiones
		await get_tree().process_frame

	is_generating_regions = false

func _generate_or_load_region(region_id: Vector2i) -> void:
	"""Generar una región nueva o cargarla del caché"""
	if active_regions.has(region_id):
		return

	# Intentar cargar del caché primero
	if region_cache_manager and region_cache_manager.has_cached_chunk(region_id):
		var region_data = region_cache_manager.load_chunk(region_id)
		var region_node = _instantiate_region_from_cache(region_id, region_data)
		if region_node:
			active_regions[region_id] = region_node
			region_loaded_from_cache.emit(region_id)
			performance_stats["regions_cached"] += 1

			if debug_mode:
				print("[InfiniteWorldManager] 📂 Región %s cargada del caché" % region_id)
			return

	# Generar región completamente nueva
	await _generate_new_region(region_id)

func _generate_new_region(region_id: Vector2i) -> void:
	"""Generar una región orgánica completamente nueva"""
	var region_center = _region_id_to_world_pos(region_id)
	var generation_start_time = Time.get_ticks_msec()

	print("[InfiniteWorldManager] 🔥 Generando región orgánica: %s en centro %s" % [region_id, region_center])

	# 1. Generar forma orgánica con OrganicShapeGenerator
	if not organic_shape_generator:
		print("[InfiniteWorldManager] ❌ OrganicShapeGenerator no disponible")
		return

	var organic_region = await organic_shape_generator.generate_region_async(region_id)
	if not organic_region:
		print("[InfiniteWorldManager] ❌ Error generando región orgánica")
		return

	# 2. Generar contenido con BiomeGenerator
	var region_data = {}
	if biome_generator:
		region_data = await biome_generator.generate_region_async(organic_region)
	else:
		print("[InfiniteWorldManager] ⚠️ BiomeGenerator no disponible")
		# Datos mínimos por defecto
		region_data = {
			"region_id": region_id,
			"biome_type": 0, # BiomeGenerator.BiomeType.GRASSLAND
			"center_position": region_center,
			"boundary_points": organic_region.boundary_points if organic_region else PackedVector2Array()
		}

	# 3. Crear nodo visual de región
	var region_node = Node2D.new()
	region_node.name = "Region_%d_%d" % [region_id.x, region_id.y]
	region_node.position = Vector2.ZERO # Las regiones usan coordenadas absolutas

	# Agregar al contenedor de regiones
	if regions_root and is_instance_valid(regions_root):
		regions_root.add_child(region_node)
	else:
		add_child(region_node)
		print("[InfiniteWorldManager] ⚠️ regions_root no disponible, agregando región a self")

	# 4. Aplicar texturas con BiomeRegionApplier
	if biome_region_applier:
		await biome_region_applier.apply_biome_to_region(region_node, region_data)
	else:
		print("[InfiniteWorldManager] ⚠️ BiomeRegionApplier no disponible")

	# 5. Aplicar blending orgánico entre regiones vecinas
	if organic_texture_blender and active_regions.size() > 0:
		# Obtener regiones vecinas para blending
		var neighbor_regions = _get_neighbor_regions_data(region_id)
		if neighbor_regions.size() > 0:
			await biome_region_applier.apply_blended_region(region_node, region_data, neighbor_regions)

	# Guardar metadatos en el nodo
	region_node.set_meta("region_id", region_id)
	region_node.set_meta("biome_type", region_data.get("biome_type", 0))
	region_node.set_meta("organic_region", organic_region)
	region_node.set_meta("region_data", region_data)

	# Guardar en caché para futuras cargas
	if region_cache_manager:
		var cache_data = _extract_region_data(region_node, organic_region)
		region_cache_manager.save_chunk(region_id, cache_data)

	# Registrar región como activa
	active_regions[region_id] = region_node
	region_generated.emit(region_id)
	performance_stats["regions_generated"] += 1

	var generation_time = Time.get_ticks_msec() - generation_start_time
	if debug_mode:
		print("[InfiniteWorldManager] ✨ Región %s generada - Bioma: %s | Tiempo: %dms" % [
			region_id,
			BiomeGenerator.BIOME_NAMES.get(region_data.get("biome_type", 0), "grassland"),
			generation_time
		])

func _get_neighbor_regions_data(region_id: Vector2i) -> Array:
	"""Obtener datos de regiones vecinas para blending"""
	var neighbors = []

	# Buscar en 8 direcciones adyacentes
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue

			var neighbor_id = region_id + Vector2i(dx, dy)
			if active_regions.has(neighbor_id):
				var neighbor_node = active_regions[neighbor_id]
				var neighbor_data = neighbor_node.get_meta("region_data", {})
				if not neighbor_data.is_empty():
					neighbors.append(neighbor_data)

	return neighbors

func _instantiate_chunk_from_cache(chunk_pos: Vector2i, chunk_data: Dictionary) -> Node2D:
	"""Recrear un chunk desde datos en caché"""
	var chunk_node = Node2D.new()
	chunk_node.name = "Chunk_%d_%d" % [chunk_pos.x, chunk_pos.y]
	chunk_node.global_position = _region_id_to_world_pos(chunk_pos)

	# IMPORTANT: Add to chunks_root, not to self
	if chunks_root and is_instance_valid(chunks_root):
		chunks_root.add_child(chunk_node)
	else:
		add_child(chunk_node)
		print("[InfiniteWorldManager] ⚠️  chunks_root not available, adding chunk to self")

	# Recrear bioma y decoraciones desde caché (sin await necesario aquí)
	if biome_generator and chunk_data.has("region_data"):
		# Comentar por ahora hasta que se implemente
		# biome_generator.generate_chunk_from_cache(chunk_node, chunk_data)
		pass

	# Aplicar texturas desde caché
	if biome_region_applier and chunk_data.has("region_data"):
		biome_region_applier.apply_biome_to_region(chunk_node, chunk_data.get("region_data", {}))

	return chunk_node

func _extract_chunk_data(chunk_node: Node2D, chunk_pos: Vector2i) -> Dictionary:
	"""Extraer datos del chunk para guardar en caché"""
	return {
		"position": chunk_pos,
		"biome": chunk_node.get_meta("biome_type") if chunk_node.has_meta("biome_type") else "grassland",
		"decorations": [],
		"items": [],
		"timestamp": Time.get_ticks_msec()
	}

func _unload_chunk(chunk_pos: Vector2i) -> void:
	"""Descargar un chunk y limpiarlo de memoria"""
	if active_chunks.has(chunk_pos):
		var chunk_node = active_chunks[chunk_pos]
		chunk_node.queue_free()
		active_chunks.erase(chunk_pos)

		if debug_mode:
			print("[InfiniteWorldManager] 🗑️ Chunk %s descargado" % chunk_pos)

# ========== MÉTODOS DE COMPATIBILIDAD (LEGACY) ==========

func get_chunk_at_pos(world_pos: Vector2) -> Node2D:
	"""Método de compatibilidad - redirige a get_region_at_position"""
	return get_region_at_position(world_pos)

func get_active_chunks() -> Array:
	"""Método de compatibilidad - redirige a get_active_regions"""
	return get_active_regions()

func force_chunk_update() -> void:
	"""Método de compatibilidad - redirige a force_region_update"""
	force_region_update()

func toggle_debug_visualization() -> void:
	"""Alternar visualización de límites de regiones orgánicas"""
	show_region_boundaries = not show_region_boundaries
	print("[InfiniteWorldManager] Debug visualization: %s" % show_region_boundaries)

func _unload_distant_regions(regions_to_keep: Array[Vector2i]) -> void:
	"""Descargar regiones que están fuera del radio de descarga"""
	var regions_to_remove: Array[Vector2i] = []

	for region_id in active_regions.keys():
		if not regions_to_keep.has(region_id):
			var region_center = _region_id_to_world_pos(region_id)
			var distance = player_virtual_position.distance_to(region_center)

			# Solo descargar si está realmente lejos
			if distance > unload_radius:
				regions_to_remove.append(region_id)

	# Descargar regiones marcadas
	for region_id in regions_to_remove:
		_unload_region(region_id)

func _unload_region(region_id: Vector2i) -> void:
	"""Descargar una región específica"""
	if not active_regions.has(region_id):
		return

	var region_node = active_regions[region_id]

	# Extraer datos para caché antes de destruir
	if region_cache_manager and region_node.has_meta("organic_region"):
		var organic_region = region_node.get_meta("organic_region")
		var region_data = _extract_region_data(region_node, organic_region)
		region_cache_manager.save_chunk(region_id, region_data)

	# Remover del mundo
	if is_instance_valid(region_node):
		region_node.queue_free()

	active_regions.erase(region_id)

	if debug_mode:
		print("[InfiniteWorldManager] 🗑️ Región %s descargada" % region_id)

func _extract_region_data(_region_node: Node2D, organic_region) -> Dictionary:
	"""Extraer datos de región para guardar en caché"""
	return {
		"region_id": organic_region.region_id,
		"center_position": organic_region.center_position,
		"boundary_points": organic_region.boundary_points,
		"biome_id": organic_region.biome_id,
		"area": organic_region.area,
		"noise_seed": organic_region.noise_seed,
		"neighbor_regions": organic_region.neighbor_regions,
		"timestamp": Time.get_unix_time_from_system()
	}

func _instantiate_region_from_cache(region_id: Vector2i, region_data: Dictionary) -> Node2D:
	"""Recrear región desde datos de caché"""
	if not organic_shape_generator:
		return null

	# Recrear OrganicRegion desde caché usando el generador
	var OrganicRegionClass = load("res://scripts/core/OrganicShapeGenerator.gd").OrganicRegion
	var organic_region = OrganicRegionClass.new(
		region_id,
		region_data.get("center_position", Vector2.ZERO),
		region_data.get("biome_id", "grassland")
	)

	organic_region.boundary_points = region_data.get("boundary_points", PackedVector2Array())
	organic_region.area = region_data.get("area", 0.0)
	organic_region.noise_seed = region_data.get("noise_seed", 0)
	organic_region.neighbor_regions = region_data.get("neighbor_regions", [])

	# Crear nodo contenedor
	var region_node = Node2D.new()
	region_node.name = "Region_%d_%d_Cache" % [region_id.x, region_id.y]
	region_node.position = organic_region.center_position

	# Agregar al mundo
	if regions_root and is_instance_valid(regions_root):
		regions_root.add_child(region_node)
	else:
		add_child(region_node)

	# Regenerar contenido desde caché
	if biome_generator:
		# Comentar por ahora hasta que se implemente
		# biome_generator.generate_region_from_cache(region_node, region_data)
		pass

	# Guardar metadatos
	region_node.set_meta("region_id", region_id)
	region_node.set_meta("biome_id", organic_region.biome_id)
	region_node.set_meta("organic_region", organic_region)

	return region_node

# ========== SISTEMA DE MOVIMIENTO DEL MUNDO ==========
func move_world(direction: Vector2, delta: float) -> void:
	"""Mover el mundo orgánico manteniendo al jugador fijo en el centro"""
	if not regions_root:
		return

	# Velocidad de movimiento (misma que sistema anterior)
	var movement_speed = 300.0 # píxeles/segundo
	var movement = direction * movement_speed * delta

	# Mover el contenedor de regiones en dirección opuesta al movimiento del jugador
	if is_instance_valid(regions_root):
		regions_root.position -= movement

	# Actualizar posición virtual del jugador (se mueve en la dirección del input)
	world_offset += movement
	player_virtual_position += movement

	# Debug logging (cada 60 frames)
	if debug_mode:
		if not has_meta("frame_count"):
			set_meta("frame_count", 0)
		var frame_count = get_meta("frame_count") + 1
		if frame_count % 60 == 0:
			print("[InfiniteWorldManager] 🔄 Virtual pos: %s | World offset: %s | Dir: %s" % [
				player_virtual_position, world_offset, direction
			])
		set_meta("frame_count", frame_count)

# ========== MÉTODOS DE INFORMACIÓN Y DEBUG ==========
func get_region_at_position(world_pos: Vector2) -> Node2D:
	"""Obtener región en una posición específica"""
	var region_id = _world_pos_to_region_id(world_pos)
	return active_regions.get(region_id, null)

func get_active_regions() -> Array:
	"""Obtener lista de regiones activas"""
	return active_regions.values()

func force_region_update() -> void:
	"""Forzar actualización de regiones (útil para debug)"""
	current_region_id = _world_pos_to_region_id(player_virtual_position)
	_update_regions_around_player()

func _draw() -> void:
	"""Dibujar contornos de regiones orgánicas en modo debug"""
	if not show_region_boundaries or not debug_mode:
		return

	# Dibujar contornos de regiones activas
	for region_node in active_regions.values():
		if not is_instance_valid(region_node) or not region_node.has_meta("organic_region"):
			continue

		var organic_region = region_node.get_meta("organic_region")
		if organic_region.boundary_points.size() < 3:
			continue

		# Dibujar contorno orgánico
		var points = organic_region.boundary_points
		for i in range(points.size()):
			var p1 = points[i]
			var p2 = points[(i + 1) % points.size()]
			draw_line(p1 - global_position, p2 - global_position, Color.CYAN, 2.0)

		# Dibujar centro de región
		var center = organic_region.center_position - global_position
		draw_circle(center, 10.0, Color.YELLOW)

func get_info() -> Dictionary:
	"""Obtener información de debug del sistema orgánico"""
	return {
		"current_region": current_region_id,
		"active_regions": active_regions.size(),
		"loading_queue": region_loading_queue.size(),
		"base_region_size": base_region_size,
		"world_seed": world_seed,
		"player_virtual_position": player_virtual_position,
		"world_offset": world_offset,
		"player_real_position": player_ref.global_position if player_ref else Vector2.ZERO,
		"performance_stats": performance_stats
	}

# ========== FUNCIONES DE CONVERSIÓN DE COORDENADAS ==========

# Función _world_pos_to_region_id ya definida arriba - eliminada duplicado

# Función _region_id_to_world_pos ya definida arriba - eliminada duplicado

# Función _extract_region_data ya definida arriba - eliminada duplicado

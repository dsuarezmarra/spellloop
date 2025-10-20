# InfiniteWorldManager.gd
# Sistema profesional de generación dinámica de chunks infinitos
# - Chunks de 5760×3240 px (3×3 pantallas)
# - 9 chunks simultáneos máximo (3×3 cuadrícula)
# - Caché persistente de estado
# - Biomas decorativos con transiciones suaves
# - Generación asíncrona sin lag

extends Node2D
class_name InfiniteWorldManager

signal chunk_generated(chunk_pos: Vector2i)
signal chunk_loaded_from_cache(chunk_pos: Vector2i)

# Dimensiones del chunk
@export var chunk_width: int = 5760
@export var chunk_height: int = 3240
var chunk_size: Vector2 = Vector2(5760, 3240)

# Límite de chunks activos (siempre 3×3)
const ACTIVE_CHUNK_GRID: Vector2i = Vector2i(3, 3)
const MAX_ACTIVE_CHUNKS: int = 9

# Control de chunks
var active_chunks: Dictionary = {}  # Key: Vector2i (cx, cy), Value: Node (chunk root)
var current_chunk_index: Vector2i = Vector2i(0, 0)
var player_ref: Node = null

# Generación y renderizado
var biome_generator: Node = null
var chunk_cache_manager: Node = null
var is_generating: bool = false

# Semilla para reproducibilidad
var world_seed: int = 12345
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Debug
var debug_mode: bool = true
var show_chunk_bounds: bool = false

func _ready() -> void:
	"""Inicializar el gestor de mundo infinito"""
	print("[InfiniteWorldManager] Inicializando...")
	
	# Inicializar RNG con semilla
	rng.seed = world_seed
	
	# Cargar componentes
	_load_biome_generator()
	_load_chunk_cache_manager()
	
	# Configurar para procesamiento
	set_process(true)
	
	print("[InfiniteWorldManager] ✅ Inicializado (chunk_size: %s)" % chunk_size)

func _load_biome_generator() -> void:
	"""Cargar el generador de biomas"""
	if ResourceLoader.exists("res://scripts/core/BiomeGenerator.gd"):
		var bg_script = load("res://scripts/core/BiomeGenerator.gd")
		if bg_script:
			biome_generator = bg_script.new()
			biome_generator.name = "BiomeGenerator"
			add_child(biome_generator)
			print("[InfiniteWorldManager] BiomeGenerator cargado")

func _load_chunk_cache_manager() -> void:
	"""Cargar el gestor de caché de chunks"""
	if ResourceLoader.exists("res://scripts/core/ChunkCacheManager.gd"):
		var ccm_script = load("res://scripts/core/ChunkCacheManager.gd")
		if ccm_script:
			chunk_cache_manager = ccm_script.new()
			chunk_cache_manager.name = "ChunkCacheManager"
			add_child(chunk_cache_manager)
			print("[InfiniteWorldManager] ChunkCacheManager cargado")

func initialize(player: Node) -> void:
	"""Inicializar con referencia al jugador"""
	player_ref = player
	
	# Generar chunk inicial
	_update_chunks_around_player()
	print("[InfiniteWorldManager] 🎮 Sistema de chunks inicializado")

func _process(_delta: float) -> void:
	"""Verificar si el jugador ha cambiado de chunk cada frame"""
	if not player_ref or not is_instance_valid(player_ref):
		return
	
	var new_chunk = _world_pos_to_chunk_index(player_ref.global_position)
	
	if new_chunk != current_chunk_index:
		current_chunk_index = new_chunk
		_update_chunks_around_player()

func _world_pos_to_chunk_index(world_pos: Vector2) -> Vector2i:
	"""Convertir posición mundial a índice de chunk (cx, cy)"""
	var cx = int(floor(world_pos.x / chunk_width))
	var cy = int(floor(world_pos.y / chunk_height))
	return Vector2i(cx, cy)

func _chunk_index_to_world_pos(cx: int, cy: int) -> Vector2:
	"""Convertir índice de chunk a posición mundial (esquina superior izquierda)"""
	return Vector2(cx * chunk_width, cy * chunk_height)

func _update_chunks_around_player() -> void:
	"""Actualizar chunks: generar nuevos, destruir lejanos, mantener 3×3 activos"""
	if is_generating:
		return
	
	# Calcular rango de chunks a mantener activos (3×3 centrado)
	var half_grid = ACTIVE_CHUNK_GRID / 2
	var min_chunk = current_chunk_index - half_grid
	var max_chunk = current_chunk_index + half_grid
	
	var chunks_to_keep: Array[Vector2i] = []
	
	# Generar/cargar chunks necesarios
	for cy in range(min_chunk.y, max_chunk.y + 1):
		for cx in range(min_chunk.x, max_chunk.x + 1):
			var chunk_pos = Vector2i(cx, cy)
			chunks_to_keep.append(chunk_pos)
			
			if not active_chunks.has(chunk_pos):
				# Generar o cargar del caché
				_generate_or_load_chunk(chunk_pos)
	
	# Destruir chunks fuera de rango
	var chunks_to_remove: Array[Vector2i] = []
	for chunk_pos in active_chunks.keys():
		if not chunks_to_keep.has(chunk_pos):
			chunks_to_remove.append(chunk_pos)
	
	for chunk_pos in chunks_to_remove:
		_unload_chunk(chunk_pos)
	
	if debug_mode:
		print("[InfiniteWorldManager] 🔄 Chunks activos: %d (central: %s)" % [active_chunks.size(), current_chunk_index])

func _generate_or_load_chunk(chunk_pos: Vector2i) -> void:
	"""Generar un chunk nuevo o cargarlo del caché de forma asíncrona"""
	if active_chunks.has(chunk_pos):
		return
	
	is_generating = true
	
	# Intentar cargar del caché
	if chunk_cache_manager and chunk_cache_manager.has_cached_chunk(chunk_pos):
		var chunk_data = chunk_cache_manager.load_chunk(chunk_pos)
		var chunk_node = _instantiate_chunk_from_cache(chunk_pos, chunk_data)
		active_chunks[chunk_pos] = chunk_node
		chunk_loaded_from_cache.emit(chunk_pos)
		print("[InfiniteWorldManager] 📂 Chunk %s cargado del caché" % chunk_pos)
		is_generating = false
		return
	
	# Generar nuevo
	await get_tree().process_frame  # Diferir para no bloquear
	_generate_new_chunk(chunk_pos)
	is_generating = false

func _generate_new_chunk(chunk_pos: Vector2i) -> void:
	"""Generar un chunk completamente nuevo"""
	# Usar semilla combinada para reproducibilidad
	var chunk_seed = world_seed ^ chunk_pos.x ^ (chunk_pos.y << 16)
	rng.seed = chunk_seed
	
	# Crear nodo raíz del chunk
	var chunk_node = Node2D.new()
	chunk_node.name = "Chunk_%d_%d" % [chunk_pos.x, chunk_pos.y]
	chunk_node.global_position = _chunk_index_to_world_pos(chunk_pos.x, chunk_pos.y)
	add_child(chunk_node)
	
	# Generar bioma y decoraciones
	if biome_generator:
		await biome_generator.generate_chunk_async(chunk_node, chunk_pos, rng)
	
	# Guardar en caché
	if chunk_cache_manager:
		var chunk_data = _extract_chunk_data(chunk_node, chunk_pos)
		chunk_cache_manager.save_chunk(chunk_pos, chunk_data)
	
	active_chunks[chunk_pos] = chunk_node
	chunk_generated.emit(chunk_pos)
	
	if debug_mode:
		print("[InfiniteWorldManager] ✨ Chunk %s generado" % chunk_pos)

func _instantiate_chunk_from_cache(chunk_pos: Vector2i, chunk_data: Dictionary) -> Node2D:
	"""Recrear un chunk desde datos en caché"""
	var chunk_node = Node2D.new()
	chunk_node.name = "Chunk_%d_%d" % [chunk_pos.x, chunk_pos.y]
	chunk_node.global_position = _chunk_index_to_world_pos(chunk_pos.x, chunk_pos.y)
	add_child(chunk_node)
	
	# Recrear bioma y decoraciones desde caché (sin await necesario aquí)
	if biome_generator:
		biome_generator.generate_chunk_from_cache(chunk_node, chunk_data)
	
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

func get_chunk_at_pos(world_pos: Vector2) -> Node2D:
	"""Obtener el nodo del chunk en una posición mundial"""
	var chunk_pos = _world_pos_to_chunk_index(world_pos)
	return active_chunks.get(chunk_pos, null)

func get_active_chunks() -> Array:
	"""Obtener lista de chunks activos"""
	return active_chunks.values()

func toggle_debug_visualization() -> void:
	"""Alternar visualización de límites de chunks"""
	show_chunk_bounds = not show_chunk_bounds
	print("[InfiniteWorldManager] Debug visualization: %s" % show_chunk_bounds)

func _draw() -> void:
	"""Dibujar límites de chunks en modo debug"""
	if not show_chunk_bounds or not debug_mode:
		return
	
	var half_grid = ACTIVE_CHUNK_GRID / 2
	var min_chunk = current_chunk_index - half_grid
	var max_chunk = current_chunk_index + half_grid
	
	for cy in range(min_chunk.y, max_chunk.y + 1):
		for cx in range(min_chunk.x, max_chunk.x + 1):
			var pos = _chunk_index_to_world_pos(cx, cy)
			var rect = Rect2(pos, chunk_size)
			draw_rect(rect, Color.YELLOW, false, 2.0)

func get_info() -> Dictionary:
	"""Obtener información de debug"""
	return {
		"current_chunk": current_chunk_index,
		"active_chunks": active_chunks.size(),
		"chunk_size": chunk_size,
		"world_seed": world_seed
	}

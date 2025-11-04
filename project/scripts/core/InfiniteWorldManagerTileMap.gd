extends Node2D
class_name InfiniteWorldManagerTileMap

"""
🌍 GESTOR DE MUNDO INFINITO CON TILEMAP
========================================

Reemplazo del sistema antiguo de chunks grandes.
Usa TileMap + BiomeTileMapGenerator + BiomeDecoratorsManager.

CARACTERÍSTICAS:
- Chunks de 32×32 tiles (2048×2048 pixels @ 64px/tile)
- Transiciones automáticas entre biomas
- Decoradores con fade en bordes
- Compatible con sistema de movimiento del jugador existente
"""

signal chunk_generated(chunk_pos: Vector2i)
signal chunk_removed(chunk_pos: Vector2i)

# Referencias
@export var tilemap_generator: BiomeTileMapGenerator
@export var decorators_manager: BiomeDecoratorsManager
@export var player_ref: Node2D

# Configuración
const ACTIVE_CHUNK_GRID: Vector2i = Vector2i(3, 3)  # 3×3 = 9 chunks
const MAX_ACTIVE_CHUNKS: int = 9

# Estado
var current_chunk_index: Vector2i = Vector2i(0, 0)
var player_virtual_position: Vector2 = Vector2.ZERO
var world_offset: Vector2 = Vector2.ZERO

# Debug
var debug_mode: bool = true
var frame_count: int = 0

func _ready():
	print("[InfiniteWorldManagerTileMap] Inicializando...")
	
	if not tilemap_generator:
		printerr("✗ BiomeTileMapGenerator no asignado")
		return
	
	if not decorators_manager:
		printerr("✗ BiomeDecoratorsManager no asignado")
		return
	
	# Conectar señales
	tilemap_generator.chunk_generated.connect(_on_chunk_generated)
	tilemap_generator.chunk_removed.connect(_on_chunk_removed)
	
	set_process(true)
	
	print("[InfiniteWorldManagerTileMap] ✅ Inicializado")

func initialize(player: Node2D):
	"""Inicializar con referencia al jugador"""
	player_ref = player
	player_virtual_position = Vector2.ZERO
	world_offset = Vector2.ZERO
	
	# Generar chunks iniciales
	_update_chunks_around_player()
	
	print("[InfiniteWorldManagerTileMap] 🎮 Inicializado con jugador (pos: %s)" % player_virtual_position)

func _process(_delta: float):
	"""Actualizar chunks según posición del jugador"""
	if not player_ref or not is_instance_valid(player_ref):
		return
	
	# Verificar si cambió de chunk
	var new_chunk = _world_pos_to_chunk_index(player_virtual_position)
	
	if new_chunk != current_chunk_index:
		current_chunk_index = new_chunk
		
		if debug_mode:
			print("[TileMapManager] 📍 Cambio a chunk %s (pos virtual: %s)" % [new_chunk, player_virtual_position])
		
		_update_chunks_around_player()

func _world_pos_to_chunk_index(world_pos: Vector2) -> Vector2i:
	"""Convertir posición mundial a índice de chunk"""
	var chunk_size_px = tilemap_generator.chunk_size * 64  # tiles × pixels_per_tile
	var cx = int(floor(world_pos.x / chunk_size_px))
	var cy = int(floor(world_pos.y / chunk_size_px))
	return Vector2i(cx, cy)

func _update_chunks_around_player():
	"""Actualizar chunks: generar necesarios, eliminar lejanos"""
	
	# Calcular rango 3×3 centrado en jugador
	var half_grid = ACTIVE_CHUNK_GRID / 2
	var min_chunk = current_chunk_index - half_grid
	var max_chunk = current_chunk_index + half_grid
	
	var chunks_to_keep: Array[Vector2i] = []
	var chunks_to_generate: Array[Vector2i] = []
	
	# Identificar chunks necesarios
	for cy in range(min_chunk.y, max_chunk.y + 1):
		for cx in range(min_chunk.x, max_chunk.x + 1):
			var chunk_pos = Vector2i(cx, cy)
			chunks_to_keep.append(chunk_pos)
			
			if not tilemap_generator.active_chunks.has(chunk_pos):
				chunks_to_generate.append(chunk_pos)
	
	# Generar chunks nuevos
	for chunk_pos in chunks_to_generate:
		tilemap_generator.generate_chunk(chunk_pos)
	
	# Eliminar chunks lejanos
	var chunks_to_remove: Array[Vector2i] = []
	for chunk_pos in tilemap_generator.active_chunks.keys():
		if not chunks_to_keep.has(chunk_pos):
			chunks_to_remove.append(chunk_pos)
	
	for chunk_pos in chunks_to_remove:
		tilemap_generator.remove_chunk(chunk_pos)
	
	if debug_mode and chunks_to_generate.size() > 0:
		print("[TileMapManager] 🔄 Chunks activos: %d | Generados: %s" % [
			tilemap_generator.get_active_chunk_count(),
			chunks_to_generate
		])

func _on_chunk_generated(chunk_pos: Vector2i):
	"""Callback cuando se genera un chunk"""
	chunk_generated.emit(chunk_pos)
	
	if debug_mode:
		print("[TileMapManager] ✨ Chunk generado: %s" % chunk_pos)

func _on_chunk_removed(chunk_pos: Vector2i):
	"""Callback cuando se elimina un chunk"""
	chunk_removed.emit(chunk_pos)
	
	if debug_mode:
		print("[TileMapManager] 🗑️ Chunk eliminado: %s" % chunk_pos)

func move_world(direction: Vector2, delta: float):
	"""
	Mover el mundo en respuesta al movimiento del jugador.
	
	IMPORTANTE: En el sistema TileMap, NO movemos físicamente el TileMap.
	Solo actualizamos la posición virtual del jugador para tracking de chunks.
	"""
	var movement_speed = 300.0  # píxeles/segundo
	var movement = direction * movement_speed * delta
	
	# Actualizar posición virtual
	world_offset += movement
	player_virtual_position += movement
	
	# Log periódico
	frame_count += 1
	if debug_mode and frame_count % 60 == 0:
		print("[TileMapManager] 🔄 Virtual pos: %s | Decorators: %d" % [
			player_virtual_position,
			decorators_manager.get_decorator_count()
		])

func force_chunk_update():
	"""Forzar actualización de chunks (debug)"""
	print("[TileMapManager] 🔄 Forzando actualización...")
	print("  - Posición virtual: %s" % player_virtual_position)
	print("  - Chunk actual: %s" % current_chunk_index)
	print("  - Chunks activos: %d" % tilemap_generator.get_active_chunk_count())
	print("  - Decoradores: %d" % decorators_manager.get_decorator_count())
	_update_chunks_around_player()

func get_biome_at_position(world_pos: Vector2) -> int:
	"""Obtener bioma en posición mundial"""
	return tilemap_generator.get_biome_at_world_position(world_pos)

func regenerate_world(new_seed: int = -1):
	"""Regenerar mundo con nueva semilla"""
	tilemap_generator.regenerate_with_new_seed(new_seed)
	decorators_manager.clear_all_decorators()
	
	print("[TileMapManager] 🔄 Mundo regenerado")

func get_info() -> Dictionary:
	"""Información de debug"""
	return {
		"current_chunk": current_chunk_index,
		"active_chunks": tilemap_generator.get_active_chunk_count(),
		"decorators": decorators_manager.get_decorator_count(),
		"player_virtual_position": player_virtual_position,
		"world_offset": world_offset,
		"noise_seed": tilemap_generator.noise.seed if tilemap_generator.noise else 0
	}

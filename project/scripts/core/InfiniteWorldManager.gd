extends Node2D
class_name InfiniteWorldManager

"""
🌍 GESTOR DE MUNDO INFINITO - VAMPIRE SURVIVORS STYLE
===================================================

Genera chunks infinitos de terreno alrededor del player.
El player permanece fijo en el centro, el mundo se mueve.
"""

signal chunk_generated(chunk_pos: Vector2i)
signal chunk_removed(chunk_pos: Vector2i)
signal world_moved(movement_delta: Vector2)  # Nueva señal para objetos estáticos

# Configuración de chunks
const CHUNK_SIZE = 1024  # Tamaño de cada chunk en píxeles
const LOAD_RADIUS = 2    # Radio de chunks cargados (2 = 5x5 grid)
const UNLOAD_RADIUS = 3  # Radio para descargar chunks lejanos

# Referencias
var player: CharacterBody2D
var world_offset: Vector2 = Vector2.ZERO  # Offset del mundo vs player fijo

# Gestión de chunks
var loaded_chunks: Dictionary = {}  # Vector2i -> ChunkData
var chunk_pool: Array[Node2D] = []  # Pool de chunks reutilizables

# Texturas y recursos
var sand_texture: Texture2D
var chunk_scene: PackedScene

func _ready():
	print("🌍 InfiniteWorldManager inicializado")
	setup_resources()
	
func setup_resources():
	"""Configurar recursos necesarios"""
	# Cargar/crear textura de arena
	var sand_size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
	sand_texture = MagicWallTextures.create_sand_floor_texture(sand_size)
	
	print("✅ Recursos de mundo configurados")

func initialize_world(player_ref: CharacterBody2D):
	"""Inicializar el mundo con referencia al player"""
	player = player_ref
	world_offset = Vector2.ZERO
	
	# Generar chunks iniciales alrededor del player
	generate_initial_chunks()
	
	print("🎮 Mundo infinito inicializado")

func generate_initial_chunks():
	"""Generar chunks iniciales en un grid alrededor del player"""
	var player_chunk = world_to_chunk(Vector2.ZERO)
	
	for x in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for y in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			var chunk_pos = player_chunk + Vector2i(x, y)
			generate_chunk(chunk_pos)
	
	print("🏗️ Chunks iniciales generados: ", loaded_chunks.size())

func update_world(movement_delta: Vector2):
	"""Actualizar mundo basándose en el movimiento del player"""
	# Mover todo el mundo en dirección opuesta al movimiento
	world_offset += movement_delta
	
	# Emitir señal para objetos estáticos ANTES de aplicar el offset
	world_moved.emit(movement_delta)
	
	# Aplicar offset a todos los nodos del mundo
	apply_world_offset(-movement_delta)
	
	# Verificar si necesitamos generar/descargar chunks
	var player_chunk = world_to_chunk(Vector2.ZERO)
	update_chunks_around_player(player_chunk)

func apply_world_offset(offset: Vector2):
	"""Aplicar offset a todos los elementos del mundo"""
	# Mover todos los chunks cargados
	for chunk_data in loaded_chunks.values():
		if chunk_data.node:
			chunk_data.node.position += offset
	
	# Mover enemigos (se hará en EnemyManager)
	# Mover items y cofres (se hará en ItemManager)

func update_chunks_around_player(player_chunk: Vector2i):
	"""Actualizar chunks alrededor del player"""
	# Generar chunks necesarios
	for x in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for y in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			var chunk_pos = player_chunk + Vector2i(x, y)
			if not loaded_chunks.has(chunk_pos):
				generate_chunk(chunk_pos)
	
	# Descargar chunks lejanos
	var chunks_to_remove = []
	for chunk_pos in loaded_chunks.keys():
		var distance = (chunk_pos - player_chunk).length()
		if distance > UNLOAD_RADIUS:
			chunks_to_remove.append(chunk_pos)
	
	for chunk_pos in chunks_to_remove:
		unload_chunk(chunk_pos)

func generate_chunk(chunk_pos: Vector2i):
	"""Generar un chunk en la posición especificada"""
	if loaded_chunks.has(chunk_pos):
		return
	
	var chunk_data = ChunkData.new()
	chunk_data.position = chunk_pos
	chunk_data.world_position = chunk_to_world(chunk_pos)
	
	# Crear nodo visual del chunk
	var chunk_node = create_chunk_visual(chunk_data)
	add_child(chunk_node)
	
	chunk_data.node = chunk_node
	loaded_chunks[chunk_pos] = chunk_data
	
	# Generar contenido del chunk (enemigos, cofres, etc.)
	generate_chunk_content(chunk_data)
	
	chunk_generated.emit(chunk_pos)
	
	#print("🏗️ Chunk generado: ", chunk_pos)

func create_chunk_visual(chunk_data: ChunkData) -> Node2D:
	"""Crear el nodo visual de un chunk"""
	var chunk_node = Node2D.new()
	chunk_node.name = "Chunk_" + str(chunk_data.position.x) + "_" + str(chunk_data.position.y)
	chunk_node.position = chunk_data.world_position
	
	# Crear suelo de arena
	var floor_rect = TextureRect.new()
	floor_rect.texture = sand_texture
	floor_rect.size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
	floor_rect.stretch_mode = TextureRect.STRETCH_TILE
	
	chunk_node.add_child(floor_rect)
	
	return chunk_node

func generate_chunk_content(chunk_data: ChunkData):
	"""Generar contenido aleatorio en el chunk (cofres, decoraciones)"""
	# Por ahora solo marcamos que el chunk tiene contenido
	# Aquí se añadirán cofres aleatorios más adelante
	chunk_data.has_content = true

func unload_chunk(chunk_pos: Vector2i):
	"""Descargar un chunk"""
	if not loaded_chunks.has(chunk_pos):
		return
	
	var chunk_data = loaded_chunks[chunk_pos]
	
	# Remover nodo visual
	if chunk_data.node:
		chunk_data.node.queue_free()
	
	# Limpiar datos
	loaded_chunks.erase(chunk_pos)
	
	chunk_removed.emit(chunk_pos)
	
	#print("🗑️ Chunk descargado: ", chunk_pos)

func world_to_chunk(world_pos: Vector2) -> Vector2i:
	"""Convertir posición del mundo a coordenadas de chunk"""
	var adjusted_pos = world_pos + world_offset
	return Vector2i(
		int(floor(adjusted_pos.x / CHUNK_SIZE)),
		int(floor(adjusted_pos.y / CHUNK_SIZE))
	)

func chunk_to_world(chunk_pos: Vector2i) -> Vector2:
	"""Convertir coordenadas de chunk a posición del mundo"""
	return Vector2(
		chunk_pos.x * CHUNK_SIZE,
		chunk_pos.y * CHUNK_SIZE
	) - world_offset

func get_world_position(local_pos: Vector2) -> Vector2:
	"""Obtener posición real del mundo desde posición local"""
	return local_pos + world_offset

func get_loaded_chunks_count() -> int:
	"""Obtener número de chunks cargados"""
	return loaded_chunks.size()

func debug_info() -> String:
	"""Información de debug"""
	var player_chunk = world_to_chunk(Vector2.ZERO)
	return "InfiniteWorld: offset=%s chunks=%d player_chunk=%s" % [
		world_offset, loaded_chunks.size(), player_chunk
	]

# Clase interna para datos de chunk
class ChunkData:
	var position: Vector2i
	var world_position: Vector2
	var node: Node2D
	var has_content: bool = false
	var entities: Array = []  # Enemigos y objetos en este chunk

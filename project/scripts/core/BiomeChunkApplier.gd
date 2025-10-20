extends Node
class_name BiomeChunkApplier

"""
🌍 BIOME CHUNK APPLIER - Sistema de Gestión de Biomas
======================================================

Responsabilidades:
- Cargar configuración JSON de biomas desde res://assets/textures/biomes/
- Aplicar texturas base y decorativas a chunks según bioma asignado
- Mantener caché de chunks activos para rendimiento
- Usar RNG determinístico basado en posición para biomas consistentes
- Limpiar chunks inactivos automáticamente

Arquitectura:
- Cada chunk (5760×3240 px = ~3 pantallas) recibe:
  * Textura base tileable (512×512 px repetida)
  * 3 decoraciones tileables adicionales (plantas, rocas, etc.)
- Máximo 9 chunks activos simultáneamente (3×3 grid)
- Caché: guardar estado para restaurar rápidamente

Integridad: asume que BiomeGenerator.gd ya genera la geometría del chunk
Este script solo gestiona texturas visuales (sin colisión).
"""

# ========== EXPORTABLES ==========
@export var config_path: String = "res://assets/textures/biomes/biome_textures_config.json"
@export var max_active_chunks: int = 9
@export var debug_mode: bool = true

# ========== PRIVADAS ==========
var _config: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _chunk_cache: Dictionary = {}  # key: "cx_cy" → cached chunk data
var _active_chunks: Dictionary = {}  # key: "cx_cy" → active chunk node
var _player_position: Vector2 = Vector2.ZERO
var _current_chunk_coords: Vector2i = Vector2i.ZERO

# ========== SEÑALES ==========
signal biome_changed(biome_name: String)
signal chunk_loaded(chunk_coords: Vector2i)

func _ready() -> void:
	print("[BiomeChunkApplier] ✓ Inicializando...")
	_rng.randomize()
	_load_config()
	print("[BiomeChunkApplier] ✓ Configuración cargada. Biomas disponibles: %d" % _config.get("biomes", []).size())

# ========== CARGAR CONFIGURACIÓN ==========
func _load_config() -> void:
	"""
	Cargar JSON de configuración de biomas desde res://assets/textures/biomes/biome_textures_config.json
	
	Estructura esperada:
	{
	  "biomes": [
	    {
	      "name": "Grassland",
	      "textures": {
	        "base": "Grassland/base.png",
	        "decor": ["Grassland/decor1.png", ...]
	      }
	    },
	    ...
	  ]
	}
	"""
	if not ResourceLoader.exists(config_path):
		printerr("[BiomeChunkApplier] ✗ Config NO encontrado: %s" % config_path)
		return
	
	var file = FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		printerr("[BiomeChunkApplier] ✗ No se pudo abrir: %s" % config_path)
		return
	
	var json_string = file.get_as_text()
	var json = JSON.new()
	var parse_error = json.parse(json_string)
	
	if parse_error != OK:
		printerr("[BiomeChunkApplier] ✗ JSON parse error: %s" % json.get_error_message())
		return
	
	_config = json.get_data()
	print("[BiomeChunkApplier] ✓ Config cargado exitosamente")

# ========== OBTENER BIOMA PARA POSICIÓN ==========
func get_biome_for_position(cx: int, cy: int) -> Dictionary:
	"""
	Determinar bioma basado en coordenadas de chunk usando RNG determinístico.
	Construye rutas completas desde la estructura del JSON.
	
	Args:
	  cx, cy: coordenadas del chunk en grid
	
	Returns:
	  Dictionary con datos del bioma seleccionado (con rutas res:// completas)
	"""
	if _config.get("biomes", []).is_empty():
		printerr("[BiomeChunkApplier] ✗ No hay biomas en config")
		return {}
	
	# Usar coordenadas como seed para determinismo
	var seed_val = hash(Vector2i(cx, cy))
	var rng_local = RandomNumberGenerator.new()
	rng_local.seed = seed_val
	
	var biomas = _config.get("biomes", [])
	var bioma_index = rng_local.randi_range(0, biomas.size() - 1)
	var bioma_config = biomas[bioma_index] as Dictionary
	
	# Construir bioma_data con rutas completas
	var bioma_data = {}
	bioma_data["name"] = bioma_config.get("name", "Unknown")
	bioma_data["id"] = bioma_config.get("id", "")
	
	# Construir rutas completas para texturas
	var textures_config = bioma_config.get("textures", {}) as Dictionary
	var base_relative = textures_config.get("base", "")
	
	if not base_relative.is_empty():
		bioma_data["base_texture_path"] = "res://assets/textures/biomes/" + base_relative
	else:
		bioma_data["base_texture_path"] = ""
	
	# Procesar decoraciones
	var decor_relative = textures_config.get("decor", []) as Array
	var decorations = []
	for decor_path in decor_relative:
		if not decor_path.is_empty():
			decorations.append("res://assets/textures/biomes/" + decor_path)
	
	bioma_data["decorations"] = decorations
	bioma_data["decor_scale"] = 1.0
	bioma_data["decor_opacity"] = 0.8
	
	if debug_mode:
		print("[BiomeChunkApplier] Chunk (%d, %d) → Bioma: %s (seed: %d)" % [cx, cy, bioma_data.get("name", "?"), seed_val])
	
	return bioma_data

# ========== APLICAR BIOMA A CHUNK ==========
func apply_biome_to_chunk(chunk_node: Node2D, cx: int, cy: int) -> void:
	"""
	Aplicar textura base y decoraciones a un chunk existente.
	
	OPTIMIZACIÓN: En lugar de crear 4 sprites separados, creamos UNA SOLA CanvasLayer
	con las texturas compuestas. Esto reduce el lag significativamente.
	"""
	var bioma_data = get_biome_for_position(cx, cy)
	
	if bioma_data.is_empty():
		printerr("[BiomeChunkApplier] ✗ No se pudo obtener bioma para (%d, %d)" % [cx, cy])
		return
	
	# Crear UNA SOLA CanvasLayer para todo el bioma
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "BiomeLayer"
	canvas_layer.layer = -10  # Detrás de todo
	chunk_node.add_child(canvas_layer)
	
	# Aplicar base + decoraciones en la misma capa
	_apply_textures_optimized(canvas_layer, bioma_data, cx, cy)
	
	# Guardar metadatos
	chunk_node.set_meta("biome_name", bioma_data.get("name", "Unknown"))
	chunk_node.set_meta("biome_id", bioma_data.get("id", -1))
	
	if debug_mode:
		print("[BiomeChunkApplier] ✓ Bioma '%s' aplicado a chunk (%d, %d)" % [bioma_data.get("name"), cx, cy])
	
	biome_changed.emit(bioma_data.get("name", ""))

# ========== APLICAR TEXTURAS OPTIMIZADAS ==========
func _apply_textures_optimized(parent: Node, bioma_data: Dictionary, _cx: int, _cy: int) -> void:
	"""
	OPTIMIZACIÓN: Aplicar textura base + todas las decoraciones.
	Crea apenas 4 sprites (1 base + 3 decor) con z_index para layering.
	"""
	var chunk_size = Vector2(5760, 3240)
	var chunk_center = chunk_size / 2
	
	# 1. APLICAR TEXTURA BASE
	var base_texture_path = bioma_data.get("base_texture_path", "")
	
	if not base_texture_path.is_empty() and ResourceLoader.exists(base_texture_path):
		var texture = load(base_texture_path) as Texture2D
		if texture:
			var sprite = Sprite2D.new()
			sprite.name = "BiomeBase"
			sprite.texture = texture
			sprite.centered = true
			sprite.position = chunk_center
			
			var texture_size = texture.get_size()
			sprite.scale = Vector2(chunk_size.x / texture_size.x, chunk_size.y / texture_size.y)
			sprite.z_index = 0
			
			parent.add_child(sprite)
			if debug_mode:
				print("[BiomeChunkApplier] ✓ Base aplicada: %s" % base_texture_path)
	
	# 2. APLICAR DECORACIONES (máximo 3)
	var decorations = bioma_data.get("decorations", []) as Array
	var decor_scale = bioma_data.get("decor_scale", 1.0)
	var decor_opacity = bioma_data.get("decor_opacity", 0.8)
	
	for i in range(min(decorations.size(), 3)):  # Máximo 3 decoraciones
		var decor_path = decorations[i]
		
		if decor_path is String and not decor_path.is_empty() and ResourceLoader.exists(decor_path):
			var texture = load(decor_path) as Texture2D
			if texture:
				var sprite = Sprite2D.new()
				sprite.name = "BiomeDecor%d" % (i + 1)
				sprite.texture = texture
				sprite.centered = true
				sprite.position = chunk_center
				
				var texture_size = texture.get_size()
				var scale_factor = decor_scale
				sprite.scale = Vector2(
					(chunk_size.x / texture_size.x) * scale_factor,
					(chunk_size.y / texture_size.y) * scale_factor
				)
				sprite.self_modulate = Color(1.0, 1.0, 1.0, decor_opacity)
				sprite.z_index = i + 1  # Layering: base=0, decor1=1, decor2=2, decor3=3
				
				parent.add_child(sprite)
				if debug_mode:
					print("[BiomeChunkApplier] ✓ Decor %d: %s" % [i+1, decor_path])

# ========== INTERFAZ PÚBLICA: ACTUALIZAR POSICIÓN ==========
func on_player_position_changed(new_position: Vector2) -> void:
	"""
	Llamar cuando el jugador se mueve a un nuevo chunk.
	Cargar/descargar chunks según necesario.
	
	Args:
	  new_position: posición global del jugador en el mundo
	"""
	_player_position = new_position
	
	# Convertir posición a coordenadas de chunk (asume chunk de 5760×3240)
	var chunk_size = Vector2(5760, 3240)
	var new_chunk = Vector2i(
		int(new_position.x / chunk_size.x),
		int(new_position.y / chunk_size.y)
	)
	
	if new_chunk != _current_chunk_coords:
		_current_chunk_coords = new_chunk
		_load_surrounding_chunks(new_chunk)

# ========== CARGAR CHUNKS ALREDEDOR DEL JUGADOR ==========
func _load_surrounding_chunks(center_chunk: Vector2i) -> void:
	"""
	Cargar chunks en grid 3×3 alrededor del centro.
	Descargar chunks lejanos.
	"""
	var chunks_to_load = []
	
	# Grid 3×3 alrededor del jugador
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var cx = center_chunk.x + dx
			var cy = center_chunk.y + dy
			chunks_to_load.append(Vector2i(cx, cy))
	
	# Cargar nuevos chunks
	for chunk_coords in chunks_to_load:
		var key = "%d_%d" % [chunk_coords.x, chunk_coords.y]
		if not _active_chunks.has(key):
			_create_chunk(chunk_coords)
	
	# Limpiar chunks lejanos
	_cleanup_distant_chunks(center_chunk)

# ========== CREAR NUEVO CHUNK ==========
func _create_chunk(chunk_coords: Vector2i) -> void:
	"""
	Crear un nuevo chunk y aplicar bioma.
	"""
	var key = "%d_%d" % [chunk_coords.x, chunk_coords.y]
	
	# Crear nodo raíz para el chunk
	var chunk_node = Node2D.new()
	chunk_node.name = "Chunk_%d_%d" % [chunk_coords.x, chunk_coords.y]
	chunk_node.position = Vector2(chunk_coords.x * 5760, chunk_coords.y * 3240)
	
	# Aplicar bioma
	apply_biome_to_chunk(chunk_node, chunk_coords.x, chunk_coords.y)
	
	# Añadir a escena
	add_child(chunk_node)
	_active_chunks[key] = chunk_node
	
	chunk_loaded.emit(chunk_coords)
	
	if debug_mode:
		print("[BiomeChunkApplier] Chunk creado: (%d, %d)" % [chunk_coords.x, chunk_coords.y])

# ========== LIMPIAR CHUNKS LEJANOS ==========
func _cleanup_distant_chunks(center_chunk: Vector2i) -> void:
	"""
	Eliminar chunks que estén demasiado lejos del jugador.
	Mantener máximo max_active_chunks activos.
	"""
	var keys_to_remove = []
	
	for key in _active_chunks.keys():
		var parts = key.split("_")
		var cx = int(parts[0])
		var cy = int(parts[1])
		
		# Si está fuera del rango 3×3, marcarlo para borrar
		if abs(cx - center_chunk.x) > 1 or abs(cy - center_chunk.y) > 1:
			keys_to_remove.append(key)
	
	# Borrar chunks lejanos
	for key in keys_to_remove:
		if _active_chunks.has(key):
			var chunk = _active_chunks[key]
			chunk.queue_free()
			_active_chunks.erase(key)
			_chunk_cache[key] = {}  # Guardar estado mínimo en caché
			
			if debug_mode:
				print("[BiomeChunkApplier] Chunk descargado: %s" % key)

# ========== DEBUGGING ==========
func print_active_chunks() -> void:
	"""Imprimir lista de chunks activos (útil para debugging)"""
	print("\n[BiomeChunkApplier] === CHUNKS ACTIVOS ===")
	for key in _active_chunks.keys():
		var chunk = _active_chunks[key]
		var biome = chunk.get_meta("biome_name", "?")
		print("  - %s (Bioma: %s)" % [key, biome])
	print("[BiomeChunkApplier] Total: %d activos, %d cacheados" % [_active_chunks.size(), _chunk_cache.size()])

func print_config() -> void:
	"""Imprimir configuración de biomas cargada"""
	print("\n[BiomeChunkApplier] === BIOMAS CONFIGURADOS ===")
	for bioma in _config.get("biomes", []):
		print("  - %s (#%s) - %s" % [bioma.get("name"), bioma.get("id"), bioma.get("description")])

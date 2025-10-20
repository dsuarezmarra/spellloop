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

# NOTE: _chunk_cache, _active_chunks, _player_position, _current_chunk_coords
# ya no se utilizan aquí (InfiniteWorldManager es responsable)
# Se mantienen comentadas por legibilidad histórica

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
	
	OPTIMIZACIÓN: Los sprites de textura ahora son Node2D Sprite2D normales,
	NO CanvasLayer. Esto permite que respeten z_index y visible_layers correctamente.
	"""
	var bioma_data = get_biome_for_position(cx, cy)
	
	if bioma_data.is_empty():
		printerr("[BiomeChunkApplier] ✗ No se pudo obtener bioma para (%d, %d)" % [cx, cy])
		return
	
	# Crear contenedor para texturas (Node2D simple, no CanvasLayer)
	var biome_layer = Node2D.new()
	biome_layer.name = "BiomeLayer"
	biome_layer.z_index = -100  # MUY ATRÁS: debajo de TODO (enemigos, player, etc siempre visible)
	chunk_node.add_child(biome_layer)
	
	# Aplicar base + decoraciones
	_apply_textures_optimized(biome_layer, bioma_data, cx, cy)
	
	# Guardar metadatos
	chunk_node.set_meta("biome_name", bioma_data.get("name", "Unknown"))
	chunk_node.set_meta("biome_id", bioma_data.get("id", -1))
	
	if debug_mode:
		print("[BiomeChunkApplier] ✓ Bioma '%s' aplicado a chunk (%d, %d)" % [bioma_data.get("name"), cx, cy])
	
	biome_changed.emit(bioma_data.get("name", ""))

# ========== APLICAR TEXTURAS OPTIMIZADAS ==========
func _apply_textures_optimized(parent: Node, bioma_data: Dictionary, cx: int, cy: int) -> void:
	"""
	SOLUCIÓN CORRECTA: Texturas base 1/9 escala × 3×3 + Decoraciones distribuidas aleatorias
	
	Especificaciones:
	- Chunk: 5760×3240 px = 3×3 pantallas FullHD (1920×1080 cada una)
	- Textura base: 1920×1080 original → escalada 1/9 → replicada 3×3 = chunk completo
	- Decoraciones: TAMBIÉN escaladas 1/9 + DISTRIBUIDAS ALEATORIAMENTE por el chunk
	- Z-index: Base -100 (abajo de todo) < Decor -99 (arriba de base) < Enemigos 0 (siempre visible)
	"""
	var chunk_size = Vector2(5760, 3240)
	var tile_size = Vector2(1920, 1080)  # Tamaño de cada cuadrante
	var grid_cols = 3
	var grid_rows = 3

	# ============ 1. TEXTURAS BASE (1/9 escala × 3×3) ============
	var base_texture_path = bioma_data.get("base_texture_path", "")

	if not base_texture_path.is_empty() and ResourceLoader.exists(base_texture_path):
		var texture = load(base_texture_path) as Texture2D
		if texture:
			var texture_size = texture.get_size()
			# Escala 1/9: para que UN sprite ocupe exactamente 1 cuadrante
			var tile_scale = Vector2(
				tile_size.x / texture_size.x,
				tile_size.y / texture_size.y
			)
			
			# Crear 3×3 grid (9 sprites idénticos)
			for row in range(grid_rows):
				for col in range(grid_cols):
					var sprite = Sprite2D.new()
					sprite.name = "BiomeBase_%d_%d" % [col, row]
					sprite.texture = texture
					sprite.centered = true
					# Centro de cada cuadrante
					sprite.position = Vector2(
						(col + 0.5) * tile_size.x,
						(row + 0.5) * tile_size.y
					)
					sprite.scale = tile_scale
					sprite.z_index = -100  # ATRÁS: debajo de enemigos, proyectiles, etc
					parent.add_child(sprite)
			
			if debug_mode:
				print("[BiomeChunkApplier] ✓ Base 1/9 escala × 3×3: %s" % base_texture_path)

	# ============ 2. DECORACIONES (1/9 escala + Distribución aleatoria) ============
	var decorations = bioma_data.get("decorations", []) as Array
	
	if not decorations.is_empty():
		# RNG determinístico por chunk (mismo seed = reproducible)
		var chunk_rng = RandomNumberGenerator.new()
		var chunk_seed = hash(Vector2i(cx, cy)) & 0xFFFFFFFF
		chunk_rng.seed = chunk_seed
		
		# Generar posiciones aleatorias (1 por cada tile)
		var decor_positions = _generate_decoration_positions(chunk_rng, tile_size)
		
		# Aplicar cada tipo de decoración
		for decor_idx in range(min(decorations.size(), 3)):
			var decor_path = decorations[decor_idx]
			
			if decor_path is String and not decor_path.is_empty() and ResourceLoader.exists(decor_path):
				var texture = load(decor_path) as Texture2D
				if texture:
					var texture_size = texture.get_size()
					# Escala 1/9 (igual que base)
					var decor_scale = Vector2(
						tile_size.x / texture_size.x,
						tile_size.y / texture_size.y
					) * 0.6  # 60% de tamaño (no tape completamente la base)
					
					# Crear instancia en CADA posición
					for pos_idx in range(decor_positions.size()):
						var sprite = Sprite2D.new()
						sprite.name = "BiomeDecor_%d_%d" % [decor_idx, pos_idx]
						sprite.texture = texture
						sprite.centered = true
						sprite.position = decor_positions[pos_idx]
						sprite.scale = decor_scale
						sprite.z_index = -99 + decor_idx  # ENCIMA de base pero DEBAJO de enemigos
						sprite.modulate = Color(1.0, 1.0, 1.0, 0.85)  # Ligeramente transparente
						parent.add_child(sprite)
					
					if debug_mode:
						print("[BiomeChunkApplier] ✓ Decor %d × 9 posiciones (1/9 escala): %s" % [decor_idx+1, decor_path])

# ============ FUNCIÓN AUXILIAR: Generar posiciones aleatorias ============
func _generate_decoration_positions(rng: RandomNumberGenerator, tile_size: Vector2) -> Array:
	"""
	Generar 9 posiciones aleatorias (una por tile) sin salir del chunk.
	
	Garantías:
	- 1 decoración por tile (9 total)
	- Posición aleatoria dentro del tile
	- No sale del chunk
	- Determinístico (RNG seeded)
	"""
	var positions: Array = []
	
	# Iterar 3×3 grid
	for row in range(3):
		for col in range(3):
			# Centro del tile
			var tile_center_x = (col + 0.5) * tile_size.x
			var tile_center_y = (row + 0.5) * tile_size.y
			
			# Offset aleatorio dentro del tile (30% de rango = seguro sin salir)
			var offset_range_x = tile_size.x * 0.3
			var offset_range_y = tile_size.y * 0.3
			
			var random_offset_x = rng.randf_range(-offset_range_x, offset_range_x)
			var random_offset_y = rng.randf_range(-offset_range_y, offset_range_y)
			
			var final_pos = Vector2(
				tile_center_x + random_offset_x,
				tile_center_y + random_offset_y
			)
			
			positions.append(final_pos)
	
	return positions

# ========== INTERFAZ PÚBLICA: APLICAR TEXTURAS ==========
func on_player_position_changed(new_position: Vector2) -> void:
	"""
	DEPRECATED: Este método ya no se utiliza.
	BiomeChunkApplier es un componente pasivo que solo aplica texturas.
	InfiniteWorldManager es responsable de la orquestación.
	"""
	pass

# ========== DEBUGGING ==========
func print_active_chunks() -> void:
	"""
	DEPRECATED: Este método ya no es relevante.
	BiomeChunkApplier no gestiona chunks activos.
	Ver InfiniteWorldManager.get_info() para información de chunks.
	"""
	print("[BiomeChunkApplier] Este sistema ahora solo aplica texturas.")
	print("[BiomeChunkApplier] Ver InfiniteWorldManager para información de chunks.")

func print_config() -> void:
	"""Imprimir configuración de biomas cargada"""
	print("\n[BiomeChunkApplier] === BIOMAS CONFIGURADOS ===")
	for bioma in _config.get("biomes", []):
		print("  - %s (#%s) - %s" % [bioma.get("name"), bioma.get("id"), bioma.get("description")])

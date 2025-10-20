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
	ARQUITECTURA OPCIÓN C:
	- Chunk: 5760×3240
	- Grid: 3×3 = 9 cuadrantes
	- Cada cuadrante: 1920×1080
	
	BASE (suelo):
	- Tamaño esperado: 1920×1080 (llena exactamente 1 cuadrante)
	- Escala: 1.0 (sin distorsión)
	
	DECORACIONES:
	- Principales: 256×256 → Escala (7.5, 4.2) × 0.5 = (3.75, 2.1)
	- Secundarias: 128×128 → Escala (15, 8.4) × 0.25 = (3.75, 2.1)
	- Ambas ocupan ~28% del área del cuadrante
	"""
	var chunk_size = Vector2(5760, 3240)
	var tile_size = Vector2(1920, 1080)  # Cada cuadrante del chunk
	var grid_cols = 3
	var grid_rows = 3

	# ============ 1. TEXTURAS BASE (1920×1080 cada una, sin escala) ============
	var base_texture_path = bioma_data.get("base_texture_path", "")

	if not base_texture_path.is_empty() and ResourceLoader.exists(base_texture_path):
		var texture = load(base_texture_path) as Texture2D
		if texture:
			var actual_texture_size = texture.get_size()
			
			if debug_mode:
				print("[BASE_TEXTURE] Tamaño: %s" % actual_texture_size)
			
			# Escala para llenar exactamente 1920×1080
			var tile_scale = Vector2(
				tile_size.x / actual_texture_size.x,
				tile_size.y / actual_texture_size.y
			)
			
			# Crear 3×3 grid (9 sprites base, uno por cuadrante)
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
					sprite.z_index = -100
					parent.add_child(sprite)
			
			if debug_mode:
				print("[✓] Base: 9 sprites × 1920×1080 (escala: %.2f, %.2f)" % [tile_scale.x, tile_scale.y])

	# ============ 2. DECORACIONES (1 POR POSICIÓN, distribución aleatoria SIN superponer) ============
	var decorations = bioma_data.get("decorations", []) as Array
	
	if not decorations.is_empty():
		# RNG determinístico por chunk
		var chunk_rng = RandomNumberGenerator.new()
		var chunk_seed = hash(Vector2i(cx, cy)) & 0xFFFFFFFF
		chunk_rng.seed = chunk_seed
		
		# Generar posiciones (9 = 3×3)
		var decor_positions = _generate_decoration_positions(chunk_rng, tile_size)
		
		# Para CADA posición: elegir 1 decor aleatoria (no superponer 27 sprites)
		for pos_idx in range(decor_positions.size()):
			# Seleccionar decoración aleatoria (una sola por posición)
			var decor_idx = chunk_rng.randi_range(0, decorations.size() - 1)
			var decor_path = decorations[decor_idx]
			
			if decor_path is String and not decor_path.is_empty() and ResourceLoader.exists(decor_path):
				var texture = load(decor_path) as Texture2D
				if texture:
					var decor_size = texture.get_size()
					var decor_scale: Vector2
					
					# Detectar tipo de decoración por tamaño PNG y calcular escala apropiada
					if decor_size.x >= 200:  # Principales: 256×256
						# Escala: (1920/256, 1080/256) × 0.5 = (7.5, 4.2) × 0.5 = (3.75, 2.1)
						decor_scale = Vector2(
							(tile_size.x / decor_size.x) * 0.5,
							(tile_size.y / decor_size.y) * 0.5
						)
						if debug_mode:
							print("[DECOR_MAIN %d] %s → Escala (%.2f, %.2f)" % [pos_idx, decor_size, decor_scale.x, decor_scale.y])
					else:  # Secundarias: 128×128
						# Escala: (1920/128, 1080/128) × 0.25 = (15, 8.4) × 0.25 = (3.75, 2.1)
						decor_scale = Vector2(
							(tile_size.x / decor_size.x) * 0.25,
							(tile_size.y / decor_size.y) * 0.25
						)
						if debug_mode:
							print("[DECOR_SEC %d] %s → Escala (%.2f, %.2f)" % [pos_idx, decor_size, decor_scale.x, decor_scale.y])
					
					var sprite = Sprite2D.new()
					sprite.name = "BiomeDecor_%d" % pos_idx
					sprite.texture = texture
					sprite.centered = true
					sprite.position = decor_positions[pos_idx]
					sprite.scale = decor_scale
					sprite.z_index = -99  # ENCIMA de base (-100) pero DEBAJO de enemigos
					sprite.modulate = Color(1.0, 1.0, 1.0, 0.9)
					parent.add_child(sprite)
		
		if debug_mode:
			print("[✓] Decoraciones: 9 instancias (1 decor aleatoria por posición, escaladas según tipo)")
	
	# ============ BORDES SUAVIZADOS ============
	# POR AHORA DESHABILITADO - necesita revisión
	# _apply_edge_smoothing(parent, bioma_data, cx, cy, chunk_size, tile_size)

# ============ FUNCIÓN: Suavizar bordes entre chunks ============
func _apply_edge_smoothing(parent: Node, bioma_data: Dictionary, cx: int, cy: int, chunk_size: Vector2, tile_size: Vector2) -> void:
	"""
	Agregar overlays semitransparentes en los bordes para suavizar transiciones.
	
	Estrategia:
	- Crear 4 overlays de baja opacidad en los bordes del chunk
	- Se sobrelapan ligeramente con chunks adyacentes para crear transición suave
	- Usa la MISMA textura base con opacidad 20-40%
	"""
	var base_texture_path = bioma_data.get("base_texture_path", "")
	if base_texture_path.is_empty() or not ResourceLoader.exists(base_texture_path):
		return
	
	var texture = load(base_texture_path) as Texture2D
	if not texture:
		return
	
	var texture_size = texture.get_size()
	var tile_scale = Vector2(
		tile_size.x / texture_size.x,
		tile_size.y / texture_size.y
	)
	
	# Detectar si es textura de chunk
	if texture_size.x > 3000:
		tile_scale = Vector2(tile_size.x / texture_size.x, tile_size.y / texture_size.y)
	
	var blend_width = 120.0  # Ancho del blend en píxeles
	var blend_height = 120.0
	
	# ============ BORDE DERECHO (x ≈ 5760) ============
	var right_blend = Sprite2D.new()
	right_blend.name = "EdgeRight"
	right_blend.texture = texture
	right_blend.centered = true
	right_blend.position = Vector2(chunk_size.x - blend_width / 2, chunk_size.y / 2)
	right_blend.scale = tile_scale
	right_blend.z_index = -98  # Encima de base pero abajo de decor
	right_blend.modulate = Color(1.0, 1.0, 1.0, 0.25)  # 25% opacidad para suavizar
	right_blend.self_modulate = Color(1.0, 1.0, 1.0, 0.25)
	parent.add_child(right_blend)
	
	# ============ BORDE INFERIOR (y ≈ 3240) ============
	var bottom_blend = Sprite2D.new()
	bottom_blend.name = "EdgeBottom"
	bottom_blend.texture = texture
	bottom_blend.centered = true
	bottom_blend.position = Vector2(chunk_size.x / 2, chunk_size.y - blend_height / 2)
	bottom_blend.scale = tile_scale
	bottom_blend.z_index = -98
	bottom_blend.modulate = Color(1.0, 1.0, 1.0, 0.25)
	bottom_blend.self_modulate = Color(1.0, 1.0, 1.0, 0.25)
	parent.add_child(bottom_blend)
	
	# ============ ESQUINA INFERIOR-DERECHA ============
	var corner_blend = Sprite2D.new()
	corner_blend.name = "EdgeCorner"
	corner_blend.texture = texture
	corner_blend.centered = true
	corner_blend.position = Vector2(chunk_size.x - blend_width / 2, chunk_size.y - blend_height / 2)
	corner_blend.scale = tile_scale
	corner_blend.z_index = -98
	corner_blend.modulate = Color(1.0, 1.0, 1.0, 0.15)  # Más transparente en esquina
	corner_blend.self_modulate = Color(1.0, 1.0, 1.0, 0.15)
	parent.add_child(corner_blend)
	
	if debug_mode:
		print("[BiomeChunkApplier] ✓ Bordes suavizados (blend width: %.0f px)" % blend_width)

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

# ========== DEBUGGING ==========
func print_config() -> void:
	"""Imprimir configuración de biomas cargada"""
	print("\n[BiomeChunkApplier] === BIOMAS CONFIGURADOS ===")
	for bioma in _config.get("biomes", []):
		print("  - %s (#%s) - %s" % [bioma.get("name"), bioma.get("id"), bioma.get("description")])

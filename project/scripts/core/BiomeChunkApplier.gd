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
	bioma_data["color_base"] = bioma_config.get("color_base", "#7ED957")

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
	ARQUITECTURA OPTIMIZADA:
	- Chunk: 3840×2160 (2× viewport, mejor performance)
	- Grid: 2×2 = 4 cuadrantes
	- Cada cuadrante: 1920×1080

	BASE (suelo):
	- Tamaño esperado: 1920×1080 (llena exactamente 1 cuadrante)
	- Escala: 1.0 (sin distorsión)

	DECORACIONES (MEJORADAS):
	- Posición: Aleatoria dentro del chunk (no grid)
	- Cantidad: Variable por bioma (density)
	- Escala: Variable según tipo (0.5-1.5)
	- Color: Variación sutil (0.9-1.1)
	- SIN rotación (según preferencia usuario)
	"""
	var chunk_size = Vector2(3840, 2160)
	var tile_size = Vector2(1920, 1080)  # Cada cuadrante del chunk
	var grid_cols = 2
	var grid_rows = 2

	# ============ 1. TEXTURAS BASE (1920×1080 cada una, sin escala) ============
	var base_texture_path = bioma_data.get("base_texture_path", "")

	if not base_texture_path.is_empty():
		if debug_mode:
			print("[BASE_TEXTURE] 📂 Intentando cargar desde: %s" % base_texture_path)

		var texture = load(base_texture_path) as Texture2D
		if texture:
			var actual_texture_size = texture.get_size()

			if debug_mode:
				print("[BASE_TEXTURE] ✓ Cargada exitosamente - Tamaño: %s" % actual_texture_size)

			# Escala para llenar exactamente 1920×1080
			var tile_scale = Vector2(
				tile_size.x / actual_texture_size.x,
				tile_size.y / actual_texture_size.y
			)

			# Crear 2×2 grid (4 sprites base, uno por cuadrante)
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
				print("[✓] Base: 4 sprites × 1920×1080 (escala: %.2f, %.2f)" % [tile_scale.x, tile_scale.y])
		else:
			printerr("[BASE_TEXTURE] ✗ NO se pudo cargar: %s" % base_texture_path)
			# FALLBACK: Crear fondo de color sólido basado en bioma
			_create_solid_color_fallback(parent, bioma_data, grid_rows, grid_cols, tile_size)
	else:
		printerr("[BASE_TEXTURE] ✗ Ruta vacía para textura base")

	# ============ 2. DECORACIONES (ORGÁNICAS CON VARIACIÓN) ============
	var decorations = bioma_data.get("decorations", []) as Array

	if not decorations.is_empty():
		# RNG determinístico por chunk
		var chunk_rng = RandomNumberGenerator.new()
		var chunk_seed = hash(Vector2i(cx, cy)) & 0xFFFFFFFF
		chunk_rng.seed = chunk_seed

		# Densidad variable por bioma (por defecto 1.0)
		var base_density = bioma_data.get("decor_density", 1.0)
		var num_decors = int(12 * base_density)  # 12 decoraciones base (3 por cuadrante)

		for i in range(num_decors):
			# Seleccionar decoración aleatoria
			var decor_idx = chunk_rng.randi_range(0, decorations.size() - 1)
			var decor_path = decorations[decor_idx]

			if decor_path is String and not decor_path.is_empty():
				var texture = load(decor_path) as Texture2D
				if texture:
					var decor_size = texture.get_size()

					# Posición completamente aleatoria dentro del chunk (no grid)
					var rand_x = chunk_rng.randf_range(0, chunk_size.x)
					var rand_y = chunk_rng.randf_range(0, chunk_size.y)

					# CORRECCIÓN: Escala base mucho más pequeña
					# Las decoraciones deberían ser ~5-15% del tamaño del chunk
					# Para un PNG de 256px, queremos ~150-200px en pantalla
					var target_size = chunk_rng.randf_range(100, 250)  # Tamaño objetivo en píxeles
					var base_scale = Vector2(
						target_size / decor_size.x,
						target_size / decor_size.y
					)

					# Multiplicador de escala según tipo de decoración (ya no sobre tile_size)
					var scale_multiplier = _get_decor_scale_multiplier(decor_path, decor_size, chunk_rng)
					var final_scale = base_scale * scale_multiplier

					# Variación sutil de color (0.9 - 1.1)
					var color_variation = Color(
						chunk_rng.randf_range(0.9, 1.1),
						chunk_rng.randf_range(0.9, 1.1),
						chunk_rng.randf_range(0.9, 1.1),
						chunk_rng.randf_range(0.85, 0.95)
					)

					var sprite = Sprite2D.new()
					sprite.name = "BiomeDecor_%d" % i
					sprite.texture = texture
					sprite.centered = true
					sprite.position = Vector2(rand_x, rand_y)
					sprite.scale = final_scale
					sprite.z_index = -96  # ENCIMA de base y dithering, DEBAJO de enemigos
					sprite.modulate = color_variation
					# NO aplicamos rotación según preferencia del usuario

					parent.add_child(sprite)

					if debug_mode and i < 3:  # Solo mostrar primeras 3 para no saturar logs
						print("[DECOR %d] Pos:(%.0f,%.0f) Escala:(%.2f,%.2f) Color:(%.2f,%.2f,%.2f)" % [
							i, rand_x, rand_y, final_scale.x, final_scale.y,
							color_variation.r, color_variation.g, color_variation.b
						])

		if debug_mode:
			print("[✓] Decoraciones: %d instancias orgánicas (variación de pos/escala/color)" % num_decors)

	# ============ TRANSICIONES SUAVES EN BORDES ============
	# Aplicar dithering/blending en los bordes del chunk
	_apply_border_transitions(parent, bioma_data, cx, cy, chunk_size)

# ============ FUNCIÓN: Transiciones de Biomas ============
func _apply_border_transitions(parent: Node, bioma_data: Dictionary, cx: int, cy: int, chunk_size: Vector2) -> void:
	"""
	Aplica dithering REAL en los bordes mezclando píxeles del bioma actual con vecinos.

	Estrategia:
	1. Obtener biomas de los 4 chunks vecinos (arriba, abajo, izq, der)
	2. Si son diferentes, crear una franja MUY DELGADA de transición
	3. En la franja, alternar píxeles de ambos biomas según patrón Bayer (puro dithering)
	"""
	var border_width = 16  # Zona de transición MÍNIMA (solo algunos píxeles entremezclados)

	# Patrón Bayer 8×8 (para dithering ordenado)
	const BAYER_8x8 = [
		[0, 32, 8, 40, 2, 34, 10, 42],
		[48, 16, 56, 24, 50, 18, 58, 26],
		[12, 44, 4, 36, 14, 46, 6, 38],
		[60, 28, 52, 20, 62, 30, 54, 22],
		[3, 35, 11, 43, 1, 33, 9, 41],
		[51, 19, 59, 27, 49, 17, 57, 25],
		[15, 47, 7, 39, 13, 45, 5, 37],
		[63, 31, 55, 23, 61, 29, 53, 21]
	]

	# Obtener texturas de biomas vecinos
	var neighbors = {
		"top": get_biome_for_position(cx, cy - 1),
		"bottom": get_biome_for_position(cx, cy + 1),
		"left": get_biome_for_position(cx - 1, cy),
		"right": get_biome_for_position(cx + 1, cy)
	}

	var current_biome_name = bioma_data.get("name", "")
	var base_texture_path = bioma_data.get("base_texture_path", "")

	if base_texture_path.is_empty() or not ResourceLoader.exists(base_texture_path):
		return

	var current_texture = load(base_texture_path) as Texture2D
	if not current_texture:
		return

	# Procesar cada borde
	for direction in ["top", "bottom", "left", "right"]:
		var neighbor = neighbors[direction]
		if neighbor.is_empty():
			continue

		var neighbor_name = neighbor.get("name", "")
		if neighbor_name == current_biome_name:
			continue  # Mismo bioma, no necesita dithering

		var neighbor_texture_path = neighbor.get("base_texture_path", "")
		if neighbor_texture_path.is_empty() or not ResourceLoader.exists(neighbor_texture_path):
			continue

		var neighbor_texture = load(neighbor_texture_path) as Texture2D
		if not neighbor_texture:
			continue

		# Crear sprites con patrón dithering para este borde
		_create_dithered_border(parent, direction, current_texture, neighbor_texture,
								chunk_size, border_width, BAYER_8x8)

func _create_dithered_border(parent: Node, direction: String, texture_a: Texture2D,
							 texture_b: Texture2D, chunk_size: Vector2,
							 border_width: float, bayer_pattern: Array) -> void:
	"""
	Crea UNA sola franja con shader que hace dithering entre dos texturas.
	MUCHO más eficiente que crear miles de sprites.
	"""
	var stripe_size = Vector2.ZERO
	var stripe_pos = Vector2.ZERO
	var is_horizontal = false

	match direction:
		"top":
			stripe_size = Vector2(chunk_size.x, border_width)
			stripe_pos = Vector2(0, 0)
			is_horizontal = true
		"bottom":
			stripe_size = Vector2(chunk_size.x, border_width)
			stripe_pos = Vector2(0, chunk_size.y - border_width)
			is_horizontal = true
		"left":
			stripe_size = Vector2(border_width, chunk_size.y)
			stripe_pos = Vector2(0, 0)
			is_horizontal = false
		"right":
			stripe_size = Vector2(border_width, chunk_size.y)
			stripe_pos = Vector2(chunk_size.x - border_width, 0)
			is_horizontal = false

	# Crear UN SOLO sprite con shader de dithering
	var sprite = Sprite2D.new()
	sprite.name = "DitherBorder_%s" % direction
	sprite.centered = false
	sprite.position = stripe_pos
	sprite.texture = texture_a
	sprite.z_index = -98  # DEBAJO de decoradores (-96), ENCIMA de base (-100)

	# Escalar textura para cubrir la franja
	var texture_size = texture_a.get_size()
	sprite.scale = Vector2(
		stripe_size.x / texture_size.x,
		stripe_size.y / texture_size.y
	)

	# Shader con DITHERING PURO - Solo píxeles intercalados sin gradientes
	var shader_code = """
shader_type canvas_item;

uniform sampler2D texture_b;
uniform float border_width = 16.0;
uniform bool is_horizontal = true;

// Patrón Bayer 4×4 (más agresivo para transiciones pixeladas)
float bayer4x4(vec2 pos) {
	int x = int(mod(pos.x, 4.0));
	int y = int(mod(pos.y, 4.0));

	const float pattern[16] = float[](
		0.0/16.0,  8.0/16.0,  2.0/16.0, 10.0/16.0,
		12.0/16.0, 4.0/16.0, 14.0/16.0,  6.0/16.0,
		3.0/16.0, 11.0/16.0,  1.0/16.0,  9.0/16.0,
		15.0/16.0, 7.0/16.0, 13.0/16.0,  5.0/16.0
	);

	return pattern[y * 4 + x];
}

void fragment() {
	vec4 color_a = texture(TEXTURE, UV);
	vec4 color_b = texture(texture_b, UV);

	// Calcular factor de blend basado en posición
	float blend_factor;
	if (is_horizontal) {
		blend_factor = UV.y;
	} else {
		blend_factor = UV.x;
	}

	// Aplicar dithering PURO (100% pattern-based, sin suavizado)
	float threshold = bayer4x4(FRAGCOORD.xy);

	// Hard dithering: si blend_factor > threshold → texture_b, sino texture_a
	COLOR = (blend_factor > threshold) ? color_b : color_a;
}
"""

	var shader_material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = shader_code
	shader_material.shader = shader
	shader_material.set_shader_parameter("texture_b", texture_b)
	shader_material.set_shader_parameter("border_width", border_width)
	shader_material.set_shader_parameter("is_horizontal", is_horizontal)
	sprite.material = shader_material

	parent.add_child(sprite)

	if debug_mode:
		print("[✓] Dithering aplicado en borde %s (shader)" % direction)

# ============ FUNCIÓN: Calcular multiplicador de escala según tipo ============
func _get_decor_scale_multiplier(decor_path: String, decor_size: Vector2, rng: RandomNumberGenerator) -> float:
	"""
	Devuelve un multiplicador de escala variable según el tipo de decoración.

	ACTUALIZADO: Ahora devuelve valores más razonables (0.5 - 2.0)
	Ya que la escala base ya está ajustada al tamaño objetivo (100-250px)

	Tipos detectados por nombre de archivo:
	- tree, trunk: 1.2 - 1.8 (árboles más grandes)
	- rock, stone, boulder: 0.6 - 1.4 (rocas variables)
	- bush, plant, flower, grass: 0.5 - 1.0 (plantas pequeñas-medianas)
	- crystal, gem: 0.4 - 0.9 (cristales pequeños)
	- default: 0.7 - 1.3
	"""
	var path_lower = decor_path.to_lower()

	# Detectar por nombre y devolver multiplicador directo
	if "tree" in path_lower or "trunk" in path_lower:
		return rng.randf_range(1.2, 1.8)  # Árboles más grandes
	elif "rock" in path_lower or "stone" in path_lower or "boulder" in path_lower:
		return rng.randf_range(0.6, 1.4)  # Rocas variables
	elif "bush" in path_lower or "plant" in path_lower or "flower" in path_lower or "grass" in path_lower:
		return rng.randf_range(0.5, 1.0)  # Plantas pequeñas
	elif "crystal" in path_lower or "gem" in path_lower:
		return rng.randf_range(0.4, 0.9)  # Cristales pequeños
	else:
		return rng.randf_range(0.7, 1.3)  # Default

# ============ FUNCIÓN: Fallback - Color sólido si no se carga textura ============
func _create_solid_color_fallback(parent: Node, bioma_data: Dictionary, grid_rows: int, grid_cols: int, tile_size: Vector2) -> void:
	"""
	Si la textura base no se puede cargar, crear un fondo de color sólido.
	Extrae el color_base del JSON de configuración.
	"""
	var color_hex = bioma_data.get("color_base", "#7ED957")
	var color = Color.from_string(color_hex, Color.WHITE)

	print("[FALLBACK] Usando color de bioma: %s" % color_hex)

	# Crear 2×2 grid de ColorRects
	for row in range(grid_rows):
		for col in range(grid_cols):
			var color_rect = ColorRect.new()
			color_rect.name = "BiomaFallback_%d_%d" % [col, row]
			color_rect.color = color
			color_rect.z_index = -100

			# Tamaño: llenar exactamente 1 tile
			color_rect.custom_minimum_size = tile_size
			color_rect.position = Vector2(col * tile_size.x, row * tile_size.y)
			color_rect.size = tile_size

			parent.add_child(color_rect)

	print("[✓] Fallback: 4 ColorRects aplicados (color: %s)" % color_hex)

# ============ FUNCIÓN: Suavizar bordes entre chunks (OLD) ============
func _apply_edge_smoothing(parent: Node, bioma_data: Dictionary, _cx: int, _cy: int, chunk_size: Vector2, tile_size: Vector2) -> void:
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

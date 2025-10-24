# BiomeGenerator.gd
# Generador de biomas orgánicos con decoraciones distribuidas naturalmente
# Reescrito para soportar regiones de forma irregular con transiciones suaves

extends Node
class_name BiomeGenerator

"""
🌿 BIOME GENERATOR - SISTEMA ORGÁNICO
====================================

Responsabilidades:
- Generar contenido de bioma dentro de regiones orgánicas irregulares
- Distribuir decoraciones usando ruido Perlin (no en grid)
- Soportar los 6 biomas existentes con sus características únicas
- Mantener determinismo basado en semilla de región
- Generar geometría base compatible con OrganicTextureBlender

Mejoras vs sistema anterior:
- Decoraciones distribuidas orgánicamente (no en cuadrícula)
- Densidad variable según ruido fractal
- Respeta contornos irregulares de regiones
- Optimizado para formas Voronoi + Perlin
"""

# ========== DEFINICIÓN DE BIOMAS (CONSERVADO) ==========
enum BiomeType {GRASSLAND, DESERT, SNOW, LAVA, ARCANE_WASTES, FOREST}

const BIOME_COLORS = {
	BiomeType.GRASSLAND: Color(0.34, 0.68, 0.35, 1.0), # Verde prado
	BiomeType.DESERT: Color(0.87, 0.78, 0.6, 1.0), # Arena amarilla
	BiomeType.SNOW: Color(0.95, 0.95, 1.0, 1.0), # Nieve blanca/azul
	BiomeType.LAVA: Color(0.4, 0.1, 0.05, 1.0), # Rojo oscuro/incandescente
	BiomeType.ARCANE_WASTES: Color(0.6, 0.3, 0.8, 1.0), # Violeta mágico
	BiomeType.FOREST: Color(0.15, 0.35, 0.15, 1.0), # Verde oscuro
}

const BIOME_NAMES = {
	BiomeType.GRASSLAND: "grassland",
	BiomeType.DESERT: "desert",
	BiomeType.SNOW: "snow",
	BiomeType.LAVA: "lava",
	BiomeType.ARCANE_WASTES: "arcane_wastes",
	BiomeType.FOREST: "forest",
}

# ========== CONFIGURACIÓN ORGÁNICA ==========
const ORGANIC_DECORATIONS = {
	BiomeType.GRASSLAND: {
		"types": ["bush", "flower", "tree_small", "grass_patch", "stone"],
		"density": 0.3,
		"cluster_size": 150.0
	},
	BiomeType.DESERT: {
		"types": ["cactus", "rock", "sand_spike", "bone", "dried_plant"],
		"density": 0.15,
		"cluster_size": 200.0
	},
	BiomeType.SNOW: {
		"types": ["ice_crystal", "snow_mound", "frozen_rock", "ice_spike"],
		"density": 0.2,
		"cluster_size": 100.0
	},
	BiomeType.LAVA: {
		"types": ["lava_rock", "fire_spike", "magma_vent", "obsidian"],
		"density": 0.25,
		"cluster_size": 120.0
	},
	BiomeType.ARCANE_WASTES: {
		"types": ["rune_stone", "arcane_crystal", "void_spike", "magic_circle"],
		"density": 0.35,
		"cluster_size": 180.0
	},
	BiomeType.FOREST: {
		"types": ["tree", "bush_dense", "fallen_log", "mushroom", "fern"],
		"density": 0.4,
		"cluster_size": 220.0
	}
}

# ========== GENERADORES DE RUIDO ==========
var distribution_noise: FastNoiseLite = FastNoiseLite.new() # Para distribución orgánica
var density_noise: FastNoiseLite = FastNoiseLite.new() # Para variación de densidad
var cluster_noise: FastNoiseLite = FastNoiseLite.new() # Para clustering natural

# ========== ESTADO ==========
var world_seed: int = 12345

func _ready() -> void:
	"""Inicializar generador de biomas orgánicos"""
	_setup_noise_generators()
	print("[BiomeGenerator] 🌿 Sistema orgánico inicializado")

func _setup_noise_generators() -> void:
	"""Configurar generadores de ruido para distribución orgánica"""
	# Ruido para distribución general de decoraciones
	distribution_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	distribution_noise.frequency = 0.008
	distribution_noise.seed = world_seed

	# Ruido para variación de densidad
	density_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	density_noise.frequency = 0.003
	density_noise.seed = world_seed + 1000

	# Ruido para clustering natural
	cluster_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	cluster_noise.frequency = 0.02
	cluster_noise.seed = world_seed + 2000

# ========== FUNCIÓN PRINCIPAL DE GENERACIÓN ==========
func generate_region_async(organic_region) -> Dictionary:
	"""
	Generar contenido de bioma para región orgánica irregular

	Args:
		organic_region: OrganicRegion - región con geometría y bioma definidos

	Returns:
		Dictionary con datos de terreno, decoraciones y metadatos
	"""

	await get_tree().process_frame

	var start_time = Time.get_ticks_msec()
	var region_center = organic_region.center_position
	var biome_type = _get_biome_type_from_id(organic_region.biome_id)
	var boundary_points = organic_region.boundary_points

	# Configurar semilla determinística para esta región
	var region_seed = _calculate_region_seed(region_center)
	_update_noise_seeds(region_seed)

	print("[BiomeGenerator] 🌿 Generando región orgánica | Centro:", region_center, " | Bioma:", BIOME_NAMES.get(biome_type))

	# Generar geometría base orgánica
	var base_geometry = _generate_organic_base_geometry(organic_region)

	# Distribuir decoraciones orgánicamente dentro del contorno
	var decorations = _distribute_organic_decorations(organic_region)

	# Generar datos de textura base
	var texture_data = _generate_texture_data(organic_region)

	var generation_time = Time.get_ticks_msec() - start_time
	print("[BiomeGenerator] ⚡ Región orgánica generada | Tiempo:", generation_time, "ms | Decoraciones:", decorations.size())

	return {
		"region_id": organic_region.region_id,
		"biome_type": biome_type,
		"center_position": region_center,
		"boundary_points": boundary_points,
		"base_geometry": base_geometry,
		"decorations": decorations,
		"texture_data": texture_data,
		"generation_time": generation_time,
		"region_seed": region_seed
	}

func _add_grass_pattern(parent: Node2D, base_color: Color, pattern_color: Color) -> void:
	"""Patrón de hierba: pequeños rectángulos"""
	var rng = RandomNumberGenerator.new()
	for y in range(0, 3240, 60):
		for x in range(0, 5760, 60):
			var rect = ColorRect.new()
			rect.color = pattern_color if rng.randf() > 0.5 else base_color.lightened(0.1)
			rect.position = Vector2(x, y)
			rect.size = Vector2(60, 60)
			rect.modulate.a = 0.3 # Semi-transparente
			parent.add_child(rect)

func _add_sand_pattern(parent: Node2D, _base_color: Color, pattern_color: Color) -> void:
	"""Patrón de arena: puntos/círculos"""
	var rng = RandomNumberGenerator.new()
	for i in range(200):
		var pos = Vector2(rng.randf() * 5760, rng.randf() * 3240)
		var circle = Polygon2D.new()
		circle.position = pos
		# Círculo usando polígono
		var radius = rng.randf() * 30 + 10
		for j in range(8):
			var angle = (TAU / 8) * j
			circle.polygon.append(Vector2(cos(angle) * radius, sin(angle) * radius))
		circle.color = pattern_color
		circle.modulate.a = 0.4
		parent.add_child(circle)

func _add_snow_pattern(parent: Node2D, _base_color: Color, pattern_color: Color) -> void:
	"""Patrón de nieve: copos/puntitos"""
	var rng = RandomNumberGenerator.new()
	for i in range(300):
		var pos = Vector2(rng.randf() * 5760, rng.randf() * 3240)
		var snowflake = Polygon2D.new()
		snowflake.position = pos
		# Pequeño hexágono
		var size = 5.0
		for j in range(6):
			var angle = (TAU / 6) * j
			snowflake.polygon.append(Vector2(cos(angle) * size, sin(angle) * size))
		snowflake.color = pattern_color.lightened(0.3)
		snowflake.modulate.a = 0.6
		parent.add_child(snowflake)

func _add_lava_pattern(parent: Node2D, _base_color: Color, pattern_color: Color) -> void:
	"""Patrón de lava: líneas/grietas"""
	var rng = RandomNumberGenerator.new()
	for i in range(15):
		var line = Line2D.new()
		line.default_color = pattern_color.lightened(0.2)
		line.width = rng.randf() * 3 + 1
		# Línea sinusoidal
		var start_y = rng.randf() * 3240
		for x in range(0, 5760, 100):
			var y = start_y + sin(float(x) / 500) * 200 + rng.randf() * 50
			line.add_point(Vector2(x, y))
		line.modulate.a = 0.5
		parent.add_child(line)

func _add_arcane_pattern(parent: Node2D, _base_color: Color, pattern_color: Color) -> void:
	"""Patrón mágico: runas"""
	var rng = RandomNumberGenerator.new()
	for i in range(50):
		var rune = Polygon2D.new()
		rune.position = Vector2(rng.randf() * 5760, rng.randf() * 3240)
		# Estrella con 6 puntas
		var size = rng.randf() * 15 + 10
		for j in range(12):
			var angle = (TAU / 12) * j
			var radius = size if j % 2 == 0 else size / 2
			rune.polygon.append(Vector2(cos(angle) * radius, sin(angle) * radius))
		rune.color = pattern_color
		rune.modulate.a = 0.4
		parent.add_child(rune)

func _add_forest_pattern(_parent: Node2D, _base_color: Color, pattern_color: Color) -> void:
	"""Patrón de bosque: líneas/ramas"""
	var rng = RandomNumberGenerator.new()
	for i in range(100):
		var line = Line2D.new()
		line.default_color = pattern_color
		line.width = rng.randf() * 2 + 1
		var start_x = rng.randf() * 5760
		var start_y = rng.randf() * 3240
		line.add_point(Vector2(start_x, start_y))
		# Línea ramificada
		var end_x = start_x + (rng.randf() - 0.5) * 200
		var end_y = start_y + (rng.randf() - 0.5) * 200
		line.add_point(Vector2(end_x, end_y))
# ========== FUNCIONES AUXILIARES ==========

func _calculate_region_seed(region_center: Vector2) -> int:
	"""Calcular semilla determinística basada en posición de región"""
	var x_hash = int(region_center.x * 73856093) % 19349663
	var y_hash = int(region_center.y * 83492791) % 19349663
	return (world_seed + x_hash + y_hash) % 2147483647

func _update_noise_seeds(region_seed: int) -> void:
	"""Actualizar semillas de todos los generadores de ruido"""
	distribution_noise.seed = region_seed
	density_noise.seed = region_seed + 1000
	cluster_noise.seed = region_seed + 2000

func _generate_organic_base_geometry(organic_region) -> Dictionary:
	"""Generar geometría base de la región (datos para rendering)"""
	return {
		"center": organic_region.center_position,
		"boundary": organic_region.boundary_points,
		"area": _calculate_polygon_area(organic_region.boundary_points),
		"bounding_rect": _calculate_bounding_rect(organic_region.boundary_points)
	}

func _distribute_organic_decorations(organic_region) -> Array:
	"""Distribuir decoraciones orgánicamente dentro del contorno irregular"""
	var decorations = []
	var biome_type = _get_biome_type_from_id(organic_region.biome_id)
	var biome_config = ORGANIC_DECORATIONS.get(biome_type, ORGANIC_DECORATIONS[BiomeType.GRASSLAND])
	var boundary_points = organic_region.boundary_points

	# Calcular área aproximada y número de decoraciones
	var area = _calculate_polygon_area(boundary_points)
	var target_count = int(area * biome_config.density / 10000.0) # Normalizar por área

	print("[BiomeGenerator] 🌸 Distribuyendo ", target_count, " decoraciones en área ", int(area))

	var attempts = 0
	var max_attempts = target_count * 3 # Evitar bucle infinito

	while decorations.size() < target_count and attempts < max_attempts:
		attempts += 1

		# Generar posición candidata dentro del bounding rectangle
		var bounding_rect = _calculate_bounding_rect(boundary_points)
		var candidate_pos = Vector2(
			randf_range(bounding_rect.position.x, bounding_rect.position.x + bounding_rect.size.x),
			randf_range(bounding_rect.position.y, bounding_rect.position.y + bounding_rect.size.y)
		)

		# Verificar si está dentro del polígono irregular
		if not _point_in_polygon(candidate_pos, boundary_points):
			continue

		# Verificar densidad usando ruido
		var density_value = density_noise.get_noise_2d(candidate_pos.x, candidate_pos.y)
		if density_value < 0.2: # Solo colocar en 20% de las posiciones más densas
			continue

		# Seleccionar tipo de decoración
		var decoration_types = biome_config.types
		var decoration_type = decoration_types[randi() % decoration_types.size()]

		# Aplicar clustering natural
		var cluster_value = cluster_noise.get_noise_2d(candidate_pos.x, candidate_pos.y)
		var cluster_scale = 1.0 + (cluster_value * 0.5) # Variación ±50%

		decorations.append({
			"type": decoration_type,
			"position": candidate_pos,
			"scale": cluster_scale,
			"rotation": randf() * TAU,
			"cluster_strength": cluster_value
		})

	return decorations

func _generate_texture_data(organic_region) -> Dictionary:
	"""Generar datos de textura base para la región"""
	var biome_type = _get_biome_type_from_id(organic_region.biome_id)
	return {
		"base_texture": BIOME_NAMES.get(biome_type),
		"texture_scale": 1.0,
		"texture_rotation": 0.0,
		"blend_strength": 1.0
	}

func _calculate_polygon_area(points: PackedVector2Array) -> float:
	"""Calcular área de polígono usando fórmula del cordón de zapatos"""
	if points.size() < 3:
		return 0.0

	var area = 0.0
	var n = points.size()

	for i in range(n):
		var j = (i + 1) % n
		area += points[i].x * points[j].y
		area -= points[j].x * points[i].y

	return abs(area) / 2.0

func _calculate_bounding_rect(points: PackedVector2Array) -> Rect2:
	"""Calcular rectángulo delimitador de un conjunto de puntos"""
	if points.size() == 0:
		return Rect2()

	var min_pos = points[0]
	var max_pos = points[0]

	for point in points:
		min_pos.x = min(min_pos.x, point.x)
		min_pos.y = min(min_pos.y, point.y)
		max_pos.x = max(max_pos.x, point.x)
		max_pos.y = max(max_pos.y, point.y)

	return Rect2(min_pos, max_pos - min_pos)

func _point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	"""Verificar si un punto está dentro de un polígono usando ray casting"""
	var n = polygon.size()
	if n < 3:
		return false

	var inside = false
	var j = n - 1

	for i in range(n):
		var pi = polygon[i]
		var pj = polygon[j]

		if ((pi.y > point.y) != (pj.y > point.y)) and \
		   (point.x < (pj.x - pi.x) * (point.y - pi.y) / (pj.y - pi.y) + pi.x):
			inside = !inside

		j = i

	return inside

# ========== FUNCIONES DE UTILIDAD (CONSERVADAS) ==========
func get_biome_color(biome_type: int) -> Color:
	"""Obtener color representativo del bioma"""
	return BIOME_COLORS.get(biome_type, Color.WHITE)

func get_biome_name(biome_type: int) -> String:
	"""Obtener nombre del bioma"""
	return BIOME_NAMES.get(biome_type, "grassland")

func get_biome_info(biome_type: int) -> Dictionary:
	"""Obtener información completa de un bioma"""
	return {
		"name": BIOME_NAMES.get(biome_type, "unknown"),
		"color": BIOME_COLORS.get(biome_type, Color.WHITE),
		"decorations": ORGANIC_DECORATIONS.get(biome_type, {}).get("types", [])
	}

func _get_biome_type_from_id(biome_id: String) -> int:
	"""Convertir biome_id (String) a BiomeType (int)"""
	for biome_type in BIOME_NAMES:
		if BIOME_NAMES[biome_type] == biome_id:
			return biome_type
	return BiomeType.GRASSLAND # Default fallback

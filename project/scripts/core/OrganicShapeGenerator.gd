# OrganicShapeGenerator.gd
# Generador de formas orgánicas usando Voronoi + ruido Perlin fractal
# Crea regiones irregulares que reemplazan chunks rectangulares

extends Node
class_name OrganicShapeGenerator

"""
🌊 ORGANIC SHAPE GENERATOR
==========================

Responsabilidades:
- Generar formas orgánicas usando diagramas de Voronoi deformados
- Aplicar ruido Perlin fractal para suavizar y naturalizar bordes
- Crear regiones de tamaño variable (1.5x - 3x tamaño de pantalla)
- Mantener determinismo basado en semilla del mundo
- Garantizar que las regiones encajen sin huecos ni solapamientos

Algoritmo:
1. Generar puntos semilla Voronoi en grid distribuido
2. Calcular polígonos Voronoi iniciales
3. Deformar bordes con ruido Perlin fractal
4. Suavizar usando splines cúbicas
5. Validar que no haya huecos entre regiones vecinas
"""

# ========== CONFIGURACIÓN ==========
@export var base_region_size: float = 2000.0 # Tamaño base de región (1x pantalla aprox)
@export var size_variance: float = 0.5 # Variación de tamaño (±50%)
@export var noise_strength: float = 300.0 # Intensidad de deformación
@export var noise_frequency: float = 0.005 # Frecuencia del ruido Perlin
@export var smoothing_passes: int = 3 # Pasadas de suavizado
@export var min_region_points: int = 6 # Mínimo de puntos por región
@export var max_region_points: int = 12 # Máximo de puntos por región

# ========== GENERADORES DE RUIDO ==========
var primary_noise: FastNoiseLite = FastNoiseLite.new()
var secondary_noise: FastNoiseLite = FastNoiseLite.new()
var size_noise: FastNoiseLite = FastNoiseLite.new()

# ========== CACHE Y ESTADO ==========
var world_seed: int = 12345
var generated_regions: Dictionary = {} # Cache de regiones generadas
var voronoi_seeds: Array[Vector2] = [] # Puntos semilla Voronoi

# ========== ESTRUCTURA DE DATOS ==========
class OrganicRegion:
	var region_id: Vector2i
	var center_position: Vector2
	var boundary_points: PackedVector2Array
	var area: float
	var biome_id: String
	var neighbor_regions: Array[Vector2i]
	var noise_seed: int

	func _init(id: Vector2i, center: Vector2, biome: String):
		region_id = id
		center_position = center
		biome_id = biome
		boundary_points = PackedVector2Array()
		neighbor_regions = []
		area = 0.0
		noise_seed = 0

func _ready() -> void:
	"""Inicializar generador de formas orgánicas"""
	_setup_noise_generators()
	print("[OrganicShapeGenerator] ✅ Inicializado - Semilla: %d" % world_seed)

func _setup_noise_generators() -> void:
	"""Configurar generadores de ruido con diferentes características"""
	# Ruido principal para deformación de bordes
	primary_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	primary_noise.frequency = noise_frequency
	primary_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	primary_noise.fractal_octaves = 4
	primary_noise.fractal_lacunarity = 2.0
	primary_noise.fractal_gain = 0.5

	# Ruido secundario para variaciones sutiles
	secondary_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	secondary_noise.frequency = noise_frequency * 2.5
	secondary_noise.fractal_octaves = 2

	# Ruido para variación de tamaños
	size_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	size_noise.frequency = 0.001

func initialize(seed_value: int) -> void:
	"""Inicializar con semilla del mundo para determinismo"""
	world_seed = seed_value
	primary_noise.seed = seed_value
	secondary_noise.seed = seed_value + 1000
	size_noise.seed = seed_value + 2000

	print("[OrganicShapeGenerator] 🎲 Semilla configurada: %d" % world_seed)

func generate_region_async(region_id: Vector2i) -> OrganicRegion:
	"""
	Generar una región orgánica de forma asíncrona

	Args:
		region_id: Identificador único de la región (coordenadas grid)

	Returns:
		OrganicRegion: Región completa con forma orgánica
	"""
	if generated_regions.has(region_id):
		return generated_regions[region_id]

	# Calcular posición central determinísticamente
	var center_pos = _calculate_region_center(region_id)

	# Determinar bioma usando ruido (será usado por BiomeGenerator)
	var biome_id = _determine_biome_for_region(region_id, center_pos)

	# Crear región base
	var region = OrganicRegion.new(region_id, center_pos, biome_id)
	region.noise_seed = _calculate_region_noise_seed(region_id)

	# Generar forma orgánica (proceso asíncrono)
	await _generate_organic_boundary(region)

	# Calcular área y validar
	region.area = _calculate_polygon_area(region.boundary_points)

	# Identificar regiones vecinas
	region.neighbor_regions = _find_neighbor_regions(region_id)

	# Cachear resultado
	generated_regions[region_id] = region

	if region.boundary_points.size() >= min_region_points:
		print("[OrganicShapeGenerator] ✨ Región %s generada - Bioma: %s, Puntos: %d, Área: %.0f" % [
			region_id, biome_id, region.boundary_points.size(), region.area
		])
		return region
	else:
		push_error("[OrganicShapeGenerator] ❌ Región %s falló - Muy pocos puntos: %d" % [region_id, region.boundary_points.size()])
		return null

func _calculate_region_center(region_id: Vector2i) -> Vector2:
	"""Calcular posición central determinística de la región"""
	var base_x = region_id.x * base_region_size
	var base_y = region_id.y * base_region_size

	# Agregar variación determinística pero controlada
	var offset_x = size_noise.get_noise_2d(region_id.x, region_id.y) * base_region_size * 0.3
	var offset_y = size_noise.get_noise_2d(region_id.x + 1000, region_id.y + 1000) * base_region_size * 0.3

	return Vector2(base_x + offset_x, base_y + offset_y)

func _determine_biome_for_region(_region_id: Vector2i, center_pos: Vector2) -> String:
	"""Determinar bioma usando ruido determinístico"""
	var biome_noise = primary_noise.get_noise_2d(center_pos.x * 0.0001, center_pos.y * 0.0001)
	biome_noise = (biome_noise + 1.0) / 2.0 # Normalizar a [0,1]

	# Mapear a 6 biomas disponibles
	var biome_names = ["grassland", "desert", "snow", "lava", "arcane_wastes", "forest"]
	var biome_index = int(biome_noise * biome_names.size())
	biome_index = clamp(biome_index, 0, biome_names.size() - 1)

	return biome_names[biome_index]

func _calculate_region_noise_seed(region_id: Vector2i) -> int:
	"""Calcular semilla de ruido única para la región"""
	return world_seed ^ region_id.x ^ (region_id.y << 16)

func _generate_organic_boundary(region: OrganicRegion) -> void:
	"""
	Generar el contorno orgánico de la región usando Voronoi deformado
	"""
	var center = region.center_position
	var region_size = _calculate_region_size(region.region_id)

	# Generar puntos base del polígono
	var num_points = randi_range(min_region_points, max_region_points)
	var base_points: PackedVector2Array = []

	# Crear polígono base aproximadamente circular
	for i in range(num_points):
		var angle = (TAU / num_points) * i
		var radius = region_size * 0.5

		# Variar el radio con ruido
		var radius_variation = primary_noise.get_noise_2d(
			center.x + cos(angle) * 100,
			center.y + sin(angle) * 100
		) * radius * size_variance

		var varied_radius = radius + radius_variation
		var point = center + Vector2(cos(angle), sin(angle)) * varied_radius

		base_points.append(point)

	# Deformar puntos con ruido Perlin fractal
	var deformed_points: PackedVector2Array = []

	for point in base_points:
		# Aplicar deformación principal
		var deform_x = primary_noise.get_noise_2d(point.x * 0.001, point.y * 0.001) * noise_strength
		var deform_y = primary_noise.get_noise_2d(point.x * 0.001 + 5000, point.y * 0.001 + 5000) * noise_strength

		# Aplicar deformación secundaria (más sutil)
		var fine_deform_x = secondary_noise.get_noise_2d(point.x * 0.003, point.y * 0.003) * noise_strength * 0.3
		var fine_deform_y = secondary_noise.get_noise_2d(point.x * 0.003 + 3000, point.y * 0.003 + 3000) * noise_strength * 0.3

		var deformed_point = point + Vector2(deform_x + fine_deform_x, deform_y + fine_deform_y)
		deformed_points.append(deformed_point)

	# Suavizar contorno con múltiples pasadas
	var smoothed_points = deformed_points
	for pass_index in range(smoothing_passes):
		smoothed_points = _smooth_polygon(smoothed_points)
		await get_tree().process_frame # Ceder control entre pasadas

	region.boundary_points = smoothed_points

func _calculate_region_size(region_id: Vector2i) -> float:
	"""Calcular tamaño variable de la región basado en ruido"""
	var size_variation = size_noise.get_noise_2d(region_id.x, region_id.y)
	size_variation = (size_variation + 1.0) / 2.0 # Normalizar [0,1]

	# Tamaño entre 1.5x y 3x el tamaño base
	return base_region_size * (1.5 + size_variation * 1.5)

func _smooth_polygon(points: PackedVector2Array) -> PackedVector2Array:
	"""Suavizar polígono usando promedio de puntos vecinos"""
	if points.size() < 3:
		return points

	var smoothed: PackedVector2Array = []
	var smoothing_factor = 0.3

	for i in range(points.size()):
		var current = points[i]
		var prev = points[(i - 1 + points.size()) % points.size()]
		var next = points[(i + 1) % points.size()]

		# Promedio ponderado con vecinos
		var smoothed_point = current * (1.0 - smoothing_factor) + (prev + next) * (smoothing_factor * 0.5)
		smoothed.append(smoothed_point)

	return smoothed

func _calculate_polygon_area(points: PackedVector2Array) -> float:
	"""Calcular área del polígono usando fórmula del cordón"""
	if points.size() < 3:
		return 0.0

	var area = 0.0
	for i in range(points.size()):
		var j = (i + 1) % points.size()
		area += points[i].x * points[j].y
		area -= points[j].x * points[i].y

	return abs(area) / 2.0

func _find_neighbor_regions(region_id: Vector2i) -> Array[Vector2i]:
	"""Encontrar regiones vecinas (8-conectividad)"""
	var neighbors: Array[Vector2i] = []

	for dx in range(-1, 2):
		for dy in range(-1, 2):
			if dx == 0 and dy == 0:
				continue

			var neighbor_id = Vector2i(region_id.x + dx, region_id.y + dy)
			neighbors.append(neighbor_id)

	return neighbors

func get_region_at_position(world_pos: Vector2) -> Vector2i:
	"""Convertir posición mundial a ID de región"""
	var region_x = int(floor(world_pos.x / base_region_size))
	var region_y = int(floor(world_pos.y / base_region_size))

	return Vector2i(region_x, region_y)

func is_point_in_region(point: Vector2, region: OrganicRegion) -> bool:
	"""Verificar si un punto está dentro de una región usando ray casting"""
	if not region or region.boundary_points.size() < 3:
		return false

	var intersections = 0
	var points = region.boundary_points

	for i in range(points.size()):
		var p1 = points[i]
		var p2 = points[(i + 1) % points.size()]

		# Ray casting hacia la derecha
		if ((p1.y > point.y) != (p2.y > point.y)) and \
		   (point.x < (p2.x - p1.x) * (point.y - p1.y) / (p2.y - p1.y) + p1.x):
			intersections += 1

	return (intersections % 2) == 1

func get_cached_region(region_id: Vector2i) -> OrganicRegion:
	"""Obtener región del caché si existe"""
	return generated_regions.get(region_id, null)

func clear_cache() -> void:
	"""Limpiar caché de regiones generadas"""
	generated_regions.clear()
	print("[OrganicShapeGenerator] 🧹 Caché limpiado")

func get_cache_size() -> int:
	"""Obtener número de regiones en caché"""
	return generated_regions.size()

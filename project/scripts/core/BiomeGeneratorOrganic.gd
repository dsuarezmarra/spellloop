# BiomeGeneratorOrganic.gd
# Generador de biomas con regiones MASIVAS y bordes IRREGULARES
# Técnica: Voronoi (regiones base) + Simplex (distorsión de bordes)
# Sistema mejorado: chunks 15000×15000 con múltiples biomas orgánicos por chunk

extends Node
class_name BiomeGeneratorOrganic

# ========== DEFINICIÓN DE BIOMAS ==========
enum BiomeType {
	GRASSLAND,      # 0: Césped verde
	DESERT,         # 1: Arena/desierto
	SNOW,           # 2: Hielo/nieve
	LAVA,           # 3: Volcán/lava
	ARCANE_WASTES,  # 4: Tierras mágicas
	FOREST          # 5: Bosque denso
}

# Mapeo de BiomeType a nombres de carpetas (debe coincidir con estructura de assets/)
const BIOME_NAMES = {
	BiomeType.GRASSLAND: "Grassland",
	BiomeType.DESERT: "Desert",
	BiomeType.SNOW: "Snow",
	BiomeType.LAVA: "Lava",
	BiomeType.ARCANE_WASTES: "ArcaneWastes",
	BiomeType.FOREST: "Forest",
}

# Colores de debug para visualización
const BIOME_COLORS = {
	BiomeType.GRASSLAND: Color(0.34, 0.68, 0.35, 1.0),
	BiomeType.DESERT: Color(0.87, 0.78, 0.6, 1.0),
	BiomeType.SNOW: Color(0.95, 0.95, 1.0, 1.0),
	BiomeType.LAVA: Color(0.4, 0.1, 0.05, 1.0),
	BiomeType.ARCANE_WASTES: Color(0.6, 0.3, 0.8, 1.0),
	BiomeType.FOREST: Color(0.15, 0.35, 0.15, 1.0),
}

# ========== NOISE GENERATORS ==========
var cellular_noise: FastNoiseLite = FastNoiseLite.new()  # Voronoi para regiones base
var distortion_noise: FastNoiseLite = FastNoiseLite.new()  # Simplex para distorsionar bordes

# ========== CONFIGURACIÓN ==========
@export var cellular_frequency: float = 0.000001  # Regiones GIGANTES ~1,000,000 px (10× más grande) - Pantalla=1920px, mínimo 4×pantalla=7680px
@export var cellular_jitter: float = 1.0          # Irregularidad máxima (1.0 = máximo caos)
@export var distortion_strength: float = 12000.0  # Fuerza de distorsión de bordes (px) - AUMENTADO para bordes más irregulares
@export var distortion_frequency: float = 0.00015  # Frecuencia del ruido de distorsión - MÁS BAJO = ondulaciones más grandes
@export var seed_value: int = 0                   # 0 = aleatorio cada vez
@export var debug_mode: bool = true

func _ready() -> void:
	"""Inicializar generador de biomas orgánicos con Voronoi + distorsión"""
	_initialize_noise_generator()
	print("[BiomeGeneratorOrganic] ✅ Inicializado con Voronoi + distorsión Simplex (bordes irregulares)")

func _initialize_noise_generator() -> void:
	"""
	Configurar FastNoiseLite para generar regiones Voronoi ENORMES e irregulares

	TIPO: TYPE_CELLULAR (Voronoi/Worley noise)
	- Crea regiones irregulares naturales masivas
	- Cada región tiene un valor uniforme
	- Los bordes son orgánicos y suaves (no rectos)

	CELLULAR_DISTANCE_FUNCTION: DISTANCE_EUCLIDEAN
	- Distancia euclidiana estándar (círculos)
	- Produce formas naturales, irregulares y orgánicas
	- Más caótico y menos geométrico que HYBRID

	CELLULAR_RETURN_TYPE: RETURN_CELL_VALUE
	- Retorna valor único por celda Voronoi
	- Perfecto para asignar bioma por región

	FREQUENCY: 0.000001
	- Regiones de ~1,000,000 px de diámetro (GIGANTES)
	- Pantalla = 1920px, mínimo bioma = 4× pantalla = 7,680px
	- Con chunks 15000×15000, la mayoría de chunks tendrán 1 solo bioma
	"""

	# Configurar seed aleatorio o fijo
	var main_seed: int
	if seed_value == 0:
		randomize()
		main_seed = randi()
		if debug_mode:
			print("[BiomeGeneratorOrganic] 🎲 Seed aleatorio: %d" % main_seed)
	else:
		main_seed = seed_value
		if debug_mode:
			print("[BiomeGeneratorOrganic] 🔒 Seed fijo: %d" % main_seed)

	# ========== CONFIGURAR VORONOI (Regiones base) ==========
	cellular_noise.seed = main_seed
	cellular_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	cellular_noise.frequency = cellular_frequency  # Regiones enormes

	# Función de distancia: EUCLIDEAN para formas naturales
	cellular_noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN

	# Tipo de retorno: CELL_VALUE para regiones uniformes
	cellular_noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE

	# Jitter: máxima irregularidad
	cellular_noise.cellular_jitter = cellular_jitter

	# Sin Domain Warp en Voronoi
	cellular_noise.domain_warp_enabled = false

	# ========== CONFIGURAR SIMPLEX (Distorsión de bordes) ==========
	distortion_noise.seed = main_seed + 1000  # Seed diferente para independencia
	distortion_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	distortion_noise.frequency = distortion_frequency
	distortion_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	distortion_noise.fractal_octaves = 4  # Múltiples escalas de distorsión
	distortion_noise.fractal_lacunarity = 2.0
	distortion_noise.fractal_gain = 0.5

	if debug_mode:
		print("[BiomeGeneratorOrganic] 🔧 Configuración Voronoi:")
		print("  - Frequency: %.6f (regiones ~%.0f px = %.1f pantallas)" % [
			cellular_frequency, 
			1.0 / cellular_frequency,
			(1.0 / cellular_frequency) / 1920.0
		])
		print("  - Jitter: %.2f (máximo caos/irregularidad)" % cellular_jitter)
		print("  - Distance: EUCLIDEAN (formas naturales)")
		print("[BiomeGeneratorOrganic] 🌊 Configuración Distorsión:")
		print("  - Strength: %.0f px (cantidad de distorsión)" % distortion_strength)
		print("  - Frequency: %.6f (escala del ruido)" % distortion_frequency)
		print("  - Octaves: 4 (detalle multi-escala)")

func get_biome_at_world_position(world_x: float, world_y: float) -> int:
	"""
	Obtener bioma en una posición específica del mundo usando Voronoi + distorsión.

	Args:
		world_x: Coordenada X en píxeles del mundo
		world_y: Coordenada Y en píxeles del mundo

	Returns:
		BiomeType (int 0-5): Tipo de bioma en esa posición

	FUNCIONAMIENTO:
	1. Calcular distorsión usando ruido Simplex
	2. Aplicar distorsión a las coordenadas (hace bordes irregulares/escalonados)
	3. Obtener valor Voronoi en coordenadas distorsionadas → [-1.0, 1.0]
	4. Normalizar a [0.0, 1.0]
	5. Mapear a [0, 5] (6 biomas)

	La distorsión crea bordes orgánicos irregulares sin suavizar la transición
	"""
	# PASO 1: Calcular offset de distorsión usando ruido Simplex
	var distortion_x = distortion_noise.get_noise_2d(world_x, world_y) * distortion_strength
	var distortion_y = distortion_noise.get_noise_2d(world_x + 5000, world_y + 5000) * distortion_strength

	# PASO 2: Aplicar distorsión a las coordenadas (esto hace los bordes irregulares)
	var distorted_x = world_x + distortion_x
	var distorted_y = world_y + distortion_y

	# PASO 3: Obtener valor Voronoi en coordenadas distorsionadas
	var noise_value = cellular_noise.get_noise_2d(distorted_x, distorted_y)

	# PASO 4: Normalizar de [-1.0, 1.0] a [0.0, 1.0]
	var normalized = (noise_value + 1.0) / 2.0
	normalized = clamp(normalized, 0.0, 1.0)

	# Mapear a índice de bioma [0, 5]
	var biome_index = int(normalized * BiomeType.size())
	biome_index = clamp(biome_index, 0, BiomeType.size() - 1)

	return biome_index

func get_biome_name_at_world_position(world_x: float, world_y: float) -> String:
	"""
	Obtener nombre del bioma en una posición específica.
	Útil para debug y logs.
	"""
	var biome_type = get_biome_at_world_position(world_x, world_y)
	return BIOME_NAMES[biome_type]

func generate_chunk_async(chunk_node: Node2D, chunk_pos: Vector2i, rng: RandomNumberGenerator) -> void:
	"""
	Generar chunk con múltiples biomas orgánicos.

	NUEVO SISTEMA:
	- Chunk puede contener MÚLTIPLES biomas (no uno solo)
	- Cada posición dentro del chunk tiene su propio bioma
	- BiomeChunkApplier se encargará de aplicar texturas correctas

	Args:
		chunk_node: Nodo del chunk (Node2D)
		chunk_pos: Coordenadas del chunk en grid
		rng: RandomNumberGenerator (no se usa en Voronoi, pero se mantiene para compatibilidad)
	"""

	# NO crear fondo uniforme (cada píxel puede ser bioma diferente)
	# BiomeChunkApplier manejará la aplicación de texturas multi-bioma

	# Guardar metadatos del chunk
	chunk_node.set_meta("biome_system", "organic_voronoi")
	chunk_node.set_meta("chunk_pos", chunk_pos)

	# Detectar qué biomas están presentes en este chunk (para optimización)
	var biomes_in_chunk = _detect_biomes_in_chunk(chunk_node, chunk_pos)
	chunk_node.set_meta("biomes_present", biomes_in_chunk)

	if debug_mode:
		var biome_names = []
		for biome_type in biomes_in_chunk:
			biome_names.append(BIOME_NAMES[biome_type])
		print("[BiomeGeneratorOrganic] ✨ Chunk %s contiene biomas: %s" % [chunk_pos, biome_names])

func _detect_biomes_in_chunk(chunk_node: Node2D, chunk_pos: Vector2i) -> Array[int]:
	"""
	Detectar qué biomas están presentes en un chunk mediante muestreo.

	OPTIMIZACIÓN: En lugar de verificar cada píxel (15000×15000 = 225M píxeles),
	muestreamos una grid de 8×8 = 64 puntos.

	Returns:
		Array[int]: Lista de BiomeType únicos presentes en el chunk
	"""
	var chunk_width = 15000
	var chunk_height = 15000
	var sample_grid_size = 8  # Muestreo 8×8 = 64 puntos

	# Calcular posición mundial del chunk
	var chunk_world_x = chunk_pos.x * chunk_width
	var chunk_world_y = chunk_pos.y * chunk_height

	var biomes_found = {}  # Dictionary para evitar duplicados

	# Muestrear grid
	var step_x = chunk_width / float(sample_grid_size)
	var step_y = chunk_height / float(sample_grid_size)

	for gy in range(sample_grid_size):
		for gx in range(sample_grid_size):
			var sample_x = chunk_world_x + (gx * step_x) + (step_x / 2.0)
			var sample_y = chunk_world_y + (gy * step_y) + (step_y / 2.0)

			var biome = get_biome_at_world_position(sample_x, sample_y)
			biomes_found[biome] = true

	# Convertir a Array
	var result: Array[int] = []
	for biome in biomes_found.keys():
		result.append(biome)

	return result

func generate_chunk_from_cache(chunk_node: Node2D, chunk_data: Dictionary) -> void:
	"""
	Recrear chunk desde caché.

	Con sistema orgánico, no necesitamos guardar geometría específica
	porque los biomas se calculan determinísticamente desde Voronoi.
	Solo necesitamos la posición del chunk.
	"""
	var chunk_pos = chunk_data.get("chunk_pos", Vector2i.ZERO)
	chunk_node.set_meta("biome_system", "organic_voronoi")
	chunk_node.set_meta("chunk_pos", chunk_pos)

	# Re-detectar biomas (muy rápido, solo 64 muestras)
	var biomes_in_chunk = _detect_biomes_in_chunk(chunk_node, chunk_pos)
	chunk_node.set_meta("biomes_present", biomes_in_chunk)

	if debug_mode:
		print("[BiomeGeneratorOrganic] 📂 Chunk %s restaurado del caché" % chunk_pos)

func get_biome_color_at_world_position(world_x: float, world_y: float) -> Color:
	"""
	Obtener color del bioma en una posición (útil para debug/visualización).
	"""
	var biome_type = get_biome_at_world_position(world_x, world_y)
	return BIOME_COLORS[biome_type]

# ========== UTILIDADES DE DEBUG ==========

func visualize_chunk_biomes(chunk_node: Node2D, chunk_pos: Vector2i, resolution: int = 100) -> void:
	"""
	Crear visualización de debug mostrando los biomas en el chunk.

	Args:
		chunk_node: Nodo del chunk
		chunk_pos: Posición del chunk
		resolution: Cuántos píxeles por sample (100 = 150×150 píxeles de debug)
	"""
	if not debug_mode:
		return

	var chunk_width = 15000
	var chunk_height = 15000
	var chunk_world_x = chunk_pos.x * chunk_width
	var chunk_world_y = chunk_pos.y * chunk_height

	var debug_layer = Node2D.new()
	debug_layer.name = "BiomeDebugVisualization"
	debug_layer.z_index = 100  # Arriba de todo
	chunk_node.add_child(debug_layer)

	var samples_x = chunk_width / resolution
	var samples_y = chunk_height / resolution

	for sy in range(samples_y):
		for sx in range(samples_x):
			var world_x = chunk_world_x + (sx * resolution) + (resolution / 2)
			var world_y = chunk_world_y + (sy * resolution) + (resolution / 2)

			var biome = get_biome_at_world_position(world_x, world_y)
			var color = BIOME_COLORS[biome]

			# Crear ColorRect pequeño
			var rect = ColorRect.new()
			rect.color = color
			rect.size = Vector2(resolution, resolution)
			rect.position = Vector2(sx * resolution, sy * resolution)
			debug_layer.add_child(rect)

	print("[BiomeGeneratorOrganic] 🎨 Visualización de debug creada para chunk %s" % chunk_pos)

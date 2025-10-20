# BiomeGenerator.gd
# Generador de biomas con decoraciones procedurales y transiciones suaves
# Soporta 6 biomas: Grassland, Desert, Snow, Lava, Arcane Wastes, Forest

extends Node
class_name BiomeGenerator

# Definición de biomas
enum BiomeType { GRASSLAND, DESERT, SNOW, LAVA, ARCANE_WASTES, FOREST }

const BIOME_COLORS = {
	BiomeType.GRASSLAND: Color(0.34, 0.68, 0.35, 1.0),      # Verde prado
	BiomeType.DESERT: Color(0.87, 0.78, 0.6, 1.0),          # Arena amarilla
	BiomeType.SNOW: Color(0.95, 0.95, 1.0, 1.0),            # Nieve blanca/azul
	BiomeType.LAVA: Color(0.4, 0.1, 0.05, 1.0),             # Rojo oscuro/incandescente
	BiomeType.ARCANE_WASTES: Color(0.6, 0.3, 0.8, 1.0),     # Violeta mágico
	BiomeType.FOREST: Color(0.15, 0.35, 0.15, 1.0),         # Verde oscuro
}

const BIOME_NAMES = {
	BiomeType.GRASSLAND: "grassland",
	BiomeType.DESERT: "desert",
	BiomeType.SNOW: "snow",
	BiomeType.LAVA: "lava",
	BiomeType.ARCANE_WASTES: "arcane_wastes",
	BiomeType.FOREST: "forest",
}

# Configuración de decoraciones por bioma
const DECORATIONS_PER_BIOME = {
	BiomeType.GRASSLAND: ["bush", "flower", "tree_small"],
	BiomeType.DESERT: ["cactus", "rock", "sand_spike"],
	BiomeType.SNOW: ["ice_crystal", "snow_mound", "frozen_rock"],
	BiomeType.LAVA: ["lava_rock", "fire_spike", "magma_vent"],
	BiomeType.ARCANE_WASTES: ["rune_stone", "arcane_crystal", "void_spike"],
	BiomeType.FOREST: ["tree", "bush_dense", "fallen_log"],
}

# Configuración de densidad de decoraciones
const DECORATION_DENSITY = 0.25  # 25% de cobertura (aumentado de 15%)

# Ruido perlin para variaciones (si se genera proceduralmente)
var noise: FastNoiseLite = FastNoiseLite.new()

func _ready() -> void:
	"""Inicializar generador de biomas"""
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.01
	print("[BiomeGenerator] ✅ Inicializado")

func generate_chunk_async(chunk_node: Node2D, chunk_pos: Vector2i, rng: RandomNumberGenerator):
	"""Generar un chunk de forma asíncrona (sin bloquear)"""
	# Elegir bioma
	var biome_type = _select_biome(chunk_pos, rng)
	chunk_node.set_meta("biome_type", BIOME_NAMES[biome_type])
	
	# Generar fondo (placeholder simple)
	_create_biome_background(chunk_node, biome_type)
	
	# Generar decoraciones (asincronamente)
	if biome_type >= 0 and biome_type < DECORATIONS_PER_BIOME.keys().size():
		await _generate_decorations_async(chunk_node, chunk_pos, biome_type, rng)
	
	# Generar transiciones con biomas vecinos
	_generate_biome_transitions(chunk_node, chunk_pos, biome_type, rng)

func generate_chunk_from_cache(chunk_node: Node2D, chunk_data: Dictionary) -> void:
	"""Recrear un chunk desde datos en caché"""
	var biome_name = chunk_data.get("biome", "grassland")
	
	# Recrear fondo
	var biome_type = _biome_name_to_type(biome_name)
	_create_biome_background(chunk_node, biome_type)

func _select_biome(chunk_pos: Vector2i, rng: RandomNumberGenerator) -> int:
	"""Seleccionar bioma según posición (determinístico con semilla)"""
	# Usar ruido perlin para que biomas sean contiguos y no aleatorios puro
	var noise_val = noise.get_noise_2d(chunk_pos.x, chunk_pos.y)
	
	# Normalizar ruido a 0-1
	noise_val = (noise_val + 1.0) / 2.0
	noise_val = clamp(noise_val, 0.0, 1.0)
	
	# Mapear a bioma
	var biome_index = int(noise_val * BiomeType.size())
	return clamp(biome_index, 0, BiomeType.size() - 1)

func _biome_name_to_type(name: String) -> int:
	"""Convertir nombre de bioma a tipo"""
	for biome_type in BIOME_NAMES.keys():
		if BIOME_NAMES[biome_type] == name:
			return biome_type
	return BiomeType.GRASSLAND

func _create_biome_background(chunk_node: Node2D, biome_type: int) -> void:
	"""Crear fondo visual del bioma (ColorRect simple)"""
	var bg = ColorRect.new()
	bg.name = "BiomeBackground"
	bg.color = BIOME_COLORS[biome_type]
	bg.size = Vector2(5760, 3240)
	bg.z_index = -10
	chunk_node.add_child(bg)

func _generate_decorations_async(chunk_node: Node2D, chunk_pos: Vector2i, biome_type: int, rng: RandomNumberGenerator):
	"""Generar decoraciones asincronamente"""
	var decorations = DECORATIONS_PER_BIOME.get(biome_type, [])
	if decorations.is_empty():
		return
	
	var chunk_area = 5760 * 3240
	var target_count = int(chunk_area * DECORATION_DENSITY / (32 * 32))  # Asumiendo ~32x32 por decoración
	
	var decorations_root = Node2D.new()
	decorations_root.name = "Decorations"
	chunk_node.add_child(decorations_root)
	
	for i in range(target_count):
		# Diferir la creación cada pocas decoraciones para no bloquear
		if i % 10 == 0:
			await get_tree().process_frame
		
		var deco_type = decorations[rng.randi() % decorations.size()]
		var pos_x = rng.randf() * 5760
		var pos_y = rng.randf() * 3240
		
		_create_decoration(decorations_root, deco_type, Vector2(pos_x, pos_y), biome_type)

func _create_decoration(parent: Node2D, deco_type: String, pos: Vector2, biome_type: int) -> void:
	"""Crear una decoración individual (solo visual, sin colisión)"""
	var deco = Node2D.new()
	deco.name = deco_type
	deco.position = pos
	deco.z_index = -5  # Atrás de enemigos/jugador
	
	# Tamaño según tipo
	var scale_val = 1.0
	var color = BIOME_COLORS[biome_type]
	match deco_type:
		"bush", "bush_dense", "cactus":
			scale_val = 0.5
		"tree", "tree_small":
			scale_val = 0.7
		"rock", "ice_crystal", "rune_stone":
			scale_val = 0.3
		_:
			scale_val = 0.4
	
	# Crear polígono visual (decoración dibujada)
	var polygon = Polygon2D.new()
	polygon.color = color.lightened(0.2)
	polygon.z_index = 0  # Asegurar que tenga z_index
	
	# Generar puntos según el tipo de decoración
	var points = _get_decoration_shape(deco_type, scale_val)
	polygon.polygon = points
	
	# Agregar un borde para mayor visibilidad
	var outline_color = color.darkened(0.3)
	
	# Crear línea alrededor del polígono
	var line = Line2D.new()
	line.default_color = outline_color
	line.width = 1.0
	line.z_index = 1  # Encima del polígono
	
	# Copiar puntos para la línea
	for point in points:
		line.add_point(point)
	line.add_point(points[0])  # Cerrar la línea
	
	deco.add_child(polygon)
	deco.add_child(line)
	parent.add_child(deco)

func _get_decoration_shape(deco_type: String, scale: float) -> PackedVector2Array:
	"""Generar puntos para forma de decoración"""
	var size = 16.0 * scale
	var points = PackedVector2Array()
	
	match deco_type:
		"bush", "bush_dense", "cactus":
			# Forma de rombo
			points.append(Vector2(0, -size))
			points.append(Vector2(size, 0))
			points.append(Vector2(0, size))
			points.append(Vector2(-size, 0))
		
		"tree", "tree_small":
			# Triángulo (árbol)
			points.append(Vector2(0, -size))
			points.append(Vector2(size/2, size/2))
			points.append(Vector2(-size/2, size/2))
		
		"rock", "rune_stone", "lava_rock":
			# Forma irregular (roca)
			points.append(Vector2(size/2, -size/2))
			points.append(Vector2(size, 0))
			points.append(Vector2(size/2, size))
			points.append(Vector2(-size/2, size))
			points.append(Vector2(-size, 0))
			points.append(Vector2(-size/2, -size/2))
		
		"ice_crystal", "arcane_crystal":
			# Forma de estrella
			for i in range(8):
				var angle = (TAU / 8) * i
				var radius = size if i % 2 == 0 else size / 2
				points.append(Vector2(cos(angle) * radius, sin(angle) * radius))
		
		"flower":
			# Forma de flor (pequeño círculo)
			for i in range(6):
				var angle = (TAU / 6) * i
				points.append(Vector2(cos(angle) * size, sin(angle) * size))
		
		"sand_spike", "fire_spike", "void_spike":
			# Forma puntiaguda
			points.append(Vector2(0, -size))
			points.append(Vector2(size/3, size))
			points.append(Vector2(-size/3, size))
		
		"snow_mound", "frozen_rock":
			# Montículo
			points.append(Vector2(-size, 0))
			points.append(Vector2(0, -size/2))
			points.append(Vector2(size, 0))
			points.append(Vector2(0, size/2))
		
		_:
			# Círculo por defecto
			for i in range(8):
				var angle = (TAU / 8) * i
				points.append(Vector2(cos(angle) * size, sin(angle) * size))
	
	return points

func _generate_biome_transitions(chunk_node: Node2D, _chunk_pos: Vector2i, _biome_type: int, _rng: RandomNumberGenerator) -> void:
	"""Generar transiciones visuales con biomas vecinos (bordes suavizados)"""
	# TODO: Implementar gradientes en bordes para suavizar transiciones
	# Por ahora, solo una implementación simple
	
	# Crear overlay de transición en bordes (opcional)
	var transition_root = Node2D.new()
	transition_root.name = "Transitions"
	chunk_node.add_child(transition_root)

func get_biome_info(biome_type: int) -> Dictionary:
	"""Obtener información de un bioma"""
	return {
		"name": BIOME_NAMES.get(biome_type, "unknown"),
		"color": BIOME_COLORS.get(biome_type, Color.WHITE),
		"decorations": DECORATIONS_PER_BIOME.get(biome_type, [])
	}

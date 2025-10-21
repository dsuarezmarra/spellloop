# OrganicBiomeTransition.gd
# Sistema de transiciones orgánicas entre biomas
# Usa ruido Perlin para crear bordes fluidos y naturales

extends Node
class_name OrganicBiomeTransition

"""
🌊 ORGANIC BIOME TRANSITIONS - Sistema de Transiciones Fluidas
=============================================================

Este sistema reemplaza las divisiones cuadriculadas de chunks por:
- Transiciones suaves y graduales basadas en ruido Perlin
- Bordes orgánicos que se entremezclan naturalmente  
- Zonas de transición del 15% del chunk (864 píxeles)
- Generación completamente aleatoria sin restricciones

Configuración:
- Transiciones suaves usando smoothstep y Simplex Smooth
- Sin sistema de afinidades - todos los biomas pueden conectarse
- Edge roughness reducido para bordes más fluidos
- Fractal octaves optimizado para suavidad
"""

# Configuración de ruido
@export var transition_noise: FastNoiseLite = FastNoiseLite.new()
@export var detail_noise: FastNoiseLite = FastNoiseLite.new() 
@export var biome_scale: float = 0.002  # Escala del ruido principal (más pequeño = biomas más grandes)
@export var transition_width: float = 864.0  # 15% del chunk (5760 * 0.15) - zona de transición suave
@export var edge_roughness: float = 0.3  # Transiciones más suaves (reducido de 0.5)

# Sin sistema de afinidades - generación completamente aleatoria

func _ready() -> void:
	"""Inicializar sistema de transiciones orgánicas"""
	_setup_noise()
	print("[OrganicBiomeTransition] ✅ Sistema inicializado")

func _setup_noise() -> void:
	"""Configurar ruido Perlin para transiciones orgánicas suaves"""
	# Ruido principal para forma general de biomas - más suave
	transition_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	transition_noise.frequency = biome_scale
	transition_noise.fractal_octaves = 3  # Reducido para transiciones más suaves
	transition_noise.fractal_lacunarity = 1.8  # Menos agresivo
	transition_noise.fractal_gain = 0.4  # Más suave
	
	# Ruido de detalle para bordes suaves con variación sutil
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH  
	detail_noise.frequency = biome_scale * 6.0  # Menos detalle agresivo
	detail_noise.fractal_octaves = 2  # Simplificado
	detail_noise.fractal_lacunarity = 1.5  # Más suave
	detail_noise.fractal_gain = 0.2  # Muy sutil

func get_biome_at_position(world_pos: Vector2) -> String:
	"""Obtener el bioma predominante en una posición mundial"""
	var biome_values = _calculate_biome_influences(world_pos)
	
	# Encontrar el bioma con mayor influencia
	var max_influence = 0.0
	var dominant_biome = "grassland"
	
	for biome in biome_values.keys():
		if biome_values[biome] > max_influence:
			max_influence = biome_values[biome]
			dominant_biome = biome
	
	return dominant_biome

func get_biome_transition_data(world_pos: Vector2) -> Dictionary:
	"""
	Obtener datos de transición para una posición (para blending de texturas)
	Returns: {"primary_biome": String, "secondary_biome": String, "blend_factor": float}
	"""
	var biome_influences = _calculate_biome_influences(world_pos)
	
	# Ordenar biomas por influencia
	var sorted_biomes = []
	for biome in biome_influences.keys():
		sorted_biomes.append({"name": biome, "influence": biome_influences[biome]})
	
	sorted_biomes.sort_custom(func(a, b): return a.influence > b.influence)
	
	var primary = sorted_biomes[0]
	var secondary = sorted_biomes[1] if sorted_biomes.size() > 1 else primary
	
	# Calcular factor de blend más suave y gradual
	var influence_diff = primary.influence - secondary.influence
	
	# Usar función smoothstep para transiciones más graduales
	var blend_factor = 1.0 - smoothstep(0.0, 0.8, influence_diff)  # Transición más extendida
	
	return {
		"primary_biome": primary.name,
		"secondary_biome": secondary.name, 
		"blend_factor": blend_factor,
		"is_transition": blend_factor > 0.05  # Umbral más bajo para transiciones más extensas
	}

func _calculate_biome_influences(world_pos: Vector2) -> Dictionary:
	"""Calcular la influencia de cada bioma en una posición específica"""
	var influences = {}
	var biomes = ["grassland", "forest", "desert", "snow", "lava", "arcane_wastes"]
	
	# Usar diferentes offsets para cada bioma para crear variación
	var offsets = {
		"grassland": Vector2(0, 0),
		"forest": Vector2(1000, 0), 
		"desert": Vector2(0, 1000),
		"snow": Vector2(1000, 1000),
		"lava": Vector2(2000, 0),
		"arcane_wastes": Vector2(0, 2000)
	}
	
	for biome in biomes:
		var offset = offsets.get(biome, Vector2.ZERO)
		var noise_pos = world_pos + offset
		
		# Ruido base
		var base_value = transition_noise.get_noise_2d(noise_pos.x, noise_pos.y)
		
		# Añadir detalle para bordes irregulares
		var detail_value = detail_noise.get_noise_2d(noise_pos.x, noise_pos.y)
		var combined = base_value + (detail_value * edge_roughness * 0.3)
		
		# Normalizar a 0-1
		influences[biome] = (combined + 1.0) / 2.0
	
	# Sin sistema de afinidades - todas las combinaciones son válidas
	return influences

func generate_transition_mask(world_pos: Vector2, size: Vector2) -> ImageTexture:
	"""Generar máscara de transición para blending de texturas en un área"""
	var image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	
	for y in range(int(size.y)):
		for x in range(int(size.x)):
			var pixel_world_pos = world_pos + Vector2(x, y)
			var transition_data = get_biome_transition_data(pixel_world_pos)
			
			# R: primary biome strength, G: secondary biome strength, B: blend factor
			var r = 1.0 - transition_data.blend_factor  
			var g = transition_data.blend_factor
			var b = transition_data.blend_factor if transition_data.is_transition else 0.0
			
			image.set_pixel(x, y, Color(r, g, b, 1.0))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func set_world_seed(world_seed: int) -> void:
	"""Establecer semilla para reproducibilidad"""
	transition_noise.seed = world_seed
	detail_noise.seed = world_seed + 1000  # Offset para el ruido de detalle

func get_debug_info(world_pos: Vector2) -> Dictionary:
	"""Obtener información de debug para una posición"""
	var transition_data = get_biome_transition_data(world_pos)
	var influences = _calculate_biome_influences(world_pos)
	
	return {
		"position": world_pos,
		"dominant_biome": get_biome_at_position(world_pos),
		"transition_data": transition_data,
		"all_influences": influences
	}
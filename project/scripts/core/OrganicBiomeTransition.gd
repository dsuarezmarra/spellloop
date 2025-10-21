# OrganicBiomeTransition.gd
# Sistema de transiciones orgánicas entre biomas
# Usa ruido Perlin para crear bordes fluidos y naturales

extends Node
class_name OrganicBiomeTransition

"""
🌊 ORGANIC BIOME TRANSITIONS - Sistema de Transiciones Fluidas
=============================================================

Este sistema reemplaza las divisiones cuadriculadas de chunks por:
- Transiciones suaves basadas en ruido Perlin
- Bordes orgánicos que se entremezclan naturalmente  
- Máscaras de transición para blending de texturas
- Generación continua por posición mundial

Técnicas:
1. Multi-octave Perlin noise para formas complejas
2. Distance fields para transiciones graduales
3. Texture blending en zonas de borde
4. Biome affinity system para transiciones realistas
"""

# Configuración de ruido
@export var transition_noise: FastNoiseLite = FastNoiseLite.new()
@export var detail_noise: FastNoiseLite = FastNoiseLite.new() 
@export var biome_scale: float = 0.002  # Escala del ruido principal (más pequeño = biomas más grandes)
@export var transition_width: float = 800.0  # Ancho de zona de transición en píxeles
@export var edge_roughness: float = 0.5  # 0.0 = suave, 1.0 = muy irregular

# Afinidades entre biomas (0.0 = incompatible, 1.0 = muy compatible)
const BIOME_AFFINITY = {
	["grassland", "forest"]: 0.9,
	["grassland", "desert"]: 0.3,
	["grassland", "snow"]: 0.4,
	["grassland", "lava"]: 0.1,
	["grassland", "arcane_wastes"]: 0.2,
	
	["forest", "snow"]: 0.6,
	["forest", "desert"]: 0.2,
	["forest", "lava"]: 0.1,
	["forest", "arcane_wastes"]: 0.3,
	
	["desert", "lava"]: 0.7,
	["desert", "snow"]: 0.1,
	["desert", "arcane_wastes"]: 0.4,
	
	["snow", "lava"]: 0.1,
	["snow", "arcane_wastes"]: 0.3,
	
	["lava", "arcane_wastes"]: 0.8,
}

func _ready() -> void:
	"""Inicializar sistema de transiciones orgánicas"""
	_setup_noise()
	print("[OrganicBiomeTransition] ✅ Sistema inicializado")

func _setup_noise() -> void:
	"""Configurar ruido Perlin para transiciones orgánicas"""
	# Ruido principal para forma general de biomas
	transition_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	transition_noise.frequency = biome_scale
	transition_noise.fractal_octaves = 4
	transition_noise.fractal_lacunarity = 2.0
	transition_noise.fractal_gain = 0.5
	
	# Ruido de detalle para bordes irregulares
	detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX  
	detail_noise.frequency = biome_scale * 8.0  # 8x más detallado
	detail_noise.fractal_octaves = 3
	detail_noise.fractal_lacunarity = 2.0
	detail_noise.fractal_gain = 0.3

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
	
	# Calcular factor de blend basado en la diferencia de influencias
	var influence_diff = primary.influence - secondary.influence
	var blend_factor = 1.0 - clamp(influence_diff, 0.0, 1.0)
	
	return {
		"primary_biome": primary.name,
		"secondary_biome": secondary.name, 
		"blend_factor": blend_factor,
		"is_transition": blend_factor > 0.1  # Umbral para considerar transición
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
	
	# Aplicar afinidades para suavizar transiciones no realistas
	influences = _apply_biome_affinities(influences, world_pos)
	
	return influences

func _apply_biome_affinities(influences: Dictionary, _world_pos: Vector2) -> Dictionary:
	"""Aplicar sistema de afinidades para hacer transiciones más realistas"""
	var adjusted = influences.duplicate()
	
	# Para cada bioma, reducir influencia de biomas incompatibles cercanos
	for biome_a in influences.keys():
		for biome_b in influences.keys():
			if biome_a == biome_b:
				continue
				
			var affinity = _get_biome_affinity(biome_a, biome_b)
			if affinity < 0.5:  # Biomas incompatibles
				# Reducir influencia mutua
				var reduction = (0.5 - affinity) * 0.3
				adjusted[biome_a] *= (1.0 - reduction)
	
	return adjusted

func _get_biome_affinity(biome_a: String, biome_b: String) -> float:
	"""Obtener afinidad entre dos biomas"""
	var key1 = [biome_a, biome_b]
	var key2 = [biome_b, biome_a]
	
	if BIOME_AFFINITY.has(key1):
		return BIOME_AFFINITY[key1]
	elif BIOME_AFFINITY.has(key2):
		return BIOME_AFFINITY[key2]
	else:
		return 0.5  # Afinidad neutra por defecto

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
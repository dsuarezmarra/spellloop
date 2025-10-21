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
var organic_transition: Node = null  # Sistema de transiciones orgánicas

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
	_setup_organic_transitions()
	print("[BiomeChunkApplier] ✓ Configuración cargada. Biomas disponibles: %d" % _config.get("biomes", []).size())

func _setup_organic_transitions() -> void:
	"""Configurar sistema de transiciones orgánicas"""
	if ResourceLoader.exists("res://scripts/core/OrganicBiomeTransition.gd"):
		var ot_script = load("res://scripts/core/OrganicBiomeTransition.gd")
		if ot_script:
			organic_transition = ot_script.new()
			organic_transition.name = "OrganicBiomeTransition"
			add_child(organic_transition)
			print("[BiomeChunkApplier] ✅ Sistema de transiciones orgánicas inicializado")

func set_world_seed(world_seed: int) -> void:
	"""Establecer semilla mundial para reproducibilidad"""
	if organic_transition and organic_transition.has_method("set_world_seed"):
		organic_transition.set_world_seed(world_seed)
		print("[BiomeChunkApplier] 🌱 Semilla establecida: %d" % world_seed)

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
	
	NUEVA FUNCIONALIDAD: Soporte para transiciones orgánicas entre biomas.
	Si está habilitado, detecta transiciones y aplica blending de texturas.
	"""
	# FORZAR DEBUG PARA DIAGNÓSTICO
	var original_debug = debug_mode
	debug_mode = true
	
	print("[BiomeChunkApplier] 🎨 INICIANDO aplicación de bioma a chunk (%d, %d)" % [cx, cy])
	
	# Crear contenedor para texturas (Node2D simple, no CanvasLayer)
	var biome_layer = Node2D.new()
	biome_layer.name = "BiomeLayer"
	biome_layer.z_index = -100  # MUY ATRÁS: debajo de TODO (enemigos, player, etc siempre visible)
	chunk_node.add_child(biome_layer)
	
	print("[BiomeChunkApplier] ✓ BiomeLayer creado y añadido a chunk")
	
	# Verificar si usar transiciones orgánicas o bioma tradicional por chunk
	if organic_transition and organic_transition.has_method("get_biome_transition_data"):
		print("[BiomeChunkApplier] 🌊 Usando sistema de transiciones orgánicas")
		_apply_organic_biome_transitions(biome_layer, chunk_node, cx, cy)
	else:
		print("[BiomeChunkApplier] 📦 Usando sistema tradicional (fallback)")
		# Fallback al sistema tradicional (un bioma por chunk)
		_apply_traditional_biome(biome_layer, chunk_node, cx, cy)
	
	# Restaurar debug original
	debug_mode = original_debug

func _apply_traditional_biome(biome_layer: Node2D, chunk_node: Node2D, cx: int, cy: int) -> void:
	"""Aplicar bioma tradicional (un bioma por chunk completo)"""
	var bioma_data = get_biome_for_position(cx, cy)
	
	if bioma_data.is_empty():
		printerr("[BiomeChunkApplier] ✗ No se pudo obtener bioma para (%d, %d)" % [cx, cy])
		return
	
	# Aplicar base + decoraciones
	_apply_textures_optimized(biome_layer, bioma_data, cx, cy)
	
	# Guardar metadatos
	chunk_node.set_meta("biome_name", bioma_data.get("name", "Unknown"))
	chunk_node.set_meta("biome_id", bioma_data.get("id", -1))
	
	if debug_mode:
		print("[BiomeChunkApplier] ✓ Bioma tradicional '%s' aplicado a chunk (%d, %d)" % [bioma_data.get("name"), cx, cy])
	
	biome_changed.emit(bioma_data.get("name", ""))

func _apply_organic_biome_transitions(biome_layer: Node2D, chunk_node: Node2D, cx: int, cy: int) -> void:
	"""Aplicar transiciones orgánicas de biomas dentro del chunk"""
	var chunk_world_pos = Vector2(cx * 5760, cy * 3240)
	var chunk_size = Vector2(5760, 3240)
	
	# Analizar el chunk para determinar biomas presentes y sus transiciones
	var biome_analysis = _analyze_chunk_biomes(chunk_world_pos, chunk_size)
	
	# Si solo hay un bioma dominante, usar aplicación tradicional optimizada
	if biome_analysis.is_uniform:
		var dominant_biome_data = _get_biome_data_by_name(biome_analysis.primary_biome)
		if not dominant_biome_data.is_empty():
			_apply_textures_optimized(biome_layer, dominant_biome_data, cx, cy)
			chunk_node.set_meta("biome_name", biome_analysis.primary_biome)
			if debug_mode:
				print("[BiomeChunkApplier] ✓ Bioma orgánico uniforme '%s' aplicado a chunk (%d, %d)" % [biome_analysis.primary_biome, cx, cy])
		else:
			print("[BiomeChunkApplier] ❌ No se pudo obtener datos para bioma '%s'" % biome_analysis.primary_biome)
	else:
		# Chunk con transiciones: aplicar blending orgánico complejo
		_apply_transition_blending(biome_layer, chunk_world_pos, chunk_size, biome_analysis)
		chunk_node.set_meta("biome_name", "%s→%s" % [biome_analysis.primary_biome, biome_analysis.secondary_biome])
		if debug_mode:
			print("[BiomeChunkApplier] 🎨 BLENDING ORGÁNICO: '%s→%s' en chunk (%d, %d) - Factor: %.2f" % [biome_analysis.primary_biome, biome_analysis.secondary_biome, cx, cy, biome_analysis.transition_factor])
	
	biome_changed.emit(chunk_node.get_meta("biome_name", "transition"))

# ========== APLICAR TEXTURAS OPTIMIZADAS ==========
func _analyze_chunk_biomes(chunk_world_pos: Vector2, chunk_size: Vector2) -> Dictionary:
	"""Analizar qué biomas están presentes en un chunk y sus proporciones"""
	if not organic_transition or not organic_transition.has_method("get_biome_transition_data"):
		return {"is_uniform": true, "primary_biome": "grassland", "secondary_biome": "grassland", "transition_factor": 0.0}
	
	# Tomar muestras en varios puntos del chunk para determinar composición
	var sample_points = [
		chunk_world_pos + Vector2(chunk_size.x * 0.2, chunk_size.y * 0.2),  # Top-left
		chunk_world_pos + Vector2(chunk_size.x * 0.8, chunk_size.y * 0.2),  # Top-right  
		chunk_world_pos + Vector2(chunk_size.x * 0.2, chunk_size.y * 0.8),  # Bottom-left
		chunk_world_pos + Vector2(chunk_size.x * 0.8, chunk_size.y * 0.8),  # Bottom-right
		chunk_world_pos + Vector2(chunk_size.x * 0.5, chunk_size.y * 0.5),  # Center
	]
	
	var biome_counts = {}
	var total_transition_factor = 0.0
	
	for point in sample_points:
		var transition_data = organic_transition.get_biome_transition_data(point)
		var primary_biome = transition_data.primary_biome
		var secondary_biome = transition_data.secondary_biome
		
		biome_counts[primary_biome] = biome_counts.get(primary_biome, 0) + 1
		if secondary_biome != primary_biome:
			biome_counts[secondary_biome] = biome_counts.get(secondary_biome, 0) + transition_data.blend_factor
		
		total_transition_factor += transition_data.blend_factor
	
	# Encontrar biomas dominantes
	var sorted_biomes = []
	for biome in biome_counts.keys():
		sorted_biomes.append({"name": biome, "count": biome_counts[biome]})
	sorted_biomes.sort_custom(func(a, b): return a.count > b.count)
	
	var primary = sorted_biomes[0].name if sorted_biomes.size() > 0 else "grassland"
	var secondary = sorted_biomes[1].name if sorted_biomes.size() > 1 else primary
	var avg_transition = total_transition_factor / sample_points.size()
	
	return {
		"is_uniform": avg_transition < 0.15,  # Solo 15% para más transiciones orgánicas visibles
		"primary_biome": primary,
		"secondary_biome": secondary, 
		"transition_factor": avg_transition
	}

func _get_biome_data_by_name(biome_name: String) -> Dictionary:
	"""Obtener datos de configuración de un bioma por nombre (procesados con rutas completas)"""
	var biomes = _config.get("biomes", [])
	for biome in biomes:
		if biome.get("name", "").to_lower() == biome_name.to_lower():
			# Procesar los datos igual que en get_biome_for_position
			var bioma_data = {}
			bioma_data["name"] = biome.get("name", "Unknown")
			bioma_data["id"] = biome.get("id", "")
			bioma_data["color_base"] = biome.get("color_base", "#7ED957")
			
			# Construir rutas completas para texturas
			var textures_config = biome.get("textures", {}) as Dictionary
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
			
			return bioma_data
	
	# Fallback a grassland si no se encuentra
	for biome in biomes:
		if biome.get("name", "").to_lower() == "grassland":
			return _get_biome_data_by_name("grassland")  # Recursión controlada
	
	return {}

func _apply_transition_blending(biome_layer: Node2D, chunk_world_pos: Vector2, chunk_size: Vector2, biome_analysis: Dictionary) -> void:
	"""Aplicar blending de texturas para transiciones suaves entre biomas"""
	var primary_biome_data = _get_biome_data_by_name(biome_analysis.primary_biome)
	var secondary_biome_data = _get_biome_data_by_name(biome_analysis.secondary_biome)
	
	if primary_biome_data.is_empty() or secondary_biome_data.is_empty():
		# Fallback al sistema tradicional si no tenemos datos
		var cx = int(chunk_world_pos.x / 5760)
		var cy = int(chunk_world_pos.y / 3240)
		if not primary_biome_data.is_empty():
			_apply_textures_optimized(biome_layer, primary_biome_data, cx, cy)
		return
	
	# Aplicar blending orgánico real por secciones
	_apply_organic_blending_by_sections(biome_layer, chunk_world_pos, chunk_size, primary_biome_data, secondary_biome_data, biome_analysis)
	
	if debug_mode:
		print("[BiomeChunkApplier] � MÁSCARA ORGÁNICA aplicada: %s→%s (factor: %.2f)" % [biome_analysis.primary_biome, biome_analysis.secondary_biome, biome_analysis.transition_factor])

func _apply_organic_blending_by_sections(biome_layer: Node2D, chunk_world_pos: Vector2, chunk_size: Vector2, primary_data: Dictionary, secondary_data: Dictionary, _biome_analysis: Dictionary) -> void:
	"""Aplicar texturas con blending orgánico usando máscaras generadas proceduralmente"""
	
	# Crear base layer con bioma primario
	_create_base_layer(biome_layer, primary_data, chunk_size)
	
	# Crear mask layer orgánica para el bioma secundario
	_create_organic_mask_layer(biome_layer, chunk_world_pos, chunk_size, secondary_data)
	
	# Añadir decoraciones mezcladas
	_add_organic_decorations(biome_layer, chunk_world_pos, chunk_size, primary_data, secondary_data)

func _create_base_layer(parent: Node2D, biome_data: Dictionary, chunk_size: Vector2) -> void:
	"""Crear la capa base del chunk con el bioma primario usando grid 3x3"""
	var base_texture_path = biome_data.get("base_texture_path", "")
	if base_texture_path.is_empty():
		return
	
	var base_texture = load(base_texture_path)
	if not base_texture:
		return
	
	# Grid 3x3 para cubrir todo el chunk
	var section_width = chunk_size.x / 3.0  # 1920
	var section_height = chunk_size.y / 3.0 # 1080
	
	for row in range(3):
		for col in range(3):
			var sprite = Sprite2D.new()
			sprite.texture = base_texture
			sprite.name = "BaseLayer_%d_%d" % [col, row]
			
			# Posicionar en el centro de cada sección
			sprite.position = Vector2(
				(col + 0.5) * section_width,
				(row + 0.5) * section_height
			)
			
			parent.add_child(sprite)

func _create_organic_mask_layer(parent: Node2D, chunk_world_pos: Vector2, chunk_size: Vector2, secondary_biome_data: Dictionary) -> void:
	"""Crear capa de máscara orgánica para el bioma secundario"""
	var secondary_texture_path = secondary_biome_data.get("base_texture_path", "")
	if secondary_texture_path.is_empty():
		return
	
	var secondary_texture = load(secondary_texture_path)
	if not secondary_texture:
		return
	
	# Crear múltiples sprites con diferentes alphas para simular bordes orgánicos
	var mask_samples = 6  # Número de muestras para el gradiente orgánico
	var section_width = chunk_size.x / 3.0
	var section_height = chunk_size.y / 3.0
	
	for row in range(3):
		for col in range(3):
			# Calcular posición mundial del centro de esta sección
			var section_center = chunk_world_pos + Vector2(
				(col + 0.5) * section_width,
				(row + 0.5) * section_height
			)
			
			# Obtener datos de transición para esta posición
			var transition_data = organic_transition.get_biome_transition_data(section_center)
			var blend_strength = transition_data.blend_factor
			
			# Solo crear máscaras donde hay suficiente influencia del bioma secundario
			if blend_strength > 0.1:
				# Muestrear múltiples puntos dentro de la sección para crear formas irregulares
				var subsample_count = 4  # 2x2 submuestreo dentro de cada sección
				var subsection_size = Vector2(section_width / 2.0, section_height / 2.0)
				
				for sub_y in range(2):
					for sub_x in range(2):
						# Posición del centro de la subsección
						var subsection_center = chunk_world_pos + Vector2(
							col * section_width + (sub_x + 0.5) * subsection_size.x,
							row * section_height + (sub_y + 0.5) * subsection_size.y
						)
						
						# Obtener influencia específica para esta subsección
						var sub_transition_data = organic_transition.get_biome_transition_data(subsection_center)
						var sub_blend_strength = sub_transition_data.blend_factor
						
						# Crear sprite de máscara solo si hay suficiente influencia local
						if sub_blend_strength > 0.15:
							var sprite = Sprite2D.new()
							sprite.texture = secondary_texture
							sprite.name = "OrganicMask_%d_%d_%d_%d" % [col, row, sub_x, sub_y]
							
							# Posición de la subsección con variación orgánica
							var organic_offset = Vector2(
								randf_range(-subsection_size.x * 0.3, subsection_size.x * 0.3),
								randf_range(-subsection_size.y * 0.3, subsection_size.y * 0.3)
							)
							
							sprite.position = Vector2(
								col * section_width + (sub_x + 0.5) * subsection_size.x + organic_offset.x,
								row * section_height + (sub_y + 0.5) * subsection_size.y + organic_offset.y
							)
							
							# Alpha variable según influencia local
							sprite.modulate.a = clamp(sub_blend_strength * 0.7, 0.1, 0.8)
							
							# Escala variable para crear bordes irregulares
							var scale_factor = 0.4 + sub_blend_strength * 0.4  # Escala entre 0.4 y 0.8
							sprite.scale = Vector2(scale_factor, scale_factor)
							
							parent.add_child(sprite)

func _add_organic_decorations(parent: Node2D, chunk_world_pos: Vector2, chunk_size: Vector2, primary_data: Dictionary, secondary_data: Dictionary) -> void:
	"""Añadir decoraciones orgánicas mezcladas según influencias de biomas"""
	var section_width = chunk_size.x / 3.0
	var section_height = chunk_size.y / 3.0
	
	for row in range(3):
		for col in range(3):
			# Calcular posición de la sección
			var section_center = chunk_world_pos + Vector2(
				(col + 0.5) * section_width,
				(row + 0.5) * section_height
			)
			
			# Obtener influencias de biomas
			var transition_data = organic_transition.get_biome_transition_data(section_center)
			var primary_influence = 1.0 - transition_data.blend_factor
			var secondary_influence = transition_data.blend_factor
			
			# Decidir qué decoración usar basado en las influencias
			var chosen_biome_data = primary_data if primary_influence > secondary_influence else secondary_data
			var decorations = chosen_biome_data.get("decorations", [])
			
			if not decorations.is_empty():
				# Añadir decoración con posición aleatoria dentro de la sección
				var random_decor_path = decorations[randi() % decorations.size()]
				var decor_texture = load(random_decor_path)
				
				if decor_texture:
					var decor_sprite = Sprite2D.new()
					decor_sprite.texture = decor_texture
					decor_sprite.name = "OrganicDecor_%d_%d" % [col, row]
					
					# Posición aleatoria dentro de la sección
					var random_offset = Vector2(
						randf_range(-section_width * 0.4, section_width * 0.4),
						randf_range(-section_height * 0.4, section_height * 0.4)
					)
					decor_sprite.position = Vector2(
						(col + 0.5) * section_width + random_offset.x,
						(row + 0.5) * section_height + random_offset.y
					)
					
					# Escalar decoración
					var decor_scale = chosen_biome_data.get("decor_scale", 1.0)
					var texture_size = decor_texture.get_size()
					var scale_factor_x = (section_width / texture_size.x) * decor_scale * 0.6
					var scale_factor_y = (section_height / texture_size.y) * decor_scale * 0.6
					decor_sprite.scale = Vector2(scale_factor_x, scale_factor_y)
					
					# Aplicar opacidad con variación orgánica
					var base_opacity = chosen_biome_data.get("decor_opacity", 0.8)
					var influence_factor = primary_influence if chosen_biome_data == primary_data else secondary_influence
					decor_sprite.modulate.a = base_opacity * influence_factor
					
					parent.add_child(decor_sprite)

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
	var _chunk_size = Vector2(5760, 3240)
	var tile_size = Vector2(1920, 1080)  # Cada cuadrante del chunk
	var grid_cols = 3
	var grid_rows = 3

	# ============ 1. TEXTURAS BASE (1920×1080 cada una, sin escala) ============
	var base_texture_path = bioma_data.get("base_texture_path", "")
	
	print("[_apply_textures_optimized] 🎨 Iniciando para chunk (%d, %d)" % [cx, cy])
	print("[_apply_textures_optimized] 📊 Datos del bioma: %s" % bioma_data)

	if not base_texture_path.is_empty():
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
					print("[BASE_TEXTURE] ✓ Sprite %d_%d creado en posición %s" % [col, row, sprite.position])
			
			print("[✓] Base: 9 sprites × 1920×1080 creados exitosamente (escala: %.2f, %.2f)" % [tile_scale.x, tile_scale.y])
		else:
			printerr("[BASE_TEXTURE] ✗ NO se pudo cargar: %s" % base_texture_path)
			# FALLBACK: Crear fondo de color sólido basado en bioma
			_create_solid_color_fallback(parent, bioma_data, grid_rows, grid_cols, tile_size)
	else:
		printerr("[BASE_TEXTURE] ✗ Ruta vacía para textura base")

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
			
			if decor_path is String and not decor_path.is_empty():
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

# ============ FUNCIÓN: Fallback - Color sólido si no se carga textura ============
func _create_solid_color_fallback(parent: Node, bioma_data: Dictionary, grid_rows: int, grid_cols: int, tile_size: Vector2) -> void:
	"""
	Si la textura base no se puede cargar, crear un fondo de color sólido.
	Extrae el color_base del JSON de configuración.
	"""
	var color_hex = bioma_data.get("color_base", "#7ED957")
	var color = Color.from_string(color_hex, Color.WHITE)
	
	print("[FALLBACK] Usando color de bioma: %s" % color_hex)
	
	# Crear 3×3 grid de ColorRects
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
	
	print("[✓] Fallback: 9 ColorRects aplicados (color: %s)" % color_hex)

# ============ FUNCIÓN: Suavizar bordes entre chunks ============
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

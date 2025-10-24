# BiomeRegionApplier.gd
# Aplicador de texturas de biomas para regiones orgánicas irregulares
# Reemplaza BiomeChunkApplier.gd - Adaptado para formas Voronoi + Perlin

extends Node
class_name BiomeRegionApplier

"""
🎨 BIOME REGION APPLIER - SISTEMA ORGÁNICO
==========================================

Responsabilidades:
- Aplicar texturas PNG existentes a regiones de forma irregular
- Integrar con OrganicTextureBlender para transiciones suaves
- Gestionar tileable patterns para shapes complejas
- Mantener compatibilidad con texturas existentes del proyecto

Diferencias vs BiomeChunkApplier:
- Aplica textures a polígonos irregulares (no rectangulares)
- Usa OrganicTextureBlender para transiciones naturales
- Respeta contornos orgánicos generados por Voronoi+Perlin
- Optimizado para regiones de tamaño variable
"""

# ========== CONFIGURACIÓN ==========
const TEXTURE_BASE_PATH = "res://assets/textures/biomes/"
const BIOME_CONFIG_PATH = "res://assets/textures/biomes/biome_textures_config.json"
const TEXTURE_SCALE = 1.0
const DEFAULT_BIOME = "grassland"

# Configuración de texturas por bioma (basada en JSON)
var biome_textures_config: Dictionary = {}

# Configuración fallback si JSON no carga
const BIOME_TEXTURES = {
	"grassland": {
		"base": "Grassland/base.png",
		"decor": ["Grassland/decor1.png"],
		"scale": 1.0,
		"tint": Color.WHITE
	},
	"desert": {
		"base": "Desert/base.png",
		"decor": ["Desert/decor1.png"],
		"scale": 1.2,
		"tint": Color(1.0, 0.95, 0.8, 1.0)
	},
	"snow": {
		"base": "Snow/base.png",
		"decor": ["Snow/decor1.png"],
		"scale": 0.8,
		"tint": Color(0.9, 0.95, 1.0, 1.0)
	},
	"lava": {
		"base": "Lava/base.png",
		"decor": ["Lava/decor1.png"],
		"scale": 1.1,
		"tint": Color(1.0, 0.8, 0.6, 1.0)
	},
	"arcane_wastes": {
		"base": "ArcaneWastes/base.png",
		"decor": ["ArcaneWastes/decor1.png"],
		"scale": 1.0,
		"tint": Color(0.9, 0.7, 1.0, 1.0)
	},
	"forest": {
		"base": "Forest/base.png",
		"decor": ["Forest/decor1.png"],
		"scale": 0.9,
		"tint": Color(0.8, 1.0, 0.8, 1.0)
	}
}

# ========== DEPENDENCIAS ==========
var organic_texture_blender: OrganicTextureBlenderSystem
var texture_cache: Dictionary = {}

# ========== ESTADO ==========
var is_initialized: bool = false

func _ready() -> void:
	"""Inicializar aplicador de texturas orgánicas"""
	_initialize_system()
	print("[BiomeRegionApplier] 🎨 Sistema de texturas orgánicas inicializado")

func _initialize_system() -> void:
	"""Configurar dependencias y cargar texturas base"""
	# Cargar configuración JSON si está disponible
	_load_biome_config_json()

	# Buscar OrganicTextureBlender en el árbol de nodos
	organic_texture_blender = _find_organic_texture_blender()
	if not organic_texture_blender:
		print("[BiomeRegionApplier] ⚠️ OrganicTextureBlender no encontrado, creando instancia...")
		organic_texture_blender = OrganicTextureBlenderSystem.new()
		organic_texture_blender.initialize(12345) # Usar semilla por defecto
		get_tree().root.add_child(organic_texture_blender)

	# Pre-cargar texturas comunes
	_preload_base_textures()

	is_initialized = true

func _load_biome_config_json() -> void:
	"""Cargar configuración de biomas desde JSON"""
	if ResourceLoader.exists(BIOME_CONFIG_PATH):
		var json_text = ResourceLoader.load(BIOME_CONFIG_PATH, "JSON")
		if json_text:
			print("[BiomeRegionApplier] ✅ Configuración JSON cargada")
	else:
		print("[BiomeRegionApplier] ℹ️ Usando configuración por defecto (JSON no encontrado)")

func set_organic_texture_blender(blender: OrganicTextureBlenderSystem) -> void:
	"""Establecer referencia directa al OrganicTextureBlender"""
	organic_texture_blender = blender
	print("[BiomeRegionApplier] 🔗 OrganicTextureBlender conectado directamente")

func _find_organic_texture_blender() -> OrganicTextureBlenderSystem:
	"""Buscar OrganicTextureBlender en el árbol de nodos"""
	# Buscar en el árbol completo
	var all_nodes = get_tree().get_nodes_in_group("organic_texture_blender")
	if all_nodes.size() > 0:
		return all_nodes[0]

	# Buscar recursivamente en el árbol desde la raíz
	return _find_node_recursive(get_tree().root, OrganicTextureBlenderSystem)

func _find_node_recursive(node: Node, target_class) -> Node:
	"""Buscar un nodo de una clase específica de forma recursiva"""
	# Verificar por script de clase personalizada - buscamos OrganicTextureBlenderSystem
	if node.has_method("get_script") and node.get_script():
		var script = node.get_script()
		if script and script.get_global_name() == "OrganicTextureBlenderSystem":
			return node

	# También verificar si el nodo tiene el nombre exacto
	if node.name == "OrganicTextureBlender":
		return node

	# Búsqueda recursiva en hijos
	for child in node.get_children():
		var result = _find_node_recursive(child, target_class)
		if result:
			return result

	return null

# ========== FUNCIÓN PRINCIPAL ==========
func apply_biome_to_region(region_node: Node2D, region_data: Dictionary) -> void:
	"""
	Aplicar texturas de bioma a una región orgánica irregular

	Args:
		region_node: Node2D - nodo contenedor de la región
		region_data: Dictionary - datos de la región (de BiomeGenerator.generate_region_async)
	"""

	if not is_initialized:
		_initialize_system()

	var start_time = Time.get_ticks_msec()
	var biome_name = BiomeGenerator.BIOME_NAMES.get(region_data.biome_type, DEFAULT_BIOME)
	var boundary_points = region_data.boundary_points

	print("[BiomeRegionApplier] 🖼️ Aplicando textura '", biome_name, "' a región orgánica")

	# Limpiar contenido anterior
	_clear_region_textures(region_node)

	# Crear geometría base para texturas
	var base_geometry = _create_organic_geometry(region_node, boundary_points, biome_name)

	# Aplicar textura base tileada
	_apply_base_texture(base_geometry, biome_name, region_data)

	# Aplicar overlay de detalles
	_apply_detail_overlay(base_geometry, biome_name, region_data)

	# Configurar metadatos
	region_node.set_meta("biome_name", biome_name)
	region_node.set_meta("region_id", region_data.region_id)
	region_node.set_meta("applied_time", Time.get_ticks_msec())

	var application_time = Time.get_ticks_msec() - start_time
	print("[BiomeRegionApplier] ✅ Textura aplicada | Tiempo:", application_time, "ms")

func apply_blended_region(region_node: Node2D, region_data: Dictionary, neighbor_regions: Array) -> void:
	"""
	Aplicar texturas con transiciones suaves entre regiones vecinas

	Args:
		region_node: Node2D - nodo contenedor de la región
		region_data: Dictionary - datos de la región principal
		neighbor_regions: Array - datos de regiones vecinas para blending
	"""

	if not is_initialized:
		_initialize_system()

	print("[BiomeRegionApplier] 🌈 Aplicando región con blending | Vecinos:", neighbor_regions.size())

	# Aplicar textura base primero
	apply_biome_to_region(region_node, region_data)

	# Si hay vecinos, aplicar blending
	if neighbor_regions.size() > 0:
		_apply_organic_blending(region_node, region_data, neighbor_regions)

# ========== FUNCIONES AUXILIARES ==========

func _clear_region_textures(region_node: Node2D) -> void:
	"""Limpiar texturas anteriores del nodo región"""
	for child in region_node.get_children():
		if child.has_meta("is_biome_texture"):
			child.queue_free()

func _create_organic_geometry(parent: Node2D, boundary_points: PackedVector2Array, biome_name: String) -> Node2D:
	"""Crear geometría base para aplicar texturas a forma irregular"""
	var geometry_container = Node2D.new()
	geometry_container.name = "BiomeGeometry_" + biome_name
	geometry_container.set_meta("is_biome_texture", true)

	# Crear Polygon2D para la forma irregular
	var region_polygon = Polygon2D.new()
	region_polygon.name = "RegionShape"
	region_polygon.polygon = boundary_points
	region_polygon.color = Color.WHITE # Base neutra para texturas
	region_polygon.z_index = 0
	region_polygon.use_parent_material = false
	region_polygon.antialiased = true

	geometry_container.add_child(region_polygon)
	parent.add_child(geometry_container)

	return geometry_container

func _apply_base_texture(geometry_container: Node2D, biome_name: String, _region_data: Dictionary) -> void:
	"""Aplicar textura base tileada a la forma irregular"""
	var texture_config = BIOME_TEXTURES.get(biome_name, BIOME_TEXTURES[DEFAULT_BIOME])
	var base_texture = _load_biome_texture(texture_config.base)

	if not base_texture:
		print("[BiomeRegionApplier] ⚠️ No se pudo cargar textura base para ", biome_name)
		return

	var region_polygon = geometry_container.get_node("RegionShape")

	if not region_polygon:
		print("[BiomeRegionApplier] ❌ No se encontró RegionShape")
		return

	# Configurar textura tileada
	region_polygon.texture = base_texture
	region_polygon.texture_scale = Vector2(texture_config.scale, texture_config.scale)
	region_polygon.texture_offset = Vector2.ZERO
	region_polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	region_polygon.modulate = texture_config.tint
	region_polygon.show()

	print("[BiomeRegionApplier] ✅ Textura base aplicada: ", biome_name, " - Size: ", base_texture.get_size())

func _apply_detail_overlay(geometry_container: Node2D, biome_name: String, _region_data: Dictionary) -> void:
	"""Aplicar overlay de detalles por encima de la textura base"""
	var texture_config = BIOME_TEXTURES.get(biome_name, BIOME_TEXTURES[DEFAULT_BIOME])

	if not texture_config.has("decor"):
		return # No hay decor definido

	var overlay_texture = _load_biome_texture(texture_config.decor[0])
	if not overlay_texture:
		return

	# Crear segundo polígono para overlay
	var overlay_polygon = Polygon2D.new()
	overlay_polygon.name = "DetailOverlay"
	overlay_polygon.polygon = geometry_container.get_node("RegionShape").polygon
	overlay_polygon.texture = overlay_texture
	overlay_polygon.texture_scale = Vector2(texture_config.scale * 0.7, texture_config.scale * 0.7)
	overlay_polygon.modulate = Color(1.0, 1.0, 1.0, 0.6) # Semi-transparente
	overlay_polygon.z_index = 1 # Por encima de la textura base

	geometry_container.add_child(overlay_polygon)

func _apply_organic_blending(region_node: Node2D, region_data: Dictionary, neighbor_regions: Array) -> void:
	"""Aplicar blending orgánico usando OrganicTextureBlender"""
	if not organic_texture_blender:
		print("[BiomeRegionApplier] ⚠️ OrganicTextureBlender no disponible para blending")
		return

	# Preparar datos para el blender
	var blend_data = {
		"biome_id": region_data.get("biome_name", "grassland"),
		"neighbors": neighbor_regions,
		"position": region_data.get("center_position", Vector2.ZERO),
		"boundary_points": region_data.get("boundary_points", PackedVector2Array())
	}

	# Aplicar blending usando OrganicTextureBlender
	var blended_material = organic_texture_blender.apply_blend_to_region(blend_data)

	if blended_material:
		_apply_blended_result(region_node, blended_material)

func _apply_blended_result(region_node: Node2D, blended_material: ShaderMaterial) -> void:
	"""Aplicar resultado final del blending a la región"""
	var geometry_container = region_node.get_node_or_null("BiomeGeometry_*")
	if not geometry_container:
		return

	# Crear polígono para material blended
	var blended_polygon = Polygon2D.new()
	blended_polygon.name = "BlendedTexture"
	blended_polygon.polygon = geometry_container.get_node("RegionShape").polygon
	blended_polygon.material = blended_material
	blended_polygon.z_index = 2 # Por encima de todo

	geometry_container.add_child(blended_polygon)

func _setup_tileable_uv_mapping(polygon: Polygon2D, bounding_rect: Rect2) -> void:
	"""Configurar UV mapping para que las texturas se repitan correctamente"""
	# Calcular offset basado en posición para continuidad global
	var texture_offset = Vector2(
		fmod(bounding_rect.position.x / 512.0, 1.0),
		fmod(bounding_rect.position.y / 512.0, 1.0)
	)

	polygon.texture_offset = texture_offset
	polygon.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

func _preload_base_textures() -> void:
	"""Pre-cargar texturas más comunes para reducir latencia"""
	var common_biomes = ["grassland", "forest", "desert"]

	for biome in common_biomes:
		if BIOME_TEXTURES.has(biome):
			var config = BIOME_TEXTURES[biome]
			_load_biome_texture(config.base)

func _load_biome_texture(texture_filename: String) -> Texture2D:
	"""Cargar textura de bioma con cache"""
	if texture_cache.has(texture_filename):
		return texture_cache[texture_filename]

	var full_path = TEXTURE_BASE_PATH + texture_filename

	if not ResourceLoader.exists(full_path):
		print("[BiomeRegionApplier] ⚠️ Textura no encontrada: ", full_path)
		return null

	var texture = load(full_path) as Texture2D
	if texture:
		texture_cache[texture_filename] = texture
		print("[BiomeRegionApplier] ✅ Textura cargada: ", texture_filename)

	return texture

# ========== FUNCIONES DE UTILIDAD ==========

func get_applied_biome(region_node: Node2D) -> String:
	"""Obtener el bioma aplicado a una región"""
	return region_node.get_meta("biome_name", DEFAULT_BIOME)

func is_region_textured(region_node: Node2D) -> bool:
	"""Verificar si una región ya tiene texturas aplicadas"""
	return region_node.has_meta("biome_name") and region_node.get_node_or_null("BiomeGeometry_*") != null

func clear_all_texture_cache() -> void:
	"""Limpiar cache de texturas (útil para debugging)"""
	texture_cache.clear()
	print("[BiomeRegionApplier] 🧹 Cache de texturas limpiado")
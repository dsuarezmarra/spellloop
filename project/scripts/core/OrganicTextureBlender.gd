# OrganicTextureBlender.gd
# Versión simplificada sin errores de parsing
extends Node
class_name OrganicTextureBlenderSystem

# ========== VARIABLES PRINCIPALES ==========
@export var debug_mode: bool = false
@export var blend_zone_width: float = 64.0
@export var enable_caching: bool = true

# ========== ESTADO INTERNO ==========
var is_initialized: bool = false
var initialized: bool = false
var world_seed: int = 0

# ========== GENERADORES ==========
var noise_generator: FastNoiseLite
var blend_shader: Shader
var material_cache: Dictionary = {}

func _ready():
	"""Configuración inicial"""
	initialized = false
	is_initialized = false
	print("[OrganicTextureBlender] 📋 Inicializado")

func initialize(seed: int) -> void:
	"""Inicializar sistema con semilla"""
	world_seed = seed

	# Añadir a grupo para fácil localización
	add_to_group("organic_texture_blender")

	# Configurar ruido
	noise_generator = FastNoiseLite.new()
	noise_generator.seed = seed
	noise_generator.noise_type = FastNoiseLite.TYPE_PERLIN
	noise_generator.frequency = 0.02

	# Cargar shader
	_load_blend_shader()

	is_initialized = true
	initialized = true
	print("[OrganicTextureBlender] ✅ Inicializado (seed: " + str(seed) + ")")

func _load_blend_shader() -> void:
	"""Cargar shader de blending"""
	var shader_path = "res://scripts/core/shaders/biome_blend.gdshader"

	if ResourceLoader.exists(shader_path):
		blend_shader = load(shader_path)
		if blend_shader:
			print("[OrganicTextureBlender] ✅ Shader cargado")
		else:
			print("[OrganicTextureBlender] ❌ Error cargando shader")
	else:
		print("[OrganicTextureBlender] ❌ Shader no encontrado: " + shader_path)

func apply_blend_to_region(region_data: Dictionary) -> ShaderMaterial:
	"""API principal: aplicar blending orgánico a una región"""
	if not is_initialized:
		print("[OrganicTextureBlender] ⚠️ Sistema no inicializado")
		return null

	if not blend_shader:
		print("[OrganicTextureBlender] ❌ Shader no disponible")
		return null

	var biome_a = region_data.get("biome_id", "grassland")
	var neighbors = region_data.get("neighbors", [])

	if neighbors.is_empty():
		return null

	# Usar el primer vecino para la demostración
	var biome_b = neighbors[0].get("biome_id", "desert")
	var position = region_data.get("position", Vector2.ZERO)

	return _create_blend_material(biome_a, biome_b, position)

func _create_blend_material(biome_a: String, biome_b: String, position: Vector2) -> ShaderMaterial:
	"""Crear material con shader para blending entre dos biomas"""
	if not blend_shader:
		return null

	var material = ShaderMaterial.new()
	material.shader = blend_shader

	# Configurar parámetros básicos
	material.set_shader_parameter("blend_strength", 0.5)
	material.set_shader_parameter("noise_scale", 1.5)
	material.set_shader_parameter("flow_speed", 0.4)
	material.set_shader_parameter("micro_oscillation", 0.03)

	# Configurar offset UV aleatorio
	var rng = RandomNumberGenerator.new()
	rng.seed = world_seed + int(position.x) + int(position.y)
	var uv_offset = Vector2(rng.randf() * 0.1, rng.randf() * 0.1)
	material.set_shader_parameter("uv_offset", uv_offset)

	print("[OrganicTextureBlender] 🎨 Material creado: " + str(biome_a) + " → " + str(biome_b))
	return material

func configure_noise(main_freq: float = 0.02) -> void:
	"""Configurar parámetros de ruido"""
	if noise_generator:
		noise_generator.frequency = main_freq
		print("[OrganicTextureBlender] 🎛️ Ruido reconfigurado: " + str(main_freq))

func set_blend_zone_width(width: float) -> void:
	"""Configurar ancho de zona de blending"""
	blend_zone_width = max(width, 32.0)
	print("[OrganicTextureBlender] 📏 Zona de blending: " + str(blend_zone_width) + " píxeles")

func clear_cache() -> void:
	"""Limpiar cachés de materiales"""
	material_cache.clear()
	print("[OrganicTextureBlender] 🧹 Caché limpiado")

func get_performance_stats() -> Dictionary:
	"""Obtener estadísticas de rendimiento"""
	return {
		"materials_cached": material_cache.size(),
		"cache_enabled": enable_caching,
		"blend_zone_width": blend_zone_width,
		"initialized": is_initialized
	}
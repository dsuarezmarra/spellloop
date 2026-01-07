extends CanvasLayer
class_name DamageVignette

## Efecto visual de daño en los bordes de la pantalla
## Estilo Binding of Isaac: vignette roja + partículas en bordes

# Configuración
@export var vignette_duration: float = 0.3
@export var vignette_max_alpha: float = 0.5
@export var particle_count: int = 12
@export var particle_lifetime: float = 0.4
@export var base_color: Color = Color(0.8, 0.0, 0.0, 0.8)

# Nodos
var _vignette_rect: ColorRect = null
var _particles_container: Control = null
var _vignette_tween: Tween = null

# Shader para vignette radial
const VIGNETTE_SHADER = """
shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 vignette_color : source_color = vec4(0.8, 0.0, 0.0, 1.0);
uniform float inner_radius : hint_range(0.0, 1.0) = 0.4;
uniform float outer_radius : hint_range(0.0, 1.0) = 0.9;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv) * 2.0;
	
	// Vignette radial con bordes suaves
	float vignette = smoothstep(inner_radius, outer_radius, dist);
	
	// Agregar ruido para efecto más orgánico
	float noise = fract(sin(dot(UV, vec2(12.9898, 78.233))) * 43758.5453);
	vignette *= 1.0 + noise * 0.1;
	
	// Solo mostrar el efecto, sin afectar lo de abajo cuando intensity es 0
	COLOR = vec4(vignette_color.rgb, vignette * intensity * vignette_color.a);
}
"""

func _ready() -> void:
	# Configurar layer para estar encima de todo
	layer = 100
	
	# Crear vignette
	_setup_vignette()
	
	# Crear contenedor de partículas
	_setup_particles_container()

func _setup_vignette() -> void:
	_vignette_rect = ColorRect.new()
	_vignette_rect.name = "VignetteRect"
	_vignette_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Crear y aplicar shader
	var shader_material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = VIGNETTE_SHADER
	shader_material.shader = shader
	shader_material.set_shader_parameter("intensity", 0.0)
	shader_material.set_shader_parameter("vignette_color", base_color)
	shader_material.set_shader_parameter("inner_radius", 0.35)
	shader_material.set_shader_parameter("outer_radius", 0.85)
	
	_vignette_rect.material = shader_material
	add_child(_vignette_rect)

func _setup_particles_container() -> void:
	_particles_container = Control.new()
	_particles_container.name = "ParticlesContainer"
	_particles_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_particles_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_particles_container)

## Mostrar efecto de daño completo
func show_damage_effect(damage_amount: int = 10, element: String = "") -> void:
	# Escalar intensidad basada en daño
	var intensity = clampf(float(damage_amount) / 25.0, 0.2, 1.0)
	
	# Color según elemento
	var color = _get_element_color(element)
	
	# Mostrar vignette
	_flash_vignette(intensity, color)
	
	# Spawner partículas en bordes
	_spawn_edge_particles(intensity, color)

func _flash_vignette(intensity: float, color: Color) -> void:
	if not is_instance_valid(_vignette_rect):
		return
	
	# Cancelar tween anterior
	if _vignette_tween and _vignette_tween.is_running():
		_vignette_tween.kill()
	
	var mat = _vignette_rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("vignette_color", color)
	
	# Crear animación de flash
	_vignette_tween = create_tween()
	_vignette_tween.set_ease(Tween.EASE_OUT)
	
	# Flash inmediato y luego fade out
	if mat:
		mat.set_shader_parameter("intensity", vignette_max_alpha * intensity)
	
	_vignette_tween.tween_method(
		func(val): 
			if mat: mat.set_shader_parameter("intensity", val),
		vignette_max_alpha * intensity,
		0.0,
		vignette_duration
	)

func _spawn_edge_particles(intensity: float, color: Color) -> void:
	if not is_instance_valid(_particles_container):
		return
	
	var viewport_size = get_viewport().get_visible_rect().size
	var count = int(particle_count * intensity)
	
	for i in range(count):
		_spawn_single_particle(viewport_size, color)

func _spawn_single_particle(viewport_size: Vector2, color: Color) -> void:
	# Posición en el borde de la pantalla
	var edge = randi() % 4  # 0=top, 1=right, 2=bottom, 3=left
	var pos: Vector2
	var direction: Vector2
	
	match edge:
		0:  # Top
			pos = Vector2(randf() * viewport_size.x, 0)
			direction = Vector2(randf_range(-0.3, 0.3), 1.0).normalized()
		1:  # Right
			pos = Vector2(viewport_size.x, randf() * viewport_size.y)
			direction = Vector2(-1.0, randf_range(-0.3, 0.3)).normalized()
		2:  # Bottom
			pos = Vector2(randf() * viewport_size.x, viewport_size.y)
			direction = Vector2(randf_range(-0.3, 0.3), -1.0).normalized()
		3:  # Left
			pos = Vector2(0, randf() * viewport_size.y)
			direction = Vector2(1.0, randf_range(-0.3, 0.3)).normalized()
	
	# Crear partícula visual
	var particle = _create_particle_visual(color)
	particle.position = pos
	_particles_container.add_child(particle)
	
	# Animar partícula
	var distance = randf_range(30, 80)
	var end_pos = pos + direction * distance
	
	var tween = particle.create_tween()
	tween.set_parallel(true)
	tween.tween_property(particle, "position", end_pos, particle_lifetime)
	tween.tween_property(particle, "modulate:a", 0.0, particle_lifetime)
	tween.tween_property(particle, "scale", Vector2(0.3, 0.3), particle_lifetime)
	tween.set_parallel(false)
	tween.tween_callback(particle.queue_free)

func _create_particle_visual(color: Color) -> Control:
	var particle = Control.new()
	particle.custom_minimum_size = Vector2(20, 20)
	particle.pivot_offset = Vector2(10, 10)
	particle.scale = Vector2(randf_range(0.5, 1.2), randf_range(0.5, 1.2))
	particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Usar draw para forma de gota/salpicadura
	var visual = Node2D.new()
	visual.position = Vector2(10, 10)
	particle.add_child(visual)
	
	var size = randf_range(4, 10)
	var particle_color = color
	
	visual.draw.connect(func():
		# Gota/salpicadura de sangre
		visual.draw_circle(Vector2.ZERO, size, particle_color)
		# Pequeños puntos adicionales
		for j in range(2):
			var offset = Vector2(randf_range(-8, 8), randf_range(-8, 8))
			visual.draw_circle(offset, size * 0.4, Color(particle_color.r, particle_color.g, particle_color.b, particle_color.a * 0.7))
	)
	visual.queue_redraw()
	
	return particle

func _get_element_color(element: String) -> Color:
	match element:
		"fire":
			return Color(1.0, 0.3, 0.0, 0.85)
		"ice":
			return Color(0.4, 0.7, 1.0, 0.8)
		"dark", "void", "shadow":
			return Color(0.4, 0.1, 0.6, 0.85)
		"poison":
			return Color(0.3, 0.8, 0.2, 0.8)
		"arcane":
			return Color(0.8, 0.3, 1.0, 0.8)
		"lightning":
			return Color(1.0, 1.0, 0.3, 0.8)
		_:
			return base_color  # Rojo por defecto

## Limpiar todos los efectos
func clear_effects() -> void:
	if _vignette_tween and _vignette_tween.is_running():
		_vignette_tween.kill()
	
	if is_instance_valid(_vignette_rect):
		var mat = _vignette_rect.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("intensity", 0.0)
	
	# Limpiar partículas
	for child in _particles_container.get_children():
		child.queue_free()

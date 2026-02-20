# AnimatedBossSprite.gd
# Componente para animar sprites de BOSSES con efectos especiales
# Los bosses son más grandes, lentos e imponentes que los enemigos normales
# Incluye aura pulsante luminosa como diferenciador visual
#
# Formato de spritesheet esperado: 1 fila × 3 columnas
# [FRENTE] [LADO_IZQ] [ESPALDA]

extends Sprite2D
class_name AnimatedBossSprite

# === CONFIGURACIÓN DE ANIMACIÓN (más lenta y pesada que enemigos normales) ===
@export var enable_bobbing: bool = true
@export var enable_breathing: bool = true
@export var enable_sway: bool = true
@export var enable_aura: bool = true              # Aura brillante pulsante

# Movimientos MÁS LENTOS y PESADOS que enemigos normales
@export var bobbing_speed: float = 1.5            # Mucho más lento (enemigos: 4.0)
@export var bobbing_amount: float = 4.0           # Menos rebote (enemigos: 6.0)
@export var breathing_speed: float = 1.0          # Respiración lenta (enemigos: 2.0)
@export var breathing_amount: float = 0.06        # Más pronunciado (enemigos: 0.05)
@export var sway_speed: float = 0.8               # Balanceo muy lento (enemigos: 2.5)
@export var sway_amount: float = 2.0              # Menos grados (enemigos: 3.0)

# Escala base MAYOR que enemigos normales
@export var sprite_scale: float = 0.35:           # Casi el doble (enemigos: 0.2)
	set(value):
		sprite_scale = value
		base_scale = Vector2(value, value)
		scale = base_scale

# === CONFIGURACIÓN DEL AURA ===
@export var aura_color: Color = Color(1.0, 0.8, 0.2, 1.0)  # Dorado por defecto
@export var aura_width: float = 6.0               # Grosor del aura (sutil para evitar cortes)
@export var aura_pulse_speed: float = 3.0         # Velocidad del pulso
@export var aura_pulse_amount: float = 0.3        # Variación de intensidad
@export var aura_glow_layers: int = 3             # Capas de brillo
@export var aura_intensity: float = 1.8           # Multiplicador de brillo

# === PARTÍCULAS FLOTANTES ===
@export var enable_particles: bool = true         # Partículas alrededor del boss
@export var particle_count: int = 8               # Número de partículas
@export var particle_orbit_radius: float = 60.0   # Radio de órbita
@export var particle_speed: float = 1.5           # Velocidad de órbita

# === ESTADO INTERNO ===
var spritesheet_texture: Texture2D = null
var frame_textures: Array[Texture2D] = []  # [frente, lado, espalda]
var frame_width: int = 0
var frame_height: int = 0

var current_direction: String = "down"
var base_scale: Vector2 = Vector2.ONE
var animation_time: float = 0.0
var direction_locked: bool = false

# Shader para el aura
var aura_material: ShaderMaterial = null

# Sistema de partículas
var particles: Array[Node2D] = []

const DIRECTION_TO_FRAME = {
	"down": 0,
	"left": 1,
	"right": 1,
	"up": 2
}

# Shader code para el aura pulsante - MUY VISIBLE
const AURA_SHADER = """
shader_type canvas_item;

uniform vec4 aura_color : source_color = vec4(1.0, 0.8, 0.2, 1.0);
uniform float aura_width : hint_range(1.0, 40.0) = 20.0;
uniform float pulse_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float glow_intensity : hint_range(0.5, 3.0) = 1.5;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	vec2 pixel_size = TEXTURE_PIXEL_SIZE;
	
	// Si el pixel actual es transparente, verificar si hay pixels cercanos opacos para el AURA
	if (tex_color.a < 0.1) {
		float max_dist = aura_width;
		float total_alpha = 0.0;
		float sample_count = 0.0;
		
		// Muestrear en círculo para un aura suave
		for (float angle = 0.0; angle < 6.28318; angle += 0.3) {
			for (float dist = 1.0; dist <= max_dist; dist += 1.0) {
				vec2 offset = vec2(cos(angle), sin(angle)) * dist * pixel_size;
				vec4 neighbor = texture(TEXTURE, UV + offset);
				if (neighbor.a > 0.3) {
					// Contribución basada en distancia (más cerca = más fuerte)
					float contribution = (1.0 - dist / max_dist);
					total_alpha += contribution * contribution; // Cuadrático para más intensidad cerca
					sample_count += 1.0;
				}
			}
		}
		
		if (sample_count > 0.0) {
			float aura_alpha = (total_alpha / sample_count) * pulse_intensity * glow_intensity;
			aura_alpha = clamp(aura_alpha, 0.0, 1.0);
			
			// Color del aura con brillo extra
			vec3 glow_color = aura_color.rgb * glow_intensity;
			COLOR = vec4(glow_color, aura_alpha * aura_color.a);
		} else {
			COLOR = vec4(0.0);
		}
	} else {
		// Pixel original - añadir un borde brillante interno sutil
		float edge_glow = 0.0;
		for (float angle = 0.0; angle < 6.28318; angle += 0.785) {
			vec2 offset = vec2(cos(angle), sin(angle)) * 2.0 * pixel_size;
			vec4 neighbor = texture(TEXTURE, UV + offset);
			if (neighbor.a < 0.1) {
				edge_glow += 0.15;
			}
		}
		
		// Mezclar color original con brillo en bordes
		vec3 final_color = tex_color.rgb + aura_color.rgb * edge_glow * pulse_intensity;
		COLOR = vec4(final_color, tex_color.a);
	}
}
"""

func _ready() -> void:
	base_scale = scale if scale != Vector2.ZERO else Vector2(sprite_scale, sprite_scale)
	scale = base_scale
	
	# Randomizar tiempo inicial
	animation_time = randf() * TAU
	
	# Configurar el shader de aura
	if enable_aura:
		_setup_aura_shader()
	
	# Crear partículas flotantes
	if enable_particles:
		call_deferred("_setup_particles")

func _setup_aura_shader() -> void:
	"""Configurar el shader de aura pulsante - MUY VISIBLE"""
	var shader = Shader.new()
	shader.code = AURA_SHADER
	
	aura_material = ShaderMaterial.new()
	aura_material.shader = shader
	aura_material.set_shader_parameter("aura_color", aura_color)
	aura_material.set_shader_parameter("aura_width", aura_width)
	aura_material.set_shader_parameter("pulse_intensity", 1.0)
	aura_material.set_shader_parameter("glow_intensity", aura_intensity)
	
	material = aura_material

func _apply_bobbing(bob_phase: float) -> void:
	"""Movimiento vertical lento y pesado"""
	offset.y += bob_phase * bobbing_amount

func _apply_breathing() -> void:
	"""Respiración lenta y dramática"""
	var breath_scale = 1.0 + sin(animation_time * breathing_speed) * breathing_amount
	scale *= breath_scale

func _apply_sway() -> void:
	"""Balanceo muy sutil y lento - imponente"""
	var sway_angle = sin(animation_time * sway_speed) * deg_to_rad(sway_amount)
	rotation = sway_angle

func _update_aura_pulse() -> void:
	"""Pulso del aura - brillo variable"""
	var pulse = 0.6 + sin(animation_time * aura_pulse_speed) * aura_pulse_amount
	aura_material.set_shader_parameter("pulse_intensity", pulse)

func load_spritesheet(path: String) -> bool:
	"""Cargar un spritesheet de 3 poses con gaps de 8px y extraer frames"""
	if not ResourceLoader.exists(path):
		push_warning("[AnimatedBossSprite] Spritesheet no encontrado: %s" % path)
		return false
	
	spritesheet_texture = load(path)
	if not spritesheet_texture:
		push_warning("[AnimatedBossSprite] Error al cargar: %s" % path)
		return false
	
	# Detectar regiones de sprites
	var img = spritesheet_texture.get_image()
	var img_width = img.get_width()
	var img_height = img.get_height()
	
	var sprite_regions = _detect_sprite_regions(img)
	
	if sprite_regions.size() != 3:
		push_warning("[AnimatedBossSprite] No se detectaron 3 sprites, usando división simple")
		var simple_width = img_width / 3
		sprite_regions = [
			Rect2(0, 0, simple_width, img_height),
			Rect2(simple_width, 0, simple_width, img_height),
			Rect2(simple_width * 2, 0, simple_width, img_height)
		]
	
	frame_width = int(sprite_regions[0].size.x)
	frame_height = int(sprite_regions[0].size.y)
	
	frame_textures.clear()
	
	for region in sprite_regions:
		var atlas = AtlasTexture.new()
		atlas.atlas = spritesheet_texture
		atlas.region = region
		atlas.filter_clip = true
		frame_textures.append(atlas)
	
	centered = true
	current_direction = "down"
	flip_h = false
	_update_frame()
	
	# print("[AnimatedBossSprite] ✓ Boss cargado: %s (aura: %s)" % [path, enable_aura])
	return true

func _detect_sprite_regions(img: Image) -> Array[Rect2]:
	"""Detectar las 3 regiones de sprites analizando el canal alpha"""
	var width = img.get_width()
	var height = img.get_height()
	
	var columns_with_content: Array[int] = []
	for x in range(width):
		var has_content = false
		for y in range(height):
			if img.get_pixel(x, y).a > 0.01:
				has_content = true
				break
		if has_content:
			columns_with_content.append(x)
	
	if columns_with_content.is_empty():
		return []
	
	var regions: Array[Rect2] = []
	var region_start = columns_with_content[0]
	var region_end = columns_with_content[0]
	
	for i in range(1, columns_with_content.size()):
		var col = columns_with_content[i]
		if col - region_end > 4:
			var y_bounds = _find_vertical_bounds(img, region_start, region_end)
			regions.append(Rect2(region_start, y_bounds.x, region_end - region_start + 1, y_bounds.y - y_bounds.x + 1))
			region_start = col
		region_end = col
	
	var y_bounds = _find_vertical_bounds(img, region_start, region_end)
	regions.append(Rect2(region_start, y_bounds.x, region_end - region_start + 1, y_bounds.y - y_bounds.x + 1))
	
	return regions

func _find_vertical_bounds(img: Image, col_start: int, col_end: int) -> Vector2:
	"""Encontrar el bounding box vertical para un rango de columnas"""
	var height = img.get_height()
	var min_y = height
	var max_y = 0
	
	for x in range(col_start, col_end + 1):
		for y in range(height):
			if img.get_pixel(x, y).a > 0.01:
				min_y = min(min_y, y)
				max_y = max(max_y, y)
	
	return Vector2(min_y, max_y)

func set_direction(direction: Vector2) -> void:
	"""Establecer dirección basada en vector de movimiento"""
	if direction_locked:
		return
	
	if direction.length() < 0.1:
		return
	
	var new_direction: String
	if abs(direction.x) > abs(direction.y):
		new_direction = "right" if direction.x > 0 else "left"
	else:
		new_direction = "down" if direction.y > 0 else "up"
	
	current_direction = new_direction
	_update_frame()

func set_direction_string(direction: String) -> void:
	"""Establecer dirección directamente por nombre"""
	if direction_locked:
		return
	if direction in DIRECTION_TO_FRAME:
		current_direction = direction
		_update_frame()

func force_direction(direction: Vector2, lock: bool = false) -> void:
	"""Forzar cambio de dirección"""
	var new_direction: String
	if abs(direction.x) > abs(direction.y):
		new_direction = "right" if direction.x > 0 else "left"
	else:
		new_direction = "down" if direction.y > 0 else "up"
	current_direction = new_direction
	if lock:
		direction_locked = true
	_update_frame()

func force_direction_string(direction: String, lock: bool = false) -> void:
	"""Forzar cambio de dirección por nombre"""
	if direction in DIRECTION_TO_FRAME:
		current_direction = direction
		if lock:
			direction_locked = true
		_update_frame()

func unlock_direction() -> void:
	"""Desbloquear la dirección"""
	direction_locked = false

func _update_frame() -> void:
	"""Actualizar el frame y flip según la dirección"""
	if frame_textures.is_empty():
		return
	
	var frame_index = DIRECTION_TO_FRAME.get(current_direction, 0)
	
	if frame_index < 0 or frame_index >= frame_textures.size():
		return
	
	var new_texture = frame_textures[frame_index]
	if new_texture == null:
		return
	
	texture = new_texture
	flip_h = (current_direction == "right")

func set_base_scale(new_scale: Vector2) -> void:
	"""Establecer escala base"""
	base_scale = new_scale
	scale = new_scale

func get_frame_size() -> Vector2:
	"""Obtener tamaño de un frame individual"""
	return Vector2(frame_width, frame_height)

# === MÉTODOS ESPECÍFICOS DE BOSS ===

func set_aura_color(color: Color) -> void:
	"""Cambiar el color del aura"""
	aura_color = color
	if aura_material:
		aura_material.set_shader_parameter("aura_color", color)

func set_aura_enabled(enabled: bool) -> void:
	"""Activar/desactivar el aura"""
	enable_aura = enabled
	if enabled and not aura_material:
		_setup_aura_shader()
	elif not enabled:
		material = null

func set_aura_width(width: float) -> void:
	"""Cambiar grosor del aura"""
	aura_width = width
	if aura_material:
		aura_material.set_shader_parameter("aura_width", width)

# === SISTEMA DE PARTÍCULAS FLOTANTES ===

func _exit_tree() -> void:
	# FIX-R7: Limpiar partículas huérfanas al destruirse el boss
	for particle in particles:
		if is_instance_valid(particle):
			particle.queue_free()
	particles.clear()

func _setup_particles() -> void:
	"""Crear partículas que orbitan alrededor del boss"""
	for i in range(particle_count):
		var particle = _create_particle(i)
		particles.append(particle)
		get_parent().add_child(particle)

func _create_particle(index: int) -> Node2D:
	"""Crear una partícula individual"""
	var particle = Node2D.new()
	
	# Sprite de la partícula (un simple círculo brillante)
	var sprite = Sprite2D.new()
	
	# Crear textura procedural para la partícula
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var center = Vector2(8, 8)
	for x in range(16):
		for y in range(16):
			var dist = Vector2(x, y).distance_to(center)
			if dist < 6:
				var alpha = 1.0 - (dist / 6.0)
				alpha = alpha * alpha  # Más brillante en el centro
				img.set_pixel(x, y, Color(aura_color.r, aura_color.g, aura_color.b, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	
	var tex = ImageTexture.create_from_image(img)
	sprite.texture = tex
	sprite.modulate = aura_color
	sprite.modulate.a = 0.8
	
	particle.add_child(sprite)
	
	# Guardar datos de órbita en metadata
	particle.set_meta("orbit_offset", (TAU / particle_count) * index)
	particle.set_meta("orbit_variation", randf_range(0.8, 1.2))
	particle.set_meta("size_variation", randf_range(0.5, 1.2))
	
	sprite.scale = Vector2.ONE * particle.get_meta("size_variation")
	
	return particle

func _update_particles() -> void:
	"""Actualizar posición de las partículas en órbita"""
	for particle in particles:
		if not is_instance_valid(particle):
			continue
		
		var orbit_offset = particle.get_meta("orbit_offset")
		var orbit_var = particle.get_meta("orbit_variation")
		
		# Calcular posición en órbita elíptica
		var angle = animation_time * particle_speed + orbit_offset
		var radius = particle_orbit_radius * orbit_var
		
		# Órbita ligeramente elíptica y con movimiento vertical
		var orbit_x = cos(angle) * radius
		var orbit_y = sin(angle) * radius * 0.4 + sin(angle * 2) * 10
		
		particle.global_position = global_position + Vector2(orbit_x, orbit_y)
		
		# Hacer que las partículas pulsen con el aura
		var pulse = 0.6 + sin(animation_time * aura_pulse_speed + orbit_offset) * 0.4
		particle.modulate.a = pulse * 0.8
		
		# Las partículas detrás del boss son más transparentes
		if orbit_y > 0:
			particle.modulate.a *= 0.5
			particle.z_index = -1
		else:
			particle.z_index = 1

func _process(delta: float) -> void:
	animation_time += delta
	
	# Resetear transformaciones
	offset = Vector2.ZERO
	rotation = 0.0
	scale = base_scale
	
	# Calcular fase del bobbing (más lenta)
	var bob_phase = sin(animation_time * bobbing_speed)
	
	# Aplicar animaciones
	if enable_bobbing:
		_apply_bobbing(bob_phase)
	
	if enable_breathing:
		_apply_breathing()
	
	if enable_sway:
		_apply_sway()
	
	# Actualizar pulso del aura
	if enable_aura and aura_material:
		_update_aura_pulse()
	
	# Actualizar partículas
	if enable_particles and particles.size() > 0:
		_update_particles()

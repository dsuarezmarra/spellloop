# AOEVisualEffect.gd
# Efecto visual animado para ataques de área (AOE)
# Estilo: Cartoon/Funko Pop con animaciones Appear → Active → Fade

class_name AOEVisualEffect
extends Node2D

# ═══════════════════════════════════════════════════════════════════════════════
# SEÑALES
# ═══════════════════════════════════════════════════════════════════════════════

signal appear_finished
signal active_started
signal fade_finished

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADOS
# ═══════════════════════════════════════════════════════════════════════════════

enum State {
	NONE,
	APPEARING,
	ACTIVE,
	FADING
}

var current_state: State = State.NONE
var visual_data: ProjectileVisualData

# ═══════════════════════════════════════════════════════════════════════════════
# NODOS
# ═══════════════════════════════════════════════════════════════════════════════

var sprite: AnimatedSprite2D
var glow_sprite: Sprite2D
var ring_sprite: Sprite2D  # Anillo exterior
var particles: GPUParticles2D

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

var _time: float = 0.0
var _radius: float = 100.0
var _duration: float = 0.5
var _active_time: float = 0.0

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_ensure_nodes_created()

func _ensure_nodes_created() -> void:
	"""Asegurar que los nodos estén creados"""
	if sprite == null:
		_create_nodes()

func setup(data: ProjectileVisualData, radius: float, duration: float = 0.5) -> void:
	"""Configurar el efecto AOE"""
	_ensure_nodes_created()
	visual_data = data
	_radius = radius
	_duration = duration
	
	if visual_data:
		_setup_animations()
	else:
		_setup_procedural()
	
	_setup_particles()

func _create_nodes() -> void:
	"""Crear estructura de nodos"""
	# Glow de fondo
	glow_sprite = Sprite2D.new()
	glow_sprite.name = "Glow"
	glow_sprite.z_index = -2
	add_child(glow_sprite)
	
	# Anillo exterior
	ring_sprite = Sprite2D.new()
	ring_sprite.name = "Ring"
	ring_sprite.z_index = -1
	add_child(ring_sprite)
	
	# Sprite principal animado
	sprite = AnimatedSprite2D.new()
	sprite.name = "MainSprite"
	sprite.centered = true
	add_child(sprite)
	sprite.animation_finished.connect(_on_animation_finished)

func _setup_animations() -> void:
	"""Configurar animaciones desde sprites"""
	var frames = SpriteFrames.new()
	var has_any_animation = false
	
	# Animación de aparición
	if visual_data.aoe_appear_spritesheet:
		_add_animation(frames, "appear", visual_data.aoe_appear_spritesheet, 
			visual_data.aoe_appear_frames, visual_data.aoe_fps, false)
		has_any_animation = true
	
	# Animación activa (loop)
	if visual_data.aoe_active_spritesheet:
		_add_animation(frames, "active", visual_data.aoe_active_spritesheet, 
			visual_data.aoe_active_frames, visual_data.aoe_fps, true)
		has_any_animation = true
	
	# Animación de fade
	if visual_data.aoe_fade_spritesheet:
		_add_animation(frames, "fade", visual_data.aoe_fade_spritesheet, 
			visual_data.aoe_fade_frames, visual_data.aoe_fps, false)
		has_any_animation = true
	
	# Si no hay ninguna animación de sprites, usar procedural
	if not has_any_animation:
		_setup_procedural()
		return
	
	sprite.sprite_frames = frames
	
	# Escalar según el radio
	var sprite_scale = _radius * 2.0 / visual_data.frame_size.x
	sprite.scale = Vector2.ONE * sprite_scale

func _setup_procedural() -> void:
	"""Crear animaciones procedurales estilo cartoon"""
	var frames = SpriteFrames.new()
	# OPTIMIZACIÓN: Usar tamaño fijo pequeño y escalar el sprite
	# En lugar de generar imágenes enormes, generamos a 64px y escalamos
	var base_size = 64  # Tamaño fijo para generación
	var target_scale = _radius * 2.0 / float(base_size)  # Escala para alcanzar el radio deseado
	
	# Colores por defecto o del visual_data
	var primary = visual_data.primary_color if visual_data else Color(0.4, 0.8, 1.0)
	var secondary = visual_data.secondary_color if visual_data else Color(0.2, 0.5, 0.9)
	var accent = visual_data.accent_color if visual_data else Color.WHITE
	var outline = visual_data.outline_color if visual_data else Color(0.1, 0.2, 0.4)
	
	# Appear animation (4 frames)
	frames.add_animation("appear")
	frames.set_animation_speed("appear", 12)
	frames.set_animation_loop("appear", false)
	for i in range(4):
		var tex = _generate_aoe_frame("appear", i, 4, base_size, primary, secondary, accent, outline)
		frames.add_frame("appear", tex)
	
	# Active animation (6 frames, loop)
	frames.add_animation("active")
	frames.set_animation_speed("active", 10)
	frames.set_animation_loop("active", true)
	for i in range(6):
		var tex = _generate_aoe_frame("active", i, 6, base_size, primary, secondary, accent, outline)
		frames.add_frame("active", tex)
	
	# Fade animation (4 frames)
	frames.add_animation("fade")
	frames.set_animation_speed("fade", 12)
	frames.set_animation_loop("fade", false)
	for i in range(4):
		var tex = _generate_aoe_frame("fade", i, 4, base_size, primary, secondary, accent, outline)
		frames.add_frame("fade", tex)
	
	sprite.sprite_frames = frames
	sprite.scale = Vector2.ONE * target_scale  # Escalar para alcanzar el tamaño correcto
	
	# Crear glow y ring con tamaño pequeño y escalar
	_create_glow_texture(base_size, primary)
	glow_sprite.scale = Vector2.ONE * target_scale * 1.5
	
	# Crear ring
	_create_ring_texture(base_size, outline, accent)
	ring_sprite.scale = Vector2.ONE * target_scale * 1.2

func _generate_aoe_frame(anim: String, frame_idx: int, total: int, size: int,
		primary: Color, secondary: Color, accent: Color, outline: Color) -> ImageTexture:
	"""Generar un frame de AOE estilo cartoon"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size * 0.4
	var progress = float(frame_idx) / float(total - 1) if total > 1 else 1.0
	
	match anim:
		"appear":
			# Círculo que crece con efecto "pop"
			var scale_factor: float
			if progress < 0.7:
				scale_factor = ease(progress / 0.7, 0.2) * 1.15  # Overshoot
			else:
				scale_factor = 1.15 - (progress - 0.7) / 0.3 * 0.15  # Settle
			_draw_aoe_circle(image, center, radius * scale_factor, primary, secondary, accent, outline, 1.0)
			
		"active":
			# Pulso y rotación de patrones
			var pulse = sin(progress * TAU) * 0.08 + 1.0
			var rotation_offset = progress * TAU * 0.5
			_draw_aoe_circle_animated(image, center, radius * pulse, primary, secondary, accent, outline, rotation_offset)
			
		"fade":
			# Desvanecimiento con contracción
			var fade_scale = 1.0 - ease(progress, 2.0) * 0.3
			var alpha = 1.0 - ease(progress, 1.5)
			var faded_primary = Color(primary.r, primary.g, primary.b, primary.a * alpha)
			var faded_secondary = Color(secondary.r, secondary.g, secondary.b, secondary.a * alpha)
			var faded_accent = Color(accent.r, accent.g, accent.b, accent.a * alpha)
			var faded_outline = Color(outline.r, outline.g, outline.b, outline.a * alpha)
			_draw_aoe_circle(image, center, radius * fade_scale, faded_primary, faded_secondary, faded_accent, faded_outline, alpha)
	
	return ImageTexture.create_from_image(image)

func _draw_aoe_circle(image: Image, center: Vector2, radius: float, 
		primary: Color, secondary: Color, accent: Color, outline: Color, alpha_mult: float) -> void:
	"""Dibujar círculo AOE estilo cartoon"""
	var outline_width = max(3.0, radius * 0.08)
	
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			# Outline exterior
			if dist <= radius + outline_width and dist > radius:
				image.set_pixel(x, y, Color(outline.r, outline.g, outline.b, outline.a * alpha_mult))
			# Interior con gradiente radial
			elif dist <= radius:
				var t = dist / radius
				# Gradiente del centro hacia afuera
				var base_color = accent.lerp(primary, t * 0.7)
				base_color = base_color.lerp(secondary, t * t)
				# Añadir transparencia hacia el centro para efecto de "energía"
				var center_alpha = 0.3 + t * 0.7
				base_color.a *= center_alpha * alpha_mult
				image.set_pixel(x, y, base_color)

func _draw_aoe_circle_animated(image: Image, center: Vector2, radius: float, 
		primary: Color, secondary: Color, accent: Color, outline: Color, rotation: float) -> void:
	"""Dibujar círculo AOE con patrón rotativo"""
	var outline_width = max(3.0, radius * 0.08)
	var num_segments = 8
	
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			var angle = (pos - center).angle() + rotation
			
			# Outline exterior
			if dist <= radius + outline_width and dist > radius:
				image.set_pixel(x, y, outline)
			# Interior
			elif dist <= radius:
				var t = dist / radius
				
				# Patrón de segmentos
				var segment_angle = fmod(angle + TAU, TAU)
				var segment_t = fmod(segment_angle, TAU / num_segments) / (TAU / num_segments)
				var segment_intensity = abs(segment_t - 0.5) * 2.0
				
				var base_color = accent.lerp(primary, t * 0.7)
				base_color = base_color.lerp(secondary, segment_intensity * 0.3)
				
				var center_alpha = 0.3 + t * 0.7
				base_color.a *= center_alpha
				image.set_pixel(x, y, base_color)

func _create_glow_texture(size: int, color: Color) -> void:
	"""Crear textura de resplandor"""
	var glow_size = int(size * 1.5)
	var image = Image.create(glow_size, glow_size, false, Image.FORMAT_RGBA8)
	var center = Vector2(glow_size / 2.0, glow_size / 2.0)
	
	for y in range(glow_size):
		for x in range(glow_size):
			var dist = Vector2(x, y).distance_to(center)
			var t = clamp(1.0 - dist / (glow_size * 0.45), 0.0, 1.0)
			t = t * t * t  # Falloff cúbico
			image.set_pixel(x, y, Color(color.r, color.g, color.b, t * 0.4))
	
	glow_sprite.texture = ImageTexture.create_from_image(image)

func _create_ring_texture(size: int, outline: Color, accent: Color) -> void:
	"""Crear textura de anillo exterior"""
	var ring_size = int(size * 1.2)
	var image = Image.create(ring_size, ring_size, false, Image.FORMAT_RGBA8)
	var center = Vector2(ring_size / 2.0, ring_size / 2.0)
	var outer_radius = ring_size * 0.45
	var inner_radius = ring_size * 0.42
	
	for y in range(ring_size):
		for x in range(ring_size):
			var dist = Vector2(x, y).distance_to(center)
			
			if dist <= outer_radius and dist >= inner_radius:
				var ring_t = (dist - inner_radius) / (outer_radius - inner_radius)
				var ring_color = outline.lerp(accent, abs(ring_t - 0.5) * 2.0)
				ring_color.a *= 0.6
				image.set_pixel(x, y, ring_color)
	
	ring_sprite.texture = ImageTexture.create_from_image(image)

func _add_animation(frames: SpriteFrames, anim_name: String, spritesheet: Texture2D,
		frame_count: int, fps: float, loop: bool) -> void:
	"""Añadir animación desde spritesheet"""
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, loop)
	
	var frame_size = visual_data.frame_size if visual_data else Vector2i(64, 64)
	
	for i in range(frame_count):
		var atlas = AtlasTexture.new()
		atlas.atlas = spritesheet
		atlas.region = Rect2(i * frame_size.x, 0, frame_size.x, frame_size.y)
		frames.add_frame(anim_name, atlas)

func _setup_particles() -> void:
	"""Configurar partículas del AOE"""
	particles = GPUParticles2D.new()
	particles.name = "Particles"
	particles.emitting = false
	particles.amount = 30
	particles.lifetime = 0.8
	particles.explosiveness = 0.3
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	material.emission_ring_radius = _radius * 0.8
	material.emission_ring_inner_radius = _radius * 0.3
	material.emission_ring_height = 0
	material.direction = Vector3(0, -1, 0)
	material.spread = 30.0
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
	material.gravity = Vector3(0, -20, 0)
	material.scale_min = 0.3
	material.scale_max = 0.8
	
	var color = visual_data.primary_color if visual_data else Color(0.4, 0.8, 1.0)
	material.color = color
	
	particles.process_material = material
	add_child(particles)

# ═══════════════════════════════════════════════════════════════════════════════
# CONTROL DE ESTADOS
# ═══════════════════════════════════════════════════════════════════════════════

func play_appear() -> void:
	"""Iniciar animación de aparición"""
	current_state = State.APPEARING
	
	# Animación de escala
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("appear"):
		sprite.play("appear")
	else:
		await tween.finished
		_on_animation_finished()
	
	# Activar partículas
	if particles:
		particles.emitting = true

func play_active(duration: float = -1.0) -> void:
	"""Mantener estado activo"""
	current_state = State.ACTIVE
	_active_time = duration if duration > 0 else _duration
	
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("active"):
		sprite.play("active")
	
	active_started.emit()
	
	# Auto-fade después del tiempo
	if _active_time > 0:
		await get_tree().create_timer(_active_time).timeout
		if current_state == State.ACTIVE:
			play_fade()

func play_fade() -> void:
	"""Iniciar animación de desvanecimiento"""
	current_state = State.FADING
	
	# Desactivar partículas
	if particles:
		particles.emitting = false
	
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("fade"):
		sprite.play("fade")
	
	# Tween de escala y alpha
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2.ONE * 0.8, 0.3)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	
	# Asegurar que la señal se emita al terminar el tween si no hay animación de sprite
	if not sprite.sprite_frames or not sprite.sprite_frames.has_animation("fade"):
		tween.finished.connect(func(): _on_animation_finished())

func _on_animation_finished() -> void:
	"""Manejar fin de animaciones"""
	match current_state:
		State.APPEARING:
			appear_finished.emit()
			play_active()
		State.FADING:
			fade_finished.emit()
			queue_free()

# ═══════════════════════════════════════════════════════════════════════════════
# PROCESO
# ═══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	_time += delta
	
	# Pulso del glow
	if glow_sprite:
		var pulse = sin(_time * 3.0) * 0.15 + 1.0
		glow_sprite.scale = Vector2.ONE * pulse
		glow_sprite.modulate.a = 0.4 + sin(_time * 5.0) * 0.1
	
	# Rotación del ring
	if ring_sprite:
		ring_sprite.rotation += delta * 0.5

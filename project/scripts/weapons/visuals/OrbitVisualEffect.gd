# OrbitVisualEffect.gd
# Efecto visual para proyectiles orbitales
# Estilo: Cartoon/Funko Pop con orbes que giran alrededor del jugador

class_name OrbitVisualEffect
extends Node2D

# ═══════════════════════════════════════════════════════════════════════════════
# SEÑALES
# ═══════════════════════════════════════════════════════════════════════════════

signal orbit_spawned
signal orbit_destroyed

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

var visual_data: ProjectileVisualData

# Colores
var _primary_color: Color = Color(0.5, 0.2, 0.8)    # Púrpura
var _secondary_color: Color = Color(0.7, 0.4, 1.0)  # Lavanda
var _core_color: Color = Color.WHITE                 # Centro brillante
var _outline_color: Color = Color(0.2, 0.1, 0.4)    # Outline oscuro
var _glow_color: Color = Color(0.6, 0.3, 1.0, 0.4)

# Parámetros del orbe
var _orb_size: float = 24.0
var _orbit_radius: float = 60.0
var _base_rotation_speed: float = 2.0

# ═══════════════════════════════════════════════════════════════════════════════
# COMPONENTES VISUALES
# ═══════════════════════════════════════════════════════════════════════════════

var sprite: AnimatedSprite2D
var glow_sprite: Sprite2D
var trail: GPUParticles2D

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADO
# ═══════════════════════════════════════════════════════════════════════════════

var _time: float = 0.0
var _angle: float = 0.0
var _rotation_speed: float = 2.0
var _spawn_progress: float = 0.0
var _is_spawning: bool = false
var _is_destroying: bool = false

# Squash & stretch
var _squash_amount: float = 0.15
var _squash_frequency: float = 3.0

# === OPTIMIZACIÓN ===
var _frame_counter: int = 0
const VISUAL_UPDATE_INTERVAL: int = 2  # Actualizar efectos cada N frames

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_ensure_nodes_created()

func _ensure_nodes_created() -> void:
	"""Asegurar que los nodos estén creados"""
	if sprite == null:
		_create_nodes()

func setup(data: ProjectileVisualData = null, orbit_radius: float = 60.0, 
		initial_angle: float = 0.0, orb_size: float = 24.0) -> void:
	"""Configurar el orbital"""
	_ensure_nodes_created()
	visual_data = data
	_orbit_radius = orbit_radius
	_angle = initial_angle
	_orb_size = orb_size
	
	if visual_data:
		_primary_color = visual_data.primary_color
		_secondary_color = visual_data.secondary_color
		_core_color = visual_data.accent_color
		_outline_color = visual_data.outline_color
		_glow_color = visual_data.glow_color if visual_data.glow_color else Color(visual_data.primary_color, 0.4)
		_rotation_speed = _base_rotation_speed
		_setup_from_sprites()
	else:
		_setup_procedural()
	
	_setup_glow()
	_setup_trail()
	_update_position()

func _create_nodes() -> void:
	"""Crear estructura de nodos"""
	# Glow
	glow_sprite = Sprite2D.new()
	glow_sprite.name = "Glow"
	glow_sprite.z_index = -1
	add_child(glow_sprite)
	
	# Sprite principal
	sprite = AnimatedSprite2D.new()
	sprite.name = "OrbSprite"
	sprite.centered = true
	add_child(sprite)
	sprite.animation_finished.connect(_on_animation_finished)

func _setup_from_sprites() -> void:
	"""Configurar desde spritesheets"""
	var frames = SpriteFrames.new()
	
	# Spawn animation
	if visual_data.orbit_spawn_spritesheet:
		_add_animation(frames, "spawn", visual_data.orbit_spawn_spritesheet,
			visual_data.orbit_spawn_frames, visual_data.orbit_fps, false)
	
	# Idle/orbit animation
	if visual_data.orbit_idle_spritesheet:
		_add_animation(frames, "orbit", visual_data.orbit_idle_spritesheet,
			visual_data.orbit_idle_frames, visual_data.orbit_fps, true)
	
	sprite.sprite_frames = frames

func _setup_procedural() -> void:
	"""Crear animaciones procedurales"""
	var frames = SpriteFrames.new()
	var size = int(_orb_size * 2)
	
	# Spawn animation (orbe que aparece con pop)
	frames.add_animation("spawn")
	frames.set_animation_speed("spawn", 12)
	frames.set_animation_loop("spawn", false)
	for i in range(6):
		var tex = _generate_spawn_frame(i, 6, size)
		frames.add_frame("spawn", tex)
	
	# Orbit animation (orbe con brillo pulsante)
	frames.add_animation("orbit")
	frames.set_animation_speed("orbit", 10)
	frames.set_animation_loop("orbit", true)
	for i in range(8):
		var tex = _generate_orbit_frame(i, 8, size)
		frames.add_frame("orbit", tex)
	
	# Destroy animation (desvanecimiento)
	frames.add_animation("destroy")
	frames.set_animation_speed("destroy", 15)
	frames.set_animation_loop("destroy", false)
	for i in range(5):
		var tex = _generate_destroy_frame(i, 5, size)
		frames.add_frame("destroy", tex)
	
	sprite.sprite_frames = frames

func _generate_spawn_frame(frame_idx: int, total: int, size: int) -> ImageTexture:
	"""Generar frame de spawn con efecto pop"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var progress = float(frame_idx) / float(total - 1) if total > 1 else 1.0
	
	# Efecto de overshoot
	var scale_factor: float
	if progress < 0.6:
		scale_factor = ease(progress / 0.6, 0.3) * 1.25
	else:
		scale_factor = 1.25 - (progress - 0.6) / 0.4 * 0.25
	
	var radius = size * 0.35 * scale_factor
	var outline_width = max(2.0, size * 0.06)
	
	_draw_cartoon_orb(image, center, radius, outline_width, 1.0)
	
	return ImageTexture.create_from_image(image)

func _generate_orbit_frame(frame_idx: int, total: int, size: int) -> ImageTexture:
	"""Generar frame de orbit con brillo animado"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var progress = float(frame_idx) / float(total - 1) if total > 1 else 0.0
	
	var radius = size * 0.35
	var outline_width = max(2.0, size * 0.06)
	
	# Variación de brillo
	var brightness = sin(progress * TAU) * 0.15 + 1.0
	
	_draw_cartoon_orb(image, center, radius, outline_width, brightness)
	
	return ImageTexture.create_from_image(image)

func _generate_destroy_frame(frame_idx: int, total: int, size: int) -> ImageTexture:
	"""Generar frame de destrucción"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var progress = float(frame_idx) / float(total - 1) if total > 1 else 1.0
	
	var radius = size * 0.35 * (1.0 + progress * 0.5)  # Expandirse
	var outline_width = max(2.0, size * 0.06) * (1.0 - progress)
	var alpha = 1.0 - ease(progress, 2.0)
	
	_draw_cartoon_orb(image, center, radius, outline_width, 1.0, alpha)
	
	return ImageTexture.create_from_image(image)

func _draw_cartoon_orb(image: Image, center: Vector2, radius: float, 
		outline_width: float, brightness: float = 1.0, alpha_mult: float = 1.0) -> void:
	"""Dibujar orbe estilo cartoon"""
	var size = image.get_height()
	
	for y in range(size):
		for x in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			# Outline
			if dist <= radius + outline_width and dist > radius:
				var outline_color = Color(_outline_color.r, _outline_color.g, _outline_color.b, alpha_mult)
				image.set_pixel(x, y, outline_color)
			# Interior
			elif dist <= radius:
				var t = dist / radius
				
				# Gradiente radial con highlight
				var base_color = _core_color.lerp(_primary_color, t * 0.5)
				base_color = base_color.lerp(_secondary_color, t * t)
				
				# Highlight en la esquina superior izquierda
				var highlight_pos = center - Vector2(radius * 0.35, radius * 0.35)
				var highlight_dist = pos.distance_to(highlight_pos)
				var highlight_t = clamp(1.0 - highlight_dist / (radius * 0.5), 0.0, 1.0)
				base_color = base_color.lerp(_core_color, highlight_t * highlight_t * 0.7)
				
				# Aplicar brillo
				base_color.r = clamp(base_color.r * brightness, 0.0, 1.0)
				base_color.g = clamp(base_color.g * brightness, 0.0, 1.0)
				base_color.b = clamp(base_color.b * brightness, 0.0, 1.0)
				base_color.a *= alpha_mult
				
				image.set_pixel(x, y, base_color)

func _setup_glow() -> void:
	"""Crear textura de glow"""
	var glow_size = int(_orb_size * 4)
	var image = Image.create(glow_size, glow_size, false, Image.FORMAT_RGBA8)
	var center = Vector2(glow_size / 2.0, glow_size / 2.0)
	
	for y in range(glow_size):
		for x in range(glow_size):
			var dist = Vector2(x, y).distance_to(center)
			var t = clamp(1.0 - dist / (glow_size * 0.45), 0.0, 1.0)
			t = t * t * t
			image.set_pixel(x, y, Color(_glow_color.r, _glow_color.g, _glow_color.b, t * _glow_color.a))
	
	glow_sprite.texture = ImageTexture.create_from_image(image)

func _setup_trail() -> void:
	"""Configurar partículas de trail"""
	trail = GPUParticles2D.new()
	trail.name = "Trail"
	trail.emitting = false
	trail.amount = 15
	trail.lifetime = 0.4
	trail.local_coords = false
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	material.direction = Vector3(0, 0, 0)
	material.spread = 180.0
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 15.0
	material.gravity = Vector3.ZERO
	material.scale_min = 0.2
	material.scale_max = 0.5
	material.color = _secondary_color
	
	# Fade out
	var color_curve = Gradient.new()
	color_curve.add_point(0.0, Color(_secondary_color, 1.0))
	color_curve.add_point(1.0, Color(_secondary_color, 0.0))
	material.color_ramp = GradientTexture1D.new()
	(material.color_ramp as GradientTexture1D).gradient = color_curve
	
	trail.process_material = material
	add_child(trail)

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

# ═══════════════════════════════════════════════════════════════════════════════
# CONTROL
# ═══════════════════════════════════════════════════════════════════════════════

func spawn() -> void:
	"""Iniciar animación de spawn"""
	_is_spawning = true
	_spawn_progress = 0.0
	
	sprite.scale = Vector2.ZERO
	glow_sprite.scale = Vector2.ZERO
	
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("spawn"):
		sprite.play("spawn")
	
	# Animación de escala
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(glow_sprite, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT)
	
	# Activar trail
	if trail:
		trail.emitting = true
	
	await tween.finished
	_is_spawning = false
	
	# Cambiar a animación de orbit
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("orbit"):
		sprite.play("orbit")
	
	orbit_spawned.emit()

func destroy() -> void:
	"""Destruir el orbital con animación"""
	_is_destroying = true
	
	if trail:
		trail.emitting = false
	
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("destroy"):
		sprite.play("destroy")
	
	var tween = create_tween()
	tween.parallel().tween_property(sprite, "scale", Vector2.ONE * 1.5, 0.3)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(glow_sprite, "scale", Vector2.ONE * 2.0, 0.3)
	tween.parallel().tween_property(glow_sprite, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	orbit_destroyed.emit()
	queue_free()

func set_orbit_speed(speed: float) -> void:
	"""Cambiar velocidad de rotación"""
	_rotation_speed = speed

func update_orbital_positions(positions: Array[Vector2]) -> void:
	"""Actualizar posiciones desde OrbitalManager (este orbe es un solo elemento)"""
	# Este visual es un orbe individual, no necesita array de posiciones
	# Se actualiza automáticamente via _update_position()
	pass

func _update_position() -> void:
	"""Actualizar posición en la órbita"""
	var orbit_pos = Vector2(
		cos(_angle) * _orbit_radius,
		sin(_angle) * _orbit_radius
	)
	position = orbit_pos

func _on_animation_finished() -> void:
	"""Callback de animación terminada"""
	if sprite.animation == "spawn":
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("orbit"):
			sprite.play("orbit")
	elif sprite.animation == "destroy":
		queue_free()

# ═══════════════════════════════════════════════════════════════════════════════
# PROCESO
# ═══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	_time += delta
	
	if _is_destroying:
		return
	
	# Actualizar ángulo (siempre necesario para posición)
	_angle += _rotation_speed * delta
	_update_position()
	
	# OPTIMIZACIÓN: Throttle para efectos visuales innecesarios a 60fps
	_frame_counter += 1
	if _frame_counter < VISUAL_UPDATE_INTERVAL:
		return
	_frame_counter = 0
	
	# Squash & Stretch basado en la dirección del movimiento
	if not _is_spawning:
		var velocity_angle = _angle + PI / 2  # Perpendicular a la órbita
		# Aproximación rápida de sin usando triángulo
		var phase = fmod(_time * _squash_frequency * _rotation_speed, TAU)
		var squash_factor = 1.0 - abs(phase - PI) / PI * 2.0
		var squash = squash_factor * _squash_amount
		
		# Aplicar squash en la dirección del movimiento
		var stretch_x = 1.0 + squash
		var stretch_y = 1.0 - squash * 0.5
		
		sprite.scale = Vector2(stretch_x, stretch_y)
		sprite.rotation = velocity_angle
	
	# Pulso del glow (optimizado)
	if glow_sprite:
		var glow_phase = fmod(_time * 4.0, TAU)
		var glow_pulse = 1.0 - abs(glow_phase - PI) / PI * 0.4  # 0.8 a 1.2
		glow_sprite.modulate.a = 0.5 + glow_pulse * 0.075  # 0.425 a 0.575
		glow_sprite.scale = Vector2.ONE * (0.8 + glow_pulse * 0.2)

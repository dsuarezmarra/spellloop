# VoidBoltVisual.gd
# Efecto visual para rayos del vacío encadenados (Lightning + Void fusion)
# Estilo: Cartoon/Funko Pop con energía del vacío - púrpura oscuro con distorsiones

class_name VoidBoltVisual
extends Node2D

# ═══════════════════════════════════════════════════════════════════════════════
# SEÑALES
# ═══════════════════════════════════════════════════════════════════════════════

signal chain_complete
signal all_chains_finished

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

var visual_data: ProjectileVisualData

# Sprites personalizados
var _use_custom_sprites: bool = false
var _bolt_spritesheet: Texture2D
var _zap_spritesheet: Texture2D
var _bolt_frames: int = 4
var _zap_frames: int = 4
var _bolt_fps: float = 18.0  # Más lento - energía del vacío
var _zap_fps: float = 20.0   # Impacto de vacío

# Colores (Lightning + Void = Deep purple con cyan eléctrico)
var _primary_color: Color = Color(0.18, 0.1, 0.3)    # Púrpura profundo del vacío
var _secondary_color: Color = Color(0.27, 0.47, 1.0) # Azul eléctrico
var _core_color: Color = Color(0.88, 1.0, 1.0)       # Cyan-blanco brillante
var _outline_color: Color = Color(0.05, 0.02, 0.13)  # Negro-púrpura abismal

# Parámetros del rayo de vacío
var _bolt_width: float = 3.0
var _glow_width: float = 10.0
var _bolt_segments: int = 6
var _jitter_amount: float = 12.0  # Distorsión del vacío

# ═══════════════════════════════════════════════════════════════════════════════
# COMPONENTES
# ═══════════════════════════════════════════════════════════════════════════════

var _main_bolt: Line2D
var _glow_bolt: Line2D
var _outline_bolt: Line2D
var _impact_particles: Array[Sprite2D] = []
var _bolt_sprites: Array[AnimatedSprite2D] = []
var _zap_sprites: Array[AnimatedSprite2D] = []

var _start_pos: Vector2
var _end_pos: Vector2
var _time: float = 0.0
var _is_active: bool = false
var _fade_timer: float = 0.0
var _max_duration: float = 0.5
var _expected_chains: int = 2

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func setup(data: ProjectileVisualData = null, chain_count: int = 2) -> void:
	"""Configurar el efecto chain de rayo del vacío"""
	visual_data = data
	_expected_chains = chain_count
	_max_duration = max(0.5, chain_count * 0.15 + 0.3)

	if visual_data:
		_primary_color = visual_data.primary_color
		_secondary_color = visual_data.secondary_color
		_core_color = visual_data.accent_color
		_outline_color = visual_data.outline_color

	_try_load_custom_sprites()

	if not _use_custom_sprites:
		_create_bolt_lines()

func _try_load_custom_sprites() -> void:
	"""Cargar sprites personalizados para el rayo del vacío"""
	var base_path = "res://assets/sprites/projectiles/fusion/void_bolt/"

	var bolt_path = base_path + "flight_spritesheet_void_bolt.png"
	var zap_path = base_path + "impact_spritesheet_void_bolt.png"

	if ResourceLoader.exists(bolt_path) and ResourceLoader.exists(zap_path):
		_bolt_spritesheet = load(bolt_path) as Texture2D
		_zap_spritesheet = load(zap_path) as Texture2D

		if _bolt_spritesheet and _zap_spritesheet:
			_use_custom_sprites = true
			print("[VoidBoltVisual] 🕳️⚡ Sprites personalizados cargados")

func _create_bolt_lines() -> void:
	"""Crear las líneas del rayo del vacío (modo procedural)"""
	# Outline (negro-púrpura abismal)
	_outline_bolt = Line2D.new()
	_outline_bolt.width = _bolt_width + 4
	_outline_bolt.default_color = _outline_color
	_outline_bolt.joint_mode = Line2D.LINE_JOINT_ROUND
	_outline_bolt.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_outline_bolt.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(_outline_bolt)

	# Glow externo (púrpura profundo con transparencia)
	_glow_bolt = Line2D.new()
	_glow_bolt.width = _glow_width
	_glow_bolt.default_color = Color(_primary_color.r, _primary_color.g, _primary_color.b, 0.4)
	_glow_bolt.joint_mode = Line2D.LINE_JOINT_ROUND
	add_child(_glow_bolt)

	# Rayo principal (azul eléctrico)
	_main_bolt = Line2D.new()
	_main_bolt.width = _bolt_width
	_main_bolt.default_color = _secondary_color
	_main_bolt.joint_mode = Line2D.LINE_JOINT_ROUND
	_main_bolt.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_main_bolt.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(_main_bolt)

# ═══════════════════════════════════════════════════════════════════════════════
# API PÚBLICA
# ═══════════════════════════════════════════════════════════════════════════════

func fire_at(start: Vector2, target: Vector2) -> void:
	"""Disparar rayo del vacío hacia un objetivo"""
	fire_chain(start, target)

func fire_chain(start: Vector2, end: Vector2) -> void:
	"""Disparar un segmento de cadena del rayo del vacío"""
	_start_pos = start
	_end_pos = end
	_is_active = true
	_fade_timer = 0.0
	_time = 0.0

	if _use_custom_sprites:
		_fire_with_sprites(start, end)
	else:
		_update_bolt_points()

	emit_signal("chain_complete")

func _fire_with_sprites(start: Vector2, end: Vector2) -> void:
	"""Disparar usando sprites personalizados"""
	var direction = (end - start).normalized()
	var distance = start.distance_to(end)
	var angle = direction.angle()

	# Crear sprite del rayo (bolt)
	var bolt_sprite = _create_bolt_sprite()
	bolt_sprite.position = start + direction * (distance * 0.5)
	bolt_sprite.rotation = angle
	bolt_sprite.scale.x = distance / 64.0  # Escalar horizontalmente
	add_child(bolt_sprite)
	_bolt_sprites.append(bolt_sprite)
	bolt_sprite.play("flight")

	# Crear sprite de impacto (zap) en el punto final
	var zap_sprite = _create_zap_sprite()
	zap_sprite.position = end
	add_child(zap_sprite)
	_zap_sprites.append(zap_sprite)
	zap_sprite.play("impact")

func _create_bolt_sprite() -> AnimatedSprite2D:
	"""Crear un sprite animado para el rayo del vacío"""
	var sprite = AnimatedSprite2D.new()
	var frames = SpriteFrames.new()

	frames.add_animation("flight")
	frames.set_animation_loop("flight", true)
	frames.set_animation_speed("flight", _bolt_fps)

	var frame_width = _bolt_spritesheet.get_width() / _bolt_frames
	var frame_height = _bolt_spritesheet.get_height()

	for i in range(_bolt_frames):
		var atlas = AtlasTexture.new()
		atlas.atlas = _bolt_spritesheet
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		frames.add_frame("flight", atlas)

	sprite.sprite_frames = frames
	sprite.centered = true
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.95)
	return sprite

func _create_zap_sprite() -> AnimatedSprite2D:
	"""Crear un sprite animado para el impacto del vacío"""
	var sprite = AnimatedSprite2D.new()
	var frames = SpriteFrames.new()

	frames.add_animation("impact")
	frames.set_animation_loop("impact", false)
	frames.set_animation_speed("impact", _zap_fps)

	var frame_width = _zap_spritesheet.get_width() / _zap_frames
	var frame_height = _zap_spritesheet.get_height()

	for i in range(_zap_frames):
		var atlas = AtlasTexture.new()
		atlas.atlas = _zap_spritesheet
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		frames.add_frame("impact", atlas)

	sprite.sprite_frames = frames
	sprite.centered = true
	sprite.scale = Vector2(1.2, 1.2)  # Impacto ligeramente más grande
	return sprite

# ═══════════════════════════════════════════════════════════════════════════════
# GENERACIÓN DE PUNTOS DEL RAYO (PROCEDURAL)
# ═══════════════════════════════════════════════════════════════════════════════

func _update_bolt_points() -> void:
	"""Actualizar los puntos del rayo con efecto distorsión del vacío"""
	var points = PackedVector2Array()
	points.append(_start_pos)

	var direction = (_end_pos - _start_pos).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	var total_distance = _start_pos.distance_to(_end_pos)
	var segment_length = total_distance / _bolt_segments

	for i in range(1, _bolt_segments):
		var base_pos = _start_pos + direction * (segment_length * i)
		# Distorsión del vacío - más caótica en el centro
		var center_factor = 1.0 - abs(float(i) / _bolt_segments - 0.5) * 2.0
		var jitter = perpendicular * randf_range(-_jitter_amount, _jitter_amount) * (1.0 + center_factor * 0.5)
		# Añadir pequeña oscilación temporal
		jitter += perpendicular * sin(_time * 20.0 + i * 1.5) * 3.0
		points.append(base_pos + jitter)

	points.append(_end_pos)

	if _outline_bolt:
		_outline_bolt.points = points
	if _glow_bolt:
		_glow_bolt.points = points
	if _main_bolt:
		_main_bolt.points = points

# ═══════════════════════════════════════════════════════════════════════════════
# PROCESO
# ═══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if not _is_active:
		return

	_time += delta
	_fade_timer += delta

	if not _use_custom_sprites:
		# Actualizar puntos del rayo (distorsión continua del vacío)
		if randf() < 0.4:  # Actualizar frecuentemente para efecto caótico
			_update_bolt_points()

	# Fade out
	if _fade_timer > _max_duration * 0.6:
		var fade_progress = (_fade_timer - _max_duration * 0.6) / (_max_duration * 0.4)
		var alpha = 1.0 - fade_progress

		if _use_custom_sprites:
			for sprite in _bolt_sprites:
				if is_instance_valid(sprite):
					sprite.modulate.a = alpha
			for sprite in _zap_sprites:
				if is_instance_valid(sprite):
					sprite.modulate.a = alpha
		else:
			if _main_bolt:
				_main_bolt.modulate.a = alpha
			if _glow_bolt:
				_glow_bolt.modulate.a = alpha * 0.5
			if _outline_bolt:
				_outline_bolt.modulate.a = alpha

	# Terminar
	if _fade_timer >= _max_duration:
		_cleanup()
		emit_signal("all_chains_finished")
		queue_free()

func _cleanup() -> void:
	"""Limpiar todos los componentes"""
	_is_active = false

	for sprite in _bolt_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	_bolt_sprites.clear()

	for sprite in _zap_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	_zap_sprites.clear()

	for particle in _impact_particles:
		if is_instance_valid(particle):
			particle.queue_free()
	_impact_particles.clear()

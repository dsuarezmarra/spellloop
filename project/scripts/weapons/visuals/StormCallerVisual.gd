# StormCallerVisual.gd
# Efecto visual para rayos de tormenta encadenados (Lightning + Wind fusion)
# Estilo: Cartoon/Funko Pop con rayos azul-púrpura de tormenta eléctrica

class_name StormCallerVisual
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
var _bolt_fps: float = 20.0  # Velocidad media - tormenta poderosa
var _zap_fps: float = 22.0   # Impacto de tormenta

# Colores (Lightning + Wind = Azul-púrpura de tormenta)
var _primary_color: Color = Color(0.5, 0.6, 0.95)     # Azul eléctrico
var _secondary_color: Color = Color(0.7, 0.5, 0.9)    # Púrpura tormentoso
var _core_color: Color = Color(0.9, 0.95, 1.0)        # Blanco brillante (centro del rayo)
var _outline_color: Color = Color(0.25, 0.25, 0.5)    # Azul muy oscuro

# Parámetros del rayo de tormenta
var _bolt_width: float = 4.5
var _glow_width: float = 16.0
var _bolt_segments: int = 8  # Más segmentos = más dinámico
var _jitter_amount: float = 12.0  # Jitter moderado - como rayos naturales

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
var _expected_chains: int = 3  # Storm caller típicamente tiene 3 saltos

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func setup(data: ProjectileVisualData = null, chain_count: int = 3) -> void:
	"""Configurar el efecto chain de tormenta"""
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
	"""Cargar sprites personalizados para el rayo de tormenta"""
	var base_path = "res://assets/sprites/projectiles/fusion/storm_caller/"

	var bolt_path = base_path + "flight_spritesheet_storm_caller.png"
	var zap_path = base_path + "impact_spritesheet_storm_caller.png"

	if ResourceLoader.exists(bolt_path) and ResourceLoader.exists(zap_path):
		_bolt_spritesheet = load(bolt_path) as Texture2D
		_zap_spritesheet = load(zap_path) as Texture2D

		if _bolt_spritesheet and _zap_spritesheet:
			_use_custom_sprites = true
			print("[StormCallerVisual] ⚡🌪️ Sprites personalizados cargados")

func _create_bolt_lines() -> void:
	"""Crear las líneas del rayo de tormenta (modo procedural)"""
	# Outline (azul muy oscuro)
	_outline_bolt = Line2D.new()
	_outline_bolt.width = _bolt_width + 3.0
	_outline_bolt.default_color = _outline_color
	_outline_bolt.joint_mode = Line2D.LINE_JOINT_ROUND
	_outline_bolt.end_cap_mode = Line2D.LINE_CAP_ROUND
	_outline_bolt.antialiased = true
	add_child(_outline_bolt)

	# Glow (azul eléctrico suave)
	_glow_bolt = Line2D.new()
	_glow_bolt.width = _glow_width
	_glow_bolt.default_color = Color(_primary_color.r, _primary_color.g, _primary_color.b, 0.4)
	_glow_bolt.joint_mode = Line2D.LINE_JOINT_ROUND
	_glow_bolt.end_cap_mode = Line2D.LINE_CAP_ROUND
	_glow_bolt.antialiased = true
	add_child(_glow_bolt)

	# Rayo principal con gradiente de tormenta
	_main_bolt = Line2D.new()
	_main_bolt.width = _bolt_width
	_main_bolt.default_color = _primary_color

	# Gradiente azul-púrpura
	var gradient = Gradient.new()
	gradient.add_point(0.0, _secondary_color)
	gradient.add_point(0.5, _core_color)
	gradient.add_point(1.0, _primary_color)
	_main_bolt.gradient = gradient

	_main_bolt.joint_mode = Line2D.LINE_JOINT_ROUND
	_main_bolt.end_cap_mode = Line2D.LINE_CAP_ROUND
	_main_bolt.antialiased = true
	add_child(_main_bolt)

func fire_chain(from: Vector2, to: Vector2) -> void:
	"""Disparar un rayo de tormenta de from a to"""
	_start_pos = from
	_end_pos = to
	_is_active = true
	_time = 0.0
	_fade_timer = 0.0

	if _use_custom_sprites:
		_create_sprite_bolt(from, to)
	else:
		_update_bolt_path()

func fire_at(from: Vector2, to: Vector2) -> void:
	"""Alias para fire_chain - compatibilidad con ProjectileFactory"""
	fire_chain(from, to)

func _create_sprite_bolt(from: Vector2, to: Vector2) -> void:
	"""Crear sprite animado del rayo de tormenta entre dos puntos"""
	var bolt_sprite = AnimatedSprite2D.new()
	var frames = SpriteFrames.new()
	frames.add_animation("default")

	# Añadir frames del spritesheet
	var frame_width = 64
	for i in range(_bolt_frames):
		var region = Rect2(i * frame_width, 0, frame_width, 64)
		var atlas = AtlasTexture.new()
		atlas.atlas = _bolt_spritesheet
		atlas.region = region
		frames.add_frame("default", atlas, i)

	frames.set_animation_speed("default", _bolt_fps)
	bolt_sprite.sprite_frames = frames

	# Posicionar y orientar
	var direction = (to - from).normalized()
	var distance = from.distance_to(to)
	var midpoint = (from + to) / 2.0

	bolt_sprite.position = midpoint
	bolt_sprite.rotation = direction.angle()
	bolt_sprite.scale = Vector2(distance / frame_width, 1.0)

	add_child(bolt_sprite)
	_bolt_sprites.append(bolt_sprite)
	bolt_sprite.play("default")

	# Crear impacto en destino
	_create_sprite_zap(to)

	# Auto-cleanup después de la animación
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(bolt_sprite):
		bolt_sprite.queue_free()

	emit_signal("chain_complete")

func _create_sprite_zap(at_pos: Vector2) -> void:
	"""Crear sprite animado de impacto de tormenta"""
	var zap_sprite = AnimatedSprite2D.new()
	var frames = SpriteFrames.new()
	frames.add_animation("default")

	# Añadir frames del spritesheet de impacto
	var frame_width = 64
	for i in range(_zap_frames):
		var region = Rect2(i * frame_width, 0, frame_width, 64)
		var atlas = AtlasTexture.new()
		atlas.atlas = _zap_spritesheet
		atlas.region = region
		frames.add_frame("default", atlas, i)

	frames.set_animation_speed("default", _zap_fps)
	zap_sprite.sprite_frames = frames
	zap_sprite.position = at_pos

	add_child(zap_sprite)
	_zap_sprites.append(zap_sprite)
	zap_sprite.play("default")

	# Auto-cleanup
	await get_tree().create_timer(0.25).timeout
	if is_instance_valid(zap_sprite):
		zap_sprite.queue_free()

func _update_bolt_path() -> void:
	"""Generar los puntos del rayo de tormenta (natural y dinámico)"""
	var points = _generate_lightning_points(_start_pos, _end_pos, _bolt_segments)

	if _outline_bolt:
		_outline_bolt.points = points
	if _glow_bolt:
		_glow_bolt.points = points
	if _main_bolt:
		_main_bolt.points = points

func _generate_lightning_points(from: Vector2, to: Vector2, segments: int) -> PackedVector2Array:
	"""Generar los puntos del rayo de tormenta (natural y dinámico)"""
	var points = PackedVector2Array()
	points.append(from)

	var direction = (to - from)
	var distance = direction.length()
	var normalized_dir = direction.normalized()
	var perpendicular = Vector2(-normalized_dir.y, normalized_dir.x)

	# Crear segmentos con jitter
	for i in range(1, segments):
		var t = float(i) / float(segments)
		var base_pos = from + direction * t

		# Jitter perpendicular (más natural que plasma)
		var jitter_offset = perpendicular * randf_range(-_jitter_amount, _jitter_amount)
		var point = base_pos + jitter_offset

		points.append(point)

	points.append(to)
	return points

func _process(delta: float) -> void:
	if not _is_active:
		return

	_time += delta
	_fade_timer += delta

	# Actualizar rayo (solo en modo procedural)
	if not _use_custom_sprites and _time < 0.1:
		# Regenerar ligeramente los puntos para efecto de "chispa"
		_update_bolt_path()

	# Fade out
	if _fade_timer >= _max_duration:
		_cleanup()

func _cleanup() -> void:
	"""Limpiar efectos visuales"""
	_is_active = false

	# Limpiar líneas procedurales
	if _main_bolt:
		_main_bolt.points = PackedVector2Array()
	if _glow_bolt:
		_glow_bolt.points = PackedVector2Array()
	if _outline_bolt:
		_outline_bolt.points = PackedVector2Array()

	# Limpiar sprites
	for sprite in _bolt_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	_bolt_sprites.clear()

	for sprite in _zap_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	_zap_sprites.clear()

	emit_signal("all_chains_finished")

func reset() -> void:
	"""Resetear el efecto para reutilización"""
	_cleanup()
	_time = 0.0
	_fade_timer = 0.0

# ═══════════════════════════════════════════════════════════════════════════════
# SECUENCIAS DE CADENA
# ═══════════════════════════════════════════════════════════════════════════════

func create_chain_sequence(targets: Array[Vector2], delay_between: float = 0.08) -> void:
	"""Crear una secuencia de rayos de tormenta entre múltiples objetivos"""
	if targets.size() < 2:
		return

	for i in range(targets.size() - 1):
		if i > 0:
			await get_tree().create_timer(delay_between).timeout

		fire_chain(targets[i], targets[i + 1])

	emit_signal("all_chains_finished")

# ShadowBoltVisual.gd
# Efecto visual para rayos de sombra encadenados (Shadow + Lightning fusion)
# Estilo: Cartoon/Funko Pop con rayos oscuros etéreos y chispas fantasmales

class_name ShadowBoltVisual
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
var _bolt_fps: float = 18.0  # Más lento - sombra etérea
var _zap_fps: float = 20.0   # Impacto fantasmal

# Colores (Shadow + Lightning = Purple-black ghostly)
var _primary_color: Color = Color(0.3, 0.1, 0.4)    # Púrpura oscuro
var _secondary_color: Color = Color(0.1, 0.04, 0.15) # Casi negro
var _core_color: Color = Color(0.8, 0.8, 1.0)       # Blanco-púrpura fantasmal
var _outline_color: Color = Color(0.1, 0.04, 0.15)  # Púrpura-negro muy oscuro

# Parámetros del rayo de sombra
var _bolt_width: float = 3.0
var _glow_width: float = 12.0
var _bolt_segments: int = 6
var _jitter_amount: float = 10.0  # Jitter moderado - etéreo pero eléctrico

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
var _max_duration: float = 0.6  # Más duración - sombras persisten
var _expected_chains: int = 3

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func setup(data: ProjectileVisualData = null, chain_count: int = 3) -> void:
	"""Configurar el efecto chain de sombra"""
	visual_data = data
	_expected_chains = chain_count
	_max_duration = max(0.6, chain_count * 0.15 + 0.35)

	if visual_data:
		_primary_color = visual_data.primary_color
		_secondary_color = visual_data.secondary_color
		_core_color = visual_data.accent_color
		_outline_color = visual_data.outline_color

	_try_load_custom_sprites()

	if not _use_custom_sprites:
		_create_bolt_lines()

func _try_load_custom_sprites() -> void:
	"""Cargar sprites personalizados para el rayo de sombra"""
	var base_path = "res://assets/sprites/projectiles/fusion/shadow_bolt/"

	var bolt_path = base_path + "flight_spritesheet_shadow_bolt.png"
	var zap_path = base_path + "impact_spritesheet_shadow_bolt.png"

	if ResourceLoader.exists(bolt_path) and ResourceLoader.exists(zap_path):
		_bolt_spritesheet = load(bolt_path) as Texture2D
		_zap_spritesheet = load(zap_path) as Texture2D

		if _bolt_spritesheet and _zap_spritesheet:
			_use_custom_sprites = true
			print("[ShadowBoltVisual] 🗡️⚡ Sprites personalizados cargados")

func _create_bolt_lines() -> void:
	"""Crear las líneas del rayo de sombra (modo procedural)"""
	# Outline (púrpura-negro muy oscuro)
	_outline_bolt = Line2D.new()
	_outline_bolt.width = _bolt_width + 4
	_outline_bolt.default_color = _outline_color
	_outline_bolt.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_outline_bolt.end_cap_mode = Line2D.LINE_CAP_ROUND
	_outline_bolt.z_index = -2
	add_child(_outline_bolt)

	# Glow (púrpura oscuro semitransparente - efecto etéreo)
	_glow_bolt = Line2D.new()
	_glow_bolt.width = _glow_width
	_glow_bolt.default_color = Color(_primary_color.r, _primary_color.g, _primary_color.b, 0.4)
	_glow_bolt.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_glow_bolt.end_cap_mode = Line2D.LINE_CAP_ROUND
	_glow_bolt.z_index = -1
	add_child(_glow_bolt)

	# Rayo principal con gradiente de sombra
	_main_bolt = Line2D.new()
	_main_bolt.width = _bolt_width
	_main_bolt.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_main_bolt.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(_main_bolt)

	var gradient = Gradient.new()
	gradient.set_color(0, _secondary_color)
	gradient.add_point(0.3, _primary_color)
	gradient.add_point(0.5, _core_color)  # Centro brillante fantasmal
	gradient.add_point(0.7, _primary_color)
	gradient.set_color(1, _secondary_color)
	_main_bolt.gradient = gradient

# ═══════════════════════════════════════════════════════════════════════════════
# CONTROL DEL RAYO
# ═══════════════════════════════════════════════════════════════════════════════

func fire_at(from: Vector2, to: Vector2) -> void:
	"""Disparar un rayo de sombra de from a to"""
	_start_pos = from
	_end_pos = to
	_is_active = true
	_time = 0.0
	_fade_timer = 0.0

	if _use_custom_sprites:
		_create_bolt_sprite(from, to)
		_create_zap_sprite(to)
	else:
		_generate_bolt_points()
		_create_impact_effect(to)

	chain_complete.emit()

func set_chain_count(count: int) -> void:
	"""Actualizar el número de cadenas esperadas"""
	_expected_chains = count
	_max_duration = max(0.6, count * 0.15 + 0.35)

func _create_bolt_sprite(from: Vector2, to: Vector2) -> void:
	"""Crear sprite animado del rayo de sombra entre dos puntos"""
	var bolt_sprite = AnimatedSprite2D.new()

	var frames = SpriteFrames.new()
	frames.add_animation("bolt")
	frames.set_animation_speed("bolt", _bolt_fps)
	frames.set_animation_loop("bolt", true)

	var frame_width = _bolt_spritesheet.get_width() / _bolt_frames
	var frame_height = _bolt_spritesheet.get_height()

	for i in range(_bolt_frames):
		var atlas = AtlasTexture.new()
		atlas.atlas = _bolt_spritesheet
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		frames.add_frame("bolt", atlas)

	bolt_sprite.sprite_frames = frames
	bolt_sprite.animation = "bolt"

	var mid_point = (from + to) / 2.0
	bolt_sprite.position = mid_point

	var direction = to - from
	bolt_sprite.rotation = direction.angle()

	var distance = direction.length()
	var scale_x = distance / frame_width
	bolt_sprite.scale.x = scale_x

	bolt_sprite.z_index = 10
	add_child(bolt_sprite)
	bolt_sprite.play("bolt")

	_bolt_sprites.append(bolt_sprite)

func _create_zap_sprite(pos: Vector2) -> void:
	"""Crear sprite animado de impacto de sombra"""
	var zap_sprite = AnimatedSprite2D.new()

	var frames = SpriteFrames.new()
	frames.add_animation("zap")
	frames.set_animation_speed("zap", _zap_fps)
	frames.set_animation_loop("zap", false)

	var frame_width = _zap_spritesheet.get_width() / _zap_frames
	var frame_height = _zap_spritesheet.get_height()

	for i in range(_zap_frames):
		var atlas = AtlasTexture.new()
		atlas.atlas = _zap_spritesheet
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		frames.add_frame("zap", atlas)

	zap_sprite.sprite_frames = frames
	zap_sprite.animation = "zap"
	zap_sprite.position = pos
	zap_sprite.z_index = 15
	zap_sprite.scale = Vector2(1.5, 1.5)

	add_child(zap_sprite)
	zap_sprite.play("zap")

	zap_sprite.animation_finished.connect(func(): zap_sprite.queue_free())

	_zap_sprites.append(zap_sprite)

func _generate_bolt_points() -> void:
	"""Generar los puntos del rayo de sombra (etéreo/fantasmal)"""
	_main_bolt.clear_points()
	_glow_bolt.clear_points()
	_outline_bolt.clear_points()

	var direction = _end_pos - _start_pos
	var length = direction.length()

	if length < 1.0:
		return

	var dir_normalized = direction.normalized()
	var perpendicular = dir_normalized.orthogonal()

	var points: Array[Vector2] = []
	points.append(_start_pos)

	for i in range(1, _bolt_segments):
		var t = float(i) / float(_bolt_segments)
		var base_pos = _start_pos + direction * t

		# Jitter más suave para efecto etéreo
		var center_factor = 1.0 - abs(t - 0.5) * 1.5
		var jitter = perpendicular * randf_range(-_jitter_amount, _jitter_amount) * center_factor

		points.append(base_pos + jitter)

	points.append(_end_pos)

	for p in points:
		_main_bolt.add_point(p)
		_glow_bolt.add_point(p)
		_outline_bolt.add_point(p)

func _create_impact_effect(pos: Vector2) -> void:
	"""Crear efecto visual de impacto de sombra"""
	var impact = Sprite2D.new()
	impact.position = pos
	impact.z_index = 1
	add_child(impact)
	_impact_particles.append(impact)

	var size = 28
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)

	for y in range(size):
		for x in range(size):
			var dist = Vector2(x, y).distance_to(center)
			var radius = size * 0.4
			if dist <= radius:
				var t = dist / radius
				# Centro brillante fantasmal, exterior oscuro
				var color = _core_color.lerp(_primary_color, t)
				color.a = (1.0 - t * 0.6) * 0.9  # Más transparente - etéreo
				image.set_pixel(x, y, color)

	impact.texture = ImageTexture.create_from_image(image)

	impact.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(impact, "scale", Vector2.ONE * 1.8, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(impact, "scale", Vector2.ONE * 1.0, 0.1)
	tween.tween_property(impact, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func():
		_impact_particles.erase(impact)
		impact.queue_free()
	)

# ═══════════════════════════════════════════════════════════════════════════════
# SECUENCIAS DE CADENA
# ═══════════════════════════════════════════════════════════════════════════════

func create_chain_sequence(targets: Array[Vector2], delay_between: float = 0.09) -> void:
	"""Crear una secuencia de rayos de sombra entre múltiples objetivos"""
	if targets.size() < 2:
		return

	for i in range(targets.size() - 1):
		if i > 0:
			await get_tree().create_timer(delay_between).timeout

		_start_pos = targets[i]
		_end_pos = targets[i + 1]

		if _use_custom_sprites:
			_create_bolt_sprite(targets[i], targets[i + 1])
			_create_zap_sprite(targets[i + 1])
		else:
			_generate_bolt_points()
			_create_impact_effect(targets[i + 1])

	_is_active = true

	await get_tree().create_timer(0.4).timeout
	fade_out()

func fade_out(duration: float = 0.25) -> void:
	"""Desvanecer el rayo de sombra (más lento - etéreo)"""
	if _use_custom_sprites:
		var tween = create_tween()
		for bolt in _bolt_sprites:
			if is_instance_valid(bolt):
				tween.parallel().tween_property(bolt, "modulate:a", 0.0, duration)
		for zap in _zap_sprites:
			if is_instance_valid(zap):
				tween.parallel().tween_property(zap, "modulate:a", 0.0, duration)

		await tween.finished

		for bolt in _bolt_sprites:
			if is_instance_valid(bolt):
				bolt.queue_free()
		for zap in _zap_sprites:
			if is_instance_valid(zap):
				zap.queue_free()
		_bolt_sprites.clear()
		_zap_sprites.clear()
	else:
		var tween = create_tween()
		if _main_bolt:
			tween.parallel().tween_property(_main_bolt, "modulate:a", 0.0, duration)
		if _glow_bolt:
			tween.parallel().tween_property(_glow_bolt, "modulate:a", 0.0, duration)
		if _outline_bolt:
			tween.parallel().tween_property(_outline_bolt, "modulate:a", 0.0, duration)

		await tween.finished

	all_chains_finished.emit()
	queue_free()

# ═══════════════════════════════════════════════════════════════════════════════
# PROCESO
# ═══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if not _is_active:
		return

	_time += delta
	_fade_timer += delta

	if _use_custom_sprites:
		# Efecto de pulso fantasmal (más lento y suave)
		var pulse = sin(_time * 15) * 0.1 + 1.0
		for bolt in _bolt_sprites:
			if is_instance_valid(bolt):
				bolt.scale.y = pulse
				# Efecto de parpadeo fantasmal
				bolt.modulate.a = 0.85 + sin(_time * 20) * 0.15
	else:
		# Modo procedural: parpadeo etéreo
		if int(_time * 18) != int((_time - delta) * 18):
			_generate_bolt_points()

		if _glow_bolt:
			var pulse = sin(_time * 15) * 0.25 + 1.0
			_glow_bolt.width = _glow_width * pulse
			# Efecto fantasmal
			_glow_bolt.modulate.a = 0.35 + sin(_time * 20) * 0.15

	if _fade_timer > _max_duration:
		_is_active = false
		fade_out()

# ChainLightningVisual.gd
# Efecto visual para rayos encadenados que conectan múltiples enemigos
# Estilo: Cartoon/Funko Pop con rayos eléctricos instantáneos
# Soporta sprites personalizados o rayos procedurales

class_name ChainLightningVisual
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
var weapon_id: String = "lightning_wand"

# Sprites personalizados
var _use_custom_sprites: bool = false
var _bolt_spritesheet: Texture2D
var _zap_spritesheet: Texture2D
var _bolt_frames: int = 4
var _zap_frames: int = 4
var _bolt_fps: float = 20.0
var _zap_fps: float = 24.0

# Colores
var _primary_color: Color = Color(1.0, 1.0, 0.3)    # Amarillo eléctrico
var _secondary_color: Color = Color(1.0, 0.9, 0.5)  # Amarillo claro
var _core_color: Color = Color.WHITE                 # Centro brillante
var _outline_color: Color = Color(0.4, 0.3, 0.1)    # Outline oscuro

# Parámetros del rayo
var _bolt_width: float = 6.0
var _glow_width: float = 18.0
var _bolt_segments: int = 6
var _jitter_amount: float = 12.0

# ═══════════════════════════════════════════════════════════════════════════════
# COMPONENTES
# ═══════════════════════════════════════════════════════════════════════════════

var _main_bolt: Line2D       # Rayo principal (blanco/core)
var _glow_bolt: Line2D       # Glow del rayo
var _outline_bolt: Line2D    # Outline oscuro
var _impact_particles: Array[Sprite2D] = []
var _bolt_sprites: Array[AnimatedSprite2D] = []  # Sprites del rayo (si usa custom)
var _zap_sprites: Array[AnimatedSprite2D] = []   # Sprites de impacto

var _start_pos: Vector2
var _end_pos: Vector2
var _time: float = 0.0
var _is_active: bool = false
var _fade_timer: float = 0.0
var _max_duration: float = 0.3
var _auto_fade_enabled: bool = true  # Permitir desactivar auto-fade para cadenas largas
var _expected_chains: int = 2        # Número esperado de saltos para calcular duración

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func setup(data: ProjectileVisualData = null, p_weapon_id: String = "lightning_wand", chain_count: int = 2) -> void:
	"""Configurar el efecto chain"""
	visual_data = data
	weapon_id = p_weapon_id
	_expected_chains = chain_count

	# Calcular duración máxima basada en número de cadenas
	# Cada cadena toma ~0.08s de delay + 0.1s de visualización
	_max_duration = max(0.5, chain_count * 0.15 + 0.3)

	if visual_data:
		_primary_color = visual_data.primary_color
		_secondary_color = visual_data.secondary_color
		_core_color = visual_data.accent_color
		_outline_color = visual_data.outline_color

	# Intentar cargar sprites personalizados
	_try_load_custom_sprites()

	if not _use_custom_sprites:
		_create_bolt_lines()

func _try_load_custom_sprites() -> void:
	"""Intentar cargar sprites personalizados para el rayo"""
	var base_path = "res://assets/sprites/projectiles/weapons/" + weapon_id + "/"

	var bolt_path = base_path + "flight_spritesheet_" + weapon_id + ".png"
	var zap_path = base_path + "impact_spritesheet_" + weapon_id + ".png"

	if ResourceLoader.exists(bolt_path) and ResourceLoader.exists(zap_path):
		_bolt_spritesheet = load(bolt_path) as Texture2D
		_zap_spritesheet = load(zap_path) as Texture2D

		if _bolt_spritesheet and _zap_spritesheet:
			_use_custom_sprites = true
			# print("[ChainLightningVisual] ⚡ Sprites personalizados cargados para: " + weapon_id)

func _create_bolt_lines() -> void:
	"""Crear las líneas del rayo (modo procedural)"""
	# Outline (más grueso, detrás)
	_outline_bolt = Line2D.new()
	_outline_bolt.width = _bolt_width + 4
	_outline_bolt.default_color = _outline_color
	_outline_bolt.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_outline_bolt.end_cap_mode = Line2D.LINE_CAP_ROUND
	_outline_bolt.z_index = -2
	add_child(_outline_bolt)

	# Glow (más grueso, semitransparente)
	_glow_bolt = Line2D.new()
	_glow_bolt.width = _glow_width
	_glow_bolt.default_color = Color(_primary_color.r, _primary_color.g, _primary_color.b, 0.4)
	_glow_bolt.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_glow_bolt.end_cap_mode = Line2D.LINE_CAP_ROUND
	_glow_bolt.z_index = -1
	add_child(_glow_bolt)

	# Rayo principal con gradiente
	_main_bolt = Line2D.new()
	_main_bolt.width = _bolt_width
	_main_bolt.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_main_bolt.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(_main_bolt)

	# Gradiente del rayo principal
	var gradient = Gradient.new()
	gradient.set_color(0, _core_color)
	gradient.add_point(0.3, _primary_color)
	gradient.add_point(0.7, _primary_color)
	gradient.set_color(1, _core_color)
	_main_bolt.gradient = gradient

# ═══════════════════════════════════════════════════════════════════════════════
# CONTROL DEL RAYO
# ═══════════════════════════════════════════════════════════════════════════════

func fire_at(from: Vector2, to: Vector2) -> void:
	"""Disparar un rayo instantáneo de from a to"""
	_start_pos = from
	_end_pos = to
	_is_active = true
	_time = 0.0
	# Reiniciar fade timer con cada nuevo disparo para permitir cadenas largas
	_fade_timer = 0.0

	if _use_custom_sprites:
		# Usar sprites personalizados
		_create_bolt_sprite(from, to)
		_create_zap_sprite(to)
	else:
		# Modo procedural
		_generate_bolt_points()
		_create_impact_effect(to)

	chain_complete.emit()

func set_chain_count(count: int) -> void:
	"""Actualizar el número de cadenas esperadas y ajustar duración"""
	_expected_chains = count
	_max_duration = max(0.5, count * 0.15 + 0.3)

func disable_auto_fade() -> void:
	"""Desactivar el auto-fade (útil para control manual)"""
	_auto_fade_enabled = false

func enable_auto_fade() -> void:
	"""Reactivar el auto-fade"""
	_auto_fade_enabled = true

func _create_bolt_sprite(from: Vector2, to: Vector2) -> void:
	"""Crear sprite animado del rayo entre dos puntos"""
	var bolt_sprite = AnimatedSprite2D.new()

	# Crear SpriteFrames para la animación
	var frames = SpriteFrames.new()
	frames.add_animation("bolt")
	frames.set_animation_speed("bolt", _bolt_fps)
	frames.set_animation_loop("bolt", true)

	# Añadir frames del spritesheet
	var frame_width = _bolt_spritesheet.get_width() / _bolt_frames
	var frame_height = _bolt_spritesheet.get_height()

	for i in range(_bolt_frames):
		var atlas = AtlasTexture.new()
		atlas.atlas = _bolt_spritesheet
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		frames.add_frame("bolt", atlas)

	bolt_sprite.sprite_frames = frames
	bolt_sprite.animation = "bolt"

	# Posicionar en el punto medio
	var mid_point = (from + to) / 2.0
	bolt_sprite.position = mid_point

	# Rotar hacia el destino
	var direction = to - from
	bolt_sprite.rotation = direction.angle()

	# Escalar para cubrir la distancia
	var distance = direction.length()
	var scale_x = distance / frame_width
	bolt_sprite.scale.x = scale_x

	bolt_sprite.z_index = 10
	add_child(bolt_sprite)
	bolt_sprite.play("bolt")

	_bolt_sprites.append(bolt_sprite)

func _create_zap_sprite(pos: Vector2) -> void:
	"""Crear sprite animado de impacto/zap"""
	var zap_sprite = AnimatedSprite2D.new()

	# Crear SpriteFrames para la animación
	var frames = SpriteFrames.new()
	frames.add_animation("zap")
	frames.set_animation_speed("zap", _zap_fps)
	frames.set_animation_loop("zap", false)

	# Añadir frames del spritesheet
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

	# Escala para que se vea bien
	zap_sprite.scale = Vector2(1.5, 1.5)

	add_child(zap_sprite)
	zap_sprite.play("zap")

	# Auto-destruir cuando termine la animación
	zap_sprite.animation_finished.connect(func(): zap_sprite.queue_free())

	_zap_sprites.append(zap_sprite)

func update_chain_positions(previous_hits: Array, current_target: Node2D) -> void:
	"""Actualizar para mostrar el rayo hacia el objetivo actual"""
	if not is_instance_valid(current_target):
		return

	# Determinar punto de inicio
	var start: Vector2
	if previous_hits.size() > 0:
		var last_hit = previous_hits[previous_hits.size() - 1]
		if is_instance_valid(last_hit):
			start = to_local(last_hit.global_position)
		else:
			start = Vector2.ZERO
	else:
		start = Vector2.ZERO

	var end = to_local(current_target.global_position)

	_start_pos = start
	_end_pos = end
	_is_active = true
	_time = 0.0

	_generate_bolt_points()

func add_chain_hit(hit_position: Vector2) -> void:
	"""Añadir efecto de impacto cuando se golpea un enemigo"""
	var local_pos = to_local(hit_position)
	_create_impact_effect(local_pos)

	# Añadir un nuevo segmento de rayo si es necesario
	if _is_active:
		# Crear un nuevo bolt desde la posición actual hacia el hit
		_end_pos = local_pos
		_generate_bolt_points()

func _generate_bolt_points() -> void:
	"""Generar los puntos zigzag del rayo"""
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

	# Generar segmentos intermedios con jitter
	for i in range(1, _bolt_segments):
		var t = float(i) / float(_bolt_segments)
		var base_pos = _start_pos + direction * t

		# Jitter aleatorio, más fuerte en el centro
		var center_factor = 1.0 - abs(t - 0.5) * 2.0
		var jitter = perpendicular * randf_range(-_jitter_amount, _jitter_amount) * center_factor

		points.append(base_pos + jitter)

	points.append(_end_pos)

	# Añadir puntos a todas las líneas
	for p in points:
		_main_bolt.add_point(p)
		_glow_bolt.add_point(p)
		_outline_bolt.add_point(p)

func _create_impact_effect(pos: Vector2) -> void:
	"""Crear efecto visual de impacto"""
	# Círculo de impacto
	var impact = Sprite2D.new()
	impact.position = pos
	impact.z_index = 1
	add_child(impact)
	_impact_particles.append(impact)

	# Crear textura del impacto
	var size = 24
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)

	for y in range(size):
		for x in range(size):
			var dist = Vector2(x, y).distance_to(center)
			var radius = size * 0.4
			if dist <= radius:
				var t = dist / radius
				var color = _core_color.lerp(_primary_color, t)
				color.a = 1.0 - t * 0.5
				image.set_pixel(x, y, color)

	impact.texture = ImageTexture.create_from_image(image)

	# Animación de impacto: pop + fade
	impact.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(impact, "scale", Vector2.ONE * 1.5, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(impact, "scale", Vector2.ONE * 0.8, 0.1)
	tween.tween_property(impact, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func():
		_impact_particles.erase(impact)
		impact.queue_free()
	)

# ═══════════════════════════════════════════════════════════════════════════════
# SECUENCIAS DE CADENA
# ═══════════════════════════════════════════════════════════════════════════════

func create_chain_sequence(targets: Array[Vector2], delay_between: float = 0.08) -> void:
	"""Crear una secuencia de rayos entre múltiples objetivos"""
	if targets.size() < 2:
		return

	for i in range(targets.size() - 1):
		if i > 0:
			await get_tree().create_timer(delay_between).timeout
			if not is_instance_valid(self):
				return

		_start_pos = targets[i]
		_end_pos = targets[i + 1]

		if _use_custom_sprites:
			_create_bolt_sprite(targets[i], targets[i + 1])
			_create_zap_sprite(targets[i + 1])
		else:
			_generate_bolt_points()
			_create_impact_effect(targets[i + 1])

	_is_active = true

	# Auto-destruir después de mostrar
	await get_tree().create_timer(0.4).timeout
	if is_instance_valid(self):
		fade_out()

func fade_out(duration: float = 0.2) -> void:
	"""Desvanecer el rayo"""
	if _use_custom_sprites:
		# Desvanecer sprites
		var tween = create_tween()
		for bolt in _bolt_sprites:
			if is_instance_valid(bolt):
				tween.parallel().tween_property(bolt, "modulate:a", 0.0, duration)
		for zap in _zap_sprites:
			if is_instance_valid(zap):
				tween.parallel().tween_property(zap, "modulate:a", 0.0, duration)

		await tween.finished

		# Limpiar
		for bolt in _bolt_sprites:
			if is_instance_valid(bolt):
				bolt.queue_free()
		for zap in _zap_sprites:
			if is_instance_valid(zap):
				zap.queue_free()
		_bolt_sprites.clear()
		_zap_sprites.clear()
	else:
		# Modo procedural
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
		# Efecto de pulso en sprites de bolt
		var pulse = sin(_time * 25) * 0.15 + 1.0
		for bolt in _bolt_sprites:
			if is_instance_valid(bolt):
				bolt.scale.y = pulse
	else:
		# Modo procedural: efecto de "chisporroteo"
		if int(_time * 20) != int((_time - delta) * 20):
			_generate_bolt_points()

		# Pulso del glow
		if _glow_bolt:
			var pulse = sin(_time * 25) * 0.3 + 1.0
			_glow_bolt.width = _glow_width * pulse

	# Auto-fade después de duración máxima (si está habilitado)
	if _auto_fade_enabled and _fade_timer > _max_duration:
		_is_active = false
		fade_out()

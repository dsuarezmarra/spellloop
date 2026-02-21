# BeamVisualEffect.gd
# Efecto visual animado para ataques de rayo/láser
# Estilo: Cartoon/Funko Pop con segmentos Start → Body → Tip

class_name BeamVisualEffect
extends Node2D

# ═══════════════════════════════════════════════════════════════════════════════
# SEÑALES
# ═══════════════════════════════════════════════════════════════════════════════

signal charge_complete
signal beam_finished

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADOS
# ═══════════════════════════════════════════════════════════════════════════════

enum State {
	NONE,
	CHARGING,    # Cargando energía
	FIRING,      # Disparando
	DISSIPATING  # Desvaneciendo
}

var current_state: State = State.NONE
var visual_data: ProjectileVisualData

# ═══════════════════════════════════════════════════════════════════════════════
# NODOS
# ═══════════════════════════════════════════════════════════════════════════════

var start_sprite: AnimatedSprite2D  # Inicio del rayo (en el jugador)
var body_line: Line2D               # Cuerpo del rayo
var tip_sprite: AnimatedSprite2D    # Punta del rayo
var glow_line: Line2D               # Resplandor
var particles: GPUParticles2D

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

var _time: float = 0.0
var _length: float = 200.0
var _direction: Vector2 = Vector2.RIGHT
var _width: float = 12.0
var _segment_length: float = 20.0  # Para efecto zigzag

# === OPTIMIZACIÓN ===
var _has_body_texture: bool = false  # Si tiene textura, skip zigzag animation
var _frame_skip_counter: int = 0     # Throttle para animación zigzag
const ZIGZAG_UPDATE_INTERVAL: int = 3  # Actualizar zigzag cada N frames
var _points_dirty: bool = true       # Solo recalcular puntos si es necesario
var _cached_points: Array[Vector2] = []  # Cache de puntos calculados

# Aproximación rápida de sin() usando onda triangular - evita llamadas a sin() costosas
static func _fast_sin(x: float) -> float:
	var period = fmod(x, TAU)
	if period < 0:
		period += TAU
	if period < PI:
		return 1.0 - (2.0 * period / PI - 1.0) * (2.0 * period / PI - 1.0) * 2.0 + 1.0
	else:
		var t = (period - PI) / PI
		return -1.0 + (2.0 * t - 1.0) * (2.0 * t - 1.0) * 2.0 - 1.0

# Colores
var _primary_color: Color = Color(1.0, 0.9, 0.3)
var _secondary_color: Color = Color(1.0, 0.6, 0.2)
var _core_color: Color = Color.WHITE
var _outline_color: Color = Color(0.8, 0.4, 0.1)

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_ensure_nodes_created()

func _ensure_nodes_created() -> void:
	"""Asegurar que los nodos estén creados"""
	if body_line == null:
		_create_nodes()

func setup(data: ProjectileVisualData, length: float = 200.0, 
		direction: Vector2 = Vector2.RIGHT, width: float = 12.0) -> void:
	"""Configurar el rayo"""
	_ensure_nodes_created()
	visual_data = data
	_length = length
	_direction = direction.normalized()
	_width = width
	
	if visual_data:
		_primary_color = visual_data.primary_color
		_secondary_color = visual_data.secondary_color
		_core_color = visual_data.accent_color
		_outline_color = visual_data.outline_color
		# Solo usar sprites si realmente existen, sino procedural
		if visual_data.beam_start_spritesheet or visual_data.beam_tip_spritesheet:
			_setup_from_sprites()
		else:
			_setup_procedural()
	else:
		_setup_procedural()

func _create_nodes() -> void:
	"""Crear estructura de nodos"""
	# Glow (detrás de todo)
	glow_line = Line2D.new()
	glow_line.name = "Glow"
	glow_line.z_index = -1
	glow_line.width = _width * 4
	glow_line.default_color = Color(_primary_color.r, _primary_color.g, _primary_color.b, 0.3)
	glow_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	glow_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(glow_line)
	
	# Cuerpo principal
	body_line = Line2D.new()
	body_line.name = "Body"
	body_line.width = _width
	body_line.default_color = _primary_color
	body_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	body_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(body_line)
	
	# Sprite de inicio
	start_sprite = AnimatedSprite2D.new()
	start_sprite.name = "StartSprite"
	start_sprite.centered = true
	add_child(start_sprite)
	
	# Sprite de punta
	tip_sprite = AnimatedSprite2D.new()
	tip_sprite.name = "TipSprite"
	tip_sprite.centered = true
	add_child(tip_sprite)

func _setup_from_sprites() -> void:
	"""Configurar desde spritesheets"""
	var frame_size = visual_data.frame_size if visual_data else Vector2i(64, 64)
	
	# Escala base de visual_data
	var sprite_scale = visual_data.base_scale if visual_data else 1.0
	
	# Start sprite
	if visual_data.beam_start_spritesheet:
		var frames = SpriteFrames.new()
		_add_animation(frames, "active", visual_data.beam_start_spritesheet, 
			visual_data.beam_frames, visual_data.beam_fps, true)
		start_sprite.sprite_frames = frames
		start_sprite.scale = Vector2.ONE * sprite_scale
		start_sprite.z_index = 10  # Encima del Line2D
		start_sprite.visible = true
		start_sprite.play("active")  # Iniciar animación inmediatamente
	
	# Body texture para el Line2D
	if visual_data.beam_body_spritesheet:
		body_line.texture = visual_data.beam_body_spritesheet
		body_line.texture_mode = Line2D.LINE_TEXTURE_TILE
		body_line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		body_line.width = visual_data.beam_body_spritesheet.get_height() * sprite_scale
		# Eliminar el gradiente cuando hay textura
		body_line.gradient = null
		# OCULTAR el glow completamente cuando hay textura de body
		glow_line.visible = false
		# OPTIMIZACIÓN: Marcar que tiene textura para skip zigzag
		_has_body_texture = true
	else:
		# Sin body sprite, hacer el Line2D más sutil para no tapar los otros sprites
		body_line.modulate.a = 0.3
		glow_line.modulate.a = 0.2
	
	# Tip sprite
	if visual_data.beam_tip_spritesheet:
		var frames = SpriteFrames.new()
		_add_animation(frames, "active", visual_data.beam_tip_spritesheet,
			visual_data.beam_frames, visual_data.beam_fps, true)
		tip_sprite.sprite_frames = frames
		tip_sprite.scale = Vector2.ONE * sprite_scale
		tip_sprite.z_index = 10  # Encima del Line2D
		tip_sprite.visible = true
		tip_sprite.play("active")  # Iniciar animación inmediatamente
	else:
		pass
	
	# Configurar gradiente del body (si no hay textura)
	if not visual_data.beam_body_spritesheet:
		_setup_body_gradient()

func _setup_procedural() -> void:
	"""Fallback: Usar spritesheet genérico (flame_breath) de VFXManager"""
	var vfx_mgr = get_node_or_null("/root/VFXManager")
	if not vfx_mgr:
		_setup_body_gradient() # Fallback último recurso
		return

	var config = vfx_mgr.BEAM_CONFIG.get("flame_breath")
	if not config:
		_setup_body_gradient()
		return
		
	var path = config.get("path", "")
	if path.is_empty() or not ResourceLoader.exists(path):
		_setup_body_gradient()
		return
	
	var tex = load(path)
	
	# Configurar sprites
	var frame_size = config.get("frame_size", Vector2(192, 64))
	var hframes = config.get("hframes", 6)
	var vframes = config.get("vframes", 2)
	var fps = 12.0
	
	# Start sprite: usar primera columna?
	# Beam spritesheets suelen ser horizontales para el cuerpo
	# Para start/tip podríamos intentar usar partes del mismo o dejarlos invisibles si no hay específicos
	# flame_breath es principalmente cuerpo.
	# Para fallback, ocultaremos start/tip y solo usaremos body line con textura
	
	start_sprite.visible = false
	tip_sprite.visible = false
	
	# Configurar Body Line con textura
	body_line.texture = tex
	body_line.texture_mode = Line2D.LINE_TEXTURE_TILE
	body_line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	body_line.width = frame_size.y * 0.5 # Ajustar ancho
	body_line.gradient = null
	glow_line.visible = false
	_has_body_texture = true
	
	# Configurar animación UV si es posible? Line2D no soporta spritesheet animation nativa fácilmente
	# pero texture_mode TILE hace que se repita.


func _setup_body_gradient() -> void:
	"""Configurar gradiente del cuerpo del rayo"""
	var gradient = Gradient.new()
	gradient.add_point(0.0, _secondary_color)
	gradient.add_point(0.3, _primary_color)
	gradient.add_point(0.5, _core_color)
	gradient.add_point(0.7, _primary_color)
	gradient.add_point(1.0, _secondary_color)
	
	body_line.gradient = gradient
	
	# Curve para el ancho
	var width_curve = Curve.new()
	width_curve.add_point(Vector2(0.0, 0.6))
	width_curve.add_point(Vector2(0.1, 1.0))
	width_curve.add_point(Vector2(0.9, 1.0))
	width_curve.add_point(Vector2(1.0, 0.3))
	body_line.width_curve = width_curve
	
	# Glow
	glow_line.default_color = Color(_primary_color.r, _primary_color.g, _primary_color.b, 0.2)
	glow_line.width = _width * 4

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
# CONTROL DE ESTADOS
# ═══════════════════════════════════════════════════════════════════════════════

func play_charge(charge_time: float = 0.3) -> void:
	"""Animación de carga antes de disparar"""
	current_state = State.CHARGING
	
	# Solo mostrar el inicio
	body_line.visible = false
	glow_line.visible = false
	tip_sprite.visible = false
	
	if start_sprite.sprite_frames and start_sprite.sprite_frames.has_animation("charging"):
		start_sprite.play("charging")
	
	# Escala creciente
	start_sprite.scale = Vector2.ONE * 0.3
	var tween = create_tween()
	tween.tween_property(start_sprite, "scale", Vector2.ONE * 1.2, charge_time).set_ease(Tween.EASE_IN)
	
	await tween.finished
	charge_complete.emit()

func fire(duration: float = 0.5) -> void:
	"""Disparar el rayo"""
	current_state = State.FIRING
	_points_dirty = true  # Marcar puntos como sucios para recalcular
	
	# Activar sprites
	if start_sprite.sprite_frames and start_sprite.sprite_frames.has_animation("active"):
		start_sprite.play("active")
	if tip_sprite.sprite_frames:
		tip_sprite.play("active")
	
	# Mostrar todos los elementos
	body_line.visible = true
	# Solo mostrar glow si NO hay textura de body personalizada
	if _has_body_texture:
		glow_line.visible = false
	else:
		glow_line.visible = true
	tip_sprite.visible = true
	
	# Animar extensión del rayo - optimizado según tipo
	if _has_body_texture:
		# Versión rápida para beams con textura
		_update_beam_points_fast(0)
		var tween = create_tween()
		tween.tween_method(_update_beam_points_fast, 0.0, _length, 0.1).set_ease(Tween.EASE_OUT)
	else:
		# Versión con zigzag para beams procedurales
		_update_beam_points(0)
		var tween = create_tween()
		tween.tween_method(_update_beam_points, 0.0, _length, 0.1).set_ease(Tween.EASE_OUT)
	
	# Mantener por duración
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(self):
		dissipate()

func _update_beam_points(current_length: float) -> void:
	"""Actualizar puntos del rayo con efecto zigzag"""
	body_line.clear_points()
	glow_line.clear_points()
	
	var points: Array[Vector2] = []
	var num_segments = int(current_length / _segment_length) + 1
	
	for i in range(num_segments + 1):
		var t = float(i) / float(num_segments)
		var base_pos = _direction * current_length * t
		
		# Añadir zigzag excepto en los extremos
		if i > 0 and i < num_segments:
			var offset_dir = _direction.orthogonal()
			var zigzag = sin(i * 1.5 + _time * 15) * _width * 0.4
			base_pos += offset_dir * zigzag
		
		points.append(base_pos)
	
	for p in points:
		body_line.add_point(p)
		glow_line.add_point(p)
	
	# Posicionar punta
	if points.size() > 0:
		tip_sprite.position = points[-1]
		tip_sprite.rotation = _direction.angle()
		# Debug: verificar posición del tip
		# if Engine.get_frames_drawn() % 60 == 0:  # Solo cada 60 frames para no saturar
		# 	print("[BeamVisualEffect] Tip en posición: " + str(tip_sprite.position) + ", visible: " + str(tip_sprite.visible))

func dissipate() -> void:
	"""Desvanecer el rayo"""
	# FIX-P0: Guard contra doble llamada (timeout + recarga simultánea)
	if current_state == State.DISSIPATING:
		return
	current_state = State.DISSIPATING
	
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(body_line, "width", 0.0, 0.2)
	
	await tween.finished
	beam_finished.emit()
	queue_free()

func set_target(target_position: Vector2) -> void:
	"""Actualizar dirección y longitud hacia un objetivo"""
	var to_target = target_position - global_position
	_direction = to_target.normalized()
	_length = to_target.length()
	
	# Rotar sprites
	start_sprite.rotation = _direction.angle()
	
	if current_state == State.FIRING:
		if _has_body_texture:
			_update_beam_points_fast(_length)
		else:
			_update_beam_points(_length)

# ═══════════════════════════════════════════════════════════════════════════════
# PROCESO
# ═══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	_time += delta
	
	if current_state != State.FIRING:
		return
	
	# OPTIMIZACIÓN: Si tiene textura de body, no necesita animación de zigzag
	if _has_body_texture:
		# Solo actualizar puntos UNA VEZ si es necesario
		if _points_dirty:
			_update_beam_points_fast(_length)
			_points_dirty = false
		return
	
	# Throttle para beams procedurales con zigzag
	_frame_skip_counter += 1
	if _frame_skip_counter >= ZIGZAG_UPDATE_INTERVAL:
		_frame_skip_counter = 0
		_update_beam_points(_length)
		
		# Pulso de glow (solo para rayos procedurales) - usando fast_sin para rendimiento
		var glow_pulse = _fast_sin(_time * 10) * 0.2 + 1.0
		glow_line.width = _width * 4 * glow_pulse
		
		# Vibración del ancho
		var width_pulse = _fast_sin(_time * 20) * 0.1 + 1.0
		body_line.width = _width * width_pulse

func _update_beam_points_fast(current_length: float) -> void:
	"""Versión rápida para beams con textura - línea recta sin zigzag"""
	body_line.clear_points()
	body_line.add_point(Vector2.ZERO)
	body_line.add_point(_direction * current_length)
	
	# Posicionar punta
	tip_sprite.position = _direction * current_length
	tip_sprite.rotation = _direction.angle()

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
	print("[BeamVisualEffect] Configurando sprites con frame_size: " + str(frame_size))
	
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
		print("  ✓ Start sprite configurado: " + str(visual_data.beam_frames) + " frames, scale: " + str(sprite_scale))
	
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
		print("  ✓ Body texture configurada: " + str(visual_data.beam_body_spritesheet.get_width()) + "x" + str(visual_data.beam_body_spritesheet.get_height()))
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
		print("  ✓ Tip sprite configurado: " + str(visual_data.beam_frames) + " frames, scale: " + str(sprite_scale))
	else:
		print("  ✗ Tip sprite NO TIENE SPRITESHEET")
	
	# Configurar gradiente del body (si no hay textura)
	if not visual_data.beam_body_spritesheet:
		_setup_body_gradient()

func _setup_procedural() -> void:
	"""Crear animaciones procedurales"""
	# Animación de inicio
	var start_frames = SpriteFrames.new()
	start_frames.add_animation("charging")
	start_frames.set_animation_speed("charging", 10)
	start_frames.set_animation_loop("charging", true)
	start_frames.add_animation("active")
	start_frames.set_animation_speed("active", 12)
	start_frames.set_animation_loop("active", true)
	
	var orb_size = int(_width * 4)
	for i in range(4):
		var tex = _generate_start_frame(i, 4, orb_size, "charging")
		start_frames.add_frame("charging", tex)
	for i in range(6):
		var tex = _generate_start_frame(i, 6, orb_size, "active")
		start_frames.add_frame("active", tex)
	
	start_sprite.sprite_frames = start_frames
	
	# Animación de punta
	var tip_frames = SpriteFrames.new()
	tip_frames.add_animation("active")
	tip_frames.set_animation_speed("active", 12)
	tip_frames.set_animation_loop("active", true)
	
	for i in range(6):
		var tex = _generate_tip_frame(i, 6, orb_size)
		tip_frames.add_frame("active", tex)
	
	tip_sprite.sprite_frames = tip_frames
	
	_setup_body_gradient()

func _generate_start_frame(frame_idx: int, total: int, size: int, anim: String) -> ImageTexture:
	"""Generar frame del orbe de inicio"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var progress = float(frame_idx) / float(total - 1) if total > 1 else 0.0
	
	var base_radius = size * 0.35
	var pulse: float
	
	if anim == "charging":
		pulse = 0.5 + progress * 0.5
	else:
		pulse = sin(progress * TAU) * 0.1 + 1.0
	
	var radius = base_radius * pulse
	var outline_width = max(2.0, size * 0.08)
	
	for y in range(size):
		for x in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			# Outline
			if dist <= radius + outline_width and dist > radius:
				image.set_pixel(x, y, _outline_color)
			# Interior
			elif dist <= radius:
				var t = dist / radius
				# Gradiente radial brillante
				var color = _core_color.lerp(_primary_color, t)
				color = color.lerp(_secondary_color, t * t)
				image.set_pixel(x, y, color)
	
	return ImageTexture.create_from_image(image)

func _generate_tip_frame(frame_idx: int, total: int, size: int) -> ImageTexture:
	"""Generar frame de la punta del rayo"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var progress = float(frame_idx) / float(total - 1) if total > 1 else 0.0
	
	var pulse = sin(progress * TAU) * 0.15 + 1.0
	var base_radius = size * 0.3 * pulse
	
	# Punta más puntiaguda (elipse)
	for y in range(size):
		for x in range(size):
			var pos = Vector2(x, y)
			var offset = pos - center
			# Elipse horizontal
			var ellipse_dist = sqrt((offset.x * 0.6) ** 2 + (offset.y * 1.3) ** 2)
			
			if ellipse_dist <= base_radius:
				var t = ellipse_dist / base_radius
				var color = _core_color.lerp(_primary_color, t * 0.5)
				# Más brillante en el centro
				color.a = 1.0 - t * 0.3
				image.set_pixel(x, y, color)
	
	return ImageTexture.create_from_image(image)

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
	
	# Activar sprites
	if start_sprite.sprite_frames and start_sprite.sprite_frames.has_animation("active"):
		start_sprite.play("active")
	if tip_sprite.sprite_frames:
		tip_sprite.play("active")
	
	# Mostrar todos los elementos
	body_line.visible = true
	# Solo mostrar glow si NO hay textura de body personalizada
	if visual_data and visual_data.beam_body_spritesheet:
		glow_line.visible = false
	else:
		glow_line.visible = true
	tip_sprite.visible = true
	
	# Animar extensión del rayo
	_update_beam_points(0)
	var tween = create_tween()
	tween.tween_method(_update_beam_points, 0.0, _length, 0.1).set_ease(Tween.EASE_OUT)
	
	# Mantener por duración
	await get_tree().create_timer(duration).timeout
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
		if Engine.get_frames_drawn() % 60 == 0:  # Solo cada 60 frames para no saturar
			print("[BeamVisualEffect] Tip en posición: " + str(tip_sprite.position) + ", visible: " + str(tip_sprite.visible))

func dissipate() -> void:
	"""Desvanecer el rayo"""
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
		_update_beam_points(_length)

# ═══════════════════════════════════════════════════════════════════════════════
# PROCESO
# ═══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	_time += delta
	
	if current_state == State.FIRING:
		# Actualizar zigzag
		_update_beam_points(_length)
		
		# Solo aplicar efectos de pulso si NO hay textura de body
		if not (visual_data and visual_data.beam_body_spritesheet):
			# Pulso de glow (solo para rayos procedurales)
			var glow_pulse = sin(_time * 10) * 0.2 + 1.0
			glow_line.width = _width * 4 * glow_pulse
			
			# Vibración del ancho
			var width_pulse = sin(_time * 20) * 0.1 + 1.0
			body_line.width = _width * width_pulse

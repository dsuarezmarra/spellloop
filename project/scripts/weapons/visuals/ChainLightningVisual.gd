# ChainLightningVisual.gd
# Efecto visual animado para rayos encadenados
# Estilo: Cartoon/Funko Pop con arcos eléctricos que saltan entre enemigos

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

# Colores
var _primary_color: Color = Color(0.3, 0.7, 1.0)    # Azul eléctrico
var _secondary_color: Color = Color(0.6, 0.9, 1.0)  # Celeste
var _core_color: Color = Color.WHITE                 # Centro brillante
var _outline_color: Color = Color(0.1, 0.3, 0.5)    # Outline oscuro

# Parámetros del rayo
var _bolt_width: float = 8.0
var _bolt_segments: int = 8
var _jitter_amount: float = 15.0

# ═══════════════════════════════════════════════════════════════════════════════
# ESTRUCTURAS
# ═══════════════════════════════════════════════════════════════════════════════

class ChainBolt:
	var line: Line2D
	var glow: Line2D
	var start_orb: Sprite2D
	var end_orb: Sprite2D
	var start_pos: Vector2
	var end_pos: Vector2
	var time: float = 0.0
	var active: bool = false

var _bolts: Array[ChainBolt] = []
var _time: float = 0.0

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func setup(data: ProjectileVisualData = null) -> void:
	"""Configurar el efecto chain"""
	visual_data = data
	
	if visual_data:
		_primary_color = visual_data.primary_color
		_secondary_color = visual_data.secondary_color
		_core_color = visual_data.accent_color
		_outline_color = visual_data.outline_color
	
	# Crear textura para los orbes
	_create_orb_texture()

var _orb_texture: ImageTexture

func _create_orb_texture() -> void:
	"""Crear textura del orbe de impacto"""
	var size = 32
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size * 0.4
	
	for y in range(size):
		for x in range(size):
			var dist = Vector2(x, y).distance_to(center)
			
			if dist <= radius:
				var t = dist / radius
				var color = _core_color.lerp(_primary_color, t)
				color = color.lerp(_secondary_color, t * t)
				image.set_pixel(x, y, color)
	
	_orb_texture = ImageTexture.create_from_image(image)

# ═══════════════════════════════════════════════════════════════════════════════
# CREAR CADENAS
# ═══════════════════════════════════════════════════════════════════════════════

func add_chain(from: Vector2, to: Vector2, delay: float = 0.0) -> void:
	"""Añadir un segmento de cadena de rayos"""
	var bolt = ChainBolt.new()
	bolt.start_pos = from
	bolt.end_pos = to
	
	# Crear glow
	bolt.glow = Line2D.new()
	bolt.glow.width = _bolt_width * 3
	bolt.glow.default_color = Color(_primary_color.r, _primary_color.g, _primary_color.b, 0.3)
	bolt.glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	bolt.glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	bolt.glow.visible = false
	add_child(bolt.glow)
	
	# Crear línea principal
	bolt.line = Line2D.new()
	bolt.line.width = _bolt_width
	bolt.line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	bolt.line.end_cap_mode = Line2D.LINE_CAP_ROUND
	bolt.line.visible = false
	add_child(bolt.line)
	
	# Gradiente para la línea
	var gradient = Gradient.new()
	gradient.add_point(0.0, _core_color)
	gradient.add_point(0.2, _primary_color)
	gradient.add_point(0.5, _secondary_color)
	gradient.add_point(0.8, _primary_color)
	gradient.add_point(1.0, _core_color)
	bolt.line.gradient = gradient
	
	# Orbe de inicio
	bolt.start_orb = Sprite2D.new()
	bolt.start_orb.texture = _orb_texture
	bolt.start_orb.scale = Vector2.ONE * 0.8
	bolt.start_orb.position = from
	bolt.start_orb.visible = false
	add_child(bolt.start_orb)
	
	# Orbe de fin
	bolt.end_orb = Sprite2D.new()
	bolt.end_orb.texture = _orb_texture
	bolt.end_orb.scale = Vector2.ONE * 1.2
	bolt.end_orb.position = to
	bolt.end_orb.visible = false
	add_child(bolt.end_orb)
	
	_bolts.append(bolt)
	
	# Activar con delay
	if delay > 0:
		await get_tree().create_timer(delay).timeout
	
	_activate_bolt(bolt)

func _activate_bolt(bolt: ChainBolt) -> void:
	"""Activar un rayo"""
	bolt.active = true
	bolt.line.visible = true
	bolt.glow.visible = true
	bolt.start_orb.visible = true
	bolt.end_orb.visible = true
	
	# Generar puntos del rayo
	_generate_bolt_points(bolt)
	
	# Animación de aparición
	bolt.start_orb.scale = Vector2.ZERO
	bolt.end_orb.scale = Vector2.ZERO
	
	var tween = create_tween()
	tween.parallel().tween_property(bolt.start_orb, "scale", Vector2.ONE * 0.8, 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(bolt.end_orb, "scale", Vector2.ONE * 1.2, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	chain_complete.emit()

func _generate_bolt_points(bolt: ChainBolt) -> void:
	"""Generar puntos zigzag para el rayo"""
	bolt.line.clear_points()
	bolt.glow.clear_points()
	
	var direction = bolt.end_pos - bolt.start_pos
	var length = direction.length()
	var dir_normalized = direction.normalized()
	var perpendicular = dir_normalized.orthogonal()
	
	var points: Array[Vector2] = []
	points.append(bolt.start_pos)
	
	for i in range(1, _bolt_segments):
		var t = float(i) / float(_bolt_segments)
		var base_pos = bolt.start_pos + direction * t
		
		# Jitter aleatorio
		var jitter = perpendicular * randf_range(-_jitter_amount, _jitter_amount)
		# Más jitter en el centro
		var center_factor = 1.0 - abs(t - 0.5) * 2.0
		jitter *= center_factor
		
		points.append(base_pos + jitter)
	
	points.append(bolt.end_pos)
	
	for p in points:
		bolt.line.add_point(p)
		bolt.glow.add_point(p)

# ═══════════════════════════════════════════════════════════════════════════════
# MODOS DE USO
# ═══════════════════════════════════════════════════════════════════════════════

func create_chain_sequence(targets: Array[Vector2], delay_between: float = 0.08) -> void:
	"""Crear una secuencia de rayos entre múltiples objetivos"""
	if targets.size() < 2:
		return
	
	for i in range(targets.size() - 1):
		add_chain(targets[i], targets[i + 1], delay_between * i)
	
	# Auto-destruir después de completar
	var total_time = delay_between * (targets.size() - 1) + 0.5
	await get_tree().create_timer(total_time).timeout
	fade_out()

func update_chain_positions(previous_hits: Array, current_target: Node2D) -> void:
	"""Actualizar posiciones de cadena según los enemigos alcanzados"""
	# Reconstruir la cadena visual basada en los hits previos y el objetivo actual
	var positions: Array[Vector2] = []
	
	for hit in previous_hits:
		if is_instance_valid(hit):
			positions.append(hit.global_position)
	
	if current_target and is_instance_valid(current_target):
		positions.append(current_target.global_position)
	
	# Solo actualizar si hay cambios significativos
	if positions.size() >= 2:
		# Actualizar el último bolt si existe
		if _bolts.size() > 0:
			var last_bolt = _bolts[_bolts.size() - 1]
			last_bolt.end_pos = positions[positions.size() - 1]
			_generate_bolt_points(last_bolt)

func add_chain_hit(hit_position: Vector2) -> void:
	"""Añadir un impacto de cadena en una posición"""
	# Crear efecto de impacto
	var impact_sprite = Sprite2D.new()
	impact_sprite.texture = _orb_texture
	impact_sprite.position = hit_position
	impact_sprite.scale = Vector2.ZERO
	impact_sprite.modulate = _core_color
	add_child(impact_sprite)
	
	# Animación de impacto
	var tween = create_tween()
	tween.tween_property(impact_sprite, "scale", Vector2.ONE * 2.0, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(impact_sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(impact_sprite.queue_free)
	
	# Si hay bolts activos, añadir conexión
	if _bolts.size() > 0:
		var last_bolt = _bolts[_bolts.size() - 1]
		if last_bolt.active:
			# El siguiente chain empezará desde esta posición
			add_chain(last_bolt.end_pos, hit_position, 0.05)

func fade_out(duration: float = 0.3) -> void:
	"""Desvanecer todos los rayos"""
	var tween = create_tween()
	
	for bolt in _bolts:
		tween.parallel().tween_property(bolt.line, "modulate:a", 0.0, duration)
		tween.parallel().tween_property(bolt.glow, "modulate:a", 0.0, duration)
		tween.parallel().tween_property(bolt.start_orb, "modulate:a", 0.0, duration)
		tween.parallel().tween_property(bolt.end_orb, "modulate:a", 0.0, duration)
	
	await tween.finished
	all_chains_finished.emit()
	queue_free()

# ═══════════════════════════════════════════════════════════════════════════════
# PROCESO
# ═══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	_time += delta
	
	for bolt in _bolts:
		if not bolt.active:
			continue
		
		bolt.time += delta
		
		# Regenerar puntos periódicamente para efecto de "chisporroteo"
		if int(bolt.time * 30) != int((bolt.time - delta) * 30):
			_generate_bolt_points(bolt)
		
		# Pulso de los orbes
		var pulse = sin(_time * 15) * 0.15 + 1.0
		bolt.start_orb.scale = Vector2.ONE * 0.8 * pulse
		bolt.end_orb.scale = Vector2.ONE * 1.2 * pulse
		
		# Pulso del glow
		var glow_pulse = sin(_time * 12) * 0.3 + 1.0
		bolt.glow.width = _bolt_width * 3 * glow_pulse
		
		# Variación del ancho del rayo
		var width_var = sin(_time * 20) * 0.15 + 1.0
		bolt.line.width = _bolt_width * width_var

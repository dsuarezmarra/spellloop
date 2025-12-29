# ChainLightningVisual.gd
# Efecto visual para rayos encadenados que conectan múltiples enemigos
# Estilo: Cartoon/Funko Pop con rayos eléctricos instantáneos

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

var _start_pos: Vector2
var _end_pos: Vector2
var _time: float = 0.0
var _is_active: bool = false
var _fade_timer: float = 0.0
var _max_duration: float = 0.3

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
	
	_create_bolt_lines()

func _create_bolt_lines() -> void:
	"""Crear las líneas del rayo"""
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
	_fade_timer = 0.0
	
	# Generar puntos zigzag
	_generate_bolt_points()
	
	# Crear efecto de impacto en destino
	_create_impact_effect(to)
	
	chain_complete.emit()

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
		
		_start_pos = targets[i]
		_end_pos = targets[i + 1]
		_generate_bolt_points()
		_create_impact_effect(targets[i + 1])
	
	_is_active = true
	
	# Auto-destruir después de mostrar
	await get_tree().create_timer(0.4).timeout
	fade_out()

func fade_out(duration: float = 0.2) -> void:
	"""Desvanecer el rayo"""
	var tween = create_tween()
	tween.parallel().tween_property(_main_bolt, "modulate:a", 0.0, duration)
	tween.parallel().tween_property(_glow_bolt, "modulate:a", 0.0, duration)
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
	
	# Efecto de "chisporroteo" - regenerar puntos periódicamente
	if int(_time * 20) != int((_time - delta) * 20):
		_generate_bolt_points()
	
	# Pulso del glow
	var pulse = sin(_time * 25) * 0.3 + 1.0
	_glow_bolt.width = _glow_width * pulse
	
	# Auto-fade después de duración máxima
	if _fade_timer > _max_duration:
		_is_active = false
		fade_out()

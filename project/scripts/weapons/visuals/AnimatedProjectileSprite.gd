# AnimatedProjectileSprite.gd
# Componente visual animado para proyectiles estilo Cartoon/Funko Pop
# Maneja las transiciones: Launch → InFlight → Impact

class_name AnimatedProjectileSprite
extends Node2D

# ═══════════════════════════════════════════════════════════════════════════════
# SEÑALES
# ═══════════════════════════════════════════════════════════════════════════════

signal launch_finished
signal impact_started
signal impact_finished
signal animation_changed(state: String)

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADOS
# ═══════════════════════════════════════════════════════════════════════════════

enum State {
	NONE,
	LAUNCH,
	IN_FLIGHT,
	IMPACT
}

var current_state: State = State.NONE
var visual_data: ProjectileVisualData

# ═══════════════════════════════════════════════════════════════════════════════
# NODOS INTERNOS
# ═══════════════════════════════════════════════════════════════════════════════

var sprite: AnimatedSprite2D
var glow_sprite: Sprite2D
var trail_particles: GPUParticles2D
var outline_sprite: AnimatedSprite2D  # Para el contorno cartoon

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

var _time: float = 0.0
var _squash_stretch_enabled: bool = true
var _current_direction: Vector2 = Vector2.RIGHT
var _rotation_offset: float = 0.0  # Offset de rotación en radianes para corregir sprites desalineados
var _lock_rotation: bool = false  # Si true, el sprite no rota con la dirección (ej: tornados)

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_ensure_nodes_created()

func _ensure_nodes_created() -> void:
	"""Asegurar que los nodos estén creados (llamar antes de setup si es necesario)"""
	if sprite == null:
		_create_sprite_nodes()

func setup(data: ProjectileVisualData) -> void:
	"""Configurar el visual con los datos del proyectil"""
	_ensure_nodes_created()
	visual_data = data
	
	if visual_data == null:
		push_warning("[AnimatedProjectileSprite] No visual_data provided")
		return
	
	_setup_animations()
	_setup_glow()
	_setup_trail()
	
	# Aplicar escala base
	scale = Vector2.ONE * visual_data.base_scale

func _create_sprite_nodes() -> void:
	"""Crear la estructura de nodos"""
	# Sprite principal con animaciones
	sprite = AnimatedSprite2D.new()
	sprite.name = "MainSprite"
	sprite.centered = true
	add_child(sprite)
	
	# Sprite de resplandor (detrás)
	glow_sprite = Sprite2D.new()
	glow_sprite.name = "GlowSprite"
	glow_sprite.centered = true
	glow_sprite.z_index = -1
	add_child(glow_sprite)
	
	# Conectar señal de animación terminada
	sprite.animation_finished.connect(_on_animation_finished)

func _setup_animations() -> void:
	"""Configurar SpriteFrames con las animaciones"""
	var frames = SpriteFrames.new()
	
	# Crear animaciones según el tipo de proyectil
	if visual_data.has_custom_sprites():
		_add_spritesheet_animation(frames, "launch", 
			visual_data.launch_spritesheet, 
			visual_data.launch_frames, 
			visual_data.launch_fps,
			visual_data.launch_loop)
		
		_add_spritesheet_animation(frames, "flight", 
			visual_data.flight_spritesheet, 
			visual_data.flight_frames, 
			visual_data.flight_fps,
			visual_data.flight_loop)
		
		_add_spritesheet_animation(frames, "impact", 
			visual_data.impact_spritesheet, 
			visual_data.impact_frames, 
			visual_data.impact_fps,
			visual_data.impact_loop)
	else:
		# Crear animaciones procedurales
		_create_procedural_animations(frames)
	
	sprite.sprite_frames = frames

func _add_spritesheet_animation(frames: SpriteFrames, anim_name: String, 
		spritesheet: Texture2D, frame_count: int, fps: float, loop: bool) -> void:
	"""Añadir una animación desde un spritesheet horizontal"""
	if spritesheet == null:
		return
	
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, loop)
	
	var frame_width = visual_data.frame_size.x
	var frame_height = visual_data.frame_size.y
	
	for i in range(frame_count):
		var atlas = AtlasTexture.new()
		atlas.atlas = spritesheet
		atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
		atlas.filter_clip = true  # Evita bleeding de frames adyacentes
		frames.add_frame(anim_name, atlas)

func _create_procedural_animations(frames: SpriteFrames) -> void:
	"""Crear animaciones procedurales cuando no hay sprites"""
	var size = visual_data.frame_size.x
	
	# Launch animation
	frames.add_animation("launch")
	frames.set_animation_speed("launch", 12)
	frames.set_animation_loop("launch", false)
	for i in range(4):
		var tex = _generate_procedural_frame("launch", i, 4, size)
		frames.add_frame("launch", tex)
	
	# Flight animation
	frames.add_animation("flight")
	frames.set_animation_speed("flight", 12)
	frames.set_animation_loop("flight", true)
	for i in range(6):
		var tex = _generate_procedural_frame("flight", i, 6, size)
		frames.add_frame("flight", tex)
	
	# Impact animation
	frames.add_animation("impact")
	frames.set_animation_speed("impact", 15)
	frames.set_animation_loop("impact", false)
	for i in range(6):
		var tex = _generate_procedural_frame("impact", i, 6, size)
		frames.add_frame("impact", tex)

func _generate_procedural_frame(anim_type: String, frame_idx: int, total_frames: int, size: int) -> ImageTexture:
	"""Generar un frame procedural estilo cartoon"""
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var progress = float(frame_idx) / float(total_frames - 1) if total_frames > 1 else 1.0
	
	var primary = visual_data.primary_color if visual_data else Color(1, 0, 1) # MAGENTA para identificar fallback
	if not visual_data:
		print("[DEBUG_MAGENTA] Fallback Magenta for weapon: %s" % _weapon_id)
	var secondary = visual_data.secondary_color if visual_data else Color(0.5, 0, 0.5)
	var accent = visual_data.accent_color if visual_data else Color.WHITE
	var outline = visual_data.outline_color if visual_data else Color(0.1, 0.2, 0.4)
	
	match anim_type:
		"launch":
			# Efecto de aparición: círculo que crece con "pop"
			var scale_factor = ease(progress, 0.2)  # Ease out back
			if progress < 0.5:
				scale_factor = progress * 2.0 * 1.2  # Overshoot
			else:
				scale_factor = 1.0 + (1.0 - (progress - 0.5) * 2.0) * 0.2
			_draw_shaped_projectile(image, center, size * 0.35 * scale_factor, 1.0, primary, secondary, accent, outline, visual_data.shape)
			
		"flight":
			# Orbe pulsante con efecto "bouncy"
			var pulse = sin(progress * TAU) * 0.1 + 1.0
			var squash = 1.0 + sin(progress * TAU * 2) * 0.05
			_draw_shaped_projectile(image, center, size * 0.35 * pulse, squash, primary, secondary, accent, outline, visual_data.shape)
			
		"impact":
			# Explosión que se expande y desvanece
			var expand = ease(progress, 0.3) * 1.5
			var alpha_mult = 1.0 - ease(progress, 2.0)
			var impact_primary = Color(primary.r, primary.g, primary.b, primary.a * alpha_mult)
			var impact_accent = Color(accent.r, accent.g, accent.b, accent.a * alpha_mult)
			_draw_impact_burst(image, center, size * 0.3 * expand, impact_primary, impact_accent, frame_idx)
	
	return ImageTexture.create_from_image(image)

func _draw_shaped_projectile(image: Image, center: Vector2, radius: float, squash: float,
		primary: Color, secondary: Color, accent: Color, outline: Color, shape: String) -> void:
	"""Dibujar proyectil con forma específica"""
	match shape:
		"shard", "ice_blade", "dark_shard", "prism":
			_draw_shape_diamond(image, center, radius, squash, primary, secondary, accent, outline)
		"bolt", "ice_bolt", "dark_bolt", "geo_bolt":
			_draw_shape_bolt(image, center, radius, squash, primary, secondary, accent, outline)
		"fireball", "plasma_ball", "orb", "storm_orb", "shadow_orb":
			_draw_shape_orb(image, center, radius, squash, primary, secondary, accent, outline)
		"leaf", "pollen":
			_draw_shape_leaf(image, center, radius, squash, primary, secondary, accent, outline)
		"star", "solar_disc":
			_draw_shape_star(image, center, radius, squash, primary, secondary, accent, outline)
		"crescent", "wind_blade":
			_draw_shape_crescent(image, center, radius, squash, primary, secondary, accent, outline)
		"spike", "dagger":
			_draw_shape_spike(image, center, radius, squash, primary, secondary, accent, outline)
		_:
			# Fallback a orbe
			_draw_shape_orb(image, center, radius, squash, primary, secondary, accent, outline)

func _draw_shape_orb(image: Image, center: Vector2, radius: float, squash: float,
		primary: Color, secondary: Color, accent: Color, outline: Color) -> void:
	"""Dibujar orbe (círculo)"""
	var outline_width = max(2.0, radius * 0.15)
	
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pos = Vector2(x, y)
			var adjusted_pos = Vector2((pos.x - center.x) / squash + center.x, (pos.y - center.y) * squash + center.y)
			var dist = adjusted_pos.distance_to(center)
			
			if dist <= radius + outline_width and dist > radius:
				image.set_pixel(x, y, outline)
			elif dist <= radius:
				var t = dist / radius
				var highlight_center = center + Vector2(-radius * 0.3, -radius * 0.3)
				var highlight_dist = adjusted_pos.distance_to(highlight_center)
				var highlight_t = clamp(1.0 - highlight_dist / (radius * 0.6), 0.0, 1.0)
				
				var base_color = primary.lerp(secondary, t * 0.5)
				var final_color = base_color.lerp(accent, highlight_t * 0.7)
				image.set_pixel(x, y, final_color)

func _draw_shape_diamond(image: Image, center: Vector2, radius: float, squash: float,
		primary: Color, secondary: Color, accent: Color, outline: Color) -> void:
	"""Dibujar diamante (shard)"""
	var outline_width = max(2.0, radius * 0.15)
	
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			# Distancia Manhattan modificada para rombo
			var dx = abs(x - center.x) / squash
			var dy = abs(y - center.y) * squash
			var dist = dx * 0.8 + dy  # Estirado un poco
			
			if dist <= radius + outline_width and dist > radius:
				image.set_pixel(x, y, outline)
			elif dist <= radius:
				var t = dist / radius
				# Highlight lineal desde el centro
				var highlight_t = clamp(1.0 - t * 1.5, 0.0, 1.0)
				
				var base_color = primary.lerp(secondary, t * 0.8)
				var final_color = base_color.lerp(accent, highlight_t)
				image.set_pixel(x, y, final_color)

func _draw_shape_bolt(image: Image, center: Vector2, radius: float, squash: float,
		primary: Color, secondary: Color, accent: Color, outline: Color) -> void:
	"""Dibujar rayo/zig-zag"""
	# Simplificado: dibujo un rombo muy estirado y rotado se verá como bolt si se rota externamente
	# Para "bolt", usamos una forma más afilada e irregular
	radius *= 1.2 # Un poco más grande para compensar
	var outline_width = max(1.0, radius * 0.1)
	
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var dx = (x - center.x) / squash
			var dy = (y - center.y) * squash
			
			# Forma de "S" o rayo paramétrico simple
			# Distancia a la linea central zigzagueante
			var zigzag_offset = sin(dy * 0.2) * radius * 0.3
			var dist_x = abs(dx - zigzag_offset)
			var dist_y = abs(dy)
			
			# Combinamos para hacer una forma alargada
			var shape_dist = dist_x * 2.0 + dist_y * 0.5
			
			if shape_dist <= radius + outline_width and shape_dist > radius:
				image.set_pixel(x, y, outline)
			elif shape_dist <= radius:
				var t = shape_dist / radius
				var base_color = primary.lerp(secondary, abs(dy) / radius)
				var final_color = base_color.lerp(accent, (1.0 - t) * 0.8)
				image.set_pixel(x, y, final_color)

func _draw_shape_star(image: Image, center: Vector2, radius: float, squash: float,
		primary: Color, secondary: Color, accent: Color, outline: Color) -> void:
	"""Dibujar estrella de 4 puntas"""
	var outline_width = max(1.0, radius * 0.1)
	
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var dx = abs(x - center.x) / squash
			var dy = abs(y - center.y) * squash
			
			# Astroid-like shape: x^(2/3) + y^(2/3) = r^(2/3) -> aprox
			# O simplemente min(dx, dy) para cruceta
			# Usamos curva cóncava
			var dist = 0.0
			if dx == 0 and dy == 0:
				dist = 0.0
			else:
				# Fórmula polar aproximada para estrella
				var angle = atan2(dy, dx)
				var r_star = radius * (0.4 + 0.6 * abs(cos(angle * 2.0))) # 4 puntas
				var current_r = sqrt(dx*dx + dy*dy)
				dist = current_r / (r_star / radius) # Normalizado a radius
			
			if dist <= radius + outline_width and dist > radius:
				image.set_pixel(x, y, outline)
			elif dist <= radius:
				var t = dist / radius
				image.set_pixel(x, y, primary.lerp(accent, (1.0 - t)))

func _draw_shape_crescent(image: Image, center: Vector2, radius: float, squash: float,
		primary: Color, secondary: Color, accent: Color, outline: Color) -> void:
	"""Dibujar media luna"""
	var outline_width = max(1.0, radius * 0.1)
	
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var dx = (x - center.x) / squash
			var dy = (y - center.y) * squash
			var dist = sqrt(dx*dx + dy*dy)
			
			# Círculo grande recortado por otro círculo desplazado
			var offset_x = radius * 0.5
			var dist_cut = sqrt((dx - offset_x)*(dx - offset_x) + dy*dy)
			
			if dist <= radius and dist_cut > radius * 0.8:
				# Dentro de la luna
				if dist > radius - outline_width or dist_cut < radius * 0.8 + outline_width:
					image.set_pixel(x, y, outline)
				else:
					image.set_pixel(x, y, primary.lerp(secondary, (dy + radius) / (2.0 * radius)))
			elif dist <= radius + outline_width and dist_cut > radius * 0.8 - outline_width:
				# Borde exterior
				if dist_cut > radius * 0.8: # Solo dibujar si no está totalmente comido
					image.set_pixel(x, y, outline)

func _draw_shape_spike(image: Image, center: Vector2, radius: float, squash: float,
		primary: Color, secondary: Color, accent: Color, outline: Color) -> void:
	"""Dibujar pico triangular"""
	var outline_width = max(1.0, radius * 0.1)
	
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var dx = (x - center.x) / squash # Apunta a derecha
			var dy = abs(y - center.y) * squash
			
			# Triángulo isósceles apuntando a derecha (x positivo)
			# x va de -radius a +radius
			# width en x varía linealmente
			var dist_x = -dx # Invertir para math simple (base en -x, punta en +x)
			
			# Definir triangulo: x < radius, x > -radius, |y| < (radius - x) * 0.5
			var in_tri = false
			if dx <= radius:
				var half_width = (radius - dx) * 0.6
				if dy <= half_width:
					in_tri = true
			
			# Calcular distancia al borde aproximada para outline
			# Simplificado:
			if in_tri:
				# Borde?
				var half_width = (radius - dx) * 0.6
				if dx > radius - outline_width or dy > half_width - outline_width:
					image.set_pixel(x, y, outline)
				else:
					image.set_pixel(x, y, primary.lerp(secondary, dy / half_width))
			# Borde fuera? (complicado de calcular exacto en pixel shader simple, omitir por ahora, el in_tri cubre la mayoría)

func _draw_shape_leaf(image: Image, center: Vector2, radius: float, squash: float,
		primary: Color, secondary: Color, accent: Color, outline: Color) -> void:
	"""Dibujar hoja (elipse puntieguda)"""
	var outline_width = max(1.0, radius * 0.1)
	
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var dx = abs(x - center.x) / squash
			var dy = abs(y - center.y) * squash
			
			# Fórmula de ojo/hoja: x^2 + 2*y^2
			var dist = sqrt(dx*dx + dy*dy * 2.5) 
			
			if dist <= radius + outline_width and dist > radius:
				image.set_pixel(x, y, outline)
			elif dist <= radius:
				image.set_pixel(x, y, primary.lerp(accent, 1.0 - dist/radius))

func _draw_impact_burst(image: Image, center: Vector2, radius: float, 
		primary: Color, accent: Color, frame_idx: int) -> void:
	"""Dibujar explosión de impacto con partículas"""
	var num_rays = 8
	var ray_angle_offset = frame_idx * 0.2
	
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			var angle = (pos - center).angle()
			
			# Círculo central
			if dist <= radius * 0.4:
				var t = dist / (radius * 0.4)
				image.set_pixel(x, y, accent.lerp(primary, t))
			# Rayos
			elif dist <= radius:
				var ray_angle = fmod(angle + ray_angle_offset + TAU, TAU)
				var ray_t = fmod(ray_angle, TAU / num_rays) / (TAU / num_rays)
				var ray_width = 0.3 - abs(ray_t - 0.5) * 0.6
				
				if ray_width > 0.1:
					var alpha = (1.0 - dist / radius) * ray_width * 2
					var ray_color = Color(primary.r, primary.g, primary.b, alpha * primary.a)
					image.set_pixel(x, y, ray_color)

func _setup_glow() -> void:
	"""Configurar el efecto de resplandor"""
	if visual_data == null or not visual_data.glow_enabled:
		glow_sprite.visible = false
		return
	
	# Crear textura de glow
	var size = visual_data.frame_size.x * 2
	var glow_image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var glow_color = visual_data.glow_color
	
	for y in range(size):
		for x in range(size):
			var dist = Vector2(x, y).distance_to(center)
			var t = clamp(1.0 - dist / (size * 0.4), 0.0, 1.0)
			t = t * t  # Falloff cuadrático
			var pixel_color = Color(glow_color.r, glow_color.g, glow_color.b, glow_color.a * t * visual_data.glow_intensity)
			glow_image.set_pixel(x, y, pixel_color)
	
	glow_sprite.texture = ImageTexture.create_from_image(glow_image)
	glow_sprite.modulate.a = 0.6

func _setup_trail() -> void:
	"""Configurar partículas de estela"""
	if visual_data == null or not visual_data.trail_enabled:
		return
	
	trail_particles = GPUParticles2D.new()
	trail_particles.name = "TrailParticles"
	trail_particles.emitting = false
	trail_particles.amount = 20
	trail_particles.lifetime = visual_data.trail_length
	trail_particles.local_coords = false
	trail_particles.z_index = -1
	
	# Crear material de partículas
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(-1, 0, 0)  # Hacia atrás
	material.spread = 15.0
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 40.0
	material.gravity = Vector3.ZERO
	material.scale_min = 0.5
	material.scale_max = 1.0
	material.color = visual_data.trail_color
	
	# Fade out
	var gradient = Gradient.new()
	gradient.set_color(0, visual_data.trail_color)
	gradient.set_color(1, Color(visual_data.trail_color.r, visual_data.trail_color.g, visual_data.trail_color.b, 0))
	var gradient_tex = GradientTexture1D.new()
	gradient_tex.gradient = gradient
	material.color_ramp = gradient_tex
	
	trail_particles.process_material = material
	add_child(trail_particles)

# ═══════════════════════════════════════════════════════════════════════════════
# CONTROL DE ESTADOS
# ═══════════════════════════════════════════════════════════════════════════════

func play_launch() -> void:
	"""Reproducir animación de lanzamiento"""
	current_state = State.LAUNCH
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("launch"):
		sprite.play("launch")
	else:
		# Si no hay animación, emitir señal y ir directo a flight
		launch_finished.emit()
		play_flight()
		return
	animation_changed.emit("launch")

func play_flight() -> void:
	"""Reproducir animación de vuelo"""
	current_state = State.IN_FLIGHT
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("flight"):
		sprite.play("flight")
	
	# Activar trail
	if trail_particles:
		trail_particles.emitting = true
	
	animation_changed.emit("flight")

func play_impact() -> void:
	"""Reproducir animación de impacto"""
	current_state = State.IMPACT
	impact_started.emit()
	
	# Desactivar trail
	if trail_particles:
		trail_particles.emitting = false
	
	# Escalar para el impacto
	if visual_data:
		var tween = create_tween()
		tween.tween_property(self, "scale", 
			Vector2.ONE * visual_data.base_scale * visual_data.impact_scale_multiplier, 
			0.1).set_ease(Tween.EASE_OUT)
	
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("impact"):
		sprite.play("impact")
	else:
		# Auto-destruir después de un momento
		await get_tree().create_timer(0.2).timeout
		impact_finished.emit()
	
	animation_changed.emit("impact")

func set_direction(dir: Vector2) -> void:
	"""Actualizar la dirección del proyectil"""
	_current_direction = dir.normalized()
	
	# Si lock_rotation está activo, el sprite mantiene su orientación fija (ej: tornados)
	if _lock_rotation:
		return
	
	# La rotación del sprite se basa directamente en la dirección del movimiento
	# Los sprites deben estar dibujados apuntando a la DERECHA (0°)
	# Se añade _rotation_offset para corregir sprites con ejes desalineados
	rotation = dir.angle() + _rotation_offset
	
	# Actualizar dirección de partículas
	if trail_particles and trail_particles.process_material:
		var mat = trail_particles.process_material as ParticleProcessMaterial
		if mat:
			mat.direction = Vector3(-dir.x, -dir.y, 0)

func set_rotation_offset(offset_degrees: float) -> void:
	"""Establecer offset de rotación en grados para corregir sprites desalineados"""
	_rotation_offset = deg_to_rad(offset_degrees)

func set_lock_rotation(locked: bool) -> void:
	"""Bloquear rotación del sprite (útil para tornados y efectos simétricos)"""
	_lock_rotation = locked
	if locked:
		rotation = 0  # Resetear a orientación original

# ═══════════════════════════════════════════════════════════════════════════════
# PROCESO
# ═══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	_time += delta
	
	# Efecto de pulso en el glow
	if glow_sprite and glow_sprite.visible:
		var pulse = sin(_time * 4.0) * 0.1 + 0.9
		glow_sprite.scale = Vector2.ONE * pulse * 1.5
	
	# Squash & stretch durante el vuelo
	if current_state == State.IN_FLIGHT and _squash_stretch_enabled:
		var squash = 1.0 + sin(_time * 8.0) * 0.05
		sprite.scale = Vector2(1.0 / squash, squash)

func _on_animation_finished() -> void:
	"""Manejar fin de animaciones"""
	match current_state:
		State.LAUNCH:
			launch_finished.emit()
			play_flight()
		State.IMPACT:
			impact_finished.emit()

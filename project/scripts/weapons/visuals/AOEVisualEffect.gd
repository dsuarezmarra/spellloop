# AOEVisualEffect.gd
# Efecto visual animado para ataques de área (AOE)
# Estilo: Cartoon/Funko Pop con animaciones Appear → Active → Fade

class_name AOEVisualEffect
extends Node2D

# ═══════════════════════════════════════════════════════════════════════════════
# SEÑALES
# ═══════════════════════════════════════════════════════════════════════════════

signal appear_finished
signal active_started
signal fade_finished

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADOS
# ═══════════════════════════════════════════════════════════════════════════════

enum State {
	NONE,
	APPEARING,
	ACTIVE,
	FADING
}

var current_state: State = State.NONE
var visual_data: ProjectileVisualData

# ═══════════════════════════════════════════════════════════════════════════════
# NODOS
# ═══════════════════════════════════════════════════════════════════════════════

var sprite: AnimatedSprite2D
var glow_sprite: Sprite2D
var ring_sprite: Sprite2D  # Anillo exterior
var particles: GPUParticles2D

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

var _time: float = 0.0
var _radius: float = 100.0
var _duration: float = 0.5
var _active_time: float = 0.0

# === OPTIMIZACIÓN ===
var _frame_counter: int = 0
const VISUAL_UPDATE_INTERVAL: int = 2  # Actualizar glow cada N frames

# Límite máximo de escala visual para evitar overdraw masivo
# (aprox 4.0 con sprites de 64px = 256px radio visual, suficiente para pantalla)
const MAX_VISUAL_SCALE: float = 4.0

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_ensure_nodes_created()

func _ensure_nodes_created() -> void:
	"""Asegurar que los nodos estén creados"""
	if sprite == null:
		_create_nodes()

func setup(data: ProjectileVisualData, radius: float, duration: float = 0.5) -> void:
	"""Configurar el efecto AOE"""
	_ensure_nodes_created()
	visual_data = data
	_radius = radius
	_duration = duration
	
	if visual_data:
		_setup_animations()
	else:
		_setup_procedural()
	
	_setup_particles()

func _create_nodes() -> void:
	"""Crear estructura de nodos"""
	# Glow de fondo
	glow_sprite = Sprite2D.new()
	glow_sprite.name = "Glow"
	glow_sprite.z_index = -2
	add_child(glow_sprite)
	
	# Anillo exterior
	ring_sprite = Sprite2D.new()
	ring_sprite.name = "Ring"
	ring_sprite.z_index = -1
	add_child(ring_sprite)
	
	# Sprite principal animado
	sprite = AnimatedSprite2D.new()
	sprite.name = "MainSprite"
	sprite.centered = true
	add_child(sprite)
	sprite.animation_finished.connect(_on_animation_finished)

func _setup_animations() -> void:
	"""Configurar animaciones desde sprites"""
	var frames = SpriteFrames.new()
	var has_any_animation = false
	
	# Animación de aparición
	if visual_data.aoe_appear_spritesheet:
		_add_animation(frames, "appear", visual_data.aoe_appear_spritesheet, 
			visual_data.aoe_appear_frames, visual_data.aoe_fps, false)
		has_any_animation = true
	
	# Animación activa (loop)
	if visual_data.aoe_active_spritesheet:
		_add_animation(frames, "active", visual_data.aoe_active_spritesheet, 
			visual_data.aoe_active_frames, visual_data.aoe_fps, true)
		has_any_animation = true
	
	# Animación de fade
	if visual_data.aoe_fade_spritesheet:
		_add_animation(frames, "fade", visual_data.aoe_fade_spritesheet, 
			visual_data.aoe_fade_frames, visual_data.aoe_fps, false)
		has_any_animation = true
	
	# Si no hay ninguna animación de sprites, usar procedural
	if not has_any_animation:
		_setup_procedural()
		return
	
	sprite.sprite_frames = frames
	
	# Escalar según el radio y el base_scale
	var sprite_scale = _radius * 2.0 / visual_data.frame_size.x
	if visual_data.base_scale != 1.0:
		sprite_scale *= visual_data.base_scale
	
	# CAP: Limitar escala visual (No afecta área lógica de daño, solo visual)
	sprite_scale = minf(sprite_scale, MAX_VISUAL_SCALE)
	
	sprite.scale = Vector2.ONE * sprite_scale
	
	# Aplicar transparencia del 30% a todos los AOE
	sprite.modulate.a = 0.7

# Cache estático retirado ya que usamos assets
static var _fallback_texture_cache: Dictionary = {}

func _setup_procedural() -> void:
	"""Fallback: Usar spritesheet genérico (fire_stomp) de VFXManager"""
	# Intentar obtener configuración de fire_stomp del VFXManager
	var vfx_mgr = get_node_or_null("/root/VFXManager")
	if not vfx_mgr:
		return

	var config = vfx_mgr.AOE_CONFIG.get("fire_stomp")
	if not config:
		return
		
	var path = config.get("path", "")
	if path.is_empty():
		return

	var tex: Texture2D
	if _fallback_texture_cache.has(path):
		tex = _fallback_texture_cache[path]
	elif ResourceLoader.exists(path):
		tex = load(path)
		_fallback_texture_cache[path] = tex
	else:
		return

	# Configurar frames desde el spritesheet
	var frames = SpriteFrames.new()
	var hframes = config.get("hframes", 4)
	var vframes = config.get("vframes", 2)
	var frame_size = config.get("frame_size", Vector2(128, 128))
	var fps = 12.0
	
	# Mapear animación: Usar todo el spritesheet como "active" y "appear"
	# Appear: frames 0-3
	frames.add_animation("appear")
	frames.set_animation_loop("appear", false)
	frames.set_animation_speed("appear", fps)
	
	for i in range(min(4, hframes * vframes)):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		# Suponiendo grid regular izquierda-derecha, arriba-abajo
		# Fila 0
		atlas.region = Rect2(i * frame_size.x, 0, frame_size.x, frame_size.y)
		frames.add_frame("appear", atlas)

	# Active: frames 4-7 (loop)
	frames.add_animation("active")
	frames.set_animation_loop("active", true)
	frames.set_animation_speed("active", fps)
	
	# Usar segunda fila si existe, sino repetir primera
	var row = 1 if vframes > 1 else 0
	for i in range(hframes):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * frame_size.x, row * frame_size.y, frame_size.x, frame_size.y)
		frames.add_frame("active", atlas)

	# Fade: invertir appear o usar últimos frames
	frames.add_animation("fade")
	frames.set_animation_loop("fade", false)
	frames.set_animation_speed("fade", fps)
	
	# Reusar frames de appear pero reverse o alpha fade en tween
	for i in range(min(4, hframes * vframes)):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * frame_size.x, 0, frame_size.x, frame_size.y)
		frames.add_frame("fade", atlas)

	sprite.sprite_frames = frames
	
	# Escalar al tamaño deseado
	var target_scale = 1.0
	if _radius > 0:
		target_scale = _radius * 2.0 / frame_size.x
		
	# Clamp scale
	target_scale = minf(target_scale, MAX_VISUAL_SCALE)
	sprite.scale = Vector2.ONE * target_scale
	sprite.modulate.a = 0.8
	
	# Ajustar glow también
	if glow_sprite:
		_create_glow_texture(int(frame_size.x), visual_data.primary_color if visual_data else Color(1, 0.5, 0.2))
		glow_sprite.scale = Vector2.ONE * target_scale * 1.5
	
	if ring_sprite:
		var outline = visual_data.outline_color if visual_data else Color(0.5, 0.2, 0)
		var accent = visual_data.accent_color if visual_data else Color(1, 0.8, 0.4)
		_create_ring_texture(int(frame_size.x), outline, accent)
		ring_sprite.scale = Vector2.ONE * target_scale * 1.2


func _create_glow_texture(size: int, color: Color) -> void:
	"""Crear textura de resplandor"""
	var glow_size = int(size * 1.5)
	var image = Image.create(glow_size, glow_size, false, Image.FORMAT_RGBA8)
	var center = Vector2(glow_size / 2.0, glow_size / 2.0)
	
	for y in range(glow_size):
		for x in range(glow_size):
			var dist = Vector2(x, y).distance_to(center)
			var t = clamp(1.0 - dist / (glow_size * 0.45), 0.0, 1.0)
			t = t * t * t  # Falloff cúbico
			image.set_pixel(x, y, Color(color.r, color.g, color.b, t * 0.4))
	
	glow_sprite.texture = ImageTexture.create_from_image(image)

func _create_ring_texture(size: int, outline: Color, accent: Color) -> void:
	"""Crear textura de anillo exterior"""
	var ring_size = int(size * 1.2)
	var image = Image.create(ring_size, ring_size, false, Image.FORMAT_RGBA8)
	var center = Vector2(ring_size / 2.0, ring_size / 2.0)
	var outer_radius = ring_size * 0.45
	var inner_radius = ring_size * 0.42
	
	for y in range(ring_size):
		for x in range(ring_size):
			var dist = Vector2(x, y).distance_to(center)
			
			if dist <= outer_radius and dist >= inner_radius:
				var ring_t = (dist - inner_radius) / (outer_radius - inner_radius)
				var ring_color = outline.lerp(accent, abs(ring_t - 0.5) * 2.0)
				ring_color.a *= 0.6
				image.set_pixel(x, y, ring_color)
	
	ring_sprite.texture = ImageTexture.create_from_image(image)

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

func _setup_particles() -> void:
	"""Configurar partículas del AOE"""
	particles = GPUParticles2D.new()
	particles.name = "Particles"
	particles.emitting = false
	particles.amount = 30
	particles.lifetime = 0.8
	particles.explosiveness = 0.3
	
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	material.emission_ring_radius = _radius * 0.8
	material.emission_ring_inner_radius = _radius * 0.3
	material.emission_ring_height = 0
	material.direction = Vector3(0, -1, 0)
	material.spread = 30.0
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 60.0
	material.gravity = Vector3(0, -20, 0)
	material.scale_min = 0.3
	material.scale_max = 0.8
	
	var color = visual_data.primary_color if visual_data else Color(0.4, 0.8, 1.0)
	material.color = color
	
	particles.process_material = material
	add_child(particles)

# ═══════════════════════════════════════════════════════════════════════════════
# CONTROL DE ESTADOS
# ═══════════════════════════════════════════════════════════════════════════════

func play_appear() -> void:
	"""Iniciar animación de aparición"""
	current_state = State.APPEARING
	
	# Animación de escala
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("appear"):
		sprite.play("appear")
	else:
		await tween.finished
		_on_animation_finished()
	
	# Activar partículas
	if particles:
		particles.emitting = true

func play_active(duration: float = -1.0) -> void:
	"""Mantener estado activo"""
	current_state = State.ACTIVE
	_active_time = duration if duration > 0 else _duration
	
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("active"):
		sprite.play("active")
	
	active_started.emit()
	
	# Auto-fade después del tiempo
	if _active_time > 0:
		await get_tree().create_timer(_active_time).timeout
		if current_state == State.ACTIVE:
			play_fade()

func play_fade() -> void:
	"""Iniciar animación de desvanecimiento"""
	current_state = State.FADING
	
	# Desactivar partículas
	if particles:
		particles.emitting = false
	
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("fade"):
		sprite.play("fade")
	
	# Tween de escala y alpha
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2.ONE * 0.8, 0.3)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	
	# Asegurar que la señal se emita al terminar el tween si no hay animación de sprite
	if not sprite.sprite_frames or not sprite.sprite_frames.has_animation("fade"):
		tween.finished.connect(func(): _on_animation_finished())

func _on_animation_finished() -> void:
	"""Manejar fin de animaciones"""
	match current_state:
		State.APPEARING:
			appear_finished.emit()
			play_active()
		State.FADING:
			fade_finished.emit()
			queue_free()

# ═══════════════════════════════════════════════════════════════════════════════
# PROCESO
# ═══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	_time += delta
	
	# Rotación del ring (siempre necesaria para movimiento suave)
	if ring_sprite:
		ring_sprite.rotation += delta * 0.5
	
	# OPTIMIZACIÓN: Throttle para efectos de glow
	_frame_counter += 1
	if _frame_counter < VISUAL_UPDATE_INTERVAL:
		return
	_frame_counter = 0
	
	# Pulso del glow - aproximación rápida sin sin()
	if glow_sprite:
		var pulse_phase = fmod(_time * 3.0, TAU)
		var pulse = 1.0 - abs(pulse_phase - PI) / PI * 0.3 + 0.85  # 0.85 a 1.15
		glow_sprite.scale = Vector2.ONE * pulse
		
		var alpha_phase = fmod(_time * 5.0, TAU)
		glow_sprite.modulate.a = 0.4 + (1.0 - abs(alpha_phase - PI) / PI * 2.0) * 0.1

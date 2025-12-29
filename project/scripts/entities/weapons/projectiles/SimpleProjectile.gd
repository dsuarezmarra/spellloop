# SimpleProjectile.gd
# Sistema de proyectiles con diferentes tipos de elemento
# ACTUALIZADO: Integra AnimatedProjectileSprite para visuales mejorados
# 
# Tipos soportados:
# - ice: Esquirla de hielo (rombo azul brillante)
# - fire: Bola de fuego (círculo naranja con estela)
# - arcane: Orbe arcano (esfera púrpura pulsante)
# - lightning: Rayo eléctrico (forma angular amarilla)
# - dark: Proyectil oscuro (esfera negra con aura)
# - nature: Hoja/espina verde

extends Area2D
class_name SimpleProjectile

signal hit_enemy(enemy: Node, damage: int)
signal destroyed

# === CONFIGURACIÓN ===
@export var damage: int = 10
@export var speed: float = 400.0
@export var lifetime: float = 3.0
@export var knockback_force: float = 150.0
@export var pierce_count: int = 0  # 0 = no atraviesa

# === TIPO DE ELEMENTO ===
@export var element_type: String = "ice"  # ice, fire, arcane, lightning, dark, nature

# === ESTADO ===
var direction: Vector2 = Vector2.RIGHT
var current_lifetime: float = 0.0
var enemies_hit: Array[Node] = []
var pierces_remaining: int = 0

# === VISUAL ===
var sprite: Sprite2D = null
var animated_sprite: AnimatedProjectileSprite = null  # NUEVO: Visual animado
var projectile_color: Color = Color(0.4, 0.7, 1.0, 1.0)
var projectile_size: float = 12.0
var trail_particles: CPUParticles2D = null
var _weapon_id: String = ""  # Para buscar visual data

# Colores por elemento
const ELEMENT_COLORS = {
	"ice": Color(0.4, 0.8, 1.0, 1.0),      # Azul hielo
	"fire": Color(1.0, 0.5, 0.1, 1.0),     # Naranja fuego
	"arcane": Color(0.7, 0.3, 1.0, 1.0),   # Púrpura arcano
	"lightning": Color(1.0, 1.0, 0.3, 1.0), # Amarillo eléctrico
	"dark": Color(0.3, 0.1, 0.4, 1.0),     # Púrpura oscuro
	"nature": Color(0.3, 0.8, 0.2, 1.0)    # Verde naturaleza
}

func _ready() -> void:
	# Configuración básica
	z_index = 10
	pierces_remaining = pierce_count
	
	# Obtener color del elemento
	if ELEMENT_COLORS.has(element_type):
		projectile_color = ELEMENT_COLORS[element_type]
	
	# Configurar colisiones
	_setup_collision()
	
	# NUEVO: Intentar crear visual animado primero
	var used_animated = _try_create_animated_visual()
	
	if not used_animated:
		# Crear visual según tipo de elemento (fallback)
		_create_visual()
		# Crear estela de partículas
		_create_trail()
	
	# Conectar señales
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _try_create_animated_visual() -> bool:
	"""Intentar crear visual animado usando ProjectileVisualManager"""
	# Obtener weapon_id desde metadata
	_weapon_id = get_meta("weapon_id", "")
	if _weapon_id.is_empty():
		print("[SimpleProjectile] ✗ No weapon_id en metadata")
		return false
	
	# Buscar el ProjectileVisualManager
	var visual_manager = ProjectileVisualManager.instance
	if visual_manager == null:
		print("[SimpleProjectile] ✗ ProjectileVisualManager.instance es null")
		return false
	
	# Obtener weapon_data para el visual
	var weapon_data = WeaponDatabase.get_weapon_data(_weapon_id)
	if weapon_data.is_empty():
		print("[SimpleProjectile] ✗ weapon_data vacío para: %s" % _weapon_id)
		return false
	
	# Crear el visual animado
	animated_sprite = visual_manager.create_projectile_visual(_weapon_id, weapon_data)
	if animated_sprite == null:
		print("[SimpleProjectile] ✗ create_projectile_visual retornó null")
		return false
	
	add_child(animated_sprite)
	
	# Iniciar animación de vuelo (saltamos launch para proyectiles en movimiento)
	animated_sprite.play_flight()
	
	print("[SimpleProjectile] ✓ Visual animado creado para: %s" % _weapon_id)
	return true

func _setup_collision() -> void:
	# Capa 4 = proyectiles del jugador
	collision_layer = 0
	set_collision_layer_value(4, true)
	
	# Máscara 2 = enemigos
	collision_mask = 0
	set_collision_mask_value(2, true)
	
	# Crear collision shape si no existe
	var shape = get_node_or_null("CollisionShape2D")
	if not shape:
		shape = CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var circle = CircleShape2D.new()
		circle.radius = projectile_size * 0.5
		shape.shape = circle
		add_child(shape)

func _create_visual() -> void:
	"""Crear visual según tipo de elemento"""
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	
	var size = int(projectile_size * 2.5)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	
	match element_type:
		"ice":
			_draw_ice_shard(image, size, center)
		"fire":
			_draw_fireball(image, size, center)
		"arcane":
			_draw_arcane_orb(image, size, center)
		"lightning":
			_draw_lightning_bolt(image, size, center)
		"dark":
			_draw_dark_orb(image, size, center)
		"nature":
			_draw_leaf(image, size, center)
		_:
			_draw_default_orb(image, size, center)
	
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	sprite.centered = true
	add_child(sprite)

func _draw_ice_shard(image: Image, size: int, center: Vector2) -> void:
	"""Dibujar esquirla de hielo (forma de diamante/rombo)"""
	var half = size / 2.0
	for x in range(size):
		for y in range(size):
			var px = x - half
			var py = y - half
			# Forma de rombo: |x| + |y| <= radio
			var diamond_dist = abs(px) * 0.8 + abs(py)
			if diamond_dist <= half * 0.85:
				var intensity = 1.0 - (diamond_dist / (half * 0.85)) * 0.4
				var color = Color(
					0.7 * intensity + 0.3,
					0.9 * intensity + 0.1,
					1.0,
					1.0 if diamond_dist < half * 0.6 else 0.85
				)
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

func _draw_fireball(image: Image, size: int, center: Vector2) -> void:
	"""Dibujar bola de fuego (círculo con gradiente cálido)"""
	var radius = size / 2.0 - 2.0
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist <= radius:
				var t = dist / radius
				# Gradiente: centro amarillo -> naranja -> rojo exterior
				var color: Color
				if t < 0.3:
					color = Color(1.0, 1.0, 0.5, 1.0)  # Amarillo centro
				elif t < 0.6:
					color = Color(1.0, 0.6, 0.1, 1.0)  # Naranja
				else:
					color = Color(1.0, 0.3, 0.0, 0.9)  # Rojo exterior
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

func _draw_arcane_orb(image: Image, size: int, center: Vector2) -> void:
	"""Dibujar orbe arcano (esfera púrpura con brillo)"""
	var radius = size / 2.0 - 2.0
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist <= radius:
				var t = 1.0 - dist / radius
				var color = Color(
					0.6 + t * 0.4,
					0.2 + t * 0.3,
					1.0,
					0.8 + t * 0.2
				)
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

func _draw_lightning_bolt(image: Image, size: int, center: Vector2) -> void:
	"""Dibujar rayo eléctrico (forma angular)"""
	var half = size / 2.0
	for x in range(size):
		for y in range(size):
			var px = (x - half) / half
			var py = (y - half) / half
			# Forma de rayo zigzag
			var in_bolt = abs(px) < 0.4 and abs(py) < 0.9
			in_bolt = in_bolt or (abs(px - 0.2) < 0.3 and py > -0.3 and py < 0.3)
			if in_bolt:
				var intensity = 0.8 + randf() * 0.2
				image.set_pixel(x, y, Color(1.0, 1.0, 0.3 * intensity, 1.0))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

func _draw_dark_orb(image: Image, size: int, center: Vector2) -> void:
	"""Dibujar orbe oscuro (núcleo oscuro con aura púrpura)"""
	var radius = size / 2.0 - 1.0
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist <= radius:
				var t = dist / radius
				if t < 0.5:
					# Núcleo oscuro
					image.set_pixel(x, y, Color(0.15, 0.05, 0.2, 1.0))
				else:
					# Aura púrpura
					var alpha = 1.0 - (t - 0.5) * 1.5
					image.set_pixel(x, y, Color(0.5, 0.1, 0.6, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

func _draw_leaf(image: Image, size: int, center: Vector2) -> void:
	"""Dibujar hoja/espina de naturaleza"""
	var half = size / 2.0
	for x in range(size):
		for y in range(size):
			var px = (x - half) / half
			var py = (y - half) / half
			# Forma de hoja: elipse con punta
			var leaf_shape = (px * px * 2.0 + py * py) < 0.7 and py < 0.8
			if leaf_shape:
				var intensity = 0.7 + abs(px) * 0.3
				image.set_pixel(x, y, Color(0.2, 0.7 * intensity, 0.1, 1.0))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

func _draw_default_orb(image: Image, size: int, center: Vector2) -> void:
	"""Dibujar orbe por defecto"""
	var radius = size / 2.0 - 1.0
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			if dist <= radius:
				var intensity = 1.0 - (dist / radius) * 0.5
				var color = Color(
					projectile_color.r * intensity + 0.3,
					projectile_color.g * intensity + 0.3,
					projectile_color.b * intensity,
					1.0 if dist < radius * 0.8 else 0.8
				)
				image.set_pixel(x, y, color)
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))

func _create_trail() -> void:
	"""Crear partículas de estela según elemento"""
	trail_particles = CPUParticles2D.new()
	trail_particles.name = "Trail"
	trail_particles.emitting = true
	trail_particles.amount = 8
	trail_particles.lifetime = 0.3
	trail_particles.speed_scale = 1.5
	trail_particles.explosiveness = 0.0
	trail_particles.direction = Vector2(-1, 0)  # Hacia atrás
	trail_particles.spread = 15.0
	trail_particles.gravity = Vector2.ZERO
	trail_particles.initial_velocity_min = 20.0
	trail_particles.initial_velocity_max = 40.0
	trail_particles.scale_amount_min = 0.3
	trail_particles.scale_amount_max = 0.6
	trail_particles.color = projectile_color
	add_child(trail_particles)

func _process(delta: float) -> void:
	# Actualizar lifetime
	current_lifetime += delta
	if current_lifetime >= lifetime:
		_destroy()
		return
	
	# Mover en línea recta (SIN rotación)
	global_position += direction * speed * delta
	
	# Actualizar dirección del sprite animado
	if animated_sprite and is_instance_valid(animated_sprite):
		animated_sprite.set_direction(direction)

func initialize(start_pos: Vector2, target_pos: Vector2, dmg: int = -1, spd: float = -1) -> void:
	"""Inicializar proyectil - llamar DESPUÉS de add_child()"""
	global_position = start_pos
	direction = (target_pos - start_pos).normalized()
	
	if dmg > 0:
		damage = dmg
	if spd > 0:
		speed = spd

func set_color(color: Color) -> void:
	"""Cambiar color del proyectil"""
	projectile_color = color
	if sprite:
		sprite.modulate = color

func _on_body_entered(body: Node2D) -> void:
	_handle_hit(body)

func _on_area_entered(area: Area2D) -> void:
	# Si el área tiene un parent que es enemigo
	if area.get_parent() and area.get_parent().is_in_group("enemies"):
		_handle_hit(area.get_parent())

func _handle_hit(target: Node) -> void:
	# Ignorar si ya golpeamos este enemigo
	if target in enemies_hit:
		return
	
	# Verificar que es un enemigo
	if not target.is_in_group("enemies"):
		return
	
	enemies_hit.append(target)
	
	# Aplicar daño
	if target.has_method("take_damage"):
		target.take_damage(damage)
	elif target.has_node("HealthComponent"):
		var hc = target.get_node("HealthComponent")
		if hc.has_method("take_damage"):
			hc.take_damage(damage, "physical")
	
	# Aplicar knockback
	if knockback_force > 0 and target.has_method("apply_knockback"):
		target.apply_knockback(direction * knockback_force)
	elif knockback_force > 0 and target is CharacterBody2D:
		target.velocity += direction * knockback_force
	
	# Emitir señal
	hit_enemy.emit(target, damage)
	
	# Efecto de impacto
	_spawn_hit_effect()
	
	# Verificar pierce
	if pierces_remaining > 0:
		pierces_remaining -= 1
	else:
		_destroy()

func _spawn_hit_effect() -> void:
	"""Crear efecto visual simple al impactar"""
	# Partículas simples de impacto
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 8
	particles.lifetime = 0.3
	particles.direction = -direction
	particles.spread = 45.0
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 100.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = projectile_color
	
	particles.global_position = global_position
	get_tree().current_scene.add_child(particles)
	
	# Auto-destruir partículas
	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(func(): 
		if is_instance_valid(particles):
			particles.queue_free()
	)

func _destroy() -> void:
	# Si tenemos visual animado, reproducir impacto
	if animated_sprite and is_instance_valid(animated_sprite):
		# Detener movimiento
		set_process(false)
		# Reproducir animación de impacto
		animated_sprite.play_impact()
		# Esperar a que termine
		await animated_sprite.impact_finished
	
	destroyed.emit()
	queue_free()

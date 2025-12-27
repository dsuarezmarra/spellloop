# SimpleProjectile.gd
# Sistema de proyectiles SIMPLE y EFECTIVO - Inspirado en Vampire Survivors
# 
# Características:
# - Movimiento en línea recta hacia el objetivo
# - Visual circular/orbe claro y visible
# - Sin rotación complicada
# - Detección de colisión simple
# - Daño al contacto con knockback

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

# === ESTADO ===
var direction: Vector2 = Vector2.RIGHT
var current_lifetime: float = 0.0
var enemies_hit: Array[Node] = []
var pierces_remaining: int = 0

# === VISUAL ===
var sprite: Sprite2D = null
var projectile_color: Color = Color(0.4, 0.7, 1.0, 1.0)  # Azul hielo por defecto
var projectile_size: float = 12.0

func _ready() -> void:
	# Configuración básica
	z_index = 10
	pierces_remaining = pierce_count
	
	# Configurar colisiones
	_setup_collision()
	
	# Crear visual
	_create_visual()
	
	# Conectar señales
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

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
	# Crear sprite circular simple
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	
	# Crear textura de orbe/círculo
	var size = int(projectile_size * 2)
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	var radius = size / 2.0 - 1.0
	
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			
			if dist <= radius:
				# Gradiente desde el centro
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
	
	var texture = ImageTexture.create_from_image(image)
	sprite.texture = texture
	sprite.centered = true
	add_child(sprite)

func _process(delta: float) -> void:
	# Actualizar lifetime
	current_lifetime += delta
	if current_lifetime >= lifetime:
		_destroy()
		return
	
	# Mover en línea recta (SIN rotación)
	global_position += direction * speed * delta

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
	destroyed.emit()
	queue_free()

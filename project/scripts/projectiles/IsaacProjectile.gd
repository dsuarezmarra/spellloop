# IsaacProjectile.gd
# Proyectil simplificado estilo Isaac que usa PlayerStats
extends CharacterBody2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500
var damage: float = 10
var lifetime: float = 3.0
var effects: Array = []

# Variables de efectos especiales
var piercing: bool = false
var burn_damage: float = 0
var slow_factor: float = 1.0

func _ready():
	# Configurar según PlayerStats
	speed = PlayerStats.shot_speed
	damage = PlayerStats.damage
	lifetime = 3.0 * PlayerStats.range_multiplier
	effects = PlayerStats.get_projectile_effects()
	piercing = PlayerStats.piercing_shots
	
	# Configurar efectos específicos
	for effect in effects:
		match effect:
			"burn":
				burn_damage = damage * 0.5  # 50% del daño como quemadura
			"slow":
				slow_factor = 0.5  # Ralentiza al 50%
			"pierce":
				piercing = true
	
	# Crear sprite visual Funko Pop
	var projectile_creator = preload("res://scripts/projectiles/FunkoPopProjectile.gd").new()
	var sprite = projectile_creator.create_projectile_sprite(0, effects)  # 0 = basic type
	add_child(sprite)
	
	# Crear colisión
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(6, 6)
	collision.shape = shape
	add_child(collision)
	
	# Configurar capas de colisión
	collision_layer = 4  # Projectile layer
	collision_mask = 10  # Walls (2) + Enemies (8)
	
	print("Isaac projectile created - DMG:", damage, " Effects:", effects)

func set_direction(new_direction: Vector2):
	direction = new_direction.normalized()

func _physics_process(delta):
	# Movimiento
	velocity = direction * speed
	var collision = move_and_collide(velocity * delta)
	
	# Manejar colisiones
	if collision:
		var collider = collision.get_collider()
		handle_collision(collider)
	
	# Reducir tiempo de vida
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func handle_collision(collider):
	"""Manejar colisión con diferentes tipos de objetos"""
	print("Isaac projectile hit: ", collider.name)
	
	if collider.has_method("take_damage"):
		# Es un enemigo, aplicar daño y efectos
		apply_effects(collider)
		
		# Solo destruir el proyectil si no es perforante
		if not piercing:
			queue_free()
	else:
		# Es una pared u otro obstáculo
		queue_free()

func apply_effects(target):
	"""Aplicar efectos del proyectil al objetivo"""
	# Aplicar daño base
	target.take_damage(damage)
	
	# Aplicar efectos especiales
	for effect in effects:
		match effect:
			"burn":
				if target.has_method("apply_burn"):
					target.apply_burn(burn_damage, 2.0)
					print("Applied burn effect to ", target.name)
			"slow":
				if target.has_method("apply_slow"):
					target.apply_slow(slow_factor, 1.5)
					print("Applied slow effect to ", target.name)
			"pierce":
				# Efecto de perforación ya se maneja en handle_collision
				pass
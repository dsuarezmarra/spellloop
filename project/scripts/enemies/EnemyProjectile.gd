# EnemyProjectile.gd
# Proyectil genérico disparado por enemigos hacia el player
# Soporta diferentes tipos visuales y efectos

extends Area2D
class_name EnemyProjectile

signal hit_player(damage: int)

# Configuración
var direction: Vector2 = Vector2.ZERO
var speed: float = 200.0
var damage: int = 10
var lifetime: float = 5.0
var element_type: String = "physical"  # physical, fire, ice, dark, arcane

# Visual
var sprite: Sprite2D = null
var trail_particles: GPUParticles2D = null

# Estado
var _lifetime_timer: float = 0.0

func _ready() -> void:
	# Configurar colisión: layer 4 (EnemyProjectile), mask 1 (Player)
	collision_layer = 0
	set_collision_layer_value(4, true)
	collision_mask = 0
	set_collision_mask_value(1, true)
	
	# Crear CollisionShape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8.0
	collision.shape = shape
	add_child(collision)
	
	# Crear sprite visual
	_create_visual()
	
	# Conectar señal de colisión
	body_entered.connect(_on_body_entered)
	
	# Rotar hacia dirección de movimiento
	if direction != Vector2.ZERO:
		rotation = direction.angle()

func initialize(p_direction: Vector2, p_speed: float, p_damage: int, p_lifetime: float = 5.0, p_element: String = "physical") -> void:
	"""Inicializar el proyectil con parámetros"""
	direction = p_direction.normalized()
	speed = p_speed
	damage = p_damage
	lifetime = p_lifetime
	element_type = p_element
	_lifetime_timer = lifetime
	
	# Actualizar visual según elemento
	_update_visual_for_element()
	
	if direction != Vector2.ZERO:
		rotation = direction.angle()

func _process(delta: float) -> void:
	# Mover
	global_position += direction * speed * delta
	
	# Lifetime
	_lifetime_timer -= delta
	if _lifetime_timer <= 0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	"""Colisión con algo"""
	# Verificar si es el player
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
			print("[EnemyProjectile] 🎯 Impacto en player: %d daño (%s)" % [damage, element_type])
		hit_player.emit(damage)
		
		# Efecto de impacto
		_spawn_hit_effect()
		queue_free()

func _create_visual() -> void:
	"""Crear visual del proyectil"""
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	
	# Crear textura procedural simple
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 0.5, 0.2, 1))  # Naranja por defecto
	
	# Dibujar círculo
	var center = Vector2(8, 8)
	for x in range(16):
		for y in range(16):
			var dist = Vector2(x, y).distance_to(center)
			if dist < 6:
				var alpha = 1.0 - (dist / 6.0) * 0.5
				img.set_pixel(x, y, Color(1, 0.7, 0.3, alpha))
			elif dist < 8:
				img.set_pixel(x, y, Color(1, 0.5, 0.2, 0.3))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	
	sprite.texture = ImageTexture.create_from_image(img)
	add_child(sprite)

func _update_visual_for_element() -> void:
	"""Actualizar color según elemento"""
	if not sprite:
		return
	
	var color = Color.WHITE
	match element_type:
		"fire":
			color = Color(1, 0.4, 0.1)
		"ice":
			color = Color(0.3, 0.7, 1.0)
		"dark", "shadow", "void":
			color = Color(0.5, 0.2, 0.8)
		"arcane":
			color = Color(0.8, 0.3, 1.0)
		"poison":
			color = Color(0.3, 0.8, 0.2)
		"lightning":
			color = Color(1.0, 1.0, 0.3)
		_:
			color = Color(0.8, 0.8, 0.8)
	
	sprite.modulate = color

func _spawn_hit_effect() -> void:
	"""Crear efecto visual de impacto"""
	# TODO: Conectar con ParticleManager si existe
	pass

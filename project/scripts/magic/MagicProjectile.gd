# MagicProjectile.gd
# Proyectil mágico con diferentes elementos y efectos
extends CharacterBody2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500
var damage: int = 10
var lifetime: float = 3.0
var spell_type: SpellSystem.SpellType = SpellSystem.SpellType.BASIC
var effect_type: String = "none"

# Variables de efectos especiales
var piercing: bool = false  # Para rayos que atraviesan
var burn_duration: float = 2.0  # Duración del daño continuo
var slow_factor: float = 0.5  # Factor de ralentización
var slow_duration: float = 1.5  # Duración de ralentización

func _ready():
	# Configurar propiedades según el tipo de hechizo
	var spell_data = SpellSystem.get_spell_data(spell_type)
	speed = spell_data["speed"]
	damage = spell_data["damage"]
	effect_type = spell_data["effect"]
	
	# Configurar efectos especiales
	match effect_type:
		"pierce":
			piercing = true
		"burn", "slow":
			pass  # Se manejan en la colisión
	
	# Crear sprite visual
	var sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(8, 8, false, Image.FORMAT_RGB8)
	image.fill(SpellSystem.get_spell_color(spell_type))
	texture.set_image(image)
	sprite.texture = texture
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
	
	print("Magic projectile created - Type: ", SpellSystem.get_spell_name(spell_type), ", Effect: ", effect_type)

func set_direction(new_direction: Vector2):
	direction = new_direction.normalized()

func set_spell_type(new_spell_type: SpellSystem.SpellType):
	spell_type = new_spell_type

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
	print("Magic projectile hit: ", collider.name)
	
	if collider.has_method("take_damage"):
		# Es un enemigo, aplicar daño y efectos
		apply_spell_effect(collider)
		
		# Solo destruir el proyectil si no es perforante
		if not piercing:
			queue_free()
	else:
		# Es una pared u otro obstáculo
		queue_free()

func apply_spell_effect(target):
	"""Aplicar el efecto del hechizo al objetivo"""
	# Aplicar daño base
	target.take_damage(damage)
	
	# Aplicar efectos especiales según el tipo
	match effect_type:
		"burn":
			apply_burn_effect(target)
		"slow":
			apply_slow_effect(target)
		"pierce":
			# El rayo ya se configuró para no destruirse
			pass

func apply_burn_effect(target):
	"""Aplicar efecto de quemadura (daño continuo)"""
	if target.has_method("apply_burn"):
		target.apply_burn(damage / 2, burn_duration)
		print("Applied burn effect to ", target.name)

func apply_slow_effect(target):
	"""Aplicar efecto de ralentización"""
	if target.has_method("apply_slow"):
		target.apply_slow(slow_factor, slow_duration)
		print("Applied slow effect to ", target.name)
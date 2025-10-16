# MagicProjectile.gd
# Magic projectile for SpellLoop
extends CharacterBody2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500
var damage: int = 10
var lifetime: float = 3.0
var effect_type: String = "none"

# Visual components
@onready var sprite_node: Sprite2D
@onready var collision_shape: CollisionShape2D

# Special effects
var piercing: bool = false
var burn_duration: float = 2.0
var slow_factor: float = 0.5
var slow_duration: float = 1.5

# Internal
var life_timer: float = 0.0

func _ready():
	_setup_visuals()
	_setup_collision()
	print("[MagicProjectile] Projectile created with damage: ", damage)

func _setup_visuals():
	"""Setup projectile visual representation"""
	sprite_node = Sprite2D.new()
	add_child(sprite_node)
	
	# Create a yellow projectile
	var image = Image.create(8, 8, false, Image.FORMAT_RGB8)
	image.fill(Color.YELLOW)
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite_node.texture = texture

func _setup_collision():
	"""Setup collision detection"""
	collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = 4
	collision_shape.shape = circle_shape
	add_child(collision_shape)
	
	# Set collision layers
	collision_layer = 4  # Projectile layer
	collision_mask = 2 | 8  # Can hit walls (layer 2) and enemies (layer 8)

func _physics_process(delta):
	# Update lifetime
	life_timer += delta
	if life_timer >= lifetime:
		_destroy()
		return
	
	# Move projectile
	velocity = direction * speed
	move_and_slide()
	
	# Check for collisions
	_check_collisions()

func _check_collisions():
	"""Check for collisions with enemies or walls"""
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider:
			_handle_collision(collider)

func _handle_collision(collider: Node):
	"""Handle collision with an object"""
	print("[MagicProjectile] Hit: ", collider.name)
	
	# Check if it's an enemy
	if collider.collision_layer & 8:  # Enemy layer
		_hit_enemy(collider)
	
	# Check if it's a wall
	elif collider.collision_layer & 2:  # Wall layer
		_hit_wall()

func _hit_enemy(enemy: Node):
	"""Handle hitting an enemy"""
	print("[MagicProjectile] Hit enemy for ", damage, " damage")
	
	# Deal damage if enemy has take_damage method
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
	
	# Apply special effects
	_apply_effects(enemy)
	
	# Destroy projectile unless it's piercing
	if not piercing:
		_destroy()

func _hit_wall():
	"""Handle hitting a wall"""
	print("[MagicProjectile] Hit wall")
	_destroy()

func _apply_effects(target: Node):
	"""Apply special effects to target"""
	match effect_type:
		"burn":
			_apply_burn_effect(target)
		"slow":
			_apply_slow_effect(target)
		"pierce":
			piercing = true
		_:
			pass  # No special effect

func _apply_burn_effect(target: Node):
	"""Apply burn damage over time"""
	print("[MagicProjectile] Applied burn effect")
	# TODO: Implement burn damage over time

func _apply_slow_effect(target: Node):
	"""Apply slow effect"""
	print("[MagicProjectile] Applied slow effect")
	# TODO: Implement slow effect

func _destroy():
	"""Destroy the projectile"""
	queue_free()

func set_spell_properties(spell_damage: int, spell_speed: float, spell_effect: String):
	"""Set projectile properties from spell data"""
	damage = spell_damage
	speed = spell_speed
	effect_type = spell_effect
	
	# Update visual based on effect
	_update_visual_for_effect()

func _update_visual_for_effect():
	"""Update projectile appearance based on effect type"""
	if not sprite_node:
		return
	
	var color = Color.YELLOW
	match effect_type:
		"burn":
			color = Color.RED
		"slow":
			color = Color.CYAN
		"pierce":
			color = Color.PURPLE
		_:
			color = Color.YELLOW
	
	var image = Image.create(8, 8, false, Image.FORMAT_RGB8)
	image.fill(color)
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite_node.texture = texture

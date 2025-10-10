# SimpleProjectile.gd
# Simple projectile that moves in a straight line
extends CharacterBody2D

var speed: float = 500.0
var direction: Vector2 = Vector2.ZERO
var damage: int = 10
var lifetime: float = 3.0  # Seconds before auto-destroy
var time_alive: float = 0.0

func _ready():
	# Create visual representation
	var sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(8, 8, false, Image.FORMAT_RGB8)
	image.fill(Color.YELLOW)  # Yellow projectiles
	texture.set_image(image)
	sprite.texture = texture
	add_child(sprite)
	
	# Create collision
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 4
	collision.shape = shape
	add_child(collision)
	
	# Set collision layers
	collision_layer = 4  # Projectile layer
	collision_mask = 2 | 8  # Can hit walls (layer 2) and enemies (layer 8)
	
	print("Projectile created, direction: ", direction)

func _physics_process(delta):
	time_alive += delta
	
	# Move projectile
	velocity = direction * speed
	
	var collision_info = move_and_collide(velocity * delta)
	if collision_info:
		var collider = collision_info.get_collider()
		print("Projectile hit: ", collider.name if collider else "unknown")
		
		# If hit an enemy, deal damage
		if collider and collider.has_method("take_damage"):
			collider.take_damage(damage)
		
		# Destroy projectile on any collision
		queue_free()
		return
	
	# Auto-destroy after lifetime
	if time_alive >= lifetime:
		print("Projectile expired")
		queue_free()

func set_direction(dir: Vector2):
	direction = dir.normalized()
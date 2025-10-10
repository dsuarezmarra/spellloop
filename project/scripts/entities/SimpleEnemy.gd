# SimpleEnemy.gd
# Simple enemy that follows the player
extends CharacterBody2D

var health: int = 30
var speed: float = 150.0
var damage: int = 20
var player_ref: Node2D = null
var attack_range: float = 40.0
var attack_cooldown: float = 1.5
var attack_timer: float = 0.0

func _ready():
	# Create visual representation
	var sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(24, 24, false, Image.FORMAT_RGB8)
	image.fill(Color.RED)  # Red enemies
	texture.set_image(image)
	sprite.texture = texture
	add_child(sprite)
	
	# Create collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(22, 22)
	collision.shape = shape
	add_child(collision)
	
	# Set collision layers
	collision_layer = 8  # Enemy layer
	collision_mask = 2 | 1  # Can hit walls (layer 2) and player (layer 1)
	
	# Find player reference
	find_player()
	
	print("Enemy created with health: ", health)

func _physics_process(delta):
	if attack_timer > 0:
		attack_timer -= delta
	
	if not player_ref:
		find_player()
		return
	
	# Move towards player
	var direction = (player_ref.global_position - global_position).normalized()
	velocity = direction * speed
	
	# Check if close enough to attack
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	if distance_to_player <= attack_range and attack_timer <= 0:
		attack_player()
		attack_timer = attack_cooldown
	
	move_and_slide()

func find_player():
	"""Find the player in the scene"""
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]
		print("Enemy found player: ", player_ref.name)

func attack_player():
	"""Attack the player if in range"""
	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(damage)
		print("Enemy attacked player for ", damage, " damage!")

func take_damage(amount: int):
	"""Take damage and die if health reaches 0"""
	health -= amount
	print("Enemy took ", amount, " damage! Health: ", health)
	
	if health <= 0:
		die()

func die():
	"""Enemy death"""
	print("Enemy died!")
	queue_free()
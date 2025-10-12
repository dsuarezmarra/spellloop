# SimplePlayerIsaac.gd - Isaac-style player
extends CharacterBody2D

const SPEED = 250.0
const DASH_SPEED = 500.0
const DASH_DURATION = 0.3
const DASH_COOLDOWN = 1.0

var health: int = 100
var max_health: int = 100
var mana: int = 100
var max_mana: int = 100

var is_dashing = false
var dash_time_left = 0.0
var dash_cooldown_left = 0.0
var dash_direction = Vector2.ZERO

# Visual components
@onready var sprite_node: Sprite2D
@onready var collision_shape: CollisionShape2D

# Shooting
var can_shoot = true
var shoot_cooldown = 0.3
var shoot_timer = 0.0

func _ready() -> void:
	print("[SimplePlayerIsaac] Isaac-style player initialized")
	add_to_group("player")
	_setup_visuals()
	_setup_collision()

func _setup_visuals():
	"""Setup player visual representation"""
	sprite_node = Sprite2D.new()
	add_child(sprite_node)
	
	# Create a blue square for the player
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(Color.BLUE)
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite_node.texture = texture

func _setup_collision():
	"""Setup collision detection"""
	collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(28, 28)
	collision_shape.shape = rect_shape
	add_child(collision_shape)
	
	# Set collision layers
	collision_layer = 1  # Player layer
	collision_mask = 2 | 8  # Can hit walls (layer 2) and enemies (layer 8)

func _physics_process(delta):
	_handle_timers(delta)
	_handle_movement(delta)
	_handle_shooting()
	move_and_slide()

func _handle_timers(delta):
	"""Handle various timers"""
	if dash_time_left > 0:
		dash_time_left -= delta
		if dash_time_left <= 0:
			is_dashing = false
	
	if dash_cooldown_left > 0:
		dash_cooldown_left -= delta
	
	if shoot_timer > 0:
		shoot_timer -= delta
		if shoot_timer <= 0:
			can_shoot = true

func _handle_movement(delta):
	"""Handle player movement and dashing"""
	var input_vector = Vector2()
	
	# Get movement input
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	
	# Normalize diagonal movement
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
	
	# Handle dash
	if Input.is_action_just_pressed("dash") and dash_cooldown_left <= 0 and not is_dashing:
		_start_dash(input_vector)
	
	# Set velocity
	if is_dashing:
		velocity = dash_direction * DASH_SPEED
	else:
		velocity = input_vector * SPEED

func _start_dash(direction: Vector2):
	"""Start dash in given direction"""
	if direction.length() == 0:
		direction = Vector2(0, -1)  # Dash up if no input
	
	is_dashing = true
	dash_direction = direction
	dash_time_left = DASH_DURATION
	dash_cooldown_left = DASH_COOLDOWN
	
	print("[SimplePlayerIsaac] Dashing!")

func _handle_shooting():
	"""Handle shooting input"""
	if not can_shoot:
		return
	
	var shoot_direction = Vector2()
	
	# Get shooting input (arrow keys or right stick)
	if Input.is_action_pressed("shoot_up"):
		shoot_direction.y -= 1
	if Input.is_action_pressed("shoot_down"):
		shoot_direction.y += 1
	if Input.is_action_pressed("shoot_left"):
		shoot_direction.x -= 1
	if Input.is_action_pressed("shoot_right"):
		shoot_direction.x += 1
	
	# Mouse shooting
	if Input.is_action_pressed("cast_spell"):
		var mouse_pos = get_global_mouse_position()
		shoot_direction = (mouse_pos - global_position).normalized()
	
	if shoot_direction.length() > 0:
		_shoot_projectile(shoot_direction.normalized())

func _shoot_projectile(direction: Vector2):
	"""Shoot a magic projectile"""
	print("[SimplePlayerIsaac] Shooting projectile in direction: ", direction)
	
	# Create a simple projectile (placeholder)
	var projectile = preload("res://scripts/magic/MagicProjectile.gd").new()
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	projectile.direction = direction
	
	can_shoot = false
	shoot_timer = shoot_cooldown

func take_damage(amount: int):
	"""Take damage"""
	health -= amount
	print("[SimplePlayerIsaac] Took ", amount, " damage. Health: ", health, "/", max_health)
	
	# Visual feedback
	sprite_node.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(sprite_node, "modulate", Color.BLUE, 0.3)
	
	if health <= 0:
		die()

func heal(amount: int):
	"""Heal the player"""
	health = min(health + amount, max_health)
	print("[SimplePlayerIsaac] Healed ", amount, ". Health: ", health, "/", max_health)

func die():
	"""Handle player death"""
	print("[SimplePlayerIsaac] Player died!")
	# TODO: Handle game over
	get_tree().paused = true

func get_health() -> int:
	return health

func get_max_health() -> int:
	return max_health

func get_mana() -> int:
	return mana

func get_max_mana() -> int:
	return max_mana

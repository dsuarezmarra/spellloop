# SimplePlayer.gd - Simple player implementation
extends CharacterBody2D

var health: int = 100
var max_health: int = 100
var speed: float = 300.0
var dash_speed: float = 600.0
var dash_duration: float = 0.2
var dash_cooldown: float = 1.0

var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var movement_input: Vector2 = Vector2.ZERO
var last_movement_direction: Vector2 = Vector2.RIGHT

# Shooting variables
var shoot_timer: float = 0.0
var shoot_cooldown: float = 0.3

# Visual components
@onready var sprite_node: Sprite2D
@onready var collision_shape: CollisionShape2D

func _ready():
	print("[SimplePlayer] Simple player initialized")
	add_to_group("player")
	_setup_visuals()
	_setup_collision()

func _setup_visuals():
	"""Setup player visual representation"""
	sprite_node = Sprite2D.new()
	add_child(sprite_node)
	
	# Create a green square for the player
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(Color.GREEN)
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite_node.texture = texture

func _setup_collision():
	"""Setup collision detection"""
	collision_shape = CollisionShape2D.new()
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = Vector2(30, 30)
	collision_shape.shape = rect_shape
	add_child(collision_shape)
	
	# Set collision layers
	collision_layer = 1  # Player layer
	collision_mask = 2 | 8  # Can hit walls and enemies

func _physics_process(delta):
	_handle_timers(delta)
	_handle_input()
	_handle_movement()
	_handle_shooting()
	move_and_slide()

func _handle_timers(delta):
	"""Handle various timers"""
	if dash_timer > 0:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
	
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	
	if shoot_timer > 0:
		shoot_timer -= delta

func _handle_input():
	"""Handle input for movement and actions"""
	movement_input = Vector2.ZERO
	
	if Input.is_action_pressed("move_up"):
		movement_input.y -= 1
	if Input.is_action_pressed("move_down"):
		movement_input.y += 1
	if Input.is_action_pressed("move_left"):
		movement_input.x -= 1
	if Input.is_action_pressed("move_right"):
		movement_input.x += 1
	
	if movement_input.length() > 0:
		movement_input = movement_input.normalized()
		last_movement_direction = movement_input
	
	# Handle dash
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
		_start_dash()

func _handle_movement():
	"""Handle player movement"""
	if is_dashing:
		velocity = dash_direction * dash_speed
	else:
		velocity = movement_input * speed

func _start_dash():
	"""Start dash ability"""
	var dash_dir = movement_input
	if dash_dir.length() == 0:
		dash_dir = last_movement_direction
	
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	dash_direction = dash_dir
	
	print("[SimplePlayer] Dashing!")

func _handle_shooting():
	"""Handle shooting input"""
	if shoot_timer > 0:
		return
	
	var should_shoot = false
	var shoot_direction = Vector2.ZERO
	
	# Spacebar shooting in last movement direction
	if Input.is_action_just_pressed("cast_spell"):
		should_shoot = true
		shoot_direction = last_movement_direction
	
	# Mouse shooting
	if Input.is_action_pressed("cast_spell"):
		should_shoot = true
		var mouse_pos = get_global_mouse_position()
		shoot_direction = (mouse_pos - global_position).normalized()
	
	if should_shoot:
		_shoot_projectile(shoot_direction)

func _shoot_projectile(direction: Vector2):
	"""Shoot a projectile in the given direction"""
	print("[SimplePlayer] Shooting projectile")
	
	# Create simple projectile
	var projectile = preload("res://scripts/magic/MagicProjectile.gd").new()
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	projectile.direction = direction
	
	shoot_timer = shoot_cooldown

func take_damage(amount: int):
	"""Take damage"""
	health -= amount
	print("[SimplePlayer] Took ", amount, " damage. Health: ", health, "/", max_health)
	
	# Visual feedback
	sprite_node.modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(sprite_node, "modulate", Color.GREEN, 0.3)
	
	if health <= 0:
		die()

func die():
	"""Handle player death"""
	print("[SimplePlayer] Player died!")
	# TODO: Handle game over

func get_health() -> int:
	return health

func get_max_health() -> int:
	return max_health
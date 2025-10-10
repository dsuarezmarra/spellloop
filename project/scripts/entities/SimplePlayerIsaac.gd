# SimplePlayerIsaac.gd - Isaac-style player with Funko Pop characteristics
extends CharacterBody2D

const SPEED = 250.0
const DASH_SPEED = 500.0
const DASH_DURATION = 0.3
const DASH_COOLDOWN = 1.0

var is_dashing = false
var dash_time_left = 0.0
var dash_cooldown_left = 0.0
var dash_direction = Vector2.ZERO

# Animation variables using new Isaac-style sprites
var current_direction = WizardSpriteLoader.Direction.DOWN
var current_frame = WizardSpriteLoader.AnimFrame.IDLE
var animation_timer = 0.0
var animation_speed = 4.0  # 4 FPS

func _ready() -> void:
	print("[SimplePlayer] Isaac-style Funko Pop player initialized")
	
	# Create collision shape (smaller for Isaac style)
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(24, 24)  # Smaller hitbox for Isaac style
	collision.shape = shape
	add_child(collision)
	
	# Create sprite node
	var sprite = Sprite2D.new()
	sprite.name = "PlayerSprite"
	add_child(sprite)
	
	# Set collision properties
	collision_layer = 1  # Player layer
	collision_mask = 2   # Collide with walls (layer 2)
	
	# Initialize sprite
	update_sprite()
	
	print("[SimplePlayer] Isaac-style player setup complete")

func _physics_process(delta: float) -> void:
	# Handle dash cooldown
	if dash_cooldown_left > 0:
		dash_cooldown_left -= delta
	
	# Handle dash
	if is_dashing:
		dash_time_left -= delta
		if dash_time_left <= 0:
			is_dashing = false
			print("[SimplePlayer] Dash ended")
		else:
			velocity = dash_direction * DASH_SPEED
			move_and_slide()
			return
	
	# Handle dash input
	if Input.is_action_just_pressed("dash") and dash_cooldown_left <= 0:
		var input_vector = Vector2(
			Input.get_axis("move_left", "move_right"),
			Input.get_axis("move_up", "move_down")
		)
		if input_vector.length() > 0:
			start_dash(input_vector.normalized())
			return
	
	# Normal movement
	var input_vector = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	
	if input_vector.length() > 0:
		velocity = input_vector.normalized() * SPEED
		update_direction_from_movement(input_vector)
		update_animation(delta, true)
	else:
		velocity = Vector2.ZERO
		update_animation(delta, false)
	
	move_and_slide()

func start_dash(direction: Vector2) -> void:
	is_dashing = true
	dash_direction = direction
	dash_time_left = DASH_DURATION
	dash_cooldown_left = DASH_COOLDOWN
	print("[SimplePlayer] Dash started in direction: ", direction)

func update_direction_from_movement(movement: Vector2):
	"""Update direction based on movement vector"""
	if movement.length() > 0:
		# Determine primary direction based on movement vector
		if abs(movement.x) > abs(movement.y):
			# Horizontal movement dominant
			if movement.x > 0:
				current_direction = WizardSpriteLoader.Direction.RIGHT
			else:
				current_direction = WizardSpriteLoader.Direction.LEFT
		else:
			# Vertical movement dominant
			if movement.y > 0:
				current_direction = WizardSpriteLoader.Direction.DOWN
			else:
				current_direction = WizardSpriteLoader.Direction.UP

func update_animation(delta: float, is_moving: bool):
	"""Update animation"""
	animation_timer += delta
	
	if is_moving:
		# Alternate between WALK1 and WALK2
		if animation_timer >= 1.0 / animation_speed:
			animation_timer = 0.0
			if current_frame == WizardSpriteLoader.AnimFrame.WALK1:
				current_frame = WizardSpriteLoader.AnimFrame.WALK2
			else:
				current_frame = WizardSpriteLoader.AnimFrame.WALK1
	else:
		# Idle state
		current_frame = WizardSpriteLoader.AnimFrame.IDLE
		animation_timer = 0.0
	
	update_sprite()

func update_sprite():
	"""Update sprite based on current direction and frame"""
	var sprite_node = get_node_or_null("PlayerSprite")
	if sprite_node:
		# Usar el nuevo sistema de carga de sprites externos
		var texture = WizardSpriteLoader.create_wizard_sprite(current_direction, current_frame)
		sprite_node.texture = texture

func _input(event):
	"""Handle shooting input"""
	if event.is_action_pressed("shoot_up"):
		shoot(Vector2(0, -1))
	elif event.is_action_pressed("shoot_down"):
		shoot(Vector2(0, 1))
	elif event.is_action_pressed("shoot_left"):
		shoot(Vector2(-1, 0))
	elif event.is_action_pressed("shoot_right"):
		shoot(Vector2(1, 0))

func shoot(direction: Vector2) -> void:
	"""Shoot a projectile in the given direction"""
	print("[SimplePlayer] Shooting in direction: ", direction)
	
	# Try to get the SpellSystem from autoload
	if SpellSystem and SpellSystem.has_method("cast_spell"):
		var spell_data = {
			"type": "basic_projectile",
			"direction": direction,
			"speed": 400,
			"damage": 10
		}
		
		SpellSystem.cast_spell(spell_data, global_position, self)
		print("[SimplePlayer] Spell cast through SpellSystem")
	else:
		print("[SimplePlayer] SpellSystem not available, creating simple projectile")
		# Fallback: create a simple projectile directly
		_create_simple_projectile(direction)

func _create_simple_projectile(direction: Vector2) -> void:
	"""Create a simple projectile as fallback"""
	var projectile = Area2D.new()
	projectile.name = "SimpleProjectile"
	
	# Add collision
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8
	collision.shape = shape
	projectile.add_child(collision)
	
	# Add sprite
	var sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color.YELLOW)
	texture.create_from_image(image)
	sprite.texture = texture
	projectile.add_child(sprite)
	
	# Set position and add to scene
	projectile.global_position = global_position + direction * 30
	get_parent().add_child(projectile)
	
	# Add simple movement without dynamic script
	var tween = create_tween()
	var target_pos = projectile.global_position + direction * 400
	tween.tween_property(projectile, "global_position", target_pos, 1.0)
	tween.tween_callback(projectile.queue_free)
	
	print("[SimplePlayer] Simple projectile created")
# Player.gd - Simplified Version
# Basic player controller for Spellloop

extends Entity
class_name PlayerSimple

# Player specific stats
@export var dash_speed: float = 500.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.0

# State
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0

# Input and facing
var facing_direction: Vector2 = Vector2.RIGHT
var last_movement_direction: Vector2 = Vector2.RIGHT

# Components
@onready var sprite: Sprite2D = $Sprite2D
@onready var dash_particles: GPUParticles2D = $DashParticles

func _ready() -> void:
	super._ready()
	
	# Set entity type
	entity_type = "player"
	
	# Initialize player stats
	base_speed = 250.0
	max_health = 100
	current_health = max_health
	
	# Setup basic appearance
	_setup_player_appearance()
	
	# Create collision shape if not exists
	if not entity_collision_shape:
		entity_collision_shape = CollisionShape2D.new()
		entity_collision_shape.name = "CollisionShape2D"
		var shape = CircleShape2D.new()
		shape.radius = 16.0
		entity_collision_shape.shape = shape
		add_child(entity_collision_shape)
	
	# Create dash particles if not exists
	if not dash_particles:
		dash_particles = GPUParticles2D.new()
		dash_particles.name = "DashParticles"
		dash_particles.emitting = false
		add_child(dash_particles)

func _physics_process(delta: float) -> void:
	# Update cooldown timers
	_update_cooldowns(delta)
	
	# Handle input
	_handle_input(delta)
	
	# Apply movement
	_handle_movement(delta)
	
	# Call parent physics process
	super._physics_process(delta)

func _setup_player_appearance() -> void:
	"""Setup basic player visual appearance"""
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	
	# Create a simple colored square as sprite
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLUE)
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture

func _handle_input(_delta: float) -> void:
	"""Handle player input"""
	var input_vector = Vector2.ZERO
	
	# Movement input
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	
	# Normalize movement
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		last_movement_direction = input_vector
		facing_direction = input_vector
	
	# Apply movement
	if not is_dashing:
		velocity = input_vector * base_speed
	
	# Dash input
	if Input.is_action_just_pressed("dash") and can_dash():
		_start_dash()

func _handle_movement(delta: float) -> void:
	"""Handle movement and dash logic"""
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			_end_dash()
	
	# Update sprite facing
	if facing_direction.x < 0:
		sprite.scale.x = -abs(sprite.scale.x)
	else:
		sprite.scale.x = abs(sprite.scale.x)

func _update_cooldowns(delta: float) -> void:
	"""Update cooldown timers"""
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

func can_dash() -> bool:
	"""Check if player can dash"""
	return not is_dashing and dash_cooldown_timer <= 0 and is_alive

func _start_dash() -> void:
	"""Start dash ability"""
	is_dashing = true
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	
	# Set dash velocity
	velocity = facing_direction * dash_speed
	
	# Start particles
	if dash_particles:
		dash_particles.emitting = true
	
	print("[Player] Dash started!")

func _end_dash() -> void:
	"""End dash ability"""
	is_dashing = false
	
	# Stop particles
	if dash_particles:
		dash_particles.emitting = false
	
	print("[Player] Dash ended!")

func take_damage(amount: int, source: Node = null) -> void:
	"""Override damage to add player-specific effects"""
	super.take_damage(amount, source)
	
	# Add screen shake or other effects here
	print("[Player] Took ", amount, " damage!")

func _on_death() -> void:
	"""Override death behavior"""
	print("[Player] Player died!")
	
	# Add death effects, game over screen, etc.
	if GameManager:
		GameManager.player_died()

# Input detection for casting
func get_cast_direction() -> Vector2:
	"""Get direction for spell casting"""
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	return direction

func get_health_percentage() -> float:
	"""Get health percentage for UI"""
	return super.get_health_percentage()
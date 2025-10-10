# Player.gd
# Player controller with movement, dash, spell casting, and input handling
# Inherits from Entity for health and damage systems
#
# Public API:
# - cast_spell(spell_slot: int) -> void
# - dash() -> void
# - equip_spell(spell_id: String, slot: int) -> void
# - get_facing_direction() -> Vector2
#
# Signals:
# - spell_cast(spell_id: String, direction: Vector2, position: Vector2)
# - dash_started()
# - dash_ended()
# - spell_changed(slot: int, spell_id: String)

extends Entity
class_name Player

signal spell_cast(spell_id: String, direction: Vector2, position: Vector2)
signal dash_started()
signal dash_ended()
signal spell_changed(slot: int, spell_id: String)

# Player stats
@export var dash_distance: float = 150.0
@export var dash_duration: float = 0.2
@export var dash_cooldown: float = 1.0

# Spell system
var equipped_spells: Array[String] = ["fireball", "ice_shard"]
var current_spell_slot: int = 0
var spell_cooldowns: Dictionary = {}

# Dash system
var is_dashing: bool = false
var dash_direction: Vector2
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
	
	# Setup player-specific properties
	_setup_player_components()
	
	print("[Player] Player initialized")

func _setup_collision_layers() -> void:
	"""Setup collision layers for player"""
	collision_layer = 1  # Player layer
	collision_mask = 4 | 8  # Walls and enemies

func _setup_player_components() -> void:
	"""Setup player-specific components"""
	# Create sprite if not exists
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	
	# Apply procedural player sprite
	SpriteGenerator.apply_sprite_to_node(self, "player")
	
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
	
	# Handle dash
	if is_dashing:
		_handle_dash(delta)
	else:
		# Normal movement when not dashing
		_handle_movement(delta)
	
	# Handle input
	_handle_input()
	
	# Update facing direction
	_update_facing_direction()
	
	# Apply physics
	move_and_slide()

func _handle_movement(delta: float) -> void:
	"""Handle player movement input"""
	if not can_move():
		apply_friction(delta)
		return
	
	var input_vector = InputManager.get_movement_vector()
	
	if input_vector.length() > 0:
		# Store last movement direction for dash
		last_movement_direction = input_vector
		
		# Apply acceleration
		var target_velocity = input_vector * base_speed
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		# Apply friction when not moving
		apply_friction(delta)

func _handle_input() -> void:
	"""Handle player input for actions"""
	if not can_act():
		return
	
	# Spell casting
	if InputManager.is_action_just_pressed("cast_primary"):
		cast_spell(0)
	elif InputManager.is_action_just_pressed("cast_secondary"):
		cast_spell(1)
	
	# Dash
	if InputManager.is_action_just_pressed("dash"):
		dash()
	
	# Swap spell
	if InputManager.is_action_just_pressed("swap_spell"):
		swap_spell_slot()

func _update_facing_direction() -> void:
	"""Update facing direction based on input or mouse"""
	if InputManager.current_device_type == "keyboard":
		# Face towards mouse cursor
		facing_direction = InputManager.get_mouse_direction_from_position(global_position)
	else:
		# Face towards gamepad right stick or movement direction
		var gamepad_direction = InputManager.get_gamepad_direction()
		if gamepad_direction.length() > 0:
			facing_direction = gamepad_direction
		elif last_movement_direction.length() > 0:
			facing_direction = last_movement_direction

func _update_cooldowns(delta: float) -> void:
	"""Update spell and dash cooldowns"""
	# Update dash cooldown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	
	# Update spell cooldowns
	for spell_id in spell_cooldowns:
		if spell_cooldowns[spell_id] > 0:
			spell_cooldowns[spell_id] -= delta

func cast_spell(spell_slot: int) -> void:
	"""Cast spell from specified slot"""
	if not can_act() or spell_slot >= equipped_spells.size():
		return
	
	var spell_id = equipped_spells[spell_slot]
	if spell_id == "":
		return
	
	# Check cooldown
	if spell_cooldowns.get(spell_id, 0) > 0:
		print("[Player] Spell ", spell_id, " is on cooldown")
		return
	
	# Calculate cast position (in front of player)
	var cast_offset = facing_direction * 20.0
	var cast_position = global_position + cast_offset
	
	# Emit spell cast signal
	spell_cast.emit(spell_id, facing_direction, cast_position)
	
	# Start cooldown (basic cooldown system)
	spell_cooldowns[spell_id] = _get_spell_cooldown(spell_id)
	
	print("[Player] Cast spell: ", spell_id, " in direction: ", facing_direction)
	
	# Play SFX
	AudioManager.play_spell_cast_sfx(spell_id)

func _get_spell_cooldown(spell_id: String) -> float:
	"""Get cooldown duration for a spell"""
	# TODO: Load from spell data
	match spell_id:
		"fireball":
			return 0.8
		"ice_shard":
			return 0.6
		"lightning_bolt":
			return 1.0
		_:
			return 1.0

func dash() -> void:
	"""Perform dash ability"""
	if not can_act() or is_dashing or dash_cooldown_timer > 0:
		return
	
	# Use last movement direction or facing direction
	var dash_dir = last_movement_direction if last_movement_direction.length() > 0 else facing_direction
	
	# Start dash
	is_dashing = true
	dash_direction = dash_dir.normalized()
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	
	# Apply dash velocity
	velocity = dash_direction * (dash_distance / dash_duration)
	
	# Become temporarily invulnerable during dash
	_start_invulnerability(dash_duration)
	
	# Visual effects
	if dash_particles:
		dash_particles.emitting = true
	
	dash_started.emit()
	print("[Player] Dash started in direction: ", dash_direction)
	
	# Play SFX
	AudioManager.play_sfx("dash")

func _handle_dash(delta: float) -> void:
	"""Handle dash movement"""
	dash_timer -= delta
	
	if dash_timer <= 0:
		# End dash
		is_dashing = false
		velocity = Vector2.ZERO
		
		# Stop visual effects
		if dash_particles:
			dash_particles.emitting = false
		
		dash_ended.emit()
		print("[Player] Dash ended")

func swap_spell_slot() -> void:
	"""Swap between equipped spells"""
	if equipped_spells.size() <= 1:
		return
	
	current_spell_slot = (current_spell_slot + 1) % equipped_spells.size()
	print("[Player] Swapped to spell slot ", current_spell_slot, ": ", equipped_spells[current_spell_slot])

func equip_spell(spell_id: String, slot: int) -> void:
	"""Equip a spell to a specific slot"""
	if slot < 0 or slot >= equipped_spells.size():
		return
	
	equipped_spells[slot] = spell_id
	spell_changed.emit(slot, spell_id)
	print("[Player] Equipped spell ", spell_id, " to slot ", slot)

func get_facing_direction() -> Vector2:
	"""Get current facing direction"""
	return facing_direction

func can_dash() -> bool:
	"""Check if player can dash"""
	return can_act() and not is_dashing and dash_cooldown_timer <= 0

func get_spell_cooldown_percentage(spell_id: String) -> float:
	"""Get spell cooldown as percentage (0.0 = ready, 1.0 = full cooldown)"""
	var remaining = spell_cooldowns.get(spell_id, 0)
	var total = _get_spell_cooldown(spell_id)
	
	if total <= 0:
		return 0.0
	
	return clamp(remaining / total, 0.0, 1.0)

func get_dash_cooldown_percentage() -> float:
	"""Get dash cooldown as percentage"""
	if dash_cooldown <= 0:
		return 0.0
	
	return clamp(dash_cooldown_timer / dash_cooldown, 0.0, 1.0)

# Override death behavior
func _on_death() -> void:
	"""Handle player death"""
	print("[Player] Player died!")
	
	# Stop all movement
	velocity = Vector2.ZERO
	is_dashing = false
	
	# Notify game manager
	if GameManager:
		GameManager.end_current_run("player_death")
	
	# Play death SFX
	AudioManager.play_player_hit_sfx()
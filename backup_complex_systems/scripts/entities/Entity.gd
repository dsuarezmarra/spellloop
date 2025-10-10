# Entity.gd
# Base class for all game entities (players, enemies, projectiles)
# Provides common functionality like health, movement, and damage system
#
# Public API:
# - take_damage(amount: int, source: Node = null) -> void
# - heal(amount: int) -> void
# - set_max_health(amount: int) -> void
# - get_health_percentage() -> float
# - die() -> void
#
# Signals:
# - health_changed(old_health: int, new_health: int)
# - max_health_changed(old_max: int, new_max: int)
# - died(entity: Entity)
# - damage_taken(amount: int, source: Node)

extends CharacterBody2D
class_name Entity

signal health_changed(old_health: int, new_health: int)
signal max_health_changed(old_max: int, new_max: int)
signal died(entity: Entity)
signal damage_taken(amount: int, source: Node)

# Health system
@export var max_health: int = 100
var current_health: int

# Common node references  
@onready var entity_collision_shape: CollisionShape2D = $CollisionShape2D

# Movement properties
@export var base_speed: float = 200.0
@export var acceleration: float = 1000.0
@export var friction: float = 800.0

# Status effects
var is_invulnerable: bool = false
var invulnerability_timer: float = 0.0
var is_stunned: bool = false
var stun_timer: float = 0.0

# Entity properties
var is_alive: bool = true
var entity_type: String = "base"

func _ready() -> void:
	# Initialize health
	current_health = max_health
	
	# Setup collision layers based on entity type
	_setup_collision_layers()
	
	print("[Entity] ", name, " initialized with ", max_health, " health")

func _physics_process(delta: float) -> void:
	# Update status effect timers
	_update_status_timers(delta)
	
	# Handle movement (to be overridden by subclasses)
	_handle_movement(delta)
	
	# Apply physics
	move_and_slide()

func _setup_collision_layers() -> void:
	"""Setup collision layers based on entity type - to be overridden"""
	pass

func _handle_movement(_delta: float) -> void:
	"""Handle movement logic - to be overridden by subclasses"""
	pass

func _update_status_timers(delta: float) -> void:
	"""Update status effect timers"""
	# Update invulnerability
	if is_invulnerable and invulnerability_timer > 0:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0:
			is_invulnerable = false
	
	# Update stun
	if is_stunned and stun_timer > 0:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false

func take_damage(amount: int, source: Node = null) -> void:
	"""Take damage from a source"""
	if not is_alive or is_invulnerable or amount <= 0:
		return
	
	var old_health = current_health
	current_health = max(0, current_health - amount)
	
	health_changed.emit(old_health, current_health)
	damage_taken.emit(amount, source)
	
	print("[Entity] ", name, " took ", amount, " damage (", current_health, "/", max_health, ")")
	
	# Trigger invulnerability frames
	if current_health > 0:
		_start_invulnerability(0.5)  # 0.5 seconds of invulnerability
	
	# Check for death
	if current_health <= 0:
		die()

func heal(amount: int) -> void:
	"""Heal the entity"""
	if not is_alive or amount <= 0:
		return
	
	var old_health = current_health
	current_health = min(max_health, current_health + amount)
	
	if current_health != old_health:
		health_changed.emit(old_health, current_health)
		print("[Entity] ", name, " healed for ", amount, " (", current_health, "/", max_health, ")")

func set_max_health(amount: int) -> void:
	"""Set maximum health"""
	if amount <= 0:
		return
	
	var old_max = max_health
	max_health = amount
	
	# Adjust current health if necessary
	if current_health > max_health:
		var old_current = current_health
		current_health = max_health
		health_changed.emit(old_current, current_health)
	
	max_health_changed.emit(old_max, max_health)

func get_health_percentage() -> float:
	"""Get health as percentage (0.0 to 1.0)"""
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)

func die() -> void:
	"""Handle entity death"""
	if not is_alive:
		return
	
	is_alive = false
	print("[Entity] ", name, " died")
	
	died.emit(self)
	
	# Override this method in subclasses for custom death behavior
	_on_death()

func _on_death() -> void:
	"""Called when entity dies - override in subclasses"""
	pass

func _start_invulnerability(duration: float) -> void:
	"""Start invulnerability for a duration"""
	is_invulnerable = true
	invulnerability_timer = duration

func stun(duration: float) -> void:
	"""Stun the entity for a duration"""
	is_stunned = true
	stun_timer = duration
	velocity = Vector2.ZERO

func knockback(force: Vector2) -> void:
	"""Apply knockback force"""
	velocity += force

func apply_friction(delta: float) -> void:
	"""Apply friction to velocity"""
	if velocity.length() > 0:
		var friction_force = velocity.normalized() * friction * delta
		if friction_force.length() > velocity.length():
			velocity = Vector2.ZERO
		else:
			velocity -= friction_force

func move_towards_target(target_position: Vector2, delta: float) -> void:
	"""Move towards a target position with acceleration"""
	var direction = (target_position - global_position).normalized()
	var target_velocity = direction * base_speed
	
	velocity = velocity.move_toward(target_velocity, acceleration * delta)

# Utility functions
func get_distance_to(target: Node2D) -> float:
	"""Get distance to another node"""
	return global_position.distance_to(target.global_position)

func get_direction_to(target: Node2D) -> Vector2:
	"""Get normalized direction to another node"""
	return (target.global_position - global_position).normalized()

func is_in_range_of(target: Node2D, range: float) -> bool:
	"""Check if target is within range"""
	return get_distance_to(target) <= range

# Status checks
func can_move() -> bool:
	"""Check if entity can move"""
	return is_alive and not is_stunned

func can_act() -> bool:
	"""Check if entity can perform actions"""
	return is_alive and not is_stunned
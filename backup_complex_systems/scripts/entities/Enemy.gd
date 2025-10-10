# Enemy.gd
# Base enemy class with AI behaviors, targeting, and attack patterns
# Inherits from Entity for health and damage systems
#
# Public API:
# - set_target(target: Entity) -> void
# - start_ai() -> void
# - stop_ai() -> void
# - attack_target() -> void
# - set_ai_behavior(behavior: AIBehavior) -> void
#
# Signals:
# - target_acquired(target: Entity)
# - target_lost()
# - attack_started(target: Entity)
# - ai_state_changed(old_state: AIState, new_state: AIState)

extends Entity
class_name Enemy

signal target_acquired(target: Entity)
signal target_lost()
signal attack_started(target: Entity)
signal ai_state_changed(old_state: AIState, new_state: AIState)

# AI behavior types
enum AIBehavior {
	AGGRESSIVE,  # Always chase and attack
	DEFENSIVE,   # Attack when approached
	PATROL,      # Move in patterns, attack when seeing player
	RANGED,      # Keep distance and shoot projectiles
	KAMIKAZE     # Rush towards player and explode
}

# AI states
enum AIState {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	FLEE,
	STUNNED,
	DEAD
}

# AI properties
@export var ai_behavior: AIBehavior = AIBehavior.AGGRESSIVE
@export var detection_range: float = 150.0
@export var attack_range: float = 50.0
@export var attack_damage: int = 15
@export var attack_cooldown: float = 1.5
@export var patrol_speed: float = 50.0
@export var chase_speed: float = 120.0

# AI state
var current_ai_state: AIState = AIState.IDLE
var target: Entity = null
var last_known_target_position: Vector2
var ai_enabled: bool = true

# Timers
var attack_cooldown_timer: float = 0.0
var state_timer: float = 0.0
var detection_timer: float = 0.0

# Patrol system
var patrol_points: Array[Vector2] = []
var current_patrol_index: int = 0
var patrol_wait_time: float = 2.0
var patrol_wait_timer: float = 0.0

# Attack system
var can_attack: bool = true
var is_attacking: bool = false

# Visual components
@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea

func _ready() -> void:
	super._ready()
	
	# Set entity type
	entity_type = "enemy"
	
	# Setup enemy-specific properties
	_setup_enemy_components()
	
	# Initialize AI
	if ai_enabled:
		start_ai()
	
	print("[Enemy] ", name, " initialized with AI behavior: ", AIBehavior.keys()[ai_behavior])

func _setup_collision_layers() -> void:
	"""Setup collision layers for enemy"""
	collision_layer = 2  # Enemy layer
	collision_mask = 1 | 4  # Player and walls

func _setup_enemy_components() -> void:
	"""Setup enemy-specific components"""
	# Create sprite if not exists
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	
	# Create detection area if not exists
	if not detection_area:
		detection_area = Area2D.new()
		detection_area.name = "DetectionArea"
		
		var detection_shape = CollisionShape2D.new()
		detection_shape.name = "DetectionShape"
		var shape = CircleShape2D.new()
		shape.radius = detection_range
		detection_shape.shape = shape
		detection_area.add_child(detection_shape)
		
		add_child(detection_area)
		
		# Set detection area collision
		detection_area.collision_layer = 0
		detection_area.collision_mask = 1  # Only detect player
		
		# Connect signals
		detection_area.body_entered.connect(_on_detection_area_entered)
		detection_area.body_exited.connect(_on_detection_area_exited)
	
	# Create attack area if not exists
	if not attack_area:
		attack_area = Area2D.new()
		attack_area.name = "AttackArea"
		
		var attack_shape = CollisionShape2D.new()
		attack_shape.name = "AttackShape"
		var shape = CircleShape2D.new()
		shape.radius = attack_range
		attack_shape.shape = shape
		attack_area.add_child(attack_shape)
		
		add_child(attack_area)
		
		# Set attack area collision
		attack_area.collision_layer = 0
		attack_area.collision_mask = 1  # Only detect player
	
	# Generate basic patrol points around starting position
	_generate_patrol_points()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	# Update AI if enabled and alive
	if ai_enabled and is_alive and not is_stunned:
		_update_ai(delta)
	
	# Update timers
	_update_timers(delta)

func _update_ai(delta: float) -> void:
	"""Update AI behavior based on current state"""
	match current_ai_state:
		AIState.IDLE:
			_ai_idle(delta)
		AIState.PATROL:
			_ai_patrol(delta)
		AIState.CHASE:
			_ai_chase(delta)
		AIState.ATTACK:
			_ai_attack(delta)
		AIState.FLEE:
			_ai_flee(delta)

func _update_timers(delta: float) -> void:
	"""Update various timers"""
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	
	state_timer += delta
	detection_timer += delta
	
	if patrol_wait_timer > 0:
		patrol_wait_timer -= delta

func start_ai() -> void:
	"""Start AI processing"""
	ai_enabled = true
	_change_ai_state(AIState.IDLE)
	print("[Enemy] ", name, " AI started")

func stop_ai() -> void:
	"""Stop AI processing"""
	ai_enabled = false
	velocity = Vector2.ZERO
	print("[Enemy] ", name, " AI stopped")

func set_target(new_target: Entity) -> void:
	"""Set the AI target"""
	if target != new_target:
		target = new_target
		if target:
			last_known_target_position = target.global_position
			target_acquired.emit(target)
			_change_ai_state(AIState.CHASE)
		else:
			target_lost.emit()
			_change_ai_state(AIState.PATROL)

func _change_ai_state(new_state: AIState) -> void:
	"""Change AI state with signal emission"""
	if current_ai_state != new_state:
		var old_state = current_ai_state
		current_ai_state = new_state
		state_timer = 0.0
		
		ai_state_changed.emit(old_state, new_state)
		print("[Enemy] ", name, " AI state: ", AIState.keys()[old_state], " -> ", AIState.keys()[new_state])

# AI Behavior Functions
func _ai_idle(delta: float) -> void:
	"""AI behavior for idle state"""
	# Apply friction
	apply_friction(delta)
	
	# Check for target
	if target and _can_see_target():
		_change_ai_state(AIState.CHASE)
	elif state_timer > 1.0:  # After 1 second of idle, start patrol
		_change_ai_state(AIState.PATROL)

func _ai_patrol(delta: float) -> void:
	"""AI behavior for patrol state"""
	# Check for target first
	if target and _can_see_target():
		_change_ai_state(AIState.CHASE)
		return
	
	# Move towards current patrol point
	if patrol_points.size() > 0:
		var target_point = patrol_points[current_patrol_index]
		var distance_to_point = global_position.distance_to(target_point)
		
		if distance_to_point < 20.0:  # Reached patrol point
			if patrol_wait_timer <= 0:
				# Move to next patrol point
				current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
				patrol_wait_timer = patrol_wait_time
		else:
			# Move towards patrol point
			move_towards_target(target_point, delta)
			velocity = velocity.limit_length(patrol_speed)

func _ai_chase(delta: float) -> void:
	"""AI behavior for chase state"""
	if not target or not is_instance_valid(target):
		set_target(null)
		return
	
	# Update last known position
	if _can_see_target():
		last_known_target_position = target.global_position
	
	var distance_to_target = global_position.distance_to(target.global_position)
	
	# Check if in attack range
	if distance_to_target <= attack_range and can_attack:
		_change_ai_state(AIState.ATTACK)
	else:
		# Chase behavior based on AI type
		match ai_behavior:
			AIBehavior.AGGRESSIVE, AIBehavior.KAMIKAZE:
				move_towards_target(target.global_position, delta)
				velocity = velocity.limit_length(chase_speed)
			
			AIBehavior.RANGED:
				# Keep optimal distance for ranged attacks
				var optimal_distance = attack_range * 0.8
				if distance_to_target < optimal_distance:
					# Move away
					var away_direction = (global_position - target.global_position).normalized()
					velocity = away_direction * chase_speed
				else:
					# Move closer
					move_towards_target(target.global_position, delta)
					velocity = velocity.limit_length(chase_speed * 0.7)
			
			AIBehavior.DEFENSIVE:
				# Only chase if target is close
				if distance_to_target < detection_range * 0.5:
					move_towards_target(target.global_position, delta)
					velocity = velocity.limit_length(chase_speed * 0.6)
				else:
					_change_ai_state(AIState.PATROL)

func _ai_attack(delta: float) -> void:
	"""AI behavior for attack state"""
	if not target or not is_instance_valid(target):
		set_target(null)
		return
	
	# Stop moving during attack
	velocity = Vector2.ZERO
	
	# Check if still in attack range
	var distance_to_target = global_position.distance_to(target.global_position)
	if distance_to_target > attack_range:
		_change_ai_state(AIState.CHASE)
		return
	
	# Attack if cooldown is ready
	if can_attack and attack_cooldown_timer <= 0:
		attack_target()

func _ai_flee(delta: float) -> void:
	"""AI behavior for flee state"""
	if target and is_instance_valid(target):
		# Move away from target
		var flee_direction = (global_position - target.global_position).normalized()
		velocity = flee_direction * chase_speed * 1.2
	else:
		# No target, return to patrol
		_change_ai_state(AIState.PATROL)

func attack_target() -> void:
	"""Perform attack on current target"""
	if not target or not can_attack or attack_cooldown_timer > 0:
		return
	
	print("[Enemy] ", name, " attacking ", target.name)
	
	# Start attack cooldown
	attack_cooldown_timer = attack_cooldown
	can_attack = false
	is_attacking = true
	
	# Emit attack signal
	attack_started.emit(target)
	
	# Perform attack based on AI behavior
	match ai_behavior:
		AIBehavior.AGGRESSIVE, AIBehavior.DEFENSIVE:
			_perform_melee_attack()
		AIBehavior.RANGED:
			_perform_ranged_attack()
		AIBehavior.KAMIKAZE:
			_perform_kamikaze_attack()
	
	# Return to chase after attack
	await get_tree().create_timer(0.5).timeout
	is_attacking = false
	can_attack = true
	
	if current_ai_state == AIState.ATTACK:
		_change_ai_state(AIState.CHASE)

func _perform_melee_attack() -> void:
	"""Perform melee attack"""
	if target and global_position.distance_to(target.global_position) <= attack_range:
		target.take_damage(attack_damage, self)
		
		# Add knockback
		var knockback_direction = (target.global_position - global_position).normalized()
		target.knockback(knockback_direction * 200)
		
		# Play attack SFX
		AudioManager.play_sfx("enemy_attack")

func _perform_ranged_attack() -> void:
	"""Perform ranged attack by shooting projectile"""
	if not target:
		return
	
	var direction = (target.global_position - global_position).normalized()
	var spawn_position = global_position + direction * 20
	
	# Create enemy projectile through spell system
	# For now, use a simple approach - later integrate with projectile system
	var projectile_scene = preload("res://scenes/characters/Projectile.tscn")
	var projectile = projectile_scene.instantiate()
	
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = spawn_position
	projectile.set_owner_entity(self)
	projectile.initialize(direction, 200, attack_damage, 300)
	
	print("[Enemy] ", name, " fired ranged attack")
	AudioManager.play_sfx("enemy_attack")

func _perform_kamikaze_attack() -> void:
	"""Perform kamikaze explosion attack"""
	if not target:
		return
	
	# Create explosion damage in area
	var explosion_radius = attack_range * 1.5
	var bodies_in_range = get_tree().get_nodes_in_group("player")
	
	for body in bodies_in_range:
		if body is Entity and global_position.distance_to(body.global_position) <= explosion_radius:
			body.take_damage(attack_damage * 2, self)
	
	# Create explosion effect
	print("[Enemy] ", name, " kamikaze explosion!")
	EffectsManager.play_spell_effect("explosion", global_position)
	EffectsManager.screen_shake(0.3, 15.0)
	AudioManager.play_sfx("enemy_attack")
	
	# Destroy self
	take_damage(max_health, self)

func _can_see_target() -> bool:
	"""Check if enemy can see the target (simple line of sight)"""
	if not target or not is_instance_valid(target):
		return false
	
	var distance = global_position.distance_to(target.global_position)
	if distance > detection_range:
		return false
	
	# Simple line of sight check (raycast to target)
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, target.global_position)
	query.collision_mask = 4  # Only check walls
	
	var result = space_state.intersect_ray(query)
	return result.is_empty()  # Can see if no wall collision

func _generate_patrol_points() -> void:
	"""Generate patrol points around starting position"""
	var start_pos = global_position
	var patrol_radius = 100.0
	
	patrol_points.clear()
	
	# Create 4 patrol points in a square pattern
	patrol_points.append(start_pos + Vector2(patrol_radius, 0))
	patrol_points.append(start_pos + Vector2(0, patrol_radius))
	patrol_points.append(start_pos + Vector2(-patrol_radius, 0))
	patrol_points.append(start_pos + Vector2(0, -patrol_radius))

func set_patrol_points(points: Array[Vector2]) -> void:
	"""Set custom patrol points"""
	patrol_points = points
	current_patrol_index = 0

# Signal handlers
func _on_detection_area_entered(body: Node2D) -> void:
	"""Handle entity entering detection range"""
	if body is Entity and body.entity_type == "player":
		set_target(body)

func _on_detection_area_exited(body: Node2D) -> void:
	"""Handle entity leaving detection range"""
	if body == target:
		# Don't immediately lose target, wait a bit
		await get_tree().create_timer(2.0).timeout
		if target and global_position.distance_to(target.global_position) > detection_range:
			set_target(null)

# Override death behavior
func _on_death() -> void:
	"""Handle enemy death"""
	print("[Enemy] ", name, " defeated!")
	
	# Stop AI
	stop_ai()
	
	# Update game stats
	if GameManager:
		GameManager.increment_run_stat("enemies_defeated")
	
	# Visual and audio effects for death
	EffectsManager.play_spell_effect("death", global_position)
	AudioManager.play_enemy_hit_sfx()
	
	# Small screen shake on death
	EffectsManager.screen_shake(0.1, 5.0)
	
	# TODO: Drop loot/experience
	# TODO: Death animation
	
	# Remove from scene after a delay
	await get_tree().create_timer(1.0).timeout
	queue_free()

# Debug visualization
func _draw() -> void:
	"""Debug visualization of AI ranges"""
	if Engine.is_editor_hint():
		return
	
	# Only draw in debug mode
	if not get_viewport().debug_draw:
		return
	
	# Draw detection range
	draw_circle(Vector2.ZERO, detection_range, Color.YELLOW, false, 2.0)
	
	# Draw attack range
	draw_circle(Vector2.ZERO, attack_range, Color.RED, false, 2.0)
	
	# Draw patrol points
	for point in patrol_points:
		var local_point = to_local(point)
		draw_circle(local_point, 5, Color.BLUE, true)

# Utility functions
func get_distance_to_target() -> float:
	"""Get distance to current target"""
	if target:
		return global_position.distance_to(target.global_position)
	return INF

func is_target_in_attack_range() -> bool:
	"""Check if target is in attack range"""
	return target and get_distance_to_target() <= attack_range

func get_ai_state_name() -> String:
	"""Get current AI state as string"""
	return AIState.keys()[current_ai_state]
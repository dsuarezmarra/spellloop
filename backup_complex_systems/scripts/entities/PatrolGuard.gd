# PatrolGuard.gd
# Patrol enemy that follows set routes and investigates disturbances
# Good for testing patrol AI and stealth-like mechanics

extends Enemy
class_name PatrolGuard

var investigate_position: Vector2
var original_patrol_index: int = 0
var patrol_target: Vector2
var patrol_timer: Timer

func _ready() -> void:
	super._ready()
	
	# Configure guard stats
	ai_behavior = AIBehavior.PATROL
	max_health = 45
	current_health = max_health
	base_speed = 70.0
	
	# AI parameters
	detection_range = 100.0
	attack_range = 50.0
	attack_damage = 12
	attack_cooldown = 1.5
	chase_speed = 110.0
	patrol_speed = 50.0
	
	# Patrol specific
	patrol_wait_time = 2.0
	
	# Apply guard appearance
	_setup_guard_appearance()
	
	# Setup patrol route
	_generate_patrol_route()
	
	print("[PatrolGuard] Patrol Guard initialized with ", patrol_points.size(), " patrol points")

func _setup_guard_appearance() -> void:
	"""Setup guard visual appearance"""
	if sprite:
		# Apply procedural guard sprite
		SpriteGeneratorUtils.apply_sprite_to_node(self, "enemy")
		sprite.modulate = Color.ORANGE_RED
		# Guards are slightly larger
		sprite.scale = Vector2(1.2, 1.2)
	
	# Larger collision for armored guard
	if entity_collision_shape and entity_collision_shape.shape is CircleShape2D:
		entity_collision_shape.shape.radius = 15.0

func _generate_patrol_route() -> void:
	"""Generate a patrol route around the guard's starting position"""
	var start_pos = global_position
	var route_radius = 100.0
	
	# Create 4-point patrol route
	for i in range(4):
		var angle = (i * PI * 0.5) + PI * 0.25  # 45, 135, 225, 315 degrees
		var point = start_pos + Vector2(cos(angle), sin(angle)) * route_radius
		patrol_points.append(point)
	
	# Set first patrol target
	if patrol_points.size() > 0:
		patrol_target = patrol_points[0]

func _handle_patrol_state(_delta: float) -> void:
	"""Override patrol handling for route following"""
	if patrol_points.is_empty():
		_generate_patrol_route()
		return
	
	# Move toward current patrol point
	var direction = (patrol_target - global_position).normalized()
	velocity = direction * patrol_speed
	
	# Check if reached patrol point
	if global_position.distance_to(patrol_target) < 20.0:
		_advance_to_next_patrol_point()

func _advance_to_next_patrol_point() -> void:
	"""Move to next point in patrol route"""
	current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
	patrol_target = patrol_points[current_patrol_index]
	
	# Brief pause at patrol points
	patrol_timer.start(patrol_wait_time)
	print("[PatrolGuard] Reached patrol point ", current_patrol_index, ", waiting...")

func _perform_melee_attack() -> void:
	"""Override melee attack for guard-specific behavior"""
	super._perform_melee_attack()
	
	# Guards are sturdy and don't get knocked back
	velocity *= 0.5  # Reduce knockback
	
	print("[PatrolGuard] Guard shield bash!")

func _on_target_lost() -> void:
	"""Override target lost to return to patrol"""
	# Don't call super since the function doesn't exist
	print("[PatrolGuard] Target lost, returning to patrol")
	
	# Remember where we lost the target for investigation
	if target:
		investigate_position = target.global_position
		original_patrol_index = current_patrol_index
	
	# Return to patrol route
	if patrol_points.size() > 0:
		patrol_target = patrol_points[current_patrol_index]
	
	print("[PatrolGuard] Lost target, returning to patrol route")

func _on_death() -> void:
	"""Override death for guard-specific effects"""
	print("[PatrolGuard] Guard defeated!")
	
	super._on_death()
# Projectile.gd
# Base projectile class for spells and enemy attacks
# Handles movement, collision detection, and damage application
#
# Public API:
# - initialize(direction: Vector2, speed: float, damage: int, range: float) -> void
# - set_owner_entity(entity: Entity) -> void
#
# Signals:
# - hit_target(target: Entity, projectile: Projectile)
# - projectile_destroyed(projectile: Projectile)

extends Entity
class_name Projectile

signal hit_target(target: Entity, projectile: Projectile)
signal projectile_destroyed(projectile: Projectile)

# Projectile properties
var damage: int = 10
var projectile_speed: float = 400.0
var max_range: float = 500.0
var piercing: int = 0  # How many enemies it can pierce through
var pierced_count: int = 0

# Movement
var direction: Vector2 = Vector2.RIGHT
var distance_traveled: float = 0.0
var start_position: Vector2

# Owner tracking
var owner_entity: Entity = null
var friendly_to_player: bool = true

# Visual effects
var trail_enabled: bool = false
var explosion_on_hit: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var area_detector: Area2D = $AreaDetector

func _ready() -> void:
	super._ready()
	
	# Set entity type
	entity_type = "projectile"
	
	# Store starting position
	start_position = global_position
	
	# Setup projectile-specific properties
	_setup_projectile_components()
	
	# Connect area detector
	if area_detector:
		area_detector.body_entered.connect(_on_body_entered)
		area_detector.area_entered.connect(_on_area_entered)

func _setup_collision_layers() -> void:
	"""Setup collision layers for projectile"""
	collision_layer = 8  # Projectiles layer
	if friendly_to_player:
		collision_mask = 2 | 4  # Enemies and walls
	else:
		collision_mask = 1 | 4  # Player and walls

func _setup_projectile_components() -> void:
	"""Setup projectile-specific components"""
	# Create sprite if not exists
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	
	# Create collision shape if not exists
	if not entity_collision_shape:
		entity_collision_shape = CollisionShape2D.new()
		entity_collision_shape.name = "CollisionShape2D"
		var shape = CircleShape2D.new()
		shape.radius = 8.0
		entity_collision_shape.shape = shape
		add_child(entity_collision_shape)
	
	# Create area detector if not exists
	if not area_detector:
		area_detector = Area2D.new()
		area_detector.name = "AreaDetector"
		
		var area_shape = CollisionShape2D.new()
		area_shape.name = "AreaShape"
		var shape = CircleShape2D.new()
		shape.radius = 10.0
		area_shape.shape = shape
		area_detector.add_child(area_shape)
		
		add_child(area_detector)
		
		# Set area detector collision layers
		if friendly_to_player:
			area_detector.collision_mask = 2  # Only detect enemies
		else:
			area_detector.collision_mask = 1  # Only detect player

func _physics_process(delta: float) -> void:
	# Move projectile
	velocity = direction * projectile_speed
	
	# Track distance
	var movement_distance = velocity.length() * delta
	distance_traveled += movement_distance
	
	# Check range
	if distance_traveled >= max_range:
		_destroy_projectile("range_exceeded")
		return
	
	# Apply movement
	move_and_slide()
	
	# Check for collision with walls
	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		if collision.get_collider().collision_layer & 4:  # Wall layer
			_destroy_projectile("wall_hit")
			return

func initialize(init_direction: Vector2, speed: float, init_damage: int, range: float) -> void:
	"""Initialize projectile with parameters"""
	direction = init_direction.normalized()
	projectile_speed = speed
	damage = init_damage
	max_range = range
	
	# Rotate sprite to face direction
	if sprite:
		sprite.rotation = direction.angle()
	
	print("[Projectile] Initialized projectile with damage: ", damage, ", speed: ", speed)

func set_owner_entity(entity: Entity) -> void:
	"""Set the entity that owns this projectile"""
	owner_entity = entity
	
	# Determine if friendly to player
	if entity and entity.entity_type == "player":
		friendly_to_player = true
	else:
		friendly_to_player = false
	
	# Update collision layers
	_setup_collision_layers()

func _on_body_entered(body: Node2D) -> void:
	"""Handle collision with entities"""
	if body == owner_entity:
		return  # Don't hit the owner
	
	if body is Entity:
		var target = body as Entity
		
		# Check if we should hit this target
		if _should_hit_target(target):
			_hit_target(target)

func _on_area_entered(area: Area2D) -> void:
	"""Handle collision with area detectors"""
	var parent = area.get_parent()
	if parent and parent is Entity and parent != owner_entity:
		var target = parent as Entity
		
		if _should_hit_target(target):
			_hit_target(target)

func _should_hit_target(target: Entity) -> bool:
	"""Check if projectile should hit the target"""
	if not target.is_alive:
		return false
	
	# Check friendly fire rules
	if friendly_to_player:
		# Player projectiles hit enemies
		return target.entity_type == "enemy"
	else:
		# Enemy projectiles hit player
		return target.entity_type == "player"

func _hit_target(target: Entity) -> void:
	"""Handle hitting a target"""
	print("[Projectile] Hit target: ", target.name)
	
	# Apply damage
	target.take_damage(damage, owner_entity)
	
	# Emit signal
	hit_target.emit(target, self)
	
	# Handle piercing
	if piercing > 0 and pierced_count < piercing:
		pierced_count += 1
		print("[Projectile] Pierced through target (", pierced_count, "/", piercing, ")")
		return
	
	# Destroy projectile if no piercing left
	_destroy_projectile("target_hit")

func _destroy_projectile(reason: String) -> void:
	"""Destroy the projectile"""
	print("[Projectile] Projectile destroyed: ", reason)
	
	# Create explosion effect if enabled
	if explosion_on_hit:
		_create_explosion_effect()
	
	# Emit signal
	projectile_destroyed.emit(self)
	
	# Remove from scene
	queue_free()

func _create_explosion_effect() -> void:
	"""Create explosion visual effect"""
	# TODO: Implement explosion particles
	print("[Projectile] Explosion effect at: ", global_position)

# Projectile type configurations
func configure_fireball() -> void:
	"""Configure as fireball projectile"""
	damage = 15
	projectile_speed = 350.0
	max_range = 400.0
	explosion_on_hit = true
	
	# TODO: Set fireball sprite and particles

func configure_ice_shard() -> void:
	"""Configure as ice shard projectile"""
	damage = 12
	projectile_speed = 450.0
	max_range = 350.0
	piercing = 1  # Can pierce through one enemy
	
	# TODO: Set ice shard sprite

func configure_lightning_bolt() -> void:
	"""Configure as lightning bolt projectile"""
	damage = 20
	projectile_speed = 600.0
	max_range = 300.0
	
	# TODO: Set lightning sprite and effects

func configure_shadow_blast() -> void:
	"""Configure as shadow blast projectile"""
	damage = 18
	projectile_speed = 300.0
	max_range = 250.0
	
	# TODO: Set shadow sprite

# Utility functions
func get_remaining_range() -> float:
	"""Get remaining range before projectile expires"""
	return max_range - distance_traveled

func get_range_percentage() -> float:
	"""Get range completion as percentage (0.0 to 1.0)"""
	if max_range <= 0:
		return 1.0
	return distance_traveled / max_range
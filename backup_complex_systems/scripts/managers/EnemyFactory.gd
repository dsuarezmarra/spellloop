# EnemyFactory.gd
# Factory class for creating and managing different enemy types
# Handles enemy spawning, positioning, and configuration

extends Node
class_name EnemyFactoryManager

enum EnemyType {
	BASIC_SLIME,
	SENTINEL_ORB,
	PATROL_GUARD
}

# Enemy type configurations
var enemy_configs = {
	EnemyType.BASIC_SLIME: {
		"scene_path": "res://scenes/entities/BasicSlime.tscn",
		"script": BasicSlime,
		"spawn_weight": 3,  # Higher = more common
		"min_level": 1,
		"preferred_group_size": 2
	},
	EnemyType.SENTINEL_ORB: {
		"scene_path": "res://scenes/entities/SentinelOrb.tscn", 
		"script": SentinelOrb,
		"spawn_weight": 2,
		"min_level": 1,
		"preferred_group_size": 1
	},
	EnemyType.PATROL_GUARD: {
		"scene_path": "res://scenes/entities/PatrolGuard.tscn",
		"script": PatrolGuard,
		"spawn_weight": 1,
		"min_level": 2,
		"preferred_group_size": 1
	}
}

# Spawn management
var active_enemies: Array[Enemy] = []
var max_enemies_per_room: int = 8
var spawn_attempts_max: int = 50

signal enemy_spawned(enemy: Enemy)
signal enemy_defeated(enemy: Enemy)
signal all_enemies_defeated()

func _ready() -> void:
	print("[EnemyFactory] Enemy Factory initialized")

func create_enemy(enemy_type: EnemyType, spawn_position: Vector2 = Vector2.ZERO, parent: Node = null) -> Enemy:
	"""Create a specific enemy type at given position"""
	if not enemy_configs.has(enemy_type):
		print("[EnemyFactory] ERROR: Unknown enemy type: ", enemy_type)
		return null
	
	var config = enemy_configs[enemy_type]
	var enemy: Enemy = null
	
	# Try to load from scene first, fallback to script instantiation
	if ResourceLoader.exists(config.scene_path):
		var enemy_scene = load(config.scene_path)
		enemy = enemy_scene.instantiate()
	else:
		# Create enemy from script (for testing/development)
		enemy = config.script.new()
		_setup_enemy_node(enemy)
	
	if not enemy:
		print("[EnemyFactory] ERROR: Failed to create enemy of type: ", enemy_type)
		return null
	
	# Configure enemy
	enemy.global_position = spawn_position
	enemy.add_to_group("enemies")
	
	# Connect signals
	enemy.enemy_died.connect(_on_enemy_died)
	
	# Add to scene
	var target_parent = parent if parent else get_tree().current_scene
	target_parent.add_child(enemy)
	
	# Track enemy
	active_enemies.append(enemy)
	enemy_spawned.emit(enemy)
	
	print("[EnemyFactory] Created ", enemy.get_class(), " at ", spawn_position)
	return enemy

func _setup_enemy_node(enemy: Enemy) -> void:
	"""Setup basic enemy node structure for script-created enemies"""
	if not enemy:
		return
	
	# Add sprite
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	enemy.add_child(sprite)
	
	# Add collision shape
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape = CircleShape2D.new()
	shape.radius = 12.0
	collision.shape = shape
	enemy.add_child(collision)
	
	# Add detection area
	var detection_area = Area2D.new()
	detection_area.name = "DetectionArea"
	var detection_collision = CollisionShape2D.new()
	detection_collision.name = "CollisionShape2D"
	var detection_shape = CircleShape2D.new()
	detection_shape.radius = 100.0
	detection_collision.shape = detection_shape
	detection_area.add_child(detection_collision)
	enemy.add_child(detection_area)
	
	# Add attack area
	var attack_area = Area2D.new()
	attack_area.name = "AttackArea"
	var attack_collision = CollisionShape2D.new()
	attack_collision.name = "CollisionShape2D"
	var attack_shape = CircleShape2D.new()
	attack_shape.radius = 40.0
	attack_collision.shape = attack_shape
	attack_area.add_child(attack_collision)
	enemy.add_child(attack_area)

func spawn_random_enemy(spawn_position: Vector2, current_level: int = 1, parent: Node = null) -> Enemy:
	"""Spawn a random enemy appropriate for the current level"""
	var available_types = _get_available_enemy_types(current_level)
	
	if available_types.is_empty():
		print("[EnemyFactory] No enemies available for level ", current_level)
		return null
	
	var chosen_type = _select_weighted_random(available_types)
	return create_enemy(chosen_type, spawn_position, parent)

func spawn_enemy_group(center_position: Vector2, current_level: int = 1, parent: Node = null) -> Array[Enemy]:
	"""Spawn a group of enemies around a center position"""
	var spawned_enemies: Array[Enemy] = []
	
	# Select enemy type for the group
	var available_types = _get_available_enemy_types(current_level)
	if available_types.is_empty():
		return spawned_enemies
	
	var enemy_type = _select_weighted_random(available_types)
	var config = enemy_configs[enemy_type]
	var group_size = config.preferred_group_size
	
	# Add some randomness to group size
	group_size += randi_range(-1, 2)
	group_size = max(1, group_size)
	
	# Spawn enemies in formation
	for i in range(group_size):
		var spawn_pos = _get_formation_position(center_position, i, group_size)
		var enemy = create_enemy(enemy_type, spawn_pos, parent)
		if enemy:
			spawned_enemies.append(enemy)
	
	print("[EnemyFactory] Spawned enemy group of ", group_size, " at ", center_position)
	return spawned_enemies

func _get_available_enemy_types(current_level: int) -> Array[EnemyType]:
	"""Get enemy types available for the current level"""
	var available: Array[EnemyType] = []
	
	for enemy_type in enemy_configs:
		var config = enemy_configs[enemy_type]
		if current_level >= config.min_level:
			available.append(enemy_type)
	
	return available

func _select_weighted_random(available_types: Array[EnemyType]) -> EnemyType:
	"""Select a random enemy type based on spawn weights"""
	var total_weight = 0
	for enemy_type in available_types:
		total_weight += enemy_configs[enemy_type].spawn_weight
	
	var random_value = randf() * total_weight
	var current_weight = 0
	
	for enemy_type in available_types:
		current_weight += enemy_configs[enemy_type].spawn_weight
		if random_value <= current_weight:
			return enemy_type
	
	# Fallback to first available
	return available_types[0]

func _get_formation_position(center: Vector2, index: int, total: int) -> Vector2:
	"""Get spawn position for enemy in formation"""
	if total == 1:
		return center
	
	# Arrange in circle formation
	var angle = (2.0 * PI * index) / total
	var radius = 50.0 + (total * 10.0)  # Larger radius for bigger groups
	
	return center + Vector2(cos(angle), sin(angle)) * radius

func clear_all_enemies() -> void:
	"""Remove all active enemies"""
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	
	active_enemies.clear()
	print("[EnemyFactory] All enemies cleared")

func get_enemy_count() -> int:
	"""Get current number of active enemies"""
	# Clean up invalid references
	active_enemies = active_enemies.filter(func(enemy): return is_instance_valid(enemy))
	return active_enemies.size()

func _on_enemy_died(enemy: Enemy) -> void:
	"""Handle enemy death"""
	active_enemies.erase(enemy)
	enemy_defeated.emit(enemy)
	
	print("[EnemyFactory] Enemy defeated. Remaining: ", get_enemy_count())
	
	# Check if all enemies defeated
	if get_enemy_count() == 0:
		all_enemies_defeated.emit()
		print("[EnemyFactory] All enemies defeated!")
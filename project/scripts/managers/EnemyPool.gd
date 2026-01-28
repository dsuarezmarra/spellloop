extends Node
# EnemyPool.gd
# Manages a pool of reusable EnemyBase instances to avoid instantiation spikes.

var _pool: Array[CharacterBody2D] = []
var _active_count: int = 0
const MAX_POOL_SIZE: int = 400
const GROW_AMOUNT: int = 20

var EnemyBaseScript: Script = preload("res://scripts/enemies/EnemyBase.gd")

func _ready() -> void:
	add_to_group("enemy_pool")

func get_enemy() -> CharacterBody2D:
	var enemy: CharacterBody2D
	
	if _pool.is_empty():
		return _create_new_enemy()
	
	enemy = _pool.pop_back()
	
	# Validation
	if not is_instance_valid(enemy):
		return _create_new_enemy()
		
	_active_count += 1
	return enemy

func return_enemy(enemy: CharacterBody2D) -> void:
	if not is_instance_valid(enemy):
		return
		
	# Reset minimal state to ensure it's "dead" in the pool
	_reset_enemy_state(enemy)
	
	if _pool.size() < MAX_POOL_SIZE:
		_pool.append(enemy)
	else:
		enemy.queue_free()
		
	_active_count = maxi(0, _active_count - 1)

func _create_new_enemy() -> CharacterBody2D:
	var enemy = CharacterBody2D.new()
	enemy.set_script(EnemyBaseScript)
	enemy.set_meta("pooled", true)
	_active_count += 1
	return enemy

func _reset_enemy_state(enemy: CharacterBody2D) -> void:
	# Hide and disable processing
	enemy.visible = false
	enemy.process_mode = Node.PROCESS_MODE_DISABLED
	enemy.set_physics_process(false)
	enemy.set_process(false)
	
	# Reset standard node stuff
	enemy.global_position = Vector2(-9999, -9999)
	enemy.skew = 0
	enemy.rotation = 0
	enemy.modulate = Color.WHITE
	
	# Remove from tree? 
	# Strategy: Keep in tree but disabled (fastest) OR remove/add (cleaner).
	# Removing from tree calls _exit_tree signals which might trigger logic.
	# Better to keep in a "PoolContainer" node?
	# For now, EnemyManager removes it from active list. 
	# We should remove it from the parent to avoid physics/draw overhead if we can't fully disable.
	
	if enemy.get_parent():
		enemy.get_parent().remove_child(enemy)

	# Clean signals
	# Note: EnemyBase needs to reconnect signals in initialize()
	# We assume initialize() does this.

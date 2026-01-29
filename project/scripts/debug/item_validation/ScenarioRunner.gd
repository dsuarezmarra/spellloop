extends Node
class_name ScenarioRunner

var current_env_instance: Node

func setup_environment() -> Node:
	# Clean previous - use call_deferred to avoid physics callback errors
	if is_instance_valid(current_env_instance):
		current_env_instance.call_deferred("queue_free")
		await get_tree().process_frame
		await get_tree().process_frame
	
	# Clear projectile pool before new environment
	if ProjectilePool and ProjectilePool.instance:
		ProjectilePool.instance.clear_pool()
	
	# Instantiate TestEnv
	var scene = load("res://scripts/debug/item_validation/TestEnv.tscn")
	if not scene:
		push_error("[ScenarioRunner] Failed to load TestEnv.tscn")
		return null
		
	current_env_instance = scene.instantiate()
	add_child(current_env_instance)
	
	# Wait for nodes to be ready
	await get_tree().process_frame
	
	return current_env_instance

func teardown_environment():
	# 1. Reset AttackManager Logic
	if is_instance_valid(current_env_instance):
		var am = current_env_instance.get_node_or_null("AttackManager")
		if am and am.has_method("reset_for_new_game"):
			am.reset_for_new_game()
	
	# 2. Clear Projectile Pool (Globals)
	if ProjectilePool and ProjectilePool.instance:
		ProjectilePool.instance.clear_pool()
		# Wait for deferred frees to process
		await get_tree().process_frame
		# Re-prewarm to prevent startup lag on next test
		ProjectilePool.instance._prewarm_pool(20)
		
	# 3. Destroy Environment - use call_deferred to avoid physics callback errors
	if is_instance_valid(current_env_instance):
		current_env_instance.call_deferred("queue_free")
		current_env_instance = null
		
	# 4. Wait for memory release
	await get_tree().process_frame
	await get_tree().process_frame

func spawn_dummy_enemy(position: Vector2) -> Node:
	var dummy_scene = load("res://scripts/debug/item_validation/DummyEnemy.tscn")
	var dummy = dummy_scene.instantiate()
	dummy.position = position
	if current_env_instance:
		current_env_instance.get_node("Enemies").add_child(dummy)
	return dummy

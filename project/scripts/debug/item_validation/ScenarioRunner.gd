extends Node
class_name ScenarioRunner

# Uses callback to return results
var _callback: Callable
var _current_test_case: Dictionary

# References
# We might need to spawn a temporary scene here
var test_env_scene = preload("res://scripts/debug/item_validation/TestEnv.tscn")
var current_env_instance: Node

func run_scenario(test_case: Dictionary, callback: Callable):
	_current_test_case = test_case
	_callback = callback
	
	# 1. Setup Environment
	# We can execute this deferred to ensure clean state
	_setup_environment.call_deferred()

func _setup_environment():
	# Clean up previous if any (shouldn't happen if we wait, but safety first)
	if is_instance_valid(current_env_instance):
		current_env_instance.queue_free()
		await get_tree().process_frame
	
	if test_env_scene:
		current_env_instance = test_env_scene.instantiate()
		add_child(current_env_instance)
	else:
		# Fallback if no scene, just use self as root mock
		current_env_instance = Node.new()
		add_child(current_env_instance)
	
	# 2. Run Test Logic
	_execute_test_logic()

func _execute_test_logic():
	# TODO: Implement actual numeric/mechanic oracle logic here
	# For Phase 1, we just mock the result
	
	var item = _current_test_case["item"]
	var item_id = item["id"]
	var result = {
		"item_id": item_id,
		"success": true,
		"details": "Mock test passed for %s" % item_id,
		"metrics": {
			"dps_before": 100,
			"dps_after": 110
		}
	}
	
	# Simulate some work
	await get_tree().create_timer(0.1).timeout
	
	# 3. Teardown
	_teardown(result)

func _teardown(result: Dictionary):
	if is_instance_valid(current_env_instance):
		current_env_instance.queue_free()
	
	_callback.call(result)

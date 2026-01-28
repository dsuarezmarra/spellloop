extends Node
class_name ScenarioRunner

var current_env_instance: Node

func setup_environment() -> Node:
	# Clean previous
	if is_instance_valid(current_env_instance):
		current_env_instance.queue_free()
	
	# Instantiate TestEnv
	var scene = load("res://scripts/debug/item_validation/TestEnv.tscn")
	current_env_instance = scene.instantiate()
	add_child(current_env_instance)
	
	return current_env_instance

func teardown_environment():
	if is_instance_valid(current_env_instance):
		current_env_instance.queue_free()

# Helper to run mechanical simulation
func run_simulation(duration: float, callback: Callable):
	# Wait for duration then callback
	await get_tree().create_timer(duration).timeout
	callback.call()

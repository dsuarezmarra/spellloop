# Main.gd - Main entry point for Isaac-style Funko Pop sprite test
extends Node

func _ready():
	print("=== ISAAC-STYLE FUNKO POP SPRITES ===")
	print("Starting sprite test with Isaac proportions...")
	
	# Load test scene
	var test_scene_script = load("res://scripts/test/TestIsaacStyleScene.gd")
	var test_scene = Node2D.new()
	test_scene.set_script(test_scene_script)
	
	get_tree().current_scene.queue_free()
	get_tree().current_scene = test_scene
	get_tree().root.add_child(test_scene)
	
	print("Test scene loaded. Use WASD to move, Shift to dash, arrows to shoot!")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		print("Exiting application...")
		get_tree().quit()
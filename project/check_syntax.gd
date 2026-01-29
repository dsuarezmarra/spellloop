@tool
extends SceneTree

func _init():
	print("Checking ItemTestRunner syntax...")
	var script = load("res://scripts/debug/item_validation/ItemTestRunner.gd")
	if script:
		print("Loaded script successfully.")
		var runner = script.new()
		if runner:
			print("Instantiated runner successfully.")
		else:
			print("Failed to instantiate runner.")
	else:
		print("Failed to load script.")
	quit()

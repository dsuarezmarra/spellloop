extends SceneTree

func _init():
	print("[RunPilot] Initializing...")
	var test_runner_scene = load("res://scripts/debug/item_validation/TestRunner.tscn")
	if not test_runner_scene:
		print("Error: Could not load TestRunner.tscn")
		quit(1)
		return
		
	var test_runner = test_runner_scene.instantiate()
	root.add_child(test_runner)
	
	# Find ItemTestRunner script node if it's not the root
	var runner_node = test_runner
	if not runner_node.has_method("run_sanity_check"):
		# Try detecting child
		var children = runner_node.get_children()
		for c in children:
			if c.has_method("run_sanity_check"):
				runner_node = c
				break
	
	if runner_node.has_method("run_sanity_check"):
		# Connect to completion signal if possible
		if runner_node.has_signal("all_tests_completed"):
			runner_node.all_tests_completed.connect(_on_completed)
		
		# RUN IT
		runner_node.run_sanity_check()
	else:
		print("Error: Could not find run_sanity_check method on TestRunner")
		quit(1)

func _on_completed(report_path):
	print("[RunPilot] All tests completed. Report: ", report_path)
	quit(0)

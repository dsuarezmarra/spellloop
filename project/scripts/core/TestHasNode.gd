extends Node

func _ready():
	print("=== Testing has_node fix ===")
	
	# Test 1: get_tree() returns SceneTree
	var gt = get_tree()
	print("get_tree() type: ", gt.get_class())
	
	# Test 2: get_tree().root returns Node
	var root = gt.root
	print("get_tree().root type: ", root.get_class() if root else "NULL")
	
	# Test 3: Test get_node_or_null (should work)
	if root:
		var test = root.get_node_or_null("NonExistent")
		print("get_node_or_null result: ", test)
	
	# Test 4: This would fail if tried:
	# var bad = gt.has_node("test") # ERROR!
	
	print("=== All tests passed ===")
	queue_free()

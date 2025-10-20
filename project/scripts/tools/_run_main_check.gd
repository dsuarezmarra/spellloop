extends SceneTree

func _enter_tree():
	print("RUN_MAIN_CHECK: attempt to load SpellloopMain.tscn")
	var path = "res://scenes/SpellloopMain.tscn"
	if not ResourceLoader.exists(path):
		print("RUN_MAIN_CHECK: MAIN SCENE NOT FOUND: ", path)
		quit()
	var res = ResourceLoader.load(path)
	if not res or not res is PackedScene:
		print("RUN_MAIN_CHECK: Failed to load main scene as PackedScene: ", res)
		quit()
	var inst = null
	var ok = true
	# Try to instantiate and add to tree (avoid try/except: GDScript doesn't support it)
	if res and res is PackedScene:
		inst = res.instantiate()
		if not inst:
			print("RUN_MAIN_CHECK: instantiate returned null for main scene")
			ok = false
	else:
		print("RUN_MAIN_CHECK: resource was not a PackedScene: ", res)
		ok = false
	if inst:
		# Attempt to add to current scene root (self refers to SceneTree)
		var root = self.current_scene
		if root:
			root.add_child(inst)
		else:
			# Add to the scene root
			var scene_root = self.root
			if scene_root:
				scene_root.add_child(inst)
		print("RUN_MAIN_CHECK: main scene instantiated and added")
	# print node count for sanity
	if inst:
		print("RUN_MAIN_CHECK: Node count: ", inst.get_child_count())
	# Done - call quit on the SceneTree
	self.quit()


extends SceneTree

# MINIMAL REPRO: SimpleProjectile instantiation in headless
# Goal: Identify EXACT crash point with numbered checkpoints

func _init():
	print("=== REPRO START ===")
	print("[1] Script initialized")
	
	# Checkpoint 2: Load script
	print("[2] Attempting to load SimpleProjectile.gd...")
	var ProjectileScript = load("res://scripts/entities/weapons/projectiles/SimpleProjectile.gd")
	if not ProjectileScript:
		print("[2] FAIL - Could not load script")
		quit(1)
		return
	print("[2] OK - Script loaded")
	
	# Checkpoint 3: Instantiate
	print("[3] Attempting to instantiate...")
	var projectile = ProjectileScript.new()
	if not projectile:
		print("[3] FAIL - Instantiation returned null")
		quit(1)
		return
	print("[3] OK - Instantiation succeeded")
	
	# Checkpoint 4: Add to tree
	print("[4] Creating root node...")
	var root_node = Node2D.new()
	root.add_child(root_node)
	print("[4] OK - Root node created")
	
	print("[5] Adding projectile to tree...")
	root_node.add_child(projectile)
	print("[5] OK - Projectile added to tree")
	
	# Checkpoint 6: Process frames
	print("[6] Processing frames...")
	for i in range(3):
		await process_frame
		print("[6] Frame %d processed" % i)
	print("[6] OK - All frames processed")
	
	# Checkpoint 7: Cleanup
	print("[7] Cleaning up...")
	projectile.queue_free()
	root_node.queue_free()
	await process_frame
	print("[7] OK - Cleanup complete")
	
	print("=== REPRO SUCCESS ===")
	quit(0)

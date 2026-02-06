extends SceneTree

func _init():
	var file = FileAccess.open("res://debug_log.txt", FileAccess.WRITE)
	file.store_string("DEBUG: Starting DebugRunner\n")
	
	print("Attempting to load Audit Runner...")
	file.store_string("DEBUG: Attempting load\n")
	var script = load("res://scripts/tests/runners/DamageDeliveryAuditRunner.gd")
	
	if script:
		file.store_string("DEBUG: Load Success\n")
		var instance = script.new()
		file.store_string("DEBUG: Instance Success\n")
		instance.queue_free()
	else:
		file.store_string("DEBUG: Load FAILED\n")
		
	file.close()
	quit()

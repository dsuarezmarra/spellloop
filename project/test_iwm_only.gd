extends SceneTree

func _init():
	print("=== TESTING InfiniteWorldManager COMPILATION ===")
	
	var iwm_script = load("res://scripts/core/InfiniteWorldManager.gd")
	if iwm_script:
		print("✅ InfiniteWorldManager script loads successfully")
		
		var iwm_instance = iwm_script.new()
		if iwm_instance:
			print("✅ InfiniteWorldManager instantiates successfully")
			iwm_instance.free()
		else:
			print("❌ InfiniteWorldManager instantiation failed")
	else:
		print("❌ InfiniteWorldManager script failed to load")
	
	quit()
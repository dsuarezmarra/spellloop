extends Node

func _ready():
	print("🧪 Testing InfiniteWorldManager properties...")
	
	# Test basic loading
	var iwm_script = preload("res://scripts/core/InfiniteWorldManager.gd")
	if iwm_script:
		print("✅ InfiniteWorldManager script loaded")
		
		# Create instance and test properties
		var iwm = iwm_script.new()
		if iwm:
			print("✅ InfiniteWorldManager instance created")
			
			# Test chunk properties access
			print("  📐 chunk_width: " + str(iwm.chunk_width))
			print("  📐 chunk_height: " + str(iwm.chunk_height))
			print("  📐 base_region_size: " + str(iwm.base_region_size))
			
			# Test method existence
			if iwm.has_method("get_chunk_at_pos"):
				print("✅ get_chunk_at_pos method exists")
			else:
				print("❌ get_chunk_at_pos method missing")
			
			print("✅ All properties accessible")
		else:
			print("❌ Failed to create InfiniteWorldManager instance")
	else:
		print("❌ Failed to load InfiniteWorldManager script")
	
	print("🏁 Test completed")
	get_tree().quit()
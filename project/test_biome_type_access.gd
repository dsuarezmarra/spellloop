extends Node

func _ready():
	print("🧪 Testing biome_type access...")
	
	# Test OrganicRegion creation and access
	var osg = preload("res://scripts/core/OrganicShapeGenerator.gd").new()
	add_child(osg)
	osg.initialize(12345)
	
	# Create a test organic region
	var region_id = Vector2i(0, 0)
	var organic_region = await osg.generate_region_async(region_id)
	
	if organic_region:
		print("✅ OrganicRegion created successfully")
		print("  - biome_id: ", organic_region.biome_id)
		print("  - region_id: ", organic_region.region_id)
		print("  - center_position: ", organic_region.center_position)
		
		# Test BiomeGenerator with corrected access
		var bg = preload("res://scripts/core/BiomeGenerator.gd").new()
		add_child(bg)
		bg.world_seed = 12345
		
		# This should not cause biome_type access error now
		var region_data = await bg.generate_region_async(organic_region)
		
		if region_data:
			print("✅ BiomeGenerator.generate_region_async successful!")
			print("  - biome_type: ", region_data.get("biome_type"))
			print("  - biome_name: ", region_data.get("biome_name"))
		else:
			print("❌ BiomeGenerator failed")
	else:
		print("❌ OrganicRegion creation failed")
	
	print("🏁 Test completed")
	get_tree().quit()
extends Node

func _ready():
	print("🧪 Testing generate_region_async call...")
	
	# Test OrganicShapeGenerator
	var osg = preload("res://scripts/core/OrganicShapeGenerator.gd").new()
	add_child(osg)
	
	# Initialize it first
	osg.initialize(12345)
	
	# Test the correct call with only region_id
	var region_id = Vector2i(0, 0)
	
	print("Calling generate_region_async with region_id: ", region_id)
	
	# This should not cause an error now
	var organic_region = await osg.generate_region_async(region_id)
	
	if organic_region:
		print("✅ generate_region_async call successful!")
		print("  Region has ", organic_region.boundary_points.size(), " boundary points")
	else:
		print("❌ generate_region_async returned null")
	
	print("🏁 Test completed")
	get_tree().quit()
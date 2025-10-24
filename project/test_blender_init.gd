extends Node

func _ready():
	print("🧪 Testing OrganicTextureBlender initialization...")

	# Test OrganicTextureBlenderSystem creation and initialization
	var otb = preload("res://scripts/core/OrganicTextureBlender.gd").new()
	add_child(otb)

	print("Before initialize - is_initialized:", otb.is_initialized)

	# Initialize with seed
	otb.initialize(12345)

	print("After initialize - is_initialized:", otb.is_initialized)
	print("World seed:", otb.world_seed)

	# Test method availability
	print("Has apply_blend_to_region method:", otb.has_method("apply_blend_to_region"))

	if otb.is_initialized:
		print("✅ OrganicTextureBlender initialization SUCCESSFUL")
	else:
		print("❌ OrganicTextureBlender initialization FAILED")

	print("🏁 Test completed")
	get_tree().quit()
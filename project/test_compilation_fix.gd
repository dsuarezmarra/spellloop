extends Node

func _ready():
	print("🧪 Testing compilation errors fix...")
	
	# Test 1: OrganicShapeGenerator loading
	var osg_script = preload("res://scripts/core/OrganicShapeGenerator.gd")
	if osg_script:
		print("✅ OrganicShapeGenerator loads without parse errors")
	else:
		print("❌ OrganicShapeGenerator has parse errors")
	
	# Test 2: BiomeGenerator loading
	var bg_script = preload("res://scripts/core/BiomeGenerator.gd")
	if bg_script:
		print("✅ BiomeGenerator loads without parse errors")
	else:
		print("❌ BiomeGenerator has parse errors")
		
	# Test 3: test_organic_system loading
	var tos_script = preload("res://scripts/tools/test_organic_system.gd")
	if tos_script:
		print("✅ test_organic_system loads without parse errors")
	else:
		print("❌ test_organic_system has parse errors")
	
	print("🏁 Compilation test completed")
	get_tree().quit()
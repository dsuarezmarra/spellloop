extends SceneTree

func _init():
	print("=== TESTING ORGANIC SYSTEM COMPILATION ===")
	
	# Test 1: Check if classes can be loaded
	var tests_passed = 0
	var tests_total = 0
	
	# Test OrganicShapeGenerator
	tests_total += 1
	var osg_script = load("res://scripts/core/OrganicShapeGenerator.gd")
	if osg_script:
		print("✅ OrganicShapeGenerator loads")
		tests_passed += 1
	else:
		print("❌ OrganicShapeGenerator failed to load")
	
	# Test InfiniteWorldManager
	tests_total += 1
	var iwm_script = load("res://scripts/core/InfiniteWorldManager.gd")
	if iwm_script:
		print("✅ InfiniteWorldManager loads")
		tests_passed += 1
	else:
		print("❌ InfiniteWorldManager failed to load")
	
	# Test BiomeRegionApplier
	tests_total += 1
	var bra_script = load("res://scripts/core/BiomeRegionApplier.gd")
	if bra_script:
		print("✅ BiomeRegionApplier loads")
		tests_passed += 1
	else:
		print("❌ BiomeRegionApplier failed to load")
	
	# Test OrganicTextureBlender
	tests_total += 1
	var otb_script = load("res://scripts/core/OrganicTextureBlender.gd")
	if otb_script:
		print("✅ OrganicTextureBlender loads")
		tests_passed += 1
	else:
		print("❌ OrganicTextureBlender failed to load")
	
	# Test instantiation
	tests_total += 1
	if osg_script and iwm_script:
		var osg_instance = osg_script.new()
		if osg_instance:
			print("✅ OrganicShapeGenerator can be instantiated")
			tests_passed += 1
			osg_instance.free()
		else:
			print("❌ OrganicShapeGenerator instantiation failed")
	else:
		print("❌ Cannot test instantiation - scripts missing")
	
	print("=== COMPILATION TEST RESULTS ===")
	print("Tests passed: %d/%d" % [tests_passed, tests_total])
	
	if tests_passed == tests_total:
		print("🎉 ALL TESTS PASSED - System ready!")
	else:
		print("🚨 SOME TESTS FAILED - Check errors above")
	
	quit()
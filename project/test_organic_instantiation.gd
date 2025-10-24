# test_organic_instantiation.gd
# Test rápido para verificar instanciación de componentes

extends Node

func _ready():
	print("🧪 TESTING ORGANIC SYSTEM INSTANTIATION")
	print("="*50)
	
	test_organic_shape_generator()
	test_biome_generator()
	test_biome_region_applier()
	test_organic_texture_blender()
	test_infinite_world_manager()
	
	print("="*50)
	print("✅ INSTANTIATION TESTS COMPLETED")
	
	# Salir después de 2 segundos
	get_tree().create_timer(2.0).timeout.connect(_exit_test)

func test_organic_shape_generator():
	print("\n🌊 Testing OrganicShapeGenerator...")
	
	var osg = OrganicShapeGenerator.new()
	if osg:
		print("  ✅ OrganicShapeGenerator instantiated")
		add_child(osg)
		osg.initialize(12345)
		print("  ✅ OrganicShapeGenerator initialized")
	else:
		print("  ❌ Failed to instantiate OrganicShapeGenerator")

func test_biome_generator():
	print("\n🌿 Testing BiomeGenerator...")
	
	var bg = BiomeGenerator.new()
	if bg:
		print("  ✅ BiomeGenerator instantiated")
		add_child(bg)
		print("  ✅ BiomeGenerator added to scene")
	else:
		print("  ❌ Failed to instantiate BiomeGenerator")

func test_biome_region_applier():
	print("\n🎨 Testing BiomeRegionApplier...")
	
	var bra = BiomeRegionApplier.new()
	if bra:
		print("  ✅ BiomeRegionApplier instantiated")
		add_child(bra)
		print("  ✅ BiomeRegionApplier added to scene")
	else:
		print("  ❌ Failed to instantiate BiomeRegionApplier")

func test_organic_texture_blender():
	print("\n🌈 Testing OrganicTextureBlender...")
	
	var otb = OrganicTextureBlender.new()
	if otb:
		print("  ✅ OrganicTextureBlender instantiated")
		add_child(otb)
		print("  ✅ OrganicTextureBlender added to scene")
	else:
		print("  ❌ Failed to instantiate OrganicTextureBlender")

func test_infinite_world_manager():
	print("\n🌍 Testing InfiniteWorldManager...")
	
	var iwm = InfiniteWorldManager.new()
	if iwm:
		print("  ✅ InfiniteWorldManager instantiated")
		add_child(iwm)
		print("  ✅ InfiniteWorldManager added to scene")
	else:
		print("  ❌ Failed to instantiate InfiniteWorldManager")

func _exit_test():
	print("\n🚪 Exiting test...")
	get_tree().quit()
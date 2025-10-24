# log_test.gd
# Test que escribe resultados a un archivo

extends Node

var log_file: FileAccess

func _ready():
	# Abrir archivo de log
	log_file = FileAccess.open("user://organic_system_test_log.txt", FileAccess.WRITE)
	
	log("🧪 TESTING ORGANIC SYSTEM INSTANTIATION")
	log("="*50)
	
	test_organic_shape_generator()
	test_biome_generator()
	test_biome_region_applier()
	test_organic_texture_blender()
	test_infinite_world_manager()
	
	log("="*50)
	log("✅ INSTANTIATION TESTS COMPLETED")
	
	# Cerrar archivo y salir
	if log_file:
		log_file.close()
	
	print("Test completed. Check user://organic_system_test_log.txt")
	get_tree().create_timer(1.0).timeout.connect(_exit_test)

func log(message: String):
	print(message)
	if log_file:
		log_file.store_line(message)
		log_file.flush()

func test_organic_shape_generator():
	log("\n🌊 Testing OrganicShapeGenerator...")
	
	if not ResourceLoader.exists("res://scripts/core/OrganicShapeGenerator.gd"):
		log("  ❌ OrganicShapeGenerator.gd file not found")
		return
	
	var osg_script = load("res://scripts/core/OrganicShapeGenerator.gd")
	if not osg_script:
		log("  ❌ Failed to load OrganicShapeGenerator script")
		return
	
	var osg = osg_script.new()
	if osg:
		log("  ✅ OrganicShapeGenerator instantiated")
		add_child(osg)
		
		if osg.has_method("initialize"):
			osg.initialize(12345)
			log("  ✅ OrganicShapeGenerator initialized")
		else:
			log("  ⚠️ initialize method not found")
	else:
		log("  ❌ Failed to instantiate OrganicShapeGenerator")

func test_biome_generator():
	log("\n🌿 Testing BiomeGenerator...")
	
	if not ResourceLoader.exists("res://scripts/core/BiomeGenerator.gd"):
		log("  ❌ BiomeGenerator.gd file not found")
		return
	
	var bg_script = load("res://scripts/core/BiomeGenerator.gd")
	if not bg_script:
		log("  ❌ Failed to load BiomeGenerator script")
		return
	
	var bg = bg_script.new()
	if bg:
		log("  ✅ BiomeGenerator instantiated")
		add_child(bg)
		log("  ✅ BiomeGenerator added to scene")
	else:
		log("  ❌ Failed to instantiate BiomeGenerator")

func test_biome_region_applier():
	log("\n🎨 Testing BiomeRegionApplier...")
	
	if not ResourceLoader.exists("res://scripts/core/BiomeRegionApplier.gd"):
		log("  ❌ BiomeRegionApplier.gd file not found")
		return
	
	var bra_script = load("res://scripts/core/BiomeRegionApplier.gd")
	if not bra_script:
		log("  ❌ Failed to load BiomeRegionApplier script")
		return
	
	var bra = bra_script.new()
	if bra:
		log("  ✅ BiomeRegionApplier instantiated")
		add_child(bra)
		log("  ✅ BiomeRegionApplier added to scene")
	else:
		log("  ❌ Failed to instantiate BiomeRegionApplier")

func test_organic_texture_blender():
	log("\n🌈 Testing OrganicTextureBlender...")
	
	if not ResourceLoader.exists("res://scripts/core/OrganicTextureBlender.gd"):
		log("  ❌ OrganicTextureBlender.gd file not found")
		return
	
	var otb_script = load("res://scripts/core/OrganicTextureBlender.gd")
	if not otb_script:
		log("  ❌ Failed to load OrganicTextureBlender script")
		return
	
	var otb = otb_script.new()
	if otb:
		log("  ✅ OrganicTextureBlender instantiated")
		add_child(otb)
		log("  ✅ OrganicTextureBlender added to scene")
	else:
		log("  ❌ Failed to instantiate OrganicTextureBlender")

func test_infinite_world_manager():
	log("\n🌍 Testing InfiniteWorldManager...")
	
	if not ResourceLoader.exists("res://scripts/core/InfiniteWorldManager.gd"):
		log("  ❌ InfiniteWorldManager.gd file not found")
		return
	
	var iwm_script = load("res://scripts/core/InfiniteWorldManager.gd")
	if not iwm_script:
		log("  ❌ Failed to load InfiniteWorldManager script")
		return
	
	var iwm = iwm_script.new()
	if iwm:
		log("  ✅ InfiniteWorldManager instantiated")
		add_child(iwm)
		log("  ✅ InfiniteWorldManager added to scene")
		
		# Verificar propiedades importantes
		if "active_regions" in iwm:
			log("  ✅ active_regions property found")
		else:
			log("  ⚠️ active_regions property not found")
	else:
		log("  ❌ Failed to instantiate InfiniteWorldManager")

func _exit_test():
	log("\n🚪 Exiting test...")
	get_tree().quit()
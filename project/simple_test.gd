# simple_test.gd
# Test básico para verificar que los componentes orgánicos se cargan correctamente

extends SceneTree

func _init():
	print("="*60)
	print("🧪 EJECUTANDO PRUEBAS BÁSICAS DEL SISTEMA ORGÁNICO")
	print("="*60)
	
	# Test 1: Verificar que las clases existen
	print("\n🔍 Test 1: Verificar clases del sistema orgánico...")
	test_class_definitions()
	
	# Test 2: Instanciar componentes básicos
	print("\n🏗️ Test 2: Instanciar componentes...")
	test_basic_instantiation()
	
	# Test 3: Verificar conexiones entre componentes
	print("\n🔗 Test 3: Verificar integraciones...")
	test_component_integration()
	
	print("\n" + "="*60)
	print("✅ PRUEBAS COMPLETADAS")
	print("="*60)
	
	# Salir del motor
	quit(0)

func test_class_definitions():
	"""Verificar que todas las clases del sistema orgánico estén definidas"""
	var classes_to_test = [
		{"name": "OrganicShapeGenerator", "path": "res://scripts/core/OrganicShapeGenerator.gd"},
		{"name": "BiomeGenerator", "path": "res://scripts/core/BiomeGenerator.gd"},
		{"name": "BiomeRegionApplier", "path": "res://scripts/core/BiomeRegionApplier.gd"},
		{"name": "OrganicTextureBlender", "path": "res://scripts/core/OrganicTextureBlender.gd"},
		{"name": "InfiniteWorldManager", "path": "res://scripts/core/InfiniteWorldManager.gd"}
	]
	
	for class_info in classes_to_test:
		if ResourceLoader.exists(class_info.path):
			var script_resource = load(class_info.path)
			if script_resource:
				print("  ✅ %s - Clase cargada correctamente" % class_info.name)
			else:
				print("  ❌ %s - Error cargando script" % class_info.name)
		else:
			print("  ❌ %s - Archivo no encontrado: %s" % [class_info.name, class_info.path])

func test_basic_instantiation():
	"""Probar instanciación básica de componentes"""
	
	# Test OrganicShapeGenerator
	print("  🌊 Probando OrganicShapeGenerator...")
	if ResourceLoader.exists("res://scripts/core/OrganicShapeGenerator.gd"):
		var osg_script = load("res://scripts/core/OrganicShapeGenerator.gd")
		if osg_script:
			var osg = osg_script.new()
			if osg:
				print("    ✅ OrganicShapeGenerator instanciado")
				osg.initialize(12345)  # Test seed
				print("    ✅ OrganicShapeGenerator inicializado")
			else:
				print("    ❌ Error instanciando OrganicShapeGenerator")
	
	# Test BiomeGenerator
	print("  🌿 Probando BiomeGenerator...")
	if ResourceLoader.exists("res://scripts/core/BiomeGenerator.gd"):
		var bg_script = load("res://scripts/core/BiomeGenerator.gd")
		if bg_script:
			var bg = bg_script.new()
			if bg:
				print("    ✅ BiomeGenerator instanciado")
			else:
				print("    ❌ Error instanciando BiomeGenerator")
	
	# Test BiomeRegionApplier
	print("  🎨 Probando BiomeRegionApplier...")
	if ResourceLoader.exists("res://scripts/core/BiomeRegionApplier.gd"):
		var bra_script = load("res://scripts/core/BiomeRegionApplier.gd")
		if bra_script:
			var bra = bra_script.new()
			if bra:
				print("    ✅ BiomeRegionApplier instanciado")
			else:
				print("    ❌ Error instanciando BiomeRegionApplier")
	
	# Test OrganicTextureBlender
	print("  🌈 Probando OrganicTextureBlender...")
	if ResourceLoader.exists("res://scripts/core/OrganicTextureBlender.gd"):
		var otb_script = load("res://scripts/core/OrganicTextureBlender.gd")
		if otb_script:
			var otb = otb_script.new()
			if otb:
				print("    ✅ OrganicTextureBlender instanciado")
			else:
				print("    ❌ Error instanciando OrganicTextureBlender")

func test_component_integration():
	"""Probar que los componentes pueden trabajar juntos"""
	
	print("  🔄 Probando integración InfiniteWorldManager...")
	if ResourceLoader.exists("res://scripts/core/InfiniteWorldManager.gd"):
		var iwm_script = load("res://scripts/core/InfiniteWorldManager.gd")
		if iwm_script:
			var iwm = iwm_script.new()
			if iwm:
				print("    ✅ InfiniteWorldManager instanciado")
				
				# Verificar que tenga las propiedades esperadas
				if "active_regions" in iwm:
					print("    ✅ active_regions encontrado")
				else:
					print("    ❌ active_regions no encontrado")
				
				if "organic_shape_generator" in iwm:
					print("    ✅ organic_shape_generator encontrado")
				else:
					print("    ❌ organic_shape_generator no encontrado")
			else:
				print("    ❌ Error instanciando InfiniteWorldManager")
	
	print("  📊 Verificando enums de BiomeGenerator...")
	if ResourceLoader.exists("res://scripts/core/BiomeGenerator.gd"):
		var bg_script = load("res://scripts/core/BiomeGenerator.gd")
		if bg_script and bg_script.has_script_signal("BiomeType"):
			print("    ✅ BiomeType enum encontrado")
		
		# Verificar constantes esperadas
		var bg = bg_script.new()
		if "BIOME_COLORS" in bg:
			print("    ✅ BIOME_COLORS encontrado")
		if "BIOME_NAMES" in bg:
			print("    ✅ BIOME_NAMES encontrado")
		if "ORGANIC_DECORATIONS" in bg:
			print("    ✅ ORGANIC_DECORATIONS encontrado")

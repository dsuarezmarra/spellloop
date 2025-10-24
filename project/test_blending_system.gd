extends Node

# Script de prueba para verificar el sistema de blending avanzado
# Archivo: test_blending_system.gd

func _ready():
	print("=== INICIANDO PRUEBAS DEL SISTEMA DE BLENDING AVANZADO ===")
	
	# Verificar que el shader existe y es válido
	test_shader_availability()
	
	# Verificar OrganicTextureBlender
	test_texture_blender()
	
	# Verificar integración completa
	test_integration_system()
	
	# Crear escena de prueba visual
	await create_visual_test()
	
	print("=== PRUEBAS COMPLETADAS ===")
	
	# Mantener la escena abierta para captura
	await get_tree().create_timer(5.0).timeout
	get_tree().quit()

func test_shader_availability():
	print("\n🔍 PRUEBA 1: Disponibilidad del Shader")
	
	var shader_path = "res://scripts/core/shaders/biome_blend.gdshader"
	
	if ResourceLoader.exists(shader_path):
		print("✅ Shader encontrado: %s" % shader_path)
		
		# Intentar cargar el shader
		var shader = load(shader_path)
		if shader is Shader:
			print("✅ Shader cargado correctamente")
			print("   - Tipo: %s" % shader.get_mode())
		else:
			print("❌ Error cargando shader")
	else:
		print("❌ Shader no encontrado en: %s" % shader_path)

func test_texture_blender():
	print("\n🔍 PRUEBA 2: OrganicTextureBlender")
	
	# Crear instancia de OrganicTextureBlender
	var blender = preload("res://scripts/core/OrganicTextureBlender.gd").new()
	
	if blender:
		print("✅ OrganicTextureBlender instanciado")
		
		# Probar inicialización
		blender.initialize(12345)
		
		if blender.is_initialized:
			print("✅ TextureBlender inicializado correctamente")
			
			# Probar configuración
			blender.configure_noise(0.02, 0.08)
			blender.set_blend_zone_width(64.0)
			
			# Obtener estadísticas
			var stats = blender.get_performance_stats()
			print("📊 Estadísticas iniciales:")
			for key in stats:
				print("   - %s: %s" % [key, stats[key]])
				
		else:
			print("❌ Error inicializando TextureBlender")
	else:
		print("❌ No se pudo instanciar OrganicTextureBlender")

func test_integration_system():
	print("\n🔍 PRUEBA 3: Sistema de Integración")
	
	# Crear instancia de integración
	var integration = preload("res://scripts/core/OrganicBlendingIntegration.gd").new()
	add_child(integration)
	
	if integration:
		print("✅ OrganicBlendingIntegration instanciado")
		
		# Esperar inicialización
		await get_tree().create_timer(0.5).timeout
		
		var status = integration.get_integration_status()
		print("📊 Estado de integración:")
		for key in status:
			print("   - %s: %s" % [key, status[key]])
	else:
		print("❌ No se pudo instanciar OrganicBlendingIntegration")

func create_visual_test():
	print("\n🔍 PRUEBA 4: Creación de Test Visual")
	
	# Crear escena de prueba
	var test_scene = Node2D.new()
	test_scene.name = "BlendingTestScene"
	add_child(test_scene)
	
	# Crear dos regiones de biomas diferentes para probar blending
	var region1 = create_test_region("grassland", Vector2(-200, 0), Color.GREEN)
	var region2 = create_test_region("desert", Vector2(200, 0), Color.SANDY_BROWN)
	
	test_scene.add_child(region1)
	test_scene.add_child(region2)
	
	print("✅ Regiones de prueba creadas")
	
	# Crear material de blending de prueba
	await test_blend_material(region1, region2)

func create_test_region(biome_id: String, position: Vector2, color: Color) -> Node2D:
	var region = Node2D.new()
	region.name = "TestRegion_" + biome_id
	region.position = position
	
	# Crear sprite visual
	var sprite = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(200, 200, false, Image.FORMAT_RGBA8)
	image.fill(color)
	texture.set_image(image)
	sprite.texture = texture
	
	region.add_child(sprite)
	
	# Añadir metadatos simulados
	var organic_region = {
		"region_id": biome_id + "_test",
		"biome_id": biome_id,
		"center_position": position,
		"boundary_points": [
			position + Vector2(-100, -100),
			position + Vector2(100, -100), 
			position + Vector2(100, 100),
			position + Vector2(-100, 100)
		],
		"neighbor_regions": []
	}
	
	region.set_meta("organic_region", organic_region)
	
	return region

func test_blend_material(region1: Node2D, region2: Node2D):
	print("\n🔍 PRUEBA 5: Creación de Material de Blending")
	
	# Crear TextureBlender
	var blender = preload("res://scripts/core/OrganicTextureBlender.gd").new()
	add_child(blender)
	blender.initialize(12345)
	
	await get_tree().create_timer(0.2).timeout
	
	if blender.is_initialized:
		# Crear datos de prueba para blending
		var blend_data = {
			"region": region1.get_meta("organic_region"),
			"biome_id": "grassland",
			"position": region1.position,
			"neighbors": [
				{
					"biome_id": "desert",
					"position": region2.position,
					"boundary": region2.get_meta("organic_region").boundary_points
				}
			]
		}
		
		# Intentar aplicar blending
		var material = blender.apply_blend_to_region(blend_data)
		
		if material:
			print("✅ Material de blending creado exitosamente")
			print("   - Tipo de material: %s" % material.get_class())
			
			# Aplicar material a región
			var sprite1 = region1.get_child(0) as Sprite2D
			if sprite1:
				sprite1.material = material
				print("✅ Material aplicado a región")
		else:
			print("❌ No se pudo crear material de blending")
	else:
		print("❌ TextureBlender no inicializado")

func _process(_delta):
	# Actualizar tiempo en shaders si existen
	var regions = get_tree().get_nodes_in_group("test_regions")
	for region in regions:
		if region.has_method("get_child"):
			var sprite = region.get_child(0)
			if sprite and sprite.material and sprite.material is ShaderMaterial:
				sprite.material.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)
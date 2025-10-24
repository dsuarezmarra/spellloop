extends SceneTree

func _init():
	print("=== PRUEBA DE BLENDING VISUAL ===")
	
	# Crear escena de prueba
	var scene = Node2D.new()
	current_scene = scene
	
	# Probar OrganicTextureBlender simplificado
	test_blender()
	
	# Crear demo visual
	create_visual_demo(scene)
	
	print("✅ Prueba completada - ejecutando por 3 segundos...")
	
	# Crear timer para cerrar automáticamente
	var timer = Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(func(): quit())
	scene.add_child(timer)
	timer.start()

func test_blender():
	var blender_script = load("res://scripts/core/OrganicTextureBlenderSimple.gd")
	if blender_script:
		print("✅ Script simplificado encontrado")
		
		var blender = blender_script.new()
		if blender:
			print("✅ Blender instanciado")
			blender.initialize(12345)
			
			if blender.is_initialized:
				print("✅ Blender inicializado")
				
				# Probar crear material
				var test_data = {"biome": "grassland"}
				var material = blender.apply_blend_to_region(test_data)
				
				if material:
					print("✅ Material de blending creado")
				else:
					print("❌ Error creando material")
			else:
				print("❌ Error inicializando blender")
		else:
			print("❌ Error instanciando blender")
	else:
		print("❌ Script no encontrado")

func create_visual_demo(scene: Node2D):
	print("Creando demo visual...")
	
	# Crear TextureBlender
	var blender_script = load("res://scripts/core/OrganicTextureBlenderSimple.gd")
	var blender = blender_script.new()
	scene.add_child(blender)
	blender.initialize(12345)
	
	# Crear sprite de prueba
	var sprite = Sprite2D.new()
	var texture = create_test_texture()
	sprite.texture = texture
	sprite.position = Vector2(400, 300)
	sprite.scale = Vector2(3, 3)
	scene.add_child(sprite)
	
	# Aplicar material de blending si está disponible
	if blender.is_initialized:
		var material = blender.apply_blend_to_region({"biome": "test"})
		if material:
			sprite.material = material
			print("✅ Material aplicado al sprite")

func create_test_texture() -> ImageTexture:
	var image = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	
	# Crear patrón de gradiente
	for y in range(128):
		for x in range(128):
			var r = float(x) / 128.0
			var g = float(y) / 128.0
			var b = 0.5
			image.set_pixel(x, y, Color(r, g, b, 1.0))
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture
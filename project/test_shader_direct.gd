# Prueba simple directa del shader
extends SceneTree

func _init():
	print("=== PRUEBA DIRECTA DE SHADER ===")
	
	# Crear escena
	var scene = preload("res://BlendingTest.tscn").instantiate()
	current_scene = scene
	
	# Probar shader directamente
	test_shader_direct()
	
	print("✅ Prueba iniciada - presiona ESC para salir")

func test_shader_direct():
	var shader = load("res://scripts/core/shaders/biome_blend.gdshader")
	if shader:
		print("✅ Shader cargado exitosamente")
		
		# Crear material
		var material = ShaderMaterial.new()
		material.shader = shader
		
		# Crear texturas de prueba
		var tex_green = create_solid_texture(Color.GREEN)
		var tex_brown = create_solid_texture(Color.SANDY_BROWN)
		
		# Configurar uniforms
		material.set_shader_parameter("biome_a_base", tex_green)
		material.set_shader_parameter("biome_a_decor", tex_green) 
		material.set_shader_parameter("biome_b_base", tex_brown)
		material.set_shader_parameter("biome_b_decor", tex_brown)
		material.set_shader_parameter("blend_strength", 0.6)
		material.set_shader_parameter("noise_scale", 1.5)
		material.set_shader_parameter("flow_speed", 0.4)
		material.set_shader_parameter("micro_oscillation", 0.03)
		
		print("✅ Material configurado")
		
		# Aplicar a sprite en la escena
		apply_to_scene(material)
	else:
		print("❌ Error cargando shader")

func create_solid_texture(color: Color) -> ImageTexture:
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func apply_to_scene(material: ShaderMaterial):
	# Buscar sprite en la escena
	var sprite_found = false
	
	# Crear sprite si no existe
	if not sprite_found:
		var sprite = Sprite2D.new()
		var texture = create_gradient_texture()
		sprite.texture = texture
		sprite.material = material
		sprite.position = Vector2(400, 300)
		sprite.scale = Vector2(4, 4)
		
		current_scene.add_child(sprite)
		print("✅ Sprite creado con material de shader")

func create_gradient_texture() -> ImageTexture:
	var image = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	
	for y in range(128):
		for x in range(128):
			var factor = float(x) / 128.0
			var color = Color.GREEN.lerp(Color.SANDY_BROWN, factor)
			image.set_pixel(x, y, color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func _process(_delta):
	# Actualizar tiempo en shader
	var sprites = current_scene.get_children().filter(func(n): return n is Sprite2D)
	for sprite in sprites:
		if sprite.material and sprite.material is ShaderMaterial:
			sprite.material.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)
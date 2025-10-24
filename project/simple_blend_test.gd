extends Node2D

# Prueba simple del sistema de blending
func _ready():
	print("=== PRUEBA SIMPLE DE BLENDING ===")
	
	# 1. Verificar que el shader existe
	var shader_path = "res://scripts/core/shaders/biome_blend.gdshader"
	if ResourceLoader.exists(shader_path):
		print("✅ Shader encontrado")
		
		var shader = load(shader_path)
		if shader:
			print("✅ Shader cargado correctamente")
			
			# Crear material de prueba
			var material = ShaderMaterial.new()
			material.shader = shader
			
			# Crear textura de prueba
			var test_texture = create_test_texture(Color.GREEN)
			
			# Configurar parámetros del shader
			material.set_shader_parameter("biome_a_base", test_texture)
			material.set_shader_parameter("biome_a_decor", test_texture)
			material.set_shader_parameter("biome_b_base", create_test_texture(Color.BROWN))
			material.set_shader_parameter("biome_b_decor", create_test_texture(Color.BROWN))
			material.set_shader_parameter("blend_strength", 0.5)
			material.set_shader_parameter("noise_scale", 1.0)
			
			print("✅ Material configurado")
			
			# Crear sprite para mostrar el resultado
			var sprite = Sprite2D.new()
			sprite.texture = test_texture
			sprite.material = material
			add_child(sprite)
			
			print("✅ Escena de prueba creada")
		else:
			print("❌ Error cargando shader")
	else:
		print("❌ Shader no encontrado")
	
	# 2. Probar OrganicTextureBlender
	test_texture_blender()

func create_test_texture(color: Color) -> ImageTexture:
	var image = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	image.fill(color)
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func test_texture_blender():
	print("\n=== PRUEBA DE TEXTURE BLENDER ===")
	
	# Verificar que la clase existe
	var blender_script = load("res://scripts/core/OrganicTextureBlender.gd")
	if blender_script:
		print("✅ Script de OrganicTextureBlender encontrado")
		
		var blender = blender_script.new()
		if blender:
			print("✅ OrganicTextureBlender instanciado")
			
			# Probar inicialización
			if blender.has_method("initialize"):
				blender.initialize(12345)
				print("✅ Método initialize ejecutado")
			else:
				print("❌ Método initialize no encontrado")
		else:
			print("❌ Error instanciando OrganicTextureBlender")
	else:
		print("❌ Script de OrganicTextureBlender no encontrado")

func _process(delta):
	# Actualizar tiempo en material
	var sprite = get_child(0) if get_child_count() > 0 else null
	if sprite and sprite.material:
		sprite.material.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)
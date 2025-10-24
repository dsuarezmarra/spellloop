extends SceneTree

func _init():
	print("=== VERIFICACION RAPIDA DEL SISTEMA ===")
	
	# 1. Verificar shader
	test_shader()
	
	# 2. Verificar scripts
	test_scripts()
	
	quit()

func test_shader():
	var shader_path = "res://scripts/core/shaders/biome_blend.gdshader"
	print("Verificando shader: %s" % shader_path)
	
	if ResourceLoader.exists(shader_path):
		print("✅ Archivo existe")
		var shader = load(shader_path)
		if shader:
			print("✅ Shader cargado: %s" % shader.get_class())
		else:
			print("❌ Error cargando shader")
	else:
		print("❌ Archivo no existe")

func test_scripts():
	var scripts = [
		"res://scripts/core/OrganicTextureBlender.gd",
		"res://scripts/core/OrganicBlendingIntegration.gd"
	]
	
	for script_path in scripts:
		print("Verificando script: %s" % script_path)
		if ResourceLoader.exists(script_path):
			print("✅ Archivo existe")
			var script = load(script_path)
			if script:
				print("✅ Script cargado: %s" % script.get_class())
			else:
				print("❌ Error cargando script")
		else:
			print("❌ Archivo no existe")
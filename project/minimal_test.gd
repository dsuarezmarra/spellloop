extends SceneTree

func _init():
	print("=== PRUEBA MINIMAL ===")
	
	# Solo verificar que el shader existe
	var shader_path = "res://scripts/core/shaders/biome_blend.gdshader"
	if ResourceLoader.exists(shader_path):
		print("✅ Shader existe")
		var shader = load(shader_path)
		if shader:
			print("✅ Shader OK")
		else:
			print("❌ Shader error")
	else:
		print("❌ Shader no existe")
	
	quit()
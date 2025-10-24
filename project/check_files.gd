extends Node

func _ready():
	print("=== VERIFICACION DE COMPILACION ===")
	
	# Verificar archivos del sistema de blending
	var files_to_check = [
		"res://scripts/core/shaders/biome_blend.gdshader",
		"res://scripts/core/OrganicTextureBlender.gd", 
		"res://scripts/core/OrganicBlendingIntegration.gd"
	]
	
	for file_path in files_to_check:
		if ResourceLoader.exists(file_path):
			print("✅ Encontrado: %s" % file_path)
		else:
			print("❌ No encontrado: %s" % file_path)
	
	# Intentar cargar shader
	var shader_path = "res://scripts/core/shaders/biome_blend.gdshader"
	if ResourceLoader.exists(shader_path):
		var shader = load(shader_path)
		if shader:
			print("✅ Shader cargado correctamente")
		else:
			print("❌ Error cargando shader")
	
	get_tree().quit()
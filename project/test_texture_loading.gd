extends Node

func _ready():
	print("TEXTURE TEST START")

	# Verificar texturas básicas
	var textures_to_check = [
		"res://assets/textures/biomes/Snow/base.png",
		"res://assets/textures/biomes/Lava/base.png"
	]

	for path in textures_to_check:
		if ResourceLoader.exists(path):
			print("OK: " + path)
		else:
			print("MISSING: " + path)

	# Verificar shader
	var shader_path = "res://scripts/core/shaders/biome_blend.gdshader"
	if ResourceLoader.exists(shader_path):
		print("SHADER OK")
	else:
		print("SHADER MISSING")

	print("TEST END")
	get_tree().quit()
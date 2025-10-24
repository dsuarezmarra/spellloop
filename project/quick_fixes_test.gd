extends Node

func _ready():
	print("=== PRUEBA RAPIDA DE CORRECCIONES ===")

	# 1. Verificar texturas
	print("1. TEXTURAS:")
	var texture_paths = [
		"res://assets/textures/biomes/Snow/base.png",
		"res://assets/textures/biomes/Lava/base.png",
		"res://assets/textures/biomes/Forest/base.png"
	]

	for path in texture_paths:
		if ResourceLoader.exists(path):
			print("  ✅ " + path)
		else:
			print("  ❌ " + path)

	# 2. Verificar OrganicTextureBlender
	print("2. ORGANIC TEXTURE BLENDER:")
	var otb_script = load("res://scripts/core/OrganicTextureBlender.gd")
	if otb_script:
		var otb = otb_script.new()
		otb.initialize(12345)

		if otb.is_initialized:
			print("  ✅ Inicializado correctamente")

			# Probar creación de material
			var test_data = {
				"biome_id": "snow",
				"neighbors": [{"biome_id": "lava"}],
				"position": Vector2.ZERO
			}
			var material = otb.apply_blend_to_region(test_data)
			if material:
				print("  ✅ Material de blending creado")
			else:
				print("  ❌ Fallo al crear material")
		else:
			print("  ❌ Falló la inicialización")
	else:
		print("  ❌ No se pudo cargar el script")

	# 3. Verificar InfiniteWorldManager
	print("3. INFINITE WORLD MANAGER:")
	var iwm_script = load("res://scripts/core/InfiniteWorldManager.gd")
	if iwm_script:
		var iwm = iwm_script.new()
		# Verificar que tenga chunks_root para compatibilidad
		if "chunks_root" in iwm:
			print("  ✅ Tiene campo chunks_root")
		else:
			print("  ❌ Falta campo chunks_root")

		# Verificar que tenga regions_root
		if "regions_root" in iwm:
			print("  ✅ Tiene campo regions_root")
		else:
			print("  ❌ Falta campo regions_root")
	else:
		print("  ❌ No se pudo cargar el script")

	print("=== FIN DE PRUEBA ===")
	get_tree().quit()
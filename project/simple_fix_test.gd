extends Node

func _ready():
	print("INICIO PRUEBA SIMPLE")

	# 1. Verificar textura básica
	if ResourceLoader.exists("res://assets/textures/biomes/Snow/base.png"):
		print("OK: Textura Snow existe")
	else:
		print("ERROR: Textura Snow no existe")

	# 2. Crear InfiniteWorldManager y verificar OrganicTextureBlender
	print("Cargando InfiniteWorldManager...")
	var iwm_script = load("res://scripts/core/InfiniteWorldManager.gd")
	if iwm_script:
		var iwm = iwm_script.new()
		add_child(iwm)

		# Esperar un frame para que se inicialice
		await get_tree().process_frame

		# Verificar OrganicTextureBlender
		if iwm.organic_texture_blender:
			print("OK: OrganicTextureBlender creado")
			if iwm.organic_texture_blender.is_initialized:
				print("OK: OrganicTextureBlender inicializado")
			else:
				print("ERROR: OrganicTextureBlender no inicializado")
		else:
			print("ERROR: OrganicTextureBlender no creado")

		# Verificar BiomeRegionApplier
		if iwm.biome_region_applier:
			print("OK: BiomeRegionApplier creado")
		else:
			print("ERROR: BiomeRegionApplier no creado")
	else:
		print("ERROR: No se pudo cargar InfiniteWorldManager")

	print("FIN PRUEBA SIMPLE")
	get_tree().quit()
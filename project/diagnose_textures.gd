extends Node

func _ready():
	print("=== DIAGNOSTICO DE TEXTURAS ===")
	
	# 1. Verificar que las texturas existen
	print("\n1. VERIFICANDO EXISTENCIA DE TEXTURAS:")
	var base_path = "res://assets/textures/biomes/"
	var biomes = ["Snow", "Lava", "Forest", "Grassland", "Desert", "ArcaneWastes"]
	
	for biome in biomes:
		var texture_path = base_path + biome + "/base.png"
		if ResourceLoader.exists(texture_path):
			print("  ✅ ", biome, ": ", texture_path)
		else:
			print("  ❌ ", biome, ": NO EXISTE - ", texture_path)
	
	# 2. Verificar BiomeRegionApplier
	print("\n2. VERIFICANDO BiomeRegionApplier:")
	var bra_path = "res://scripts/core/BiomeRegionApplier.gd"
	if ResourceLoader.exists(bra_path):
		var bra_script = load(bra_path)
		if bra_script:
			print("  ✅ Script cargado")
			var bra = bra_script.new()
			if bra:
				print("  ✅ Instancia creada")
				print("  - TEXTURE_BASE_PATH: ", bra.TEXTURE_BASE_PATH)
				print("  - DEFAULT_BIOME: ", bra.DEFAULT_BIOME)
				if bra.BIOME_TEXTURES.has("snow"):
					print("  - snow texture config: ", bra.BIOME_TEXTURES["snow"])
			else:
				print("  ❌ No se pudo instanciar")
		else:
			print("  ❌ No se pudo cargar el script")
	else:
		print("  ❌ Script no encontrado: ", bra_path)
	
	# 3. Verificar carga de textura
	print("\n3. CARGANDO TEXTURA DE PRUEBA:")
	var test_texture_path = base_path + "Snow/base.png"
	if ResourceLoader.exists(test_texture_path):
		var texture = load(test_texture_path)
		if texture:
			print("  ✅ Textura cargada: ", texture.get_size())
		else:
			print("  ❌ Error cargando textura")
	else:
		print("  ❌ Ruta no existe: ", test_texture_path)
	
	# 4. Verificar OrganicTextureBlender
	print("\n4. VERIFICANDO OrganicTextureBlender:")
	var otb_path = "res://scripts/core/OrganicTextureBlender.gd"
	if ResourceLoader.exists(otb_path):
		print("  ✅ Script encontrado")
	else:
		print("  ❌ Script no encontrado")
	
	# 5. Verificar shader
	print("\n5. VERIFICANDO SHADER:")
	var shader_path = "res://scripts/core/shaders/biome_blend.gdshader"
	if ResourceLoader.exists(shader_path):
		print("  ✅ Shader encontrado: ", shader_path)
	else:
		print("  ❌ Shader no encontrado: ", shader_path)
	
	print("\n=== FIN DIAGNOSTICO ===")
	await get_tree().process_frame
	get_tree().quit()

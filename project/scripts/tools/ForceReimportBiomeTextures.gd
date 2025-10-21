@tool
extends EditorScript

func _run():
	print("\n🔄 FORZANDO REIMPORTACIÓN DE TEXTURAS DE BIOMAS...")
	
	var biome_paths = [
		"res://assets/textures/biomes/Grassland/",
		"res://assets/textures/biomes/Desert/",
		"res://assets/textures/biomes/Snow/",
		"res://assets/textures/biomes/Lava/",
		"res://assets/textures/biomes/ArcaneWastes/",
		"res://assets/textures/biomes/Forest/",
	]
	
	var fs = EditorFileSystem.get_singleton()
	
	for path in biome_paths:
		print("  📁 Reimportando: %s" % path)
		fs.reimport_files([path])
	
	print("✓ Reimportación solicitada. Esperando a que se complete...")
	print("💡 Los cambios se aplicarán cuando el editor procese los assets.")

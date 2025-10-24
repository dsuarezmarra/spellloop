extends Node

func _ready():
	print("🔥 Verificación rápida de compilación")
	
	# Solo verificar que las clases carguen
	var scripts = [
		"res://scripts/core/OrganicTextureBlender.gd",
		"res://scripts/core/BiomeRegionApplier.gd",
		"res://scripts/core/InfiniteWorldManager.gd",
		"res://scripts/core/BiomeGenerator.gd"
	]
	
	for script_path in scripts:
		var script = load(script_path)
		if script:
			print("✅ " + script_path.get_file())
		else:
			print("❌ " + script_path.get_file())
	
	print("✅ Verificación completa")
	get_tree().quit()
extends Node
"""
🔧 DEBUG SCRIPT - Verificar que el sistema de biomas funciona correctamente
Reporta: JSON loading, bioma selection, texture paths, sprite creation
"""

func _ready() -> void:
	print("\n" + ("="*80))
	print("🔧 BIOME SYSTEM DEBUG - Iniciando verificaciones...")
	print("="*80)
	
	# Verificar que config existe
	var config_path = "res://assets/textures/biomes/biome_textures_config.json"
	print("\n[1] Verificando archivo de configuración:")
	print("    Path: %s" % config_path)
	print("    Existe: %s" % ResourceLoader.exists(config_path))
	
	if ResourceLoader.exists(config_path):
		# Cargar y parsear JSON
		var file = FileAccess.open(config_path, FileAccess.READ)
		var json_str = file.get_as_text()
		var json = JSON.new()
		var parse_ok = json.parse(json_str)
		
		print("    JSON parseado: %s" % (parse_ok == OK))
		
		if parse_ok == OK:
			var data = json.data
			var biomes = data.get("biomes", [])
			print("    Biomas encontrados: %d" % biomes.size())
			
			for i in range(biomes.size()):
				var biome = biomes[i]
				print("\n    [Bioma %d]" % i)
				print("      Nombre: %s" % biome.get("name", "?"))
				
				var textures = biome.get("textures", {})
				var base_rel = textures.get("base", "")
				var decor_rel = textures.get("decor", [])
				
				print("      Base (relativo): %s" % base_rel)
				
				if not base_rel.is_empty():
					var base_full = "res://assets/textures/biomes/" + base_rel
					print("      Base (completo): %s" % base_full)
					print("      Base existe: %s" % ResourceLoader.exists(base_full))
				
				print("      Decoraciones: %d" % decor_rel.size())
				for j in range(decor_rel.size()):
					var decor_full = "res://assets/textures/biomes/" + decor_rel[j]
					print("        [%d] %s → existe: %s" % [j, decor_full, ResourceLoader.exists(decor_full)])
	
	print("\n" + ("="*80))
	print("✅ DEBUG COMPLETADO")
	print("="*80 + "\n")
	
	# Auto-eliminar este script después de mostrar info
	await get_tree().process_frame
	queue_free()

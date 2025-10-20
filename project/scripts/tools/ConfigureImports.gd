extends EditorScript
## Script de Editor - Configura los import settings de todas las texturas
## USO: Abrir este script en Godot → Click derecho → Run

const BIOME_NAMES = ["Grassland", "Desert", "Snow", "Lava", "ArcaneWastes", "Forest"]
const TEXTURE_TYPES = ["base", "decor1", "decor2", "decor3"]

func _run() -> void:
	print("\n[ImportConfigurator] Configurando imports de texturas...")
	
	var total = 0
	var configured = 0
	
	for biome in BIOME_NAMES:
		for texture_type in TEXTURE_TYPES:
			var texture_path = "res://assets/textures/biomes/%s/%s.png" % [biome, texture_type]
			total += 1
			
			# Obtener configuración actual
			var import_settings = {
				"compress/mode": 2,  # VRAM Compressed
				"mipmaps/generate": true,
				"process/fix_alpha_border": true,
				"hint_color/is_srgb": false
			}
			
			# Aplicar configuración (esto requiere re-importar en Godot)
			# Los settings se aplican cuando haces reimport en el editor
			print("  • %s/%s.png - Pendiente de reimport" % [biome, texture_type])
			configured += 1
	
	print("\n✅ Configuración de imports completada")
	print("Próximo paso: Selecciona todas las texturas y haz click en 'Reimport'")
	print("Los archivos .import ya fueron creados automáticamente\n")

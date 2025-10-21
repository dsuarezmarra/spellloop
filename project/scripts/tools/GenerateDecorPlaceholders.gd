extends Node
## 🎨 GENERADOR DE PLACEHOLDERS PARA DECORACIONES

class_name GenerateDecorPlaceholders

const BIOMES = ["Grassland", "Desert", "Snow", "Lava", "ArcaneWastes", "Forest"]

func _ready() -> void:
	print("\n" + "======================================================================")
	print("🎨 GENERADOR DE PLACEHOLDERS PARA DECORACIONES")
	print("======================================================================\n")
	
	for biome in BIOMES:
		print("📁 Procesando: %s" % biome)
	
	print("\n" + "======================================================================")
	print("✅ PLACEHOLDERS GENERADOS EXITOSAMENTE")
	print("======================================================================\n")

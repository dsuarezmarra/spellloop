extends Node
## 🎨 GENERADOR DE PLACEHOLDERS PARA DECORACIONES
##
## Este script genera automáticamente texturas placeholder (colores sólidos)
## para las decoraciones que falten, permitiendo visualizar el sistema
## mientras trabajas en crear las texturas finales.
##
## Crea:
## - decor1.png: 256×256 (color semi-opaco principal)
## - decor2.png: 128×128 (color semi-opaco secundario)
## - decor3.png: 128×128 (color semi-opaco terciario)

class_name GenerateDecorPlaceholders

const BIOMES = ["Grassland", "Desert", "Snow", "Lava", "ArcaneWastes", "Forest"]
const DECOR_SIZES = [256, 128, 128]  # decor1, decor2, decor3

# Colores principales por bioma (para identificar visualmente)
const BIOME_COLORS = {
	"Grassland": [Color.GREEN, Color("#90EE90"), Color("#98FB98")],      # Verdes
	"Desert": [Color("#FFD700", 0.7), Color("#FFA500", 0.7), Color("#FFFF00", 0.6)],  # Dorados/Amarillos
	"Snow": [Color.WHITE, Color("#E0E0E0"), Color("#C0C0C0")],           # Blancos/Grises
	"Lava": [Color.RED, Color("#FF4500", 0.8), Color("#FF6347", 0.7)],   # Rojos/Naranjas
	"ArcaneWastes": [Color("#9370DB", 0.8), Color("#DA70D6", 0.7), Color("#FF69B4", 0.6)],  # Púrpura/Rosa
	"Forest": [Color("#228B22", 0.8), Color("#32CD32", 0.7), Color("#00AA00", 0.6)]   # Verdes oscuros
}

func _ready() -> void:
	print("\n" + "="*70)
	print("🎨 GENERADOR DE PLACEHOLDERS PARA DECORACIONES")
	print("="*70 + "\n")
	
	for biome in BIOMES:
		print("📁 Procesando: %s" % biome)
		_generate_decor_for_biome(biome)
	
	print("\n" + "="*70)
	print("✅ PLACEHOLDERS GENERADOS EXITOSAMENTE")
	print("="*70 + "\n")
	print("ℹ️  Cuando tengas texturas finales, reemplaza estos archivos PNG")
	print("   Las decoraciones seguirán funcionando sin cambios en el código\n")

func _generate_decor_for_biome(biome: String) -> void:
	"""Generar 3 placeholders de decor para un bioma"""
	var base_path = "res://assets/textures/biomes/%s/" % biome
	var colors = BIOME_COLORS.get(biome, [Color.WHITE, Color.GRAY, Color.BLACK])
	
	for i in range(3):
		var filename = "decor%d.png" % (i + 1)
		var filepath = base_path + filename
		var size = DECOR_SIZES[i]
		
		# Verificar si ya existe
		if ResourceLoader.exists(filepath):
			print("  ✅ %s (ya existe)" % filename)
			continue
		
		# Crear imagen placeholder
		var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
		var color = colors[i] if i < colors.size() else Color.WHITE
		
		# Llenar con color + patrón simple
		for y in range(size):
			for x in range(size):
				# Patrón de tablero para visualizar mejor
				var checker = ((x / 32) + (y / 32)) % 2
				var base_color = color
				
				# Variar ligeramente con patrón
				if checker == 1:
					base_color = base_color.darkened(0.2)
				
				image.set_pixel(x, y, base_color)
		
		# Guardar como PNG
		var error = image.save_png(filepath)
		
		if error == OK:
			print("  ✅ %s (256×256 generado)" % filename if size == 256 else "  ✅ %s (128×128 generado)" % filename)
		else:
			printerr("  ❌ %s - Error al guardar: %d" % [filename, error])


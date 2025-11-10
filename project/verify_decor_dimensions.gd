extends Node

# Script de diagnóstico para verificar dimensiones de decoraciones

func _ready():
	print("\n=== VERIFICACIÓN DE DIMENSIONES - DECORACIONES LAVA ===\n")
	
	var decor_files = [
		"res://assets/textures/biomes/Lava/decor/lava_decor1_sheet_f8_256.png",
		"res://assets/textures/biomes/Lava/decor/lava_decor2_sheet_f7_256.png",
		"res://assets/textures/biomes/Lava/decor/lava_decor3_sheet_f6_256.png",
		"res://assets/textures/biomes/Lava/decor/lava_decor4_sheet_f6_256.png",
		"res://assets/textures/biomes/Lava/decor/lava_decor5_sheet_f6_256.png",
		"res://assets/textures/biomes/Lava/decor/lava_decor6_sheet_f6_256.png"
	]
	
	for path in decor_files:
		verify_image(path)
	
	print("\n=== Verificación completada ===\n")
	get_tree().quit()

func verify_image(path: String):
	var filename = path.get_file()
	print("📄 Verificando: %s" % filename)
	
	# Extraer frames y tamaño del nombre
	var regex = RegEx.new()
	regex.compile("_sheet_f(\\d+)_(\\d+)\\.png$")
	var match = regex.search(filename)
	
	if not match:
		print("  ❌ Nombre no sigue la convención\n")
		return
	
	var expected_frames = int(match.get_string(1))
	var expected_frame_size = int(match.get_string(2))
	var expected_width = (expected_frame_size * expected_frames) + (4 * (expected_frames - 1))
	var expected_height = expected_frame_size
	
	print("  📐 Especificaciones del nombre:")
	print("    - Frames esperados: %d" % expected_frames)
	print("    - Tamaño por frame: %d×%d px" % [expected_frame_size, expected_frame_size])
	print("    - Dimensiones totales esperadas: %d×%d px" % [expected_width, expected_height])
	
	# Cargar textura y verificar dimensiones reales
	if not ResourceLoader.exists(path):
		print("  ❌ Archivo no encontrado\n")
		return
	
	var texture = load(path) as Texture2D
	if texture == null:
		print("  ❌ No se pudo cargar como Texture2D\n")
		return
	
	var actual_width = texture.get_width()
	var actual_height = texture.get_height()
	
	print("  📏 Dimensiones reales:")
	print("    - Ancho real: %d px" % actual_width)
	print("    - Alto real: %d px" % actual_height)
	
	# Verificar si coinciden
	var width_ok = abs(actual_width - expected_width) <= 4
	var height_ok = abs(actual_height - expected_height) <= 4
	
	if width_ok and height_ok:
		print("  ✅ CORRECTO - Dimensiones coinciden")
	else:
		print("  ⚠️ INCORRECTO - Dimensiones no coinciden")
		if not width_ok:
			print("    ❌ Ancho: esperado ~%d, real %d (diferencia: %d)" % [
				expected_width, actual_width, abs(actual_width - expected_width)
			])
		if not height_ok:
			print("    ❌ Alto: esperado ~%d, real %d (diferencia: %d)" % [
				expected_height, actual_height, abs(actual_height - expected_height)
			])
	
	print("")

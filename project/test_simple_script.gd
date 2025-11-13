extends SceneTree

func _init():
	print("SCRIPT DE PRUEBA INICIADO")
	print("Godot version: " + Engine.get_version_info().string)

	# Verificar acceso a archivos
	var test_path = "C:/Users/dsuarez1/Downloads/biomes/Grassland/decor/01.png"
	print("Verificando archivo: " + test_path)

	if FileAccess.file_exists(test_path):
		print("[OK] Archivo encontrado")

		var img = Image.load_from_file(test_path)
		if img:
			print("[OK] Imagen cargada: %dx%d" % [img.get_width(), img.get_height()])
		else:
			print("[ERROR] No se pudo cargar la imagen")
	else:
		print("[ERROR] Archivo no encontrado")

	print("SCRIPT FINALIZADO")
	quit(0)

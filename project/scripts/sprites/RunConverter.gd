# RunConverter.gd - Ejecuta la conversión directamente
extends RefCounted
class_name RunConverter

static func convert_sprites():
	"""Convierte los sprites JPEG del usuario a PNG directamente"""
	
	print("🔄 INICIANDO CONVERSIÓN DE SPRITES")
	print("==================================")
	
	var original_dir = "res://sprites/wizard/backup_original/"
	var target_dir = "res://sprites/wizard/"
	
	var files = ["wizard_down.png", "wizard_up.png", "wizard_left.png", "wizard_right.png"]
	var converted_count = 0
	
	for file_name in files:
		var original_path = original_dir + file_name
		var target_path = target_dir + file_name
		
		print("🔍 Procesando: ", file_name)
		
		# Verificar que el archivo original existe
		if not FileAccess.file_exists(original_path):
			print("  ❌ Archivo original no existe: ", original_path)
			continue
		
		# Leer el archivo original
		var file = FileAccess.open(original_path, FileAccess.READ)
		if not file:
			print("  ❌ No se puede abrir: ", original_path)
			continue
		
		var buffer = file.get_buffer(file.get_length())
		file.close()
		
		print("  📏 Tamaño del archivo: ", buffer.size(), " bytes")
		
		# Verificar header JPEG
		if buffer.size() > 4:
			var header = buffer.slice(0, 4)
			var is_jpeg = (header[0] == 0xFF and header[1] == 0xD8)
			
			print("  🔍 Header: ", header[0], " ", header[1], " ", header[2], " ", header[3])
			print("  📄 Tipo detectado: ", "JPEG" if is_jpeg else "Otro")
			
			if is_jpeg:
				print("  ✅ JPEG detectado, convirtiendo...")
				
				# Crear imagen desde JPEG
				var image = Image.new()
				var result = image.load_jpg_from_buffer(buffer)
				
				if result == OK:
					var width = image.get_width()
					var height = image.get_height()
					print("  ✅ Imagen JPEG cargada: ", width, "x", height)
					
					# Guardar como PNG
					var save_result = image.save_png(target_path)
					if save_result == OK:
						print("  ✅ Guardado como PNG: ", target_path)
						converted_count += 1
						
						# Verificar el PNG resultante
						var verify_file = FileAccess.open(target_path, FileAccess.READ)
						if verify_file:
							var png_buffer = verify_file.get_buffer(8)
							verify_file.close()
							
							# Verificar header PNG
							var expected_png = PackedByteArray([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
							if png_buffer == expected_png:
								print("  ✅ PNG válido confirmado!")
							else:
								print("  ⚠️ PNG header inesperado: ", png_buffer)
								
							# Verificar tamaño final
							var final_file = FileAccess.open(target_path, FileAccess.READ)
							if final_file:
								var final_size = final_file.get_length()
								final_file.close()
								print("  📏 Tamaño PNG final: ", final_size, " bytes")
					else:
						print("  ❌ Error guardando PNG: ", save_result)
				else:
					print("  ❌ Error cargando JPEG: ", result)
			else:
				print("  ⚠️ No es JPEG válido")
		else:
			print("  ❌ Archivo muy pequeño")
	
	print("🎉 CONVERSIÓN COMPLETADA")
	print("📊 Sprites convertidos: ", converted_count, "/", files.size())
	
	if converted_count == files.size():
		print("✅ ¡TODOS LOS SPRITES CONVERTIDOS EXITOSAMENTE!")
		print("🎮 Tus sprites del mago ya están listos como PNG")
	else:
		print("⚠️ Algunos sprites no se pudieron convertir")
	
	return converted_count
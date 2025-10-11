extends Node

# Script para eliminar fondo blanco en tiempo real dentro de Godot
class_name SmartBackgroundRemover

static func remove_background_smart(image: Image) -> Image:
	print("🎯 Eliminando fondo blanco inteligentemente...")
	
	var width = image.get_width()
	var height = image.get_height()
	
	# Crear copia de la imagen con formato RGBA
	var clean_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	for y in range(height):
		for x in range(width):
			var pixel = image.get_pixel(x, y)
			
			# Detectar si es fondo blanco
			var is_background = false
			
			# Criterio 1: Color muy blanco
			if pixel.r > 0.97 and pixel.g > 0.97 and pixel.b > 0.97:
				# Criterio 2: Distancia al borde
				var dist_to_edge = min(min(x, width - 1 - x), min(y, height - 1 - y))
				
				if dist_to_edge < 8:
					is_background = true
				elif dist_to_edge < 16:
					# Verificar homogeneidad en área 3x3
					var white_count = 0
					var total_count = 0
					
					for dy in range(-1, 2):
						for dx in range(-1, 2):
							var nx = x + dx
							var ny = y + dy
							if nx >= 0 and nx < width and ny >= 0 and ny < height:
								var neighbor = image.get_pixel(nx, ny)
								if neighbor.r > 0.95 and neighbor.g > 0.95 and neighbor.b > 0.95:
									white_count += 1
								total_count += 1
					
					if total_count > 0 and float(white_count) / float(total_count) > 0.8:
						is_background = true
			
			# Aplicar píxel
			if is_background:
				clean_image.set_pixel(x, y, Color.TRANSPARENT)
			else:
				clean_image.set_pixel(x, y, pixel)
	
	print("✅ Fondo blanco eliminado preservando detalles")
	return clean_image

static func process_wizard_sprites():
	print("🧙‍♂️ Procesando sprites wizard...")
	
	var sprite_names = ["wizard_down.png", "wizard_up.png", "wizard_left.png", "wizard_right.png"]
	
	for sprite_name in sprite_names:
		var path = "res://sprites/wizard/" + sprite_name
		
		if ResourceLoader.exists(path):
			var texture = load(path) as Texture2D
			if texture:
				var image = texture.get_image()
				var clean_image = remove_background_smart(image)
				
				# Guardar imagen limpia
				var save_path = "user://clean_" + sprite_name
				clean_image.save_png(save_path)
				print("💾 Guardado: ", save_path)
		else:
			print("❌ No encontrado: ", path)
	
	print("🎉 Procesamiento completo!")
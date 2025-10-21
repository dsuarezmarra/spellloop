@tool
extends EditorScript

"""
Script para regenerar las texturas de biomas como imágenes PNG válidas.
Ejecutar: Click derecho > Execute
"""

func _run():
	print("\n🎨 REGENERANDO TEXTURAS DE BIOMAS...")
	
	var biomes = {
		"Grassland": Color(0.49, 0.85, 0.34),  # Verde
		"Desert": Color(0.91, 0.76, 0.48),     # Naranja
		"Snow": Color(0.92, 0.96, 1.0),        # Blanco/Azul
		"Lava": Color(0.96, 0.35, 0.2),        # Rojo
		"ArcaneWastes": Color(0.71, 0.43, 0.86), # Púrpura
		"Forest": Color(0.19, 0.38, 0.19),     # Verde oscuro
	}
	
	for biome_name in biomes:
		var color = biomes[biome_name]
		var biome_path = "res://assets/textures/biomes/%s/" % biome_name
		
		# Crear imagen base
		var base_img = Image.create(1920, 1080, false, Image.FORMAT_RGB8)
		for x in range(1920):
			for y in range(1080):
				base_img.set_pixel(x, y, color)
		
		# Guardar
		var base_file = biome_path + "base.png"
		var error = base_img.save_png(base_file)
		if error == OK:
			print("  ✓ %s" % base_file)
		else:
			print("  ✗ Error guardando %s: %d" % [base_file, error])
		
		# Crear decoraciones simples (256x256)
		for i in range(1, 4):
			var decor_img = Image.create(256, 256, false, Image.FORMAT_RGBA8)
			var decor_color = color.darkened(0.2 + i * 0.1)
			for x in range(256):
				for y in range(256):
					if ((x + y) % (20 + i)) < 10:
						decor_img.set_pixel(x, y, decor_color)
					else:
						decor_img.set_pixel(x, y, Color.TRANSPARENT)
			
			var decor_file = biome_path + "decor%d.png" % i
			error = decor_img.save_png(decor_file)
			if error == OK:
				print("    ✓ decor%d.png" % i)
			else:
				print("    ✗ Error: %d" % error)
	
	print("\n✅ Regeneración completa")
	print("💡 Godot reimportará automáticamente los archivos")

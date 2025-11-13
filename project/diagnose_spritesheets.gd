extends SceneTree

# Script de diagnóstico para verificar cómo se están cargando los spritesheets

func _init():
	print("\n" + "="*70)
	print("DIAGNÓSTICO DE SPRITESHEETS - DESERT Y DEATH")
	print("="*70)

	# Rutas de los spritesheets
	var paths = {
		"Desert": "res://assets/textures/biomes/Desert/base/desert_base_animated_sheet_f8_512.png",
		"Death": "res://assets/textures/biomes/Death/base/death_base_animated_sheet_f8_512.png"
	}

	for biome_name in paths.keys():
		var path = paths[biome_name]

		print("\n--- %s ---" % biome_name)
		print("Ruta: %s" % path)

		# Verificar que existe
		if not FileAccess.file_exists(path):
			print("❌ ERROR: Archivo no existe")
			continue

		# Cargar textura directamente
		var tex: Texture2D = load(path)
		if tex == null:
			print("❌ ERROR: No se pudo cargar la textura")
			continue

		var w = tex.get_width()
		var h = tex.get_height()
		print("✅ Dimensiones de la textura: %dx%d px" % [w, h])

		# Calcular frames esperados
		var frame_size = 512
		var frames_count = 8
		var expected_no_padding = frame_size * frames_count  # 4096
		var expected_with_padding = (frame_size + 4) * frames_count - 4  # 4100

		print("   Esperado SIN padding: %d px" % expected_no_padding)
		print("   Esperado CON padding: %d px" % expected_with_padding)

		if w == expected_no_padding:
			print("✅ La textura NO tiene padding (correcto)")
		elif w == expected_with_padding:
			print("⚠️  La textura tiene padding de 4px")
		else:
			print("❌ Dimensiones inesperadas")

		# Probar carga con AutoFrames
		print("\nProbando carga con AutoFrames...")
		var base_path = path.replace("_sheet_f8_512.png", "")
		var node = AutoFrames.load_sprite(base_path, 5.0)

		if node == null:
			print("❌ AutoFrames.load_sprite() retornó null")
		elif node is AnimatedSprite2D:
			var frames = node.sprite_frames
			var frame_count = frames.get_frame_count("default")
			var fps = frames.get_animation_speed("default")
			print("✅ AnimatedSprite2D creado correctamente")
			print("   Frames: %d" % frame_count)
			print("   FPS: %d" % fps)
			print("   Texture filter: %d (0=nearest, 1=linear)" % node.texture_filter)
			print("   Texture repeat: %d (0=disabled, 1=enabled)" % node.texture_repeat)

			# Verificar región del primer frame
			if frame_count > 0:
				var first_frame_tex = frames.get_frame_texture("default", 0)
				if first_frame_tex is AtlasTexture:
					var region = first_frame_tex.region
					print("   Región primer frame: x=%d, y=%d, w=%d, h=%d" % [region.position.x, region.position.y, region.size.x, region.size.y])
		else:
			print("⚠️  Se creó un nodo pero no es AnimatedSprite2D")

	print("\n" + "="*70)
	print("DIAGNÓSTICO COMPLETADO")
	print("="*70)

	quit(0)

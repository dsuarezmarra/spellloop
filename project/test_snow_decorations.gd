extends Node2D

# Script de prueba unificado para sistema de biomas Snow
# Muestra texturas base animadas + decoraciones animadas

func _ready():
	print("\n=== PRUEBA COMPLETA - SISTEMA BIOMA SNOW ===\n")

	# ===== TEXTURA BASE ANIMADA DEL SUELO (MOSAICO) =====
	print("--- TEXTURA BASE ANIMADA (MOSAICO) ---")
	var base_texture_path = "res://assets/textures/biomes/Snow/base/snow_base_animated_sheet_f8_512.png"

	# Crear mosaico de textura base (cubrir toda la pantalla)
	var viewport_size = get_viewport_rect().size
	var tile_size = 512  # Tamaño de cada tile
	var tiles_x = ceil(viewport_size.x / tile_size) + 1
	var tiles_y = ceil(viewport_size.y / tile_size) + 1

	print("Creando mosaico: %dx%d tiles (tamaño %dpx)" % [tiles_x, tiles_y, tile_size])

	var tiles_created = 0
	var sync_frame = randi() % 8  # Frame sincronizado (8 frames para Snow)

	for ty in range(tiles_y):
		for tx in range(tiles_x):
			var base_node = AutoFrames.load_sprite(base_texture_path, 5.0)  # 5 FPS para animación suave

			if base_node == null:
				if tx == 0 and ty == 0:
					push_error("❌ No se pudo cargar textura base desde: %s" % base_texture_path)
					print("❌ AutoFrames.load_sprite() retornó null")
				continue

			if base_node != null:
				base_node.position = Vector2(
					tx * tile_size + tile_size / 2,
					ty * tile_size + tile_size / 2
				)
				base_node.z_index = -100  # Fondo

				if base_node is AnimatedSprite2D:
					base_node.play("default")
					base_node.speed_scale = 1.0  # Velocidad fija para sincronización

					# SINCRONIZAR: Todos los tiles empiezan en el mismo frame
					var frames = base_node.sprite_frames
					var frame_count = frames.get_frame_count("default")
					if frame_count > 0:
						base_node.frame = sync_frame % frame_count

					# Info solo del primer tile
					if tx == 0 and ty == 0:
						var fps = frames.get_animation_speed("default")
						print("✅ Textura base animada: %d frames @ %d FPS (sincronizado)" % [frame_count, fps])
						print("   Tamaño por tile: %s" % str(frames.get_frame_texture("default", 0).get_size()))

				add_child(base_node)
				tiles_created += 1

	print("✅ %d tiles de textura base creados\n" % tiles_created)

	# ===== DECORACIONES ANIMADAS =====
	print("--- DECORACIONES ANIMADAS ---")
	var decor_paths = [
		"res://assets/textures/biomes/Snow/decor/snow_decor1_sheet_f8_256.png",
		"res://assets/textures/biomes/Snow/decor/snow_decor2_sheet_f8_256.png",
		"res://assets/textures/biomes/Snow/decor/snow_decor3_sheet_f8_256.png",
		"res://assets/textures/biomes/Snow/decor/snow_decor4_sheet_f8_256.png",
		"res://assets/textures/biomes/Snow/decor/snow_decor5_sheet_f8_256.png",
		"res://assets/textures/biomes/Snow/decor/snow_decor6_sheet_f8_256.png",
		"res://assets/textures/biomes/Snow/decor/snow_decor7_sheet_f8_256.png",
		"res://assets/textures/biomes/Snow/decor/snow_decor8_sheet_f8_256.png",
		"res://assets/textures/biomes/Snow/decor/snow_decor9_sheet_f8_256.png",
		"res://assets/textures/biomes/Snow/decor/snow_decor10_sheet_f8_256.png"
	]

	var decor_count = 0
	var positions = [
		Vector2(300, 200), Vector2(800, 300), Vector2(1200, 250),
		Vector2(400, 500), Vector2(900, 600), Vector2(1400, 550),
		Vector2(200, 800), Vector2(700, 900), Vector2(1100, 850),
		Vector2(500, 1100)
	]

	for i in range(decor_paths.size()):
		var decor_node = AutoFrames.load_sprite(decor_paths[i], 5.0)

		if decor_node != null:
			decor_node.position = positions[i]
			decor_node.z_index = 10

			if decor_node is AnimatedSprite2D:
				decor_node.play("default")

				if decor_count == 0:
					var frames = decor_node.sprite_frames
					var frame_count = frames.get_frame_count("default")
					var fps = frames.get_animation_speed("default")
					print("✅ Decoración: %d frames @ %d FPS" % [frame_count, fps])

			add_child(decor_node)
			decor_count += 1

	print("✅ %d decoraciones cargadas\n" % decor_count)
	print("=== PRUEBA INICIADA - Presiona ESC para salir ===\n")

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()

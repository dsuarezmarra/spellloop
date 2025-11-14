extends Node2D

# Script de prueba para sistema de bioma Forest
# Muestra texturas base animadas (decoraciones pendientes)

func _ready():
	print("\n=== PRUEBA COMPLETA - SISTEMA BIOMA FOREST ===\n")

	# ===== TEXTURA BASE ANIMADA DEL SUELO (MOSAICO) =====
	print("--- TEXTURA BASE ANIMADA (MOSAICO) ---")
	var base_texture_path = "res://assets/textures/biomes/Forest/base/forest_base_animated_sheet_f8_512.png"

	# Crear mosaico de textura base (cubrir toda la pantalla)
	var viewport_size = get_viewport_rect().size
	var tile_size = 512  # Tamaño de cada tile
	var tiles_x = ceil(viewport_size.x / tile_size) + 1
	var tiles_y = ceil(viewport_size.y / tile_size) + 1

	print("Creando mosaico: %dx%d tiles (tamaño %dpx)" % [tiles_x, tiles_y, tile_size])

	var tiles_created = 0
	var sync_frame = randi() % 24  # Frame sincronizado (8 frames × 3 = 24 frames totales)

	for ty in range(tiles_y):
		for tx in range(tiles_x):
			var base_node = AutoFrames.load_sprite(base_texture_path, 5.0, 3)  # 5 FPS × 3 duplicados = 24 frames totales

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

	if tiles_created > 0:
		print("✅ Mosaico creado: %d tiles" % tiles_created)
	else:
		print("❌ No se pudo cargar la textura base")

	print("\n--- DECORACIONES ANIMADAS ---")

	# ===== DECORACIONES ANIMADAS =====
	var decor_paths = [
		"res://assets/textures/biomes/Forest/decor/forest_decor1_sheet_f8_256.png",
		"res://assets/textures/biomes/Forest/decor/forest_decor2_sheet_f8_256.png",
		"res://assets/textures/biomes/Forest/decor/forest_decor3_sheet_f8_256.png",
		"res://assets/textures/biomes/Forest/decor/forest_decor4_sheet_f8_256.png",
		"res://assets/textures/biomes/Forest/decor/forest_decor5_sheet_f8_256.png",
		"res://assets/textures/biomes/Forest/decor/forest_decor6_sheet_f8_256.png",
		"res://assets/textures/biomes/Forest/decor/forest_decor7_sheet_f8_256.png",
		"res://assets/textures/biomes/Forest/decor/forest_decor8_sheet_f8_256.png",
		"res://assets/textures/biomes/Forest/decor/forest_decor9_sheet_f8_256.png",
		"res://assets/textures/biomes/Forest/decor/forest_decor10_sheet_f8_256.png"
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
					print("   Tamaño: %s" % str(frames.get_frame_texture("default", 0).get_size()))

			add_child(decor_node)
			decor_count += 1
		else:
			if i == 0:
				push_error("❌ No se pudo cargar decoración desde: %s" % decor_paths[i])

	print("✅ %d decoraciones creadas\n" % decor_count)

	print("\n=== PRUEBA COMPLETADA ===")
	print("Fondo: Mosaico de textura base animada (cubre toda la pantalla)")
	print("Decoraciones: %d decoraciones animadas distribuidas" % decor_count)
	print("Animación a 5 FPS para movimiento suave")
	print("Presiona ESC o cierra la ventana para salir\n")

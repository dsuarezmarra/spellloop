extends Node2D

# Script de prueba unificado para sistema de biomas Lava
# Muestra texturas base animadas + decoraciones animadas

func _ready():
	print("\n=== PRUEBA COMPLETA - SISTEMA BIOMA LAVA ===\n")

	# ===== TEXTURA BASE ANIMADA DEL SUELO (MOSAICO) =====
	print("--- TEXTURA BASE ANIMADA (MOSAICO) ---")
	var base_texture_path = "res://assets/textures/biomes/Lava/base/lava_base_animated_sheet_f8_512.png"

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
		"res://assets/textures/biomes/Lava/decor/lava_decor1_sheet_f8_256.png",
		"res://assets/textures/biomes/Lava/decor/lava_decor2_sheet_f8_256.png",
		"res://assets/textures/biomes/Lava/decor/lava_decor3_sheet_f8_256.png",
		"res://assets/textures/biomes/Lava/decor/lava_decor4_sheet_f8_256.png",
		"res://assets/textures/biomes/Lava/decor/lava_decor5_sheet_f8_256.png",
		"res://assets/textures/biomes/Lava/decor/lava_decor6_sheet_f8_256.png",
		"res://assets/textures/biomes/Lava/decor/lava_decor7_sheet_f8_256.png",
		"res://assets/textures/biomes/Lava/decor/lava_decor8_sheet_f8_256.png",
		"res://assets/textures/biomes/Lava/decor/lava_decor9_sheet_f8_256.png",
		"res://assets/textures/biomes/Lava/decor/lava_decor10_sheet_f8_256.png"
	]

	# Distribuir decoraciones aleatoriamente por toda la pantalla
	# Reutilizar viewport_size ya declarado arriba
	var num_decors_to_place = 50  # Colocar 50 decoraciones (5 de cada tipo)

	print("Colocando %d decoraciones aleatorias..." % num_decors_to_place)

	for i in range(num_decors_to_place):
		# Seleccionar decoración aleatoria
		var path = decor_paths[randi() % decor_paths.size()]

		# Usar DecorFactory para crear el nodo con FPS reducido a 5.0
		var decor_node = DecorFactory.make_decor(path, 5.0)

		if decor_node:
			# Posición aleatoria
			decor_node.position = Vector2(
				randf() * viewport_size.x,
				randf() * viewport_size.y
			)

			# Escala aleatoria (0.25x a 0.5x)
			var scale_factor = randf_range(0.25, 0.5)
			decor_node.scale = Vector2(scale_factor, scale_factor)

			# Mirror horizontal (50% probabilidad)
			if randf() > 0.5:
				decor_node.scale.x *= -1.0

			decor_node.z_index = 0  # Sobre la textura base
			add_child(decor_node)

			# Información del nodo creado (solo primeros 3)
			if i < 3:
				if decor_node is AnimatedSprite2D:
					var sprite_frames = decor_node.sprite_frames
					var frame_count = sprite_frames.get_frame_count("default")
					var fps = sprite_frames.get_animation_speed("default")
					print("  ✅ %s: escala %.2fx, mirror: %s" % [
						path.get_file().get_basename(),
						scale_factor,
						"Sí" if decor_node.scale.x < 0 else "No"
					])
		else:
			print("  ❌ Error al crear decoración: %s" % path.get_file())

	print("\n=== PRUEBA COMPLETADA ===")
	print("Fondo: Mosaico de textura base animada (cubre toda la pantalla)")
	print("Decoraciones: %d elementos distribuidos aleatoriamente" % num_decors_to_place)
	print("  - Escalas: 0.25x a 0.5x aleatorias")
	print("  - Mirror horizontal: 50%% probabilidad")
	print("Todo a 5 FPS para animaciones suaves")
	print("Presiona ESC o cierra la ventana para salir\n")

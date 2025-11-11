extends Node2D

# Script de prueba unificado para sistema de biomas ArcaneWastes
# Muestra texturas base animadas + decoraciones animadas

func _ready():
	print("\n=== PRUEBA COMPLETA - SISTEMA BIOMA ARCANEWASTES ===\n")

	# ===== TEXTURA BASE ANIMADA DEL SUELO (MOSAICO) =====
	print("--- TEXTURA BASE ANIMADA (MOSAICO) ---")
	var base_texture_path = "res://assets/textures/biomes/ArcaneWastes/base/arcanewastes_base_animated"

	print("Intentando cargar textura base desde: %s" % base_texture_path)

	# Crear mosaico de textura base (cubrir toda la pantalla)
	var viewport_size = get_viewport_rect().size
	var tile_size = 512  # Tamaño de cada tile
	var tiles_x = ceil(viewport_size.x / tile_size) + 1
	var tiles_y = ceil(viewport_size.y / tile_size) + 1

	print("Creando mosaico: %dx%d tiles (tamaño %dpx)" % [tiles_x, tiles_y, tile_size])

	var tiles_created = 0
	var sync_frame = randi() % 8  # Frame sincronizado (8 frames para ArcaneWastes)

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
					tx * tile_size,
					ty * tile_size
				)
				base_node.z_index = -100  # Fondo

				if base_node is AnimatedSprite2D:
					# CRÍTICO: Desactivar centered para evitar movimiento en tiles del suelo
					base_node.centered = false
					base_node.play("default")
					base_node.speed_scale = 1.0  # Velocidad fija para sincronización					# SINCRONIZAR: Todos los tiles empiezan en el mismo frame
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
		"res://assets/textures/biomes/ArcaneWastes/decor/arcanewastes_decor1_sheet_f8_256.png",
		"res://assets/textures/biomes/ArcaneWastes/decor/arcanewastes_decor2_sheet_f8_256.png",
		"res://assets/textures/biomes/ArcaneWastes/decor/arcanewastes_decor3_sheet_f8_256.png",
		"res://assets/textures/biomes/ArcaneWastes/decor/arcanewastes_decor4_sheet_f8_256.png",
		"res://assets/textures/biomes/ArcaneWastes/decor/arcanewastes_decor5_sheet_f8_256.png",
		"res://assets/textures/biomes/ArcaneWastes/decor/arcanewastes_decor6_sheet_f8_256.png",
		"res://assets/textures/biomes/ArcaneWastes/decor/arcanewastes_decor7_sheet_f8_256.png",
		"res://assets/textures/biomes/ArcaneWastes/decor/arcanewastes_decor8_sheet_f8_256.png",
		"res://assets/textures/biomes/ArcaneWastes/decor/arcanewastes_decor9_sheet_f8_256.png",
		"res://assets/textures/biomes/ArcaneWastes/decor/arcanewastes_decor10_sheet_f8_256.png",
		"res://assets/textures/biomes/ArcaneWastes/decor/arcanewastes_decor11_sheet_f8_256.png"
	]

	# Distribuir decoraciones aleatoriamente por toda la pantalla
	# Reutilizar viewport_size ya declarado arriba
	var num_decors_to_place = 50  # Colocar 50 decoraciones (aprox 4-5 de cada tipo)

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

			# Escala aleatoria (0.5x a 3.0x)
			var scale_factor = randf_range(0.5, 3.0)
			decor_node.scale = Vector2(scale_factor, scale_factor)

			# Mirror horizontal (50% probabilidad)
			if randf() > 0.5:
				decor_node.flip_h = true

			# Z-index aleatorio (encima del fondo)
			decor_node.z_index = randi_range(0, 10)

			add_child(decor_node)

			# Info solo de la primera decoración
			if i == 0:
				if decor_node is AnimatedSprite2D:
					var frames = decor_node.sprite_frames
					var frame_count = frames.get_frame_count("default")
					var fps = frames.get_animation_speed("default")
					print("✅ Decoración animada: %d frames @ %d FPS" % [frame_count, fps])

	print("✅ %d decoraciones colocadas aleatoriamente" % num_decors_to_place)
	print("\n=== PRUEBA LISTA ===\n")

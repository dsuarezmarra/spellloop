extends Node2D

# Script de prueba unificado para sistema de biomas Snow
# Muestra texturas base animadas + decoraciones animadas

func _ready():
	print("\n=== PRUEBA COMPLETA - SISTEMA BIOMA SNOW ===\n")
	
	# ===== TEXTURA BASE ANIMADA DEL SUELO (MOSAICO) =====
	print("--- TEXTURA BASE ANIMADA (MOSAICO) ---")
	var base_texture_path = "res://assets/textures/biomes/Snow/base/snow_base_animated"
	
	# Crear mosaico de textura base (cubrir toda la pantalla)
	var viewport_size = get_viewport_rect().size
	var tile_size = 512  # Tamaño de cada tile
	var tiles_x = ceil(viewport_size.x / tile_size) + 1
	var tiles_y = ceil(viewport_size.y / tile_size) + 1
	
	print("Creando mosaico: %dx%d tiles (tamaño %dpx)" % [tiles_x, tiles_y, tile_size])
	
	var tiles_created = 0
	var sync_frame = randi() % 8  # Frame sincronizado (8 frames)
	
	for ty in range(tiles_y):
		for tx in range(tiles_x):
			var base_node = AutoFrames.load_sprite(base_texture_path, 5.0)  # 5 FPS para animación suave
			
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
	
	# Distribuir decoraciones aleatoriamente por toda la pantalla
	var num_decors_to_place = 50  # Colocar 50 decoraciones
	
	print("Colocando %d decoraciones aleatorias..." % num_decors_to_place)
	
	for i in range(num_decors_to_place):
		# Seleccionar decoración aleatoria
		var path = decor_paths[randi() % decor_paths.size()]
		
		# Usar DecorFactory para crear el nodo con shader y biome_name
		var decor_node = DecorFactory.make_decor(path, 5.0, true, "Snow")
		
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
				decor_node.scale.x *= -1.0
			
			# Z-index aleatorio para variación de profundidad
			decor_node.z_index = randi() % 10
			
			add_child(decor_node)
	
	print("✅ Decoraciones colocadas: %d" % num_decors_to_place)
	print("\n=== PRUEBA COMPLETADA ===")
	print("Presiona ESC para salir o F5 para reload\n")

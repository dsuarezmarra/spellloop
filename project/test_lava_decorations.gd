extends Node2D

# Script de prueba unificado para sistema de biomas Lava
# Muestra texturas base animadas + decoraciones animadas

func _ready():
	print("\n=== PRUEBA COMPLETA - SISTEMA BIOMA LAVA ===\n")
	
	# ===== TEXTURA BASE ANIMADA DEL SUELO (MOSAICO) =====
	print("--- TEXTURA BASE ANIMADA (MOSAICO) ---")
	var base_texture_path = "res://assets/textures/biomes/Lava/base/lava_base_animated"
	
	# Crear mosaico de textura base (cubrir toda la pantalla)
	var viewport_size = get_viewport_rect().size
	var tile_size = 512  # Tamaño de cada tile
	var tiles_x = ceil(viewport_size.x / tile_size) + 1
	var tiles_y = ceil(viewport_size.y / tile_size) + 1
	
	print("Creando mosaico: %dx%d tiles (tamaño %dpx)" % [tiles_x, tiles_y, tile_size])
	
	var tiles_created = 0
	var sync_frame = randi() % 8  # Frame sincronizado para todos los tiles
	
	for ty in range(tiles_y):
		for tx in range(tiles_x):
			var base_node = AutoFrames.load_sprite(base_texture_path)
			
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
	
	var x_offset = 200  # Mayor separación (era 130)
	var current_x = 100
	var decor_y = get_viewport_rect().size.y - 200  # Abajo pero con margen
	
	for i in range(decor_paths.size()):
		var path = decor_paths[i]
		print("Cargando: %s" % path.get_file())
		
		# Usar DecorFactory para crear el nodo con FPS reducido a 5.0
		var decor_node = DecorFactory.make_decor(path, 5.0)
		
		if decor_node:
			decor_node.position = Vector2(current_x, decor_y)
			decor_node.z_index = 0  # Sobre la textura base
			add_child(decor_node)
			
			# Información del nodo creado
			if decor_node is AnimatedSprite2D:
				var sprite_frames = decor_node.sprite_frames
				var frame_count = sprite_frames.get_frame_count("default")
				var fps = sprite_frames.get_animation_speed("default")
				print("  ✅ AnimatedSprite2D: %d frames @ %d FPS" % [frame_count, fps])
			else:
				print("  ⚠️ No es AnimatedSprite2D (tipo: %s)" % decor_node.get_class())
			
			current_x += x_offset
		else:
			print("  ❌ Error al crear decoración")
	
	print("\n=== PRUEBA COMPLETADA ===")
	print("Fondo: Mosaico de textura base animada (cubre toda la pantalla)")
	print("Abajo: 10 decoraciones animadas con más separación")
	print("Todo a 5 FPS para animaciones suaves")
	print("Presiona ESC o cierra la ventana para salir\n")

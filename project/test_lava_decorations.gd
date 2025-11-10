extends Node2D

# Script de prueba unificado para sistema de biomas Lava
# Muestra texturas base animadas + decoraciones animadas

func _ready():
	print("\n=== PRUEBA COMPLETA - SISTEMA BIOMA LAVA ===\n")
	
	# ===== TEXTURA BASE ANIMADA DEL SUELO =====
	print("--- TEXTURA BASE ANIMADA ---")
	var base_texture_path = "res://assets/textures/biomes/Lava/base/lava_base_animated"
	var base_node = AutoFrames.load_sprite(base_texture_path)
	
	if base_node != null:
		base_node.position = Vector2(640, 200)  # Centro superior
		base_node.z_index = -100  # Fondo
		
		if base_node is AnimatedSprite2D:
			base_node.play("default")
			base_node.speed_scale = 1.0
			add_child(base_node)
			
			var frames = base_node.sprite_frames
			var frame_count = frames.get_frame_count("default")
			var fps = frames.get_animation_speed("default")
			print("✅ Textura base animada cargada: %d frames @ %d FPS" % [frame_count, fps])
			print("   Tamaño: %s" % str(frames.get_frame_texture("default", 0).get_size()))
			print("   Posición: (640, 200)")
		else:
			add_child(base_node)
			print("⚠️ Textura base estática (Sprite2D)")
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
	
	var x_offset = 130
	var current_x = 60
	
	for i in range(decor_paths.size()):
		var path = decor_paths[i]
		print("Cargando: %s" % path.get_file())
		
		# Usar DecorFactory para crear el nodo con FPS reducido a 5.0
		var decor_node = DecorFactory.make_decor(path, 5.0)
		
		if decor_node:
			decor_node.position = Vector2(current_x, 500)
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
	print("Arriba: Textura base animada del suelo")
	print("Abajo: 10 decoraciones animadas")
	print("Todo a 5 FPS para animaciones suaves")
	print("Presiona ESC o cierra la ventana para salir\n")

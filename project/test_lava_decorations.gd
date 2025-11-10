extends Node2D

# Script de prueba para decoraciones animadas del bioma Lava
# Carga y muestra todas las decoraciones para verificar el sistema

func _ready():
	print("\n=== PRUEBA DE DECORACIONES ANIMADAS - BIOMA LAVA ===\n")
	
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
	
	var x_offset = 150
	var current_x = 100
	
	for i in range(decor_paths.size()):
		var path = decor_paths[i]
		print("Cargando: %s" % path.get_file())
		
		# Usar DecorFactory para crear el nodo con FPS reducido a 5.0 (la mitad)
		var decor_node = DecorFactory.make_decor(path, 5.0)
		
		if decor_node:
			decor_node.position = Vector2(current_x, 300)
			add_child(decor_node)
			
			# Información del nodo creado
			if decor_node is AnimatedSprite2D:
				var sprite_frames = decor_node.sprite_frames
				var frame_count = sprite_frames.get_frame_count("default")
				var fps = sprite_frames.get_animation_speed("default")
				print("  ✅ AnimatedSprite2D creado: %d frames @ %d FPS" % [frame_count, fps])
				print("  📍 Posición: (%d, 300)" % current_x)
			else:
				print("  ⚠️ No es AnimatedSprite2D (tipo: %s)" % decor_node.get_class())
			
			current_x += x_offset
		else:
			print("  ❌ Error al crear decoración")
	
	print("\n=== Prueba completada ===")
	print("Deberías ver 10 decoraciones animadas en pantalla")
	print("Presiona ESC o cierra la ventana para salir\n")

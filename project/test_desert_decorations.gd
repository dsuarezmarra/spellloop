extends Node2D

# Script de prueba para sistema de bioma Desert
# Muestra textura base animada (decoraciones pendientes)

func _ready():
	print("\n=== PRUEBA COMPLETA - SISTEMA BIOMA DESERT ===\n")

	# ===== TEXTURA BASE ANIMADA DEL SUELO (MOSAICO) =====
	print("--- TEXTURA BASE ANIMADA (MOSAICO) ---")
	var base_texture_path = "res://assets/textures/biomes/Desert/base/desert_base_animated_sheet_f8_1024.png"

	# Crear mosaico de textura base (cubrir toda la pantalla)
	var viewport_size = get_viewport_rect().size
	var tile_size = 1024  # CORRECCIÓN: Los frames son 1024x1024, no 512x512
	var tiles_x = ceil(viewport_size.x / tile_size) + 1
	var tiles_y = ceil(viewport_size.y / tile_size) + 1

	print("Creando mosaico: %dx%d tiles (tamaño %dpx)" % [tiles_x, tiles_y, tile_size])

	var tiles_created = 0
	var sync_frame = randi() % 24  # Frame sincronizado (24 frames pre-interpolados)

	for ty in range(tiles_y):
		for tx in range(tiles_x):
			var base_node = AutoFrames.load_sprite(base_texture_path, 5.0)  # 5 FPS, 24 frames pre-interpolados

			if base_node == null:
				if tx == 0 and ty == 0:
					push_error("❌ No se pudo cargar textura base desde: %s" % base_texture_path)
					print("❌ AutoFrames.load_sprite() retornó null")
				continue

			if base_node != null:
				# CRÍTICO: Posicionar en esquina superior izquierda del tile (NO centrar)
				# Esto evita subpixel positioning y gaps entre tiles
				base_node.position = Vector2(tx * tile_size, ty * tile_size)
				base_node.centered = false  # Sprite comienza en su esquina superior izquierda
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

	print("\n--- DECORACIONES ANIMADAS ---")
	print("⚠️  PENDIENTE: Decoraciones no disponibles aún")
	print("   Las decoraciones se agregarán cuando estén listas")

	print("\n=== PRUEBA COMPLETADA ===")
	print("Fondo: Mosaico de textura base animada (cubre toda la pantalla)")
	print("Decoraciones: PENDIENTE (se agregarán próximamente)")
	print("Animación a 5 FPS para movimiento suave")
	print("Presiona ESC o cierra la ventana para salir\n")

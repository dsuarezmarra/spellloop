extends Node2D

# Script de prueba para sistema de bioma Grassland
# Muestra texturas base animadas (decoraciones pendientes)

func _ready():
	print("\n=== PRUEBA COMPLETA - SISTEMA BIOMA GRASSLAND ===\n")

	# ===== TEXTURA BASE ANIMADA DEL SUELO (MOSAICO) =====
	print("--- TEXTURA BASE ANIMADA (MOSAICO) ---")
	var base_texture_path = "res://assets/textures/biomes/Grassland/base/grassland_base_animated_sheet_f8_512.png"

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
	print("⚠️  PENDIENTE: Decoraciones no disponibles aún")
	print("   Las decoraciones se agregarán cuando estén listas")

	print("\n=== PRUEBA COMPLETADA ===")
	print("Fondo: Mosaico de textura base animada (cubre toda la pantalla)")
	print("Decoraciones: PENDIENTE (se agregarán próximamente)")
	print("Animación a 5 FPS para movimiento suave")
	print("Presiona ESC o cierra la ventana para salir\n")

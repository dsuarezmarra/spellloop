extends SceneTree

func _init():
	print("=== GENERANDO PRUEBA VISUAL DE BLENDING ===")
	
	# Crear escena
	var scene = Node2D.new()
	current_scene = scene
	
	# Crear demo del sistema
	create_blending_demo()
	
	# Esperar un frame y tomar captura
	await process_frame
	take_screenshot()
	
	print("✅ Demo completado")
	quit()

func create_blending_demo():
	print("Creando demo de blending...")
	
	# Cargar shader
	var shader = load("res://scripts/core/shaders/biome_blend.gdshader")
	if not shader:
		print("❌ No se pudo cargar shader")
		return
	
	print("✅ Shader cargado")
	
	# Crear material
	var material = ShaderMaterial.new()
	material.shader = shader
	
	# Crear texturas de biomas
	var grassland_tex = create_biome_texture(Color.GREEN, "grassland")
	var desert_tex = create_biome_texture(Color.SANDY_BROWN, "desert")
	var forest_tex = create_biome_texture(Color.DARK_GREEN, "forest")
	
	# Configurar material con texturas
	material.set_shader_parameter("biome_a_base", grassland_tex)
	material.set_shader_parameter("biome_a_decor", grassland_tex)
	material.set_shader_parameter("biome_b_base", desert_tex) 
	material.set_shader_parameter("biome_b_decor", desert_tex)
	material.set_shader_parameter("blend_strength", 0.7)
	material.set_shader_parameter("noise_scale", 2.0)
	material.set_shader_parameter("flow_speed", 0.5)
	material.set_shader_parameter("micro_oscillation", 0.04)
	material.set_shader_parameter("time", 0.0)
	
	# Crear sprites de demostración
	create_demo_sprites(material, grassland_tex, desert_tex, forest_tex)
	
	print("✅ Demo visual creado")

func create_biome_texture(base_color: Color, biome_name: String) -> ImageTexture:
	var image = Image.create(256, 256, false, Image.FORMAT_RGBA8)
	
	for y in range(256):
		for x in range(256):
			# Crear patrón orgánico con ruido
			var noise_x = float(x) * 0.02
			var noise_y = float(y) * 0.02
			var noise_val = (sin(noise_x) * cos(noise_y) + 1.0) * 0.5
			
			# Variar color basado en ruido
			var variation = 0.2 * noise_val
			var final_color = base_color.lerp(Color.WHITE, variation)
			
			# Añadir detalles específicos del bioma
			if biome_name == "grassland":
				# Manchas verdes más oscuras
				if noise_val > 0.7:
					final_color = final_color.lerp(Color.DARK_GREEN, 0.3)
			elif biome_name == "desert":
				# Manchas más claras tipo arena
				if noise_val > 0.6:
					final_color = final_color.lerp(Color.YELLOW, 0.4)
			elif biome_name == "forest":
				# Sombras más oscuras
				if noise_val < 0.3:
					final_color = final_color.lerp(Color.BLACK, 0.2)
			
			image.set_pixel(x, y, final_color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func create_demo_sprites(blend_material: ShaderMaterial, grass_tex: ImageTexture, desert_tex: ImageTexture, forest_tex: ImageTexture):
	# Sprite central con blending
	var blend_sprite = Sprite2D.new()
	blend_sprite.texture = grass_tex
	blend_sprite.material = blend_material
	blend_sprite.position = Vector2(512, 384)
	blend_sprite.scale = Vector2(2, 2)
	current_scene.add_child(blend_sprite)
	
	# Sprites de referencia sin blending
	var grass_sprite = Sprite2D.new()
	grass_sprite.texture = grass_tex
	grass_sprite.position = Vector2(200, 200)
	grass_sprite.scale = Vector2(1.5, 1.5)
	current_scene.add_child(grass_sprite)
	
	var desert_sprite = Sprite2D.new()
	desert_sprite.texture = desert_tex
	desert_sprite.position = Vector2(824, 200)
	desert_sprite.scale = Vector2(1.5, 1.5)
	current_scene.add_child(desert_sprite)
	
	var forest_sprite = Sprite2D.new()
	forest_sprite.texture = forest_tex
	forest_sprite.position = Vector2(512, 600)
	forest_sprite.scale = Vector2(1.5, 1.5)
	current_scene.add_child(forest_sprite)
	
	# Etiquetas
	create_label("🌱 Grassland", Vector2(200, 120))
	create_label("🏜️ Desert", Vector2(824, 120))
	create_label("🌲 Forest", Vector2(512, 520))
	create_label("🌊 Organic Blending", Vector2(512, 280))
	create_label("Sistema de Blending Orgánico - Spellloop", Vector2(512, 50))

func create_label(text: String, pos: Vector2):
	var label = Label.new()
	label.text = text
	label.position = pos - Vector2(text.length() * 8, 10)
	label.add_theme_font_size_override("font_size", 20)
	current_scene.add_child(label)

func take_screenshot():
	print("Tomando captura de pantalla...")
	
	# Crear viewport para captura
	var viewport = SubViewport.new()
	viewport.size = Vector2i(1024, 768)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	# Clonar escena al viewport
	var scene_copy = current_scene.duplicate()
	viewport.add_child(scene_copy)
	current_scene.add_child(viewport)
	
	# Renderizar
	await process_frame
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	# Obtener imagen
	var image = viewport.get_texture().get_image()
	
	# Guardar
	var save_path = "user://blending_test_result.png"
	image.save_png(save_path)
	
	print("✅ Captura guardada en: " + save_path)
	print("   Ruta completa del sistema: " + OS.get_user_data_dir() + "/blending_test_result.png")
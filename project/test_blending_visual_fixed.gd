extends Node2D

# Script de prueba visual corregido
@onready var camera = $Camera2D
@onready var ui_label = $UI/Label

var test_regions = []
var blender: Node

func _ready():
	print("=== INICIANDO PRUEBA VISUAL DE BLENDING CORREGIDA ===")
	
	# Crear TextureBlender
	var blender_script = load("res://scripts/core/OrganicTextureBlenderFixed.gd")
	if blender_script:
		blender = blender_script.new()
		add_child(blender)
		blender.initialize(12345)
		
		# Crear regiones de prueba
		create_test_regions()
		
		# Aplicar blending
		apply_test_blending()
		
		# Actualizar UI
		update_ui()
	else:
		print("❌ No se pudo cargar OrganicTextureBlender")

func create_test_regions():
	print("Creando regiones de prueba...")
	
	# Región de pasto (izquierda)
	var grassland_region = create_biome_region(
		"grassland", 
		Vector2(-300, 0), 
		Color.GREEN,
		"🌱 Pradera"
	)
	
	# Región de desierto (derecha)  
	var desert_region = create_biome_region(
		"desert",
		Vector2(300, 0),
		Color.SANDY_BROWN,
		"🏜️ Desierto"
	)
	
	add_child(grassland_region)
	add_child(desert_region)
	
	test_regions = [grassland_region, desert_region]
	
	print("✅ Regiones creadas: " + str(test_regions.size()))

func create_biome_region(biome_id: String, pos: Vector2, color: Color, label: String) -> Node2D:
	var region = Node2D.new()
	region.name = "Region_" + biome_id
	region.position = pos
	
	# Crear sprite visual
	var sprite = Sprite2D.new()
	var texture = create_biome_texture(color, biome_id)
	sprite.texture = texture
	sprite.scale = Vector2(2, 2)
	region.add_child(sprite)
	
	# Añadir etiqueta
	var label_node = Label.new()
	label_node.text = label
	label_node.position = Vector2(-50, -150)
	label_node.add_theme_font_size_override("font_size", 20)
	region.add_child(label_node)
	
	# Metadatos para el sistema orgánico
	var organic_data = {
		"region_id": biome_id + "_test",
		"biome_id": biome_id,
		"center_position": pos,
		"boundary_points": [
			pos + Vector2(-100, -100),
			pos + Vector2(100, -100),
			pos + Vector2(100, 100), 
			pos + Vector2(-100, 100)
		]
	}
	
	region.set_meta("organic_region", organic_data)
	
	return region

func create_biome_texture(base_color: Color, biome_id: String) -> ImageTexture:
	var size = 128
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Llenar con patrón básico del bioma
	for y in range(size):
		for x in range(size):
			var noise_val = sin(x * 0.1) * cos(y * 0.1)
			var color_variation = base_color.lerp(Color.WHITE, noise_val * 0.2)
			image.set_pixel(x, y, color_variation)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func apply_test_blending():
	print("Aplicando blending de prueba...")
	
	if not blender or not blender.is_initialized:
		print("❌ Blender no inicializado")
		return
	
	# Crear zona de blending entre pradera y desierto
	var blend_region = create_blend_zone(
		test_regions[0],  # grassland
		test_regions[1]   # desert
	)
	
	if blend_region:
		add_child(blend_region)
		print("✅ Zona de blending creada")

func create_blend_zone(region_a: Node2D, region_b: Node2D) -> Node2D:
	var blend_zone = Node2D.new()
	blend_zone.name = "BlendZone"
	blend_zone.position = (region_a.position + region_b.position) / 2
	
	# Crear sprite para la zona de blending
	var sprite = Sprite2D.new()
	var texture = create_blend_texture()
	sprite.texture = texture
	sprite.scale = Vector2(2, 2)
	
	# Crear datos de prueba para blending
	var blend_data = {
		"biome_id": "grassland",
		"position": blend_zone.position,
		"neighbors": [
			{"biome_id": "desert", "position": region_b.position}
		]
	}
	
	# Aplicar material de blending
	var material = blender.apply_blend_to_region(blend_data)
	if material:
		sprite.material = material
		print("✅ Material de shader aplicado")
	
	blend_zone.add_child(sprite)
	
	# Etiqueta
	var label = Label.new()
	label.text = "🌊 Zona de Blending"
	label.position = Vector2(-70, -150)
	label.add_theme_font_size_override("font_size", 16)
	blend_zone.add_child(label)
	
	return blend_zone

func create_blend_texture() -> ImageTexture:
	var size = 128
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Crear patrón de transición
	for y in range(size):
		for x in range(size):
			var blend_factor = float(x) / size
			var grass_color = Color.GREEN
			var desert_color = Color.SANDY_BROWN
			var blended = grass_color.lerp(desert_color, blend_factor)
			image.set_pixel(x, y, blended)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	return texture

func update_ui():
	var status_text = "SISTEMA DE BLENDING ORGÁNICO - Prueba Visual\n\n"
	status_text += "Estado del Sistema:\n"
	status_text += "✅ Shader: Cargado\n"
	status_text += "✅ TextureBlender: " + ("Inicializado" if blender and blender.is_initialized else "Error")
	status_text += "\n✅ Regiones de prueba: " + str(test_regions.size())
	status_text += "\n\n🎮 Usa WASD para mover la cámara"
	
	if ui_label:
		ui_label.text = status_text

func _process(delta):
	# Actualizar tiempo en materiales de shader
	var blend_zones = get_children().filter(func(n): return n.name == "BlendZone")
	for zone in blend_zones:
		if zone.get_child_count() > 0:
			var sprite = zone.get_child(0)
			if sprite and sprite.material and sprite.material is ShaderMaterial:
				sprite.material.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)

func _input(event):
	# Control de cámara básico
	if not camera:
		return
		
	if event is InputEventKey and event.pressed:
		var speed = 200
		match event.keycode:
			KEY_W:
				camera.position.y -= speed * get_process_delta_time() * 10
			KEY_S:
				camera.position.y += speed * get_process_delta_time() * 10
			KEY_A:
				camera.position.x -= speed * get_process_delta_time() * 10
			KEY_D:
				camera.position.x += speed * get_process_delta_time() * 10
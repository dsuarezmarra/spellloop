extends Node2D

## Test de visualización de dithering entre biomas
## Muestra un chunk con el nuevo sistema de transiciones Bayer

var biome_generator: BiomeGeneratorOrganic
var biome_applier: BiomeChunkApplierOrganic

func _ready() -> void:
	print("=" * 60)
	print("🎨 TEST: BIOME DITHERING VISUALIZATION")
	print("=" * 60)
	
	# Configurar cámara
	var camera = Camera2D.new()
	camera.zoom = Vector2(0.1, 0.1)  # Alejada para ver todo el chunk
	add_child(camera)
	
	# Crear generador de biomas
	biome_generator = BiomeGeneratorOrganic.new()
	biome_generator.cellular_frequency = 0.00001  # Regiones grandes
	biome_generator.seed_value = 12345  # Seed fijo para testing
	biome_generator.debug_mode = true
	add_child(biome_generator)
	
	# Esperar un frame para que se inicialice
	await get_tree().process_frame
	
	# Crear chunk de prueba
	var test_chunk = Node2D.new()
	test_chunk.name = "TestChunk"
	add_child(test_chunk)
	
	# Crear applier de biomas
	biome_applier = BiomeChunkApplierOrganic.new()
	biome_applier.tile_resolution = 512
	biome_applier.dithering_enabled = true
	biome_applier.dithering_width = 16
	biome_applier.debug_mode = true
	biome_applier._biome_generator = biome_generator
	add_child(biome_applier)
	
	# Esperar que cargue configuración
	await get_tree().process_frame
	
	# Aplicar biomas al chunk (0, 0)
	print("\n🔨 Aplicando biomas con dithering al chunk (0,0)...")
	biome_applier.apply_biome_to_chunk(test_chunk, 0, 0)
	
	print("\n✅ Chunk generado. Controles:")
	print("  - WASD: Mover cámara")
	print("  - Q/E: Zoom in/out")
	print("  - R: Regenerar con nuevo seed")
	print("  - ESC: Salir")

func _process(_delta: float) -> void:
	# Controles de cámara
	var camera = get_node_or_null("Camera2D")
	if camera == null:
		return
	
	var move_speed = 1000.0
	
	if Input.is_key_pressed(KEY_W):
		camera.position.y -= move_speed
	if Input.is_key_pressed(KEY_S):
		camera.position.y += move_speed
	if Input.is_key_pressed(KEY_A):
		camera.position.x -= move_speed
	if Input.is_key_pressed(KEY_D):
		camera.position.x += move_speed
	
	if Input.is_key_pressed(KEY_Q):
		camera.zoom *= 1.01
	if Input.is_key_pressed(KEY_E):
		camera.zoom *= 0.99
	
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			print("\n🔄 Regenerando chunk con nuevo seed...")
			_regenerate_chunk()

func _regenerate_chunk() -> void:
	"""Regenerar chunk con nuevo seed aleatorio"""
	
	# Eliminar chunk anterior
	var old_chunk = get_node_or_null("TestChunk")
	if old_chunk:
		old_chunk.queue_free()
	
	# Nuevo seed aleatorio
	randomize()
	biome_generator.seed_value = randi()
	biome_generator._initialize_noise_generator()
	
	# Crear nuevo chunk
	var test_chunk = Node2D.new()
	test_chunk.name = "TestChunk"
	add_child(test_chunk)
	
	# Aplicar biomas
	biome_applier.apply_biome_to_chunk(test_chunk, 0, 0)
	
	print("✅ Chunk regenerado con seed: %d" % biome_generator.cellular_noise.seed)

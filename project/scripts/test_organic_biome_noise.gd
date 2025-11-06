extends Node2D

"""
🧪 TEST: ORGANIC BIOME GENERATION WITH VORONOI + DOMAIN WARP
=============================================================

Este script es un test standalone para visualizar y ajustar
los parámetros de generación de biomas orgánicos.

INSTRUCCIONES:
1. Crear escena nueva en Godot
2. Añadir Node2D raíz
3. Adjuntar este script
4. Ejecutar escena (F6)
5. Ajustar parámetros en el Inspector
6. Ver resultados en pantalla

CONTROLES:
- R: Regenerar con nueva seed
- +/-: Ajustar zoom
- WASD: Mover cámara
- ESC: Salir
"""

# ========== PARÁMETROS AJUSTABLES ==========

@export_category("Cellular Noise (Voronoi)")
@export var cellular_frequency: float = 0.0003  # Menor = regiones más grandes
@export var cellular_jitter: float = 1.0  # 0-1, irregularidad de células

@export_category("Domain Warp")
@export var use_domain_warp: bool = true
@export var warp_amplitude: float = 100.0  # Intensidad de distorsión
@export var warp_frequency: float = 0.005  # Frecuencia de distorsión
@export var warp_octaves: int = 3  # Capas de distorsión

@export_category("Detail Noise (Perlin)")
@export var use_detail_noise: bool = true
@export var detail_frequency: float = 0.01
@export var detail_octaves: int = 3
@export var detail_influence: float = 0.15  # 0-1, cuánto afecta al resultado

@export_category("Visualization")
@export var visualization_size: Vector2i = Vector2i(800, 600)
@export var pixel_size: int = 2  # Tamaño de cada píxel en pantalla
@export var show_grid: bool = true
@export var show_info: bool = true

# ========== VARIABLES INTERNAS ==========

var cellular_noise: FastNoiseLite
var detail_noise: FastNoiseLite
var image: Image
var texture: ImageTexture
var sprite: Sprite2D
var world_seed: int = 0
var camera_offset: Vector2 = Vector2.ZERO
var zoom_level: float = 1.0

# Colores de biomas
var biome_colors = [
	Color(0.90, 0.85, 0.60, 1.0),  # Desert - Arena
	Color(0.30, 0.70, 0.30, 1.0),  # Forest - Verde
	Color(0.70, 0.90, 1.00, 1.0),  # Ice - Azul claro
	Color(1.00, 0.50, 0.30, 1.0),  # Fire - Rojo/naranja
	Color(0.50, 0.20, 0.80, 1.0),  # Abyss - Púrpura
]

var biome_names = ["Desert", "Forest", "Ice", "Fire", "Abyss"]

# ========== INICIALIZACIÓN ==========

func _ready() -> void:
	print("\n" + "============================================================")
	print("🧪 TEST: ORGANIC BIOME GENERATION")
	print("============================================================")

	# Configurar ventana
	get_viewport().size = Vector2i(1280, 720)

	# Seed inicial aleatoria
	randomize()
	world_seed = randi()

	# Inicializar noise
	_initialize_noise()

	# Crear visualización
	_create_visualization()

	# Generar primera vez
	_generate_biome_map()

	print("\n📋 CONTROLES:")
	print("  R - Regenerar con nueva seed")
	print("  +/- - Ajustar zoom")
	print("  WASD - Mover cámara")
	print("  G - Toggle grid")
	print("  I - Toggle info")
	print("  ESC - Salir")
	print("============================================================\n")

func _initialize_noise() -> void:
	"""Inicializar generadores de ruido"""

	# Cellular noise (Voronoi)
	cellular_noise = FastNoiseLite.new()
	cellular_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	cellular_noise.cellular_distance_function = FastNoiseLite.DISTANCE_HYBRID
	cellular_noise.cellular_return_type = FastNoiseLite.RETURN_CELL_VALUE
	cellular_noise.cellular_jitter = cellular_jitter
	cellular_noise.frequency = cellular_frequency
	cellular_noise.seed = world_seed

	# Domain warp
	if use_domain_warp:
		cellular_noise.domain_warp_enabled = true
		cellular_noise.domain_warp_type = FastNoiseLite.DOMAIN_WARP_SIMPLEX
		cellular_noise.domain_warp_amplitude = warp_amplitude
		cellular_noise.domain_warp_frequency = warp_frequency
		cellular_noise.domain_warp_fractal_type = FastNoiseLite.DOMAIN_WARP_FRACTAL_PROGRESSIVE
		cellular_noise.domain_warp_fractal_octaves = warp_octaves

	# Detail noise (Perlin)
	detail_noise = FastNoiseLite.new()
	detail_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	detail_noise.frequency = detail_frequency
	detail_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	detail_noise.fractal_octaves = detail_octaves
	detail_noise.fractal_gain = 0.5
	detail_noise.fractal_lacunarity = 2.0
	detail_noise.seed = world_seed + 1

	print("✅ Noise inicializado:")
	print("   Cellular: freq=%.4f, jitter=%.2f" % [cellular_frequency, cellular_jitter])
	if use_domain_warp:
		print("   Domain Warp: amp=%.1f, freq=%.4f, octaves=%d" % [warp_amplitude, warp_frequency, warp_octaves])
	if use_detail_noise:
		print("   Detail: freq=%.4f, octaves=%d, influence=%.2f" % [detail_frequency, detail_octaves, detail_influence])

func _create_visualization() -> void:
	"""Crear sprite para visualización"""
	image = Image.create(visualization_size.x, visualization_size.y, false, Image.FORMAT_RGB8)
	texture = ImageTexture.create_from_image(image)

	sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.scale = Vector2(pixel_size, pixel_size)
	add_child(sprite)

	print("✅ Visualización creada: %dx%d píxeles" % [visualization_size.x, visualization_size.y])

# ========== GENERACIÓN ==========

func _generate_biome_map() -> void:
	"""Generar y visualizar mapa de biomas"""
	var start_time = Time.get_ticks_usec()

	print("\n🎨 Generando mapa de biomas...")
	print("   Seed: %d" % world_seed)
	print("   Offset: %s" % camera_offset)

	# Estadísticas de biomas
	var biome_stats = {}
	for i in range(biome_names.size()):
		biome_stats[i] = 0

	# Generar píxel por píxel
	for y in range(visualization_size.y):
		for x in range(visualization_size.x):
			var world_x = (x + camera_offset.x) * zoom_level
			var world_y = (y + camera_offset.y) * zoom_level

			var biome_type = _get_biome_at_position(world_x, world_y)
			var color = biome_colors[biome_type]

			image.set_pixel(x, y, color)
			biome_stats[biome_type] += 1

	# Actualizar textura
	texture.update(image)

	var elapsed = (Time.get_ticks_usec() - start_time) / 1000.0
	print("✅ Generación completada en %.2f ms" % elapsed)

	# Mostrar estadísticas
	print("\n📊 Distribución de biomas:")
	var total_pixels = visualization_size.x * visualization_size.y
	for biome_type in biome_stats.keys():
		var count = biome_stats[biome_type]
		var percentage = (count * 100.0) / total_pixels
		print("   %s: %.1f%% (%d px)" % [biome_names[biome_type], percentage, count])

	queue_redraw()

func _get_biome_at_position(x: float, y: float) -> int:
	"""Obtener tipo de bioma en posición (con Voronoi + Domain Warp + Detail)"""

	# Cellular noise (región Voronoi)
	var cellular_value = cellular_noise.get_noise_2d(x, y)
	cellular_value = (cellular_value + 1.0) / 2.0  # Normalizar a 0-1

	# Detail noise (variación fina)
	var combined = cellular_value
	if use_detail_noise:
		var detail_value = detail_noise.get_noise_2d(x, y)
		detail_value = (detail_value + 1.0) / 2.0
		combined = cellular_value * (1.0 - detail_influence) + detail_value * detail_influence

	# Mapear a tipo de bioma
	var biome_count = biome_colors.size()
	var biome_index = int(combined * biome_count)
	return clamp(biome_index, 0, biome_count - 1)

# ========== INPUT ==========

func _input(event: InputEvent) -> void:
	# Regenerar con nueva seed
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		world_seed = randi()
		cellular_noise.seed = world_seed
		detail_noise.seed = world_seed + 1
		_generate_biome_map()

	# Zoom
	if event is InputEventKey and event.pressed and event.keycode == KEY_EQUAL:
		zoom_level *= 0.9
		print("🔍 Zoom: %.2f" % zoom_level)
		_generate_biome_map()

	if event is InputEventKey and event.pressed and event.keycode == KEY_MINUS:
		zoom_level *= 1.1
		print("🔍 Zoom: %.2f" % zoom_level)
		_generate_biome_map()

	# Mover cámara
	if event is InputEventKey and event.pressed:
		var move_speed = 50.0 * zoom_level
		match event.keycode:
			KEY_W:
				camera_offset.y -= move_speed
				_generate_biome_map()
			KEY_S:
				camera_offset.y += move_speed
				_generate_biome_map()
			KEY_A:
				camera_offset.x -= move_speed
				_generate_biome_map()
			KEY_D:
				camera_offset.x += move_speed
				_generate_biome_map()

	# Toggle grid
	if event is InputEventKey and event.pressed and event.keycode == KEY_G:
		show_grid = not show_grid
		queue_redraw()

	# Toggle info
	if event is InputEventKey and event.pressed and event.keycode == KEY_I:
		show_info = not show_info
		queue_redraw()

	# Salir
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().quit()

# ========== DIBUJO ==========

func _draw() -> void:
	if show_grid:
		_draw_grid()

	if show_info:
		_draw_info()

func _draw_grid() -> void:
	"""Dibujar grid de referencia"""
	var grid_size = 100 * pixel_size
	var color = Color(1, 1, 1, 0.2)

	# Líneas verticales
	for x in range(0, visualization_size.x * pixel_size, grid_size):
		draw_line(Vector2(x, 0), Vector2(x, visualization_size.y * pixel_size), color, 1.0)

	# Líneas horizontales
	for y in range(0, visualization_size.y * pixel_size, grid_size):
		draw_line(Vector2(0, y), Vector2(visualization_size.x * pixel_size, y), color, 1.0)

func _draw_info() -> void:
	"""Dibujar información en pantalla"""
	var font_size = 16
	var y_offset = 10
	var line_height = 20

	var info_lines = [
		"Seed: %d" % world_seed,
		"Zoom: %.2fx" % zoom_level,
		"Offset: (%.0f, %.0f)" % [camera_offset.x, camera_offset.y],
		"",
		"Cellular Freq: %.4f" % cellular_frequency,
		"Cellular Jitter: %.2f" % cellular_jitter,
		"",
		"Warp: %s" % ("ON" if use_domain_warp else "OFF"),
		"Warp Amp: %.1f" % warp_amplitude if use_domain_warp else "",
		"",
		"Detail: %s" % ("ON" if use_detail_noise else "OFF"),
		"Detail Influence: %.2f" % detail_influence if use_detail_noise else "",
	]

	# Fondo semitransparente
	var bg_height = info_lines.size() * line_height + 20
	draw_rect(Rect2(5, 5, 250, bg_height), Color(0, 0, 0, 0.7))

	# Texto
	for i in range(info_lines.size()):
		var line = info_lines[i]
		if line != "":
			draw_string(ThemeDB.fallback_font, Vector2(10, y_offset + (i + 1) * line_height), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

# ========== ACTUALIZACIÓN DE PARÁMETROS ==========

func _process(_delta: float) -> void:
	# Detectar cambios en parámetros del Inspector
	# (En Godot, si cambias valores en Inspector durante runtime, se llama a _set())
	pass

# test_voronoi_visualization.gd
# Script de prueba para visualizar el sistema Voronoi antes de integrarlo
# Crea una ventana de 800×600 mostrando cómo se ven los biomas orgánicos

extends Node2D

# Configuración
@export var visualization_width: int = 800
@export var visualization_height: int = 600
@export var world_scale: float = 20.0  # Cuántos píxeles del mundo por píxel de pantalla
@export var show_grid: bool = true
@export var show_info: bool = true

var biome_generator: Node = null
var camera_offset: Vector2 = Vector2.ZERO
var zoom_level: float = 1.0

# Estadísticas
var biome_stats: Dictionary = {}
var last_regenerate_time: int = 0

func _ready() -> void:
	print("[VoronoiTest] Inicializando visualización de prueba...")

	# Cargar BiomeGeneratorOrganic
	if ResourceLoader.exists("res://scripts/core/BiomeGeneratorOrganic.gd"):
		var bg_script = load("res://scripts/core/BiomeGeneratorOrganic.gd")
		biome_generator = bg_script.new()
		biome_generator.seed_value = 0  # Aleatorio
		add_child(biome_generator)
		print("[VoronoiTest] ✅ BiomeGeneratorOrganic cargado")
	else:
		printerr("[VoronoiTest] ❌ BiomeGeneratorOrganic.gd no encontrado")
		return

	# Generar visualización inicial
	_regenerate_visualization()

	print("[VoronoiTest] ✅ Visualización lista")
	print("[VoronoiTest] Controles:")
	print("  - R: Regenerar con nuevo seed")
	print("  - WASD: Mover cámara")
	print("  - +/-: Zoom in/out")
	print("  - G: Alternar grid")
	print("  - I: Alternar info")
	print("  - ESC: Salir")

func _process(_delta: float) -> void:
	# Controles
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

	if Input.is_key_pressed(KEY_R):
		_regenerate_visualization()

	# Movimiento de cámara
	var move_speed = 10.0
	if Input.is_key_pressed(KEY_W):
		camera_offset.y -= move_speed
		queue_redraw()
	if Input.is_key_pressed(KEY_S):
		camera_offset.y += move_speed
		queue_redraw()
	if Input.is_key_pressed(KEY_A):
		camera_offset.x -= move_speed
		queue_redraw()
	if Input.is_key_pressed(KEY_D):
		camera_offset.x += move_speed
		queue_redraw()

	# Zoom
	if Input.is_key_pressed(KEY_EQUAL) or Input.is_key_pressed(KEY_PLUS):
		zoom_level = min(zoom_level * 1.05, 5.0)
		queue_redraw()
	if Input.is_key_pressed(KEY_MINUS):
		zoom_level = max(zoom_level * 0.95, 0.2)
		queue_redraw()

	# Alternar opciones
	if Input.is_key_pressed(KEY_G):
		show_grid = not show_grid
		queue_redraw()
		await get_tree().create_timer(0.2).timeout

	if Input.is_key_pressed(KEY_I):
		show_info = not show_info
		queue_redraw()
		await get_tree().create_timer(0.2).timeout

func _regenerate_visualization() -> void:
	"""Regenerar con nuevo seed"""
	if Time.get_ticks_msec() - last_regenerate_time < 500:
		return  # Evitar spam

	last_regenerate_time = Time.get_ticks_msec()

	# Nuevo seed aleatorio
	randomize()
	var new_seed = randi()
	biome_generator.cellular_noise.seed = new_seed

	print("[VoronoiTest] 🎲 Regenerado con seed: %d" % new_seed)

	# Calcular estadísticas
	_calculate_biome_stats()

	queue_redraw()

func _calculate_biome_stats() -> void:
	"""Calcular distribución de biomas en el área visible"""
	biome_stats.clear()

	var samples = 100  # 100×100 muestras
	var total_samples = samples * samples

	for sy in range(samples):
		for sx in range(samples):
			var world_x = (sx * visualization_width / float(samples)) * world_scale
			var world_y = (sy * visualization_height / float(samples)) * world_scale

			var biome = biome_generator.get_biome_at_world_position(world_x, world_y)

			if not biome_stats.has(biome):
				biome_stats[biome] = 0
			biome_stats[biome] += 1

	# Convertir a porcentajes
	for biome in biome_stats.keys():
		biome_stats[biome] = (biome_stats[biome] * 100.0) / total_samples

func _draw() -> void:
	"""Dibujar visualización"""
	if biome_generator == null:
		return

	# Limpiar
	draw_rect(Rect2(0, 0, visualization_width, visualization_height), Color.BLACK)

	# Dibujar biomas píxel por píxel (con sampling reducido para performance)
	var pixel_size = 2  # Cada "píxel" es 2×2 px de pantalla

	for py in range(0, visualization_height, pixel_size):
		for px in range(0, visualization_width, pixel_size):
			# Calcular posición mundial
			var world_x = ((px + camera_offset.x) * world_scale) / zoom_level
			var world_y = ((py + camera_offset.y) * world_scale) / zoom_level

			# Obtener bioma
			var biome_color = biome_generator.get_biome_color_at_world_position(world_x, world_y)

			# Dibujar píxel
			draw_rect(Rect2(px, py, pixel_size, pixel_size), biome_color)

	# Dibujar grid opcional
	if show_grid:
		_draw_grid()

	# Dibujar info
	if show_info:
		_draw_info()

func _draw_grid() -> void:
	"""Dibujar grid de referencia"""
	var grid_spacing = 100

	# Líneas verticales
	for x in range(0, visualization_width, grid_spacing):
		draw_line(Vector2(x, 0), Vector2(x, visualization_height), Color(1, 1, 1, 0.2), 1.0)

	# Líneas horizontales
	for y in range(0, visualization_height, grid_spacing):
		draw_line(Vector2(0, y), Vector2(visualization_width, y), Color(1, 1, 1, 0.2), 1.0)

func _draw_info() -> void:
	"""Dibujar información en pantalla"""
	var y_offset = 10
	var line_height = 20

	# Fondo semi-transparente
	draw_rect(Rect2(10, 10, 300, 200), Color(0, 0, 0, 0.7))

	# Texto
	var info_lines = [
		"VORONOI BIOME VISUALIZATION",
		"",
		"Seed: %d" % biome_generator.cellular_noise.seed,
		"Zoom: %.2fx" % zoom_level,
		"Offset: (%.0f, %.0f)" % [camera_offset.x, camera_offset.y],
		"",
		"Biome Distribution:"
	]

	for biome_id in biome_stats.keys():
		var biome_name = biome_generator.BIOME_NAMES.get(biome_id, "Unknown")
		var percentage = biome_stats[biome_id]
		info_lines.append("  %s: %.1f%%" % [biome_name, percentage])

	for i in range(info_lines.size()):
		_draw_text_with_shadow(
			info_lines[i],
			Vector2(20, y_offset + line_height + i * line_height),
			Color.WHITE
		)

func _draw_text_with_shadow(text: String, pos: Vector2, color: Color) -> void:
	"""Dibujar texto con sombra para mejor legibilidad"""
	# Sombra
	draw_string(
		ThemeDB.fallback_font,
		pos + Vector2(1, 1),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		Color.BLACK
	)
	# Texto
	draw_string(
		ThemeDB.fallback_font,
		pos,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		16,
		color
	)

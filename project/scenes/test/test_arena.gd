# test_arena.gd
# Escena de prueba para visualizar el ArenaManager

extends Node2D

var arena_manager: Node = null
var camera: Camera2D = null
var player_mock: Node2D = null

# Control de cámara
var camera_speed: float = 2000.0
var zoom_speed: float = 0.1
var min_zoom: float = 0.02
var max_zoom: float = 2.0

func _ready() -> void:
	print("🧪 [TestArena] Iniciando test de ArenaManager...")
	
	_setup_camera()
	_setup_mock_player()
	_setup_arena()
	_setup_ui()

func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.name = "TestCamera"
	camera.enabled = true
	camera.zoom = Vector2(0.1, 0.1)  # Zoom out para ver toda la arena
	add_child(camera)

func _setup_mock_player() -> void:
	# Crear un "player" falso para que el ArenaManager tenga referencia
	player_mock = Node2D.new()
	player_mock.name = "MockPlayer"
	add_child(player_mock)
	
	# Añadir visual al player mock
	var player_visual = Node2D.new()
	player_visual.name = "PlayerVisual"
	player_mock.add_child(player_visual)
	
	# Script para dibujar el player
	var script = GDScript.new()
	script.source_code = """
extends Node2D

func _draw():
	# Círculo del player
	draw_circle(Vector2.ZERO, 50, Color.GREEN)
	# Dirección
	draw_line(Vector2.ZERO, Vector2(80, 0), Color.WHITE, 3)
"""
	script.reload()
	player_visual.set_script(script)

func _setup_arena() -> void:
	# Crear nodo raíz para la arena
	var arena_root = Node2D.new()
	arena_root.name = "ArenaRoot"
	add_child(arena_root)
	
	# Crear ArenaManager
	var am_script = load("res://scripts/core/ArenaManager.gd")
	if am_script:
		arena_manager = am_script.new()
		arena_manager.name = "ArenaManager"
		add_child(arena_manager)
		
		# Inicializar
		arena_manager.initialize(player_mock, arena_root)
		
		# Conectar señales
		arena_manager.arena_ready.connect(_on_arena_ready)
		arena_manager.player_zone_changed.connect(_on_player_zone_changed)
		
		print("✅ ArenaManager creado e inicializado")
	else:
		push_error("❌ No se pudo cargar ArenaManager.gd")

func _setup_ui() -> void:
	# Crear UI de instrucciones
	var ui_layer = CanvasLayer.new()
	ui_layer.layer = 100
	add_child(ui_layer)
	
	var instructions = Label.new()
	instructions.text = """
🏟️ TEST ARENA MANAGER

Controles:
[WASD / Flechas] - Mover player/cámara
[Scroll / +/-] - Zoom
[R] - Reset posición al centro
[1-4] - Ir a zona (Safe, Medium, Danger, Death)
[SPACE] - Regenerar arena (nuevo seed)
[ESC] - Salir

Info:
- Radio total: 10,000 px
- Safe Zone: 0 - 2,500 px
- Medium Zone: 2,500 - 5,500 px  
- Danger Zone: 5,500 - 8,500 px
- Death Zone: 8,500 - 10,000 px
"""
	instructions.position = Vector2(20, 20)
	instructions.add_theme_font_size_override("font_size", 16)
	instructions.add_theme_color_override("font_color", Color.WHITE)
	ui_layer.add_child(instructions)
	
	# Label de info de posición
	var pos_label = Label.new()
	pos_label.name = "PosLabel"
	pos_label.position = Vector2(20, 350)
	pos_label.add_theme_font_size_override("font_size", 18)
	pos_label.add_theme_color_override("font_color", Color.YELLOW)
	ui_layer.add_child(pos_label)

func _on_arena_ready(arena_data: Dictionary) -> void:
	print("🏟️ Arena lista:")
	print("   Seed: %d" % arena_data.seed)
	print("   Radio: %.0f px" % arena_data.radius)
	for zone_name in arena_data.zones.keys():
		var zone = arena_data.zones[zone_name]
		print("   %s: %s (r=%.0f)" % [zone_name.capitalize(), zone.biome, zone.radius])

func _on_player_zone_changed(zone_id: int, zone_name: String) -> void:
	print("📍 Player entró en: %s" % zone_name)

func _process(delta: float) -> void:
	_handle_input(delta)
	_update_ui()

func _handle_input(delta: float) -> void:
	# Movimiento del player mock (y cámara lo sigue)
	var move_dir = Vector2.ZERO
	
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		move_dir.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		move_dir.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		move_dir.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		move_dir.y += 1
	
	if move_dir != Vector2.ZERO:
		move_dir = move_dir.normalized()
		player_mock.position += move_dir * camera_speed * delta
		camera.position = player_mock.position

func _unhandled_input(event: InputEvent) -> void:
	# Zoom con scroll
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom *= 1.1
			camera.zoom = camera.zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom *= 0.9
			camera.zoom = camera.zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
	
	# Teclas
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_EQUAL, KEY_KP_ADD:
				camera.zoom *= 1.2
				camera.zoom = camera.zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
			KEY_MINUS, KEY_KP_SUBTRACT:
				camera.zoom *= 0.8
				camera.zoom = camera.zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
			KEY_R:
				# Reset al centro
				player_mock.position = Vector2.ZERO
				camera.position = Vector2.ZERO
				print("🔄 Posición reseteada al centro")
			KEY_1:
				# Ir a Safe Zone
				player_mock.position = Vector2(1000, 0)
				camera.position = player_mock.position
			KEY_2:
				# Ir a Medium Zone
				player_mock.position = Vector2(4000, 0)
				camera.position = player_mock.position
			KEY_3:
				# Ir a Danger Zone
				player_mock.position = Vector2(7000, 0)
				camera.position = player_mock.position
			KEY_4:
				# Ir a Death Zone
				player_mock.position = Vector2(9500, 0)
				camera.position = player_mock.position
			KEY_SPACE:
				# Regenerar arena con nuevo seed
				_regenerate_arena()
			KEY_ESCAPE:
				get_tree().quit()

func _regenerate_arena() -> void:
	print("🔄 Regenerando arena con nuevo seed...")
	
	# Eliminar arena actual
	if arena_manager:
		arena_manager.queue_free()
	
	# Esperar un frame
	await get_tree().process_frame
	
	# Buscar y eliminar ArenaRoot existente
	var old_root = get_node_or_null("ArenaRoot")
	if old_root:
		old_root.queue_free()
	
	await get_tree().process_frame
	
	# Recrear
	_setup_arena()

func _update_ui() -> void:
	var pos_label = get_node_or_null("CanvasLayer/PosLabel")
	if pos_label and arena_manager:
		var pos = player_mock.position
		var dist = pos.length()
		var zone = arena_manager.get_player_zone_name()
		var biome = arena_manager.get_biome_at_position(pos)
		var diff_mult = arena_manager.get_difficulty_multiplier_at_position(pos)
		
		pos_label.text = "Pos: (%.0f, %.0f)\nDist: %.0f px\nZona: %s\nBioma: %s\nDificultad: x%.1f" % [
			pos.x, pos.y, dist, zone, biome, diff_mult
		]

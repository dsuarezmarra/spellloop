# test_boss_sprites.gd
# Escena de prueba para visualizar los sprites de bosses animados
# con sus efectos especiales (aura, movimientos lentos, escala mayor)

extends Node2D

const BOSSES_PATH = "res://assets/sprites/enemies/bosses/"

# Lista de bosses con sus colores de aura personalizados (MÁS VIBRANTES)
const BOSSES = [
	{
		"name": "el_conjurador_primigenio",
		"display_name": "El Conjurador Primigenio",
		"aura_color": Color(0.8, 0.3, 1.0, 1.0)  # Púrpura brillante
	},
	{
		"name": "el_corazon_del_vacio",
		"display_name": "El Corazón del Vacío",
		"aura_color": Color(0.3, 0.5, 1.0, 1.0)  # Azul eléctrico
	},
	{
		"name": "el_guardian_de_runas",
		"display_name": "El Guardián de Runas",
		"aura_color": Color(1.0, 0.85, 0.2, 1.0)  # Dorado brillante
	},
	{
		"name": "minotauro_de_fuego",
		"display_name": "Minotauro de Fuego",
		"aura_color": Color(1.0, 0.4, 0.1, 1.0)  # Naranja fuego
	}
]

var spawned_bosses: Array = []

func _ready() -> void:
	_setup_background()
	_setup_title()
	_spawn_bosses()
	_setup_instructions()

func _setup_background() -> void:
	# Fondo oscuro para que el aura se vea mejor
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -100
	
	var canvas = CanvasLayer.new()
	canvas.layer = -10
	canvas.add_child(bg)
	add_child(canvas)

func _setup_title() -> void:
	var title = Label.new()
	title.text = "🔥 BOSSES - Test de Animación 🔥"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(640, 30)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.GOLD)
	add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Efectos: Aura Brillante + Partículas Orbitales + Bobbing Lento + Breathing\nEscala: 0.35 (casi el doble que enemigos normales)"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(640, 70)
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	add_child(subtitle)

func _spawn_bosses() -> void:
	var start_x = 200
	var spacing = 300
	var y_pos = 350
	
	for i in range(BOSSES.size()):
		var boss_data = BOSSES[i]
		var x_pos = start_x + i * spacing
		
		_spawn_boss(boss_data, Vector2(x_pos, y_pos))

func _spawn_boss(boss_data: Dictionary, pos: Vector2) -> void:
	var spritesheet_path = BOSSES_PATH + boss_data.name + "_spritesheet.png"
	
	# Crear el sprite de boss
	var boss_sprite = AnimatedBossSprite.new()
	boss_sprite.position = pos
	boss_sprite.set_aura_color(boss_data.aura_color)
	
	add_child(boss_sprite)
	
	# Cargar el spritesheet
	if boss_sprite.load_spritesheet(spritesheet_path):
		spawned_bosses.append(boss_sprite)
		print("✅ Boss cargado: %s" % boss_data.display_name)
		
		# Label con el nombre del boss
		var label = Label.new()
		label.text = boss_data.display_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(pos.x, pos.y + 120)
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", boss_data.aura_color)
		add_child(label)
	else:
		push_error("❌ Error cargando boss: %s" % boss_data.name)

func _setup_instructions() -> void:
	var instructions = Label.new()
	instructions.text = """
Controles:
[1-4] Cambiar dirección (Down, Left, Right, Up)
[A] Toggle Aura ON/OFF
[P] Toggle Partículas ON/OFF
[+/-] Aumentar/Reducir escala
[R] Resetear
[ESC] Salir
"""
	instructions.position = Vector2(50, 500)
	instructions.add_theme_font_size_override("font_size", 14)
	instructions.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	add_child(instructions)

var selected_boss_index: int = 0

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_set_all_directions("down")
			KEY_2:
				_set_all_directions("left")
			KEY_3:
				_set_all_directions("right")
			KEY_4:
				_set_all_directions("up")
			KEY_A:
				_toggle_aura()
			KEY_P:
				_toggle_particles()
			KEY_EQUAL, KEY_KP_ADD:
				_change_scale(0.05)
			KEY_MINUS, KEY_KP_SUBTRACT:
				_change_scale(-0.05)
			KEY_R:
				_reset_bosses()
			KEY_ESCAPE:
				get_tree().quit()

func _set_all_directions(dir: String) -> void:
	for boss in spawned_bosses:
		boss.set_direction_string(dir)
	print("Dirección: %s" % dir)

func _toggle_aura() -> void:
	for boss in spawned_bosses:
		boss.set_aura_enabled(!boss.enable_aura)
	print("Aura: %s" % ("ON" if spawned_bosses[0].enable_aura else "OFF"))

func _toggle_particles() -> void:
	for boss in spawned_bosses:
		boss.enable_particles = !boss.enable_particles
		# Ocultar/mostrar partículas existentes
		for particle in boss.particles:
			if is_instance_valid(particle):
				particle.visible = boss.enable_particles
	print("Partículas: %s" % ("ON" if spawned_bosses[0].enable_particles else "OFF"))

func _change_scale(delta: float) -> void:
	for boss in spawned_bosses:
		var new_scale = clamp(boss.sprite_scale + delta, 0.1, 1.0)
		boss.sprite_scale = new_scale
	print("Escala: %.2f" % spawned_bosses[0].sprite_scale)

func _reset_bosses() -> void:
	for boss in spawned_bosses:
		boss.sprite_scale = 0.35
		boss.set_aura_enabled(true)
		boss.set_direction_string("down")
	print("Bosses reseteados")

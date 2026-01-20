extends Control
class_name GameOverScreen

## Pantalla de Game Over
## Muestra estadisticas de la partida y opciones
## NAVEGACION: Solo WASD y gamepad (NO flechas de direccion)

signal retry_pressed
signal menu_pressed

@onready var stats_container: VBoxContainer = $Panel/VBoxContainer/StatsContainer
@onready var retry_button: Button = $Panel/VBoxContainer/ButtonsContainer/RetryButton
@onready var menu_button: Button = $Panel/VBoxContainer/ButtonsContainer/MenuButton
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel

# Stats de la partida
var final_stats: Dictionary = {}

# Sistema de navegacion WASD
var buttons: Array[Button] = []
var current_button_index: int = 0

func _ready() -> void:
	_connect_signals()
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _connect_signals() -> void:
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

func show_game_over(stats: Dictionary = {}) -> void:
	final_stats = stats
	visible = true
	get_tree().paused = true

	_display_stats()
	_setup_wasd_navigation()

	# Animacion de entrada
	modulate.a = 0
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

	_play_game_over_sound()

func _setup_wasd_navigation() -> void:
	"""Configurar navegacion WASD"""
	buttons.clear()

	if retry_button:
		buttons.append(retry_button)
		# Desactivar navegacion por flechas
		retry_button.focus_neighbor_top = retry_button.get_path()
		retry_button.focus_neighbor_bottom = retry_button.get_path()
		retry_button.focus_neighbor_left = retry_button.get_path()
		retry_button.focus_neighbor_right = retry_button.get_path()

	if menu_button:
		buttons.append(menu_button)
		menu_button.focus_neighbor_top = menu_button.get_path()
		menu_button.focus_neighbor_bottom = menu_button.get_path()
		menu_button.focus_neighbor_left = menu_button.get_path()
		menu_button.focus_neighbor_right = menu_button.get_path()

	current_button_index = 0
	if buttons.size() > 0:
		buttons[0].grab_focus()

func _input(event: InputEvent) -> void:
	if not visible:
		return

	var handled = false

	# Navegacion con teclado WASD + Flechas
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_A, KEY_W, KEY_LEFT, KEY_UP:
				_navigate(-1)
				handled = true
			KEY_D, KEY_S, KEY_RIGHT, KEY_DOWN:
				_navigate(1)
				handled = true
			KEY_SPACE, KEY_ENTER:
				_activate_current()
				handled = true

	# Soporte para gamepad
	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_UP:
				_navigate(-1)
				handled = true
			JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_DOWN:
				_navigate(1)
				handled = true
			JOY_BUTTON_A:
				_activate_current()
				handled = true

	# Soporte para joystick analogico
	if event is InputEventJoypadMotion:
		if event.axis == JOY_AXIS_LEFT_X or event.axis == JOY_AXIS_LEFT_Y:
			if event.axis_value < -0.5:
				_navigate(-1)
				handled = true
			elif event.axis_value > 0.5:
				_navigate(1)
				handled = true

	if handled:
		var vp = get_viewport()
		if vp:
			vp.set_input_as_handled()

func _navigate(direction: int) -> void:
	if buttons.is_empty():
		return

	current_button_index = wrapi(current_button_index + direction, 0, buttons.size())
	buttons[current_button_index].grab_focus()

func _activate_current() -> void:
	if buttons.is_empty():
		return

	var current = buttons[current_button_index]
	if current:
		current.pressed.emit()

func _display_stats() -> void:
	if not stats_container:
		return

	# Limpiar stats anteriores
	for child in stats_container.get_children():
		child.queue_free()

	# Tiempo sobrevivido
	var time_survived = final_stats.get("time", 0.0)
	var minutes = int(time_survived) / 60
	var seconds = int(time_survived) % 60
	_add_stat_line("⏱️ Tiempo", "%02d:%02d" % [minutes, seconds])

	# Nivel alcanzado
	var level = final_stats.get("level", 1)
	_add_stat_line("⭐ Nivel", str(level))

	# Enemigos eliminados
	var kills = final_stats.get("kills", 0)
	_add_stat_line("💀 Enemigos", str(kills))

	# XP total obtenida
	var xp = final_stats.get("xp_total", 0)
	_add_stat_line("✨ XP Total", str(xp))

	# Oro recogido
	var gold = final_stats.get("gold", 0)
	if gold > 0:
		_add_stat_line("🪙 Oro", str(gold))

	# Daño total
	var damage = final_stats.get("damage_dealt", 0)
	if damage > 0:
		_add_stat_line("⚔️ Daño Total", str(damage))

func _add_stat_line(label_text: String, value_text: String) -> void:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 18)

	var value = Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_font_size_override("font_size", 18)
	value.add_theme_color_override("font_color", Color(1, 0.9, 0.5))

	hbox.add_child(label)
	hbox.add_child(value)
	stats_container.add_child(hbox)

func _on_retry_pressed() -> void:
	_play_button_sound()
	retry_pressed.emit()
	# La transición de escena se maneja en Game.gd

func _on_menu_pressed() -> void:
	_play_button_sound()
	menu_pressed.emit()
	# La transición de escena se maneja en Game.gd

func _play_button_sound() -> void:
	var tree = get_tree()
	if tree and tree.root:
		var audio_manager = tree.root.get_node_or_null("AudioManager")
		if audio_manager and audio_manager.has_method("play_sfx"):
			audio_manager.play_sfx("ui_click")

func _play_game_over_sound() -> void:
	var tree = get_tree()
	if tree and tree.root:
		var audio_manager = tree.root.get_node_or_null("AudioManager")
		if audio_manager and audio_manager.has_method("play_sfx"):
			audio_manager.play_sfx("game_over")

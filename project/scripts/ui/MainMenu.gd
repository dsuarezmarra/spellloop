extends Control
class_name MainMenu

## Menu principal del juego
## Gestiona: Jugar/Reanudar, Opciones, Creditos, Salir
## NAVEGACION: Solo WASD y gamepad (NO flechas de direccion)

signal play_pressed
signal resume_pressed
signal options_pressed
signal quit_pressed

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $TitleLabel
@onready var version_label: Label = $VersionLabel

# Se crea dinámicamente si hay partida activa
var resume_button: Button = null

# Sistema de navegacion WASD
var menu_buttons: Array[Button] = []
var current_button_index: int = 0

const GAME_VERSION = "0.1.0-alpha"

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_play_menu_music()
	_update_resume_button()
	_setup_wasd_navigation()

func _setup_ui() -> void:
	if version_label:
		version_label.text = "v" + GAME_VERSION

	# Animación de entrada
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

	# Focus en el botón apropiado
	_set_initial_focus()

func _update_resume_button() -> void:
	"""Mostrar u ocultar el boton de reanudar segun el estado del juego"""
	# Crear boton de reanudar si no existe
	if not resume_button:
		_create_resume_button()

	# Verificar si hay partida activa que se pueda reanudar
	var can_resume_game = SessionState.can_resume() if SessionState else false

	if resume_button:
		resume_button.visible = can_resume_game
		if can_resume_game and SessionState:
			resume_button.text = ">> Reanudar (%s)" % SessionState.get_paused_time_formatted()

	# Actualizar texto del botón de jugar
	if play_button:
		if can_resume_game:
			play_button.text = "🎮 Nueva Partida"
		else:
			play_button.text = "🎮 Jugar"

func _create_resume_button() -> void:
	"""Crear el boton de reanudar dinamicamente si no existe en la escena"""
	if play_button and play_button.get_parent():
		var parent = play_button.get_parent()
		resume_button = Button.new()
		resume_button.name = "ResumeButton"
		resume_button.text = ">> Reanudar"
		resume_button.custom_minimum_size = play_button.custom_minimum_size
		resume_button.visible = false

		# Copiar tamanio de fuente del boton de jugar
		if play_button.has_theme_font_size_override("font_size"):
			resume_button.add_theme_font_size_override("font_size", play_button.get_theme_font_size("font_size"))
		else:
			resume_button.add_theme_font_size_override("font_size", 24)

		# Insertar antes del boton de jugar
		var play_index = parent.get_child_count()
		for i in parent.get_child_count():
			if parent.get_child(i) == play_button:
				play_index = i
				break
		parent.add_child(resume_button)
		parent.move_child(resume_button, play_index)

		resume_button.pressed.connect(_on_resume_pressed)

func _set_initial_focus() -> void:
	"""Establecer foco en el boton apropiado"""
	if not is_inside_tree():
		return
	await get_tree().process_frame
	_update_button_list()
	_highlight_current_button()

func _setup_wasd_navigation() -> void:
	"""Configurar navegacion WASD y desactivar flechas"""
	if not is_inside_tree():
		return
	await get_tree().process_frame
	_update_button_list()

	# Desactivar navegacion por flechas en todos los botones
	for btn in menu_buttons:
		if btn and is_instance_valid(btn):
			btn.focus_neighbor_top = btn.get_path()
			btn.focus_neighbor_bottom = btn.get_path()
			btn.focus_neighbor_left = btn.get_path()
			btn.focus_neighbor_right = btn.get_path()

	_highlight_current_button()

func _update_button_list() -> void:
	"""Actualizar lista de botones navegables"""
	menu_buttons.clear()

	# Agregar botones en orden (verificar que existan y sean validos)
	if resume_button and is_instance_valid(resume_button) and resume_button.visible:
		menu_buttons.append(resume_button)
	if play_button and is_instance_valid(play_button):
		menu_buttons.append(play_button)
	if options_button and is_instance_valid(options_button):
		menu_buttons.append(options_button)
	if quit_button and is_instance_valid(quit_button):
		menu_buttons.append(quit_button)

	# Resetear indice si es necesario
	if current_button_index >= menu_buttons.size():
		current_button_index = 0

func _highlight_current_button() -> void:
	"""Dar foco al boton actual"""
	if menu_buttons.size() > 0 and current_button_index < menu_buttons.size():
		var btn = menu_buttons[current_button_index]
		if btn and is_instance_valid(btn):
			btn.grab_focus()

func _connect_signals() -> void:
	if play_button and not play_button.pressed.is_connected(_on_play_pressed):
		play_button.pressed.connect(_on_play_pressed)
	if resume_button and not resume_button.pressed.is_connected(_on_resume_pressed):
		resume_button.pressed.connect(_on_resume_pressed)
	if options_button and not options_button.pressed.is_connected(_on_options_pressed):
		options_button.pressed.connect(_on_options_pressed)
	if quit_button and not quit_button.pressed.is_connected(_on_quit_pressed):
		quit_button.pressed.connect(_on_quit_pressed)

func _play_menu_music() -> void:
	# Menu music not implemented yet - would use AudioManager.play_music("music_menu")
	pass

func _get_audio_manager() -> Node:
	var tree = get_tree()
	if tree and tree.root:
		return tree.root.get_node_or_null("AudioManager")
	return null

# Referencia a la pantalla de selección de slot
var slot_select_screen: Control = null
var character_select_screen: Control = null
var _pending_slot_index: int = 0

func _on_play_pressed() -> void:
	_play_button_sound()
	play_pressed.emit()

	# Mostrar pantalla de selección de slot
	_show_slot_select()

func _show_slot_select() -> void:
	"""Mostrar pantalla de selección de slot de guardado"""
	if slot_select_screen and is_instance_valid(slot_select_screen):
		slot_select_screen.visible = true
		slot_select_screen.refresh()
		return

	# Cargar la escena de selección de slot
	var slot_scene = load("res://scenes/ui/SaveSlotSelect.tscn")
	if not slot_scene:
		push_warning("[MainMenu] No se pudo cargar SaveSlotSelect.tscn")
		# Fallback: iniciar juego directamente
		_start_game_with_default_slot()
		return

	slot_select_screen = slot_scene.instantiate()
	add_child(slot_select_screen)

	# Conectar señales
	slot_select_screen.slot_selected.connect(_on_slot_selected)
	slot_select_screen.back_pressed.connect(_on_slot_back)

	# Ocultar el menú principal mientras se muestra la selección
	$VBoxContainer.visible = false
	$TitleLabel.visible = false
	if has_node("SubtitleLabel"):
		$SubtitleLabel.visible = false

func _on_slot_selected(slot_index: int) -> void:
	"""Callback cuando se selecciona un slot"""
	_pending_slot_index = slot_index

	# Activar el slot en SaveManager
	var save_manager = get_tree().root.get_node_or_null("SaveManager")
	if save_manager and save_manager.has_method("set_active_slot"):
		save_manager.set_active_slot(slot_index)

	# Guardar slot en SessionState
	if SessionState:
		SessionState.set_save_slot(slot_index)

	# Ocultar pantalla de slots y mostrar selección de personaje
	if slot_select_screen:
		slot_select_screen.visible = false

	_show_character_select()

func _show_character_select() -> void:
	"""Mostrar pantalla de selección de personaje"""
	if character_select_screen and is_instance_valid(character_select_screen):
		character_select_screen.visible = true
		if character_select_screen.has_method("show_screen"):
			character_select_screen.show_screen()
		return

	# Cargar la escena de selección de personaje
	var char_scene = load("res://scenes/ui/CharacterSelectScreen.tscn")
	if not char_scene:
		push_warning("[MainMenu] No se pudo cargar CharacterSelectScreen.tscn")
		# Fallback: iniciar juego con personaje por defecto
		_start_game_with_default_character()
		return

	character_select_screen = char_scene.instantiate()
	add_child(character_select_screen)

	# Mostrar la pantalla
	character_select_screen.show_screen()

	# Conectar señales
	character_select_screen.character_selected.connect(_on_character_selected)
	character_select_screen.back_pressed.connect(_on_character_back)

func _on_character_selected(character_id: String) -> void:
	"""Callback cuando se selecciona un personaje"""
	# Guardar personaje en SessionState
	if SessionState:
		SessionState.start_new_game(_pending_slot_index, character_id)

	# Iniciar juego
	_start_game()

func _on_character_back() -> void:
	"""Callback cuando se vuelve de la selección de personaje"""
	# Ocultar pantalla de personajes
	if character_select_screen:
		character_select_screen.visible = false

	# Mostrar pantalla de slots
	if slot_select_screen:
		slot_select_screen.visible = true
		if slot_select_screen.has_method("refresh"):
			slot_select_screen.refresh()

func _start_game_with_default_character() -> void:
	"""Iniciar juego con personaje por defecto (fallback)"""
	if SessionState:
		SessionState.start_new_game(_pending_slot_index, "frost_mage")
	_start_game()

func _on_slot_back() -> void:
	"""Callback cuando se vuelve de la selección de slot"""
	# Ocultar pantalla de slots
	if slot_select_screen:
		slot_select_screen.visible = false

	# Mostrar menú principal
	$VBoxContainer.visible = true
	$TitleLabel.visible = true
	if has_node("SubtitleLabel"):
		$SubtitleLabel.visible = true

	# Actualizar navegación
	_update_button_list()
	_highlight_current_button()

func _start_game_with_default_slot() -> void:
	"""Iniciar juego con slot por defecto (fallback)"""
	var save_manager = get_tree().root.get_node_or_null("SaveManager")
	if save_manager and save_manager.has_method("set_active_slot"):
		save_manager.set_active_slot(0)
	_start_game()

func _on_resume_pressed() -> void:
	_play_button_sound()
	resume_pressed.emit()
	_resume_game()

func _on_options_pressed() -> void:
	_play_button_sound()
	options_pressed.emit()
	_show_options()

func _on_quit_pressed() -> void:
	_play_button_sound()
	quit_pressed.emit()
	# Pequeña espera para que suene el botón
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()

func _play_button_sound() -> void:
	AudioManager.play("sfx_ui_click")

func _start_game() -> void:
	# Transición con fade
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	# Cambiar a la escena del juego
	get_tree().change_scene_to_file("res://scenes/game/Game.tscn")

func _resume_game() -> void:
	"""Reanudar la partida guardada"""
	# Transicion con fade
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	# Volver a la escena de juego (el estado se restaurara alli)
	var scene_path = "res://scenes/game/Game.tscn"
	if SessionState and SessionState.game_scene_path:
		scene_path = SessionState.game_scene_path
	get_tree().change_scene_to_file(scene_path)

func _show_options() -> void:
	# Buscar o crear el menú de opciones
	var options_menu = get_node_or_null("OptionsMenu")
	if not options_menu:
		var options_scene = load("res://scenes/ui/OptionsMenu.tscn")
		if options_scene:
			options_menu = options_scene.instantiate()
			options_menu.name = "OptionsMenu"
			add_child(options_menu)

	if options_menu:
		options_menu.visible = true
		if options_menu.has_signal("closed"):
			if not options_menu.closed.is_connected(_on_options_closed):
				options_menu.closed.connect(_on_options_closed)

func _on_options_closed() -> void:
	_update_button_list()
	_highlight_current_button()

func _input(event: InputEvent) -> void:
	# Si hay un submenu de opciones abierto, no procesar
	var options_menu = get_node_or_null("OptionsMenu")
	if options_menu and options_menu.visible:
		return

	# Navegacion con teclado WASD
	if event is InputEventKey and event.pressed:
		var handled = false

		match event.keycode:
			KEY_W:
				_navigate_menu(-1)
				handled = true
			KEY_S:
				_navigate_menu(1)
				handled = true
			KEY_SPACE, KEY_ENTER:
				_activate_current_button()
				handled = true
			KEY_ESCAPE:
				if quit_button:
					current_button_index = menu_buttons.find(quit_button)
					_highlight_current_button()
				handled = true

		if handled:
			get_viewport().set_input_as_handled()

	# Soporte para gamepad - botones
	if event is InputEventJoypadButton and event.pressed:
		var handled = false

		match event.button_index:
			JOY_BUTTON_DPAD_UP:
				_navigate_menu(-1)
				handled = true
			JOY_BUTTON_DPAD_DOWN:
				_navigate_menu(1)
				handled = true
			JOY_BUTTON_A:
				_activate_current_button()
				handled = true

		if handled:
			get_viewport().set_input_as_handled()

	# Soporte para joystick analogico
	if event is InputEventJoypadMotion:
		if event.axis == JOY_AXIS_LEFT_Y:
			if event.axis_value < -0.5:
				_navigate_menu(-1)
				get_viewport().set_input_as_handled()
			elif event.axis_value > 0.5:
				_navigate_menu(1)
				get_viewport().set_input_as_handled()

func _navigate_menu(direction: int) -> void:
	"""Navegar entre botones del menu"""
	if menu_buttons.is_empty():
		return

	current_button_index = wrapi(current_button_index + direction, 0, menu_buttons.size())
	AudioManager.play("sfx_ui_hover")
	_highlight_current_button()

func _activate_current_button() -> void:
	"""Activar el boton actualmente seleccionado"""
	if menu_buttons.is_empty():
		return

	var current = menu_buttons[current_button_index]
	if current:
		current.pressed.emit()

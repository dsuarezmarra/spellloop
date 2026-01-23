extends Control

signal closed

# Sistema de navegacion WASD
var focusable_controls: Array[Control] = []
var current_focus_index: int = 0

# Language options
var language_codes: Array[String] = []

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Wire sliders to AudioManager if available
	var am = _get_audio_manager()
	if am:
		var music_slider = get_node_or_null("Panel/VBox/MusicContainer/MusicSlider")
		var sfx_slider = get_node_or_null("Panel/VBox/SFXContainer/SFXSlider")

		if music_slider and am.has_method("get_music_volume"):
			music_slider.value = am.get_music_volume()
			music_slider.value_changed.connect(_on_music_volume_changed)

		if sfx_slider and am.has_method("get_sfx_volume"):
			sfx_slider.value = am.get_sfx_volume()
			sfx_slider.value_changed.connect(_on_sfx_volume_changed)

	# Setup language selector
	_setup_language_selector()

	# Conectar boton de cerrar - buscar en ruta correcta
	var close_button = get_node_or_null("Panel/VBox/CloseButton")
	if close_button:
		if not close_button.pressed.is_connected(_on_close_pressed):
			close_button.pressed.connect(_on_close_pressed)

	# Configurar navegacion WASD
	_setup_wasd_navigation()

func _setup_language_selector() -> void:
	"""Setup the language dropdown with available languages"""
	var language_option = get_node_or_null("Panel/VBox/LanguageContainer/LanguageOption")
	if not language_option:
		return

	language_option.clear()
	language_codes.clear()

	# Get available languages from Localization
	var loc = _get_localization()
	if not loc:
		# Fallback to basic options
		language_option.add_item("English", 0)
		language_option.add_item("Espanol", 1)
		language_codes = ["en", "es"]
		return

	# Add all available languages
	var available = loc.get_available_languages()
	var current_lang = loc.get_current_language()
	var selected_idx = 0

	for i in range(available.size()):
		var lang_code = available[i]
		var lang_info = loc.SUPPORTED_LANGUAGES.get(lang_code, {})
		var display_name = lang_info.get("native", lang_code)
		language_option.add_item(display_name, i)
		language_codes.append(lang_code)

		if lang_code == current_lang:
			selected_idx = i

	language_option.selected = selected_idx

	if not language_option.item_selected.is_connected(_on_language_selected):
		language_option.item_selected.connect(_on_language_selected)

func _get_localization() -> Node:
	"""Get the Localization singleton"""
	if get_tree() and get_tree().root:
		return get_tree().root.get_node_or_null("Localization")
	return null

func _on_language_selected(index: int) -> void:
	"""Handle language selection change"""
	if index < 0 or index >= language_codes.size():
		return

	var lang_code = language_codes[index]
	var loc = _get_localization()
	if loc and loc.has_method("set_language"):
		loc.set_language(lang_code)
		print("[OptionsMenu] Language changed to: %s" % lang_code)
		# Refrescar textos inmediatamente después del cambio
		_refresh_ui_texts()

	# Configurar navegacion WASD
	_setup_wasd_navigation()

func _refresh_ui_texts() -> void:
	"""Refrescar todos los textos de la UI con el nuevo idioma"""
	var loc = _get_localization()
	if not loc:
		return
	
	# Actualizar textos usando el sistema de localización
	var title_label = get_node_or_null("Panel/VBox/TitleLabel")
	if title_label:
		title_label.text = "⚙️ " + loc.L("ui.options.title", "OPCIONES")
	
	var music_label = get_node_or_null("Panel/VBox/MusicContainer/MusicLabel")
	if music_label:
		music_label.text = "🎵 " + loc.L("ui.options.music", "Música")
	
	var sfx_label = get_node_or_null("Panel/VBox/SFXContainer/SFXLabel")
	if sfx_label:
		sfx_label.text = "🔊 " + loc.L("ui.options.sfx", "Efectos de Sonido")
	
	var lang_label = get_node_or_null("Panel/VBox/LanguageContainer/LanguageLabel")
	if lang_label:
		lang_label.text = "🌐 " + loc.L("ui.options.language", "Idioma / Language")
	
	var close_button = get_node_or_null("Panel/VBox/CloseButton")
	if close_button:
		close_button.text = loc.L("ui.options.close", "Cerrar")

func _setup_wasd_navigation() -> void:
	"""Configurar controles navegables y desactivar navegacion por flechas"""
	focusable_controls.clear()

	# Recolectar todos los controles focusables
	_collect_focusable_controls(self)

	# Desactivar navegacion por flechas en todos los controles
	for control in focusable_controls:
		control.focus_mode = Control.FOCUS_ALL
		# Desactivar navegacion por flechas
		control.focus_neighbor_top = control.get_path()
		control.focus_neighbor_bottom = control.get_path()
		control.focus_neighbor_left = control.get_path()
		control.focus_neighbor_right = control.get_path()

	# Dar foco al primer control
	if focusable_controls.size() > 0:
		current_focus_index = 0
		focusable_controls[0].grab_focus()

func _collect_focusable_controls(node: Node) -> void:
	"""Recolectar controles focusables en orden"""
	if node is Button or node is HSlider or node is CheckBox or node is SpinBox or node is OptionButton:
		focusable_controls.append(node as Control)

	for child in node.get_children():
		_collect_focusable_controls(child)

func _get_audio_manager() -> Node:
	if get_tree() and get_tree().root:
		return get_tree().root.get_node_or_null("AudioManager")
	return null

func _on_music_volume_changed(v: float) -> void:
	var am = _get_audio_manager()
	if am and am.has_method("set_music_volume"):
		am.set_music_volume(v)
		if am.has_method("save_volume_settings"):
			am.save_volume_settings()

func _on_sfx_volume_changed(v: float) -> void:
	var am = _get_audio_manager()
	if am and am.has_method("set_sfx_volume"):
		am.set_sfx_volume(v)
		if am.has_method("save_volume_settings"):
			am.save_volume_settings()

func _on_close_pressed() -> void:
	visible = false
	closed.emit()

func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Cerrar con ESC
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()
		return

	# Navegacion WASD
	if event is InputEventKey and event.pressed:
		var handled = false

		match event.keycode:
			KEY_W:
				_navigate(-1)
				handled = true
			KEY_S:
				_navigate(1)
				handled = true
			KEY_A:
				_adjust_slider(-1)
				handled = true
			KEY_D:
				_adjust_slider(1)
				handled = true
			KEY_SPACE, KEY_ENTER:
				_activate_current()
				handled = true

		if handled:
			get_viewport().set_input_as_handled()

	# Soporte para gamepad
	if event is InputEventJoypadButton and event.pressed:
		var handled = false

		match event.button_index:
			JOY_BUTTON_DPAD_UP:
				_navigate(-1)
				handled = true
			JOY_BUTTON_DPAD_DOWN:
				_navigate(1)
				handled = true
			JOY_BUTTON_DPAD_LEFT:
				_adjust_slider(-1)
				handled = true
			JOY_BUTTON_DPAD_RIGHT:
				_adjust_slider(1)
				handled = true
			JOY_BUTTON_A:
				_activate_current()
				handled = true
			JOY_BUTTON_B:
				_on_close_pressed()
				handled = true

		if handled:
			get_viewport().set_input_as_handled()

	# Soporte para joystick analogico
	if event is InputEventJoypadMotion:
		if event.axis == JOY_AXIS_LEFT_Y:
			if event.axis_value < -0.5:
				_navigate(-1)
				get_viewport().set_input_as_handled()
			elif event.axis_value > 0.5:
				_navigate(1)
				get_viewport().set_input_as_handled()
		elif event.axis == JOY_AXIS_LEFT_X:
			if event.axis_value < -0.5:
				_adjust_slider(-1)
				get_viewport().set_input_as_handled()
			elif event.axis_value > 0.5:
				_adjust_slider(1)
				get_viewport().set_input_as_handled()

func _navigate(direction: int) -> void:
	"""Navegar arriba/abajo entre controles"""
	if focusable_controls.is_empty():
		return

	current_focus_index = wrapi(current_focus_index + direction, 0, focusable_controls.size())
	focusable_controls[current_focus_index].grab_focus()

func _adjust_slider(direction: int) -> void:
	"""Ajustar slider o dropdown si el control actual lo soporta"""
	if focusable_controls.is_empty():
		return

	var current = focusable_controls[current_focus_index]
	if current is HSlider:
		current.value += direction * current.step * 5  # 5 pasos por pulsacion
	elif current is OptionButton:
		var new_idx = wrapi(current.selected + direction, 0, current.item_count)
		current.selected = new_idx
		current.item_selected.emit(new_idx)

func _activate_current() -> void:
	"""Activar el control actual (para botones)"""
	if focusable_controls.is_empty():
		return

	var current = focusable_controls[current_focus_index]
	if current is Button:
		current.pressed.emit()

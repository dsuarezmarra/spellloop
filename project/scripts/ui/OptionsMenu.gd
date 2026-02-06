extends Control

signal closed

# Sistema de navegacion WASD
var focusable_controls: Array[Control] = []
var current_focus_index: int = 0

# Language options
var language_codes: Array[String] = []

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	# ✨ POLISH: Transparencia y Estilo
	var panel = get_node_or_null("Panel")
	if panel:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.0, 0.0, 0.0, 0.85) # Fondo oscuro translúcido
		style.set_corner_radius_all(12)
		panel.add_theme_stylebox_override("panel", style)

	# Wire sliders to AudioManager if available
	var am = _get_audio_manager()
	if am:
		# Busqueda robusta de nodos (no depende de rutas exactas)
		var music_slider = find_child("MusicSlider", true, false)
		var sfx_slider = find_child("SFXSlider", true, false)
		
		if music_slider and am.has_method("get_music_volume"):
			# Configurar slider para rango 0-1
			music_slider.min_value = 0.0
			music_slider.max_value = 1.0
			music_slider.step = 0.05
			
			music_slider.value = am.get_music_volume()
			if not music_slider.value_changed.is_connected(_on_music_volume_changed):
				music_slider.value_changed.connect(_on_music_volume_changed)
			_update_volume_label("music", music_slider.value)

		if sfx_slider and am.has_method("get_sfx_volume"):
			# Configurar slider para rango 0-1
			sfx_slider.min_value = 0.0
			sfx_slider.max_value = 1.0
			sfx_slider.step = 0.05
			
			sfx_slider.value = am.get_sfx_volume()
			if not sfx_slider.value_changed.is_connected(_on_sfx_volume_changed):
				sfx_slider.value_changed.connect(_on_sfx_volume_changed)
			_update_volume_label("sfx", sfx_slider.value)

	# Setup language selector
	_setup_language_selector()

	# ✨ POLISH: Ocultar botón "Back" (limpieza visual)
	var close_button = find_child("CloseButton", true, false)
	if close_button:
		close_button.visible = false
		
	# Configurar navegacion WASD
	_setup_wasd_navigation()

func _setup_language_selector() -> void:
	"""Setup the language dropdown with available languages"""
	var language_option = find_child("LanguageOption", true, false)
	if not language_option:
		return

	language_option.clear()
	language_codes.clear()

	# Get available languages from Localization
	var loc = _get_localization()
	if not loc:
		# Fallback to basic options
		language_option.add_item("English", 0)
		language_option.add_item("Español", 1)
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
	
	# Usar find_child para robustez
	var title_label = find_child("TitleLabel", true, false)
	if title_label:
		title_label.text = loc.L("ui.options.title")
	
	var am = _get_audio_manager()
	if am:
		_update_volume_label("music", am.get_music_volume())
		_update_volume_label("sfx", am.get_sfx_volume())
	
	var lang_label = find_child("LanguageLabel", true, false)
	if lang_label:
		lang_label.text = "🌐 " + loc.L("ui.options.language")
	
	var close_button = find_child("CloseButton", true, false)
	if close_button:
		close_button.text = loc.L("ui.options.close")

func _update_volume_label(type: String, value: float) -> void:
	"""Actualizar etiqueta de volumen con porcentaje"""
	var loc = _get_localization()
	var prefix = ""
	var label_node = null
	
	if type == "music":
		label_node = find_child("MusicLabel", true, false)
		prefix = "🎵 " + (loc.L("ui.options.music_volume") if loc else "Music")
	elif type == "sfx":
		label_node = find_child("SFXLabel", true, false)
		prefix = "🔊 " + (loc.L("ui.options.sfx_volume") if loc else "SFX")
		
	if label_node:
		label_node.text = "%s: %d%%" % [prefix, int(value * 100)]

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
		var control = node as Control
		focusable_controls.append(control)
		if not control.mouse_entered.is_connected(_on_element_hover):
			control.mouse_entered.connect(_on_element_hover)

	for child in node.get_children():
		_collect_focusable_controls(child)

func _on_element_hover() -> void:
	AudioManager.play_fixed("sfx_ui_hover")

func _get_audio_manager() -> Node:
	if get_tree() and get_tree().root:
		return get_tree().root.get_node_or_null("AudioManager")
	return null

func _on_music_volume_changed(v: float) -> void:
	var am = _get_audio_manager()
	if am and am.has_method("set_music_volume"):
		am.set_music_volume(v)
		_update_volume_label("music", v)
		if am.has_method("save_volume_settings"):
			am.save_volume_settings()

func _on_sfx_volume_changed(v: float) -> void:
	var am = _get_audio_manager()
	if am and am.has_method("set_sfx_volume"):
		am.set_sfx_volume(v)
		_update_volume_label("sfx", v)
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
	AudioManager.play_fixed("sfx_ui_hover")

func _adjust_slider(direction: int) -> void:
	"""Ajustar slider o dropdown si el control actual lo soporta"""
	if focusable_controls.is_empty():
		return

	var current = focusable_controls[current_focus_index]
	var changed = false
	
	if current is HSlider:
		current.value += direction * current.step * 5  # 5 pasos por pulsacion
		changed = true
	elif current is OptionButton:
		var new_idx = wrapi(current.selected + direction, 0, current.item_count)
		if new_idx != current.selected:
			current.selected = new_idx
			current.item_selected.emit(new_idx)
			changed = true
			
	if changed:
		AudioManager.play_fixed("sfx_ui_click")

func _activate_current() -> void:
	"""Activar el control actual (para botones)"""
	if focusable_controls.is_empty():
		return

	var current = focusable_controls[current_focus_index]
	if current is Button:
		AudioManager.play_fixed("sfx_ui_confirm")
		current.pressed.emit()


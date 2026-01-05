extends Control

signal closed

# Sistema de navegacion WASD
var focusable_controls: Array[Control] = []
var current_focus_index: int = 0

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

	# Conectar botón de cerrar - buscar en ruta correcta
	var close_button = get_node_or_null("Panel/VBox/CloseButton")
	if close_button:
		if not close_button.pressed.is_connected(_on_close_pressed):
			close_button.pressed.connect(_on_close_pressed)

	# Configurar navegacion WASD
	_setup_wasd_navigation()

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
	if node is Button or node is HSlider or node is CheckBox or node is SpinBox:
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
	"""Ajustar slider si el control actual es un slider"""
	if focusable_controls.is_empty():
		return

	var current = focusable_controls[current_focus_index]
	if current is HSlider:
		current.value += direction * current.step * 5  # 5 pasos por pulsacion

func _activate_current() -> void:
	"""Activar el control actual (para botones)"""
	if focusable_controls.is_empty():
		return

	var current = focusable_controls[current_focus_index]
	if current is Button:
		current.emit_signal("pressed")

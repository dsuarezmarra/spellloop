extends Control

signal closed

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
		# Dar foco al botón de cerrar
		close_button.grab_focus()

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
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
		get_viewport().set_input_as_handled()

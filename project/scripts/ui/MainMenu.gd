extends Control
class_name MainMenu

## Menú principal del juego
## Gestiona: Jugar/Reanudar, Opciones, Créditos, Salir

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

const GAME_VERSION = "0.1.0-alpha"

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_play_menu_music()
	_update_resume_button()

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
	
	# Verificar si hay partida activa
	var can_resume = SessionState.has_active_game if SessionState else false
	
	if resume_button:
		resume_button.visible = can_resume
		if can_resume and SessionState:
			resume_button.text = ">> Reanudar (%s)" % SessionState.get_paused_time_formatted()
	
	# Actualizar texto del botón de jugar
	if play_button:
		if can_resume:
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
	await get_tree().process_frame
	
	var can_resume = SessionState.has_active_game if SessionState else false
	
	if can_resume and resume_button and resume_button.visible:
		resume_button.grab_focus()
	elif play_button:
		play_button.grab_focus()

func _connect_signals() -> void:
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if options_button:
		options_button.pressed.connect(_on_options_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _play_menu_music() -> void:
	var audio_manager = _get_audio_manager()
	if audio_manager and audio_manager.has_method("play_music"):
		audio_manager.play_music("menu")

func _get_audio_manager() -> Node:
	var tree = get_tree()
	if tree and tree.root:
		return tree.root.get_node_or_null("AudioManager")
	return null

func _on_play_pressed() -> void:
	_play_button_sound()
	play_pressed.emit()
	
	# Limpiar estado de partida anterior si existe
	if SessionState:
		SessionState.clear_game_state()
	
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
	var audio_manager = _get_audio_manager()
	if audio_manager and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx("ui_click")

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
	if play_button:
		play_button.grab_focus()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if quit_button:
			quit_button.grab_focus()

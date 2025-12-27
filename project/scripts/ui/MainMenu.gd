extends Control
class_name MainMenu

## Menú principal del juego
## Gestiona: Jugar, Opciones, Créditos, Salir

signal play_pressed
signal options_pressed
signal quit_pressed

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $TitleLabel
@onready var version_label: Label = $VersionLabel

const GAME_VERSION = "0.1.0-alpha"

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_play_menu_music()

func _setup_ui() -> void:
	if version_label:
		version_label.text = "v" + GAME_VERSION
	
	# Animación de entrada
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	# Focus en el botón de jugar
	if play_button:
		play_button.grab_focus()

func _connect_signals() -> void:
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
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
	_start_game()

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

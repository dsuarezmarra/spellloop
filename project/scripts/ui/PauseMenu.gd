extends Control
class_name PauseMenu

## Menú de pausa
## Se muestra al presionar ESC durante la partida

signal resume_pressed
signal options_pressed
signal quit_to_menu_pressed

@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var options_button: Button = $Panel/VBoxContainer/OptionsButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton
@onready var time_label: Label = $Panel/TimeLabel

var game_time: float = 0.0

func _ready() -> void:
	_connect_signals()
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _connect_signals() -> void:
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if options_button:
		options_button.pressed.connect(_on_options_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func show_pause_menu(current_time: float = 0.0) -> void:
	game_time = current_time
	_update_time_display()
	visible = true
	get_tree().paused = true
	
	if resume_button:
		resume_button.grab_focus()
	
	# Animación de entrada
	modulate.a = 0
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

func hide_pause_menu() -> void:
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	await tween.finished
	
	visible = false
	get_tree().paused = false

func _update_time_display() -> void:
	if time_label:
		var minutes = int(game_time) / 60
		var seconds = int(game_time) % 60
		time_label.text = "Tiempo: %02d:%02d" % [minutes, seconds]

func _on_resume_pressed() -> void:
	_play_button_sound()
	resume_pressed.emit()
	hide_pause_menu()

func _on_options_pressed() -> void:
	_play_button_sound()
	options_pressed.emit()
	_show_options()

func _on_quit_pressed() -> void:
	_play_button_sound()
	quit_to_menu_pressed.emit()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _show_options() -> void:
	var options_menu = get_node_or_null("OptionsMenu")
	if not options_menu:
		var options_scene = load("res://scenes/ui/OptionsMenu.tscn")
		if options_scene:
			options_menu = options_scene.instantiate()
			options_menu.name = "OptionsMenu"
			add_child(options_menu)
	
	if options_menu:
		options_menu.visible = true

func _play_button_sound() -> void:
	var tree = get_tree()
	if tree and tree.root:
		var audio_manager = tree.root.get_node_or_null("AudioManager")
		if audio_manager and audio_manager.has_method("play_sfx"):
			audio_manager.play_sfx("ui_click")

func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		_on_resume_pressed()
		get_viewport().set_input_as_handled()

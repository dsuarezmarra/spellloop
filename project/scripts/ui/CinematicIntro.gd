extends Control
class_name CinematicIntro
## Intro cinematográfica: reproduce un vídeo y transiciona al menú principal.
## Saltable con Enter, Escape o Espacio. Fade-out suave al terminar/saltar.

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var fade_rect: ColorRect = $FadeRect
@onready var skip_label: Label = $SkipLabel

const MAIN_MENU_SCENE = "res://scenes/ui/MainMenu.tscn"
const FADE_DURATION := 0.6

## Flag global: true cuando la intro ya se reprodujo en esta sesión
static var intro_shown := false

var _transitioning := false

func _ready() -> void:
	# Fondo negro y fade rect preparados
	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skip_label.modulate.a = 0.0

	# Cargar vídeo (OGV — formato nativo de Godot)
	var video_path := "res://assets/ui/videos/intro.ogv"
	var vid = load(video_path)

	if vid:
		video_player.stream = vid
		video_player.play()
		# Fade-in desde negro
		var fade_in := create_tween()
		fade_in.tween_property(fade_rect, "color:a", 0.0, 0.5)
		# Mostrar hint de skip tras 1.5s
		fade_in.tween_property(skip_label, "modulate:a", 0.5, 0.4).set_delay(1.0)
	else:
		# Sin vídeo: ir directo al menú
		_go_to_main_menu()

func _input(event: InputEvent) -> void:
	if _transitioning:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ENTER, KEY_ESCAPE, KEY_SPACE, KEY_KP_ENTER:
				_skip_video()

func _on_video_stream_player_finished() -> void:
	_go_to_main_menu()

func _skip_video() -> void:
	if _transitioning:
		return
	video_player.stop()
	_go_to_main_menu()

func _go_to_main_menu() -> void:
	if _transitioning:
		return
	_transitioning = true
	intro_shown = true
	set_process_input(false)

	# Fade-out a negro
	skip_label.modulate.a = 0.0
	var fade_out := create_tween()
	fade_out.tween_property(fade_rect, "color:a", 1.0, FADE_DURATION)
	await fade_out.finished

	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

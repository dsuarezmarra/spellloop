extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer

# Ruta al menú principal
const MAIN_MENU_SCENE = "res://scenes/ui/MainMenu.tscn"

func _ready() -> void:
	# Intentar cargar video (prioridad MP4, fallback OGV)
	var video_path = "res://assets/ui/videos/intro.mp4"
	if not FileAccess.file_exists(video_path):
		video_path = "res://assets/ui/videos/intro.ogv"
	
	if FileAccess.file_exists(video_path):
		var stream = VideoStreamTheora.new() # Default fallback/container
		# Nota: Para MP4 real, Godot necesita el recurso importado. 
		# Si es mp4, se usa load() normal.
		video_player.stream = load(video_path)
		video_player.play()
	else:
		# Si no hay video, saltar directo
		_go_to_main_menu()

func _input(event: InputEvent) -> void:
	# Permitir saltar con cualquier tecla/botón
	if event is InputEventKey and event.pressed:
		_go_to_main_menu()
	elif event is InputEventMouseButton and event.pressed:
		_go_to_main_menu()
	elif event is InputEventJoypadButton and event.pressed:
		_go_to_main_menu()

func _on_video_stream_player_finished() -> void:
	_go_to_main_menu()

func _go_to_main_menu() -> void:
	# Evitar llamadas dobles
	if is_processing_input():
		set_process_input(false)
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)

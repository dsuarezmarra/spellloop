extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer

# Ruta al menú principal
const MAIN_MENU_SCENE = "res://scenes/ui/MainMenu.tscn"

@onready var debug_label: Label = $DebugLabel

func _ready() -> void:
	debug_label.text = "Initializing Video..."
	
	# Intentar cargar video (prioridad MP4, fallback OGV)
	var video_path = "res://assets/ui/videos/intro.mp4"
	var final_path = video_path
	
	if not FileAccess.file_exists(video_path):
		debug_msg("MP4 not found via res://. Checking OGV...")
		video_path = "res://assets/ui/videos/intro.ogv"
		final_path = video_path
	
	# Try global path if res fails (fix for MP4 not imported)
	if not FileAccess.file_exists(video_path):
		debug_msg("Res path failed. Trying global path...")
		final_path = ProjectSettings.globalize_path("res://assets/ui/videos/intro.mp4")

	if FileAccess.file_exists(final_path) or FileAccess.file_exists(video_path):
		debug_msg("File found: " + final_path)
		
		# Try loading
		var vid = load(video_path)
		if not vid:
			debug_msg("load(res) failed. This is expected for non-imported MP4.")
			# For MP4 on windows we might need to rely on the player handling the file path if create_video_stream is available?
			# Actually Godot VideoStreamPlayer needs a Resource.
			# If load() fails, we are kind of stuck unless we used a detailed plugin.
			# But let's see if it loaded.
		
		if vid:
			video_player.stream = vid
			video_player.play()
			debug_msg("Stream Set. Playing...")
			
			# Check in 0.5s
			await get_tree().create_timer(0.5).timeout
			debug_msg("Is Playing: " + str(video_player.is_playing()))
			
			# Safety timeout
			await get_tree().create_timer(2.5).timeout # Extended to 3s total
			if not video_player.is_playing() and visible:
				debug_msg("Timeout reached. Skipping...")
				await get_tree().create_timer(1.0).timeout
				_go_to_main_menu()
		else:
			debug_msg("ERROR: load() returned null. Godot hasn't imported this video.")
			await get_tree().create_timer(2.0).timeout
			_go_to_main_menu()
	else:
		debug_msg("NO VIDEO FILE FOUND AT: " + final_path)
		# Si no hay video, saltar directo
		debug_msg("NO VIDEO FILE FOUND AT: " + final_path)
		# DEBUG: No saltar automáticamente para que el usuario pueda leer el error
		# await get_tree().create_timer(2.0).timeout
		# _go_to_main_menu()

func debug_msg(text: String) -> void:
	print(text)
	if debug_label:
		debug_label.text = text

func _input(event: InputEvent) -> void:
	# Permitir saltar con cualquier tecla (Manual only)
	if event is InputEventKey and event.pressed:
		_go_to_main_menu()
#	elif event is InputEventMouseButton and event.pressed:
#		_go_to_main_menu()

func _on_video_stream_player_finished() -> void:
	debug_msg("Video Finished.")
	await get_tree().create_timer(1.0).timeout
	_go_to_main_menu()

func _go_to_main_menu() -> void:
	# Evitar llamadas dobles
	if is_processing_input():
		set_process_input(false)
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)

extends Node

# AudioManager.gd
# Global singleton for audio playback
# Usage: AudioManager.play("sfx_player_hurt")

var manifest: Dictionary = {}
var sfx_players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer

const SFX_POOL_SIZE = 32

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_audio_system()

func _init_audio_system():
	# Load manifest
	manifest = AudioLoader.load_manifest()
	print("[AudioManager] Loaded %d audio definitions" % manifest.size())
	
	# Setup music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	
	# Setup SFX pool
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

func play(audio_id: String, volume_offset: float = 0.0) -> void:
	"""Play a sound effect by ID."""
	if not manifest.has(audio_id):
		push_warning("[AudioManager] Sound not found: " + audio_id)
		return
	
	var entry = manifest[audio_id]
	var files = entry.get("files", [])
	
	if files.is_empty():
		return
	
	# Pick random variation
	var file_path = files.pick_random()
	
	# Load stream
	var stream = load(file_path)
	if not stream:
		push_error("[AudioManager] Failed to load: " + file_path)
		return
	
	# Find free player
	var player = _get_free_player()
	if not player:
		return
	
	# Configure and play
	player.stream = stream
	player.volume_db = entry.get("volume_db", 0.0) + volume_offset
	
	var pitch_range = entry.get("pitch_scale", [1.0, 1.0])
	player.pitch_scale = randf_range(pitch_range[0], pitch_range[1])
	
	player.bus = entry.get("bus", "SFX")
	player.play()

func play_music(music_id: String, fade_time: float = 1.0) -> void:
	"""Play music track."""
	if not manifest.has(music_id):
		push_warning("[AudioManager] Music not found: " + music_id)
		return
	
	var entry = manifest[music_id]
	var files = entry.get("files", [])
	
	if files.is_empty():
		return
	
	var stream = load(files[0])
	if not stream:
		return
	
	music_player.stream = stream
	music_player.volume_db = entry.get("volume_db", -3.0)
	music_player.play()

func stop_music(fade_time: float = 1.0) -> void:
	"""Stop current music."""
	music_player.stop()

func _get_free_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	return null

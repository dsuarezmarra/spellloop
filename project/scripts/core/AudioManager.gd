extends Node

# AudioManager.gd
# Global singleton to handle all audio playback requests
# Usage: AudioManager.play("sfx_player_hurt")

var manifest: Dictionary = {}
var sfx_players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer
var sfx_bus_index: int
var music_bus_index: int

const SFX_POOL_SIZE = 32

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_audio_system()
	
func _init_audio_system():
	# Load Manifest
	manifest = AudioLoader.load_manifest()
	print("[AudioManager] Loaded %d audio definitions" % manifest.size())
	
	# Create Buses references
	sfx_bus_index = AudioServer.get_bus_index("SFX")
	music_bus_index = AudioServer.get_bus_index("Music")
	
	# Setup Music Player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	
	# Setup SFX Pool
	for i in range(SFX_POOL_SIZE):
		var p = AudioStreamPlayer.new()
		p.bus = "SFX"
		p.finished.connect(_on_sfx_finished.bind(p))
		add_child(p)
		sfx_players.append(p)

func play(audio_id: String, position: Vector2 = Vector2.ZERO):
	"""
	Play a sound by ID. 
	If position is provided (not ZERO), it could be spatial (not implemented in this 2D simple version yet, 
	but API allows future expansion).
	"""
	if not manifest.has(audio_id):
		push_warning("[AudioManager] Sound not found: " + audio_id)
		return
		
	var entry = manifest[audio_id]
	var files = entry.get("files", [])
	
	if files.is_empty():
		return
		
	# Select variation
	var file_path = files.pick_random()
	
	# Load Stream
	var stream = load(file_path)
	if not stream:
		push_error("Failed to load stream: " + file_path)
		return
		
	# Find free player
	var player = _get_free_player()
	if not player:
		# Optional: Steal oldest? For now just skip
		return
		
	# Setup
	player.stream = stream
	player.volume_db = entry.get("volume_db", 0.0)
	
	# Pitch randomization
	var pitch_range = entry.get("pitch_scale", [1.0, 1.0])
	player.pitch_scale = randf_range(pitch_range[0], pitch_range[1])
	
	player.bus = entry.get("bus", "SFX")
	
	player.play()

func play_music(music_id: String, fade_time: float = 1.0):
	if not manifest.has(music_id):
		return
		
	var entry = manifest[music_id]
	var files = entry.get("files", [])
	if files.is_empty():
		return
		
	var stream = load(files[0])
	
	# Simple crossfade logic could go here
	music_player.stream = stream
	music_player.volume_db = entry.get("volume_db", 0.0)
	music_player.play()

func _get_free_player() -> AudioStreamPlayer:
	for p in sfx_players:
		if not p.playing:
			return p
	return null

func _on_sfx_finished(player: AudioStreamPlayer):
	pass

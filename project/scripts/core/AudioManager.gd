extends Node

# AudioManager.gd
# Global singleton for audio playback
# Usage: AudioManager.play("sfx_player_hurt")  # Random variation (for projectiles/music)
# Usage: AudioManager.play_fixed("sfx_ui_click")  # Fixed sound (for UI/feedback)

var manifest: Dictionary = {}
var sfx_players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer

const SFX_POOL_SIZE = 32
const SETTINGS_PATH = "user://audio_settings.cfg"

# Volume settings (0.0 to 1.0)
var music_volume: float = 1.0
var sfx_volume: float = 1.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_audio_system()
	_load_volume_settings()

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
	
	# Ensure audio buses exist
	_ensure_audio_buses()

func _ensure_audio_buses():
	"""Create audio buses if they don't exist."""
	var bus_layout = AudioServer.get_bus_count()
	
	# Check for Music bus
	var music_idx = AudioServer.get_bus_index("Music")
	if music_idx == -1:
		AudioServer.add_bus()
		music_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(music_idx, "Music")
		AudioServer.set_bus_send(music_idx, "Master")
	
	# Check for SFX bus
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_idx == -1:
		AudioServer.add_bus()
		sfx_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(sfx_idx, "SFX")
		AudioServer.set_bus_send(sfx_idx, "Master")

func play(audio_id: String, volume_offset: float = 0.0) -> void:
	"""Play a sound effect with random variation (for variety sounds like projectiles)."""
	_play_internal(audio_id, volume_offset, true)

func play_fixed(audio_id: String, volume_offset: float = 0.0) -> void:
	"""Play a sound effect with FIXED first variation (for deterministic feedback like UI)."""
	_play_internal(audio_id, volume_offset, false)

func _play_internal(audio_id: String, volume_offset: float, random_variation: bool) -> void:
	"""Internal play method."""
	if not manifest.has(audio_id):
		# push_warning("[AudioManager] Sound not found: " + audio_id)
		return
	
	var entry = manifest[audio_id]
	var files = entry.get("files", [])
	
	if files.is_empty():
		return
	
	# Pick variation - random or first
	var file_path: String
	if random_variation and files.size() > 1:
		file_path = files.pick_random()
	else:
		file_path = files[0]
	
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
	var base_volume = entry.get("volume_db", 0.0) + volume_offset
	player.volume_db = base_volume + linear_to_db(sfx_volume)
	
	# Only use pitch variation for random mode
	if random_variation:
		var pitch_range = entry.get("pitch_scale", [1.0, 1.0])
		if pitch_range is Array and pitch_range.size() >= 2:
			player.pitch_scale = randf_range(pitch_range[0], pitch_range[1])
		else:
			player.pitch_scale = 1.0
	else:
		player.pitch_scale = 1.0
	
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
	
	# Force loop mode if supported
	if stream.get("loop") != null:
		stream.loop = true
	
	music_player.stream = stream
	music_player.volume_db = entry.get("volume_db", -3.0) + linear_to_db(music_volume)
	music_player.play()

func stop_music(fade_time: float = 1.0) -> void:
	"""Stop current music."""
	music_player.stop()

# ═══════════════════════════════════════════════════════════════════════════════
# VOLUME CONTROL API (for Options Menu)
# ═══════════════════════════════════════════════════════════════════════════════

func set_music_volume(value: float) -> void:
	"""Set music volume (0.0 to 1.0)."""
	music_volume = clamp(value, 0.0, 1.0)
	var music_bus_idx = AudioServer.get_bus_index("Music")
	if music_bus_idx != -1:
		AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(music_volume))

func set_sfx_volume(value: float) -> void:
	"""Set SFX volume (0.0 to 1.0)."""
	sfx_volume = clamp(value, 0.0, 1.0)
	var sfx_bus_idx = AudioServer.get_bus_index("SFX")
	if sfx_bus_idx != -1:
		AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(sfx_volume))

func get_music_volume() -> float:
	"""Get current music volume (0.0 to 1.0)."""
	return music_volume

func get_sfx_volume() -> float:
	"""Get current SFX volume (0.0 to 1.0)."""
	return sfx_volume

func save_volume_settings() -> void:
	"""Save volume settings to file."""
	var config = ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.save(SETTINGS_PATH)

func _load_volume_settings() -> void:
	"""Load volume settings from file."""
	var config = ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		music_volume = config.get_value("audio", "music_volume", 1.0)
		sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
		set_music_volume(music_volume)
		set_sfx_volume(sfx_volume)

func _get_free_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	return null

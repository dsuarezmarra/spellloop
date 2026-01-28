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

# Cache for loaded streams to avoid disk hitting on every play
var stream_cache: Dictionary = {}

# Volume settings (0.0 to 1.0)
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var debug_audio: bool = OS.is_debug_build()

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Registrar en grupo para compatibilidad con scripts legacy que usan get_nodes_in_group
	add_to_group("audio_manager")
	
	# Ensure audio buses exist FIRST
	_ensure_audio_buses()
	
	_init_audio_system()
	_load_volume_settings()
	
	if debug_audio:
		validate_manifest()

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

func validate_manifest() -> void:
	"""Runtime validation of audio assets (Debug only)."""
	print("[AudioManager] Validating manifest...")
	var empty_ids = 0
	var broken_paths = 0
	
	for id in manifest:
		var entry = manifest[id]
		var files = entry.get("files", [])
		
		if files.is_empty():
			push_warning("[AudioManager] ID '%s' has no files defined" % id)
			empty_ids += 1
		
		for path in files:
			if not FileAccess.file_exists(path):
				push_warning("[AudioManager] ID '%s' points to missing file: %s" % [id, path])
				broken_paths += 1
	
	if empty_ids > 0 or broken_paths > 0:
		print("[AudioManager] Validation finished with issues: %d empty IDs, %d broken paths." % [empty_ids, broken_paths])
	else:
		print("[AudioManager] Validation passed cleanly.")

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

	# Check for UI bus
	var ui_idx = AudioServer.get_bus_index("UI")
	if ui_idx == -1:
		AudioServer.add_bus()
		ui_idx = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(ui_idx, "UI")
	
	# Route UI -> SFX so SFX slider controls UI volume too
	AudioServer.set_bus_send(ui_idx, "SFX")

func play(audio_id: String, volume_offset: float = 0.0) -> void:
	"""Play a sound effect with random variation (for variety sounds like projectiles)."""
	_play_internal(audio_id, volume_offset, true)

func play_fixed(audio_id: String, volume_offset: float = 0.0) -> void:
	"""Play a sound effect with FIXED first variation (for deterministic feedback like UI)."""
	_play_internal(audio_id, volume_offset, false)

func _play_internal(audio_id: String, volume_offset: float, random_variation: bool) -> void:
	"""Internal play method."""
	if not manifest.has(audio_id):
		if debug_audio:
			push_warning("[AudioManager] Sound not found: " + audio_id)
		return
	
	var entry = manifest[audio_id]
	var files = entry.get("files", [])
	
	if files.is_empty():
		if debug_audio:
			push_warning("[AudioManager] ID '%s' is empty" % audio_id)
		return
	
	# Pick variation - random or first
	var file_path: String
	if random_variation and files.size() > 1:
		file_path = files.pick_random()
	else:
		file_path = files[0]
	
	# Load stream (with cache)
	var stream = _get_stream(file_path)
	if not stream:
		return
	
	# Find free player
	var player = _get_free_player()
	if not player:
		return
	
	# Configure and play
	player.stream = stream
	var base_volume = entry.get("volume_db", 0.0) + volume_offset
	
	player.volume_db = base_volume
	
	# Only use pitch variation for random mode AND if configured
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

func _get_stream(path: String) -> AudioStream:
	if stream_cache.has(path):
		return stream_cache[path]
	
	if not FileAccess.file_exists(path):
		if debug_audio:
			push_warning("[AudioManager] File not found: " + path)
		return null
		
	var stream = load(path)
	if stream:
		stream_cache[path] = stream
	else:
		push_error("[AudioManager] Failed to load: " + path)
		
	return stream

func play_music(music_id: String, fade_time: float = 1.0) -> void:
	"""Play music track."""
	if not manifest.has(music_id):
		push_warning("[AudioManager] Music not found: " + music_id)
		return
	
	var entry = manifest[music_id]
	var files = entry.get("files", [])
	
	if files.is_empty():
		return
	
	# Normalize path loading
	var stream = _get_stream(files[0])
	if not stream:
		return
	
	# Force loop mode if supported
	if stream.get("loop") != null:
		stream.loop = true
	
	music_player.stream = stream
	# FIX: Removed double volume application. Bus handles it.
	music_player.volume_db = entry.get("volume_db", -3.0) 
	music_player.play()

func stop_music(fade_time: float = 1.0) -> void:
	"""Stop current music."""
	music_player.stop()

func pause_music(paused: bool) -> void:
	"""Pause or resume current music."""
	music_player.stream_paused = paused

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

# ═══════════════════════════════════════════════════════════════════════════════
# COIN SFX SYSTEM (High Polyphony)
# ═══════════════════════════════════════════════════════════════════════════════

# Mini-Pool para monedas (permite pitch variable simultáneo)
var coin_pool: Array[AudioStreamPlayer] = []
const COIN_POOL_SIZE = 32 # Aumentado para soportar imanes masivos
var coin_pool_idx = 0

func play_coin_sfx(pitch: float = 1.0) -> void:
	"""
	Reproducir sonido de moneda con alta polifonía usando el manifest.
	"""
	var audio_id = "sfx_coin_pickup"
	if not manifest.has(audio_id):
		return
		
	var entry = manifest[audio_id]
	var files = entry.get("files", [])
	if files.is_empty():
		return
		
	var file_path = files[0]
	var stream = _get_stream(file_path)
	if not stream:
		return

	if coin_pool.is_empty():
		# Crear pool bajo demanda
		# Nota: Recibe bus del manifest si existe, sino default "SFX"
		var target_bus = entry.get("bus", "SFX")
		
		for i in range(COIN_POOL_SIZE):
			var p = AudioStreamPlayer.new()
			p.bus = target_bus 
			add_child(p)
			coin_pool.append(p)
	
	# Usar Round Robin para sobrescribir el más viejo si todos están ocupados
	var player = coin_pool[coin_pool_idx]
	
	# Ensure stream is set (optimized by cache)
	if player.stream != stream:
		player.stream = stream

	player.pitch_scale = pitch
	# FIX: Removed double volume application. 
	# Usar volume_db del manifest (-6.0) en lugar de hardcodeado -5.0
	var base_db = entry.get("volume_db", -6.0)
	player.volume_db = base_db # AudioServer bus handles sfx_volume reduction
	
	player.play()
	
	coin_pool_idx = (coin_pool_idx + 1) % COIN_POOL_SIZE

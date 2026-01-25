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
	
	# Registrar en grupo para compatibilidad con scripts legacy que usan get_nodes_in_group
	add_to_group("audio_manager")
	
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
	
	# SETUP DEDICATED COIN PLAYER (High Polyphony) - Now using Pool
	# _setup_coin_player() removed (superseded by pool)
	
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

var coin_player: AudioStreamPlayer
const COIN_SFX_PATH = "res://assets/audio/sfx/pickups/sfx_coin_pickup.wav"

func _setup_coin_player() -> void:
	coin_player = AudioStreamPlayer.new()
	coin_player.name = "CoinPlayer"
	coin_player.bus = "SFX"
	# Permitir muchas voces simultáneas para el mismo sonido
	coin_player.max_polyphony = 64 
	add_child(coin_player)
	
	# Pre-cargar el sonido
	var stream = load(COIN_SFX_PATH)
	if stream:
		coin_player.stream = stream
	else:
		push_warning("[AudioManager] Coin SFX not found at: " + COIN_SFX_PATH)

func play_coin_sfx(pitch: float = 1.0) -> void:
	"""
	Reproducir sonido de moneda con alta polifonía.
	Garantiza que siempre suene incluso si hay muchas monedas juntas.
	"""
	if not coin_player:
		return
		
	if not coin_player.stream:
		# Intentar recargar si falló al inicio
		var stream = load(COIN_SFX_PATH)
		if stream:
			coin_player.stream = stream
		else:
			return

	# Ajustar pitch y reproducir
	# NOTA: En Godot 4, cambiar pitch_scale afecta a TODAS las voces activas de este player si no es polifónico real.
	# Pero con max_polyphony, cada trigger 'play()' genera una voz nueva con los parámetros actuales?
	# VERIFICACIÓN: AudioStreamPlayer.play() dice: "If the stream is not playing, plays it. If it is already playing, adds a new voice... but parameters like pitch are shared per Node in some versions."
	# Si cambiar pitch afecta a todos, entonces necesitamos un pool específico para monedas.
	# HACK: Para monedas, el pitch cambia muy rápido. Si el nodo comparte pitch, sonará raro.
	# SOLUCIÓN: Usar un mini-pool de monedas si el pitch es variable.
	
	# REVISIÓN: Si cambiamos pitch_scale, afecta al nodo entero.
	# Por lo tanto, para tener distintos pitch SIMULTÁNEOS, necesitamos múltiples nodos.
	# VOLVEMOS AL POOL, pero específico para monedas.
	
	_play_coin_from_pool(pitch)

# Mini-Pool para monedas (permite pitch variable simultáneo)
var coin_pool: Array[AudioStreamPlayer] = []
const COIN_POOL_SIZE = 32 # Aumentado para soportar imanes masivos
var coin_pool_idx = 0

func _play_coin_from_pool(pitch: float) -> void:
	if coin_pool.is_empty():
		# Crear pool bajo demanda
		for i in range(COIN_POOL_SIZE):
			var p = AudioStreamPlayer.new()
			p.bus = "SFX"
			p.stream = load(COIN_SFX_PATH)
			add_child(p)
			coin_pool.append(p)
	
	# Usar Round Robin para sobrescribir el más viejo si todos están ocupados
	# Esto garantiza que siempre suene el nuevo, cortando el más viejo si es necesario
	var player = coin_pool[coin_pool_idx]
	
	player.pitch_scale = pitch
	# Priorizar sonido: Volumen más alto (-5.0db en vez de -12)
	player.volume_db = -5.0 + linear_to_db(sfx_volume) 
	player.play()
	
	coin_pool_idx = (coin_pool_idx + 1) % COIN_POOL_SIZE

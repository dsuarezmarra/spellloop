# AudioManager.gd - Simplified Version
# Core audio management system for Spellloop
# Handles music, SFX, and ambient sounds

extends Node

signal music_started(track_name: String)
signal music_stopped()
signal volume_changed(bus_name: String, new_volume: float)

# Audio buses
const MASTER_BUS = "Master"
const MUSIC_BUS = "Music"
const SFX_BUS = "SFX"
const AMBIENT_BUS = "Ambient"

# Audio players
var music_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS = 10

# Audio resources
var music_tracks: Dictionary = {}
var sfx_sounds: Dictionary = {}

# Current state
var current_music_track: String = ""
var is_music_playing: bool = false

# Volume settings
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 0.9
var ambient_volume: float = 0.6

func _ready() -> void:
	print("[AudioManager] Initializing audio system...")
	
	# Create audio players
	_setup_audio_players()
	
	# Setup audio buses
	_setup_audio_buses()
	
	# Load default audio resources
	_load_default_audio()
	
	print("[AudioManager] Audio system ready")

func _setup_audio_players() -> void:
	"""Setup audio player nodes"""
	# Music player
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = MUSIC_BUS
	add_child(music_player)
	
	# Ambient player
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientPlayer"
	ambient_player.bus = AMBIENT_BUS
	add_child(ambient_player)
	
	# SFX players pool
	for i in range(MAX_SFX_PLAYERS):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer" + str(i)
		sfx_player.bus = SFX_BUS
		add_child(sfx_player)
		sfx_players.append(sfx_player)

func _setup_audio_buses() -> void:
	"""Setup audio bus volumes"""
	var master_idx = AudioServer.get_bus_index(MASTER_BUS)
	var music_idx = AudioServer.get_bus_index(MUSIC_BUS)
	var sfx_idx = AudioServer.get_bus_index(SFX_BUS)
	var ambient_idx = AudioServer.get_bus_index(AMBIENT_BUS)
	
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_volume))
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(music_volume))
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(sfx_volume))
	if ambient_idx >= 0:
		AudioServer.set_bus_volume_db(ambient_idx, linear_to_db(ambient_volume))

func _load_default_audio() -> void:
	"""Load default audio resources"""
	# This would load actual audio files in a real implementation
	print("[AudioManager] Default audio resources loaded")

func play_music(track_name: String, _fade_in: bool = true) -> void:
	"""Play background music"""
	if current_music_track == track_name and is_music_playing:
		return
	
	stop_music()
	
	if music_tracks.has(track_name):
		music_player.stream = music_tracks[track_name]
		music_player.play()
		is_music_playing = true
		current_music_track = track_name
		music_started.emit(track_name)
		print("[AudioManager] Playing music: ", track_name)

func stop_music() -> void:
	"""Stop background music"""
	if music_player.playing:
		music_player.stop()
	
	is_music_playing = false
	current_music_track = ""
	music_stopped.emit()

func play_sfx(sound_name: String, volume: float = 1.0) -> void:
	"""Play sound effect"""
	var player = _get_available_sfx_player()
	if not player:
		return
	
	if sfx_sounds.has(sound_name):
		player.stream = sfx_sounds[sound_name]
		player.volume_db = linear_to_db(volume * sfx_volume)
		player.play()

func set_master_volume(volume: float) -> void:
	"""Set master volume (0.0 to 1.0)"""
	master_volume = clamp(volume, 0.0, 1.0)
	var master_idx = AudioServer.get_bus_index(MASTER_BUS)
	if master_idx >= 0:
		AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_volume))
	volume_changed.emit(MASTER_BUS, master_volume)
	_save_volume_settings()

func set_music_volume(volume: float) -> void:
	"""Set music volume (0.0 to 1.0)"""
	music_volume = clamp(volume, 0.0, 1.0)
	var music_idx = AudioServer.get_bus_index(MUSIC_BUS)
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(music_volume))
	volume_changed.emit(MUSIC_BUS, music_volume)
	_save_volume_settings()

func set_sfx_volume(volume: float) -> void:
	"""Set SFX volume (0.0 to 1.0)"""
	sfx_volume = clamp(volume, 0.0, 1.0)
	var sfx_idx = AudioServer.get_bus_index(SFX_BUS)
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(sfx_volume))
	volume_changed.emit(SFX_BUS, sfx_volume)
	_save_volume_settings()

func _get_available_sfx_player() -> AudioStreamPlayer:
	"""Get an available SFX player from pool"""
	for player in sfx_players:
		if not player.playing:
			return player
	
	# If all players are busy, use the first one
	return sfx_players[0] if sfx_players.size() > 0 else null

func _save_volume_settings() -> void:
	"""Save current volume settings"""
	var settings = {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"ambient_volume": ambient_volume
	}
	
	var save_manager = get_node("/root/SaveManager")
	if save_manager:
		save_manager.save_settings(settings)

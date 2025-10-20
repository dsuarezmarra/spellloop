extends Node

signal music_started(track_name: String)
signal music_stopped()
signal volume_changed(bus_name: String, new_volume: float)

# Audio buses
const MASTER_BUS = "Master"
const MUSIC_BUS = "Music"
const SFX_BUS = "SFX"
const AMBIENT_BUS = "Ambient"

# Config
var sfx_folder: String = "res://assets/sfx/"
var settings_path: String = "user://settings.json"
var music_volume: float = 0.8
var sfx_volume: float = 0.8

var music_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS = 20

var music_tracks: Dictionary = {}
var sfx_sounds: Dictionary = {}
var spell_sounds: Dictionary = {}
var biome_tracks: Dictionary = {}

var current_music_track: String = ""
var current_biome_track: String = ""
var is_music_playing: bool = false

var master_volume: float = 1.0
var ambient_volume: float = 0.6

var music_fade_tween: Tween
var crossfade_tween: Tween


func _ready() -> void:
	print("[AudioManager] Initializing AudioManager...")
	
	# Setup audio buses
	_setup_audio_buses()
	
	# Create audio players
	_create_audio_players()
	
	# Load audio resources
	_load_audio_resources()
	
	# Load volume settings
	_load_volume_settings()
	
	print("[AudioManager] AudioManager initialized successfully")

func _setup_audio_buses() -> void:
	"""Setup audio buses for volume control"""
	# Audio buses are typically configured in Godot's Audio settings
	# This function applies volume settings to existing buses
	pass

func _create_audio_players() -> void:
	"""Create audio stream players for music, ambient, and SFX"""
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = MUSIC_BUS
	add_child(music_player)
	
	# Create ambient player
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientPlayer"
	ambient_player.bus = AMBIENT_BUS
	add_child(ambient_player)
	
	# Create SFX players pool
	for i in range(MAX_SFX_PLAYERS):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer" + str(i)
		sfx_player.bus = SFX_BUS
		add_child(sfx_player)
		sfx_players.append(sfx_player)

func _load_audio_resources() -> void:
	"""Load and create procedural audio resources"""
	print("[AudioManager] Loading audio resources...")
	
	# Create placeholder audio streams for different types
	_create_music_tracks()
	_create_sfx_sounds()
	_create_spell_sounds()
	_create_biome_tracks()
	
	print("[AudioManager] Audio resources loaded successfully")

func _create_music_tracks() -> void:
	"""Create music track data"""
	music_tracks = {
		"main_menu": {
			"file": "res://assets/audio/music/main_menu.ogg",
			"loop": true,
			"volume": 0.8
		},
		"gameplay": {
			"file": "res://assets/audio/music/gameplay.ogg", 
			"loop": true,
			"volume": 0.7
		},
		"boss_battle": {
			"file": "res://assets/audio/music/boss_battle.ogg",
			"loop": true,
			"volume": 0.9
		},
		"victory": {
			"file": "res://assets/audio/music/victory.ogg",
			"loop": false,
			"volume": 0.8
		},
		"defeat": {
			"file": "res://assets/audio/music/defeat.ogg",
			"loop": false,
			"volume": 0.7
		}
	}

func _create_biome_tracks() -> void:
	"""Create biome-specific ambient tracks"""
	biome_tracks = {
		"dungeon": {
			"music": "dungeon_ambient",
			"ambient": "dungeon_echoes",
			"intensity": 0.6
		},
		"forest": {
			"music": "forest_ambient",
			"ambient": "forest_winds",
			"intensity": 0.5
		},
		"volcanic": {
			"music": "volcanic_ambient", 
			"ambient": "lava_bubbles",
			"intensity": 0.8
		},
		"ice": {
			"music": "ice_ambient",
			"ambient": "ice_winds",
			"intensity": 0.4
		},
		"corruption": {
			"music": "corruption_ambient",
			"ambient": "dark_whispers",
			"intensity": 0.9
		},
		"celestial": {
			"music": "celestial_ambient",
			"ambient": "heavenly_chorus",
			"intensity": 0.7
		}
	}

func _create_sfx_sounds() -> void:
	"""Create sound effect data"""
	sfx_sounds = {
		# UI Sounds
		"ui_select": {"volume": 0.8, "pitch": 1.0},
		"ui_hover": {"volume": 0.6, "pitch": 1.2},
		"ui_error": {"volume": 0.9, "pitch": 0.8},
		"ui_confirm": {"volume": 0.8, "pitch": 1.0},
		
		# Combat Sounds
		"hit_impact": {"volume": 0.9, "pitch": 1.0},
		"critical_hit": {"volume": 1.0, "pitch": 1.3},
		"enemy_death": {"volume": 0.8, "pitch": 0.9},
		"player_hurt": {"volume": 0.9, "pitch": 0.8},
		"player_death": {"volume": 1.0, "pitch": 0.7},
		
		# Movement Sounds  
		"footstep": {"volume": 0.5, "pitch": 1.0},
		"dash": {"volume": 0.7, "pitch": 1.1},
		"jump": {"volume": 0.6, "pitch": 1.0},
		
		# Interaction Sounds
		"pickup_item": {"volume": 0.8, "pitch": 1.2},
		"open_chest": {"volume": 0.9, "pitch": 1.0},
		"level_up": {"volume": 1.0, "pitch": 1.4},
		"achievement": {"volume": 0.9, "pitch": 1.3},
		
		# Environment Sounds
		"door_open": {"volume": 0.7, "pitch": 1.0},
		"door_close": {"volume": 0.7, "pitch": 0.9},
		"explosion": {"volume": 1.0, "pitch": 0.8},
		"portal": {"volume": 0.8, "pitch": 1.1}
	}

func _create_spell_sounds() -> void:
	"""Create spell-specific sound effects"""
	spell_sounds = {
		"fireball": {"volume": 0.8, "pitch": 1.0},
		"ice_shard": {"volume": 0.7, "pitch": 1.2},
		"lightning_bolt": {"volume": 0.9, "pitch": 1.1},
		"shadow_blast": {"volume": 0.8, "pitch": 0.8},
		"healing_light": {"volume": 0.6, "pitch": 1.3},
		"earth_spike": {"volume": 0.9, "pitch": 0.9},
		"wind_slash": {"volume": 0.7, "pitch": 1.1},
		
		# Combination spells
		"frost_nova": {"volume": 0.9, "pitch": 0.9},
		"flame_wave": {"volume": 1.0, "pitch": 0.8},
		"thunder_storm": {"volume": 1.0, "pitch": 0.7},
		"shadow_fire": {"volume": 0.9, "pitch": 0.8},
		"crystal_lance": {"volume": 0.8, "pitch": 1.2},
		"void_storm": {"volume": 1.0, "pitch": 0.6},
		"phoenix_resurrection": {"volume": 0.9, "pitch": 1.4}
	}
	
	# Load music tracks
	_load_music_tracks()
	
	# Load SFX sounds
	_load_sfx_sounds()
	
	print("[AudioManager] Audio resources loaded: ", music_tracks.size(), " music tracks, ", sfx_sounds.size(), " SFX sounds")

func _load_music_tracks() -> void:
	"""Load music tracks from assets/audio/music/"""
	var music_dir = "res://assets/audio/music/"
	var dir = DirAccess.open(music_dir)
	
	if dir == null:
		print("[AudioManager] Music directory not found: ", music_dir)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".ogg") or file_name.ends_with(".mp3"):
			var track_name = file_name.get_basename()
			var track_path = music_dir + file_name
			
			var audio_stream = load(track_path)
			if audio_stream:
				music_tracks[track_name] = audio_stream
				print("[AudioManager] Loaded music track: ", track_name)
			else:
				print("[AudioManager] Failed to load music track: ", track_path)
		
		file_name = dir.get_next()

func _load_sfx_sounds() -> void:
	"""Load SFX sounds from assets/audio/sfx/"""
	var sfx_dir = "res://assets/audio/sfx/"
	var dir = DirAccess.open(sfx_dir)
	
	if dir == null:
		print("[AudioManager] SFX directory not found: ", sfx_dir)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".ogg") or file_name.ends_with(".mp3"):
			var sfx_name = file_name.get_basename()
			var sfx_path = sfx_dir + file_name
			
			var audio_stream = load(sfx_path)
			if audio_stream:
				sfx_sounds[sfx_name] = audio_stream
				print("[AudioManager] Loaded SFX: ", sfx_name)
			else:
				print("[AudioManager] Failed to load SFX: ", sfx_path)
		
		file_name = dir.get_next()

func play_music(track_name: String, fade_time: float = 1.0) -> void:
	"""Play a music track with optional fade transition"""
	if track_name == current_music_track and is_music_playing:
		return  # Already playing this track
	
	if not music_tracks.has(track_name):
		print("[AudioManager] Warning: Music track not found: ", track_name)
		return
	
	print("[AudioManager] Playing music: ", track_name)
	
	# Stop current music if playing
	if is_music_playing:
		stop_music(fade_time * 0.5)
		await get_tree().create_timer(fade_time * 0.5).timeout
	
	# Play new track
	music_player.stream = music_tracks[track_name]
	music_player.play()
	
	current_music_track = track_name
	is_music_playing = true
	
	# TODO: Implement fade in effect
	
	music_started.emit(track_name)

func stop_music(_fade_time: float = 1.0) -> void:
	"""Stop current music with optional fade out"""
	if not is_music_playing:
		return
	
	print("[AudioManager] Stopping music")
	
	# TODO: Implement fade out effect
	music_player.stop()
	
	current_music_track = ""
	is_music_playing = false
	
	music_stopped.emit()

func play_sfx(sfx_name: String, volume: float = 1.0) -> void:
	"""Play a sound effect"""
	if not sfx_sounds.has(sfx_name):
		print("[AudioManager] Warning: SFX not found: ", sfx_name)
		return
	
	# Find available SFX player
	var available_player: AudioStreamPlayer = null
	for player in sfx_players:
		if not player.playing:
			available_player = player
			break
	
	if available_player == null:
		# All players busy, use the first one (interrupt)
		available_player = sfx_players[0]
		print("[AudioManager] Warning: All SFX players busy, interrupting oldest")
	
	# Play the sound
	available_player.stream = sfx_sounds[sfx_name]
	available_player.volume_db = linear_to_db(volume * sfx_volume)
	available_player.play()

func set_master_volume(volume: float) -> void:
	"""Set master volume (0.0 to 1.0)"""
	master_volume = clamp(volume, 0.0, 1.0)
	var bus_index = AudioServer.get_bus_index(MASTER_BUS)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(master_volume))
	
	volume_changed.emit(MASTER_BUS, master_volume)
	print("[AudioManager] Master volume set to: ", master_volume)

func set_music_volume(volume: float) -> void:
	"""Set music volume (0.0 to 1.0)"""
	music_volume = clamp(volume, 0.0, 1.0)
	var bus_index = AudioServer.get_bus_index(MUSIC_BUS)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(music_volume))
	
	volume_changed.emit(MUSIC_BUS, music_volume)
	print("[AudioManager] Music volume set to: ", music_volume)

func set_sfx_volume(volume: float) -> void:
	"""Set SFX volume (0.0 to 1.0)"""
	sfx_volume = clamp(volume, 0.0, 1.0)
	var bus_index = AudioServer.get_bus_index(SFX_BUS)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(sfx_volume))
	
	volume_changed.emit(SFX_BUS, sfx_volume)
	print("[AudioManager] SFX volume set to: ", sfx_volume)

func get_master_volume() -> float:
	"""Get current master volume"""
	return master_volume

func get_music_volume() -> float:
	"""Get current music volume"""
	return music_volume

func get_sfx_volume() -> float:
	"""Get current SFX volume"""
	return sfx_volume

func _load_volume_settings() -> void:
	"""Load volume settings from SaveManager"""
	# Runtime lookup for SaveManager to avoid identifier not found at parse time
	if get_tree() and get_tree().root:
		var sm = get_tree().root.get_node_or_null("SaveManager")
		if sm and sm.has_method("is_data_loaded") and sm.is_data_loaded:
			var settings = sm.current_settings
			if typeof(settings) == TYPE_DICTIONARY and settings.has("audio"):
				var audio_settings = settings["audio"]
				if audio_settings.has("master_volume"):
					set_master_volume(audio_settings["master_volume"])
				if audio_settings.has("music_volume"):
					set_music_volume(audio_settings["music_volume"])
				if audio_settings.has("sfx_volume"):
					set_sfx_volume(audio_settings["sfx_volume"])

func save_volume_settings() -> void:
	"""Save current volume settings"""
	# Try SaveManager first
	if get_tree() and get_tree().root:
		var sm = get_tree().root.get_node_or_null("SaveManager")
		if sm and sm.has_method("current_settings"):
			var settings = sm.current_settings
			if typeof(settings) != TYPE_DICTIONARY:
				settings = {}
			if not settings.has("audio"):
				settings["audio"] = {}
			settings["audio"]["master_volume"] = master_volume
			settings["audio"]["music_volume"] = music_volume
			settings["audio"]["sfx_volume"] = sfx_volume
			if sm.has_method("save_settings"):
				sm.save_settings(settings)
				return

	# Fallback: write to user://settings.json directly
	var cfg = {
		"audio": {
			"master_volume": master_volume,
			"music_volume": music_volume,
			"sfx_volume": sfx_volume
		}
	}
	var file = FileAccess.open(settings_path, FileAccess.WRITE)
	if file:
		# store_var writes a binary-serialised variant; acceptable for settings persistence
		file.store_var(cfg)
		file.close()

# Convenience methods for enhanced SFX
func play_spell_cast_sfx(spell_id: String) -> void:
	"""Play spell casting SFX based on spell ID"""
	if spell_sounds.has(spell_id):
		var spell_data = spell_sounds[spell_id]
		play_sfx_enhanced("spell_cast", spell_data.get("volume", 0.8), spell_data.get("pitch", 1.0))
	else:
		play_sfx("spell_cast")

func play_sfx_enhanced(_sfx_name: String, volume: float = 1.0, pitch: float = 1.0) -> void:
	"""Play a sound effect with custom volume and pitch"""
	# Find available SFX player
	var available_player: AudioStreamPlayer = null
	for player in sfx_players:
		if not player.playing:
			available_player = player
			break
	
	if not available_player:
		available_player = sfx_players[0]  # Use first player if all busy
	
	# Create a simple sine wave tone for placeholder audio
	var audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = 22050
	audio_stream.buffer_length = 0.1
	
	available_player.stream = audio_stream
	available_player.volume_db = linear_to_db(volume * sfx_volume)
	available_player.pitch_scale = pitch
	available_player.play()

func play_biome_music(biome: String) -> void:
	"""Play biome-specific music and ambient sounds"""
	if not biome_tracks.has(biome):
		print("[AudioManager] Warning: Biome music not found: ", biome)
		return
	
	var biome_data = biome_tracks[biome]
	var music_track = biome_data.get("music", "")
	var ambient_track = biome_data.get("ambient", "")
	var intensity = biome_data.get("intensity", 0.7)
	
	# Crossfade to new biome music
	crossfade_to_biome_music(music_track, intensity)
	
	# Play ambient sounds
	if ambient_track != "" and ambient_player:
		play_ambient_sound(ambient_track)
	
	current_biome_track = biome
	print("[AudioManager] Playing biome music: ", biome)

func crossfade_to_biome_music(track_name: String, intensity: float) -> void:
	"""Crossfade between biome music tracks"""
	if crossfade_tween:
		crossfade_tween.kill()
	
	crossfade_tween = create_tween()
	crossfade_tween.set_parallel(true)
	
	# Fade out current music
	if is_music_playing:
		crossfade_tween.tween_property(music_player, "volume_db", -80, 1.0)
	
	# Start new music and fade in
	var target_volume = linear_to_db(music_volume * intensity)
	
	crossfade_tween.tween_callback(func(): _start_new_biome_track(track_name)).set_delay(0.5)
	crossfade_tween.tween_property(music_player, "volume_db", target_volume, 1.0).set_delay(0.5)

func _start_new_biome_track(track_name: String) -> void:
	"""Start playing a new biome track"""
	# For now, create a placeholder audio stream
	var audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = 22050
	audio_stream.buffer_length = 10.0  # Long loop for ambient music
	
	music_player.stream = audio_stream
	music_player.volume_db = -80  # Start silent
	music_player.play()
	
	current_music_track = track_name
	is_music_playing = true
	music_started.emit(track_name)

func play_ambient_sound(_ambient_track: String) -> void:
	"""Play ambient background sounds"""
	if not ambient_player:
		return
	
	# Create ambient audio stream
	var audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = 22050
	audio_stream.buffer_length = 5.0
	
	ambient_player.stream = audio_stream
	ambient_player.volume_db = linear_to_db(ambient_volume)
	ambient_player.play()

func play_enemy_hit_sfx() -> void:
	"""Play enemy hit SFX"""
	play_sfx("hit_impact")

func play_player_hit_sfx() -> void:
	"""Play player hit SFX"""
	play_sfx("player_hurt")

func play_pickup_sfx() -> void:
	"""Play item pickup SFX"""
	play_sfx("pickup_item")

func play_door_sfx() -> void:
	"""Play door opening SFX"""
	play_sfx("door_open")

func play_level_up_sfx() -> void:
	"""Play level up SFX"""
	play_sfx("level_up")

func play_achievement_sfx() -> void:
	"""Play achievement unlock SFX"""
	play_sfx("achievement")

func play_boss_music() -> void:
	"""Switch to boss battle music"""
	play_music("boss_battle", 2.0)

func play_victory_music() -> void:
	"""Play victory music"""
	play_music("victory", 1.0)

func play_defeat_music() -> void:
	"""Play defeat music"""
	play_music("defeat", 1.0)

func set_ambient_volume(volume: float) -> void:
	"""Set ambient volume"""
	ambient_volume = clamp(volume, 0.0, 1.0)
	
	if ambient_player:
		ambient_player.volume_db = linear_to_db(ambient_volume)
	
	volume_changed.emit(AMBIENT_BUS, ambient_volume)
	_save_volume_settings()

# Audio analysis for dynamic effects
func get_music_intensity() -> float:
	"""Get current music intensity for visual effects"""
	if not is_music_playing:
		return 0.0
	
	# This would analyze the current audio stream in a real implementation
	return randf_range(0.3, 1.0)  # Placeholder

func stop_all_audio() -> void:
	"""Stop all audio playback"""
	music_player.stop()
	ambient_player.stop()
	
	for player in sfx_players:
		player.stop()
	
	is_music_playing = false
	current_music_track = ""
	current_biome_track = ""

func pause_all_audio() -> void:
	"""Pause all audio playback"""
	music_player.stream_paused = true
	ambient_player.stream_paused = true

func resume_all_audio() -> void:
	"""Resume all audio playback"""
	music_player.stream_paused = false
	ambient_player.stream_paused = false

func play_dramatic_sting(sting_type: String = "level_up") -> void:
	"""Play dramatic musical sting for special events"""
	var sting_track = "sting_" + sting_type
	var sting_player = _get_available_sfx_player()
	if sting_player and sfx_sounds.has(sting_track):
		sting_player.stream = sfx_sounds[sting_track]
		sting_player.volume_db = linear_to_db(sfx_volume)
		sting_player.play()

func set_dynamic_music_intensity(intensity: float) -> void:
	"""Adjust music intensity based on gameplay situation (0.0 - 1.0)"""
	intensity = clamp(intensity, 0.0, 1.0)
	
	# Adjust volume and filter effects based on intensity
	if music_player:
		# Higher intensity = louder, more dramatic
		var volume_modifier = 0.8 + (intensity * 0.2)
		music_player.volume_db = linear_to_db(music_volume * volume_modifier)
		
		# Add low-pass filter effect at low intensity
		if intensity < 0.3:
			music_player.pitch_scale = 0.9
		else:
			music_player.pitch_scale = 1.0

func crossfade_to_track(track_name: String, fade_duration: float = 2.0) -> void:
	"""Smoothly crossfade to a new music track"""
	if not music_tracks.has(track_name):
		print("[AudioManager] Track not found: ", track_name)
		return
	
	# Create tween for crossfade
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade out current track
	if music_player.playing:
		tween.tween_property(music_player, "volume_db", -80.0, fade_duration * 0.5)
	
	# Switch track at halfway point
	tween.tween_callback(func():
		music_player.stream = music_tracks[track_name]
		music_player.play()
		current_music_track = track_name
	).set_delay(fade_duration * 0.5)
	
	# Fade in new track
	tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), fade_duration * 0.5).set_delay(fade_duration * 0.5)

func play_spell_combo_sfx(combo_name: String) -> void:
	"""Play special sound effect for spell combinations"""
	var combo_sfx = "combo_" + combo_name.to_lower()
	if sfx_sounds.has(combo_sfx):
		play_sfx(combo_sfx)
	else:
		# Fallback to generic combo sound
		play_sfx("spell_combo")

func add_audio_filter_effect(effect_type: String, duration: float = 1.0) -> void:
	"""Add temporary audio filter effects (underwater, echo, etc.)"""
	match effect_type:
		"underwater":
			_apply_underwater_effect(duration)
		"echo":
			_apply_echo_effect(duration)
		"muffled":
			_apply_muffled_effect(duration)
		_:
			print("[AudioManager] Unknown audio effect: ", effect_type)

func _apply_underwater_effect(duration: float) -> void:
	"""Apply underwater-like audio effect"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Lower pitch and volume for underwater effect
	tween.tween_property(music_player, "pitch_scale", 0.7, 0.5)
	for player in sfx_players:
		tween.tween_property(player, "pitch_scale", 0.8, 0.5)
	
	# Restore after duration
	tween.tween_property(music_player, "pitch_scale", 1.0, 0.5).set_delay(duration)
	for player in sfx_players:
		tween.tween_property(player, "pitch_scale", 1.0, 0.5).set_delay(duration)

func _apply_echo_effect(duration: float) -> void:
	"""Apply echo-like audio effect"""
	# This would typically require audio effects nodes in a real implementation
	print("[AudioManager] Echo effect applied for ", duration, " seconds")

func _apply_muffled_effect(duration: float) -> void:
	"""Apply muffled audio effect (like being in a different room)"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Reduce volume temporarily
	var current_music_db = music_player.volume_db
	var _current_sfx_volume = sfx_volume
	
	tween.tween_property(music_player, "volume_db", current_music_db - 10.0, 0.5)
	
	# Restore after duration
	tween.tween_property(music_player, "volume_db", current_music_db, 0.5).set_delay(duration)

func _save_volume_settings() -> void:
	"""Save current volume settings"""
	var settings = {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"ambient_volume": ambient_volume
	}
	# Runtime lookup for SaveManager
	if get_tree() and get_tree().root:
		var sm = get_tree().root.get_node_or_null("SaveManager")
		if sm and sm.has_method("save_settings"):
			sm.save_settings(settings)

func _get_available_sfx_player() -> AudioStreamPlayer:
	"""Get an available SFX player from pool"""
	if not sfx_players:
		return null
	
	for player in sfx_players:
		if player and not player.playing:
			return player
	
	return sfx_players[0] if sfx_players.size() > 0 else null


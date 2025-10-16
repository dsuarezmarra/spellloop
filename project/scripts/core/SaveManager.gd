# SaveManager.gd
# Handles all game saving and loading operations including local storage and Steam Cloud sync
# Manages player progression, settings, and run data persistence
#
# Public API:
# - save_game_data() -> bool
# - load_game_data() -> Dictionary
# - save_run_data(run_data: Dictionary) -> void
# - get_player_progression() -> Dictionary
# - save_settings(settings: Dictionary) -> bool
# - load_settings() -> Dictionary
#
# Signals:
# - save_completed()
# - save_failed(error: String)
# - load_completed(data: Dictionary)
# - load_failed(error: String)

extends Node

signal save_completed()
signal save_failed(error: String)
signal load_completed(data: Dictionary)
signal load_failed(error: String)

# File paths
const SAVE_DIR = "user://saves/"
const SAVE_FILE = "user://saves/game_data.json"
const SETTINGS_FILE = "user://settings.json"
const RUN_HISTORY_FILE = "user://saves/run_history.json"

# Default save data structure
const DEFAULT_SAVE_DATA = {
	"version": "1.0.0",
	"player_data": {
		"unlocked_mages": ["fire_mage"],  # Starting with fire mage unlocked
		"meta_currency": 0,
		"unlocked_spells": ["fireball", "ice_shard"],
		"unlocked_talents": [],
		"unlocked_runes": [],
		"total_runs": 0,
		"best_score": 0,
		"total_playtime": 0.0
	},
	"achievements": {},
	"statistics": {
		"enemies_defeated": 0,
		"spells_cast": 0,
		"rooms_completed": 0,
		"bosses_defeated": 0
	}
}

# Default settings
const DEFAULT_SETTINGS = {
	"version": "1.0.0",
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0
	},
	"video": {
		"fullscreen": false,
		"vsync": true,
		"resolution": "1280x720"
	},
	"language": "en",
	"input": {
		"custom_keybinds": {}
	}
}

# Current loaded data
var current_save_data: Dictionary = {}
var current_settings: Dictionary = {}
var is_data_loaded: bool = false

func _ready() -> void:
	print("[SaveManager] Initializing SaveManager...")
	
	# Create save directory if it doesn't exist
	_ensure_save_directory()
	
	# Load existing data
	_load_all_data()
	
	print("[SaveManager] SaveManager initialized successfully")

func _ensure_save_directory() -> void:
	"""Ensure the save directory exists"""
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.open("user://").make_dir_recursive("saves")
		print("[SaveManager] Created save directory: ", SAVE_DIR)

func _load_all_data() -> void:
	"""Load all game data on startup"""
	current_save_data = load_game_data()
	current_settings = load_settings()
	is_data_loaded = true

func save_game_data() -> bool:
	"""Save current game data to file"""
	print("[SaveManager] Saving game data...")
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file == null:
		var error = "Failed to open save file for writing: " + SAVE_FILE
		print("[SaveManager] Error: ", error)
		save_failed.emit(error)
		return false
	
	var json_string = JSON.stringify(current_save_data)
	file.store_string(json_string)
	file.close()
	
	print("[SaveManager] Game data saved successfully")
	save_completed.emit()
	
	# TODO: Sync with Steam Cloud if available
	_sync_steam_cloud()
	
	return true

func load_game_data() -> Dictionary:
	"""Load game data from file"""
	print("[SaveManager] Loading game data...")
	
	if not FileAccess.file_exists(SAVE_FILE):
		print("[SaveManager] No save file found, using default data")
		current_save_data = DEFAULT_SAVE_DATA.duplicate(true)
		save_game_data()  # Create initial save file
		return current_save_data
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file == null:
		var error = "Failed to open save file for reading: " + SAVE_FILE
		print("[SaveManager] Error: ", error)
		load_failed.emit(error)
		return DEFAULT_SAVE_DATA.duplicate(true)
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		var error = "Failed to parse save file JSON"
		print("[SaveManager] Error: ", error)
		load_failed.emit(error)
		return DEFAULT_SAVE_DATA.duplicate(true)
	
	var loaded_data = json.data
	
	# Validate and merge with default structure
	current_save_data = _validate_save_data(loaded_data)
	
	print("[SaveManager] Game data loaded successfully")
	load_completed.emit(current_save_data)
	
	return current_save_data

func save_run_data(run_data: Dictionary) -> void:
	"""Save completed run data for progression"""
	print("[SaveManager] Saving run data...")
	
	# Update player progression based on run
	_process_run_progression(run_data)
	
	# Save run to history
	_save_run_history(run_data)
	
	# Save updated game data
	save_game_data()

func _process_run_progression(run_data: Dictionary) -> void:
	"""Process run data and update player progression"""
	if not current_save_data.has("player_data"):
		return
	
	var player_data = current_save_data["player_data"]
	var stats = current_save_data["statistics"]
	
	# Update statistics
	if run_data.has("enemies_defeated"):
		stats["enemies_defeated"] += run_data["enemies_defeated"]
	if run_data.has("spells_cast"):
		stats["spells_cast"] += run_data["spells_cast"]
	if run_data.has("rooms_completed"):
		stats["rooms_completed"] += run_data["rooms_completed"]
	
	# Update best score
	if run_data.has("score") and run_data["score"] > player_data["best_score"]:
		player_data["best_score"] = run_data["score"]
	
	# Add meta currency based on performance
	var currency_gained = _calculate_meta_currency(run_data)
	player_data["meta_currency"] += currency_gained
	
	# Increment total runs
	player_data["total_runs"] += 1
	
	# Add playtime
	if run_data.has("duration"):
		player_data["total_playtime"] += run_data["duration"]

func _calculate_meta_currency(run_data: Dictionary) -> int:
	"""Calculate meta currency gained from a run"""
	var base_currency = 10
	var bonus = 0
	
	# Bonus for rooms completed
	if run_data.has("rooms_completed"):
		bonus += run_data["rooms_completed"] * 2
	
	# Bonus for enemies defeated
	if run_data.has("enemies_defeated"):
		bonus += run_data["enemies_defeated"]
	
	# Bonus for bosses defeated
	if run_data.has("bosses_defeated"):
		bonus += run_data.get("bosses_defeated", 0) * 20
	
	return base_currency + bonus

func _save_run_history(run_data: Dictionary) -> void:
	"""Save run to history file"""
	var history = []
	
	if FileAccess.file_exists(RUN_HISTORY_FILE):
		var history_file = FileAccess.open(RUN_HISTORY_FILE, FileAccess.READ)
		if history_file:
			var json = JSON.new()
			var parse_result = json.parse(history_file.get_as_text())
			history_file.close()
			
			if parse_result == OK and json.data is Array:
				history = json.data
	
	# Add new run to history
	history.append(run_data)
	
	# Keep only last 100 runs
	if history.size() > 100:
		history = history.slice(-100)
	
	# Save updated history
	var save_file = FileAccess.open(RUN_HISTORY_FILE, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(history))
		save_file.close()

func save_settings(settings: Dictionary) -> bool:
	"""Save game settings"""
	print("[SaveManager] Saving settings...")
	
	current_settings = settings
	
	var settings_file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if settings_file == null:
		var error = "Failed to open settings file for writing"
		print("[SaveManager] Error: ", error)
		return false
	
	var json_string = JSON.stringify(settings)
	settings_file.store_string(json_string)
	settings_file.close()
	
	print("[SaveManager] Settings saved successfully")
	return true

func load_settings() -> Dictionary:
	"""Load game settings"""
	print("[SaveManager] Loading settings...")
	
	if not FileAccess.file_exists(SETTINGS_FILE):
		print("[SaveManager] No settings file found, using defaults")
		current_settings = DEFAULT_SETTINGS.duplicate(true)
		save_settings(current_settings)
		return current_settings
	
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
	if file == null:
		print("[SaveManager] Failed to open settings file, using defaults")
		return DEFAULT_SETTINGS.duplicate(true)
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("[SaveManager] Failed to parse settings JSON, using defaults")
		return DEFAULT_SETTINGS.duplicate(true)
	
	current_settings = _validate_settings(json.data)
	print("[SaveManager] Settings loaded successfully")
	
	return current_settings

func get_player_progression() -> Dictionary:
	"""Get current player progression data"""
	if current_save_data.has("player_data"):
		return current_save_data["player_data"]
	return DEFAULT_SAVE_DATA["player_data"].duplicate(true)

func unlock_mage(mage_id: String) -> void:
	"""Unlock a new mage"""
	var player_data = get_player_progression()
	if mage_id not in player_data["unlocked_mages"]:
		player_data["unlocked_mages"].append(mage_id)
		save_game_data()
		print("[SaveManager] Unlocked mage: ", mage_id)

func unlock_spell(spell_id: String) -> void:
	"""Unlock a new spell"""
	var player_data = get_player_progression()
	if spell_id not in player_data["unlocked_spells"]:
		player_data["unlocked_spells"].append(spell_id)
		save_game_data()
		print("[SaveManager] Unlocked spell: ", spell_id)

func spend_meta_currency(amount: int) -> bool:
	"""Spend meta currency if available"""
	var player_data = get_player_progression()
	if player_data["meta_currency"] >= amount:
		player_data["meta_currency"] -= amount
		save_game_data()
		return true
	return false

func save_dungeon_completion(dungeon_seed: int, rewards: Dictionary) -> void:
	"""Save dungeon completion data"""
	print("[SaveManager] Saving dungeon completion...")
	
	var run_data = {
		"type": "dungeon",
		"seed": dungeon_seed,
		"rewards": rewards,
		"timestamp": Time.get_unix_time_from_system(),
		"duration": 0  # Placeholder
	}
	
	save_run_data(run_data)

func _validate_save_data(data: Dictionary) -> Dictionary:
	"""Validate loaded save data and merge with defaults"""
	var validated_data = DEFAULT_SAVE_DATA.duplicate(true)
	
	# TODO: Implement proper data validation and migration
	if data.has("version") and data.has("player_data"):
		validated_data.merge(data, true)
	
	return validated_data

func _validate_settings(data: Dictionary) -> Dictionary:
	"""Validate loaded settings and merge with defaults"""
	var validated_settings = DEFAULT_SETTINGS.duplicate(true)
	
	# TODO: Implement proper settings validation
	if data.has("version"):
		validated_settings.merge(data, true)
	
	return validated_settings

func _sync_steam_cloud() -> void:
	"""Sync save data with Steam Cloud (placeholder)"""
	# TODO: Implement Steam Cloud sync
	print("[SaveManager] Steam Cloud sync placeholder - not implemented yet")

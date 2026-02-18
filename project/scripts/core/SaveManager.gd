# SaveManager.gd
# Handles all game saving and loading operations including local storage and Steam Cloud sync
# Manages player progression, settings, and run data persistence
# SUPPORTS MULTIPLE SAVE SLOTS (like The Binding of Isaac)
#
# Public API:
# - save_game_data() -> bool
# - load_game_data() -> Dictionary
# - save_run_data(run_data: Dictionary) -> void
# - get_player_progression() -> Dictionary
# - save_settings(settings: Dictionary) -> bool
# - load_settings() -> Dictionary
# - set_active_slot(slot_index: int) -> void
# - get_slot_data(slot_index: int) -> Dictionary
# - delete_slot(slot_index: int) -> void
#
# Signals:
# - save_completed()
# - save_failed(error: String)
# - load_completed(data: Dictionary)
# - load_failed(error: String)
# - slot_changed(slot_index: int)

extends Node

signal save_completed()
signal save_failed(error: String)
signal load_completed(data: Dictionary)
signal load_failed(error: String)
signal meta_changed(key: String, value)
signal player_data_changed(data: Dictionary)
signal slot_changed(slot_index: int)

# Número de slots de guardado
const NUM_SAVE_SLOTS = 3

# Slot activo actual
var active_slot: int = -1  # -1 = ninguno seleccionado

# File paths
const SAVE_DIR = "user://saves/"
const SLOT_FILE_TEMPLATE = "user://saves/slot_%d.json"
const SETTINGS_FILE = "user://settings.json"
const SLOT_CONFIG_FILE = "user://saves/slot_config.json"

# Legacy (para migración)
const LEGACY_SAVE_FILE = "user://saves/game_data.json"
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

# Meta-shop persistent data (se guarda en user://meta.json)
const META_FILE = "user://meta.json"
var meta_data: Dictionary = {}

const DEFAULT_META = {
	"unlocked_weapon_slots": 6,
	"luck_points": 0,
	"pickup_radius_bonus": 0.0,
	"unlocked_weapons_cap": 6,
	"shop_purchases": {}
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
	# Debug desactivado: print("[SaveManager] Initializing SaveManager...")

	# Create save directory if it doesn't exist
	_ensure_save_directory()

	# Migrar datos legacy si existe
	_migrate_legacy_save()

	# Load meta persistence (shop) - compartido entre slots
	_load_meta()

	# Cargar configuración de slot (último slot usado)
	_load_slot_config()

	# Load settings
	current_settings = load_settings()

	# Debug desactivado: print("[SaveManager] SaveManager initialized successfully")

func _ensure_save_directory() -> void:
	"""Ensure the save directory exists"""
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.open("user://").make_dir_recursive("saves")
		# Debug desactivado: print("[SaveManager] Created save directory: ", SAVE_DIR)

func _load_all_data() -> void:
	"""Load all game data on startup - DEPRECATED, usar set_active_slot"""
	# Ya no cargamos datos automáticamente - esperamos selección de slot
	current_settings = load_settings()

	# Ensure meta defaults applied
	if meta_data == {}:
		meta_data = DEFAULT_META.duplicate(true)

func save_game_data() -> bool:
	"""Save current game data to the active slot"""
	if not has_active_slot():
		push_warning("[SaveManager] No hay slot activo para guardar")
		return false

	# Guardar en el slot activo
	if not _save_slot_data(active_slot, current_save_data):
		save_failed.emit("Error al guardar en slot %d" % active_slot)
		return false

	save_completed.emit()

	# Emit player data changed so UI can sync authoritative values
	if current_save_data.has("player_data"):
		player_data_changed.emit(current_save_data["player_data"].duplicate(true))

	# TODO: Sync with Steam Cloud if available
	_sync_steam_cloud()

	return true

func _load_meta() -> void:
	"""Load meta-shop persistence from user://meta.json"""
	if not FileAccess.file_exists(META_FILE):
		meta_data = DEFAULT_META.duplicate(true)
		_save_meta()
		return

	var f = FileAccess.open(META_FILE, FileAccess.READ)
	if not f:
		meta_data = DEFAULT_META.duplicate(true)
		return
	var json = JSON.new()
	var parse_result = json.parse(f.get_as_text())
	f.close()
	if parse_result != OK:
		meta_data = DEFAULT_META.duplicate(true)
		return
	if not json.data is Dictionary:
		push_warning("[SaveManager] meta.json no contiene un Dictionary válido, reseteando")
		meta_data = DEFAULT_META.duplicate(true)
		return
	meta_data = json.data

func _save_meta() -> bool:
	var f = FileAccess.open(META_FILE, FileAccess.WRITE)
	if not f:
		push_warning("[SaveManager] Error al abrir meta file para escribir")
		return false
	f.store_string(JSON.stringify(meta_data))
	f.close()
	# Notify listeners that meta data was updated
	meta_changed.emit("__meta_full_update__", meta_data.duplicate(true))
	return true

func get_meta_data() -> Dictionary:
	# Return a copy of meta data, ensure defaults applied
	if meta_data == {}:
		meta_data = DEFAULT_META.duplicate(true)
	return meta_data

func add_meta_luck(points: int) -> void:
	if not meta_data.has("luck_points"):
		meta_data["luck_points"] = 0
	meta_data["luck_points"] += points
	_save_meta()
	# Emit specific meta change for luck points
	meta_changed.emit("luck_points", meta_data["luck_points"])

func set_meta_value(key: String, value) -> void:
	meta_data[key] = value
	_save_meta()
	# Emit change for this meta key
	meta_changed.emit(key, meta_data[key])

func spend_meta_currency_from_meta(amount: int) -> bool:
	# Spend from meta_currency in save data
	var player_data = get_player_progression()
	if player_data["meta_currency"] >= amount:
		player_data["meta_currency"] -= amount
		save_game_data()
		return true
	return false

func load_game_data() -> Dictionary:
	"""Load game data from active slot"""
	if not has_active_slot():
		push_warning("[SaveManager] No hay slot activo, usando datos por defecto")
		return DEFAULT_SAVE_DATA.duplicate(true)

	var slot_data = _load_slot_data(active_slot)

	if slot_data.is_empty():
		# Slot vacío - crear datos nuevos
		current_save_data = DEFAULT_SAVE_DATA.duplicate(true)
		save_game_data()  # Guardar datos iniciales
		return current_save_data

	current_save_data = slot_data
	is_data_loaded = true

	load_completed.emit(current_save_data)
	return current_save_data

func save_run_data(run_data: Dictionary) -> void:
	"""Save completed run data for progression"""
	# Debug desactivado: print("[SaveManager] Saving run data...")

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

	# Calculate Score logic
	var score = run_data.get("score", 0)
	if score == 0:
		# Calculate score if not provided
		# Example: 10 pts per enemy, 1 pt per second survived (approx)
		var enemies = run_data.get("enemies_defeated", 0)
		var duration = run_data.get("duration", 0)
		score = (enemies * 10) + int(duration)

	# Update best score
	if score > player_data.get("best_score", 0):
		player_data["best_score"] = score

	# Add meta currency based on performance
	var currency_gained = _calculate_meta_currency(run_data)
	player_data["meta_currency"] += currency_gained

	# Increment total runs
	player_data["total_runs"] += 1

	# Add playtime (accumulator)
	# Add playtime (handled via explicit add_playtime calls now)
	# Playtime is updated incrementally via Game.save_session_playtime -> SaveManager.add_playtime
	pass

func add_playtime(seconds: float) -> void:
	"""Add seconds to total playtime and save"""
	if seconds <= 0: return

	var player_data = get_player_progression()
	var current_time = player_data.get("total_playtime", 0.0)
	player_data["total_playtime"] = current_time + seconds

	save_game_data()
	# Debug desactivado: print("[SaveManager] Playtime updated: +%.1fs (Total: %.1fh)" % [seconds, player_data["total_playtime"]/3600.0])

	# Emit player data changed so UI can update immediately
	player_data_changed.emit(player_data.duplicate(true))

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
	# Debug desactivado: print("[SaveManager] Saving settings...")

	current_settings = settings

	var settings_file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if settings_file == null:
		var error = "Failed to open settings file for writing"
		push_warning("[SaveManager] Error: " + error)
		return false

	var json_string = JSON.stringify(settings)
	settings_file.store_string(json_string)
	settings_file.close()

	# Debug desactivado: print("[SaveManager] Settings saved successfully")
	return true

func load_settings() -> Dictionary:
	"""Load game settings"""
	# Debug desactivado: print("[SaveManager] Loading settings...")

	if not FileAccess.file_exists(SETTINGS_FILE):
		# Debug desactivado: print("[SaveManager] No settings file found, using defaults")
		current_settings = DEFAULT_SETTINGS.duplicate(true)
		save_settings(current_settings)
		return current_settings

	var file = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
	if file == null:
		# Debug desactivado: print("[SaveManager] Failed to open settings file, using defaults")
		return DEFAULT_SETTINGS.duplicate(true)

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		# Debug desactivado: print("[SaveManager] Failed to parse settings JSON, using defaults")
		return DEFAULT_SETTINGS.duplicate(true)

	current_settings = _validate_settings(json.data)
	# Debug desactivado: print("[SaveManager] Settings loaded successfully")

	return current_settings

func get_player_progression() -> Dictionary:
	"""Get current player progression data (always returns reference to current_save_data)"""
	if not current_save_data.has("player_data"):
		current_save_data["player_data"] = DEFAULT_SAVE_DATA["player_data"].duplicate(true)
	return current_save_data["player_data"]

func unlock_mage(mage_id: String) -> void:
	"""Unlock a new mage"""
	var player_data = get_player_progression()
	if mage_id not in player_data["unlocked_mages"]:
		player_data["unlocked_mages"].append(mage_id)
		save_game_data()
		# STEAM ACHIEVEMENTS: Notificar desbloqueo de mago
		if SteamAchievements:
			SteamAchievements.on_mage_unlocked(player_data["unlocked_mages"].size())
		# Debug desactivado: print("[SaveManager] Unlocked mage: ", mage_id)

func unlock_spell(spell_id: String) -> void:
	"""Unlock a new spell"""
	var player_data = get_player_progression()
	if spell_id not in player_data["unlocked_spells"]:
		player_data["unlocked_spells"].append(spell_id)
		save_game_data()
		# Debug desactivado: print("[SaveManager] Unlocked spell: ", spell_id)

func spend_meta_currency(amount: int) -> bool:
	"""Spend meta currency if available"""
	var player_data = get_player_progression()
	if player_data["meta_currency"] >= amount:
		player_data["meta_currency"] -= amount
		save_game_data()
		return true
	return false

func save_dungeon_completion(dungeon_seed: int, rewards: Dictionary, duration: float = 0.0) -> void:
	"""Save dungeon completion data"""
	# Debug desactivado: print("[SaveManager] Saving dungeon completion...")

	var ts = null
	# Try dynamic Time.get_unix_time_from_system() if available
	if Time and Time.has_method("get_unix_time_from_system"):
		var val = Time.call("get_unix_time_from_system")
		if typeof(val) in [TYPE_INT, TYPE_FLOAT]:
			ts = float(val)
	# Fallback to GameManager/LoopiaLikeGame helper if available
	if ts == null and get_tree() and get_tree().root and get_tree().root.get_node_or_null("GameManager"):
		var gm = get_tree().root.get_node("GameManager")
		if gm and gm.has_method("get_unix_time_safe"):
			ts = float(gm.get_unix_time_safe())
	if ts == null:
		ts = float(Engine.get_physics_frames())

	var run_data = {
		"type": "dungeon",
		"seed": dungeon_seed,
		"rewards": rewards,
		"timestamp": ts,
		"duration": duration,
		"score": 0 # Let _process_run_progression calculate it based on stats
	}

	save_run_data(run_data)

func _validate_save_data(data: Dictionary) -> Dictionary:
	"""Validate loaded save data field-by-field with type checking + version migration."""
	var validated = DEFAULT_SAVE_DATA.duplicate(true)

	if data.is_empty():
		return validated

	# Version migration
	var data_version := str(data.get("version", "0.0.0"))
	validated["version"] = DEFAULT_SAVE_DATA["version"]

	# --- player_data ---
	if data.has("player_data") and data["player_data"] is Dictionary:
		var pd: Dictionary = data["player_data"]
		var vpd: Dictionary = validated["player_data"]

		if pd.has("unlocked_mages") and pd["unlocked_mages"] is Array:
			# Asegurar que fire_mage siempre esté
			var mages: Array = pd["unlocked_mages"].duplicate()
			if "fire_mage" not in mages:
				mages.insert(0, "fire_mage")
			vpd["unlocked_mages"] = mages

		if pd.has("meta_currency") and (pd["meta_currency"] is int or pd["meta_currency"] is float):
			vpd["meta_currency"] = maxi(0, int(pd["meta_currency"]))

		if pd.has("unlocked_spells") and pd["unlocked_spells"] is Array:
			var spells: Array = pd["unlocked_spells"].duplicate()
			for starter in ["fireball", "ice_shard"]:
				if starter not in spells:
					spells.append(starter)
			vpd["unlocked_spells"] = spells

		for arr_key in ["unlocked_talents", "unlocked_runes"]:
			if pd.has(arr_key) and pd[arr_key] is Array:
				vpd[arr_key] = pd[arr_key].duplicate()

		for int_key in ["total_runs", "best_score"]:
			if pd.has(int_key) and (pd[int_key] is int or pd[int_key] is float):
				vpd[int_key] = maxi(0, int(pd[int_key]))

		if pd.has("total_playtime") and (pd["total_playtime"] is int or pd["total_playtime"] is float):
			vpd["total_playtime"] = maxf(0.0, float(pd["total_playtime"]))

	# --- achievements ---
	if data.has("achievements") and data["achievements"] is Dictionary:
		validated["achievements"] = data["achievements"].duplicate(true)

	# --- statistics ---
	if data.has("statistics") and data["statistics"] is Dictionary:
		var src: Dictionary = data["statistics"]
		var dst: Dictionary = validated["statistics"]
		for key in dst.keys():
			if src.has(key) and (src[key] is int or src[key] is float):
				dst[key] = maxi(0, int(src[key]))
		# Preserve extra stats from newer versions
		for key in src.keys():
			if key not in dst and (src[key] is int or src[key] is float):
				dst[key] = maxi(0, int(src[key]))

	# Apply version migrations (expand as needed)
	if data_version < "1.0.0":
		push_warning("[SaveManager] Migrating save from v%s -> v%s" % [data_version, validated["version"]])

	return validated

func _validate_settings(data: Dictionary) -> Dictionary:
	"""Validate loaded settings with type checking and range clamping."""
	var validated = DEFAULT_SETTINGS.duplicate(true)

	if data.is_empty():
		return validated

	validated["version"] = DEFAULT_SETTINGS["version"]

	# --- audio ---
	if data.has("audio") and data["audio"] is Dictionary:
		var src: Dictionary = data["audio"]
		for vol_key in ["master_volume", "music_volume", "sfx_volume"]:
			if src.has(vol_key) and (src[vol_key] is float or src[vol_key] is int):
				validated["audio"][vol_key] = clampf(float(src[vol_key]), 0.0, 1.0)

	# --- video ---
	if data.has("video") and data["video"] is Dictionary:
		var src: Dictionary = data["video"]
		if src.has("fullscreen") and src["fullscreen"] is bool:
			validated["video"]["fullscreen"] = src["fullscreen"]
		if src.has("vsync") and src["vsync"] is bool:
			validated["video"]["vsync"] = src["vsync"]
		if src.has("resolution") and src["resolution"] is String:
			var parts = src["resolution"].split("x")
			if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
				validated["video"]["resolution"] = src["resolution"]

	# --- language ---
	if data.has("language") and data["language"] is String:
		validated["language"] = data["language"]

	# --- input ---
	if data.has("input") and data["input"] is Dictionary:
		if data["input"].has("custom_keybinds") and data["input"]["custom_keybinds"] is Dictionary:
			validated["input"]["custom_keybinds"] = data["input"]["custom_keybinds"].duplicate(true)

	return validated

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE SLOTS DE GUARDADO
# ═══════════════════════════════════════════════════════════════════════════════

func _get_slot_file_path(slot_index: int) -> String:
	"""Obtener la ruta del archivo para un slot específico"""
	return SLOT_FILE_TEMPLATE % slot_index

func _load_slot_config() -> void:
	"""Cargar configuración de slots (último slot usado, etc.)"""
	if not FileAccess.file_exists(SLOT_CONFIG_FILE):
		return

	var file = FileAccess.open(SLOT_CONFIG_FILE, FileAccess.READ)
	if not file:
		return

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()

	if parse_result == OK and json.data is Dictionary:
		# No cargar automáticamente el último slot - esperar selección del usuario
		pass

func _save_slot_config() -> void:
	"""Guardar configuración de slots"""
	var config = {
		"last_active_slot": active_slot
	}

	var file = FileAccess.open(SLOT_CONFIG_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(config))
		file.close()

func _migrate_legacy_save() -> void:
	"""Migrar guardado legacy (pre-slots) al Slot 1"""
	if not FileAccess.file_exists(LEGACY_SAVE_FILE):
		return

	# Verificar si ya existe el Slot 0
	var slot_0_path = _get_slot_file_path(0)
	if FileAccess.file_exists(slot_0_path):
		return  # Ya migrado

	# Migrar
	var legacy_file = FileAccess.open(LEGACY_SAVE_FILE, FileAccess.READ)
	if legacy_file:
		var legacy_data = legacy_file.get_as_text()
		legacy_file.close()

		# Guardar en Slot 0
		var slot_file = FileAccess.open(slot_0_path, FileAccess.WRITE)
		if slot_file:
			slot_file.store_string(legacy_data)
			slot_file.close()
			print("[SaveManager] ✓ Datos legacy migrados al Slot 1")

func set_active_slot(slot_index: int) -> void:
	"""Establecer el slot activo y cargar sus datos"""
	if slot_index < 0 or slot_index >= NUM_SAVE_SLOTS:
		push_warning("[SaveManager] Índice de slot inválido: %d" % slot_index)
		return

	active_slot = slot_index
	_save_slot_config()

	# Cargar datos del slot
	current_save_data = _load_slot_data(slot_index)
	is_data_loaded = true

	slot_changed.emit(slot_index)
	load_completed.emit(current_save_data)

	print("[SaveManager] ✓ Slot %d activado" % (slot_index + 1))

func get_active_slot() -> int:
	"""Obtener el índice del slot activo"""
	return active_slot

func has_active_slot() -> bool:
	"""Verificar si hay un slot activo seleccionado"""
	return active_slot >= 0 and active_slot < NUM_SAVE_SLOTS

func get_slot_data(slot_index: int) -> Dictionary:
	"""Obtener datos de un slot específico (para preview)"""
	if slot_index < 0 or slot_index >= NUM_SAVE_SLOTS:
		return {}

	return _load_slot_data(slot_index)

func _load_slot_data(slot_index: int) -> Dictionary:
	"""Cargar datos de un slot específico"""
	var slot_path = _get_slot_file_path(slot_index)

	if not FileAccess.file_exists(slot_path):
		return {}  # Slot vacío

	var file = FileAccess.open(slot_path, FileAccess.READ)
	if not file:
		return {}

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()

	if parse_result != OK or not json.data is Dictionary:
		return {}

	return _validate_save_data(json.data)

func _save_slot_data(slot_index: int, data: Dictionary) -> bool:
	"""Guardar datos en un slot específico"""
	var slot_path = _get_slot_file_path(slot_index)

	var file = FileAccess.open(slot_path, FileAccess.WRITE)
	if not file:
		push_warning("[SaveManager] Error al abrir slot %d para escritura" % slot_index)
		return false

	file.store_string(JSON.stringify(data))
	file.close()
	return true

func delete_slot(slot_index: int) -> void:
	"""Borrar un slot de guardado"""
	if slot_index < 0 or slot_index >= NUM_SAVE_SLOTS:
		return

	var slot_path = _get_slot_file_path(slot_index)

	if FileAccess.file_exists(slot_path):
		DirAccess.remove_absolute(slot_path)
		print("[SaveManager] ✓ Slot %d borrado" % (slot_index + 1))

	# Si era el slot activo, desactivar
	if active_slot == slot_index:
		active_slot = -1
		current_save_data = {}
		is_data_loaded = false

func slot_has_data(slot_index: int) -> bool:
	"""Verificar si un slot tiene datos guardados"""
	if slot_index < 0 or slot_index >= NUM_SAVE_SLOTS:
		return false

	var slot_path = _get_slot_file_path(slot_index)
	return FileAccess.file_exists(slot_path)

func _sync_steam_cloud() -> void:
	"""Sync save data with Steam Cloud using GodotSteam Remote Storage API.
	Handles upload, download, and conflict resolution (newest wins)."""
	var steam_mgr = get_node_or_null("/root/SteamManager")
	if not steam_mgr or not steam_mgr.is_steam_available:
		return  # Steam not available — silent skip

	if not active_slot >= 0:
		return

	var _steam = steam_mgr.get("_steam")
	if _steam == null:
		return

	# Verify Remote Storage is enabled
	if _steam.has_method("isCloudEnabledForAccount") and not _steam.isCloudEnabledForAccount():
		push_warning("[SaveManager] Steam Cloud disabled by user account settings")
		return
	if _steam.has_method("isCloudEnabledForApp") and not _steam.isCloudEnabledForApp():
		push_warning("[SaveManager] Steam Cloud disabled for this app")
		return

	var cloud_filename := "slot_%d.json" % active_slot

	# --- UPLOAD current local save ---
	var local_json := JSON.stringify(current_save_data, "\t")
	var local_bytes := local_json.to_utf8_buffer()

	if _steam.has_method("fileWrite"):
		var success = _steam.fileWrite(cloud_filename, local_bytes, local_bytes.size())
		if success:
			pass  # Upload OK
		else:
			push_warning("[SaveManager] Steam Cloud upload failed for %s" % cloud_filename)

func _download_steam_cloud_save(slot_index: int) -> Dictionary:
	"""Download save data from Steam Cloud for conflict checking.
	Returns empty Dictionary if no cloud save or Steam unavailable."""
	var steam_mgr = get_node_or_null("/root/SteamManager")
	if not steam_mgr or not steam_mgr.is_steam_available:
		return {}

	var _steam = steam_mgr.get("_steam")
	if _steam == null:
		return {}

	var cloud_filename := "slot_%d.json" % slot_index

	if not _steam.has_method("fileExists") or not _steam.fileExists(cloud_filename):
		return {}

	if not _steam.has_method("fileRead"):
		return {}

	var file_size: int = 0
	if _steam.has_method("getFileSize"):
		file_size = _steam.getFileSize(cloud_filename)
	if file_size <= 0:
		return {}

	var data_dict: Dictionary = _steam.fileRead(cloud_filename, file_size)
	if data_dict.is_empty() or not data_dict.has("buf"):
		return {}

	var json_text: String = data_dict["buf"].get_string_from_utf8()
	var json := JSON.new()
	if json.parse(json_text) != OK:
		push_warning("[SaveManager] Steam Cloud save corrupted for %s" % cloud_filename)
		return {}

	if json.data is Dictionary:
		return json.data

	return {}

func resolve_cloud_conflict(slot_index: int) -> void:
	"""Compare local vs cloud save and keep the one with more progress.
	Uses total_runs + total_playtime as heuristic."""
	var cloud_data := _download_steam_cloud_save(slot_index)
	if cloud_data.is_empty():
		return  # No cloud save — nothing to resolve

	var local_path := _get_slot_file_path(slot_index)
	if not FileAccess.file_exists(local_path):
		# No local save, adopt cloud
		current_save_data = _validate_save_data(cloud_data)
		_save_slot_data(slot_index, current_save_data)
		print("[SaveManager] Adopted cloud save for slot %d (no local)" % slot_index)
		return

	# Compare progress: more runs + more playtime = more "advanced"
	var local_pd: Dictionary = current_save_data.get("player_data", {})
	var cloud_pd: Dictionary = cloud_data.get("player_data", {})

	var local_score: float = float(local_pd.get("total_runs", 0)) + float(local_pd.get("total_playtime", 0.0)) / 3600.0
	var cloud_score: float = float(cloud_pd.get("total_runs", 0)) + float(cloud_pd.get("total_playtime", 0.0)) / 3600.0

	if cloud_score > local_score + 0.5:
		# Cloud is ahead — adopt cloud data
		current_save_data = _validate_save_data(cloud_data)
		_save_slot_data(slot_index, current_save_data)
		print("[SaveManager] Cloud save adopted for slot %d (cloud: %.1f > local: %.1f)" % [slot_index, cloud_score, local_score])
	else:
		# Local is ahead or equal — upload local to cloud
		print("[SaveManager] Local save kept for slot %d (local: %.1f >= cloud: %.1f)" % [slot_index, local_score, cloud_score])


# BalanceTelemetry.gd
# Sistema de telemetría de balance para análisis de runs
# Genera 1 archivo JSONL por run en user://balance_logs/
# Toggle: enabled = true/false, CLI: --enable-balance-telemetry / --disable-balance-telemetry
extends Node

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

const SCHEMA_VERSION: int = 1
const LOG_DIR: String = "user://balance_logs"

var enabled: bool = true
var _run_active: bool = false

# ═══════════════════════════════════════════════════════════════════════════════
# RUN STATE
# ═══════════════════════════════════════════════════════════════════════════════

var _session_id: String = ""
var _run_id: int = 0
var _run_seed: int = 0
var _current_log_file: String = ""
var _run_start_time_ms: int = 0
var _last_minute_logged: int = -1

# ═══════════════════════════════════════════════════════════════════════════════
# ROLLING COUNTERS (reset each minute_snapshot)
# ═══════════════════════════════════════════════════════════════════════════════

var _damage_dealt_last_60s: int = 0
var _damage_taken_last_60s: int = 0
var _healing_done_last_60s: int = 0
var _kills_last_60s: int = 0
var _elites_killed_last_60s: int = 0
var _bosses_killed_last_60s: int = 0
var _gold_gained_last_60s: int = 0
var _rerolls_used_last_60s: int = 0
var _chests_opened_last_60s: int = 0
var _fusions_obtained_total: int = 0
var _rerolls_used_total: int = 0
var _chests_opened_total: int = 0

# DPS estimation buffer (last 30s of damage samples)
var _dps_samples: Array[int] = []
var _dps_sample_timer: float = 0.0
const DPS_SAMPLE_INTERVAL: float = 1.0  # Sample every 1 second
const DPS_SAMPLES_COUNT: int = 30  # Keep 30 seconds

# XP rolling buffer for xp_per_min calculation
var _xp_samples: Array[Dictionary] = []  # {time_min: float, xp: int}
const XP_ROLLING_MINUTES: float = 3.0

# Level history for levels_per_min
var _level_at_start: int = 1
var _levels_gained_this_run: int = 0

# ═══════════════════════════════════════════════════════════════════════════════
# POLLING STATE (for delta calculations from run_stats)
# ═══════════════════════════════════════════════════════════════════════════════

var _poll_timer: float = 0.0
const POLL_INTERVAL: float = 1.0  # Poll every 1 second

# Previous values for delta calculation
var _prev_kills: int = 0
var _prev_damage_dealt: int = 0
var _prev_damage_taken: int = 0
var _prev_healing_done: int = 0
var _prev_gold: int = 0
var _prev_xp_total: int = 0

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_session_id = _generate_session_id()
	
	# Parse CLI arguments
	var args = OS.get_cmdline_args()
	if "--disable-balance-telemetry" in args:
		enabled = false
	elif "--enable-balance-telemetry" in args:
		enabled = true
	
	# Only enable by default in debug builds
	if not OS.is_debug_build() and "--enable-balance-telemetry" not in args:
		enabled = false
	
	if enabled:
		_init_log_dir()
		print("[BalanceTelemetry] Initialized. Logs at: %s" % ProjectSettings.globalize_path(LOG_DIR))
	else:
		print("[BalanceTelemetry] Disabled")

func _process(delta: float) -> void:
	"""Poll game state for telemetry data"""
	if not enabled or not _run_active:
		return
	
	_poll_timer += delta
	if _poll_timer < POLL_INTERVAL:
		return
	_poll_timer = 0.0
	
	# Get current game state
	var game = _get_game_node()
	if not game or not "run_stats" in game:
		return
	
	var run_stats = game.run_stats
	var t_min = game.game_time / 60.0
	
	# === KILLS DELTA ===
	var current_kills = run_stats.get("kills", 0)
	var kills_delta = current_kills - _prev_kills
	if kills_delta > 0:
		_kills_last_60s += kills_delta
		# Track elites/bosses
		var current_elites = run_stats.get("elites_killed", 0)
		var elites_delta = current_elites - run_stats.get("_prev_elites", 0)
		_elites_killed_last_60s += maxi(0, elites_delta)
		
		var current_bosses = run_stats.get("bosses_killed", 0)
		var bosses_delta = current_bosses - run_stats.get("_prev_bosses", 0)
		_bosses_killed_last_60s += maxi(0, bosses_delta)
	_prev_kills = current_kills
	
	# === DAMAGE DEALT DELTA (for DPS) ===
	var current_damage_dealt = run_stats.get("damage_dealt", 0)
	var damage_delta = current_damage_dealt - _prev_damage_dealt
	if damage_delta > 0:
		_damage_dealt_last_60s += damage_delta
		# Add to DPS samples (damage per second)
		if _dps_samples.size() >= DPS_SAMPLES_COUNT:
			_dps_samples.pop_front()
		_dps_samples.append(damage_delta)
	_prev_damage_dealt = current_damage_dealt
	
	# === DAMAGE TAKEN DELTA ===
	var current_damage_taken = run_stats.get("damage_taken", 0)
	var damage_taken_delta = current_damage_taken - _prev_damage_taken
	if damage_taken_delta > 0:
		_damage_taken_last_60s += damage_taken_delta
	_prev_damage_taken = current_damage_taken
	
	# === HEALING DELTA ===
	var current_healing = run_stats.get("healing_done", 0)
	var healing_delta = current_healing - _prev_healing_done
	if healing_delta > 0:
		_healing_done_last_60s += healing_delta
	_prev_healing_done = current_healing
	
	# === GOLD DELTA ===
	var current_gold = run_stats.get("gold", 0)
	var gold_delta = current_gold - _prev_gold
	if gold_delta > 0:
		_gold_gained_last_60s += gold_delta
	_prev_gold = current_gold
	
	# === XP SAMPLE (for xp_per_min rolling average) ===
	var current_xp = run_stats.get("xp_total", 0)
	if current_xp != _prev_xp_total:
		_xp_samples.append({"time_min": t_min, "xp": current_xp})
		# Prune old samples (keep last N minutes)
		while _xp_samples.size() > 0 and _xp_samples[0]["time_min"] < t_min - XP_ROLLING_MINUTES:
			_xp_samples.pop_front()
		_prev_xp_total = current_xp

func _init_log_dir() -> void:
	if not DirAccess.dir_exists_absolute(LOG_DIR):
		DirAccess.make_dir_recursive_absolute(LOG_DIR)

func _generate_session_id() -> String:
	return "%08x-%04x-%04x" % [
		Time.get_unix_time_from_system(),
		randi() & 0xFFFF,
		randi() & 0xFFFF
	]

# ═══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════════════════════

func start_run(context: Dictionary = {}) -> void:
	"""Initialize a new run log. Call from Game._start_game()"""
	if not enabled:
		return
	
	_run_active = true
	_run_id = _get_next_run_id()
	_run_seed = context.get("seed", randi())
	_run_start_time_ms = Time.get_ticks_msec()
	_last_minute_logged = -1
	
	# Reset all counters
	_reset_counters()
	
	# Create log file
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	_current_log_file = LOG_DIR.path_join("run_%04d_%s.jsonl" % [_run_id, timestamp])
	
	# Log run_start event
	var event = {
		"event": "run_start",
		"character_id": context.get("character_id", "unknown"),
		"starting_weapons": context.get("starting_weapons", []),
		"game_version": context.get("game_version", "0.1.0"),
		"seed": _run_seed
	}
	_log_event(event)

func end_run(context: Dictionary = {}) -> void:
	"""Finalize run log. Call from Game.player_died() or manual exit"""
	if not enabled or not _run_active:
		return
	
	var event = {
		"event": "run_end",
		"time_survived": context.get("time_survived", 0.0),
		"score_final": context.get("score_final", 0),
		"end_reason": context.get("end_reason", "death"),
		"killed_by": context.get("killed_by", "unknown"),
		
		"final_stats": {
			"level": context.get("level", 1),
			"kills": context.get("kills", 0),
			"elites_killed": context.get("elites_killed", 0),
			"bosses_killed": context.get("bosses_killed", 0),
			"gold": context.get("gold", 0),
			"damage_dealt": context.get("damage_dealt", 0),
			"damage_taken": context.get("damage_taken", 0),
			"healing_done": context.get("healing_done", 0),
			"xp_total": context.get("xp_total", 0)
		},
		
		"build_final": {
			"weapons": context.get("weapons", []),
			"upgrades": context.get("upgrades", []),
			"player_stats": context.get("player_stats", {})
		},
		
		"economy": {
			"rerolls_used": _rerolls_used_total,
			"chests_opened": _chests_opened_total,
			"fusions_obtained": _fusions_obtained_total
		}
	}
	_log_event(event)
	
	_run_active = false
	_current_log_file = ""

func log_minute_snapshot(context: Dictionary) -> void:
	"""Log periodic snapshot. Call every 60s of game_time from Game._process()"""
	if not enabled or not _run_active:
		return
	
	var event = {
		"event": "minute_snapshot",
		
		"progression": {
			"xp_total": context.get("xp_total", 0),
			"xp_to_next": context.get("xp_to_next", 0),
			"xp_per_min": _calculate_xp_per_min(),
			"level": context.get("level", 1),
			"levels_per_min": _calculate_levels_per_min(context.get("t_min", 1.0))
		},
		
		"combat": {
			"dps_est": _calculate_dps(),
			"damage_done_last_60s": _damage_dealt_last_60s,
			"damage_taken_last_60s": _damage_taken_last_60s,
			"healing_done_last_60s": _healing_done_last_60s,
			"kills_last_60s": _kills_last_60s,
			"elites_killed_last_60s": _elites_killed_last_60s,
			"bosses_killed_last_60s": _bosses_killed_last_60s
		},
		
		"economy": {
			"gold_total": context.get("gold", 0),
			"gold_gained_last_60s": _gold_gained_last_60s,
			"rerolls_used_last_60s": _rerolls_used_last_60s,
			"rerolls_total": _rerolls_used_total,
			"chests_opened_last_60s": _chests_opened_last_60s,
			"fusions_obtained_total": _fusions_obtained_total
		},
		
		"difficulty": context.get("difficulty", {}),
		
		"build": {
			"weapons": context.get("weapons", []),
			"top_upgrades": context.get("top_upgrades", []),
			"stats": context.get("player_stats", {})
		}
	}
	_log_event(event)
	
	# Reset 60s counters
	_reset_60s_counters()

func log_upgrade_pick(context: Dictionary) -> void:
	"""Log when player picks an upgrade. Call from LevelUpPanel._apply_option()"""
	if not enabled or not _run_active:
		return
	
	var event = {
		"event": "upgrade_pick",
		"source": context.get("source", "levelup"),  # levelup / chest_elite / chest_boss / shop
		"options_shown": context.get("options_shown", []),
		"picked_id": context.get("picked_id", "unknown"),
		"picked_type": context.get("picked_type", "upgrade"),  # upgrade / weapon / fusion
		"reroll_count_this_pick": context.get("reroll_count", 0),
		"rerolls_total": _rerolls_used_total
	}
	_log_event(event)

func log_weapon_level_up(weapon_id: String, old_level: int, new_level: int) -> void:
	"""Log weapon level up"""
	if not enabled or not _run_active:
		return
	
	var event = {
		"event": "weapon_level_up",
		"weapon_id": weapon_id,
		"level_before": old_level,
		"level_after": new_level
	}
	_log_event(event)

func log_chest_opened(context: Dictionary) -> void:
	"""Log chest opening. Call from ChestSpawner/TreasureChest"""
	if not enabled or not _run_active:
		return
	
	_chests_opened_last_60s += 1
	_chests_opened_total += 1
	
	if context.get("fusion_obtained", false):
		_fusions_obtained_total += 1
	
	var event = {
		"event": "chest_opened",
		"chest_type": context.get("chest_type", "normal"),  # normal / elite / boss
		"loot_ids": context.get("loot_ids", []),
		"fusion_obtained": context.get("fusion_obtained", false)
	}
	_log_event(event)

func log_elite_spawned(context: Dictionary) -> void:
	"""Log elite spawn with abilities. Call from EnemyManager"""
	if not enabled or not _run_active:
		return
	
	var event = {
		"event": "elite_spawned",
		"enemy_id": context.get("enemy_id", "unknown"),
		"tier": context.get("tier", 1),
		"abilities": context.get("abilities", [])
	}
	_log_event(event)

func log_boss_spawned(context: Dictionary) -> void:
	"""Log boss spawn. Call from WaveManager"""
	if not enabled or not _run_active:
		return
	
	var event = {
		"event": "boss_spawned",
		"boss_id": context.get("boss_id", "unknown"),
		"phase": context.get("phase", 1)
	}
	_log_event(event)

# ═══════════════════════════════════════════════════════════════════════════════
# COUNTER INCREMENTS (call from various game systems)
# ═══════════════════════════════════════════════════════════════════════════════

func add_damage_dealt(amount: int) -> void:
	if not enabled or not _run_active:
		return
	_damage_dealt_last_60s += amount

func add_damage_taken(amount: int) -> void:
	if not enabled or not _run_active:
		return
	_damage_taken_last_60s += amount

func add_healing(amount: int) -> void:
	if not enabled or not _run_active:
		return
	_healing_done_last_60s += amount

func add_kill(is_elite: bool = false, is_boss: bool = false) -> void:
	if not enabled or not _run_active:
		return
	_kills_last_60s += 1
	if is_elite:
		_elites_killed_last_60s += 1
	if is_boss:
		_bosses_killed_last_60s += 1

func add_gold(amount: int) -> void:
	if not enabled or not _run_active:
		return
	_gold_gained_last_60s += amount

func add_reroll() -> void:
	if not enabled or not _run_active:
		return
	_rerolls_used_last_60s += 1
	_rerolls_used_total += 1

func add_level_up() -> void:
	if not enabled or not _run_active:
		return
	_levels_gained_this_run += 1

func record_xp_sample(xp_total: int, t_min: float) -> void:
	"""Record XP sample for rolling average"""
	if not enabled or not _run_active:
		return
	_xp_samples.append({"time_min": t_min, "xp": xp_total})
	# Prune old samples
	while _xp_samples.size() > 0 and _xp_samples[0]["time_min"] < t_min - XP_ROLLING_MINUTES:
		_xp_samples.pop_front()

func record_dps_sample(damage: int) -> void:
	"""Record damage sample for DPS estimation"""
	if not enabled or not _run_active:
		return
	if _dps_samples.size() >= DPS_SAMPLES_COUNT:
		_dps_samples.pop_front()
	_dps_samples.append(damage)

# ═══════════════════════════════════════════════════════════════════════════════
# INTERNAL HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

func _log_event(event: Dictionary) -> void:
	"""Write event to JSONL file"""
	if _current_log_file.is_empty():
		return
	
	# Add common fields
	var game = _get_game_node()
	var t_min = 0.0
	var difficulty_phase = 1
	var player_level = 1
	var score_current = 0
	
	if game:
		t_min = game.game_time / 60.0
		player_level = game.run_stats.get("level", 1)
		if game.has_method("_calculate_run_score"):
			score_current = game._calculate_run_score()
	
	var difficulty_manager = get_tree().get_first_node_in_group("difficulty_manager")
	if difficulty_manager and difficulty_manager.has_method("get_current_phase"):
		difficulty_phase = difficulty_manager.get_current_phase()
	
	event["schema_version"] = SCHEMA_VERSION
	event["session_id"] = _session_id
	event["run_id"] = _run_id
	event["timestamp_ms"] = Time.get_ticks_msec()
	event["t_min"] = snappedf(t_min, 0.01)
	event["seed"] = _run_seed
	event["difficulty_phase"] = difficulty_phase
	event["player_level"] = player_level
	event["score_current"] = score_current
	
	# Write to file
	var file = FileAccess.open(_current_log_file, FileAccess.READ_WRITE)
	if not file:
		file = FileAccess.open(_current_log_file, FileAccess.WRITE)
	if file:
		file.seek_end()
		file.store_line(JSON.stringify(event))
		file.close()

func _get_next_run_id() -> int:
	# Read from meta file or increment
	var meta_path = LOG_DIR.path_join("_meta.json")
	var run_id = 1
	
	if FileAccess.file_exists(meta_path):
		var file = FileAccess.open(meta_path, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			var data = JSON.parse_string(content)
			if data and data is Dictionary:
				run_id = data.get("next_run_id", 1)
	
	# Save incremented value
	var file = FileAccess.open(meta_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"next_run_id": run_id + 1}))
		file.close()
	
	return run_id

func _get_game_node() -> Node:
	"""Get the Game node for polling run_stats"""
	return get_tree().root.get_node_or_null("Game")

func _reset_counters() -> void:
	_damage_dealt_last_60s = 0
	_damage_taken_last_60s = 0
	_healing_done_last_60s = 0
	_kills_last_60s = 0
	_elites_killed_last_60s = 0
	_bosses_killed_last_60s = 0
	_gold_gained_last_60s = 0
	_rerolls_used_last_60s = 0
	_chests_opened_last_60s = 0
	_fusions_obtained_total = 0
	_rerolls_used_total = 0
	_chests_opened_total = 0
	_dps_samples.clear()
	_xp_samples.clear()
	_levels_gained_this_run = 0
	_level_at_start = 1
	
	# Reset polling state
	_poll_timer = 0.0
	_prev_kills = 0
	_prev_damage_dealt = 0
	_prev_damage_taken = 0
	_prev_healing_done = 0
	_prev_gold = 0
	_prev_xp_total = 0

func _reset_60s_counters() -> void:
	_damage_dealt_last_60s = 0
	_damage_taken_last_60s = 0
	_healing_done_last_60s = 0
	_kills_last_60s = 0
	_elites_killed_last_60s = 0
	_bosses_killed_last_60s = 0
	_gold_gained_last_60s = 0
	_rerolls_used_last_60s = 0
	_chests_opened_last_60s = 0

func _calculate_dps() -> float:
	if _dps_samples.is_empty():
		return 0.0
	var total: int = 0
	for sample in _dps_samples:
		total += sample
	return float(total) / float(_dps_samples.size())

func _calculate_xp_per_min() -> float:
	if _xp_samples.size() < 2:
		return 0.0
	var oldest = _xp_samples[0]
	var newest = _xp_samples[-1]
	var time_diff = newest["time_min"] - oldest["time_min"]
	if time_diff < 0.5:  # Need at least 30 seconds of data
		return 0.0
	var xp_diff = newest["xp"] - oldest["xp"]
	return float(xp_diff) / time_diff

func _calculate_levels_per_min(t_min: float) -> float:
	if t_min < 0.5:
		return 0.0
	return float(_levels_gained_this_run) / t_min

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS FOR GAME INTEGRATION
# ═══════════════════════════════════════════════════════════════════════════════

func get_current_weapons_snapshot() -> Array:
	"""Get compact weapons array [{id, lvl}, ...]"""
	var result: Array = []
	var attack_manager = get_tree().get_first_node_in_group("attack_manager")
	if attack_manager and attack_manager.has_method("get_weapons"):
		for weapon in attack_manager.get_weapons():
			result.append({
				"id": weapon.id if "id" in weapon else "unknown",
				"lvl": weapon.level if "level" in weapon else 1
			})
	return result

func get_top_upgrades_snapshot(max_count: int = 10) -> Array:
	"""Get top upgrades by stacks [{id, stacks}, ...]"""
	var result: Array = []
	var player_stats = get_tree().get_first_node_in_group("player_stats")
	if player_stats and "collected_upgrades" in player_stats:
		# Count stacks per upgrade
		var counts: Dictionary = {}
		for upgrade in player_stats.collected_upgrades:
			var uid = upgrade.get("id", upgrade.get("name", "unknown"))
			counts[uid] = counts.get(uid, 0) + 1
		
		# Sort by count
		var sorted_ids = counts.keys()
		sorted_ids.sort_custom(func(a, b): return counts[a] > counts[b])
		
		for i in range(mini(max_count, sorted_ids.size())):
			result.append({"id": sorted_ids[i], "stacks": counts[sorted_ids[i]]})
	return result

func get_player_stats_snapshot() -> Dictionary:
	"""Get key player stats for snapshot"""
	var result: Dictionary = {}
	var player_stats = get_tree().get_first_node_in_group("player_stats")
	if player_stats:
		var stat_names = [
			"max_health", "hp_regen", "life_steal", "armor", "damage_reduction",
			"dodge_chance", "attack_speed_mult", "damage_mult", "crit_chance",
			"crit_damage", "move_speed"
		]
		for stat_name in stat_names:
			if player_stats.has_method("get_stat"):
				var val = player_stats.get_stat(stat_name)
				if val != null:
					result[stat_name] = val
	return result

func get_difficulty_snapshot() -> Dictionary:
	"""Get current difficulty multipliers"""
	var result: Dictionary = {
		"enemy_hp_mult": 1.0,
		"enemy_dmg_mult": 1.0,
		"spawn_mult": 1.0,
		"elite_mult": 1.0,
		"speed_mult": 1.0
	}
	
	var difficulty_manager = get_tree().get_first_node_in_group("difficulty_manager")
	if difficulty_manager:
		# Use correct variable names from DifficultyManager.gd
		if "enemy_health_multiplier" in difficulty_manager:
			result["enemy_hp_mult"] = snappedf(difficulty_manager.enemy_health_multiplier, 0.01)
		if "enemy_damage_multiplier" in difficulty_manager:
			result["enemy_dmg_mult"] = snappedf(difficulty_manager.enemy_damage_multiplier, 0.01)
		if "enemy_count_multiplier" in difficulty_manager:
			result["spawn_mult"] = snappedf(difficulty_manager.enemy_count_multiplier, 0.01)
		if "elite_frequency_multiplier" in difficulty_manager:
			result["elite_mult"] = snappedf(difficulty_manager.elite_frequency_multiplier, 0.01)
		if "enemy_speed_multiplier" in difficulty_manager:
			result["speed_mult"] = snappedf(difficulty_manager.enemy_speed_multiplier, 0.01)
	
	return result

# ═══════════════════════════════════════════════════════════════════════════════
# MINUTE CHECK (call from Game._process)
# ═══════════════════════════════════════════════════════════════════════════════

func check_minute_snapshot(game_time: float) -> bool:
	"""Returns true if we should log a minute snapshot now"""
	if not enabled or not _run_active:
		return false
	var current_minute = int(game_time / 60.0)
	if current_minute > _last_minute_logged:
		_last_minute_logged = current_minute
		return true
	return false

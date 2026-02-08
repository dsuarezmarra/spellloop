# RunAuditTracker.gd
# Sistema de auditoría completa de runs
# Recolecta métricas detalladas con agregación eficiente y muestreo configurable
# Genera JSONL en user://audit_logs/ y reportes MD en user://audit_reports/
extends Node

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

const SCHEMA_VERSION: int = 1
const LOG_DIR: String = "user://audit_logs"
const REPORT_DIR: String = "user://audit_reports"

## Toggle principal - solo activo en debug por defecto
@export var ENABLE_AUDIT: bool = true

## Muestreo de hits (1 de cada N hits se registra en detalle, totales siempre exactos)
@export var HIT_SAMPLE_RATE: int = 50

## Máximo de spikes por minuto para evitar spam
@export var MAX_SPIKES_PER_MINUTE: int = 10

## Umbral de spikes en ms
@export var SPIKE_THRESHOLD_MS: float = 33.0  # ~30 FPS
@export var SEVERE_SPIKE_THRESHOLD_MS: float = 66.0  # ~15 FPS

## Top N para rankings
const TOP_N: int = 20

# ═══════════════════════════════════════════════════════════════════════════════
# RUN STATE
# ═══════════════════════════════════════════════════════════════════════════════

var _run_active: bool = false
var _run_id: String = ""
var _run_seed: int = 0
var _run_start_time_ms: int = 0
var _session_id: String = ""
var _current_log_file: String = ""
var _current_minute: int = 0

# ═══════════════════════════════════════════════════════════════════════════════
# WEAPON TRACKING
# ═══════════════════════════════════════════════════════════════════════════════

# weapon_id -> WeaponStats
var _weapon_stats: Dictionary = {}

class WeaponStats:
	var weapon_id: String = ""
	var weapon_name: String = ""
	var damage_total: int = 0
	var hits_total: int = 0
	var crits_total: int = 0
	var kills: int = 0
	var status_procs: Dictionary = {}  # status_type -> count
	
	# Per-minute rolling (reset each minute)
	var damage_last_60s: int = 0
	var hits_last_60s: int = 0
	
	func get_crit_rate() -> float:
		if hits_total == 0:
			return 0.0
		return float(crits_total) / float(hits_total)
	
	func get_dps_last_60s() -> float:
		return damage_last_60s / 60.0
	
	func reset_minute() -> void:
		damage_last_60s = 0
		hits_last_60s = 0
	
	func to_dict() -> Dictionary:
		return {
			"weapon_id": weapon_id,
			"weapon_name": weapon_name,
			"damage_total": damage_total,
			"hits_total": hits_total,
			"crits_total": crits_total,
			"crit_rate": get_crit_rate(),
			"kills": kills,
			"status_procs": status_procs.duplicate(),
			"dps_last_60s": get_dps_last_60s()
		}

# ═══════════════════════════════════════════════════════════════════════════════
# ENEMY TRACKING (damage TO player)
# ═══════════════════════════════════════════════════════════════════════════════

# enemy_id -> EnemyDamageStats
var _enemy_damage_stats: Dictionary = {}

class EnemyDamageStats:
	var enemy_id: String = ""
	var enemy_name: String = ""
	var damage_to_player_total: int = 0
	var hits_to_player: int = 0
	var kills_caused: int = 0  # veces que mató al jugador (normalmente 0-1)
	var spawns_total: int = 0
	var attack_breakdown: Dictionary = {}  # attack_id -> {damage: int, hits: int}
	
	func to_dict() -> Dictionary:
		return {
			"enemy_id": enemy_id,
			"enemy_name": enemy_name,
			"damage_to_player": damage_to_player_total,
			"hits_to_player": hits_to_player,
			"kills_caused": kills_caused,
			"spawns": spawns_total,
			"top_attacks": _get_top_attacks()
		}
	
	func _get_top_attacks() -> Array:
		var attacks: Array = []
		for atk_id in attack_breakdown:
			var data = attack_breakdown[atk_id]
			attacks.append({
				"attack_id": atk_id,
				"damage": data.get("damage", 0),
				"hits": data.get("hits", 0)
			})
		attacks.sort_custom(func(a, b): return a.damage > b.damage)
		if attacks.size() > 5:
			attacks.resize(5)
		return attacks

# ═══════════════════════════════════════════════════════════════════════════════
# UPGRADE TRACKING
# ═══════════════════════════════════════════════════════════════════════════════

var _upgrade_picks: Array[Dictionary] = []  # Timeline de picks

# ═══════════════════════════════════════════════════════════════════════════════
# PLAYER STATS SNAPSHOTS (cada minuto)
# ═══════════════════════════════════════════════════════════════════════════════

var _player_stats_history: Array[Dictionary] = []

# ═══════════════════════════════════════════════════════════════════════════════
# DIFFICULTY SNAPSHOTS (cada minuto)
# ═══════════════════════════════════════════════════════════════════════════════

var _difficulty_history: Array[Dictionary] = []

# ═══════════════════════════════════════════════════════════════════════════════
# PERFORMANCE / SPIKES
# ═══════════════════════════════════════════════════════════════════════════════

var _spikes_this_minute: int = 0
var _spikes_33ms_total: int = 0
var _spikes_66ms_total: int = 0
var _spike_samples: Array[Dictionary] = []  # Muestreo de spikes con contexto
const MAX_SPIKE_SAMPLES: int = 50

# ═══════════════════════════════════════════════════════════════════════════════
# SCORING BREAKDOWN
# ═══════════════════════════════════════════════════════════════════════════════

var _score_snapshots: Array[Dictionary] = []  # Cada 5 minutos

# ═══════════════════════════════════════════════════════════════════════════════
# ECONOMY TRACKING
# ═══════════════════════════════════════════════════════════════════════════════

var _level_timeline: Array[Dictionary] = []  # {t_min: float, level: int}
var _chests_opened: Dictionary = {"normal": 0, "elite": 0, "boss": 0}
var _fusions_obtained: Array[Dictionary] = []  # {t_min, weapons, result}
var _rerolls_used: int = 0
var _gold_spent: int = 0

# ═══════════════════════════════════════════════════════════════════════════════
# ELITE/BOSS TRACKING
# ═══════════════════════════════════════════════════════════════════════════════

var _elite_ability_combos: Dictionary = {}  # "ability1+ability2" -> count
var _elite_kills_per_minute: Array[int] = []
var _boss_kills_per_minute: Array[int] = []

# ═══════════════════════════════════════════════════════════════════════════════
# HIT SAMPLE COUNTER
# ═══════════════════════════════════════════════════════════════════════════════

var _hit_counter: int = 0

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_session_id = _generate_id()
	
	# Parse CLI arguments
	var args = OS.get_cmdline_args()
	if "--disable-audit" in args:
		ENABLE_AUDIT = false
	elif "--enable-audit" in args:
		ENABLE_AUDIT = true
	
	# Only enable by default in debug builds
	if not OS.is_debug_build() and "--enable-audit" not in args:
		ENABLE_AUDIT = false
	
	if ENABLE_AUDIT:
		_init_dirs()
		print("[RunAuditTracker] ✅ Initialized. Logs: %s | Reports: %s" % [
			ProjectSettings.globalize_path(LOG_DIR),
			ProjectSettings.globalize_path(REPORT_DIR)
		])
	else:
		print("[RunAuditTracker] ❌ Disabled")

func _init_dirs() -> void:
	for dir in [LOG_DIR, REPORT_DIR]:
		if not DirAccess.dir_exists_absolute(dir):
			DirAccess.make_dir_recursive_absolute(dir)

func _generate_id() -> String:
	return "%08x-%04x" % [Time.get_unix_time_from_system(), randi() & 0xFFFF]

# ═══════════════════════════════════════════════════════════════════════════════
# PUBLIC API - RUN LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func start_run(context: Dictionary = {}) -> void:
	"""Iniciar tracking de una nueva run. Llamar desde Game._start_game()"""
	if not ENABLE_AUDIT:
		return
	
	_run_active = true
	_run_id = _generate_id()
	_run_seed = context.get("seed", randi())
	_run_start_time_ms = Time.get_ticks_msec()
	_current_minute = 0
	
	# Reset all tracking
	_reset_all()
	
	# Reset instrumentation scopes
	Instrumentation.reset_run_scopes()
	
	# Create log file
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	_current_log_file = LOG_DIR.path_join("audit_%s_%s.jsonl" % [_run_id, timestamp])
	
	# Log run_start event
	_log_event({
		"event": "run_start",
		"schema_version": SCHEMA_VERSION,
		"session_id": _session_id,
		"run_id": _run_id,
		"seed": _run_seed,
		"character_id": context.get("character_id", "unknown"),
		"starting_weapons": context.get("starting_weapons", []),
		"game_version": context.get("game_version", "0.1.0")
	})

func end_run(context: Dictionary = {}) -> void:
	"""Finalizar tracking. Llamar desde Game.player_died()"""
	if not ENABLE_AUDIT or not _run_active:
		return
	
	var end_reason = context.get("end_reason", "death")
	var time_survived = context.get("time_survived", 0.0)
	
	# Final minute snapshot
	minute_tick(context)
	
	# Build final summary
	var summary = _build_final_summary(context)
	
	# Log run_end event
	_log_event({
		"event": "run_end",
		"run_id": _run_id,
		"time_survived": time_survived,
		"end_reason": end_reason,
		"killed_by": context.get("killed_by", "unknown"),
		"summary": summary
	})
	
	# Generate markdown report
	var report_path = _generate_markdown_report(summary, context)
	print("[RunAuditTracker] 📊 Report generated: %s" % ProjectSettings.globalize_path(report_path))
	
	_run_active = false

func minute_tick(context: Dictionary = {}) -> void:
	"""Snapshot cada minuto. Llamar desde Game._check_telemetry_minute_snapshot()"""
	if not ENABLE_AUDIT or not _run_active:
		return
	
	_current_minute += 1
	
	# Collect minute data
	var minute_data = _collect_minute_data(context)
	
	# Log minute snapshot
	_log_event({
		"event": "minute_snapshot",
		"t_min": _current_minute,
		"data": minute_data
	})
	
	# Reset minute counters
	_reset_minute_counters()
	
	# Score snapshot every 5 minutes
	if _current_minute % 5 == 0:
		_capture_score_snapshot(context)

# ═══════════════════════════════════════════════════════════════════════════════
# PUBLIC API - DAMAGE REPORTING (con muestreo)
# ═══════════════════════════════════════════════════════════════════════════════

func report_damage_dealt(weapon_id: String, weapon_name: String, amount: int, is_crit: bool, status_applied: Array = [], killed: bool = false) -> void:
	"""Reportar daño hecho por un arma. Totales siempre exactos, detalle muestreado."""
	if not ENABLE_AUDIT or not _run_active:
		return
	
	# Ensure weapon exists
	if not _weapon_stats.has(weapon_id):
		var stats = WeaponStats.new()
		stats.weapon_id = weapon_id
		stats.weapon_name = weapon_name
		_weapon_stats[weapon_id] = stats
	
	var stats: WeaponStats = _weapon_stats[weapon_id]
	
	# ALWAYS update totals (exact)
	stats.damage_total += amount
	stats.damage_last_60s += amount
	stats.hits_total += 1
	stats.hits_last_60s += 1
	
	if is_crit:
		stats.crits_total += 1
	
	if killed:
		stats.kills += 1
	
	for status in status_applied:
		if not stats.status_procs.has(status):
			stats.status_procs[status] = 0
		stats.status_procs[status] += 1
	
	# Sampling: Only log detailed event 1/N times
	_hit_counter += 1
	# (detailed logging disabled for performance - only aggregate)

func report_damage_to_player(enemy_id: String, enemy_name: String, attack_id: String, amount: int, killed_player: bool = false) -> void:
	"""Reportar daño recibido por el jugador desde un enemigo."""
	if not ENABLE_AUDIT or not _run_active:
		return
	
	if not _enemy_damage_stats.has(enemy_id):
		var stats = EnemyDamageStats.new()
		stats.enemy_id = enemy_id
		stats.enemy_name = enemy_name
		_enemy_damage_stats[enemy_id] = stats
	
	var stats: EnemyDamageStats = _enemy_damage_stats[enemy_id]
	stats.damage_to_player_total += amount
	stats.hits_to_player += 1
	
	if killed_player:
		stats.kills_caused += 1
	
	# Track attack breakdown
	if not stats.attack_breakdown.has(attack_id):
		stats.attack_breakdown[attack_id] = {"damage": 0, "hits": 0}
	stats.attack_breakdown[attack_id]["damage"] += amount
	stats.attack_breakdown[attack_id]["hits"] += 1

func report_enemy_spawn(enemy_id: String, enemy_name: String, is_elite: bool = false, abilities: Array = []) -> void:
	"""Reportar spawn de enemigo."""
	if not ENABLE_AUDIT or not _run_active:
		return
	
	if not _enemy_damage_stats.has(enemy_id):
		var stats = EnemyDamageStats.new()
		stats.enemy_id = enemy_id
		stats.enemy_name = enemy_name
		_enemy_damage_stats[enemy_id] = stats
	
	_enemy_damage_stats[enemy_id].spawns_total += 1
	
	# Track elite ability combos
	if is_elite and abilities.size() > 0:
		var combo_key = "+".join(abilities.map(func(a): return str(a)))
		if not _elite_ability_combos.has(combo_key):
			_elite_ability_combos[combo_key] = 0
		_elite_ability_combos[combo_key] += 1

# ═══════════════════════════════════════════════════════════════════════════════
# PUBLIC API - ECONOMY / PROGRESSION
# ═══════════════════════════════════════════════════════════════════════════════

func report_level_up(new_level: int, t_min: float) -> void:
	"""Reportar subida de nivel."""
	if not ENABLE_AUDIT or not _run_active:
		return
	_level_timeline.append({"t_min": t_min, "level": new_level})

func report_upgrade_pick(context: Dictionary) -> void:
	"""Reportar selección de upgrade."""
	if not ENABLE_AUDIT or not _run_active:
		return
	_upgrade_picks.append(context.duplicate())

func report_chest_opened(chest_type: String, loot_ids: Array = [], fusion_obtained: bool = false, fusion_data: Dictionary = {}) -> void:
	"""Reportar apertura de cofre."""
	if not ENABLE_AUDIT or not _run_active:
		return
	
	if _chests_opened.has(chest_type):
		_chests_opened[chest_type] += 1
	else:
		_chests_opened[chest_type] = 1
	
	if fusion_obtained:
		_fusions_obtained.append({
			"t_min": _current_minute,
			"chest_type": chest_type,
			"fusion_data": fusion_data.duplicate()
		})

func report_reroll() -> void:
	"""Reportar uso de reroll."""
	if not ENABLE_AUDIT or not _run_active:
		return
	_rerolls_used += 1

func report_gold_spent(amount: int) -> void:
	"""Reportar gasto de oro."""
	if not ENABLE_AUDIT or not _run_active:
		return
	_gold_spent += amount

# ═══════════════════════════════════════════════════════════════════════════════
# PUBLIC API - PERFORMANCE
# ═══════════════════════════════════════════════════════════════════════════════

func report_spike(frame_time_ms: float, context: Dictionary = {}) -> void:
	"""Reportar spike de frame. Llamar desde PerfTracker."""
	if not ENABLE_AUDIT or not _run_active:
		return
	
	# Rate limit
	if _spikes_this_minute >= MAX_SPIKES_PER_MINUTE:
		return
	
	_spikes_this_minute += 1
	
	if frame_time_ms >= SEVERE_SPIKE_THRESHOLD_MS:
		_spikes_66ms_total += 1
	elif frame_time_ms >= SPIKE_THRESHOLD_MS:
		_spikes_33ms_total += 1
	
	# Sample spike with context
	if _spike_samples.size() < MAX_SPIKE_SAMPLES:
		_spike_samples.append({
			"t_min": _current_minute,
			"frame_time_ms": frame_time_ms,
			"enemies_alive": context.get("enemies_alive", -1),
			"projectiles_alive": context.get("projectiles_alive", -1),
			"pickups_alive": context.get("pickups_alive", -1),
			"node_count": context.get("node_count", -1),
			"draw_calls": context.get("draw_calls", -1),
			"top_scopes": Instrumentation.get_top_scopes_minute(3)
		})

# ═══════════════════════════════════════════════════════════════════════════════
# INTERNAL - DATA COLLECTION
# ═══════════════════════════════════════════════════════════════════════════════

func _collect_minute_data(context: Dictionary) -> Dictionary:
	"""Recopilar datos del minuto actual."""
	
	# Get top weapons by damage
	var top_weapons = _get_top_weapons(10)
	
	# Get top enemies by damage to player
	var top_enemies = _get_top_enemies_by_damage(10)
	
	# Performance scopes
	var top_scopes = Instrumentation.get_top_scopes_minute(5)
	
	# Player stats snapshot
	var player_stats_snap = context.get("player_stats", {})
	_player_stats_history.append({
		"t_min": _current_minute,
		"stats": player_stats_snap.duplicate()
	})
	
	# Difficulty snapshot
	var difficulty_snap = context.get("difficulty", {})
	_difficulty_history.append({
		"t_min": _current_minute,
		"difficulty": difficulty_snap.duplicate()
	})
	
	return {
		"weapons": top_weapons,
		"enemies_dangerous": top_enemies,
		"performance": {
			"top_scopes": top_scopes,
			"spikes_33ms": _spikes_33ms_total,
			"spikes_66ms": _spikes_66ms_total,
			"spikes_this_minute": _spikes_this_minute
		},
		"player_stats": player_stats_snap,
		"difficulty": difficulty_snap,
		"economy": {
			"chests": _chests_opened.duplicate(),
			"fusions": _fusions_obtained.size(),
			"rerolls": _rerolls_used
		}
	}

func _get_top_weapons(n: int) -> Array:
	"""Obtener top N armas por daño total."""
	var weapons: Array = []
	for weapon_id in _weapon_stats:
		weapons.append(_weapon_stats[weapon_id].to_dict())
	
	weapons.sort_custom(func(a, b): return a.damage_total > b.damage_total)
	
	if weapons.size() > n:
		weapons.resize(n)
	
	return weapons

func _get_top_enemies_by_damage(n: int) -> Array:
	"""Obtener top N enemigos por daño al jugador."""
	var enemies: Array = []
	for enemy_id in _enemy_damage_stats:
		enemies.append(_enemy_damage_stats[enemy_id].to_dict())
	
	enemies.sort_custom(func(a, b): return a.damage_to_player > b.damage_to_player)
	
	if enemies.size() > n:
		enemies.resize(n)
	
	return enemies

func _capture_score_snapshot(context: Dictionary) -> void:
	"""Capturar snapshot de score cada 5 minutos."""
	_score_snapshots.append({
		"t_min": _current_minute,
		"score_total": context.get("score_total", 0),
		"breakdown": context.get("score_breakdown", {})
	})

func _build_final_summary(context: Dictionary) -> Dictionary:
	"""Construir resumen final de la run."""
	var total_damage_dealt: int = 0
	for weapon_id in _weapon_stats:
		total_damage_dealt += _weapon_stats[weapon_id].damage_total
	
	var total_damage_taken: int = 0
	for enemy_id in _enemy_damage_stats:
		total_damage_taken += _enemy_damage_stats[enemy_id].damage_to_player_total
	
	return {
		"duration_minutes": _current_minute,
		"final_level": context.get("level", 1),
		"phase_reached": context.get("phase", 1),
		"score_final": context.get("score_total", 0),
		
		"damage": {
			"dealt_total": total_damage_dealt,
			"taken_total": total_damage_taken
		},
		
		"weapons": {
			"top_10": _get_top_weapons(10),
			"total_equipped": _weapon_stats.size()
		},
		
		"enemies": {
			"top_10_dangerous": _get_top_enemies_by_damage(10)
		},
		
		"economy": {
			"chests_opened": _chests_opened.duplicate(),
			"fusions_obtained": _fusions_obtained.size(),
			"rerolls_used": _rerolls_used,
			"gold_spent": _gold_spent
		},
		
		"upgrades": {
			"picks_count": _upgrade_picks.size(),
			"timeline": _upgrade_picks
		},
		
		"level_timeline": _level_timeline,
		
		"performance": {
			"spikes_33ms_total": _spikes_33ms_total,
			"spikes_66ms_total": _spikes_66ms_total,
			"top_scopes_run": Instrumentation.get_top_scopes_run(10),
			"spike_samples": _spike_samples
		},
		
		"elite_ability_combos": _elite_ability_combos,
		
		"score_snapshots": _score_snapshots,
		
		"player_stats_history": _player_stats_history,
		"difficulty_history": _difficulty_history
	}

# ═══════════════════════════════════════════════════════════════════════════════
# INTERNAL - RESET
# ═══════════════════════════════════════════════════════════════════════════════

func _reset_all() -> void:
	"""Resetear todo el tracking."""
	_weapon_stats.clear()
	_enemy_damage_stats.clear()
	_upgrade_picks.clear()
	_player_stats_history.clear()
	_difficulty_history.clear()
	_spikes_this_minute = 0
	_spikes_33ms_total = 0
	_spikes_66ms_total = 0
	_spike_samples.clear()
	_score_snapshots.clear()
	_level_timeline.clear()
	_chests_opened = {"normal": 0, "elite": 0, "boss": 0}
	_fusions_obtained.clear()
	_rerolls_used = 0
	_gold_spent = 0
	_elite_ability_combos.clear()
	_elite_kills_per_minute.clear()
	_boss_kills_per_minute.clear()
	_hit_counter = 0

func _reset_minute_counters() -> void:
	"""Resetear contadores del minuto."""
	_spikes_this_minute = 0
	
	# Reset weapon minute counters
	for weapon_id in _weapon_stats:
		_weapon_stats[weapon_id].reset_minute()
	
	# Reset instrumentation minute scopes
	Instrumentation.reset_minute_scopes()

# ═══════════════════════════════════════════════════════════════════════════════
# INTERNAL - LOGGING
# ═══════════════════════════════════════════════════════════════════════════════

func _log_event(event: Dictionary) -> void:
	"""Escribir evento al archivo JSONL."""
	if _current_log_file.is_empty():
		return
	
	# Add common fields
	event["timestamp_ms"] = Time.get_ticks_msec() - _run_start_time_ms
	event["run_id"] = _run_id
	event["session_id"] = _session_id
	
	var file = FileAccess.open(_current_log_file, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(_current_log_file, FileAccess.WRITE)
	
	if file:
		file.seek_end()
		file.store_line(JSON.stringify(event))
		file.close()

# ═══════════════════════════════════════════════════════════════════════════════
# MARKDOWN REPORT GENERATION
# ═══════════════════════════════════════════════════════════════════════════════

func _generate_markdown_report(summary: Dictionary, context: Dictionary) -> String:
	"""Generar reporte Markdown de la run."""
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var report_path = REPORT_DIR.path_join("run_%s_%s.md" % [_run_id, timestamp])
	
	var report = RunAuditReport.generate(summary, context, _run_id, _run_seed)
	
	var file = FileAccess.open(report_path, FileAccess.WRITE)
	if file:
		file.store_string(report)
		file.close()
	
	return report_path

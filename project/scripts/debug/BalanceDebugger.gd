# BalanceDebugger.gd
# Sistema de debug para balance - trackea métricas clave durante una run
# Activar con F10 durante gameplay
#
# MÉTRICAS QUE TRACKEA:
# - Daño por hit (min/avg/max del jugador hacia enemigos)
# - Mitigación efectiva (dodge, DR, armor, shield)
# - Sustain/s (regen, lifesteal, heal-on-kill acumulado)
# - TTK de elite/boss (tiempo desde spawn hasta muerte)
extends Node
# class_name removed to avoid conflict with autoload singleton

# ═══════════════════════════════════════════════════════════════════════════════
# SEÑALES
# ═══════════════════════════════════════════════════════════════════════════════

signal metrics_updated(metrics: Dictionary)

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADO
# ═══════════════════════════════════════════════════════════════════════════════

var enabled: bool = false

# --- Daño del jugador ---
var _damage_dealt_samples: Array[int] = []
var _damage_dealt_total: int = 0
var _damage_dealt_count: int = 0

# --- Daño recibido / Mitigación ---
var _damage_taken_raw: int = 0        # Daño antes de mitigación
var _damage_taken_final: int = 0      # Daño después de mitigación
var _dodges_count: int = 0
var _shield_absorbed: int = 0
var _armor_reduced: int = 0

# --- Sustain ---
var _heal_from_regen: float = 0.0
var _heal_from_lifesteal: float = 0.0
var _heal_from_kill: float = 0.0
var _heal_total: float = 0.0

# --- TTK Tracking ---
var _elite_spawn_times: Dictionary = {}  # enemy_id -> spawn_time_msec
var _elite_ttk_samples: Array[float] = []
var _boss_spawn_times: Dictionary = {}
var _boss_ttk_samples: Array[float] = []

# --- BALANCE PASS 2: XP / Level / Difficulty Tracking ---
var _xp_gained_total: int = 0
var _levels_gained: int = 0
var _last_level: int = 1
var _last_difficulty_snapshot: Dictionary = {}

# --- Timing ---
var _session_start_time: int = 0
var _update_timer: float = 0.0
const UPDATE_INTERVAL: float = 0.5  # Actualizar métricas cada 0.5s

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Auto-disable in release builds
	if not OS.is_debug_build() and "--enable-balance-debugger" not in OS.get_cmdline_args():
		enabled = false
		set_process(false)
		return
	_session_start_time = Time.get_ticks_msec()
	add_to_group("balance_debugger")

func _process(delta: float) -> void:
	if not enabled:
		return
	
	_update_timer += delta
	if _update_timer >= UPDATE_INTERVAL:
		_update_timer = 0.0
		metrics_updated.emit(get_current_metrics())

# ═══════════════════════════════════════════════════════════════════════════════
# API PÚBLICA - Llamar desde otros scripts para registrar eventos
# ═══════════════════════════════════════════════════════════════════════════════

## Registrar daño infligido por el jugador
## FIX-12: Siempre coleccionar datos, 'enabled' solo controla UI overlay
func log_damage_dealt(amount: int) -> void:
	_damage_dealt_samples.append(amount)
	_damage_dealt_total += amount
	_damage_dealt_count += 1
	# Mantener solo últimos 100 samples para avg reciente
	if _damage_dealt_samples.size() > 100:
		_damage_dealt_samples.pop_front()

## Registrar daño recibido (antes y después de mitigación)
## FIX-12: Siempre coleccionar datos
func log_damage_taken(raw: int, final: int, dodged: bool, shield_absorbed: int = 0, armor_reduced: int = 0) -> void:
	if dodged:
		_dodges_count += 1
		return
	_damage_taken_raw += raw
	_damage_taken_final += final
	_shield_absorbed += shield_absorbed
	_armor_reduced += armor_reduced

## Registrar curación
## FIX-12: Siempre coleccionar datos
func log_heal(amount: float, source: String) -> void:
	_heal_total += amount
	match source:
		"regen":
			_heal_from_regen += amount
		"lifesteal":
			_heal_from_lifesteal += amount
		"kill":
			_heal_from_kill += amount

## Registrar spawn de elite/boss para TTK
## FIX-12: Siempre coleccionar datos
func log_elite_spawn(enemy_id: int, is_boss: bool = false) -> void:
	var now = Time.get_ticks_msec()
	if is_boss:
		_boss_spawn_times[enemy_id] = now
	else:
		_elite_spawn_times[enemy_id] = now

## Registrar muerte de elite/boss para TTK
## FIX-12: Siempre coleccionar datos
func log_elite_death(enemy_id: int, is_boss: bool = false) -> void:
	var now = Time.get_ticks_msec()
	if is_boss:
		if _boss_spawn_times.has(enemy_id):
			var ttk = (now - _boss_spawn_times[enemy_id]) / 1000.0
			_boss_ttk_samples.append(ttk)
			_boss_spawn_times.erase(enemy_id)
			print("[BALANCE DEBUG] 🏆 BOSS TTK: %.2fs" % ttk)
	else:
		if _elite_spawn_times.has(enemy_id):
			var ttk = (now - _elite_spawn_times[enemy_id]) / 1000.0
			_elite_ttk_samples.append(ttk)
			_elite_spawn_times.erase(enemy_id)
			# Solo imprimir cada 5 elites para no spamear
			if enabled and _elite_ttk_samples.size() % 5 == 0:
				print("[BALANCE DEBUG] ⭐ Elite avg TTK (last 5): %.2fs" % _get_avg(_elite_ttk_samples.slice(-5)))

## BALANCE PASS 2: Registrar XP ganada
## FIX-12: Siempre coleccionar datos
func log_xp_gained(amount: int) -> void:
	_xp_gained_total += amount

## BALANCE PASS 2: Registrar level up
## FIX-12: Siempre coleccionar datos
func log_level_up(new_level: int) -> void:
	if new_level > _last_level:
		_levels_gained += 1
		_last_level = new_level
		if enabled:
			var elapsed_min = (Time.get_ticks_msec() - _session_start_time) / 60000.0
			print("[BALANCE DEBUG] \U0001f4c8 Level %d reached at %.1f min" % [new_level, elapsed_min])

## BALANCE PASS 2.5: Registrar snapshot de difficulty scaling (ahora incluye fase)
## FIX-12: Siempre coleccionar datos
func log_difficulty_scaling(snapshot: Dictionary) -> void:
	_last_difficulty_snapshot = snapshot
	# Log cada minuto entero (solo si overlay activo)
	if not enabled:
		return
	var min_elapsed = int(snapshot.get("minute", 0))
	if min_elapsed > 0 and min_elapsed % 5 == 0:  # Log cada 5 minutos
		var phase_name = snapshot.get("phase_name", "?")
		print("[BALANCE DEBUG] 🎯 [%s] @ min %d: HP=%.2fx DMG=%.2fx SPAWN=%.2fx ELITE=%.2fx" % [
			phase_name,
			min_elapsed,
			snapshot.get("hp_mult", 1.0),
			snapshot.get("dmg_mult", 1.0),
			snapshot.get("spawn_mult", 1.0),
			snapshot.get("elite_freq_mult", 1.0)
		])

# ═══════════════════════════════════════════════════════════════════════════════
# MÉTRICAS
# ═══════════════════════════════════════════════════════════════════════════════

func get_current_metrics() -> Dictionary:
	var elapsed_sec = (Time.get_ticks_msec() - _session_start_time) / 1000.0
	if elapsed_sec < 0.1:
		elapsed_sec = 0.1  # Evitar división por cero
	var elapsed_min = elapsed_sec / 60.0
	
	# Calcular mitigación efectiva
	var mitigation_pct = 0.0
	if _damage_taken_raw > 0:
		mitigation_pct = 1.0 - (float(_damage_taken_final) / float(_damage_taken_raw))
	
	# Sustain por segundo
	var sustain_per_sec = _heal_total / elapsed_sec
	
	# XP per minute
	var xp_per_min = _xp_gained_total / elapsed_min if elapsed_min > 0 else 0.0
	var levels_per_min = _levels_gained / elapsed_min if elapsed_min > 0 else 0.0
	
	return {
		# Daño infligido
		"damage_dealt": {
			"min": _damage_dealt_samples.min() if _damage_dealt_samples.size() > 0 else 0,
			"max": _damage_dealt_samples.max() if _damage_dealt_samples.size() > 0 else 0,
			"avg": _get_avg(_damage_dealt_samples),
			"total": _damage_dealt_total,
			"dps": _damage_dealt_total / elapsed_sec
		},
		# Mitigación
		"mitigation": {
			"dodges": _dodges_count,
			"shield_absorbed": _shield_absorbed,
			"armor_reduced": _armor_reduced,
			"damage_raw": _damage_taken_raw,
			"damage_final": _damage_taken_final,
			"mitigation_pct": mitigation_pct
		},
		# Sustain
		"sustain": {
			"regen": _heal_from_regen,
			"lifesteal": _heal_from_lifesteal,
			"kill_heal": _heal_from_kill,
			"total": _heal_total,
			"per_sec": sustain_per_sec
		},
		# TTK
		"ttk": {
			"elite_avg": _get_avg(_elite_ttk_samples),
			"elite_samples": _elite_ttk_samples.size(),
			"boss_avg": _get_avg(_boss_ttk_samples),
			"boss_samples": _boss_ttk_samples.size()
		},
		# BALANCE PASS 2: XP/Level
		"progression": {
			"xp_total": _xp_gained_total,
			"xp_per_min": xp_per_min,
			"current_level": _last_level,
			"levels_gained": _levels_gained,
			"levels_per_min": levels_per_min
		},
		# BALANCE PASS 2: Difficulty Scaling
		"difficulty": _last_difficulty_snapshot.duplicate() if _last_difficulty_snapshot else {},
		# Meta
		"elapsed_sec": elapsed_sec,
		"elapsed_min": elapsed_min
	}

func _get_avg(arr: Array) -> float:
	if arr.is_empty():
		return 0.0
	var sum = 0.0
	for v in arr:
		sum += v
	return sum / arr.size()

## Resetear todas las métricas (llamar al inicio de cada run)
func reset_metrics() -> void:
	_damage_dealt_samples.clear()
	_damage_dealt_total = 0
	_damage_dealt_count = 0
	_damage_taken_raw = 0
	_damage_taken_final = 0
	_dodges_count = 0
	_shield_absorbed = 0
	_armor_reduced = 0
	_heal_from_regen = 0.0
	_heal_from_lifesteal = 0.0
	_heal_from_kill = 0.0
	_heal_total = 0.0
	_elite_spawn_times.clear()
	_elite_ttk_samples.clear()
	_boss_spawn_times.clear()
	_boss_ttk_samples.clear()
	# BALANCE PASS 2
	_xp_gained_total = 0
	_levels_gained = 0
	_last_level = 1
	_last_difficulty_snapshot.clear()
	_session_start_time = Time.get_ticks_msec()

func toggle() -> void:
	enabled = !enabled
	if enabled:
		print("[BALANCE DEBUG] ✅ ACTIVADO - Trackeando métricas de balance (F10 para toggle)")
		reset_metrics()
	else:
		print("[BALANCE DEBUG] ❌ DESACTIVADO")
		_print_session_summary()

func _print_session_summary() -> void:
	var m = get_current_metrics()
	print("═══════════════════════════════════════════════════════════════════")
	print("BALANCE DEBUG - SESSION SUMMARY (%.1f min)" % m.elapsed_min)
	print("═══════════════════════════════════════════════════════════════════")
	print("DAMAGE DEALT:")
	print("  Min/Avg/Max: %d / %.0f / %d" % [m.damage_dealt.min, m.damage_dealt.avg, m.damage_dealt.max])
	print("  Total: %d | DPS: %.0f" % [m.damage_dealt.total, m.damage_dealt.dps])
	print("MITIGATION:")
	print("  Dodges: %d | Shield: %d | Armor: %d" % [m.mitigation.dodges, m.mitigation.shield_absorbed, m.mitigation.armor_reduced])
	print("  Raw→Final: %d → %d (%.0f%% mitigated)" % [m.mitigation.damage_raw, m.mitigation.damage_final, m.mitigation.mitigation_pct * 100])
	print("SUSTAIN:")
	print("  Regen: %.0f | Lifesteal: %.0f | Kill: %.0f" % [m.sustain.regen, m.sustain.lifesteal, m.sustain.kill_heal])
	print("  Total: %.0f | Per Sec: %.1f HP/s" % [m.sustain.total, m.sustain.per_sec])
	print("TTK:")
	print("  Elite: %.2fs avg (%d samples)" % [m.ttk.elite_avg, m.ttk.elite_samples])
	print("  Boss: %.2fs avg (%d samples)" % [m.ttk.boss_avg, m.ttk.boss_samples])
	print("PROGRESSION (PASS 2):")
	print("  Level: %d | XP Total: %d | XP/min: %.0f" % [m.progression.current_level, m.progression.xp_total, m.progression.xp_per_min])
	print("  Levels gained: %d | Levels/min: %.2f" % [m.progression.levels_gained, m.progression.levels_per_min])
	if not m.difficulty.is_empty():
		print("DIFFICULTY SCALING (PASS 2):")
		print("  HP: %.2fx | DMG: %.2fx | Spawn: %.2fx | Speed: %.2fx" % [
			m.difficulty.get("hp_mult", 1.0),
			m.difficulty.get("dmg_mult", 1.0),
			m.difficulty.get("spawn_mult", 1.0),
			m.difficulty.get("speed_mult", 1.0)
		])
	print("═══════════════════════════════════════════════════════════════════")

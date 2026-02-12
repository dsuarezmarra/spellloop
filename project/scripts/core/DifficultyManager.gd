# DifficultyManager.gd
# Gestor de dificultad dinámica
# BALANCE PASS 2.5: Escalado ASINTÓTICO para endurance runs (4-8h posibles)
# NOTE: No usar class_name - este script es un autoload singleton

extends Node

signal difficulty_changed(new_level: int)
signal boss_event_triggered(time_minutes: int)
signal phase_changed(new_phase: int, phase_name: String)

var game_manager: Node = null
var enemy_manager: Node = null

# Parámetros de escalado
var current_difficulty_level: int = 1
var elapsed_time: float = 0.0
var boss_spawn_interval: float = 300.0  # 5 minutos en segundos

# Escaladores de dificultad (calculados por fase)
var enemy_speed_multiplier: float = 1.0
var enemy_count_multiplier: float = 1.0
var enemy_damage_multiplier: float = 1.0
var enemy_health_multiplier: float = 1.0
var enemy_attack_speed_multiplier: float = 1.0
var elite_frequency_multiplier: float = 1.0

# Fase actual de escalado
var current_scaling_phase: int = 1

# ═══════════════════════════════════════════════════════════════════════════════
# BALANCE PASS 2.5: ESCALADO ASINTÓTICO PARA ENDURANCE
# ═══════════════════════════════════════════════════════════════════════════════
# 
# FASES DE ESCALADO:
# 1) EARLY/MID (0 - T1): Exponencial agresivo (ranking competitivo)
# 2) LATE COMPETITIVE (T1 - T2): Exponencial suave (runs largas)
# 3) ENDURANCE (T2+): Logarítmico/asintótico (runs de horas)
#
# OBJETIVO:
# - Run promedio: 30-50 min
# - Run buena: 60-90 min
# - Run excepcional: 4-8 horas (posible, no garantizado)
# - Sin "death timer" matemático
#
# TABLE DE ESCALADO:
# ┌────────┬─────────┬──────────┬───────────┐
# │ Minuto │ HP Mult │ DMG Mult │ Fase      │
# ├────────┼─────────┼──────────┼───────────┤
# │   10   │  1.79x  │  1.55x   │ Early     │
# │   30   │  5.74x  │  3.75x   │ Transition│
# │   60   │ 12.0x   │  6.5x    │ Late      │
# │   90   │ 19.8x   │  9.2x    │ Transition│
# │  120   │ 22.5x   │ 10.5x    │ Endurance │
# │  240   │ 27.0x   │ 12.2x    │ Endurance │
# │  480   │ 31.5x   │ 14.0x    │ Endurance │
# └────────┴─────────┴──────────┴───────────┘
# ═══════════════════════════════════════════════════════════════════════════════

# === TRANSICIÓN DE FASES ===
const PHASE_1_END: float = 30.0      # T1: Fin de early/mid (minutos)
const PHASE_2_END: float = 90.0      # T2: Fin de late competitive (minutos)
const PHASE_TRANSITION: float = 10.0 # Duración de transición suave (minutos)

# === PHASE 1: EARLY/MID (0-30 min) - Exponencial agresivo ===
const P1_RATE_HP: float = 0.06       # 6%/min → 5.74x@30min
const P1_RATE_DAMAGE: float = 0.045  # 4.5%/min → 3.75x@30min
const P1_RATE_SPAWN: float = 0.035   # 3.5%/min
const P1_RATE_SPEED: float = 0.015   # 1.5%/min
const P1_RATE_ATTACK_SPEED: float = 0.02

# === PHASE 2: LATE COMPETITIVE (30-90 min) - Exponencial suave ===
const P2_RATE_HP: float = 0.02       # 2%/min (reducido de 6%)
const P2_RATE_DAMAGE: float = 0.015  # 1.5%/min (reducido de 4.5%)
const P2_RATE_SPAWN: float = 0.02    # 2%/min
const P2_RATE_ELITE: float = 0.025   # 2.5%/min - elites más frecuentes

# === PHASE 3: ENDURANCE (90+ min) - Logarítmico/Asintótico ===
# Fórmula: base * (1 + LOG_RATE * ln(1 + (t - T2) / LOG_SCALE))
const P3_LOG_RATE_HP: float = 0.12       # Cuánto crece por cada "e" de tiempo
const P3_LOG_SCALE_HP: float = 45.0      # Escala temporal (minutos para +1 ln)
const P3_LOG_RATE_DAMAGE: float = 0.08
const P3_LOG_SCALE_DAMAGE: float = 60.0
const P3_ELITE_RATE: float = 0.008       # +0.8% por minuto en P3
const P3_SPAWN_RATE: float = 0.008       # Spawn sigue subiendo lento

# === CAPS GLOBALES ===
const SPEED_CAP: float = 1.8
const ATTACK_SPEED_CAP: float = 2.0
const SPAWN_CAP: float = 6.0             # Subido de 4.0 para endurance
const ELITE_FREQ_CAP: float = 3.5        # Máximo 3.5x más elites
const HP_SOFT_CAP: float = 80.0          # Soft cap ~80x HP
const DAMAGE_SOFT_CAP: float = 40.0      # Soft cap ~40x DMG

var boss_events_triggered: int = 0

# === ADAPTIVE DIFFICULTY (Performance-based) ===
# Factor adaptativo: 0.7 = jugador struggle, 1.0 = normal, 1.3 = dominando
var performance_factor: float = 1.0
const PERF_FACTOR_MIN: float = 0.7
const PERF_FACTOR_MAX: float = 1.3
const PERF_LERP_SPEED: float = 0.02  # Suavizado lento para evitar oscilaciones

# Cache de valores base para transiciones
var _p1_end_hp: float = 0.0
var _p1_end_dmg: float = 0.0
var _p1_end_spawn: float = 0.0
var _p2_end_hp: float = 0.0
var _p2_end_dmg: float = 0.0
var _p2_end_spawn: float = 0.0
var _p2_end_elite: float = 0.0

func _ready() -> void:
	add_to_group("difficulty_manager")
	_find_managers()
	_initialize_phase_cache()

func _initialize_phase_cache() -> void:
	# Valores al final de Phase 1 (T1 = 30 min)
	_p1_end_hp = pow(1.0 + P1_RATE_HP, PHASE_1_END)
	_p1_end_dmg = pow(1.0 + P1_RATE_DAMAGE, PHASE_1_END)
	_p1_end_spawn = pow(1.0 + P1_RATE_SPAWN, PHASE_1_END)
	
	# Valores al final de Phase 2 (T2 = 90 min)
	var p2_duration = PHASE_2_END - PHASE_1_END
	_p2_end_hp = _p1_end_hp * pow(1.0 + P2_RATE_HP, p2_duration)
	_p2_end_dmg = _p1_end_dmg * pow(1.0 + P2_RATE_DAMAGE, p2_duration)
	_p2_end_spawn = _p1_end_spawn * pow(1.0 + P2_RATE_SPAWN, p2_duration)
	_p2_end_elite = pow(1.0 + P2_RATE_ELITE, p2_duration)

func _find_managers() -> void:
	var _gt = get_tree()
	if _gt and _gt.root:
		game_manager = _gt.root.get_node_or_null("GameManager")
		enemy_manager = _gt.root.get_node_or_null("EnemyManager")

func _process(delta: float) -> void:
	if not game_manager:
		_find_managers()
		if not game_manager:
			return
	if not game_manager.is_run_active:
		return
	elapsed_time += delta
	_update_difficulty()

func _update_difficulty() -> void:
	var t = elapsed_time / 60.0
	var new_difficulty_level = int(t) + 1
	
	# Determinar fase actual
	var new_phase = _get_current_phase(t)
	if new_phase != current_scaling_phase:
		current_scaling_phase = new_phase
		phase_changed.emit(new_phase, _get_phase_name(new_phase))
	
	# Calcular multiplicadores según fase
	_calculate_phase_multipliers(t)
	
	# Aplicar caps globales
	enemy_speed_multiplier = minf(enemy_speed_multiplier, SPEED_CAP)
	enemy_attack_speed_multiplier = minf(enemy_attack_speed_multiplier, ATTACK_SPEED_CAP)
	enemy_count_multiplier = minf(enemy_count_multiplier, SPAWN_CAP)
	enemy_health_multiplier = minf(enemy_health_multiplier, HP_SOFT_CAP)
	enemy_damage_multiplier = minf(enemy_damage_multiplier, DAMAGE_SOFT_CAP)
	elite_frequency_multiplier = minf(elite_frequency_multiplier, ELITE_FREQ_CAP)
	
	# Aplicar factor adaptativo (performance-based)
	enemy_health_multiplier *= performance_factor
	enemy_damage_multiplier *= performance_factor
	
	# Eventos de nivel
	if new_difficulty_level > current_difficulty_level:
		current_difficulty_level = new_difficulty_level
		difficulty_changed.emit(current_difficulty_level)
		_on_difficulty_level_up()
	
	# Boss events
	if int(elapsed_time) % int(boss_spawn_interval) == 0 and int(elapsed_time) > 0:
		if int(elapsed_time / boss_spawn_interval) > boss_events_triggered:
			boss_events_triggered = int(elapsed_time / boss_spawn_interval)
			_trigger_boss_event()

func _get_current_phase(t: float) -> int:
	if t < PHASE_1_END:
		return 1
	elif t < PHASE_2_END:
		return 2
	else:
		return 3

func _get_phase_name(phase: int) -> String:
	match phase:
		1: return "Early/Mid"
		2: return "Late"
		3: return "Endurance"
		_: return "Unknown"

func _calculate_phase_multipliers(t: float) -> void:
	if t < PHASE_1_END:
		# === PHASE 1: Exponencial puro ===
		enemy_health_multiplier = pow(1.0 + P1_RATE_HP, t)
		enemy_damage_multiplier = pow(1.0 + P1_RATE_DAMAGE, t)
		enemy_count_multiplier = pow(1.0 + P1_RATE_SPAWN, t)
		enemy_speed_multiplier = pow(1.0 + P1_RATE_SPEED, t)
		enemy_attack_speed_multiplier = pow(1.0 + P1_RATE_ATTACK_SPEED, t)
		elite_frequency_multiplier = 1.0
		
	elif t < PHASE_2_END:
		# === PHASE 2: Exponencial suave con transición ===
		var t_in_p2 = t - PHASE_1_END
		var blend = _smoothstep(t, PHASE_1_END, PHASE_1_END + PHASE_TRANSITION)
		
		# HP: transición suave de P1 rate a P2 rate
		var hp_p1_continued = pow(1.0 + P1_RATE_HP, t)
		var hp_p2_from_base = _p1_end_hp * pow(1.0 + P2_RATE_HP, t_in_p2)
		enemy_health_multiplier = lerpf(hp_p1_continued, hp_p2_from_base, blend)
		
		# Damage
		var dmg_p1_continued = pow(1.0 + P1_RATE_DAMAGE, t)
		var dmg_p2_from_base = _p1_end_dmg * pow(1.0 + P2_RATE_DAMAGE, t_in_p2)
		enemy_damage_multiplier = lerpf(dmg_p1_continued, dmg_p2_from_base, blend)
		
		# Spawn
		enemy_count_multiplier = _p1_end_spawn * pow(1.0 + P2_RATE_SPAWN, t_in_p2)
		
		# Speed y attack speed continúan hacia cap
		enemy_speed_multiplier = pow(1.0 + P1_RATE_SPEED, t)
		enemy_attack_speed_multiplier = pow(1.0 + P1_RATE_ATTACK_SPEED, t)
		
		# Elite frequency empieza a subir
		elite_frequency_multiplier = pow(1.0 + P2_RATE_ELITE, t_in_p2)
		
	else:
		# === PHASE 3: Logarítmico/Asintótico ===
		var t_in_p3 = t - PHASE_2_END
		var blend = _smoothstep(t, PHASE_2_END, PHASE_2_END + PHASE_TRANSITION)
		
		# HP: logarítmico desde base P2
		var hp_log = _p2_end_hp * (1.0 + P3_LOG_RATE_HP * log(1.0 + t_in_p3 / P3_LOG_SCALE_HP))
		var hp_p2_continued = _p1_end_hp * pow(1.0 + P2_RATE_HP, t - PHASE_1_END)
		enemy_health_multiplier = lerpf(hp_p2_continued, hp_log, blend)
		
		# Damage logarítmico
		var dmg_log = _p2_end_dmg * (1.0 + P3_LOG_RATE_DAMAGE * log(1.0 + t_in_p3 / P3_LOG_SCALE_DAMAGE))
		var dmg_p2_continued = _p1_end_dmg * pow(1.0 + P2_RATE_DAMAGE, t - PHASE_1_END)
		enemy_damage_multiplier = lerpf(dmg_p2_continued, dmg_log, blend)
		
		# Spawn sigue subiendo lentamente
		enemy_count_multiplier = _p2_end_spawn * pow(1.0 + P3_SPAWN_RATE, t_in_p3)
		
		# Speed y attack speed en cap
		enemy_speed_multiplier = SPEED_CAP
		enemy_attack_speed_multiplier = ATTACK_SPEED_CAP
		
		# Elite frequency sigue subiendo hacia cap
		elite_frequency_multiplier = _p2_end_elite * (1.0 + P3_ELITE_RATE * t_in_p3)

func _smoothstep(t: float, edge0: float, edge1: float) -> float:
	if t <= edge0:
		return 0.0
	if t >= edge1:
		return 1.0
	var x = (t - edge0) / (edge1 - edge0)
	return x * x * (3.0 - 2.0 * x)

func _on_difficulty_level_up() -> void:
	# FIX-BT2b: Siempre recopilar datos
	if BalanceDebugger:
		BalanceDebugger.log_difficulty_scaling(get_scaling_snapshot())

func _trigger_boss_event() -> void:
	var boss_time_minutes = int(elapsed_time / 60.0)
	boss_event_triggered.emit(boss_time_minutes)

func get_difficulty_level() -> int:
	return current_difficulty_level

func get_elapsed_time() -> float:
	return elapsed_time

func get_minutes_elapsed() -> float:
	return elapsed_time / 60.0

func get_current_phase() -> int:
	return current_scaling_phase

func get_elite_frequency_multiplier() -> float:
	return elite_frequency_multiplier

func get_scaling_snapshot() -> Dictionary:
	return {
		"minute": get_minutes_elapsed(),
		"phase": current_scaling_phase,
		"phase_name": _get_phase_name(current_scaling_phase),
		"hp_mult": enemy_health_multiplier,
		"dmg_mult": enemy_damage_multiplier,
		"spawn_mult": enemy_count_multiplier,
		"speed_mult": enemy_speed_multiplier,
		"atk_speed_mult": enemy_attack_speed_multiplier,
		"elite_freq_mult": elite_frequency_multiplier,
		"performance_factor": performance_factor
	}

func reset() -> void:
	elapsed_time = 0.0
	current_difficulty_level = 1
	current_scaling_phase = 1
	enemy_speed_multiplier = 1.0
	enemy_count_multiplier = 1.0
	enemy_damage_multiplier = 1.0
	enemy_health_multiplier = 1.0
	enemy_attack_speed_multiplier = 1.0
	elite_frequency_multiplier = 1.0
	boss_events_triggered = 0
	performance_factor = 1.0

# ═══════════════════════════════════════════════════════════════════════════════
# ADAPTIVE DIFFICULTY — Factor de rendimiento
# ═══════════════════════════════════════════════════════════════════════════════

func update_performance_factor(player_dps: float, damage_taken_rate: float, _kill_rate: float) -> void:
	"""Ajusta la dificultad según el rendimiento del jugador.
	- Si el jugador domina (alto DPS, poco daño recibido) → sube dificultad.
	- Si el jugador está en problemas (bajo DPS, mucho daño) → baja dificultad.
	Se debe llamar periódicamente (ej: cada snapshot de minuto)."""
	if damage_taken_rate <= 0.0 and player_dps <= 0.0:
		return  # Sin datos suficientes

	# Ratio: cuánto daño hace vs cuánto recibe
	# Alto ratio = dominando, bajo ratio = muriendo
	var effectiveness: float
	if damage_taken_rate > 0.0:
		effectiveness = clampf(player_dps / maxf(damage_taken_rate, 1.0), 0.0, 100.0)
	else:
		effectiveness = 10.0  # No recibe daño = dominando

	# Mapear effectiveness a target factor
	# effectiveness ~1-3 → factor 0.7-0.8 (struggling)
	# effectiveness ~5-10 → factor 1.0 (balanced)
	# effectiveness ~15+ → factor 1.2-1.3 (dominating)
	var target: float
	if effectiveness < 5.0:
		target = lerpf(PERF_FACTOR_MIN, 1.0, effectiveness / 5.0)
	elif effectiveness < 15.0:
		target = lerpf(1.0, PERF_FACTOR_MAX, (effectiveness - 5.0) / 10.0)
	else:
		target = PERF_FACTOR_MAX

	# Suavizado lento para evitar oscilaciones bruscas
	performance_factor = lerpf(performance_factor, target, PERF_LERP_SPEED)


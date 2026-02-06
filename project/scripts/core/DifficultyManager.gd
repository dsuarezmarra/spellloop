# DifficultyManager.gd
# Gestor de dificultad dinámica
# BALANCE PASS 2: Escalado EXPONENCIAL para modo ranking

extends Node

class_name DifficultyManager

signal difficulty_changed(new_level: int)
signal boss_event_triggered(time_minutes: int)

var game_manager: Node = null
var enemy_manager: Node = null

# Parámetros de escalado
var current_difficulty_level: int = 1
var elapsed_time: float = 0.0
var boss_spawn_interval: float = 300.0  # 5 minutos en segundos

# Escaladores de dificultad (calculados exponencialmente)
var enemy_speed_multiplier: float = 1.0
var enemy_count_multiplier: float = 1.0
var enemy_damage_multiplier: float = 1.0
var enemy_health_multiplier: float = 1.0
var enemy_attack_speed_multiplier: float = 1.0  # NUEVO: attack speed scaling

# ═══════════════════════════════════════════════════════════════════════════════
# BALANCE PASS 2: ESCALADO MAESTRO EXPONENCIAL
# ═══════════════════════════════════════════════════════════════════════════════
# Fórmula: mult(t) = pow(1.0 + RATE, t) donde t = minutos
#
# DISEÑO PARA RANKING:
# - El juego eventualmente supera al jugador, incluso con build top
# - Build top dura MUCHO (30-45 min), pero no infinito
# - El late game "aprieta" progresivamente
#
# CALIBRACIÓN (valores objetivo):
# - Min 10: HP ~1.8x, DMG ~1.5x
# - Min 20: HP ~3.2x, DMG ~2.4x  
# - Min 30: HP ~5.7x, DMG ~3.5x
# - Min 45: HP ~13x,  DMG ~6.5x
# ═══════════════════════════════════════════════════════════════════════════════

# Rates exponenciales por minuto (estos son los valores de la fórmula pow(1+rate, t))
const EXP_RATE_HP: float = 0.06         # 6% compuesto por minuto → 1.8x@10min, 3.2x@20min
const EXP_RATE_DAMAGE: float = 0.045    # 4.5% compuesto → 1.5x@10min, 2.4x@20min
const EXP_RATE_SPAWN: float = 0.035     # 3.5% compuesto → densidad sube pero no lag
const EXP_RATE_SPEED: float = 0.015     # 1.5% compuesto → sube lento, tiene cap
const EXP_RATE_ATTACK_SPEED: float = 0.02  # 2% compuesto → atacan más rápido

# Caps para evitar situaciones injugables
const SPEED_CAP: float = 1.8            # Máximo 80% más rápido
const ATTACK_SPEED_CAP: float = 2.0     # Máximo 2x velocidad de ataque
const SPAWN_CAP: float = 4.0            # Máximo 4x densidad (evita slideshow)

var boss_events_triggered: int = 0

func _ready() -> void:
	add_to_group("difficulty_manager")
	_find_managers()

func _find_managers() -> void:
	"""Buscar referencias a managers necesarios"""
	var _gt = get_tree()
	if _gt and _gt.root:
		game_manager = _gt.root.get_node_or_null("GameManager")
		enemy_manager = _gt.root.get_node_or_null("EnemyManager")

func _process(delta: float) -> void:
	if not game_manager or not game_manager.is_run_active:
		return
	
	elapsed_time += delta
	_update_difficulty()

func _update_difficulty() -> void:
	"""Actualizar multiplicadores de dificultad con escalado EXPONENCIAL"""
	var minutes_elapsed = elapsed_time / 60.0
	var new_difficulty_level = int(minutes_elapsed) + 1
	
	# ESCALADO EXPONENCIAL: mult = pow(1 + rate, t)
	enemy_health_multiplier = pow(1.0 + EXP_RATE_HP, minutes_elapsed)
	enemy_damage_multiplier = pow(1.0 + EXP_RATE_DAMAGE, minutes_elapsed)
	enemy_count_multiplier = minf(pow(1.0 + EXP_RATE_SPAWN, minutes_elapsed), SPAWN_CAP)
	enemy_speed_multiplier = minf(pow(1.0 + EXP_RATE_SPEED, minutes_elapsed), SPEED_CAP)
	enemy_attack_speed_multiplier = minf(pow(1.0 + EXP_RATE_ATTACK_SPEED, minutes_elapsed), ATTACK_SPEED_CAP)
	
	# Cambio de nivel cada minuto
	if new_difficulty_level > current_difficulty_level:
		current_difficulty_level = new_difficulty_level
		difficulty_changed.emit(current_difficulty_level)
		_on_difficulty_level_up()
	
	# Boss event cada 5 minutos
	if int(elapsed_time) % int(boss_spawn_interval) == 0 and int(elapsed_time) > 0:
		if int(elapsed_time / boss_spawn_interval) > boss_events_triggered:
			boss_events_triggered = int(elapsed_time / boss_spawn_interval)
			_trigger_boss_event()

func _on_difficulty_level_up() -> void:
	"""Llamado cuando sube el nivel de dificultad"""
	# Log de escalado para debug (F10)
	if BalanceDebugger and BalanceDebugger.enabled:
		BalanceDebugger.log_difficulty_scaling(get_scaling_snapshot())

func _trigger_boss_event() -> void:
	"""Desencadenar evento de boss"""
	var boss_time_minutes = int(elapsed_time / 60.0)
	boss_event_triggered.emit(boss_time_minutes)

func get_difficulty_level() -> int:
	return current_difficulty_level

func get_elapsed_time() -> float:
	return elapsed_time

func get_minutes_elapsed() -> float:
	"""Obtener minutos transcurridos (para uso externo)"""
	return elapsed_time / 60.0

func get_scaling_snapshot() -> Dictionary:
	"""Obtener snapshot de todos los multiplicadores actuales (para debug/telemetry)"""
	return {
		"minute": get_minutes_elapsed(),
		"hp_mult": enemy_health_multiplier,
		"dmg_mult": enemy_damage_multiplier,
		"spawn_mult": enemy_count_multiplier,
		"speed_mult": enemy_speed_multiplier,
		"atk_speed_mult": enemy_attack_speed_multiplier
	}

func reset() -> void:
	"""Reiniciar el gestor de dificultad"""
	elapsed_time = 0.0
	current_difficulty_level = 1
	enemy_speed_multiplier = 1.0
	enemy_count_multiplier = 1.0
	enemy_damage_multiplier = 1.0
	enemy_health_multiplier = 1.0
	enemy_attack_speed_multiplier = 1.0
	boss_events_triggered = 0


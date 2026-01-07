# DifficultyManager.gd
# Gestor de dificultad dinámica
# Aumenta progresivamente la dificultad cada minuto

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

# Escaladores de dificultad
var enemy_speed_multiplier: float = 1.0
var enemy_count_multiplier: float = 1.0
var enemy_damage_multiplier: float = 1.0
var enemy_health_multiplier: float = 1.0

# Configuración de escalado
var speed_increase_per_minute: float = 0.05  # 5% por minuto
var spawn_rate_increase_per_minute: float = 0.08  # 8% por minuto
var damage_increase_per_minute: float = 0.03  # 3% por minuto
var health_increase_per_minute: float = 0.04  # 4% por minuto

var boss_events_triggered: int = 0

func _ready() -> void:
	print("[DifficultyManager] Inicializado")
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
	"""Actualizar multiplicadores de dificultad basados en tiempo transcurrido"""
	var minutes_elapsed = elapsed_time / 60.0
	var new_difficulty_level = int(minutes_elapsed) + 1
	
	# Actualizar escaladores
	enemy_speed_multiplier = 1.0 + (minutes_elapsed * speed_increase_per_minute)
	enemy_count_multiplier = 1.0 + (minutes_elapsed * spawn_rate_increase_per_minute)
	enemy_damage_multiplier = 1.0 + (minutes_elapsed * damage_increase_per_minute)
	enemy_health_multiplier = 1.0 + (minutes_elapsed * health_increase_per_minute)
	
	# Cambio de nivel cada minuto
	if new_difficulty_level > current_difficulty_level:
		current_difficulty_level = new_difficulty_level
		difficulty_changed.emit(current_difficulty_level)
		# Debug desactivado: print("[DifficultyManager] Dificultad aumentada")
		_on_difficulty_level_up()
	
	# Boss event cada 5 minutos
	if int(elapsed_time) % int(boss_spawn_interval) == 0 and int(elapsed_time) > 0:
		if int(elapsed_time / boss_spawn_interval) > boss_events_triggered:
			boss_events_triggered = int(elapsed_time / boss_spawn_interval)
			_trigger_boss_event()

func _on_difficulty_level_up() -> void:
	"""Llamado cuando sube el nivel de dificultad"""
	# Aquí se pueden activar eventos especiales, cambios visuales, etc.
	pass

func _trigger_boss_event() -> void:
	"""Desencadenar evento de boss"""
	var boss_time_minutes = int(elapsed_time / 60.0)
	boss_event_triggered.emit(boss_time_minutes)
	# Debug desactivado: print("[DifficultyManager] Evento de Boss")

func get_difficulty_level() -> int:
	return current_difficulty_level

func get_elapsed_time() -> float:
	return elapsed_time

func reset() -> void:
	"""Reiniciar el gestor de dificultad"""
	elapsed_time = 0.0
	current_difficulty_level = 1
	enemy_speed_multiplier = 1.0
	enemy_count_multiplier = 1.0
	enemy_damage_multiplier = 1.0
	enemy_health_multiplier = 1.0
	boss_events_triggered = 0
	print("[DifficultyManager] Reiniciado")


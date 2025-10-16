# GameManager.gd
# Main game state manager and coordinator for all game systems
# Handles game flow, state transitions, and core game loop
# 
# Public API:
# - start_new_run() -> void
# - end_current_run(reason: String) -> void
# - pause_game() -> void
# - resume_game() -> void
# - get_current_state() -> GameState
#
# Signals:
# - game_state_changed(old_state: GameState, new_state: GameState)
# - run_started()
# - run_ended(reason: String, stats: Dictionary)
# - game_paused()
# - game_resumed()

extends Node

signal game_state_changed(old_state: GameState, new_state: GameState)
signal run_started()
signal run_ended(reason: String, stats: Dictionary)
signal game_paused()
signal game_resumed()

enum GameState {
	MAIN_MENU,
	IN_RUN,
	PAUSED,
	GAME_OVER,
	LOADING,
	SETTINGS
}

# Current game state
var current_state: GameState = GameState.MAIN_MENU
var is_run_active: bool = false

# Current run data
var current_run_data: Dictionary = {}
var run_start_time: float = 0.0
var game_start_time: float = 0.0  # Para tracking de tiempo de juego

# Steam integration placeholders
const STEAM_APP_ID = "PLACEHOLDER_STEAM_APPID"  # Replace with real Steam AppID
var steam_initialized: bool = false

func _ready() -> void:
	print("[GameManager] Initializing GameManager...")
	
	# Initialize Steam if available
	_initialize_steam()
	
	# Connect to other managers
	_setup_manager_connections()
	
	print("[GameManager] GameManager initialized successfully")

func _initialize_steam() -> void:
	"""Initialize Steam API if available"""
	# TODO: Implement actual Steam initialization
	# This is a placeholder for Steam integration
	print("[GameManager] Steam initialization placeholder - AppID: ", STEAM_APP_ID)
	steam_initialized = false  # Will be true when real Steam integration is added

func _setup_manager_connections() -> void:
	"""Setup connections with other manager singletons"""
	# Connect to SaveManager signals
	if SaveManager:
		SaveManager.save_completed.connect(_on_save_completed)
		SaveManager.save_failed.connect(_on_save_failed)
	
	# Connect to InputManager signals
	if InputManager:
		InputManager.pause_requested.connect(_on_pause_requested)
	
	# Initialize dungeon system
	_initialize_dungeon_system()

func _initialize_dungeon_system() -> void:
	"""Initialize the dungeon system"""
	# Sistema de mazmorra desactivado temporalmente
	print("[GameManager] Sistema básico inicializado")

func start_new_run() -> void:
	"""Start a new game run"""
	print("[GameManager] Starting new run...")
	
	var old_state = current_state
	current_state = GameState.IN_RUN
	is_run_active = true
	run_start_time = Time.get_time_dict_from_system()["unix"]
	game_start_time = Time.get_time_dict_from_system()["unix"]  # Inicializar tiempo de juego
	
	# Initialize run data
	current_run_data = {
		"start_time": run_start_time,
		"current_biome": 0,
		"rooms_completed": 0,
		"enemies_defeated": 0,
		"spells_cast": 0,
		"damage_taken": 0,
		"score": 0
	}
	
	game_state_changed.emit(old_state, current_state)
	run_started.emit()
	
	# Sistema de mazmorra desactivado temporalmente
	print("[GameManager] Nueva partida iniciada")

func end_current_run(reason: String) -> void:
	"""End the current game run with a given reason"""
	if not is_run_active:
		print("[GameManager] Warning: Attempted to end run but no run is active")
		return
	
	print("[GameManager] Ending run. Reason: ", reason)
	
	var old_state = current_state
	current_state = GameState.GAME_OVER
	is_run_active = false
	
	# Calculate final stats
	var end_time = Time.get_time_dict_from_system()["unix"]
	current_run_data["end_time"] = end_time
	current_run_data["duration"] = end_time - run_start_time
	current_run_data["end_reason"] = reason
	
	game_state_changed.emit(old_state, current_state)
	run_ended.emit(reason, current_run_data)
	
	# Save run data for progression
	SaveManager.save_run_data(current_run_data)

func pause_game() -> void:
	"""Pause the current game"""
	if current_state != GameState.IN_RUN:
		return
	
	var old_state = current_state
	current_state = GameState.PAUSED
	get_tree().paused = true
	
	game_state_changed.emit(old_state, current_state)
	game_paused.emit()

func resume_game() -> void:
	"""Resume the paused game"""
	if current_state != GameState.PAUSED:
		return
	
	var old_state = current_state
	current_state = GameState.IN_RUN
	get_tree().paused = false
	
	game_state_changed.emit(old_state, current_state)
	game_resumed.emit()

func get_current_state() -> GameState:
	"""Get the current game state"""
	return current_state

func change_state(new_state: GameState) -> void:
	"""Change game state"""
	var old_state = current_state
	current_state = new_state
	game_state_changed.emit(old_state, new_state)

func update_run_stat(stat_name: String, value) -> void:
	"""Update a statistic for the current run"""
	if not is_run_active:
		return
	
	if stat_name in current_run_data:
		current_run_data[stat_name] = value
	else:
		print("[GameManager] Warning: Unknown stat: ", stat_name)

func increment_run_stat(stat_name: String, amount: int = 1) -> void:
	"""Increment a statistic for the current run"""
	if not is_run_active:
		return
	
	if stat_name in current_run_data:
		current_run_data[stat_name] += amount
	else:
		print("[GameManager] Warning: Unknown stat: ", stat_name)

# Signal handlers
func _on_save_completed() -> void:
	print("[GameManager] Save completed successfully")

func _on_save_failed(error: String) -> void:
	print("[GameManager] Save failed: ", error)

func _on_pause_requested() -> void:
	if current_state == GameState.IN_RUN:
		pause_game()
	elif current_state == GameState.PAUSED:
		resume_game()

# ========== MÉTODOS PARA SISTEMA DE ENEMIGOS ==========

func get_elapsed_minutes() -> int:
	"""Obtener minutos transcurridos desde el inicio de la partida"""
	if not is_run_active or game_start_time == 0.0:
		return 0
	
	var current_time = Time.get_time_dict_from_system()["unix"]
	var elapsed_seconds = current_time - game_start_time
	var elapsed_minutes = int(elapsed_seconds / 60.0)
	
	return elapsed_minutes

func get_elapsed_seconds() -> float:
	"""Obtener segundos transcurridos desde el inicio de la partida"""
	if not is_run_active or game_start_time == 0.0:
		return 0.0
	
	var current_time = Time.get_time_dict_from_system()["unix"]
	return current_time - game_start_time

func get_game_time_formatted() -> String:
	"""Obtener tiempo de juego formateado como MM:SS"""
	var total_seconds = int(get_elapsed_seconds())
	var minutes = total_seconds / 60
	var seconds = total_seconds % 60
	
	return "%02d:%02d" % [minutes, seconds]

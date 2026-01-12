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

# Combat systems
var attack_manager = null
var player_ref = null
var projectile_visual_manager = null  # Gestor de visuales de proyectiles

# Current run data
var current_run_data: Dictionary = {}
var run_start_time: float = 0.0
var game_start_time: float = 0.0  # Para tracking de tiempo de juego

# Steam integration placeholders
const STEAM_APP_ID = "PLACEHOLDER_STEAM_APPID"  # Replace with real Steam AppID
var steam_initialized: bool = false

func _ready() -> void:
	# Debug desactivado: print("[GameManager] Initializing GameManager...")
	
	# Initialize Steam if available
	_initialize_steam()
	
	# Connect to other managers
	_setup_manager_connections()
	
	# print("[GameManager] GameManager initialized successfully")

func _initialize_steam() -> void:
	"""Initialize Steam API if available"""
	# TODO: Implement actual Steam initialization
	# This is a placeholder for Steam integration
	# Debug desactivado: print("[GameManager] Steam initialization placeholder - AppID: ", STEAM_APP_ID)
	steam_initialized = false  # Will be true when real Steam integration is added

func _setup_manager_connections() -> void:
	"""Setup connections with other manager singletons"""
	# Connect to SaveManager signals (lookup autoload safely)
	var save_manager = null
	var _gt = get_tree()
	save_manager = _gt.root.get_node_or_null("SaveManager") if _gt and _gt.root else null
	if save_manager:
		save_manager.save_completed.connect(_on_save_completed)
		save_manager.save_failed.connect(_on_save_failed)
	
	# Connect to InputManager signals
	var input_manager = null
	# reuse _gt from above (already assigned)
	input_manager = _gt.root.get_node_or_null("InputManager") if _gt and _gt.root else null
	if input_manager:
		input_manager.pause_requested.connect(_on_pause_requested)
	
	# Initialize dungeon system
	_initialize_dungeon_system()

func _initialize_dungeon_system() -> void:
	"""Initialize the dungeon system"""
	# Crear AttackManager como hijo de GameManager
	var am_script = load("res://scripts/core/AttackManager.gd")
	if am_script:
		attack_manager = am_script.new()
		attack_manager.name = "AttackManager"
		add_child(attack_manager)
		# Debug desactivado: print("[GameManager] ⚔️ AttackManager creado")
	
	# Crear ProjectileVisualManager para efectos visuales de proyectiles
	projectile_visual_manager = ProjectileVisualManager.new()
	projectile_visual_manager.name = "ProjectileVisualManager"
	add_child(projectile_visual_manager)
	# Debug desactivado: print("[GameManager] 🎨 ProjectileVisualManager creado")
	
	# Sistema de mazmorra desactivado temporalmente
	# Debug desactivado: print("[GameManager] Sistema básico inicializado")

func start_new_run() -> void:
	"""Start a new game run"""
	# Debug desactivado: print("[GameManager] Starting new run...")
	
	var old_state = current_state
	current_state = GameState.IN_RUN
	is_run_active = true
	# Use a safe accessor for system unix time (handles API differences and missing keys)
	run_start_time = get_unix_time_safe()
	game_start_time = get_unix_time_safe()  # Inicializar tiempo de juego
	
	# Resetear tracking de bosses para nueva partida
	SpawnConfig.reset_boss_tracking()
	
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
	
	# Inicializar AttackManager con el jugador
	if attack_manager:
		# Buscar el jugador en la escena
		var _gt = get_tree()
		var player = null
		if _gt and _gt.root:
			# Intentar varias rutas donde podría estar el player
			player = _gt.root.get_node_or_null("SpellloopGame/SpellloopPlayer")
			if not player:
				player = _gt.root.get_node_or_null("SpellloopGame/WorldRoot/Player")
			if not player:
				player = _gt.root.get_node_or_null("SpellloopGame/Player")
		
		if player:
			attack_manager.initialize(player)
			player_ref = player
			# Debug desactivado: print("[GameManager] ✓ AttackManager inicializado con player")
			# NOTA: Las armas iniciales las equipa el propio Player (_equip_starting_weapons)
			# No duplicar aquí para evitar armas duplicadas
			# equip_initial_weapons()  # DESACTIVADO - ver WizardPlayer._equip_starting_weapons()
		else:
			push_warning("[GameManager] No se encontró el player en la escena")
	
	game_state_changed.emit(old_state, current_state)
	run_started.emit()
	
	# Sistema de mazmorra desactivado temporalmente
	# Debug desactivado: print("[GameManager] Nueva partida iniciada")

func end_current_run(reason: String) -> void:
	"""End the current game run with a given reason"""
	if not is_run_active:
		push_warning("[GameManager] Warning: Attempted to end run but no run is active")
		return
	
	# Debug desactivado: print("[GameManager] Ending run. Reason: ", reason)
	
	var old_state = current_state
	current_state = GameState.GAME_OVER
	is_run_active = false
	
	# Calculate final stats
	var end_time = get_unix_time_safe()
	current_run_data["end_time"] = end_time
	current_run_data["duration"] = end_time - run_start_time
	current_run_data["end_reason"] = reason
	
	game_state_changed.emit(old_state, current_state)
	run_ended.emit(reason, current_run_data)
	
	# Save run data for progression (lookup SaveManager autoload safely)
	var sm = null
	var _gt2 = get_tree()
	sm = _gt2.root.get_node_or_null("SaveManager") if _gt2 and _gt2.root else null
	if sm and sm.has_method("save_run_data"):
		sm.save_run_data(current_run_data)

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
		push_warning("[GameManager] Warning: Unknown stat: " + str(stat_name))

func increment_run_stat(stat_name: String, amount: int = 1) -> void:
	"""Increment a statistic for the current run"""
	if not is_run_active:
		return
	
	if stat_name in current_run_data:
		current_run_data[stat_name] += amount
	else:
		push_warning("[GameManager] Warning: Unknown stat: " + str(stat_name))

# Signal handlers
func _on_save_completed() -> void:
	# Debug desactivado: print("[GameManager] Save completed successfully")
	pass

func _on_save_failed(error: String) -> void:
	push_warning("[GameManager] Save failed: " + error)

func _on_pause_requested() -> void:
	if current_state == GameState.IN_RUN:
		pause_game()
	elif current_state == GameState.PAUSED:
		resume_game()

# ========== MÉTODOS PARA SISTEMA DE COMBATE ==========

func equip_weapon(weapon) -> bool:
	"""Equipar un arma en el AttackManager"""
	if not attack_manager:
		push_warning("[GameManager] Error: AttackManager no disponible")
		return false
	
	attack_manager.add_weapon(weapon)
	return true

# ========== MÉTODOS PARA SISTEMA DE ENEMIGOS ==========

func get_elapsed_minutes() -> int:
	"""Obtener minutos transcurridos desde el inicio de la partida"""
	if not is_run_active or game_start_time == 0.0:
		return 0
	
	var current_time = get_unix_time_safe()
	var elapsed_seconds = current_time - game_start_time
	var elapsed_minutes = int(elapsed_seconds / 60.0)
	
	return elapsed_minutes

func get_elapsed_seconds() -> float:
	"""Obtener segundos transcurridos desde el inicio de la partida"""
	if not is_run_active or game_start_time == 0.0:
		return 0.0
	
	var current_time = get_unix_time_safe()
	return current_time - game_start_time


func get_unix_time_safe() -> float:
	"""Return a unix timestamp (float) using Time.get_time_dict_from_system() if available,
	otherwise fallback to available OS/Time API. Defensive: ensures a number is returned.
	"""
	# Prefer Time.get_time_dict_from_system() if available
	if Time and Time.has_method("get_time_dict_from_system"):
		var tdict = Time.get_time_dict_from_system()
		if typeof(tdict) == TYPE_DICTIONARY and tdict.has("unix"):
			return float(tdict["unix"])

	# Fallback to OS.get_unix_time_from_system() if available
	if OS and OS.has_method("get_unix_time_from_system"):
		# Call dynamically to avoid parse-time errors on builds missing this API
		var val = OS.call("get_unix_time_from_system")
		if typeof(val) in [TYPE_INT, TYPE_FLOAT]:
			return float(val)

	# As last resort, use engine frame count as a monotonic fallback
	return float(Engine.get_physics_frames())

func get_game_time_formatted() -> String:
	"""Obtener tiempo de juego formateado como MM:SS"""
	var total_seconds = int(get_elapsed_seconds())
	var minutes = total_seconds / 60.0
	var seconds = total_seconds % 60
	
	return "%02d:%02d" % [minutes, seconds]

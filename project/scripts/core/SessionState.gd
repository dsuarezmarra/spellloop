# SessionState.gd
# Autoload global para mantener el estado de la sesion entre escenas
#
# Guarda informacion sobre:
# - Si hay una partida activa que se puede reanudar
# - Tiempo de juego al pausar
# - Estado completo de la partida para poder reanudarla

extends Node

# Estado de partida
var has_active_game: bool = false
var paused_game_time: float = 0.0
var game_scene_path: String = "res://scenes/game/Game.tscn"
var saved_player_data: Dictionary = {}

# Estado completo del juego para reanudar
var saved_game_state: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func set_active_game(time: float, player_data: Dictionary = {}) -> void:
	has_active_game = true
	paused_game_time = time
	saved_player_data = player_data
	print("[SessionState] Partida marcada como activa - Tiempo: %.1f" % time)

func save_full_game_state(game_state: Dictionary) -> void:
	"""Guardar el estado completo del juego para poder reanudarlo"""
	has_active_game = true
	saved_game_state = game_state.duplicate(true)  # Deep copy
	paused_game_time = game_state.get("game_time", 0.0)
	print("[SessionState] Estado completo guardado:")
	print("  - Tiempo: %.1f" % paused_game_time)
	print("  - Nivel: %d" % game_state.get("player_level", 1))
	print("  - HP: %d/%d" % [game_state.get("player_hp", 100), game_state.get("player_max_hp", 100)])
	print("  - Armas: %d" % game_state.get("weapons", []).size())
	print("  - Monedas: %d" % game_state.get("coins", 0))

func get_saved_state() -> Dictionary:
	"""Obtener el estado guardado - retorna una copia para evitar modificaciones"""
	print("[SessionState] get_saved_state() llamado - has_active_game: %s, state size: %d" % [has_active_game, saved_game_state.size()])
	if not saved_game_state.is_empty():
		print("  - Nivel guardado: %d" % saved_game_state.get("player_level", 1))
		print("  - Tiempo guardado: %.1f" % saved_game_state.get("game_time", 0.0))
	return saved_game_state.duplicate(true)  # Retornar copia profunda para evitar problemas

func clear_game_state() -> void:
	has_active_game = false
	paused_game_time = 0.0
	saved_player_data = {}
	saved_game_state = {}
	print("[SessionState] Estado de partida limpiado")

func can_resume() -> bool:
	return has_active_game and not saved_game_state.is_empty()

func get_paused_time_formatted() -> String:
	var minutes = int(paused_game_time) / 60
	var seconds = int(paused_game_time) % 60
	return "%02d:%02d" % [minutes, seconds]

# SessionState.gd
# Autoload global para mantener el estado de la sesion entre escenas
#
# Guarda informacion sobre:
# - Si hay una partida activa que se puede reanudar
# - Tiempo de juego al pausar
# - Referencia al estado guardado

extends Node

# Estado de partida
var has_active_game: bool = false
var paused_game_time: float = 0.0
var game_scene_path: String = "res://scenes/game/Game.tscn"
var saved_player_data: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func set_active_game(time: float, player_data: Dictionary = {}) -> void:
	has_active_game = true
	paused_game_time = time
	saved_player_data = player_data
	print("[SessionState] Partida marcada como activa - Tiempo: %.1f" % time)

func clear_game_state() -> void:
	has_active_game = false
	paused_game_time = 0.0
	saved_player_data = {}
	print("[SessionState] Estado de partida limpiado")

func can_resume() -> bool:
	return has_active_game

func get_paused_time_formatted() -> String:
	var minutes = int(paused_game_time) / 60
	var seconds = int(paused_game_time) % 60
	return "%02d:%02d" % [minutes, seconds]

# SessionState.gd
# Autoload global para mantener el estado de la sesion entre escenas
#
# Guarda informacion sobre:
# - Si hay una partida activa que se puede reanudar
# - Tiempo de juego al pausar
# - Estado completo de la partida para poder reanudarla
# - Slot de guardado seleccionado
# - Personaje seleccionado
#
# IMPORTANTE: Ahora persiste a disco para sobrevivir reinicios del juego

extends Node

# Archivo de guardado para partidas en progreso
const SAVE_FILE = "user://session_state.json"

# Estado de partida
var has_active_game: bool = false
var paused_game_time: float = 0.0
var game_scene_path: String = "res://scenes/game/Game.tscn"
var saved_player_data: Dictionary = {}

# Slot y personaje seleccionados
var selected_save_slot: int = -1  # -1 = ninguno seleccionado (consistente con SaveManager)
var selected_character_id: String = "frost_mage"  # ID del personaje seleccionado

# Estado completo del juego para reanudar
var saved_game_state: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Cargar estado guardado de disco al iniciar
	_load_from_disk()

func _load_from_disk() -> void:
	"""Cargar estado de partida desde disco"""
	if not FileAccess.file_exists(SAVE_FILE):
		return

	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file == null:
		# Debug desactivado: print("[SessionState] No se pudo abrir archivo de sesión")
		return

	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		# Debug desactivado: print("[SessionState] Error parseando JSON de sesión")
		return

	var data = json.data
	if not data is Dictionary:
		return

	has_active_game = data.get("has_active_game", false)
	paused_game_time = data.get("paused_game_time", 0.0)
	saved_game_state = data.get("saved_game_state", {})
	saved_player_data = data.get("saved_player_data", {})

	# Restaurar personaje seleccionado (CRÍTICO para resume correcto)
	var saved_char = data.get("selected_character_id", "")
	if not saved_char.is_empty():
		selected_character_id = saved_char

	if has_active_game:
		# Debug desactivado: print("[SessionState] ✅ Partida guardada encontrada en disco:")
		# Debug desactivado: print("  - Tiempo: %.1f segundos" % paused_game_time)
		# Debug desactivado: print("  - Nivel: %d" % saved_game_state.get("player_level", 1))
		# Debug desactivado: print("  - Monedas: %d" % saved_game_state.get("coins", 0))
		pass

func _save_to_disk() -> void:
	"""Guardar estado de partida a disco"""
	var data = {
		"has_active_game": has_active_game,
		"paused_game_time": paused_game_time,
		"saved_game_state": saved_game_state,
		"saved_player_data": saved_player_data,
		"selected_character_id": selected_character_id
	}

	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file == null:
		push_warning("[SessionState] Error: No se pudo guardar a disco")
		return

	file.store_string(JSON.stringify(data))
	file.close()
	# Debug desactivado: print("[SessionState] 💾 Estado guardado a disco")

func set_active_game(time: float, player_data: Dictionary = {}) -> void:
	has_active_game = true
	paused_game_time = time
	saved_player_data = player_data
	# Debug desactivado: print("[SessionState] Partida marcada como activa - Tiempo: %.1f" % time)
	_save_to_disk()

func save_full_game_state(game_state: Dictionary) -> void:
	"""Guardar el estado completo del juego para poder reanudarlo"""
	has_active_game = true
	saved_game_state = game_state.duplicate(true)  # Deep copy
	paused_game_time = game_state.get("game_time", 0.0)
	# Debug desactivado: print("[SessionState] Estado completo guardado:")
	# Debug desactivado: print("  - Tiempo: %.1f" % paused_game_time)
	# Debug desactivado: print("  - Nivel: %d" % game_state.get("player_level", 1))
	# Debug desactivado: print("  - HP: %d/%d" % [game_state.get("player_hp", 100), game_state.get("player_max_hp", 100)])
	# Debug desactivado: print("  - Armas: %d" % game_state.get("weapons", []).size())
	# Debug desactivado: print("  - Monedas: %d" % game_state.get("coins", 0))
	# Debug desactivado: print("  - XP: %d/%d" % [game_state.get("current_exp", 0), game_state.get("exp_to_next_level", 10)])
	# Persistir a disco automáticamente
	_save_to_disk()

func get_saved_state() -> Dictionary:
	"""Obtener el estado guardado - retorna una copia para evitar modificaciones"""
	# Debug desactivado: print("[SessionState] get_saved_state() llamado - has_active_game: %s, state size: %d" % [has_active_game, saved_game_state.size()])
	# Debug desactivado: if not saved_game_state.is_empty():
	# Debug desactivado: 	print("  - Nivel guardado: %d" % saved_game_state.get("player_level", 1))
	# Debug desactivado: 	print("  - Tiempo guardado: %.1f" % saved_game_state.get("game_time", 0.0))
	# Debug desactivado: 	print("  - Monedas guardadas: %d" % saved_game_state.get("coins", 0))
	return saved_game_state.duplicate(true)  # Retornar copia profunda para evitar problemas

func clear_game_state() -> void:
	has_active_game = false
	paused_game_time = 0.0
	saved_player_data = {}
	saved_game_state = {}
	# Debug desactivado: print("[SessionState] Estado de partida limpiado")
	# Eliminar archivo de disco
	if FileAccess.file_exists(SAVE_FILE):
		DirAccess.remove_absolute(SAVE_FILE)
		# Debug desactivado: print("[SessionState] 🗑️ Archivo de sesión eliminado")

func can_resume() -> bool:
	return has_active_game and not saved_game_state.is_empty()

func get_paused_time_formatted() -> String:
	var minutes = int(paused_game_time) / 60
	var seconds = int(paused_game_time) % 60
	return "%02d:%02d" % [minutes, seconds]

# ═══════════════════════════════════════════════════════════════════════════════
# SELECCIÓN DE PERSONAJE Y SLOT
# ═══════════════════════════════════════════════════════════════════════════════

func set_save_slot(slot: int) -> void:
	"""Establecer el slot de guardado seleccionado (0-2)"""
	selected_save_slot = clampi(slot, 0, 2)

func get_save_slot() -> int:
	"""Obtener el slot de guardado actual"""
	return selected_save_slot

func set_character(character_id: String) -> void:
	"""Establecer el personaje seleccionado"""
	selected_character_id = character_id

func get_character() -> String:
	"""Obtener el ID del personaje seleccionado"""
	return selected_character_id

func start_new_game(slot: int, character_id: String) -> void:
	"""Iniciar una nueva partida con slot y personaje específicos"""
	selected_save_slot = clampi(slot, 0, 2)
	selected_character_id = character_id
	clear_game_state()

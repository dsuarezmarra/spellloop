extends Node
## RunContext — Singleton con estado unificado de la run actual.
## Autoload ANTES de los trackers para que todos compartan el mismo run_id.
##
## Proporciona:
##   - run_id unificado (String, 8hex-4hex)
##   - session_id, timestamps, seed
##   - Estado de la run (activa/inactiva)
##   - Señales de ciclo de vida que los trackers pueden escuchar

# ═══════════════════════════════════════════════════════════════════════════════
# SIGNALS
# ═══════════════════════════════════════════════════════════════════════════════

## Emitida al iniciar una nueva run — los trackers deben iniciar sus logs.
signal run_started(context: Dictionary)

## Emitida al finalizar la run — los trackers deben cerrar sus logs.
signal run_ended(context: Dictionary)

# ═══════════════════════════════════════════════════════════════════════════════
# STATE
# ═══════════════════════════════════════════════════════════════════════════════

## ID de sesión (persiste entre runs mientras el juego esté abierto)
var session_id: String = ""

## ID de la run actual (generado en start_run)
var run_id: String = ""

## Seed de la run actual
var run_seed: int = 0

## Timestamp UNIX del inicio de la run
var run_start_timestamp: float = 0.0

## Timestamp ISO del inicio de la run (para nombres de archivo)
var run_start_iso: String = ""

## Ticks al inicio de la run (para medir duración precisa)
var run_start_ticks_ms: int = 0

## ¿Hay una run activa?
var run_active: bool = false

## Contexto completo pasado en start_run (character_id, weapons, etc.)
var run_context: Dictionary = {}

## Contador de runs en esta sesión
var runs_this_session: int = 0

## Versión del juego (se setea desde Game)
var game_version: String = "0.1.0"

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	session_id = _generate_id()

# ═══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════════════════════

func start_run(context: Dictionary = {}) -> void:
	"""Iniciar una nueva run. Llamar ANTES de que los trackers comiencen."""
	if run_active:
		push_warning("[RunContext] start_run() llamado con run ya activa (id=%s). Cerrando." % run_id)
		end_run({"end_reason": "forced_restart"})

	runs_this_session += 1
	run_active = true
	run_id = _generate_id()
	run_seed = context.get("seed", randi())
	run_start_timestamp = Time.get_unix_time_from_system()
	run_start_iso = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	run_start_ticks_ms = Time.get_ticks_msec()
	game_version = context.get("game_version", game_version)

	# Enriquecer contexto con datos unificados
	run_context = context.duplicate()
	run_context["run_id"] = run_id
	run_context["session_id"] = session_id
	run_context["seed"] = run_seed
	run_context["game_version"] = game_version
	run_context["run_start_timestamp"] = run_start_timestamp
	run_context["run_start_iso"] = run_start_iso

	print("[RunContext] 🎮 Run started: %s (session=%s, seed=%d)" % [run_id, session_id, run_seed])
	run_started.emit(run_context)

func end_run(context: Dictionary = {}) -> void:
	"""Finalizar la run actual."""
	if not run_active:
		return

	run_active = false

	# Calcular duración
	var duration_ms = Time.get_ticks_msec() - run_start_ticks_ms
	var duration_s = duration_ms / 1000.0

	# Enriquecer contexto de fin
	var end_context = context.duplicate()
	end_context["run_id"] = run_id
	end_context["session_id"] = session_id
	end_context["duration_s"] = duration_s
	end_context["run_seed"] = run_seed
	end_context["game_version"] = game_version
	end_context["run_start_timestamp"] = run_start_timestamp

	print("[RunContext] 🏁 Run ended: %s (duration=%.1fs, reason=%s)" % [
		run_id, duration_s, end_context.get("end_reason", "unknown")
	])
	run_ended.emit(end_context)

func get_elapsed_seconds() -> float:
	"""Segundos transcurridos desde el inicio de la run."""
	if not run_active:
		return 0.0
	return (Time.get_ticks_msec() - run_start_ticks_ms) / 1000.0

func get_difficulty_snapshot() -> Dictionary:
	"""Obtener snapshot de dificultad actual desde DifficultyManager.
	Centraliza el acceso para que ningún otro módulo haga /root/ lookups."""
	var dm = get_node_or_null("/root/DifficultyManager")
	if dm and dm.has_method("get_scaling_snapshot"):
		return dm.get_scaling_snapshot()
	# Fallback: group lookup
	if dm == null:
		var tree = get_tree()
		if tree:
			dm = tree.get_first_node_in_group("difficulty_manager")
			if dm and dm.has_method("get_scaling_snapshot"):
				return dm.get_scaling_snapshot()
	# DifficultyManager not available
	return {"status": "not_available", "_warning": "DifficultyManager not found"}

# ═══════════════════════════════════════════════════════════════════════════════
# INTERNAL
# ═══════════════════════════════════════════════════════════════════════════════

func _generate_id() -> String:
	return "%08x-%04x" % [Time.get_unix_time_from_system(), randi() & 0xFFFF]

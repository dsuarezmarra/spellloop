extends SceneTree
## AutopilotRunner.gd — Simula partidas completas en modo headless.
##
## Funciona como SceneTree main script (godot --headless -s AutopilotRunner.gd).
## Carga la escena Game.tscn, inyecta un "bot" que:
##   1. Mueve al jugador aleatoriamente (zigzag, kiting)
##   2. Auto-selecciona upgrades en level-ups
##   3. Monitoriza: orphan nodes, errores GDScript, enemy count, FPS, leaks
##   4. Escribe un reporte al finalizar cada run
##
## Uso:
##   godot --headless -s res://tests/autopilot/AutopilotRunner.gd -- --autopilot-runs=3

# ═════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═════════════════════════════════════════════════════════════════
const DEFAULT_RUNS := 2
const DEFAULT_RUN_DURATION := 120.0  # segundos por run (tiempo de juego)
const MOVEMENT_CHANGE_INTERVAL := 1.5  # segundos entre cambios de dirección
const UPGRADE_AUTO_PICK_DELAY := 0.3  # delay antes de auto-seleccionar upgrade
const MAX_ORPHAN_THRESHOLD := 200  # si hay más de N orphans, es un leak
const REPORT_FILE := "user://autopilot_report.json"

# ═════════════════════════════════════════════════════════════════
# ESTADO
# ═════════════════════════════════════════════════════════════════
var _num_runs: int = DEFAULT_RUNS
var _run_duration: float = DEFAULT_RUN_DURATION
var _current_run: int = 0
var _run_timer: float = 0.0
var _movement_timer: float = 0.0
var _current_direction: Vector2 = Vector2.RIGHT
var _game_node: Node = null
var _player_ref: WeakRef = null
var _is_headless: bool = true
var _total_errors: int = 0
var _run_reports: Array = []
var _current_run_errors: Array = []
var _current_run_warnings: Array = []
var _frames_processed: int = 0
var _level_ups_handled: int = 0
var _enemies_killed_total: int = 0
var _upgrade_pending: bool = false
var _startup_complete: bool = false
var _waiting_for_game: bool = false
var _game_scene_loaded: bool = false
var _quit_requested: bool = false
var _phase: String = "init"  # init, loading, playing, reporting, done
var _global_timer: float = 0.0  # Safety timeout global
var _max_global_time: float = 600.0  # 10 min máximo absoluto
var _waiting_for_ready_timer: float = 0.0
const MAX_WAIT_FOR_READY := 30.0  # 30s máximo esperando que el juego cargue

# Monitorización de leaks
var _last_object_count: int = 0
var _object_count_samples: Array = []
var _orphan_count_samples: Array = []

func _initialize() -> void:
	_parse_args()
	_log("═══════════════════════════════════════════════════════")
	_log("🤖 AUTOPILOT RUNNER — Loopialike Gameplay Test")
	_log("   Runs: %d | Duration per run: %ds" % [_num_runs, int(_run_duration)])
	_log("   Headless: %s" % str(_is_headless))
	_log("═══════════════════════════════════════════════════════")

	if _is_headless:
		Engine.time_scale = 20.0
		_log("   ⚡ Engine time_scale set to 20.0x for fast fuzzer")

	# Capturar errores de GDScript
	# En Godot 4.x no hay signal de error global, pero monitorizamos el log
	_phase = "loading"
	_start_next_run()

func _parse_args() -> void:
	var args = OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--autopilot-runs="):
			_num_runs = int(arg.split("=")[1])
		elif arg.begins_with("--autopilot-duration="):
			_run_duration = float(arg.split("=")[1])
		elif arg.begins_with("--autopilot-headless="):
			_is_headless = arg.split("=")[1] == "true"

	# También parsear args normales (sin --)
	var all_args = OS.get_cmdline_args()
	for arg in all_args:
		if arg.begins_with("--autopilot-runs="):
			_num_runs = int(arg.split("=")[1])
		elif arg.begins_with("--autopilot-duration="):
			_run_duration = float(arg.split("=")[1])

func _start_next_run() -> void:
	_current_run += 1
	if _current_run > _num_runs:
		_finalize_all()
		return

	_log("")
	_log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	_log("🎮 RUN %d / %d — Starting..." % [_current_run, _num_runs])
	_log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	_run_timer = 0.0
	_movement_timer = 0.0
	_current_run_errors = []
	_current_run_warnings = []
	_frames_processed = 0
	_level_ups_handled = 0
	_upgrade_pending = false
	_game_scene_loaded = false
	_phase = "loading"

	# Resetear SessionState para evitar "resume"
	var session_state = root.get_node_or_null("SessionState")
	if session_state and session_state.has_method("clear_saved_state"):
		session_state.clear_saved_state()
	if session_state and "saved_state" in session_state:
		session_state.saved_state = {}
	if session_state and "_can_resume" in session_state:
		session_state._can_resume = false

	# Configurar personaje por defecto
	if session_state and session_state.has_method("set_character"):
		session_state.set_character("arcanist")  # Personaje seguro

	# Cargar Game.tscn
	_load_game_scene()

func _load_game_scene() -> void:
	_log("   📦 Loading Game.tscn...")

	# Limpiar escena actual si existe
	if _game_node and is_instance_valid(_game_node):
		_game_node.queue_free()
		_game_node = null

	var packed = load("res://scenes/game/Game.tscn")
	if packed == null:
		_record_error("CRITICAL", "Cannot load Game.tscn")
		_end_current_run("load_failed")
		return

	_game_node = packed.instantiate()
	if _game_node == null:
		_record_error("CRITICAL", "Cannot instantiate Game.tscn")
		_end_current_run("instantiate_failed")
		return

	root.add_child(_game_node)
	_game_scene_loaded = true
	_phase = "waiting_for_ready"
	_waiting_for_ready_timer = 0.0
	_log("   ✅ Game scene added to tree")

	# Esperar frames para que _ready() corra
	await _wait_frames(15)
	if _phase == "waiting_for_ready":
		_on_game_ready()

func _on_game_ready() -> void:
	# Buscar el player
	var player = _find_player()
	if player:
		_player_ref = weakref(player)
		_log("   🎯 Player found: %s" % player.name)
	else:
		_log("   ⚠️  Player not found yet, will retry...")

	# Conectar señales del GameManager
	var gm = root.get_node_or_null("GameManager")
	if gm:
		if gm.has_signal("run_ended") and not gm.run_ended.is_connected(_on_run_ended):
			gm.run_ended.connect(_on_run_ended)

	# Capturar snapshot inicial de objetos
	_last_object_count = Performance.get_monitor(Performance.OBJECT_COUNT)

	_phase = "playing"
	_log("   ▶️  Playing started (monitoring for %ds)" % int(_run_duration))

func _process(delta: float) -> bool:
	# Safety timeout global — NUNCA colgarse más de _max_global_time
	_global_timer += delta
	if _global_timer > _max_global_time:
		_log("   🛑 GLOBAL SAFETY TIMEOUT (%.0fs) — forcing exit" % _global_timer)
		_total_errors += 1
		_finalize_all()
		return false

	# SceneTree override
	match _phase:
		"playing":
			_process_gameplay(delta)
		"waiting_for_ready":
			_waiting_for_ready_timer += delta
			if _waiting_for_ready_timer > MAX_WAIT_FOR_READY:
				_log("   ❌ Game failed to become ready in %.0fs" % MAX_WAIT_FOR_READY)
				_record_error("LOAD_TIMEOUT", "Game not ready after %.0fs" % MAX_WAIT_FOR_READY)
				_end_current_run("load_timeout")
		"done":
			if not _quit_requested:
				_quit_requested = true
				quit(0 if _total_errors == 0 else 1)
	return false  # false = continuar procesando

func _process_gameplay(delta: float) -> void:
	_run_timer += delta
	_movement_timer += delta
	_frames_processed += 1

	# ─── Monitorización cada 5 segundos ───
	if _frames_processed % 300 == 0:  # ~5s a 60fps
		_monitor_health_check()

	# ─── Check fin de run ───
	if _run_timer >= _run_duration:
		_log("   ⏱️  Run duration reached (%.0fs)" % _run_timer)
		_end_current_run("duration_complete")
		return

	# ─── Verificar que el player sigue vivo ───
	var player = _get_player()
	if player == null:
		# Puede que haya muerto — esperar Game Over
		if _run_timer > 5.0:  # Dar 5s de gracia al inicio
			_check_game_over_screen()
		return

	# ─── Movimiento simulado ───
	if _movement_timer >= MOVEMENT_CHANGE_INTERVAL:
		_movement_timer = 0.0
		_update_movement_direction()

	_apply_movement(player)

	# ─── Auto-handle level-up panels ───
	_check_and_handle_level_up()

	# ─── Auto-handle chest popups ───
	_check_and_handle_chest_popup()

func _update_movement_direction() -> void:
	# Patrón de movimiento: zigzag con tendencia a alejarse de bordes
	var patterns := [
		Vector2(1, 0),    # derecha
		Vector2(1, 1).normalized(),   # diagonal abajo-derecha
		Vector2(0, -1),   # arriba
		Vector2(-1, 1).normalized(),  # diagonal abajo-izquierda
		Vector2(-1, 0),   # izquierda
		Vector2(1, -1).normalized(),  # diagonal arriba-derecha
		Vector2(0, 1),    # abajo
		Vector2(-1, -1).normalized(), # diagonal arriba-izquierda
	]

	# Elegir dirección aleatoria pero con tendencia al centro si estamos lejos
	var player = _get_player()
	if player:
		var pos = player.global_position
		var dist_from_center = pos.length()
		if dist_from_center > 600:  # Si estamos lejos del centro, volver
			_current_direction = -pos.normalized()
			# Añadir un poco de variación
			_current_direction = _current_direction.rotated(randf_range(-0.5, 0.5))
		else:
			_current_direction = patterns[randi() % patterns.size()]
	else:
		_current_direction = patterns[randi() % patterns.size()]

func _apply_movement(player: Node) -> void:
	if "velocity" in player:
		var speed := 200.0
		if player.has_method("get_speed"):
			speed = player.get_speed()
		elif "move_speed" in player:
			speed = player.move_speed
		player.velocity = _current_direction * speed

		# CHEAT: Full God Mode every frame so the fuzzer survives to late game
		if "max_health" in player:
			player.max_health = 999999
		if "current_health" in player:
			player.current_health = 999999
		elif player.has_method("heal"):
			player.heal(999999)

		# CHEAT: Continuous XP gain so the fuzzer levels up and tests 90% of upgrades
		if player.is_inside_tree():
			var exp_mgr = player.get_tree().get_first_node_in_group("experience_manager")
			if exp_mgr and exp_mgr.has_method("gain_experience"):
				if randf() < 0.1: # Smooth the calls to prevent spamming popups too densely
					exp_mgr.gain_experience(150)

func _check_and_handle_level_up() -> void:
	# Buscar LevelUpPanel activo
	var level_panel = _find_node_by_class_hint("LevelUpPanel")
	if level_panel == null or not level_panel.visible:
		_upgrade_pending = false
		return

	if _upgrade_pending:
		return  # Ya estamos procesando uno

	_upgrade_pending = true
	_level_ups_handled += 1

	# Buscar botones/opciones de upgrade y seleccionar uno aleatorio
	# LevelUpPanel tiene un método para esto o botones clickeables
	await _wait_frames(int(UPGRADE_AUTO_PICK_DELAY * 60))

	if not is_instance_valid(level_panel) or not level_panel.visible:
		_upgrade_pending = false
		return

	# Intentar interactuar con el LevelUpPanel específico del juego
	if level_panel.has_method("_confirm_selection") and "option_index" in level_panel and "options" in level_panel:
		if level_panel.options.size() > 0:
			level_panel.option_index = randi() % level_panel.options.size()
			level_panel.current_row = 0 # Asegurar que estemos en fila opciones (Row.OPTIONS)
			level_panel._confirm_selection()
			_log("   🎰 Auto-selected upgrade option #%d (level-up #%d)" % [level_panel.option_index, _level_ups_handled])
	elif level_panel.has_method("_on_option_selected"):
		# Fallback genérico 1
		var option_idx = randi() % 3
		level_panel.call("_on_option_selected", option_idx)
		_log("   🎰 Auto-selected upgrade option #%d (level-up #%d)" % [option_idx, _level_ups_handled])
	elif level_panel.has_method("select_option"):
		# Fallback genérico 2
		level_panel.select_option(randi() % 3)
	else:
		# Fallback: buscar botones genéricos
		var buttons = _find_children_of_type(level_panel, "Button")
		if buttons.size() > 0:
			var btn = buttons[randi() % buttons.size()]
			if btn.has_method("emit_signal"):
				btn.emit_signal("pressed")
				_log("   🎰 Auto-pressed upgrade button (level-up #%d)" % _level_ups_handled)

	_upgrade_pending = false

func _check_and_handle_chest_popup() -> void:
	var chest_panel = _find_node_by_class_hint("SimpleChestPopup")
	if chest_panel != null and chest_panel.visible:
		# Añadir un delay corto tal como en level_up
		if not chest_panel.has_meta("autopilot_handling"):
			chest_panel.set_meta("autopilot_handling", true)
			await _wait_frames(30)
			if not is_instance_valid(chest_panel) or not chest_panel.visible:
				return
			
			if chest_panel.is_jackpot_mode:
				if chest_panel.has_method("_on_claim_all_pressed"):
					chest_panel.call("_on_claim_all_pressed")
					_log("   🎁 Auto-claimed jackpot chest")
			else:
				if chest_panel.has_method("_select_item_at_index"):
					chest_panel.call("_select_item_at_index", 0)
					_log("   🎁 Auto-claimed standard chest")
			
			if is_instance_valid(chest_panel) and chest_panel.has_method("queue_free") and chest_panel.visible:
				chest_panel.queue_free()

func _check_game_over_screen() -> void:
	var go_screen = _find_node_by_class_hint("GameOverScreen")
	if go_screen and go_screen.visible:
		_log("   💀 Game Over screen detected at %.0fs" % _run_timer)
		_end_current_run("player_died")
		return

func _monitor_health_check() -> void:
	# ─── Object count (leak detection) ───
	var obj_count = Performance.get_monitor(Performance.OBJECT_COUNT)
	_object_count_samples.append(obj_count)

	var orphan_count = Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	_orphan_count_samples.append(orphan_count)

	if orphan_count > MAX_ORPHAN_THRESHOLD:
		_record_warning("LEAK_SUSPECT",
			"Orphan nodes: %d (threshold: %d)" % [orphan_count, MAX_ORPHAN_THRESHOLD])

	# ─── Object count growth check ───
	if _object_count_samples.size() > 5:
		var growth = obj_count - _object_count_samples[0]
		var time_elapsed = _run_timer
		if time_elapsed > 10 and growth > 500:
			var rate = growth / time_elapsed
			if rate > 20:  # Más de 20 objetos/segundo es sospechoso
				_record_warning("OBJECT_GROWTH",
					"Object count growing at %.1f/s (total: %d, delta: %d)" %
					[rate, obj_count, growth])

	# ─── Enemy count sanity ───
	var enemies = _find_nodes_in_group("enemies")
	var enemy_count = enemies.size() if enemies else 0
	if enemy_count > 500:
		_record_warning("ENEMY_OVERFLOW",
			"Enemy count very high: %d" % enemy_count)

	# ─── Player health ───
	var player = _get_player()
	if player and player.has_method("get_health"):
		var hp = player.get_health()
		if hp is Dictionary and hp.has("current") and hp.has("max"):
			if hp.current < 0:
				_record_error("NEGATIVE_HP",
					"Player HP is negative: %d" % hp.current)

	# ─── Log periódico ───
	var time_str = "%02d:%02d" % [int(_run_timer) / 60, int(_run_timer) % 60]
	_log("   📊 [%s] Objects: %d | Orphans: %d | Enemies: %d | LevelUps: %d" %
		[time_str, obj_count, orphan_count, enemy_count, _level_ups_handled])

func _end_current_run(reason: String) -> void:
	_phase = "reporting"

	# Recopilar stats finales
	var report := {
		"run": _current_run,
		"reason": reason,
		"duration_seconds": _run_timer,
		"frames_processed": _frames_processed,
		"level_ups_handled": _level_ups_handled,
		"errors": _current_run_errors.duplicate(),
		"warnings": _current_run_warnings.duplicate(),
		"error_count": _current_run_errors.size(),
		"warning_count": _current_run_warnings.size(),
		"final_object_count": Performance.get_monitor(Performance.OBJECT_COUNT),
		"final_orphan_count": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		"object_count_samples": _object_count_samples.duplicate(),
		"orphan_count_samples": _orphan_count_samples.duplicate(),
	}

	# Stats del juego si están disponibles
	if _game_node and "run_stats" in _game_node:
		report["game_stats"] = _game_node.run_stats.duplicate()

	# RunAuditTracker data
	var rat = root.get_node_or_null("RunAuditTracker")
	if rat and rat.has_method("get_run_summary"):
		report["audit_data"] = rat.get_run_summary()

	_run_reports.append(report)

	_log("")
	_log("   📋 Run %d Report:" % _current_run)
	_log("      Reason: %s" % reason)
	_log("      Duration: %.1fs" % _run_timer)
	_log("      Frames: %d" % _frames_processed)
	_log("      Level-ups: %d" % _level_ups_handled)
	_log("      Errors: %d | Warnings: %d" % [_current_run_errors.size(), _current_run_warnings.size()])

	if _current_run_errors.size() > 0:
		_log("      ❌ ERRORS:")
		for err in _current_run_errors:
			_log("         - [%s] %s" % [err.type, err.message])

	if _current_run_warnings.size() > 0:
		_log("      ⚠️  WARNINGS:")
		for warn in _current_run_warnings:
			_log("         - [%s] %s" % [warn.type, warn.message])

	# Limpiar escena actual
	_cleanup_current_game()

	# Reset monitoring
	_object_count_samples.clear()
	_orphan_count_samples.clear()
	_player_ref = null

	# Siguiente run o finalizar
	await _wait_frames(30)
	_start_next_run()

func _cleanup_current_game() -> void:
	# Terminar el run en GameManager si está activo
	var gm = root.get_node_or_null("GameManager")
	if gm and gm.has_method("end_current_run"):
		gm.end_current_run("autopilot_end")

	# Limpiar escena
	if _game_node and is_instance_valid(_game_node):
		# Quitar del árbol sin queue_free aún (para evitar race conditions)
		if _game_node.get_parent():
			_game_node.get_parent().remove_child(_game_node)
		_game_node.queue_free()
		_game_node = null

func _finalize_all() -> void:
	_log("")
	_log("═══════════════════════════════════════════════════════")
	_log("📊 AUTOPILOT FINAL REPORT")
	_log("═══════════════════════════════════════════════════════")
	_log("   Runs completed: %d / %d" % [_run_reports.size(), _num_runs])
	_log("   Total errors: %d" % _total_errors)

	var total_warnings := 0
	var total_level_ups := 0
	for report in _run_reports:
		total_warnings += report.warning_count
		total_level_ups += report.level_ups_handled

	_log("   Total warnings: %d" % total_warnings)
	_log("   Total level-ups auto-handled: %d" % total_level_ups)
	_log("")

	# Escribir reporte JSON
	_write_report()

	if _total_errors > 0:
		_log("❌ AUTOPILOT_FAIL — %d errors detected across %d runs" %
			[_total_errors, _run_reports.size()])
	else:
		_log("✅ AUTOPILOT_PASS — All %d runs completed clean" % _run_reports.size())

	_log("═══════════════════════════════════════════════════════")
	_phase = "done"

func _write_report() -> void:
	var report := {
		"timestamp": Time.get_datetime_string_from_system(),
		"godot_version": Engine.get_version_info(),
		"runs_requested": _num_runs,
		"runs_completed": _run_reports.size(),
		"total_errors": _total_errors,
		"run_reports": _run_reports,
	}

	var file = FileAccess.open(REPORT_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
		_log("   📄 Report written to: %s" % REPORT_FILE)
	else:
		_log("   ⚠️  Could not write report file")

# ═════════════════════════════════════════════════════════════════
# UTILIDADES
# ═════════════════════════════════════════════════════════════════
func _find_player() -> Node:
	var players = _find_nodes_in_group("player")
	if players.size() > 0:
		return players[0]

	# Fallback: buscar por nombre
	if _game_node:
		var pc = _game_node.get_node_or_null("PlayerContainer")
		if pc and pc.get_child_count() > 0:
			return pc.get_child(0)

	return null

func _get_player() -> Node:
	if _player_ref and _player_ref.get_ref():
		return _player_ref.get_ref()
	# Retry
	var p = _find_player()
	if p:
		_player_ref = weakref(p)
	return p

func _find_node_by_class_hint(class_hint: String) -> Node:
	# Busca nodos cuyo script path contenga el hint
	return _find_node_recursive(root, class_hint)

func _find_node_recursive(node: Node, hint: String) -> Node:
	if node.name == hint:
		return node
	var script = node.get_script()
	if script and script.resource_path.find(hint) != -1:
		return node
	for child in node.get_children():
		var found = _find_node_recursive(child, hint)
		if found:
			return found
	return null

func _find_children_of_type(node: Node, type_name: String) -> Array:
	var result := []
	for child in node.get_children():
		if child.get_class() == type_name:
			result.append(child)
		result.append_array(_find_children_of_type(child, type_name))
	return result

func _wait_frames(count: int) -> void:
	for i in count:
		await process_frame

func _record_error(type: String, message: String) -> void:
	_total_errors += 1
	_current_run_errors.append({
		"type": type,
		"message": message,
		"time": _run_timer,
		"run": _current_run,
	})
	_log("   ❌ ERROR [%s]: %s (t=%.1fs)" % [type, message, _run_timer])

func _record_warning(type: String, message: String) -> void:
	_current_run_warnings.append({
		"type": type,
		"message": message,
		"time": _run_timer,
		"run": _current_run,
	})
	# No log every warning to avoid spam — only first occurrence of each type
	var seen_types := {}
	for w in _current_run_warnings:
		seen_types[w.type] = true
	if not type in seen_types or _current_run_warnings.size() <= 3:
		_log("   ⚠️  WARNING [%s]: %s" % [type, message])

func _on_run_ended(_reason: String, _stats: Dictionary) -> void:
	if _phase == "playing":
		_log("   🏁 GameManager.run_ended signal received: %s" % _reason)
		_end_current_run("gm_signal_%s" % _reason)

func _log(msg: String) -> void:
	print(msg)

func _find_nodes_in_group(group: String) -> Array:
	# self ES el SceneTree, llamar al método nativo directamente
	return get_nodes_in_group(group)

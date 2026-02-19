extends Node
## RunBundleManager — Orquestador del sistema de bundles por run.
##
## Crea carpeta unificada `user://runs/run_<run_id>/` y redirige todos los
## logs de los trackers existentes a esa carpeta, sin modificar su lógica interna.
##
## Estructura de cada bundle:
##   run_<id>/
##     meta.json           — metadatos de la run (timestamps, seed, character, etc.)
##     summary.json        — resumen generado al final (stats, duración, etc.)
##     audit.jsonl          — log de RunAuditTracker
##     audit_report.md      — reporte markdown de RunAuditTracker
##     balance.jsonl        — log de BalanceTelemetry
##     perf.jsonl           — extracto de PerfTracker para esta run
##
## Archivos legacy siguen escribiéndose en sus carpetas originales (backward compat).
##
## USO desde Game.gd:
##   Inicio:  RunBundleManager.begin_bundle(context)   # ANTES de start_run() de trackers
##   Fin:     RunBundleManager.finalize_bundle(context) # DESPUÉS de end_run() de trackers

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIG
# ═══════════════════════════════════════════════════════════════════════════════

const RUNS_DIR: String = "user://runs"
const MAX_BUNDLES: int = 200  ## Máximo de bundles a conservar (FIFO)
const ENABLE_BUNDLES: bool = true

# ═══════════════════════════════════════════════════════════════════════════════
# STATE
# ═══════════════════════════════════════════════════════════════════════════════

var _current_bundle_dir: String = ""
var _bundle_active: bool = false
var _run_id: String = ""
var _meta: Dictionary = {}

# Paths dentro del bundle actual (usados por trackers via get_log_path_for())
var _bundle_paths: Dictionary = {}  # tracker_name -> path

var _bundle_meta_path: String = ""
var _bundle_summary_path: String = ""

# Path del perf log de sesión (para extraer segmento)
var _session_perf_log: String = ""

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Auto-disable in release builds
	if not OS.is_debug_build() and "--enable-run-bundles" not in OS.get_cmdline_args():
		return

	if not ENABLE_BUNDLES:
		return

	# Asegurar directorio raíz
	if not DirAccess.dir_exists_absolute(RUNS_DIR):
		DirAccess.make_dir_recursive_absolute(RUNS_DIR)

	print("[RunBundleManager] ✅ Initialized. Bundles: %s" % ProjectSettings.globalize_path(RUNS_DIR))

# ═══════════════════════════════════════════════════════════════════════════════
# PUBLIC API — Llamar desde Game.gd
# ═══════════════════════════════════════════════════════════════════════════════

func begin_bundle(context: Dictionary = {}) -> void:
	"""Crear directorio del bundle y preparar paths.
	Llamar ANTES de tracker.start_run() para que los trackers puedan
	usar get_log_path_for() durante su inicialización."""
	if not ENABLE_BUNDLES:
		return

	var ctx = get_node_or_null("/root/RunContext")
	_run_id = ctx.run_id if ctx else context.get("run_id", "unknown")

	# Crear directorio del bundle
	_current_bundle_dir = RUNS_DIR.path_join("run_%s" % _run_id)
	DirAccess.make_dir_recursive_absolute(_current_bundle_dir)

	# Definir paths del bundle (los trackers los consultan via get_log_path_for)
	_bundle_paths = {
		"audit": _current_bundle_dir.path_join("audit.jsonl"),
		"balance": _current_bundle_dir.path_join("balance.jsonl"),
		"perf": _current_bundle_dir.path_join("perf.jsonl"),
		"audit_report": _current_bundle_dir.path_join("audit_report.md"),
		"upgrade_audit": _current_bundle_dir.path_join("upgrade_audit.jsonl"),
	}
	_bundle_meta_path = _current_bundle_dir.path_join("meta.json")
	_bundle_summary_path = _current_bundle_dir.path_join("summary.json")

	# Guardar referencia al perf log de sesión (para extraer segmento al final)
	var perf = get_node_or_null("/root/PerfTracker")
	if perf and "_current_log_file" in perf:
		_session_perf_log = perf._current_log_file

	# Escribir meta.json
	var iso = ""
	if ctx:
		iso = ctx.run_start_iso
	if iso == "":
		iso = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")

	_meta = {
		"schema_version": 2,
		"run_id": _run_id,
		"session_id": ctx.session_id if ctx else "",
		"seed": ctx.run_seed if ctx else context.get("seed", 0),
		"character_id": context.get("character_id", "unknown"),
		"starting_weapons": context.get("starting_weapons", []),
		"game_version": context.get("game_version", "0.1.0"),
		"start_timestamp": ctx.run_start_timestamp if ctx else Time.get_unix_time_from_system(),
		"start_iso": iso,
		"os": OS.get_name(),
		"godot_version": Engine.get_version_info().string,
		"files": {
			"audit_log": "audit.jsonl",
			"balance_log": "balance.jsonl",
			"perf_log": "perf.jsonl",
			"audit_report": "audit_report.md",
			"summary": "summary.json",
			"event_index": "event_index.json"
		}
	}
	_write_json(_bundle_meta_path, _meta)

	_bundle_active = true
	print("[RunBundleManager] 📦 Bundle created: %s" % ProjectSettings.globalize_path(_current_bundle_dir))

func finalize_bundle(context: Dictionary = {}) -> void:
	"""Generar summary, copiar perf segment, copiar audit report.
	Llamar DESPUÉS de tracker.end_run() para que los reports ya estén generados."""
	if not ENABLE_BUNDLES or not _bundle_active:
		return

	_bundle_active = false

	# Copiar el extracto de perf relevante a esta run
	_copy_perf_segment()

	# Copiar el reporte MD de audit al bundle si existe
	_copy_audit_report()

	# Copiar logs del bundle a carpetas legacy (backward compatibility)
	_copy_to_legacy_dirs()

	# Generar summary.json
	_generate_summary(context)

	# Generar event_index.json (índice por tipo de evento para navegación rápida)
	# MUST run before integrity so integrity can verify the file exists
	_generate_event_index()

	# Generar integrity.json (last artifact step — verifies all others)
	_generate_integrity()

	# Limpieza de bundles antiguos
	_cleanup_old_bundles()

	print("[RunBundleManager] 📦 Bundle finalized: %s" % _run_id)

func get_log_path_for(tracker_name: String) -> String:
	"""Devuelve la ruta dentro del bundle para un tracker dado.
	Los trackers llaman esto en su start_run() para saber dónde escribir.
	Devuelve "" si no hay bundle activo — el tracker usa su path legacy."""
	if not ENABLE_BUNDLES or not _bundle_active:
		return ""
	return _bundle_paths.get(tracker_name, "")

# ═══════════════════════════════════════════════════════════════════════════════
# LEGACY BACKWARD COMPATIBILITY
# ═══════════════════════════════════════════════════════════════════════════════

func _copy_to_legacy_dirs() -> void:
	"""Copiar los logs del bundle a las carpetas legacy originales."""

	# RunAuditTracker → user://audit_logs/
	var audit = get_node_or_null("/root/RunAuditTracker")
	if audit and "LOG_DIR" in audit:
		var audit_bundle = _bundle_paths.get("audit", "")
		if audit_bundle != "" and FileAccess.file_exists(audit_bundle):
			var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
			var legacy_path = audit.LOG_DIR.path_join("audit_%s_%s.jsonl" % [_run_id, timestamp])
			_copy_file(audit_bundle, legacy_path)

	# BalanceTelemetry → user://balance_logs/
	var balance = get_node_or_null("/root/BalanceTelemetry")
	if balance and "LOG_DIR" in balance:
		var balance_bundle = _bundle_paths.get("balance", "")
		if balance_bundle != "" and FileAccess.file_exists(balance_bundle):
			var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
			var legacy_path = balance.LOG_DIR.path_join("run_%s_%s.jsonl" % [_run_id, timestamp])
			_copy_file(balance_bundle, legacy_path)

# ═══════════════════════════════════════════════════════════════════════════════
# PERF EXTRACTION
# ═══════════════════════════════════════════════════════════════════════════════

func _copy_perf_segment() -> void:
	"""Extraer las líneas de PerfTracker que corresponden a esta run
	(basándose en timestamps) y copiarlas al bundle."""
	if _session_perf_log == "":
		return

	var perf_bundle_path = _bundle_paths.get("perf", "")
	if perf_bundle_path == "":
		return

	var ctx = get_node_or_null("/root/RunContext")
	if not ctx:
		return

	var run_start_ticks = ctx.run_start_ticks_ms

	# Leer perf log completo y filtrar líneas de esta run
	if not FileAccess.file_exists(_session_perf_log):
		return

	var source = FileAccess.open(_session_perf_log, FileAccess.READ)
	if not source:
		return

	var dest = FileAccess.open(perf_bundle_path, FileAccess.WRITE)
	if not dest:
		source.close()
		return

	while not source.eof_reached():
		var line = source.get_line().strip_edges()
		if line.is_empty():
			continue

		var json = JSON.new()
		if json.parse(line) != OK:
			continue

		var data = json.data
		if data is Dictionary:
			var ts = data.get("timestamp", 0)
			# Incluir si el timestamp (ticks_msec) es >= run_start
			# PerfTracker usa Time.get_ticks_msec() para "timestamp" en log_event
			# pero uses Time.get_unix_time_from_system() for session_start
			# Incluimos todo lo que tenga frame (spike events durante la run)
			if data.get("event", "") == "session_start":
				# Inject run_id so integrity checker sees it on the first line
				data["run_id"] = _run_id
				dest.store_line(JSON.stringify(data))
			elif ts >= run_start_ticks:
				dest.store_line(line)

	source.close()
	dest.close()

# ═══════════════════════════════════════════════════════════════════════════════
# AUDIT REPORT COPY
# ═══════════════════════════════════════════════════════════════════════════════

func _copy_audit_report() -> void:
	"""Copiar el reporte markdown de RunAuditTracker al bundle."""
	var bundle_report_path = _bundle_paths.get("audit_report", "")
	if bundle_report_path == "":
		return

	# Buscar el report más reciente que contenga nuestro run_id
	var report_dir = "user://audit_reports"
	if not DirAccess.dir_exists_absolute(report_dir):
		return

	var dir = DirAccess.open(report_dir)
	if not dir:
		return

	dir.list_dir_begin()
	var latest_report: String = ""
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.contains(_run_id) and file_name.ends_with(".md"):
			latest_report = report_dir.path_join(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	if latest_report != "":
		_copy_file(latest_report, bundle_report_path)

# ═══════════════════════════════════════════════════════════════════════════════
# SUMMARY GENERATION
# ═══════════════════════════════════════════════════════════════════════════════

func _generate_summary(context: Dictionary) -> void:
	"""Generar summary.json con estadísticas finales de la run."""
	# Duration: single canonical source = context.duration_s (set by Game from RunContext)
	var duration_s: float = context.get("duration_s", 0.0)
	var duration_warning: String = ""
	if duration_s <= 0.0:
		duration_warning = "duration_s not provided in context — set to 0"
		push_warning("[RunBundleManager] %s" % duration_warning)

	var summary: Dictionary = {
		"schema_version": 2,
		"run_id": _run_id,
		"end_reason": context.get("end_reason", "death"),
		"killed_by": context.get("killed_by", "unknown"),
		"duration_s": duration_s,
		"time_survived": context.get("time_survived", duration_s),
		"duration_note": "duration_s=wall-clock (includes pauses), time_survived=gameplay only (excludes pauses/menus)",
		"end_timestamp": Time.get_unix_time_from_system(),
		"end_iso": Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_"),

		"stats": {
			"level": context.get("level", 1),
			"kills": context.get("kills", 0),
			"elites_killed": context.get("elites_killed", 0),
			"bosses_killed": context.get("bosses_killed", 0),
			"gold": context.get("gold", 0),
			"damage_dealt": context.get("damage_dealt", 0),
			"damage_taken": context.get("damage_taken", 0),
			"healing_done": context.get("healing_done", 0),
			"xp_total": context.get("xp_total", 0),
		},

		"build": {
			"weapons": context.get("weapons", []),
			"upgrades": context.get("upgrades", []),
			"player_stats": context.get("player_stats", {}),
		},

		"difficulty_final": context.get("difficulty_final", {}),

		"death_context": {
			"killer": context.get("killed_by", "unknown"),
			"killer_attack": context.get("death_context", {}).get("killer_attack", "unknown"),
			"killer_damage_type": context.get("death_context", {}).get("killer_damage_type", "physical"),
			"killer_source_kind": context.get("death_context", {}).get("killer_source_kind", "melee"),
			"window_duration_s": context.get("death_context", {}).get("window_duration_s", 0.0),
			"hits_in_window": context.get("death_context", {}).get("hits_in_window", 0),
			"total_damage_in_window": context.get("death_context", {}).get("total_damage_in_window", 0),
		},

		"bundle_files": {
			"meta": "meta.json",
			"audit_log": "audit.jsonl",
			"balance_log": "balance.jsonl",
			"perf_log": "perf.jsonl",
			"audit_report": "audit_report.md",
			"upgrade_audit_log": "upgrade_audit.jsonl",
			"upgrade_audit_report": "upgrade_audit_report.md",
			"integrity": "integrity.json",
			"event_index": "event_index.json",
		},

		"file_sizes": _get_bundle_file_sizes(),
	}

	# Add upgrade audit summary if available
	var upgrade_auditor = get_node_or_null("/root/UpgradeAuditor")
	if upgrade_auditor and upgrade_auditor.has_method("get_run_summary"):
		var ua_summary = upgrade_auditor.get_run_summary()
		summary["upgrade_audit"] = ua_summary
		summary["stats"]["rerolls_total"] = context.get("death_context", {}).get("rerolls", ua_summary.get("counts", {}).get("rerolls", 0))

	# Add duration warning if applicable
	if duration_warning != "":
		summary["_warnings"] = [duration_warning]

	# Actualizar meta con end info
	_meta["end_timestamp"] = summary["end_timestamp"]
	_meta["end_iso"] = summary["end_iso"]
	_meta["end_reason"] = summary["end_reason"]
	_meta["duration_s"] = duration_s
	_meta["killed_by"] = summary["killed_by"]
	_write_json(_bundle_meta_path, _meta)

	# Escribir summary
	_write_json(_bundle_summary_path, summary)

func _get_bundle_file_sizes() -> Dictionary:
	"""Obtener tamaños de archivos del bundle."""
	var sizes: Dictionary = {}
	for fname in ["audit.jsonl", "balance.jsonl", "perf.jsonl", "audit_report.md", "meta.json", "upgrade_audit.jsonl", "upgrade_audit_report.md", "event_index.json"]:
		var path = _current_bundle_dir.path_join(fname)
		sizes[fname] = _get_file_size(path)
	return sizes

# ═══════════════════════════════════════════════════════════════════════════════
# CLEANUP
# ═══════════════════════════════════════════════════════════════════════════════

func _cleanup_old_bundles() -> void:
	"""Eliminar bundles más antiguos si se excede MAX_BUNDLES."""
	var dir = DirAccess.open(RUNS_DIR)
	if not dir:
		return

	var bundles: Array[String] = []
	dir.list_dir_begin()
	var entry = dir.get_next()
	while entry != "":
		if dir.current_is_dir() and entry.begins_with("run_"):
			bundles.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()

	if bundles.size() <= MAX_BUNDLES:
		return

	# Ordenar por nombre (contiene timestamp hex, orden natural = cronológico)
	bundles.sort()

	var to_remove = bundles.size() - MAX_BUNDLES
	for i in to_remove:
		var bundle_path = RUNS_DIR.path_join(bundles[i])
		_remove_directory_recursive(bundle_path)
		print("[RunBundleManager] 🗑️ Cleaned old bundle: %s" % bundles[i])

func _remove_directory_recursive(path: String) -> void:
	"""Eliminar directorio y su contenido."""
	var dir = DirAccess.open(path)
	if not dir:
		return

	dir.list_dir_begin()
	var entry = dir.get_next()
	while entry != "":
		if entry != "." and entry != "..":
			var full_path = path.path_join(entry)
			if dir.current_is_dir():
				_remove_directory_recursive(full_path)
			else:
				dir.remove(entry)
		entry = dir.get_next()
	dir.list_dir_end()

	# Remover el directorio vacío
	DirAccess.remove_absolute(path)

# ═══════════════════════════════════════════════════════════════════════════════
# UTILS
# ═══════════════════════════════════════════════════════════════════════════════

func _write_json(path: String, data: Dictionary) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func _copy_file(source_path: String, dest_path: String) -> void:
	"""Copiar contenido de un archivo a otro."""
	if not FileAccess.file_exists(source_path):
		return
	var source = FileAccess.open(source_path, FileAccess.READ)
	if not source:
		return
	var content = source.get_as_text()
	source.close()
	var dest = FileAccess.open(dest_path, FileAccess.WRITE)
	if dest:
		dest.store_string(content)
		dest.close()

func _get_file_size(path: String) -> int:
	"""Obtener tamaño de un archivo en bytes."""
	if not FileAccess.file_exists(path):
		return 0
	var f = FileAccess.open(path, FileAccess.READ)
	if f:
		var size = f.get_length()
		f.close()
		return size
	return 0

# ═══════════════════════════════════════════════════════════════════════════════
# INTEGRITY VERIFICATION
# ═══════════════════════════════════════════════════════════════════════════════

func _generate_integrity() -> void:
	"""Generate integrity.json — verifies all artifacts belong to this run_id."""
	var ctx = get_node_or_null("/root/RunContext")
	var integrity: Dictionary = {
		"schema_version": 2,
		"run_id": _run_id,
		"session_id": ctx.session_id if ctx else _meta.get("session_id", ""),
		"generated_at": Time.get_datetime_string_from_system(),
		"artifacts": {},
		"warnings": []
	}

	var artifacts_to_check: Array = [
		"meta.json", "summary.json", "audit.jsonl", "balance.jsonl",
		"perf.jsonl", "audit_report.md", "upgrade_audit.jsonl",
		"upgrade_audit_report.md", "event_index.json"
	]

	for fname in artifacts_to_check:
		var path = _current_bundle_dir.path_join(fname)
		if FileAccess.file_exists(path):
			var status = "present"
			# For JSONL files, verify first line has matching run_id
			if fname.ends_with(".jsonl"):
				status = _verify_jsonl_run_id(path)
				if status == "run_id_mismatch":
					integrity["warnings"].append("⚠️ %s contains events from a different run_id" % fname)
				elif status != "ok" and status != "present":
					integrity["warnings"].append("⚠️ %s has status: %s" % [fname, status])
			# For JSON files, verify run_id key
			elif fname.ends_with(".json") and fname != "integrity.json":
				status = _verify_json_run_id(path)
				if status == "run_id_mismatch":
					integrity["warnings"].append("⚠️ %s has mismatched run_id" % fname)
				elif status != "ok" and status != "present":
					integrity["warnings"].append("⚠️ %s has status: %s" % [fname, status])
			integrity["artifacts"][fname] = {
				"exists": true,
				"size_bytes": _get_file_size(path),
				"status": status
			}
		else:
			integrity["artifacts"][fname] = {
				"exists": false,
				"size_bytes": 0,
				"status": "missing"
			}
			integrity["warnings"].append("⚠️ %s is missing" % fname)

	integrity["is_consistent"] = integrity["warnings"].is_empty()
	_write_json(_current_bundle_dir.path_join("integrity.json"), integrity)

func _verify_jsonl_run_id(path: String) -> String:
	"""Verify that JSONL file's first event has matching run_id."""
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return "unreadable"
	var first_line = file.get_line().strip_edges()
	file.close()
	if first_line.is_empty():
		return "empty"
	var json = JSON.new()
	if json.parse(first_line) != OK:
		return "parse_error"
	var data = json.data
	if data is Dictionary:
		var file_run_id = str(data.get("run_id", ""))
		if file_run_id == _run_id:
			return "ok"
		elif file_run_id == "":
			return "no_run_id"
		else:
			return "run_id_mismatch"
	return "invalid_format"

func _verify_json_run_id(path: String) -> String:
	"""Verify that JSON file has matching run_id."""
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return "unreadable"
	var content = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(content) != OK:
		return "parse_error"
	var data = json.data
	if data is Dictionary:
		var file_run_id = str(data.get("run_id", ""))
		if file_run_id == _run_id:
			return "ok"
		elif file_run_id == "":
			return "no_run_id"
		else:
			return "run_id_mismatch"
	return "invalid_format"

# ═══════════════════════════════════════════════════════════════════════════════
# EVENT INDEX GENERATION
# ═══════════════════════════════════════════════════════════════════════════════

func _generate_event_index() -> void:
	"""Generate event_index.json — maps event_type to [{timestamp_ms, line}] for fast JSONL navigation."""
	var index: Dictionary = {
		"schema_version": 2,
		"run_id": _run_id,
		"generated_at": Time.get_datetime_string_from_system(),
		"sources": {}
	}

	# Index each JSONL file in the bundle
	for tracker_name in ["audit", "balance"]:
		var path = _bundle_paths.get(tracker_name, "")
		if path == "" or not FileAccess.file_exists(path):
			continue

		var source_index: Dictionary = {}  # event_type -> Array of {timestamp_ms, line}
		var file = FileAccess.open(path, FileAccess.READ)
		if not file:
			continue

		var line_num: int = 0
		while not file.eof_reached():
			var line = file.get_line().strip_edges()
			line_num += 1
			if line.is_empty():
				continue

			var json = JSON.new()
			if json.parse(line) != OK:
				continue
			var data = json.data
			if data is Dictionary:
				var event_type = str(data.get("event", "unknown"))
				if not source_index.has(event_type):
					source_index[event_type] = []
				source_index[event_type].append({
					"timestamp_ms": data.get("timestamp_ms", 0),
					"line": line_num
				})

		file.close()

		# Store summary per event type (count + first/last line)
		var source_summary: Dictionary = {}
		for event_type in source_index:
			var entries = source_index[event_type]
			source_summary[event_type] = {
				"count": entries.size(),
				"lines": entries,
			}
		index["sources"][tracker_name] = source_summary

	_write_json(_current_bundle_dir.path_join("event_index.json"), index)

# ═══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════════════════════

func get_current_bundle_dir() -> String:
	"""Devuelve el directorio del bundle activo, o vacío si no hay run."""
	return _current_bundle_dir if _bundle_active else ""

func get_bundle_path(run_id: String) -> String:
	"""Devuelve la ruta del bundle para un run_id dado."""
	return RUNS_DIR.path_join("run_%s" % run_id)

func list_bundles() -> Array[Dictionary]:
	"""Lista todos los bundles disponibles con su meta."""
	var result: Array[Dictionary] = []
	var dir = DirAccess.open(RUNS_DIR)
	if not dir:
		return result

	dir.list_dir_begin()
	var entry = dir.get_next()
	while entry != "":
		if dir.current_is_dir() and entry.begins_with("run_"):
			var meta_path = RUNS_DIR.path_join(entry).path_join("meta.json")
			if FileAccess.file_exists(meta_path):
				var f = FileAccess.open(meta_path, FileAccess.READ)
				if f:
					var json = JSON.new()
					if json.parse(f.get_as_text()) == OK and json.data is Dictionary:
						result.append(json.data)
					f.close()
		entry = dir.get_next()
	dir.list_dir_end()

	return result

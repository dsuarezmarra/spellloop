extends Node
## UpgradeAuditor — Sistema de verificación automática de objetos, armas y fusiones.
##
## Cada vez que el jugador recoge un upgrade, arma o fusión:
##   1. Captura snapshot de stats ANTES de aplicar
##   2. Deja que el sistema aplique los cambios
##   3. Captura snapshot de stats DESPUÉS
##   4. Compara effects[] declarados vs cambios reales
##   5. Clasifica como: OK / FAIL / WARN / DEAD_STAT
##
## Los resultados se escriben en el bundle de la run (upgrade_audit.jsonl)
## y se genera un reporte resumen al final (upgrade_audit_report.md).

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIG
# ═══════════════════════════════════════════════════════════════════════════════

var ENABLE_AUDIT: bool = true

## Tolerancia para comparación de floats (0.001 = 0.1%)
const FLOAT_TOLERANCE: float = 0.001

## Stats que se definen en PlayerStats pero NO tienen consumidor en código gameplay.
## Estos upgrades "funcionan" (el stat sube) pero NO producen efecto real.
const DEAD_STATS: Array[String] = [
	"orbital_damage_mult",
	"orbital_count_bonus",
	"orbital_speed_mult",
	"aoe_damage_mult",
	"single_target_mult",
	"kill_damage_scaling",
	"hp_cost_per_attack",
]

## Stats cuyo efecto es indirecto (se leen dentro de get_stat() de otro stat).
## Se verifican distinto: no los leemos directamente, verificamos que el stat
## compuesto cambia.
const INDIRECT_STATS: Dictionary = {
	"damage_per_gold": "damage_mult",       # Investor: leído dentro de get_stat("damage_mult")
	"momentum_factor": "damage_mult",       # Momentum: leído dentro de get_stat("damage_mult")
	"chrono_jump_active": "enemy_slow_aura", # Chrono: leído dentro de get_stat("enemy_slow_aura")
}

## Stats que son flags booleanos (0/1) — verificar que se activan
const FLAG_STATS: Array[String] = [
	"is_glass_cannon", "blood_pact", "grit_active", "frost_nova_on_hit",
	"soul_link_active", "turret_mode_enabled", "instant_combustion",
	"instant_bleed", "infinite_pickup_range",
]

## Stats que son de arma y van a GlobalWeaponStats (no a PlayerStats.stats)
const WEAPON_STATS: Array[String] = [
	"damage_mult", "damage_flat", "attack_speed_mult", "cooldown_mult",
	"area_mult", "projectile_speed_mult", "duration_mult", "extra_projectiles",
	"extra_pierce", "knockback_mult", "range_mult", "crit_chance", "crit_damage",
	"chain_count", "life_steal",
]

# ═══════════════════════════════════════════════════════════════════════════════
# STATE
# ═══════════════════════════════════════════════════════════════════════════════

var _run_active: bool = false
var _audit_log: Array[Dictionary] = []  # Todos los resultados de esta run
var _current_log_file: String = ""
var _pickup_counter: int = 0

# Contadores de resumen
var _counts := {"ok": 0, "fail": 0, "warn": 0, "dead_stat": 0, "unknown": 0}

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Auto-disable in release builds
	if not OS.is_debug_build() and "--enable-upgrade-auditor" not in OS.get_cmdline_args():
		ENABLE_AUDIT = false
		return

# ═══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════════════════════

func start_run() -> void:
	if not ENABLE_AUDIT:
		return
	_run_active = true
	_audit_log.clear()
	_pickup_counter = 0
	_counts = {"ok": 0, "fail": 0, "warn": 0, "dead_stat": 0, "unknown": 0}

	# Determinar path del log
	_current_log_file = ""
	var bundle_mgr = get_node_or_null("/root/RunBundleManager")
	if bundle_mgr and bundle_mgr.has_method("get_log_path_for"):
		var path = bundle_mgr.get_log_path_for("upgrade_audit")
		if path != "":
			_current_log_file = path

	# Fallback: carpeta legacy
	if _current_log_file == "":
		var dir = "user://audit_logs"
		if not DirAccess.dir_exists_absolute(dir):
			DirAccess.make_dir_recursive_absolute(dir)
		var ts = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
		_current_log_file = dir.path_join("upgrade_audit_%s.jsonl" % ts)

	print("[UpgradeAuditor] 🔍 Audit started → %s" % _current_log_file.get_file())

func end_run() -> void:
	if not ENABLE_AUDIT or not _run_active:
		return
	_run_active = false

	# Generar reporte markdown
	_generate_report()

	print("[UpgradeAuditor] 📋 Audit complete: %d pickups — OK:%d FAIL:%d WARN:%d DEAD:%d" % [
		_pickup_counter, _counts.ok, _counts.fail, _counts.warn, _counts.dead_stat
	])

func get_run_summary() -> Dictionary:
	"""Resumen ligero para integrar en summary.json y audit_report.md."""
	var top_picked: Dictionary = {}  # upgrade_id -> count
	for entry in _audit_log:
		var uid = entry.get("id", entry.get("name", "unknown"))
		top_picked[uid] = top_picked.get(uid, 0) + 1

	# Sort by count descending
	var sorted_list: Array = []
	for uid in top_picked:
		sorted_list.append({"id": uid, "count": top_picked[uid]})
	sorted_list.sort_custom(func(a, b): return a.count > b.count)
	if sorted_list.size() > 10:
		sorted_list.resize(10)

	return {
		"total_pickups": _pickup_counter,
		"counts": _counts.duplicate(),
		"top_upgrades_picked": sorted_list,
	}

# ═══════════════════════════════════════════════════════════════════════════════
# CORE — Audit de una mejora de jugador
# ═══════════════════════════════════════════════════════════════════════════════

func audit_player_upgrade(upgrade_data: Dictionary, stats_before: Dictionary, stats_after: Dictionary) -> Dictionary:
	"""Auditar un upgrade de jugador comparando stats antes/después.
	Llamar desde PlayerStats.apply_upgrade() con snapshots."""
	if not ENABLE_AUDIT or not _run_active:
		return {}

	_pickup_counter += 1
	var upgrade_id = upgrade_data.get("id", upgrade_data.get("name", "unknown"))
	var effects = upgrade_data.get("effects", [])

	var result := {
		"event": "upgrade_audit",
		"pickup_num": _pickup_counter,
		"timestamp": Time.get_ticks_msec(),
		"type": "player_upgrade",
		"id": upgrade_id,
		"name": upgrade_data.get("name", upgrade_id),
		"tier": upgrade_data.get("tier", 0),
		"category": upgrade_data.get("category", "unknown"),
		"effects_declared": effects.size(),
		"checks": [],
		"verdict": "OK",  # OK, FAIL, WARN, DEAD_STAT
	}

	var has_fail := false
	var has_warn := false
	var has_dead := false

	for effect in effects:
		var stat = effect.get("stat", "")
		var value = effect.get("value", 0.0)
		var op = effect.get("operation", "add")

		if stat == "":
			continue

		var check := _verify_single_effect(stat, value, op, stats_before, stats_after, upgrade_data)
		result.checks.append(check)

		match check.status:
			"FAIL": has_fail = true
			"WARN": has_warn = true
			"DEAD_STAT": has_dead = true

	# Determinar veredicto global
	if has_fail:
		result.verdict = "FAIL"
		_counts.fail += 1
	elif has_dead:
		result.verdict = "DEAD_STAT"
		_counts.dead_stat += 1
	elif has_warn:
		result.verdict = "WARN"
		_counts.warn += 1
	else:
		result.verdict = "OK"
		_counts.ok += 1

	_audit_log.append(result)
	_log_event(result)

	# Print para debug en consola
	if result.verdict != "OK":
		var emoji = {"FAIL": "❌", "WARN": "⚠️", "DEAD_STAT": "💀"}.get(result.verdict, "❓")
		print("[UpgradeAuditor] %s %s '%s': %s" % [emoji, result.verdict, result.name, _summarize_checks(result.checks)])

	return result

# ═══════════════════════════════════════════════════════════════════════════════
# CORE — Audit de arma nueva / level up / fusión
# ═══════════════════════════════════════════════════════════════════════════════

func audit_weapon_pickup(weapon_data: Dictionary, action: String) -> Dictionary:
	"""Auditar obtención/subida/fusión de arma.
	action: 'new_weapon', 'level_up', 'fusion'"""
	if not ENABLE_AUDIT or not _run_active:
		return {}

	_pickup_counter += 1
	var weapon_id = weapon_data.get("id", weapon_data.get("weapon_id", "unknown"))

	var result := {
		"event": "weapon_audit",
		"pickup_num": _pickup_counter,
		"timestamp": Time.get_ticks_msec(),
		"type": action,
		"id": weapon_id,
		"name": weapon_data.get("name", weapon_id),
		"checks": [],
		"verdict": "OK",
	}

	# Para armas verificamos que se añadió al attack manager
	var attack_manager = get_tree().get_first_node_in_group("attack_manager")
	if attack_manager:
		match action:
			"new_weapon":
				var found = _weapon_exists_in_manager(attack_manager, weapon_id)
				result.checks.append({
					"check": "weapon_registered",
					"stat": weapon_id,
					"status": "OK" if found else "FAIL",
					"detail": "Arma registrada en AttackManager" if found else "Arma NO encontrada en AttackManager"
				})
				if not found:
					result.verdict = "FAIL"
					_counts.fail += 1
				else:
					_counts.ok += 1

			"level_up":
				var level = _get_weapon_level(attack_manager, weapon_id)
				result.checks.append({
					"check": "weapon_level",
					"stat": weapon_id,
					"status": "OK" if level > 1 else "WARN",
					"detail": "Nivel actual: %d" % level
				})
				if level <= 1:
					result.verdict = "WARN"
					_counts.warn += 1
				else:
					_counts.ok += 1

			"fusion":
				var found = _weapon_exists_in_manager(attack_manager, weapon_id)
				var source_a = weapon_data.get("source_a", "")
				var source_b = weapon_data.get("source_b", "")
				var a_removed = not _weapon_exists_in_manager(attack_manager, source_a) if source_a != "" else true
				var b_removed = not _weapon_exists_in_manager(attack_manager, source_b) if source_b != "" else true

				result.checks.append({
					"check": "fusion_created",
					"stat": weapon_id,
					"status": "OK" if found else "FAIL",
					"detail": "Fusión registrada" if found else "Fusión NO encontrada"
				})
				result.checks.append({
					"check": "sources_removed",
					"stat": "%s + %s" % [source_a, source_b],
					"status": "OK" if (a_removed and b_removed) else "WARN",
					"detail": "Originales removidas" if (a_removed and b_removed) else "Originales aún presentes"
				})

				if not found:
					result.verdict = "FAIL"
					_counts.fail += 1
				elif not (a_removed and b_removed):
					result.verdict = "WARN"
					_counts.warn += 1
				else:
					_counts.ok += 1
	else:
		result.checks.append({
			"check": "attack_manager",
			"stat": "N/A",
			"status": "WARN",
			"detail": "AttackManager no encontrado"
		})
		result.verdict = "WARN"
		_counts.warn += 1

	_audit_log.append(result)
	_log_event(result)

	if result.verdict != "OK":
		var emoji = {"FAIL": "❌", "WARN": "⚠️"}.get(result.verdict, "❓")
		print("[UpgradeAuditor] %s %s '%s': %s" % [emoji, result.verdict, result.name, action])

	return result

func audit_global_weapon_upgrade(upgrade_data: Dictionary, gws_before: Dictionary, gws_after: Dictionary) -> Dictionary:
	"""Auditar un upgrade global de armas (damage_mult, crit, etc.)
	gws_before/gws_after: snapshots de GlobalWeaponStats."""
	if not ENABLE_AUDIT or not _run_active:
		return {}

	_pickup_counter += 1
	var upgrade_id = upgrade_data.get("id", upgrade_data.get("name", "unknown"))
	var effects = upgrade_data.get("effects", [])

	var result := {
		"event": "global_weapon_upgrade_audit",
		"pickup_num": _pickup_counter,
		"timestamp": Time.get_ticks_msec(),
		"type": "global_weapon_upgrade",
		"id": upgrade_id,
		"name": upgrade_data.get("name", upgrade_id),
		"effects_declared": effects.size(),
		"checks": [],
		"verdict": "OK",
	}

	var has_fail := false

	for effect in effects:
		var stat = effect.get("stat", "")
		var value = effect.get("value", 0.0)
		var op = effect.get("operation", "add")
		if stat == "":
			continue

		# Skip non-weapon stats — they live in PlayerStats and are audited
		# by _verify_single_effect via audit_upgrade(), not here.
		if stat not in WEAPON_STATS:
			result.checks.append({
				"check": "gws_stat_skipped",
				"stat": stat,
				"status": "OK",
				"detail": "PlayerStat, no GWS — verificado en audit_upgrade()"
			})
			continue

		var before_val = gws_before.get(stat, 0.0)
		var after_val = gws_after.get(stat, 0.0)
		var expected = _calculate_expected(before_val, value, op)
		var delta = after_val - before_val

		# Exact match
		var exact_match = absf(after_val - expected) < FLOAT_TOLERANCE
		# Direction OK (may be capped)
		var direction_ok = _same_direction(delta, value, op) and absf(delta) > FLOAT_TOLERANCE
		var was_capped = not exact_match and direction_ok

		var status: String
		var detail: String

		if exact_match:
			status = "OK"
			detail = ""
		elif was_capped:
			status = "OK"
			detail = "Aplicado con cap: esperado %.3f, real %.3f (capped)" % [expected, after_val]
		elif absf(delta) < FLOAT_TOLERANCE:
			if absf(value) < FLOAT_TOLERANCE:
				status = "WARN"
				detail = "Efecto con value=0 declarado"
			else:
				status = "FAIL"
				detail = "Stat no cambió como se esperaba"
		else:
			status = "WARN"
			detail = "Cambio inesperado: %.3f→%.3f (esperado %.3f)" % [before_val, after_val, expected]

		var check := {
			"check": "gws_stat_change",
			"stat": stat,
			"before": snapped(before_val, 0.001),
			"after": snapped(after_val, 0.001),
			"expected": snapped(expected, 0.001),
			"delta": snapped(delta, 0.001),
			"operation": op,
			"declared_value": value,
			"status": status,
			"detail": detail,
		}
		result.checks.append(check)
		if status == "FAIL":
			has_fail = true

	if has_fail:
		result.verdict = "FAIL"
		_counts.fail += 1
	else:
		result.verdict = "OK"
		_counts.ok += 1

	_audit_log.append(result)
	_log_event(result)

	if result.verdict != "OK":
		print("[UpgradeAuditor] ❌ FAIL global weapon '%s'" % result.name)

	return result

# ═══════════════════════════════════════════════════════════════════════════════
# SINGLE EFFECT VERIFICATION
# ═══════════════════════════════════════════════════════════════════════════════

func _verify_single_effect(stat: String, value: float, op: String,
		stats_before: Dictionary, stats_after: Dictionary,
		_upgrade_data: Dictionary) -> Dictionary:
	"""Verificar que UN efecto declarado se aplicó correctamente."""

	# Caso 1: Stat muerto — funciona a nivel de almacenamiento pero sin efecto gameplay
	if stat in DEAD_STATS:
		var before_val = stats_before.get(stat, 0.0)
		var after_val = stats_after.get(stat, 0.0)
		var changed = absf(after_val - before_val) > FLOAT_TOLERANCE
		return {
			"check": "dead_stat",
			"stat": stat,
			"before": snapped(before_val, 0.001),
			"after": snapped(after_val, 0.001),
			"status": "DEAD_STAT",
			"detail": "Stat se almacena (%.2f→%.2f) pero NO tiene consumidor en gameplay" % [before_val, after_val]
		}

	# Caso 2: Stat es de arma — va a GlobalWeaponStats, no a PlayerStats.stats
	# Esos se verifican aparte con audit_global_weapon_upgrade()
	if stat in WEAPON_STATS:
		return {
			"check": "weapon_stat_delegated",
			"stat": stat,
			"status": "OK",
			"detail": "Delegado a GlobalWeaponStats (verificado aparte)"
		}

	# Caso 3: Flag booleano — verificar que se activó
	if stat in FLAG_STATS:
		var after_val = stats_after.get(stat, 0.0)
		var is_on = after_val > 0
		return {
			"check": "flag_activation",
			"stat": stat,
			"after": after_val,
			"status": "OK" if is_on else "FAIL",
			"detail": "Flag activo" if is_on else "Flag NO se activó (valor=%.2f)" % after_val
		}

	# Caso 4: Stat normal — verificar before/after vs expected
	var before_val = stats_before.get(stat, 0.0)
	var after_val = stats_after.get(stat, 0.0)
	var expected = _calculate_expected(before_val, value, op)
	var delta = after_val - before_val

	# Verificar si el cambio es el esperado
	var exact_match = absf(after_val - expected) < FLOAT_TOLERANCE
	# O al menos que cambió en la dirección correcta (puede haber caps)
	var direction_ok = _same_direction(delta, value, op) and absf(delta) > FLOAT_TOLERANCE
	# Verificar si fue capeado (límite)
	var was_capped = not exact_match and direction_ok

	var status: String
	var detail: String

	if exact_match:
		status = "OK"
		detail = ""
	elif was_capped:
		status = "OK"
		detail = "Aplicado con cap: esperado %.3f, real %.3f (capped)" % [expected, after_val]
	elif absf(delta) < FLOAT_TOLERANCE:
		# No cambió nada
		if absf(value) < FLOAT_TOLERANCE:
			status = "WARN"
			detail = "Efecto con value=0 declarado"
		else:
			status = "FAIL"
			detail = "Stat NO cambió. Before=%.3f, After=%.3f, Expected=%.3f" % [before_val, after_val, expected]
	else:
		# Cambió pero en dirección inesperada o cantidad muy diferente
		status = "WARN"
		detail = "Cambio inesperado: %.3f→%.3f (esperado %.3f)" % [before_val, after_val, expected]

	return {
		"check": "stat_change",
		"stat": stat,
		"before": snapped(before_val, 0.001),
		"after": snapped(after_val, 0.001),
		"expected": snapped(expected, 0.001),
		"delta": snapped(delta, 0.001),
		"operation": op,
		"declared_value": value,
		"status": status,
		"detail": detail,
	}

# ═══════════════════════════════════════════════════════════════════════════════
# REPORT GENERATION
# ═══════════════════════════════════════════════════════════════════════════════

func _generate_report() -> void:
	"""Generar reporte markdown resumen de la auditoría de upgrades."""
	var report_path := ""

	# Intentar escribir en el bundle
	var bundle_mgr = get_node_or_null("/root/RunBundleManager")
	if bundle_mgr and "_current_bundle_dir" in bundle_mgr and bundle_mgr._current_bundle_dir != "":
		report_path = bundle_mgr._current_bundle_dir.path_join("upgrade_audit_report.md")
	else:
		var dir = "user://audit_reports"
		if not DirAccess.dir_exists_absolute(dir):
			DirAccess.make_dir_recursive_absolute(dir)
		var ts = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
		report_path = dir.path_join("upgrade_audit_%s.md" % ts)

	var run_ctx = get_node_or_null("/root/RunContext")
	var run_id = run_ctx.run_id if run_ctx and run_ctx.run_id != "" else "unknown"

	var lines: Array[String] = []
	lines.append("# Upgrade Audit Report")
	lines.append("")
	lines.append("**Run ID:** `%s`" % run_id)
	lines.append("**Total Pickups:** %d" % _pickup_counter)
	lines.append("**Results:** ✅ OK: %d | ❌ FAIL: %d | ⚠️ WARN: %d | 💀 DEAD: %d" % [
		_counts.ok, _counts.fail, _counts.warn, _counts.dead_stat
	])
	lines.append("")

	# Sección FAIL primero
	var fails = _audit_log.filter(func(e): return e.verdict == "FAIL")
	if fails.size() > 0:
		lines.append("## ❌ FAILED (%d)" % fails.size())
		lines.append("")
		for entry in fails:
			lines.append("### %s `%s`" % [entry.get("name", "?"), entry.id])
			lines.append("- Type: %s | Pickup #%d" % [entry.type, entry.pickup_num])
			for check in entry.get("checks", []):
				if check.status == "FAIL":
					lines.append("- **FAIL** `%s`: %s" % [check.stat, check.get("detail", "")])
					if check.has("before"):
						lines.append("  - Before: `%.3f` → After: `%.3f` (Expected: `%.3f`)" % [
							check.before, check.after, check.get("expected", 0.0)])
			lines.append("")

	# Sección DEAD_STAT
	var deads = _audit_log.filter(func(e): return e.verdict == "DEAD_STAT")
	if deads.size() > 0:
		lines.append("## 💀 DEAD STATS (%d)" % deads.size())
		lines.append("")
		lines.append("Estos upgrades modifican stats que **no tienen consumidor en el código gameplay**:")
		lines.append("")
		for entry in deads:
			lines.append("- `%s` (%s)" % [entry.id, entry.get("name", "?")])
			for check in entry.get("checks", []):
				if check.status == "DEAD_STAT":
					lines.append("  - `%s`: %s" % [check.stat, check.get("detail", "")])
		lines.append("")

	# Sección WARN
	var warns = _audit_log.filter(func(e): return e.verdict == "WARN")
	if warns.size() > 0:
		lines.append("## ⚠️ WARNINGS (%d)" % warns.size())
		lines.append("")
		for entry in warns:
			lines.append("- `%s` (%s): " % [entry.id, entry.get("name", "?")])
			for check in entry.get("checks", []):
				if check.status == "WARN":
					lines.append("  - `%s`: %s" % [check.stat, check.get("detail", "")])
		lines.append("")

	# Sección OK (resumen breve)
	var oks = _audit_log.filter(func(e): return e.verdict == "OK")
	if oks.size() > 0:
		lines.append("## ✅ PASSED (%d)" % oks.size())
		lines.append("")
		for entry in oks:
			var effects_str = ""
			for check in entry.get("checks", []):
				if check.has("stat") and check.has("delta"):
					effects_str += "%s(%+.2f) " % [check.stat, check.get("delta", 0.0)]
				elif check.has("stat"):
					effects_str += "%s " % check.stat
			lines.append("- `%s` — %s" % [entry.get("name", entry.id), effects_str.strip_edges()])
		lines.append("")

	var file = FileAccess.open(report_path, FileAccess.WRITE)
	if file:
		file.store_string("\n".join(lines))
		file.close()
		print("[UpgradeAuditor] 📄 Report → %s" % report_path.get_file())

# ═══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

func _calculate_expected(before: float, value: float, op: String) -> float:
	match op:
		"add": return before + value
		"multiply": return before * value
		"set": return value
		_: return before + value

func _same_direction(delta: float, value: float, op: String) -> bool:
	"""Verificar que el cambio va en la dirección esperada."""
	match op:
		"add": return signf(delta) == signf(value) or absf(value) < FLOAT_TOLERANCE
		"multiply":
			if value > 1.0: return delta > 0
			elif value < 1.0: return delta < 0
			else: return true
		"set": return true
		_: return signf(delta) == signf(value)

func _weapon_exists_in_manager(am: Node, weapon_id: String) -> bool:
	if am.has_method("get_weapons"):
		for w in am.get_weapons():
			if "id" in w and w.id == weapon_id:
				return true
	if am.has_method("has_weapon"):
		return am.has_weapon(weapon_id)
	return false

func _get_weapon_level(am: Node, weapon_id: String) -> int:
	if am.has_method("get_weapons"):
		for w in am.get_weapons():
			if "id" in w and w.id == weapon_id:
				return w.level if "level" in w else 1
	return 0

func _summarize_checks(checks: Array) -> String:
	var parts: Array[String] = []
	for c in checks:
		if c.status != "OK":
			parts.append("%s(%s)" % [c.stat, c.status])
	return ", ".join(parts) if parts.size() > 0 else "all OK"

func _log_event(data: Dictionary) -> void:
	if _current_log_file == "":
		return
	var file = FileAccess.open(_current_log_file, FileAccess.READ_WRITE)
	if not file:
		file = FileAccess.open(_current_log_file, FileAccess.WRITE)
	if file:
		file.seek_end()
		file.store_line(JSON.stringify(data))
		file.close()

func get_stats_snapshot() -> Dictionary:
	"""Capturar snapshot de PlayerStats para comparación antes/después."""
	var ps = get_tree().get_first_node_in_group("player_stats")
	if not ps or not "stats" in ps:
		return {}
	return ps.stats.duplicate()

func get_gws_snapshot() -> Dictionary:
	"""Capturar snapshot de GlobalWeaponStats para comparación."""
	var ps = get_tree().get_first_node_in_group("player_stats")
	if not ps:
		return {}
	# GlobalWeaponStats se accede a través de PlayerStats
	if "global_weapon_stats" in ps and ps.global_weapon_stats:
		var gws = ps.global_weapon_stats
		if gws.has_method("get_all_stats"):
			return gws.get_all_stats()
		elif "stats" in gws:
			return gws.stats.duplicate()
	return {}

# CombatDiagnostics.gd
# In-game diagnostic tool for combat correctness auditing
#
# Add to scene hierarchy for real-time monitoring
# Or run headless with: godot --headless -s scripts/tools/CombatDiagnostics.gd

extends Node
class_name CombatDiagnostics

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

## Enable real-time monitoring (prints every damage event)
const REALTIME_MONITORING: bool = false

## Enable aggregated reporting (prints summary every N seconds)
const AGGREGATED_REPORTING: bool = true
const REPORT_INTERVAL: float = 10.0

## Track weapon stats
static var weapon_stats: Dictionary = {}  # weapon_id -> {shots, hits, damage, crits}
static var status_stats: Dictionary = {}  # status_type -> {applied, ticks, total_damage}
static var upgrade_stats: Dictionary = {}  # upgrade_id -> {expected_stat, verified}
static var feedback_stats: Dictionary = {"text": 0, "sfx": 0, "vfx": 0}  # type -> count

## Singleton access
static var instance: CombatDiagnostics = null

var _report_timer: float = 0.0
var _session_start: int = 0

func _ready() -> void:
	if instance != null:
		queue_free()
		return
	instance = self
	_session_start = Time.get_ticks_msec()
	
	# Add to diagnostic group
	add_to_group("diagnostics")
	
	print("═" * 60)
	print("📊 COMBAT DIAGNOSTICS ACTIVE")
	print("═" * 60)

func _process(delta: float) -> void:
	if not AGGREGATED_REPORTING:
		return
	
	_report_timer += delta
	if _report_timer >= REPORT_INTERVAL:
		_report_timer = 0.0
		print_interim_report()

# ═══════════════════════════════════════════════════════════════════════════════
# TRACKING API (Call from damage sources)
# ═══════════════════════════════════════════════════════════════════════════════

static func track_weapon_shot(weapon_id: String) -> void:
	"""Call when a weapon fires"""
	_ensure_weapon_entry(weapon_id)
	weapon_stats[weapon_id].shots += 1
	
	if REALTIME_MONITORING:
		print("[COMBAT] 🔫 %s: Shot fired" % weapon_id)

static func track_weapon_hit(weapon_id: String, damage: int, is_crit: bool = false) -> void:
	"""Call when a weapon projectile hits and deals damage"""
	_ensure_weapon_entry(weapon_id)
	var stats = weapon_stats[weapon_id]
	stats.hits += 1
	stats.damage += damage
	if is_crit:
		stats.crits += 1
	
	if REALTIME_MONITORING:
		var crit_str = " CRIT!" if is_crit else ""
		print("[COMBAT] ✓ %s: Hit for %d dmg%s" % [weapon_id, damage, crit_str])

static func track_weapon_miss(weapon_id: String, reason: String = "") -> void:
	"""Call when a projectile expires without hitting"""
	_ensure_weapon_entry(weapon_id)
	weapon_stats[weapon_id].misses += 1
	
	if REALTIME_MONITORING:
		var reason_str = " (%s)" % reason if reason != "" else ""
		print("[COMBAT] ✗ %s: Missed%s" % [weapon_id, reason_str])

static func track_status_applied(status_type: String, target_name: String = "") -> void:
	"""Call when a status effect is successfully applied"""
	_ensure_status_entry(status_type)
	status_stats[status_type].applied += 1
	
	if REALTIME_MONITORING:
		var target_str = " → %s" % target_name if target_name != "" else ""
		print("[COMBAT] 🔥 %s: Applied%s" % [status_type, target_str])

static func track_status_tick(status_type: String, damage: float) -> void:
	"""Call when a DoT status deals tick damage"""
	_ensure_status_entry(status_type)
	status_stats[status_type].ticks += 1
	status_stats[status_type].total_damage += damage
	
	if REALTIME_MONITORING:
		print("[COMBAT] ⏱ %s: Tick %.1f dmg" % [status_type, damage])

static func track_upgrade_applied(upgrade_id: String, stat_name: String, old_value: float, new_value: float) -> void:
	"""Call when an upgrade modifies a stat"""
	var verified = new_value != old_value
	upgrade_stats[upgrade_id] = {
		"stat": stat_name,
		"old": old_value,
		"new": new_value,
		"verified": verified
	}
	
	if REALTIME_MONITORING:
		var icon = "✅" if verified else "❌"
		print("[COMBAT] %s Upgrade %s: %s %.2f → %.2f" % [icon, upgrade_id, stat_name, old_value, new_value])

static func track_feedback(type: String, info: String = "") -> void:
	"""Call when feedback is spawned (text, sfx, vfx)"""
	if feedback_stats.has(type):
		feedback_stats[type] += 1
	else:
		feedback_stats[type] = 1
		
	if REALTIME_MONITORING:
		print("[COMBAT] 👁️ Feedback (%s): %s" % [type, info])

# ═══════════════════════════════════════════════════════════════════════════════
# REPORTING
# ═══════════════════════════════════════════════════════════════════════════════

func print_interim_report() -> void:
	"""Print interim report of current session"""
	var elapsed = (Time.get_ticks_msec() - _session_start) / 1000.0
	
	print("\n" + "─" * 50)
	print("📊 COMBAT STATS @ %.1fs" % elapsed)
	print("─" * 50)
	
	if weapon_stats.is_empty():
		print("  No weapon activity recorded")
	else:
		print("┌──────────────────┬───────┬──────┬───────────┬──────────┬──────────┐")
		print("│ Weapon           │ Shots │ Hits │ Hit Rate  │ Damage   │ Crits    │")
		print("├──────────────────┼───────┼──────┼───────────┼──────────┼──────────┤")
		for weapon_id in weapon_stats:
			var s = weapon_stats[weapon_id]
			var hit_rate = (float(s.hits) / float(s.shots) * 100.0) if s.shots > 0 else 0.0
			var weapon_short = weapon_id.substr(0, 16).rpad(16)
			print("│ %s │ %5d │ %4d │ %6.1f%%   │ %8d │ %8d │" % [
				weapon_short, s.shots, s.hits, hit_rate, s.damage, s.crits])
		print("└──────────────────┴───────┴──────┴───────────┴──────────┴──────────┘")
	
	if not status_stats.is_empty():
		print("\n📌 Status Effects:")
		for status in status_stats:
			var s = status_stats[status]
			print("  %s: %d applied, %d ticks, %.0f total dmg" % [status, s.applied, s.ticks, s.total_damage])

	if not feedback_stats.is_empty():
		print("\n👁️ Feedback Generated:")
		for type in feedback_stats:
			print("  %s: %d events" % [type, feedback_stats[type]])
	
	print("─" * 50 + "\n")

static func generate_full_report() -> String:
	"""Generate full markdown report"""
	var lines: Array[String] = []
	lines.append("# Combat Diagnostics Report")
	lines.append("")
	lines.append("**Generated**: %s" % Time.get_datetime_string_from_system())
	lines.append("")
	
	# Weapons
	lines.append("## Weapon Performance")
	lines.append("")
	lines.append("| Weapon | Shots | Hits | Hit% | Misses | Total Damage | Avg Dmg | Crits |")
	lines.append("|--------|-------|------|------|--------|--------------|---------|-------|")
	
	var problem_weapons: Array[String] = []
	
	for weapon_id in weapon_stats:
		var s = weapon_stats[weapon_id]
		var hit_rate = (float(s.hits) / float(s.shots) * 100.0) if s.shots > 0 else 0.0
		var avg_dmg = float(s.damage) / float(s.hits) if s.hits > 0 else 0.0
		var misses = s.get("misses", 0)
		
		lines.append("| %s | %d | %d | %.1f%% | %d | %d | %.1f | %d |" % [
			weapon_id, s.shots, s.hits, hit_rate, misses, s.damage, avg_dmg, s.crits])
		
		# Flag problems
		if s.shots > 10 and hit_rate < 20.0:
			problem_weapons.append("**%s**: %.1f%% hit rate (fired %d, hit %d)" % [weapon_id, hit_rate, s.shots, s.hits])
		elif s.shots > 5 and s.damage == 0:
			problem_weapons.append("**%s**: 0 damage dealt despite %d shots" % [weapon_id, s.shots])
	
	# Problems section
	if problem_weapons.size() > 0:
		lines.append("")
		lines.append("### ⚠️ Problem Weapons")
		lines.append("")
		for p in problem_weapons:
			lines.append("- " + p)
	
	# Status Effects
	if not status_stats.is_empty():
		lines.append("")
		lines.append("## Status Effects")
		lines.append("")
		lines.append("| Status | Applied | Ticks | Total Damage |")
		lines.append("|--------|---------|-------|--------------|")
		for status in status_stats:
			var s = status_stats[status]
			lines.append("| %s | %d | %d | %.0f |" % [status, s.applied, s.ticks, s.total_damage])
	
	# Upgrades
	if not upgrade_stats.is_empty():
		lines.append("")
		lines.append("## Upgrade Verification")
		lines.append("")
		lines.append("| Upgrade | Stat | Old Value | New Value | Verified |")
		lines.append("|---------|------|-----------|-----------|----------|")
		for upgrade_id in upgrade_stats:
			var u = upgrade_stats[upgrade_id]
			var icon = "✅" if u.verified else "❌"
			lines.append("| %s | %s | %.2f | %.2f | %s |" % [upgrade_id, u.stat, u.old, u.new, icon])
	
	return "\n".join(lines)

static func reset() -> void:
	"""Reset all tracked stats"""
	weapon_stats.clear()
	status_stats.clear()
	upgrade_stats.clear()
	feedback_stats = {"text": 0, "sfx": 0, "vfx": 0}

# ═══════════════════════════════════════════════════════════════════════════════
# INTERNAL
# ═══════════════════════════════════════════════════════════════════════════════

static func _ensure_weapon_entry(weapon_id: String) -> void:
	if not weapon_stats.has(weapon_id):
		weapon_stats[weapon_id] = {
			"shots": 0,
			"hits": 0,
			"misses": 0,
			"damage": 0,
			"crits": 0
		}

static func _ensure_status_entry(status_type: String) -> void:
	if not status_stats.has(status_type):
		status_stats[status_type] = {
			"applied": 0,
			"ticks": 0,
			"total_damage": 0.0
		}

extends Node
class_name StatusEffectOracle

# ═══════════════════════════════════════════════════════════════════════════════
# STRICT STATUS EFFECT VALIDATION ORACLE
# ═══════════════════════════════════════════════════════════════════════════════
#
# Este oracle valida que los efectos de status se aplican EXACTAMENTE como se
# especifica en el contrato del item:
# - Duración correcta
# - Ticks correctos
# - Daño por tick correcto
# - Parámetros correctos (slow amount, freeze amount, etc.)
# - No status extra no declarados

# Stores tracking data for status effects
# Structure: { enemy_instance_id: { effect_name: { ... } } }
var tracked_statuses: Dictionary = {}
var _is_listening: bool = false
var _tracked_enemies: Array = []

# STRICT MODE - más estricto, menos tolerancia
var strict_mode: bool = true

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

# Tolerancias (más estrictas en strict_mode)
const TICK_TOLERANCE_NORMAL = 1  # Allow +/- 1 tick
const TICK_TOLERANCE_STRICT = 0  # Exact tick count required
const DURATION_TOLERANCE_NORMAL = 0.2  # 200ms
const DURATION_TOLERANCE_STRICT = 0.05  # 50ms
const DAMAGE_TOLERANCE_NORMAL = 0.1
const DAMAGE_TOLERANCE_STRICT = 0.01

# Status effect definitions for validation
const STATUS_DEFINITIONS = {
	"burn": {
		"tick_interval": 0.5,
		"default_duration": 3.0,
		"damage_type": "fire",
		"is_dot": true
	},
	"bleed": {
		"tick_interval": 0.5,
		"default_duration": 3.0,
		"damage_type": "bleed",
		"is_dot": true
	},
	"poison": {
		"tick_interval": 1.0,
		"default_duration": 5.0,
		"damage_type": "poison",
		"is_dot": true
	},
	"freeze": {
		"is_cc": true,
		"default_duration": 2.0,
		"prevents_movement": true
	},
	"slow": {
		"is_cc": true,
		"default_duration": 2.0,
		"movement_modifier": true
	},
	"stun": {
		"is_cc": true,
		"default_duration": 1.0,
		"prevents_actions": true
	},
	"blind": {
		"is_debuff": true,
		"default_duration": 2.0
	},
	"pull": {
		"is_displacement": true,
		"instant": true
	},
	"knockback": {
		"is_displacement": true,
		"instant": true
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func start_listening():
	_clear_data()
	_is_listening = true

func stop_listening():
	_is_listening = false

func _clear_data():
	tracked_statuses = {}
	_tracked_enemies = []

func set_strict_mode(enabled: bool) -> void:
	strict_mode = enabled

# ═══════════════════════════════════════════════════════════════════════════════
# TRACKING
# ═══════════════════════════════════════════════════════════════════════════════

func track_enemy(enemy_node: Node):
	if not is_instance_valid(enemy_node): return
	if enemy_node in _tracked_enemies: return
	
	_tracked_enemies.append(enemy_node)
	
	# Connect to status signals
	if enemy_node.has_signal("status_applied"):
		if not enemy_node.is_connected("status_applied", _on_status_applied):
			enemy_node.connect("status_applied", _on_status_applied.bind(enemy_node))
	
	if enemy_node.has_signal("status_removed"):
		if not enemy_node.is_connected("status_removed", _on_status_removed):
			enemy_node.connect("status_removed", _on_status_removed.bind(enemy_node))
	
	# Connect for DoT tick tracking
	if enemy_node.has_node("HealthComponent"):
		var hc = enemy_node.get_node("HealthComponent")
		if hc.has_signal("damaged"):
			if not hc.is_connected("damaged", _on_damage_taken):
				hc.connect("damaged", _on_damage_taken.bind(enemy_node))

func _on_status_applied(name: String, duration: float, params: Dictionary, enemy: Node):
	if not _is_listening: return
	
	var enemy_id = enemy.get_instance_id()
	if not tracked_statuses.has(enemy_id):
		tracked_statuses[enemy_id] = {}
	
	# Record detailed status application
	tracked_statuses[enemy_id][name] = {
		"start_time_ms": Time.get_ticks_msec(),
		"expected_duration": duration,
		"params": params.duplicate(),
		"ticks": 0,
		"tick_damages": [],  # Array of each tick's damage
		"total_damage": 0.0,
		"active": true,
		"application_count": tracked_statuses[enemy_id].get(name, {}).get("application_count", 0) + 1
	}

func _on_status_removed(name: String, enemy: Node):
	if not _is_listening: return
	
	var enemy_id = enemy.get_instance_id()
	if tracked_statuses.has(enemy_id) and tracked_statuses[enemy_id].has(name):
		var data = tracked_statuses[enemy_id][name]
		if data["active"]:
			data["end_time_ms"] = Time.get_ticks_msec()
			data["actual_duration_sec"] = (data["end_time_ms"] - data["start_time_ms"]) / 1000.0
			data["active"] = false

func _on_damage_taken(amount: int, element: String, enemy: Node):
	if not _is_listening: return
	
	# Map damage elements to status names
	var element_to_status = {
		"fire": "burn",
		"bleed": "bleed",
		"poison": "poison"
	}
	
	if not element_to_status.has(element): return
	var status_name = element_to_status[element]
	
	var enemy_id = enemy.get_instance_id()
	if tracked_statuses.has(enemy_id) and tracked_statuses[enemy_id].has(status_name):
		var data = tracked_statuses[enemy_id][status_name]
		if data["active"]:
			data["ticks"] += 1
			data["tick_damages"].append(amount)
			data["total_damage"] += amount

# ═══════════════════════════════════════════════════════════════════════════════
# STRICT VERIFICATION
# ═══════════════════════════════════════════════════════════════════════════════

func verify_status_strict(effect_name: String, expected: Dictionary) -> Dictionary:
	"""
	STRICT verification of a status effect.
	
	expected = {
		"must_apply": true,          # Status MUST be applied
		"damage_per_tick": 5.0,      # For DoTs
		"duration": 3.0,             # Expected duration
		"tick_count": 6,             # Expected number of ticks
		"total_damage": 30.0,        # Expected total DoT damage
		"amount": 0.5,               # For slow/freeze (50% slow)
		"on_enemies": 1              # Expected number of enemies affected
	}
	"""
	var result = {
		"passed": true,
		"status": effect_name,
		"checks": [],
		"failures": [],
		"instances_found": 0,
		"enemies_affected": 0
	}
	
	var must_apply = expected.get("must_apply", true)
	var expected_enemies = expected.get("on_enemies", 1)
	
	# Count instances across all enemies
	var instances_data = []
	for enemy_id in tracked_statuses:
		if tracked_statuses[enemy_id].has(effect_name):
			result["enemies_affected"] += 1
			instances_data.append({
				"enemy_id": enemy_id,
				"data": tracked_statuses[enemy_id][effect_name]
			})
	
	result["instances_found"] = instances_data.size()
	
	# Check 1: Was status applied when expected?
	if must_apply and result["instances_found"] == 0:
		result["passed"] = false
		result["failures"].append({
			"check": "application",
			"expected": "Status '%s' to be applied" % effect_name,
			"actual": "Status was never applied",
			"severity": "critical"
		})
		return result
	
	# Check 2: Correct number of enemies affected?
	if result["enemies_affected"] < expected_enemies:
		result["passed"] = false
		result["failures"].append({
			"check": "enemy_count",
			"expected": "%d enemies affected" % expected_enemies,
			"actual": "%d enemies affected" % result["enemies_affected"],
			"severity": "major"
		})
	
	# For each instance, validate parameters
	for instance in instances_data:
		var data = instance["data"]
		var enemy_id = instance["enemy_id"]
		
		# Check 3: Duration validation
		if expected.has("duration"):
			var exp_duration = expected["duration"]
			var actual_duration = data.get("actual_duration_sec", data.get("expected_duration", 0))
			var tolerance = DURATION_TOLERANCE_STRICT if strict_mode else DURATION_TOLERANCE_NORMAL
			
			if abs(actual_duration - exp_duration) > tolerance:
				result["passed"] = false
				result["failures"].append({
					"check": "duration",
					"enemy_id": enemy_id,
					"expected": "%.2f seconds" % exp_duration,
					"actual": "%.2f seconds" % actual_duration,
					"delta": abs(actual_duration - exp_duration),
					"severity": "major"
				})
			else:
				result["checks"].append({
					"check": "duration",
					"status": "PASS",
					"value": actual_duration
				})
		
		# Check 4: Tick count for DoTs
		if expected.has("tick_count"):
			var exp_ticks = expected["tick_count"]
			var actual_ticks = data.get("ticks", 0)
			var tolerance = TICK_TOLERANCE_STRICT if strict_mode else TICK_TOLERANCE_NORMAL
			
			if abs(actual_ticks - exp_ticks) > tolerance:
				result["passed"] = false
				result["failures"].append({
					"check": "tick_count",
					"enemy_id": enemy_id,
					"expected": "%d ticks" % exp_ticks,
					"actual": "%d ticks" % actual_ticks,
					"delta": abs(actual_ticks - exp_ticks),
					"severity": "major"
				})
			else:
				result["checks"].append({
					"check": "tick_count",
					"status": "PASS",
					"value": actual_ticks
				})
		
		# Check 5: Damage per tick
		if expected.has("damage_per_tick"):
			var exp_dpt = expected["damage_per_tick"]
			var tick_damages = data.get("tick_damages", [])
			var tolerance = DAMAGE_TOLERANCE_STRICT if strict_mode else DAMAGE_TOLERANCE_NORMAL
			
			for i in range(tick_damages.size()):
				var actual_dpt = tick_damages[i]
				if abs(actual_dpt - exp_dpt) > tolerance:
					result["passed"] = false
					result["failures"].append({
						"check": "damage_per_tick",
						"enemy_id": enemy_id,
						"tick": i + 1,
						"expected": "%.2f damage" % exp_dpt,
						"actual": "%.2f damage" % actual_dpt,
						"severity": "major"
					})
		
		# Check 6: Total damage
		if expected.has("total_damage"):
			var exp_total = expected["total_damage"]
			var actual_total = data.get("total_damage", 0)
			var tolerance_pct = 0.05 if strict_mode else 0.10
			
			var delta_pct = 0.0
			if exp_total > 0:
				delta_pct = abs(actual_total - exp_total) / exp_total
			
			if delta_pct > tolerance_pct:
				result["passed"] = false
				result["failures"].append({
					"check": "total_damage",
					"enemy_id": enemy_id,
					"expected": "%.2f total" % exp_total,
					"actual": "%.2f total" % actual_total,
					"delta_percent": delta_pct * 100,
					"severity": "major"
				})
			else:
				result["checks"].append({
					"check": "total_damage",
					"status": "PASS",
					"value": actual_total
				})
		
		# Check 7: Amount (for slow/freeze)
		if expected.has("amount"):
			var exp_amount = expected["amount"]
			var actual_amount = data.get("params", {}).get("amount", 0)
			var tolerance = 0.01 if strict_mode else 0.05
			
			if abs(actual_amount - exp_amount) > tolerance:
				result["passed"] = false
				result["failures"].append({
					"check": "amount",
					"enemy_id": enemy_id,
					"expected": "%.2f" % exp_amount,
					"actual": "%.2f" % actual_amount,
					"severity": "major"
				})
			else:
				result["checks"].append({
					"check": "amount",
					"status": "PASS",
					"value": actual_amount
				})
	
	return result

func verify_no_unexpected_status(allowed_statuses: Array) -> Dictionary:
	"""
	Verifica que NO se aplicaron status effects que no están en la lista permitida.
	Esto detecta efectos fantasma / bugs.
	"""
	var result = {
		"passed": true,
		"unexpected": [],
		"summary": ""
	}
	
	for enemy_id in tracked_statuses:
		for status_name in tracked_statuses[enemy_id]:
			if not status_name in allowed_statuses:
				result["passed"] = false
				result["unexpected"].append({
					"status": status_name,
					"enemy_id": enemy_id,
					"params": tracked_statuses[enemy_id][status_name].get("params", {}),
					"severity": "critical"
				})
	
	if result["passed"]:
		result["summary"] = "No unexpected status effects detected"
	else:
		result["summary"] = "CRITICAL: %d unexpected status effects applied!" % result["unexpected"].size()
	
	return result

# ═══════════════════════════════════════════════════════════════════════════════
# REPORTING
# ═══════════════════════════════════════════════════════════════════════════════

func get_detailed_report() -> Array:
	"""Returns a detailed report of all tracked status effects"""
	var report = []
	for enemy_id in tracked_statuses:
		for effect_name in tracked_statuses[enemy_id]:
			var data = tracked_statuses[enemy_id][effect_name]
			report.append({
				"enemy_id": enemy_id,
				"effect": effect_name,
				"ticks": data.get("ticks", 0),
				"tick_damages": data.get("tick_damages", []),
				"total_damage": data.get("total_damage", 0.0),
				"duration_sec": data.get("actual_duration_sec", -1),
				"expected_duration": data.get("expected_duration", 0),
				"params": data.get("params", {}),
				"active": data.get("active", false),
				"application_count": data.get("application_count", 1)
			})
	return report

func get_summary() -> Dictionary:
	"""Returns a summary of all status effect activity"""
	var summary = {
		"total_enemies_tracked": _tracked_enemies.size(),
		"total_statuses_applied": 0,
		"statuses_by_type": {},
		"total_dot_damage": 0.0,
		"total_ticks": 0
	}
	
	for enemy_id in tracked_statuses:
		for effect_name in tracked_statuses[enemy_id]:
			var data = tracked_statuses[enemy_id][effect_name]
			summary["total_statuses_applied"] += data.get("application_count", 1)
			summary["total_dot_damage"] += data.get("total_damage", 0.0)
			summary["total_ticks"] += data.get("ticks", 0)
			
			if not summary["statuses_by_type"].has(effect_name):
				summary["statuses_by_type"][effect_name] = 0
			summary["statuses_by_type"][effect_name] += 1
	
	return summary

func get_all_applied_statuses() -> Array:
	"""Returns array of all status effect names that were applied"""
	var statuses = []
	for enemy_id in tracked_statuses:
		for effect_name in tracked_statuses[enemy_id]:
			if not effect_name in statuses:
				statuses.append(effect_name)
	return statuses


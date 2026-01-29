extends Node
class_name StatusEffectOracle

# Stores tracking data for status effects
# Structure: { enemy_instance_id: { effect_name: { "start_time": int, "end_time": int, "ticks": 0, "total_damage": 0.0, "params": {} } } }
var tracked_statuses = {}
var _is_listening = false

# Configuration
const TICK_TOLERANCE = 1 # Allow +/- 1 tick due to frame alignment
const DURATION_TOLERANCE_SEC = 0.2

func start_listening():
	_clear_data()
	_is_listening = true

func stop_listening():
	_is_listening = false

func _clear_data():
	tracked_statuses = {}

func track_enemy(enemy_node: Node):
	if not is_instance_valid(enemy_node): return
	
	# Connect to signals
	if not enemy_node.is_connected("status_applied", _on_status_applied):
		enemy_node.connect("status_applied", _on_status_applied.bind(enemy_node))
	
	if not enemy_node.is_connected("status_removed", _on_status_removed):
		enemy_node.connect("status_removed", _on_status_removed.bind(enemy_node))
		
	# Connect for tick tracking (damage events)
	if enemy_node.has_node("HealthComponent"):
		var hc = enemy_node.get_node("HealthComponent")
		if not hc.is_connected("damaged", _on_damage_taken):
			hc.connect("damaged", _on_damage_taken.bind(enemy_node))

func _on_status_applied(name: String, duration: float, params: Dictionary, enemy: Node):
	if not _is_listening: return
	
	var enemy_id = enemy.get_instance_id()
	if not tracked_statuses.has(enemy_id):
		tracked_statuses[enemy_id] = {}
		
	# If refreshing, we might overwrite or merge. For verification, we assume single application test.
	tracked_statuses[enemy_id][name] = {
		"start_time": Time.get_ticks_msec(),
		"expected_duration": duration,
		"params": params,
		"ticks": 0,
		"total_damage": 0.0,
		"active": true
	}

func _on_status_removed(name: String, enemy: Node):
	if not _is_listening: return
	
	var enemy_id = enemy.get_instance_id()
	if tracked_statuses.has(enemy_id) and tracked_statuses[enemy_id].has(name):
		var data = tracked_statuses[enemy_id][name]
		if data["active"]:
			data["end_time"] = Time.get_ticks_msec()
			data["actual_duration"] = (data["end_time"] - data["start_time"]) / 1000.0
			data["active"] = false

func _on_damage_taken(amount: int, element: String, enemy: Node):
	if not _is_listening: return
	
	# Map elements to statuses (fire -> burn, bleed -> bleed)
	var effect_map = {
		"fire": "burn",
		"bleed": "bleed",
		"poison": "poison"
	}
	
	if not effect_map.has(element): return
	var status_name = effect_map[element]
	
	var enemy_id = enemy.get_instance_id()
	if tracked_statuses.has(enemy_id) and tracked_statuses[enemy_id].has(status_name):
		var data = tracked_statuses[enemy_id][status_name]
		if data["active"]:
			data["ticks"] += 1
			data["total_damage"] += amount

func verify_status(effect_name: String, expected_params: Dictionary) -> Dictionary:
	"""
	Verifies if a specific status was applied correctly across ALL tracked enemies.
	Returns aggregate result.
	"""
	var total_instances = 0
	var passed_instances = 0
	var failures = []
	
	for enemy_id in tracked_statuses:
		var enemy_data = tracked_statuses[enemy_id]
		# Check if effect tracked via signal OR currently active via API (fallback)
		var has_data = enemy_data.has(effect_name)
		var is_active_now = false
		
		# Try to find enemy instance to verify active state
		var enemy_node = instance_from_id(enemy_id)
		if is_instance_valid(enemy_node) and enemy_node.has_method("get_active_statuses"):
			var active = enemy_node.get_active_statuses()
			if active.has(effect_name):
				is_active_now = true
				if not has_data:
					# Discovered late or implicitly
					has_data = true
					enemy_data[effect_name] = {
						"start_time": Time.get_ticks_msec(),
						"active": true,
						"ticks": 0,
						"total_damage": 0.0,
						"params": active[effect_name]
					}
		
		if has_data:
			total_instances += 1
			var data = enemy_data[effect_name]
			var checks = []
			var valid = true
			
			# Check Duration (if expected)
			# Note: In a short test, duration might not finish, so we check if it started at least
			# Or if expected duration passed, verify it ended?
			# For now, just check specific params if provided.
			
			if expected_params.has("damage"):
				var expected_dmg = expected_params.get("damage")
				# Burn/Bleed params usually are damage_per_tick in signals
				var actual_dmg_param = data.get("params", {}).get("damage", 0)
				# Also check damage dealt if available
				# allow slight precision error
				if abs(actual_dmg_param - expected_dmg) > 0.1:
					valid = false
					checks.append("Damage Param Mismatch: Exp %.1f vs Act %.1f" % [expected_dmg, actual_dmg_param])
					
			if expected_params.has("amount"): # for slow/freeze
				var expected_amt = expected_params.get("amount")
				var actual_amt = data.get("params", {}).get("amount", 0)
				if abs(actual_amt - expected_amt) > 0.1:
					valid = false
					checks.append("Amount Mismatch: Exp %.1f vs Act %.1f" % [expected_amt, actual_amt])
			
			if valid:
				passed_instances += 1
			else:
				failures.append("Enemy %d: %s" % [enemy_id, ", ".join(checks)])
				
	if total_instances == 0:
		return {"passed": false, "reason": "No instances of status '%s' detected." % effect_name}
		
	if passed_instances == total_instances:
		return {"passed": true, "reason": "All %d instances validated." % total_instances}
	else:
		return {"passed": false, "reason": "Failures in %d/%d instances: %s" % [(total_instances - passed_instances), total_instances, "; ".join(failures)]}

func get_detailed_report() -> Array:
	var report = []
	for eid in tracked_statuses:
		for effect in tracked_statuses[eid]:
			var data = tracked_statuses[eid][effect]
			report.append({
				"enemy_id": eid,
				"effect": effect,
				"ticks": data.get("ticks", 0),
				"total_damage": data.get("total_damage", 0.0),
				"duration_sec": data.get("actual_duration", -1)
			})
	return report

			var checks = []
			
			# 1. Check Duration
			var expected_dur = data["expected_duration"]
			# If simulation ended before natural expiration, we can't fully verify actual_duration matches expected
			# But we can verify it didn't expire too early. 
			# For now, let's assume the test window is longer than status duration.
			
			if "actual_duration" in data:
				var actual_dur = data["actual_duration"]
				var diff = abs(actual_dur - expected_dur)
				if diff > DURATION_TOLERANCE_SEC:
					checks.append("Duration mismatch: Expected %.1fs, Actual %.1fs" % [expected_dur, actual_dur])
			
			# 2. Check Ticks (if DoT)
			if effect_name in ["burn", "bleed", "poison"]:
				var tick_interval = 0.5 # Default
				var expected_ticks = floor(expected_dur / tick_interval)
				# Only strict check if we recorded the full duration
				if "actual_duration" in data: 
					if abs(data["ticks"] - expected_ticks) > TICK_TOLERANCE:
						checks.append("Tick count mismatch: Expected ~%d, Actual %d" % [expected_ticks, data["ticks"]])
				
				# Verify Damage Per Tick matches params
				if data["ticks"] > 0:
					var avg_tick = data["total_damage"] / data["ticks"]
					var expected_tick_dmg = 0.0
					if effect_name == "burn": expected_tick_dmg = data["params"].get("damage", 0)
					if effect_name == "bleed": expected_tick_dmg = data["params"].get("damage", 0)
					
					if abs(avg_tick - expected_tick_dmg) > 1.0: # 1 damage tolerance
						checks.append("Damage/Tick mismatch: Expected %.1f, Actual Avg %.1f" % [expected_tick_dmg, avg_tick])
			
			# 3. Check Modifier Application (if relevant params exist)
			if effect_name == "slow" or effect_name == "freeze":
				var expected_amt = expected_params.get("amount", 0.0)
				var actual_amt = data["params"].get("amount", 0.0)
				if abs(actual_amt - expected_amt) > 0.01:
					checks.append("Modifier Amount mismatch: Expected %.2f, Actual %.2f" % [expected_amt, actual_amt])
			
			if checks.is_empty():
				passed_instances += 1
			else:
				failures.append("Enemy %s: %s" % [enemy_id, str(checks)])
	
	if total_instances == 0:
		return {"passed": false, "reason": "Status '%s' was never applied." % effect_name}
		
	var passed = (passed_instances == total_instances)
	return {
		"passed": passed,
		"instances": total_instances,
		"passed_instances": passed_instances,
		"failures": failures,
		"reason": "Status Verified" if passed else "Status Verification Failed: %s" % str(failures)
	}

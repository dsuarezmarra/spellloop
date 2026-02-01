extends Node

# DamageDeliveryLogger.gd
# Herramienta centralizada para auditar la tubería de daño (Phase 15)
# Registra cada paso del proceso: Cálculo -> Aplicación -> Feedback

const HEADLESS_MODE = true # Auto-detected usually, forced for safety in scripts
var _events: Array = []
var _log_enabled: bool = false # Toggle via runner

# Estructura de evento
# {
#   "id": int,
#   "frame": int,
#   "weapon_id": String,
#   "target_id": String,
#   "calculated": int,
#   "applied": int,
#   "feedback_shown": bool,
#   "is_crit": bool,
#   "timestamp": int
# }

func start_logging():
	_events.clear()
	_log_enabled = true
	print("📊 [DamageDelivery] Logging Started")

func stop_logging():
	_log_enabled = false
	print("📊 [DamageDelivery] Logging Stopped. Total Events: %d" % _events.size())

func log_calculation(weapon_id: String, target: Node, amount: int, is_crit: bool, flags: Dictionary = {}) -> int:
	if not _log_enabled: return -1
	
	var event_id = _events.size()
	var event = {
		"id": event_id,
		"frame": Engine.get_process_frames(),
		"weapon_id": weapon_id,
		"target_id": target.name if is_instance_valid(target) else "null",
		"calculated": amount,
		"applied": -1, # Pending
		"feedback_shown": false,
		"is_crit": is_crit,
		"flags": flags,
		"timestamp": Time.get_ticks_msec()
	}
	_events.append(event)
	return event_id

func log_application(event_id: int, applied_amount: int) -> void:
	if not _log_enabled: return
	if event_id >= 0 and event_id < _events.size():
		var event = _events[event_id]
		event["applied"] = applied_amount
		
		# Check consistency immediately
		if event["calculated"] != applied_amount:
			push_warning("⚠️ [DamageDelivery] Mismatch! Calc: %d vs Applied: %d (ID: %d)" % [event["calculated"], applied_amount, event_id])

func log_feedback(amount: int, is_crit: bool, position: Vector2) -> void:
	if not _log_enabled: return
	
	# Heuristic matching: Find recent event with matching amount/crit that hasn't shown feedback yet
	# Search backwards (LIFO)
	var found = false
	var frame = Engine.get_process_frames()
	
	for i in range(_events.size() - 1, -1, -1):
		var event = _events[i]
		# Match criteria: Same frame (or prev), same amount, no feedback yet
		if (frame - event["frame"]) <= 1 and event["applied"] == amount and not event["feedback_shown"]:
			event["feedback_shown"] = true
			found = true
			break
			
	if not found:
		# Phantom Feedback (Fake Hit?)
		push_warning("👻 [DamageDelivery] Feedback spawned but no matching damage event found! Amount: %d" % amount)

func get_events() -> Array:
	return _events

func get_discrepancies() -> Array:
	var discrepancies = []
	for e in _events:
		# Case 1: Calculated vs Applied
		if e["applied"] != -1 and e["calculated"] != e["applied"]:
			discrepancies.append(e)
			continue
			
		# Case 2: Applied but No Feedback
		if e["applied"] > 0 and not e["feedback_shown"]:
			# Ignore if frame just happened? No, runner waits.
			discrepancies.append(e)
			continue
			
		# Case 3: Zero damage but feedback? (Handled in log_feedback warning)
		
	return discrepancies

func save_report(path: String = "damage_delivery_discrepancies.json"):
	var disc = get_discrepancies()
	if disc.is_empty():
		print("✅ [DamageDelivery] No discrepancies found!")
		return
		
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(disc, "\t"))
		print("⚠️ [DamageDelivery] Saved %d discrepancies to %s" % [disc.size(), path])

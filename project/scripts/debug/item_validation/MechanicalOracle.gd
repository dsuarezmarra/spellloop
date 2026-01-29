extends Node
class_name MechanicalOracle

# Stores events captured during the test window
var captured_events = {
	"damage_events": [], # {amount, source, target}
	"death_events": [],
	"hits": 0,
	"total_damage": 0.0,
	"projectiles_spawned": 0
}

var _is_listening = false

func start_listening():
	_clear_events()
	_is_listening = true

func stop_listening():
	_is_listening = false

func _clear_events():
	captured_events = {
		"damage_events": [],
		"death_events": [],
		"hits": 0,
		"total_damage": 0.0,
		"projectiles_spawned": 0
	}

# Call this to register a dummy enemy for tracking
func track_enemy(enemy_node: Node):
	# 1. Try HealthComponent (Standard)
	if enemy_node.has_node("HealthComponent"):
		var hc = enemy_node.get_node("HealthComponent")
		# Standard SpellLoop Signal: damaged(amount: int, type: String)
		if hc.has_signal("damaged"):
			if not hc.damaged.is_connected(_on_damaged_signal):
				hc.damaged.connect(_on_damaged_signal.bind(enemy_node))
		
		# Fallback/Legacy
		if not hc.health_changed.is_connected(_on_health_changed):
			hc.health_changed.connect(_on_health_changed)
		if not hc.died.is_connected(_on_died):
			hc.died.connect(_on_died)
			
	# 2. Try Direct Signals (DummyEnemy)
	if enemy_node.has_signal("damage_taken"):
		# DummyEnemy: damage_taken(amount, is_crit)
		if not enemy_node.damage_taken.is_connected(_on_direct_damage_taken):
			enemy_node.damage_taken.connect(_on_direct_damage_taken.bind(enemy_node))
			
	# Start tracking damage numbers if possible (e.g. from DamageLogger signal if available)
	# For now we rely on HealthComponent changes

# Event Handlers
func _on_damaged_signal(amount, _type, target_node):
	# HealthComponent signal: damaged(amount, type)
	# We assume is_crit is false here unless we have better info, or use a heuristic
	# But typically Projectile handles the crit calculation. 
	# For strict checking, we rely on the numeric value.
	log_damage(amount, false, target_node)

func _on_direct_damage_taken(amount, is_crit, target_node):
	# DummyEnemy signal: damage_taken(amount, is_crit)
	log_damage(amount, is_crit, target_node)

func _on_health_changed(_current, _max_hp):
	# Legacy fallback, ignore if we are getting explicit damage signals
	pass

func log_damage(amount, is_crit, target):
	if not _is_listening: return
	captured_events["hits"] += 1
	captured_events["total_damage"] += amount
	captured_events["damage_events"].append({
		"amount": amount,
		"is_crit": is_crit,
		"target": target.name
	})

func _on_died():
	if not _is_listening: return
	captured_events["death_events"].append(Time.get_ticks_msec())

# Verification Logic
func verify_damage_event(expected_damage: float, tolerance_percent: float = 0.05) -> Dictionary:
	var actual = captured_events["total_damage"]
	var delta = abs(actual - expected_damage)
	var delta_percent = 0.0
	if expected_damage != 0:
		delta_percent = delta / expected_damage
	
	var passed = delta_percent <= tolerance_percent
	
	# Fallback: if expected is small (like 0), use absolute tolerance
	if expected_damage < 1.0:
		passed = delta < 0.1
		
	return {
		"passed": passed,
		"expected": expected_damage,
		"actual": actual,
		"delta_abs": delta,
		"delta_percent": delta_percent,
		"hits": captured_events["hits"],
		"reason": "Match (Delta %.1f%%)" % (delta_percent*100) if passed else "Mismatch (Delta %.1f%% > %.1f%%)" % [delta_percent*100, tolerance_percent*100]
	}

func verify_projectile_count(expected_count: int) -> Dictionary:
	# This requires ProjectileFactory instrumentation which we don't have yet fully.
	# Fallback: check hits if single target 100% hit rate assumption
	var actual = captured_events["hits"]
	var passed = actual == expected_count 
	
	return {
		"passed": passed,
		"expected": expected_count,
		"actual": actual,
		"reason": "Hit count match" if passed else "Hit count mismatch (Proxy for projectiles)"
	}

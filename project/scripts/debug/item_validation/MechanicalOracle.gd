extends Node
class_name MechanicalOracle

# Stores events captured during the test window
var captured_events = {
	"damage_events": [], # {amount, source, target}
	"death_events": [],
	"hits": 0,
	"total_damage": 0.0,
	"projectiles_spawned": 0,
	"initial_hp_map": {},
	"final_hp_map": {}
}

var _tracked_enemies = []
var _is_listening = false
var is_measure_mode = false

func start_listening():
	_clear_events()
	_is_listening = true
	
	# Snapshot Initial HP
	for enemy in _tracked_enemies:
		if is_instance_valid(enemy):
			var hp = 0
			if enemy.has_node("HealthComponent"):
				hp = enemy.get_node("HealthComponent").current_health
			elif "hp" in enemy:
				hp = enemy.hp
			captured_events["initial_hp_map"][enemy] = hp

func stop_listening():
	_is_listening = false
	# Snapshot Final HP
	for enemy in _tracked_enemies:
		if is_instance_valid(enemy):
			var hp = 0
			if enemy.has_node("HealthComponent"):
				hp = enemy.get_node("HealthComponent").current_health
			elif "hp" in enemy:
				hp = enemy.hp
			captured_events["final_hp_map"][enemy] = hp

func _clear_events():
	_tracked_enemies = []
	captured_events = {
		"damage_events": [],
		"death_events": [],
		"hits": 0,
		"total_damage": 0.0,
		"projectiles_spawned": 0,
		"initial_hp_map": {},
		"final_hp_map": {}
	}

# Call this to register a dummy enemy for tracking
func track_enemy(enemy_node: Node):
	if not enemy_node in _tracked_enemies:
		_tracked_enemies.append(enemy_node)
		
	# 1. Try HealthComponent (Standard) - Prioritize this
	if enemy_node.has_node("HealthComponent"):
		var hc = enemy_node.get_node("HealthComponent")
		if hc.has_signal("damaged"):
			if not hc.damaged.is_connected(_on_damaged_signal):
				hc.damaged.connect(_on_damaged_signal.bind(enemy_node))
				return # Don't connect to other signals to avoid double-logging
		
	# 2. Try Direct Signals (DummyEnemy) - Fallback
	if enemy_node.has_signal("damage_taken"):
		if not enemy_node.damage_taken.is_connected(_on_direct_damage_taken):
			enemy_node.damage_taken.connect(_on_direct_damage_taken.bind(enemy_node))

# Event Handlers
func _on_damaged_signal(amount, _type, target_node):
	log_damage(amount, false, target_node)

func _on_direct_damage_taken(amount, is_crit, target_node):
	log_damage(amount, is_crit, target_node)

func _on_health_changed(_current, _max_hp):
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
	"""LEGACY: Single damage event verification"""
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

func verify_simulation_results(stats: Dictionary, projectile_type: String, test_duration: float, tolerance: float) -> Dictionary:
	"""
	Calculates expected total damage based on projectile semantics.
	"""
	var captured_total = captured_events["total_damage"]
	var damage_final = stats.get("damage_final", stats.get("damage_base", 1.0))
	var projectile_count = stats.get("projectile_count_final", stats.get("projectile_count_base", 1))
	
	# Model Classification
	var model = "SIMPLE" # Default
	match projectile_type:
		"BEAM": model = "BEAM"
		"ORBIT": model = "ORBIT" 
		"AOE": model = "AOE"
		"CHAIN": model = "CHAIN" 
		"MULTI": model = "MULTI"
		_:
			if projectile_count > 1:
				model = "MULTI"

	# 1. Calculate DPS Cycle (Volley)
	var damage_per_volley = damage_final
	if model in ["MULTI", "CHAIN", "AOE"]:
		damage_per_volley = damage_final * projectile_count
	
	# 2. Calculate Fire Count based on Cooldown
	var cooldown = stats.get("cooldown_final", stats.get("cooldown_base", 1.0))
	if cooldown <= 0: cooldown = 0.1 # Safety
	
	# Initial shot at T=0, then every 'cooldown' seconds.
	var fire_count = 1 + floor((test_duration + 0.05) / cooldown)
	
	var expected_hit_damage = 0.0

	match model:
		"SIMPLE":
			expected_hit_damage = damage_per_volley * fire_count
			
		"CHAIN":
			# Lightning Wand (1) or Storm Caller (5). 
			# In 1v1 test, assume all chains hit.
			expected_hit_damage = damage_per_volley * fire_count
			
		"MULTI":
			# Shotgun. All projectiles hit.
			expected_hit_damage = damage_per_volley * fire_count
			
		"BEAM":
			# DESIGN RULE: Beam hits multiple times during its fire event.
			# Empirically, thunder_spear hits ~1.6-2.0 times per fire in 2s.
			expected_hit_damage = damage_final * 2 * fire_count
			
		"ORBIT":
			# DESIGN RULE: Orbitals hit based on their rotation speed.
			# Orbit Time = (2 * PI * Radius) / Speed
			var radius = stats.get("range_final", stats.get("range_base", 120.0))
			var speed = stats.get("projectile_speed_final", stats.get("projectile_speed_base", 200.0))
			var orbit_time = (2.0 * PI * radius) / speed if speed > 0 else 4.0
			var periodic_hits = 1 + floor((test_duration + 0.01) / orbit_time)
			# Clamp by global 0.5s cooldown per entity
			periodic_hits = min(periodic_hits, 1 + floor((test_duration + 0.01) / 0.5))
			expected_hit_damage = damage_final * projectile_count * periodic_hits
			
		"AOE":
			# AOE usually hits once per fire.
			expected_hit_damage = damage_per_volley * fire_count

	# 3. Calculate Status Effects (DoT)
	var expected_dot_damage = 0.0
	var burn_chance = stats.get("burn_chance", 0.0)
	var bleed_chance = stats.get("bleed_chance", 0.0)
	
	var status_duration_mult = stats.get("status_duration_mult", 1.0)
	
	# Burn: 0.5s interval
	if burn_chance > 0.1: # Significant chance
		var burn_dmg = stats.get("burn_damage", 3.0)
		var burn_active_duration = max(0, test_duration - 0.2) # Assume applied shortly after start
		var ticks = floor(burn_active_duration / 0.5)
		# If chance is < 1.0, effectively it applies once and refreshes.
		# For validation, we assume application.
		expected_dot_damage += burn_dmg * ticks

	# Bleed: 0.5s interval
	if bleed_chance > 0.1:
		var bleed_dmg = stats.get("bleed_damage", 2.0)
		var bleed_active_duration = max(0, test_duration - 0.2)
		var ticks = floor(bleed_active_duration / 0.5)
		expected_dot_damage += bleed_dmg * ticks

	var expected_total_damage = expected_hit_damage + expected_dot_damage

	# Breakdown for reporting
	var breakdown = {
		"initial_hit_damage": expected_hit_damage,
		"dot_damage_burn": expected_dot_damage if burn_chance > 0.1 else 0.0,
		"dot_damage_bleed": expected_dot_damage if bleed_chance > 0.1 else 0.0,
		"total_damage": expected_total_damage,
		"window_seconds": test_duration,
		"burn_chance": burn_chance,
		"bleed_chance": bleed_chance
	}

	# Tolerance Adjustments
	var tolerance_percent = tolerance # Initialize with the passed tolerance
	match model:
		"BEAM", "ORBIT": tolerance_percent = 0.35 
		"CHAIN": tolerance_percent = 0.25
		_: 
			# Apply stricter tolerance for simple models now that double-logging is fixed
			tolerance_percent = 0.15 
	
	var delta = abs(captured_total - expected_total_damage)
	var delta_percent = 0.0
	if expected_total_damage > 0:
		delta_percent = delta / expected_total_damage
		
	var passed = delta_percent <= tolerance_percent
	
	# Fallback for very low values
	if expected_total_damage < 5.0 and delta < 2.0:
		passed = true
	
	var result_code = "PASS"
	var triage = "NONE"
	
	if not passed:
		if delta_percent > 3.0: 
			result_code = "BUG"
		else:
			result_code = "DESIGN_VIOLATION"
			
		# Task 2: Automated Triage (A/B/C)
		if model in ["BEAM", "CHAIN"]:
			triage = "MODEL_GAP" # Beams/Chains are hard to model perfectly
		elif model == "ORBIT":
			triage = "TEST_ENV_GAP" # Orbit depends heavily on dummy placement
		elif stats.get("crit_chance", 0) > 0.1 or stats.get("life_steal", 0) > 0:
			triage = "MODEL_GAP" # Crit/Lifesteal adds variance/complexity
		else:
			triage = "BALANCE_REAL"
	else:
		result_code = "DESIGN_ACCEPTABLE"
		
	var report = {
		"passed": passed,
		"expected": expected_total_damage,
		"actual": captured_total,
		"delta_percent": delta_percent,
		"model": model,
		"result_code": result_code,
		"triage": triage,
		"reason": "[%s] Hit Expected %.1f vs Actual %.1f (Delta %.1f%%) -> %s" % [model, expected_total_damage, captured_total, delta_percent*100, result_code],
		"breakdown": breakdown
	}
	
	# MEASURE Mode: return raw counts
	if is_measure_mode:
		report["measurements"] = {
			"hits": captured_events["hits"],
			"total_damage": captured_events["total_damage"],
			"duration": test_duration,
			"avg_damage_per_hit": captured_events["total_damage"] / max(1, captured_events["hits"])
		}
		
	return report

func verify_projectile_count(expected_count: int) -> Dictionary:
	var actual = captured_events["hits"]
	var passed = actual >= expected_count
	return {
		"passed": passed,
		"expected": expected_count,
		"actual": actual,
		"reason": "Hit count match" if passed else "Hit count mismatch"
	}

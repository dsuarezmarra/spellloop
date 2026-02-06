extends Node
class_name NumericOracle

# Tolerances
const MULTIPLIER_TOLERANCE = 0.02 # 2% tolerance for float multipliers
const ADDITIVE_TOLERANCE = 0.001

func verify_changes(item: Dictionary, baseline: Dictionary, actual: Dictionary, weapon_type: String) -> Dictionary:
	var results = {
		"passed": true,
		"failures": [],
		"subtests": []
	}
	
	var effects = item.get("effects", [])
	
	# Verify each effect defined in the item
	for effect in effects:
		var stat = effect.get("stat")
		var op = effect.get("operation", "add")
		var value = effect.get("value")
		
		# Map item stat names to AttackManager stat keys
		var keys = _map_stat_keys(stat)
		
		for key_group in keys:
			var base_key = key_group["base"]
			var final_key = key_group["final"]
			var mult_key = key_group.get("mult")
			
			if not baseline.has(final_key) or not actual.has(final_key):
				results["subtests"].append({
					"stat": stat,
					"passed": false,
					"reason": "Stat key not found in AttackManager: %s" % final_key
				})
				results["failures"].append("Missing key: %s" % final_key)
				continue
				
			var val_base = baseline[final_key]
			var val_actual = actual[final_key]
			var expected_val = val_base
			
			# Calculate Expected Value
			# Note: Baseline might already have other modifiers if not clean, 
			# but in our test harness we assume clean state + this item.
			# However, AttackManager logic is complex (base -> current -> final).
			# We should verify the DELTA or the FINAL value based on the operation.
			
			if op == "multiply":
				# For multipliers, we often check the 'mult' field if available, 
				# or we expect Final = Baseline * Value
				
				# Case A: Checking the Multiplier Field directly (most robust for multipliers)
				if mult_key and baseline.has(mult_key) and actual.has(mult_key):
					var mult_base = baseline[mult_key]
					var mult_actual = actual[mult_key]
					# Expected: New Mult = Old Mult * Value (or + Value if additive multiplier like damage_mult)
					# Godot logic usually: damage_mult += value (if additive stack) or damage_mult *= value
					# Most upgrades in this game seem to be additive percentage (e.g. +10% damage = +0.1 to mult)
					# EXCEPT if explicitly defined. Let's infer from existing UpgradeDatabase.
					# Defensive: "add" 0.1 usually. "multiply" 1.15.
					
					var expected_mult = mult_base
					
					# Special handling for known additive-stacking multipliers logic in this game
					# If operation is "add" on a "mult" stat, it adds.
					# If operation is "multiply", it multiplies.
					
					if op == "add": 
						expected_mult += value
					elif op == "multiply":
						expected_mult *= value
						
					if not _is_close(mult_actual, expected_mult, MULTIPLIER_TOLERANCE):
						results["passed"] = false
						results["failures"].append("Multiplier mismatch for %s: Expected %.2f, Got %.2f" % [stat, expected_mult, mult_actual])
						results["subtests"].append({"stat": stat, "passed": false, "reason": "Multiplier mismatch"})
					else:
						results["subtests"].append({"stat": stat, "passed": true, "val": mult_actual})
						
				# Case B: Checking Final Value (fall back if no mult key or for simple validation)
				else:
					expected_val = val_base * value
					if not _is_close(val_actual, expected_val, MULTIPLIER_TOLERANCE):
						# Fallback: maybe it was additive percent? (Base * (1 + val))
						var alt_expected = val_base * (1.0 + value)
						# Or maybe it was additive to base?
						
						results["passed"] = false
						results["failures"].append("Value mismatch for %s: Baseline %.2f, Expected ~%.2f, Got %.2f" % [stat, val_base, expected_val, val_actual])
						results["subtests"].append({"stat": stat, "passed": false, "reason": "Value mismatch"})
					else:
						results["subtests"].append({"stat": stat, "passed": true, "val": val_actual})

			elif op == "add":
				# Additive
				expected_val = val_base + value
				
				# Tolerance check
				var tolerance = ADDITIVE_TOLERANCE
				if typeof(val_actual) == TYPE_FLOAT:
					if not _is_close(val_actual, expected_val, tolerance):
						results["passed"] = false
						results["failures"].append("Value mismatch for %s: Expected %.2f, Got %.2f" % [stat, expected_val, val_actual])
						results["subtests"].append({"stat": stat, "passed": false, "reason": "Additive mismatch"})
					else:
						results["subtests"].append({"stat": stat, "passed": true, "val": val_actual})
				else:
					# Integer strict check
					if val_actual != int(expected_val):
						results["passed"] = false
						results["failures"].append("Value mismatch for %s: Expected %d, Got %d" % [stat, int(expected_val), val_actual])
						results["subtests"].append({"stat": stat, "passed": false, "reason": "Integer mismatch"})
					else:
						results["subtests"].append({"stat": stat, "passed": true, "val": val_actual})
	
	return results

func _is_close(a: float, b: float, tol: float) -> bool:
	return abs(a - b) <= tol

func _map_stat_keys(stat_name: String) -> Array:
	# Maps an item stat name (e.g., "damage_mult") to AttackManager keys
	# Returns an array of dicts because one stat might affect multiple keys (rare but possible)
	
	match stat_name:
		"damage", "damage_mult":
			# AttackManager keys: damage_final, damage_mult
			return [{ "base": "damage_base", "final": "damage_final", "mult": "damage_mult" }]
		"area", "area_mult":
			return [{ "base": "area_base", "final": "area_final", "mult": "area_mult" }]
		"cooldown", "attack_speed", "attack_speed_mult":
			# Cooldown is inverse of attack speed roughly, but we check specific keys
			return [
				{ "base": "attack_speed_base", "final": "attack_speed_final", "mult": "attack_speed_mult" },
				{ "base": "cooldown_base", "final": "cooldown_final" } # Optional check
			]
		"projectile_speed", "projectile_speed_mult":
			return [{ "base": "projectile_speed_base", "final": "projectile_speed_final", "mult": "projectile_speed_mult" }]
		"duration", "duration_mult":
			return [{ "base": "duration_base", "final": "duration_final", "mult": "duration_mult" }]
		"amount", "projectile_count", "extra_projectiles":
			return [{ "base": "projectile_count_base", "final": "projectile_count_final", "mult": null }] # Usually additive
		"pierce", "extra_pierce":
			return [{ "base": "pierce_base", "final": "pierce_final" }]
		"knockback", "knockback_mult":
			return [{ "base": "knockback_base", "final": "knockback_final", "mult": "knockback_mult" }]
		"range", "range_mult":
			return [{ "base": "range_base", "final": "range_final", "mult": "range_mult" }]
		_:
			# Default guess: assume key exists as-is or with _final suffix
			return [{ "base": stat_name + "_base", "final": stat_name + "_final", "mult": stat_name + "_mult" }]

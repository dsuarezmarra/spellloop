extends Node
class_name EnemyContractOracle

# EnemyContractOracle.gd
# Validates that an instantiated Enemy matches its EnemyDatabase definition.
# Part of Phase 5: Enemy & Combat Validation.

const FLOAT_TOLERANCE = 0.5
const COLOR_TOLERANCE = 0.1

static func validate_enemy(enemy: Node, expected_data: Dictionary = {}, strict: bool = true) -> Dictionary:
	var result = {
		"passed": true,
		"enemy_id": "unknown",
		"checks": [],
		"discrepancies": []
	}
	
	if not is_instance_valid(enemy):
		result.passed = false
		result.discrepancies.append("Enemy instance is invalid/null")
		return result
		
	# 1. Get Actual Data
	var actual_id = enemy.get("enemy_id") if "enemy_id" in enemy else "unknown"
	result.enemy_id = actual_id
	
	# 2. Get Expected Data (if not provided, try to find it, but this might fail in headless without autoloads)
	if expected_data.is_empty():
		# Try to use global EnemyDatabase if available
		# In headless runner this might fail if not autoloaded
		if ClassDB.class_exists("EnemyDatabase") or Engine.has_singleton("EnemyDatabase"):
			expected_data = EnemyDatabase.get_enemy_by_id(actual_id)
		else:
			# If we can't find it, we can't validate
			result.passed = false
			result.discrepancies.append("Expected data not provided and EnemyDatabase not found.")
			return result
	
	if expected_data.is_empty():
		result.passed = false
		result.discrepancies.append("Enemy ID '%s' not found in EnemyDatabase" % actual_id)
		return result
		
	# 3. Validate Properties
	
	# HP
	var exp_hp = expected_data.get("base_hp", 0)
	var exp_tier = int(expected_data.get("tier", 1))
	
	# Apply Tier Scaling (Simplest check: Database returns BASE stats, Enemy has SCALED stats?)
	# Use initialize_from_database logic logic to infer expected scaled values if needed.
	# EnemyBase.initialize_from_database sets max_hp directly from data.
	# But wait, EnemyDatabase constants define SCALING.
	
	# Actually, `EnemyDatabase.get_enemy_by_id` usually returns the static definition.
	# `EnemyBase` applies scaling if logic demands, OR the validation should check if 
	# the enemy is configured AS DEFINED.
	# Phase 5 goal: "Validar que HP, armor, speed, size coinciden con definición"
	
	# Property: Tier
	_check_property(result, enemy, "enemy_tier", exp_tier, "Same")
	
	# Property: HP
	# Note: Enemy might be scaled. We should check if it matches the definition provided to it.
	# If strict mode, we assume the enemy was initialized with this exact dict.
	_check_property(result, enemy, "max_hp", expected_data.get("base_hp"), "Equal")
	
	# Property: Damage
	_check_property(result, enemy, "damage", expected_data.get("base_damage"), "Equal")
	
	# Property: Speed
	_check_property(result, enemy, "speed", expected_data.get("base_speed"), "Float", FLOAT_TOLERANCE)
	
	# Property: XP
	_check_property(result, enemy, "exp_value", expected_data.get("base_xp"), "Equal")
	
	# Property: Archetype
	_check_property(result, enemy, "archetype", expected_data.get("archetype"), "Equal")
	
	# Property: Collision Radius
	var col_shape = _find_circle_shape(enemy)
	if col_shape:
		var exp_radius = expected_data.get("collision_radius", 16.0)
		if abs(col_shape.radius - exp_radius) > FLOAT_TOLERANCE:
			_fail(result, "collision_radius", exp_radius, col_shape.radius, "Mismatch")
		else:
			_pass(result, "collision_radius", exp_radius)
	else:
		_fail(result, "collision_shape", "CircleShape2D", "None", "Missing collision shape")

	# Property: Status Immunities (Logic check, not property check usually)
	# Assuming immunities are metadata or specific flags?
	# EnemyBase doesn't seem to have 'immunities' var in the snippet read.
	
	return result

static func _check_property(result: Dictionary, obj: Object, prop: String, expected: Variant, comparison: String = "Equal", tolerance: float = 0.0) -> void:
	if not prop in obj:
		_fail(result, prop, "Exists", "Missing property", "Property not found on enemy")
		return
		
	var actual = obj.get(prop)
	
	match comparison:
		"Equal":
			if str(actual) != str(expected): # String comparison for safety
				_fail(result, prop, expected, actual)
			else:
				_pass(result, prop, actual)
		"Same":
			if actual != expected:
				_fail(result, prop, expected, actual)
			else:
				_pass(result, prop, actual)
		"Float":
			if abs(float(actual) - float(expected)) > tolerance:
				_fail(result, prop, expected, actual)
			else:
				_pass(result, prop, actual)

static func _fail(result: Dictionary, check: String, expected: Variant, actual: Variant, msg: String = "") -> void:
	result.passed = false
	var log_msg = "[FAIL] %s: Expected %s, Got %s" % [check, str(expected), str(actual)]
	if msg: log_msg += " (%s)" % msg
	result.discrepancies.append(log_msg)
	result.checks.append({"check": check, "status": "FAIL", "expected": expected, "actual": actual})

static func _pass(result: Dictionary, check: String, val: Variant) -> void:
	result.checks.append({"check": check, "status": "PASS", "value": val})

static func _find_circle_shape(node: Node) -> CircleShape2D:
	for child in node.get_children():
		if child is CollisionShape2D and child.shape is CircleShape2D:
			return child.shape
	return null

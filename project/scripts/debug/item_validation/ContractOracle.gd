# ContractOracle.gd
# Sistema de validación por contrato para items de Spellloop
#
# Un CONTRATO es la especificación exacta de lo que un item DEBE hacer:
# - Qué stats modifica
# - Con qué valores exactos
# - Qué efectos de status aplica
# - Qué efectos NO debe aplicar
# - Condiciones de activación
#
# Este oracle:
# 1. INFIERE el contrato a partir de la definición del item
# 2. VALIDA que el comportamiento real coincide EXACTAMENTE
# 3. DETECTA efectos no declarados (side effects / bugs)

extends Node
class_name ContractOracle

# ═══════════════════════════════════════════════════════════════════════════════
# TIPOS DE CONTRATO
# ═══════════════════════════════════════════════════════════════════════════════

enum ContractType {
	STAT_MODIFIER,      # Modifica un stat del jugador/arma
	STATUS_APPLIER,     # Aplica un efecto de status
	DAMAGE_DEALER,      # Hace daño (armas/fusiones)
	PASSIVE_EFFECT,     # Efecto pasivo (personajes)
	CONDITIONAL_EFFECT, # Efecto que requiere condición
	COMPLEX_BEHAVIOR    # Múltiples efectos combinados
}

enum ValidationResult {
	PASS,              # Contrato cumplido exactamente
	FAIL_VALUE,        # Valor incorrecto
	FAIL_MISSING,      # Efecto esperado no aplicado
	FAIL_EXTRA,        # Efecto no declarado aplicado
	FAIL_ORDER,        # Orden de aplicación incorrecto
	FAIL_STACKING,     # Acumulación incorrecta
	BUG                # Error crítico / crash
}

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTES
# ═══════════════════════════════════════════════════════════════════════════════

# Tolerancias estrictas
const TOLERANCE_ADDITIVE = 0.001      # Para valores aditivos
const TOLERANCE_MULTIPLICATIVE = 0.01 # 1% para multiplicadores
const TOLERANCE_DAMAGE = 0.05         # 5% para daño (varianza de crits)
const TOLERANCE_STATUS_DURATION = 0.1 # 0.1 segundos para duraciones
const TOLERANCE_TICK_COUNT = 1        # +/- 1 tick permitido

# Stats que son "safe" para el jugador (no deben bajar de ciertos valores)
const STAT_MINIMUMS = {
	"max_health": 1,
	"damage_mult": 0.1,
	"move_speed": 10.0,
	"armor": -100  # Puede ser negativo pero con límite
}

# ═══════════════════════════════════════════════════════════════════════════════
# ESTRUCTURA DEL CONTRATO
# ═══════════════════════════════════════════════════════════════════════════════

# Un contrato inferido tiene esta estructura:
# {
#   "item_id": "health_1",
#   "contract_type": ContractType.STAT_MODIFIER,
#   "expected_effects": [
#     {
#       "type": "stat_change",
#       "stat": "max_health",
#       "operation": "add",
#       "value": 10,
#       "tolerance": 0.001
#     }
#   ],
#   "forbidden_effects": ["damage_mult", "crit_chance", ...],  # Stats que NO debe tocar
#   "status_effects": [],  # Status que debe aplicar
#   "forbidden_status": ["burn", "freeze", ...],  # Status que NO debe aplicar
#   "conditions": [],  # Condiciones de activación
#   "stacking_rules": {"max_stacks": 10, "stacking_type": "additive"}
# }

var _inferred_contracts: Dictionary = {}  # Cache de contratos inferidos

# ═══════════════════════════════════════════════════════════════════════════════
# INFERENCIA DE CONTRATOS
# ═══════════════════════════════════════════════════════════════════════════════

func infer_contract(item: Dictionary) -> Dictionary:
	"""
	Analiza la definición de un item y construye su contrato funcional.
	"""
	var item_id = item.get("id", "unknown")
	
	# Check cache
	if _inferred_contracts.has(item_id):
		return _inferred_contracts[item_id]
	
	var contract = {
		"item_id": item_id,
		"item_type": item.get("_type", "UNKNOWN"),
		"category": item.get("category", "unknown"),
		"contract_type": _infer_contract_type(item),
		"expected_effects": [],
		"expected_status": [],
		"forbidden_effects": [],
		"forbidden_status": [],
		"conditions": [],
		"stacking_rules": {
			"max_stacks": item.get("max_stacks", 1),
			"is_unique": item.get("is_unique", false),
			"is_cursed": item.get("is_cursed", false)
		},
		"description": item.get("description", ""),
		"inferred_from_description": []
	}
	
	# 1. Extraer efectos declarados
	var effects = item.get("effects", [])
	var declared_stats = []
	
	for effect in effects:
		var stat = effect.get("stat", "")
		var value = effect.get("value", 0)
		var operation = effect.get("operation", "add")
		
		declared_stats.append(stat)
		
		contract["expected_effects"].append({
			"type": "stat_change",
			"stat": stat,
			"operation": operation,
			"value": value,
			"tolerance": _get_tolerance_for_stat(stat, operation)
		})
	
	# 2. Inferir efectos de status desde stats especiales
	_infer_status_from_stats(item, contract)
	
	# 3. Inferir desde descripción (regex patterns)
	_infer_from_description(item, contract)
	
	# 4. Construir lista de efectos prohibidos
	_build_forbidden_list(contract, declared_stats)
	
	# 5. Inferir condiciones especiales
	_infer_conditions(item, contract)
	
	# Cache
	_inferred_contracts[item_id] = contract
	
	return contract

func _infer_contract_type(item: Dictionary) -> int:
	var item_type = item.get("_type", "")
	var effects = item.get("effects", [])
	
	if item_type in ["WEAPON", "FUSION"]:
		return ContractType.DAMAGE_DEALER
	
	if item_type == "CHARACTER":
		return ContractType.PASSIVE_EFFECT
	
	if item_type in ["ENEMY_T1", "ENEMY_T2", "ENEMY_T3", "ENEMY_T4"]:
		return ContractType.DAMAGE_DEALER  # Enemies deal damage
	
	# Check for status effects in stats
	for effect in effects:
		var stat = effect.get("stat", "")
		if stat in ["burn_chance", "freeze_chance", "bleed_chance", "stun_chance", "slow_chance"]:
			return ContractType.STATUS_APPLIER
	
	# Check for conditional keywords
	var desc = item.get("description", "").to_lower()
	if "cuando" in desc or "si " in desc or "al " in desc:
		return ContractType.CONDITIONAL_EFFECT
	
	# Check if it has multiple different effect types
	if effects.size() > 2:
		return ContractType.COMPLEX_BEHAVIOR
	
	return ContractType.STAT_MODIFIER

func _get_tolerance_for_stat(stat: String, operation: String) -> float:
	if operation == "multiply":
		return TOLERANCE_MULTIPLICATIVE
	
	# Damage stats need more tolerance due to variance
	if stat in ["damage_base", "damage_mult", "crit_damage"]:
		return TOLERANCE_DAMAGE
	
	return TOLERANCE_ADDITIVE

func _infer_status_from_stats(item: Dictionary, contract: Dictionary) -> void:
	"""Infiere efectos de status a partir de stats como burn_chance, freeze_chance, etc."""
	var effects = item.get("effects", [])
	
	var status_map = {
		"burn_chance": {"status": "burn", "damage_stat": "burn_damage", "default_damage": 3.0},
		"freeze_chance": {"status": "freeze", "amount_stat": "freeze_amount", "default_amount": 1.0},
		"bleed_chance": {"status": "bleed", "damage_stat": "bleed_damage", "default_damage": 2.0},
		"slow_chance": {"status": "slow", "amount_stat": "slow_amount", "default_amount": 0.3},
		"stun_chance": {"status": "stun", "duration_stat": "stun_duration", "default_duration": 1.0},
		"knockback": {"status": "knockback", "force_stat": "knockback_force", "default_force": 100.0}
	}
	
	for effect in effects:
		var stat = effect.get("stat", "")
		if status_map.has(stat):
			var mapping = status_map[stat]
			var status_contract = {
				"status": mapping["status"],
				"chance": effect.get("value", 1.0),
				"params": {}
			}
			
			# Find associated damage/amount stat
			for e2 in effects:
				if mapping.has("damage_stat") and e2.get("stat") == mapping["damage_stat"]:
					status_contract["params"]["damage"] = e2.get("value")
				if mapping.has("amount_stat") and e2.get("stat") == mapping["amount_stat"]:
					status_contract["params"]["amount"] = e2.get("value")
				if mapping.has("duration_stat") and e2.get("stat") == mapping["duration_stat"]:
					status_contract["params"]["duration"] = e2.get("value")
			
			contract["expected_status"].append(status_contract)

func _infer_from_description(item: Dictionary, contract: Dictionary) -> void:
	"""Usa patrones de regex para extraer información adicional de la descripción."""
	var desc = item.get("description", "")
	if desc.is_empty():
		return
	
	# Pattern: "+X stat" o "-X stat"
	var stat_pattern = RegEx.new()
	stat_pattern.compile("([+-]?\\d+(?:\\.\\d+)?)[%]?\\s+([\\w\\s]+)")
	
	var matches = stat_pattern.search_all(desc)
	for m in matches:
		contract["inferred_from_description"].append({
			"value": m.get_string(1),
			"context": m.get_string(2)
		})
	
	# Pattern: Status effects mentioned
	var status_keywords = ["quema", "congela", "ralentiza", "aturde", "sangra", 
						   "burn", "freeze", "slow", "stun", "bleed", "poison"]
	for keyword in status_keywords:
		if keyword in desc.to_lower():
			contract["inferred_from_description"].append({
				"type": "status_mention",
				"status": keyword
			})

func _build_forbidden_list(contract: Dictionary, declared_stats: Array) -> void:
	"""Construye la lista de stats que este item NO debe modificar."""
	
	# Lista de todos los stats posibles
	var all_stats = [
		"max_health", "health_regen", "armor", "dodge_chance", "life_steal",
		"damage_taken_mult", "shield", "thorns",
		"move_speed", "xp_mult", "gold_mult", "luck", "pickup_range",
		"damage_mult", "damage_base", "attack_speed_mult", "cooldown_mult",
		"area_mult", "projectile_count", "pierce", "chain_count",
		"projectile_speed", "duration_mult", "knockback", "range_mult",
		"crit_chance", "crit_damage", "burn_chance", "freeze_chance",
		"bleed_chance", "slow_chance", "stun_chance"
	]
	
	for stat in all_stats:
		if not stat in declared_stats:
			contract["forbidden_effects"].append(stat)
	
	# Si no aplica ningún status, todos los status son prohibidos
	if contract["expected_status"].is_empty():
		contract["forbidden_status"] = ["burn", "freeze", "slow", "stun", "bleed", "poison", "blind", "pull"]

func _infer_conditions(item: Dictionary, contract: Dictionary) -> void:
	"""Infiere condiciones especiales de activación."""
	var desc = item.get("description", "").to_lower()
	
	# Low HP conditions
	if "bajo" in desc and ("hp" in desc or "vida" in desc):
		var threshold_match = RegEx.new()
		threshold_match.compile("(\\d+)[%]")
		var result = threshold_match.search(desc)
		if result:
			contract["conditions"].append({
				"type": "hp_threshold",
				"direction": "below",
				"value": float(result.get_string(1)) / 100.0
			})
	
	# Full HP conditions
	if "máxima" in desc or "completa" in desc or "full" in desc:
		contract["conditions"].append({
			"type": "hp_threshold",
			"direction": "at_max",
			"value": 1.0
		})
	
	# Kill conditions
	if "matar" in desc or "mata" in desc or "kill" in desc:
		contract["conditions"].append({
			"type": "on_kill"
		})

# ═══════════════════════════════════════════════════════════════════════════════
# VALIDACIÓN DE CONTRATOS
# ═══════════════════════════════════════════════════════════════════════════════

func validate_contract(contract: Dictionary, baseline_state: Dictionary, actual_state: Dictionary, 
					   status_data: Dictionary = {}, damage_data: Dictionary = {}) -> Dictionary:
	"""
	Valida que el estado actual cumple EXACTAMENTE con el contrato.
	
	Retorna:
	{
		"passed": bool,
		"result": ValidationResult,
		"violations": [
			{"type": "...", "expected": ..., "actual": ..., "severity": "..."}
		],
		"extra_effects": [...],  # Efectos no declarados detectados
		"summary": "..."
	}
	"""
	var result = {
		"passed": true,
		"result": ValidationResult.PASS,
		"violations": [],
		"extra_effects": [],
		"missing_effects": [],
		"summary": ""
	}
	
	# 1. Validar cada efecto esperado
	for expected in contract["expected_effects"]:
		var check = _validate_single_effect(expected, baseline_state, actual_state)
		if not check["passed"]:
			result["passed"] = false
			result["result"] = ValidationResult.FAIL_VALUE
			result["violations"].append(check)
	
	# 2. Validar status effects esperados
	for expected_status in contract["expected_status"]:
		var check = _validate_status_effect(expected_status, status_data)
		if not check["passed"]:
			result["passed"] = false
			result["result"] = ValidationResult.FAIL_MISSING
			result["missing_effects"].append(check)
	
	# 3. Detectar efectos NO declarados (side effects)
	var extra = _detect_extra_effects(contract, baseline_state, actual_state)
	if not extra.is_empty():
		result["extra_effects"] = extra
		# Solo marcar como fallo si hay cambios significativos
		for e in extra:
			if e.get("severity", "minor") == "major":
				result["passed"] = false
				result["result"] = ValidationResult.FAIL_EXTRA
	
	# 4. Detectar status no declarados
	var extra_status = _detect_extra_status(contract, status_data)
	if not extra_status.is_empty():
		result["extra_effects"].append_array(extra_status)
		result["passed"] = false
		result["result"] = ValidationResult.FAIL_EXTRA
	
	# 5. Validar daño si es weapon/fusion
	if contract["contract_type"] == ContractType.DAMAGE_DEALER:
		var damage_check = _validate_damage(contract, damage_data)
		if not damage_check["passed"]:
			result["passed"] = false
			if damage_check.get("is_zero_damage", false):
				result["result"] = ValidationResult.BUG
			else:
				result["result"] = ValidationResult.FAIL_VALUE
			result["violations"].append(damage_check)
	
	# 6. Generar resumen
	result["summary"] = _generate_summary(result, contract)
	
	return result

func _validate_single_effect(expected: Dictionary, baseline: Dictionary, actual: Dictionary) -> Dictionary:
	"""Valida un único efecto de stat."""
	var stat = expected["stat"]
	var operation = expected["operation"]
	var value = expected["value"]
	var tolerance = expected["tolerance"]
	
	# Mapear stat a keys reales (algunos stats tienen _base, _mult, _final)
	var key_mappings = _get_stat_key_mappings(stat)
	
	var result = {
		"passed": true,
		"stat": stat,
		"operation": operation,
		"expected_value": value,
		"actual_delta": 0.0,
		"reason": "",
		# Standardized keys for ItemTestRunner integration
		"detail": stat,
		"expected": null,
		"actual": null
	}
	
	# Check primary key
	var primary_key = key_mappings.get("primary", stat)
	
	if not actual.has(primary_key):
		# Try fallback keys
		var found = false
		for fallback in key_mappings.get("fallbacks", []):
			if actual.has(fallback):
				primary_key = fallback
				found = true
				break
		
		if not found:
			result["passed"] = false
			result["reason"] = "Stat '%s' not found in actual state" % stat
			return result
	
	var baseline_val = baseline.get(primary_key, 0.0)
	var actual_val = actual.get(primary_key, 0.0)
	
	# Calculate expected final value
	var expected_final = baseline_val
	if operation == "add":
		expected_final = baseline_val + value
	elif operation == "multiply":
		expected_final = baseline_val * value
	elif operation == "set":
		expected_final = value
	
	# Calculate delta
	var delta = abs(actual_val - expected_final)
	var delta_percent = 0.0
	if expected_final != 0:
		delta_percent = delta / abs(expected_final)
	
	result["baseline"] = baseline_val
	result["expected_final"] = expected_final
	result["actual"] = actual_val
	result["actual_delta"] = delta
	result["delta_percent"] = delta_percent
	
	# Check tolerance
	if operation == "add" or operation == "set":
		if delta > tolerance:
			result["passed"] = false
			result["reason"] = "Value mismatch: expected %.3f, got %.3f (delta %.3f > tol %.3f)" % [
				expected_final, actual_val, delta, tolerance
			]
			result["detail"] = "%s (%s)" % [stat, operation]
			result["expected"] = expected_final
			result["actual"] = actual_val
	else:  # multiply
		if delta_percent > tolerance:
			result["passed"] = false
			result["reason"] = "Multiplier mismatch: expected %.3f, got %.3f (delta %.1f%% > tol %.1f%%)" % [
				expected_final, actual_val, delta_percent * 100, tolerance * 100
			]
			result["detail"] = "%s (mult)" % stat
			result["expected"] = expected_final
			result["actual"] = actual_val
	
	return result

func _validate_status_effect(expected_status: Dictionary, status_data: Dictionary) -> Dictionary:
	"""Valida que un status effect se aplicó correctamente."""
	var status_name = expected_status["status"]
	var expected_chance = expected_status.get("chance", 1.0)
	var expected_params = expected_status.get("params", {})
	
	var result = {
		"passed": true,
		"status": status_name,
		"expected_chance": expected_chance,
		"expected_params": expected_params,
		"reason": "",
		# Standardized keys for ItemTestRunner integration
		"detail": "status_%s" % status_name,
		"expected": "applied",
		"actual": "not_applied"
	}
	
	# Check if status was tracked
	var found_instances = 0
	var param_mismatches = []
	
	for enemy_id in status_data:
		var enemy_statuses = status_data[enemy_id]
		if enemy_statuses.has(status_name):
			found_instances += 1
			var actual_data = enemy_statuses[status_name]
			
			# Validate params
			for param_key in expected_params:
				var expected_val = expected_params[param_key]
				var actual_val = actual_data.get("params", {}).get(param_key, 0)
				
				if abs(actual_val - expected_val) > 0.1:
					param_mismatches.append("%s: expected %.2f, got %.2f" % [param_key, expected_val, actual_val])
	
	if found_instances == 0 and expected_chance >= 1.0:
		result["passed"] = false
		result["reason"] = "Status '%s' was expected but never applied" % status_name
		result["actual"] = "not_applied (0 instances)"
	elif not param_mismatches.is_empty():
		result["passed"] = false
		result["reason"] = "Status '%s' param mismatches: %s" % [status_name, ", ".join(param_mismatches)]
		result["expected"] = str(expected_params)
		result["actual"] = "mismatched: %s" % ", ".join(param_mismatches)
	else:
		result["actual"] = "applied (%d instances)" % found_instances
	
	return result

func _detect_extra_effects(contract: Dictionary, baseline: Dictionary, actual: Dictionary) -> Array:
	"""Detecta cambios en stats que no están declarados en el contrato."""
	var extras = []
	var forbidden = contract["forbidden_effects"]
	
	for stat in forbidden:
		var key_mappings = _get_stat_key_mappings(stat)
		var primary_key = key_mappings.get("primary", stat)
		
		if not baseline.has(primary_key) or not actual.has(primary_key):
			continue
		
		var baseline_val = baseline[primary_key]
		var actual_val = actual[primary_key]
		var delta = abs(actual_val - baseline_val)
		
		# Check if there's a meaningful change
		if delta > TOLERANCE_ADDITIVE:
			var severity = "minor"
			# Major if the change is > 5% or absolute > 1
			if baseline_val != 0 and delta / abs(baseline_val) > 0.05:
				severity = "major"
			if delta > 1.0:
				severity = "major"
			
			extras.append({
				"type": "undeclared_stat_change",
				"stat": stat,
				"baseline": baseline_val,
				"actual": actual_val,
				"delta": delta,
				"severity": severity
			})
	
	return extras

func _detect_extra_status(contract: Dictionary, status_data: Dictionary) -> Array:
	"""Detecta status effects aplicados que no están declarados."""
	var extras = []
	var forbidden = contract["forbidden_status"]
	var expected_statuses = []
	
	for es in contract["expected_status"]:
		expected_statuses.append(es["status"])
	
	for enemy_id in status_data:
		for status_name in status_data[enemy_id]:
			if status_name in forbidden and not status_name in expected_statuses:
				extras.append({
					"type": "undeclared_status",
					"status": status_name,
					"enemy_id": enemy_id,
					"severity": "major"
				})
	
	return extras

func _validate_damage(contract: Dictionary, damage_data: Dictionary) -> Dictionary:
	"""Valida que un arma/fusión hace el daño esperado."""
	var expected = damage_data.get("expected", 0)
	var actual = damage_data.get("actual", 0)
	
	var result = {
		"passed": true,
		"expected_damage": expected,
		"actual_damage": actual,
		"reason": "",
		# Standardized keys for ItemTestRunner integration
		"detail": "damage_dealt",
		"expected": expected,
		"actual": actual
	}
	
	if expected == 0:
		result["passed"] = true  # No damage expected
		return result
	
	if actual == 0 and expected > 0:
		result["passed"] = false
		result["is_zero_damage"] = true
		result["reason"] = "Zero damage dealt when %.1f expected - CRITICAL BUG" % expected
		result["detail"] = "damage_zero"
		return result
	
	var delta_percent = abs(actual - expected) / expected
	
	if delta_percent > TOLERANCE_DAMAGE:
		result["passed"] = false
		result["delta_percent"] = delta_percent
		result["reason"] = "Damage mismatch: expected %.1f, got %.1f (delta %.1f%%)" % [
			expected, actual, delta_percent * 100
		]
		result["detail"] = "damage_mismatch (%.1f%%)" % (delta_percent * 100)
	
	return result

func _get_stat_key_mappings(stat: String) -> Dictionary:
	"""Mapea nombres de stats a sus keys en el sistema."""
	var mappings = {
		"max_health": {"primary": "max_health", "fallbacks": ["max_hp", "health_max"]},
		"health_regen": {"primary": "health_regen", "fallbacks": ["hp_regen", "regen"]},
		"damage_mult": {"primary": "damage_mult", "fallbacks": ["damage_multiplier"]},
		"damage_base": {"primary": "damage_base", "fallbacks": ["base_damage"]},
		"move_speed": {"primary": "move_speed", "fallbacks": ["speed", "movement_speed"]},
		"attack_speed_mult": {"primary": "attack_speed_mult", "fallbacks": ["attack_speed"]},
		"cooldown_mult": {"primary": "cooldown_mult", "fallbacks": ["cooldown_reduction"]},
		"area_mult": {"primary": "area_mult", "fallbacks": ["area_multiplier"]},
		"projectile_count": {"primary": "projectile_count_final", "fallbacks": ["projectile_count"]},
		"pierce": {"primary": "pierce_final", "fallbacks": ["pierce"]},
		"crit_chance": {"primary": "crit_chance", "fallbacks": ["critical_chance"]},
		"crit_damage": {"primary": "crit_damage", "fallbacks": ["critical_damage"]}
	}
	
	return mappings.get(stat, {"primary": stat, "fallbacks": []})

func _generate_summary(result: Dictionary, contract: Dictionary) -> String:
	"""Genera un resumen legible del resultado de validación."""
	var item_id = contract["item_id"]
	
	if result["passed"]:
		return "✅ [%s] Contract PASSED - All effects validated" % item_id
	
	var issues = []
	
	if not result["violations"].is_empty():
		issues.append("%d value violations" % result["violations"].size())
	
	if not result["missing_effects"].is_empty():
		issues.append("%d missing effects" % result["missing_effects"].size())
	
	if not result["extra_effects"].is_empty():
		var major_count = 0
		for e in result["extra_effects"]:
			if e.get("severity") == "major":
				major_count += 1
		if major_count > 0:
			issues.append("%d undeclared side effects" % major_count)
	
	var result_name = ValidationResult.keys()[result["result"]]
	return "❌ [%s] Contract FAILED (%s): %s" % [item_id, result_name, ", ".join(issues)]

# ═══════════════════════════════════════════════════════════════════════════════
# UTILIDADES
# ═══════════════════════════════════════════════════════════════════════════════

func clear_cache() -> void:
	_inferred_contracts.clear()

func get_contract_for_item(item_id: String) -> Dictionary:
	return _inferred_contracts.get(item_id, {})

func get_all_contracts() -> Dictionary:
	return _inferred_contracts.duplicate()

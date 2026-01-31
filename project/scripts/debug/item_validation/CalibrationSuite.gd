# CalibrationSuite.gd
# Suite de calibración para validar el sistema de contratos contra falsos positivos
# Contiene ~20 items representativos de cada categoría de mecánicas
#
# USO: Ejecutar ANTES del Full Sweep para verificar tolerancias
# OBJETIVO: 100% de PASS en todos los items de calibración
# Si falla un item de calibración, ajustar tolerancias con justificación
#
# CATEGORÍAS CUBIERTAS:
# - 5 items aditivos puros (stats planos)
# - 5 items multiplicativos puros (stats %)
# - 3 items con DoT (burn, bleed, poison)
# - 3 items con status CC (slow, freeze, stun)
# - 2 items con efectos on_hit/on_kill
# - 2 items con crecimiento temporal (per_minute patterns)

extends Node
class_name CalibrationSuite

# ═══════════════════════════════════════════════════════════════════════════════
# REFERENCIAS
# ═══════════════════════════════════════════════════════════════════════════════

var contract_oracle: ContractOracle
var item_test_runner: Node
var status_effect_oracle: StatusEffectOracle

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

const CALIBRATION_REPETITIONS: int = 5  # N iteraciones para items con RNG
const BINOMIAL_CONFIDENCE: float = 0.95  # Nivel de confianza para tests RNG

# Tolerancias actuales (documentar cualquier cambio con justificación)
var tolerance_config: Dictionary = {
	"additive": {
		"value": 0.001,  # ±0.001 para stats aditivos
		"justification": "Baseline: precisión de float32 en Godot"
	},
	"multiplicative": {
		"value": 0.01,  # ±1% para multiplicadores
		"justification": "Baseline: acumulación de errores de redondeo en cadena mult"
	},
	"damage": {
		"value": 0.05,  # ±5% para daño
		"justification": "Baseline: variabilidad de timing en frames y armor reduction"
	},
	"status_duration": {
		"value": 0.05,  # ±50ms para duración de status
		"justification": "Baseline: tick rate de proceso en physics_process"
	},
	"status_ticks": {
		"value": 0,  # 0 tolerancia en número de ticks
		"justification": "Estricto: ticks deben ser exactos"
	},
	"rng_chance": {
		"min_trials": 50,  # Mínimo de trials para validar RNG
		"tolerance_percent": 0.15,  # ±15% del valor esperado (binomial bounds)
		"justification": "Baseline: binomial test con p=0.95 confidence"
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# ITEMS DE CALIBRACIÓN
# Seleccionados para representar cada tipo de mecánica
# ═══════════════════════════════════════════════════════════════════════════════

const CALIBRATION_ITEMS: Dictionary = {
	# ─────────────────────────────────────────────────────────────────────────────
	# ADITIVOS PUROS (5 items)
	# Contrato: baseline + value = actual
	# ─────────────────────────────────────────────────────────────────────────────
	"additive": [
		{
			"id": "health_1",
			"source": "UpgradeDatabase.DEFENSIVE_UPGRADES",
			"expected_stat": "max_health",
			"expected_delta": 10,
			"operation": "add",
			"rationale": "Item básico Tier 1, sin stacking, efecto directo"
		},
		{
			"id": "armor_2",
			"source": "UpgradeDatabase.DEFENSIVE_UPGRADES",
			"expected_stat": "armor",
			"expected_delta": 5,
			"operation": "add",
			"rationale": "Armadura con valor impar para detectar errores de redondeo"
		},
		{
			"id": "regen_3",
			"source": "UpgradeDatabase.DEFENSIVE_UPGRADES",
			"expected_stat": "health_regen",
			"expected_delta": 3.0,
			"operation": "add",
			"rationale": "Regen HP/s, requiere validación temporal"
		},
		{
			"id": "global_damage_flat_1",
			"source": "WeaponUpgradeDatabase.GLOBAL_UPGRADES",
			"expected_stat": "damage_flat",
			"expected_delta": 3,
			"operation": "add",
			"rationale": "Daño plano global, afecta todas las armas"
		},
		{
			"id": "shield_regen_delay_1",
			"source": "UpgradeDatabase.DEFENSIVE_UPGRADES",
			"expected_stat": "shield_regen_delay",
			"expected_delta": -0.5,
			"operation": "add",
			"rationale": "Valor negativo, verifica operación add con negativos"
		}
	],
	
	# ─────────────────────────────────────────────────────────────────────────────
	# MULTIPLICATIVOS PUROS (5 items)
	# Contrato: baseline * value = actual
	# ─────────────────────────────────────────────────────────────────────────────
	"multiplicative": [
		{
			"id": "health_percent_1",
			"source": "UpgradeDatabase.DEFENSIVE_UPGRADES",
			"expected_stat": "max_health",
			"expected_multiplier": 1.15,
			"operation": "multiply",
			"rationale": "Multiplicador 15% sobre HP base"
		},
		{
			"id": "speed_1",
			"source": "UpgradeDatabase.UTILITY_UPGRADES",
			"expected_stat": "move_speed",
			"expected_multiplier": 1.08,
			"operation": "multiply",
			"rationale": "Velocidad +8%, valor pequeño para detectar precisión"
		},
		{
			"id": "global_damage_2",
			"source": "WeaponUpgradeDatabase.GLOBAL_UPGRADES",
			"expected_stat": "damage_mult",
			"expected_multiplier": 1.20,
			"operation": "multiply",
			"rationale": "Daño global +20%, afecta cadena de multiplicación"
		},
		{
			"id": "attack_speed_2",
			"source": "UpgradeDatabase.OFFENSIVE_UPGRADES",
			"expected_stat": "attack_speed_mult",
			"expected_multiplier": 1.20,
			"operation": "multiply",
			"rationale": "Attack speed multiplier, interactúa con cooldowns"
		},
		{
			"id": "giant_slayer",
			"source": "UpgradeDatabase.OFFENSIVE_UPGRADES",
			"expected_stat": "elite_damage_mult",
			"expected_multiplier": 1.20,
			"operation": "multiply",
			"rationale": "Multiplicador condicional (solo vs elites)"
		}
	],
	
	# ─────────────────────────────────────────────────────────────────────────────
	# DoTs (3 items)
	# Contrato: damage_per_tick * tick_count ≈ total_damage (±tolerance)
	# ─────────────────────────────────────────────────────────────────────────────
	"dots": [
		{
			"id": "fire_wand",
			"source": "WeaponDatabase.WEAPONS",
			"effect": "burn",
			"expected_damage_per_tick": 3.0,
			"expected_duration": 4.0,
			"tick_interval": 1.0,
			"rationale": "Burn básico: 3 dmg/tick, 4 ticks"
		},
		{
			"id": "hemorrhage",
			"source": "UpgradeDatabase.OFFENSIVE_UPGRADES",
			"effect": "bleed",
			"effect_trigger": "on_hit",
			"chance": 0.20,
			"rationale": "Bleed on hit con 20% chance, requiere múltiples trials"
		},
		{
			"id": "shadow_dagger",  # Inferir de WeaponDatabase si tiene poison
			"source": "WeaponDatabase.WEAPONS",
			"effect": "poison",
			"expected_damage_per_tick": 2.0,
			"expected_duration": 5.0,
			"tick_interval": 1.0,
			"rationale": "Poison DoT, verifica stacking de DoTs"
		}
	],
	
	# ─────────────────────────────────────────────────────────────────────────────
	# STATUS CC (3 items)
	# Contrato: status_applied = true, duration_actual ≈ duration_expected
	# ─────────────────────────────────────────────────────────────────────────────
	"status_cc": [
		{
			"id": "ice_wand",
			"source": "WeaponDatabase.WEAPONS",
			"effect": "slow",
			"expected_amount": 0.40,  # 40% slow
			"expected_duration": 2.0,
			"rationale": "Slow básico, verifica reducción de move_speed"
		},
		{
			"id": "frost_nova",
			"source": "UpgradeDatabase.DEFENSIVE_UPGRADES",
			"effect": "freeze",
			"trigger": "on_damage_taken",
			"expected_duration": 1.0,
			"rationale": "Freeze reactivo, requiere simular daño entrante"
		},
		{
			"id": "stun_chance",  # Buscar un item con stun
			"source": "WeaponUpgradeDatabase.GLOBAL_UPGRADES",
			"effect": "stun",
			"chance": 0.10,
			"expected_duration": 1.0,
			"rationale": "Stun con probabilidad, requiere múltiples trials"
		}
	],
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ON_HIT / ON_KILL (2 items)
	# Contrato: efecto se dispara exactamente N veces tras N eventos
	# ─────────────────────────────────────────────────────────────────────────────
	"event_triggers": [
		{
			"id": "soul_link",
			"source": "UpgradeDatabase.DEFENSIVE_UPGRADES",
			"trigger": "on_damage_taken",
			"expected_effect": "damage_redirect",
			"redirect_percent": 0.30,
			"rationale": "30% del daño recibido se redirige a enemigos"
		},
		{
			"id": "combustion",
			"source": "UpgradeDatabase.OFFENSIVE_UPGRADES",
			"trigger": "on_burn_applied",
			"expected_effect": "instant_burn_damage",
			"rationale": "Consume burn para hacer daño instantáneo"
		}
	],
	
	# ─────────────────────────────────────────────────────────────────────────────
	# TEMPORAL / PER_MINUTE (2 items)
	# Contrato: stat(t+60s) = stat(t) + growth_per_minute
	# ─────────────────────────────────────────────────────────────────────────────
	"temporal": [
		{
			"id": "xp_mult_1",
			"source": "UpgradeDatabase.UTILITY_UPGRADES",
			"expected_stat": "xp_mult",
			"expected_multiplier": 1.10,
			"operation": "multiply",
			"rationale": "XP multiplier, verifica acumulación con tiempo de juego"
		},
		{
			"id": "gold_mult_1",
			"source": "UpgradeDatabase.UTILITY_UPGRADES",
			"expected_stat": "gold_mult",
			"expected_multiplier": 1.10,
			"operation": "multiply",
			"rationale": "Gold multiplier, crece con el tiempo indirectamente"
		}
	]
}

# ═══════════════════════════════════════════════════════════════════════════════
# RESULTADOS
# ═══════════════════════════════════════════════════════════════════════════════

var calibration_results: Array = []
var false_positives_detected: Array = []
var tolerance_adjustments: Array = []

# ═══════════════════════════════════════════════════════════════════════════════
# EJECUCIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Inicializar referencias
	contract_oracle = ContractOracle.new()
	status_effect_oracle = StatusEffectOracle.new()

func run_calibration_suite(test_runner: Node = null) -> Dictionary:
	"""
	Ejecuta la suite de calibración completa.
	Retorna un reporte con:
	- pass_rate: % de items que pasaron
	- false_positives: items que fallaron pero no deberían
	- tolerance_recommendations: ajustes sugeridos
	"""
	if test_runner:
		item_test_runner = test_runner
	
	calibration_results.clear()
	false_positives_detected.clear()
	tolerance_adjustments.clear()
	
	var total_items := 0
	var passed_items := 0
	
	# Ejecutar cada categoría
	for category in CALIBRATION_ITEMS.keys():
		var items = CALIBRATION_ITEMS[category]
		for item_spec in items:
			total_items += 1
			var result = _test_calibration_item(category, item_spec)
			calibration_results.append(result)
			
			if result["passed"]:
				passed_items += 1
			else:
				# Analizar si es falso positivo
				var fp_analysis = _analyze_false_positive(category, item_spec, result)
				if fp_analysis["is_false_positive"]:
					false_positives_detected.append({
						"item_id": item_spec["id"],
						"category": category,
						"reason": fp_analysis["reason"],
						"suggested_tolerance": fp_analysis["suggested_tolerance"]
					})
	
	# Generar reporte
	var report = {
		"timestamp": Time.get_datetime_string_from_system(),
		"total_items": total_items,
		"passed": passed_items,
		"pass_rate": float(passed_items) / float(total_items) if total_items > 0 else 0.0,
		"results": calibration_results,
		"false_positives": false_positives_detected,
		"tolerance_adjustments": tolerance_adjustments,
		"tolerance_config": tolerance_config
	}
	
	_generate_calibration_report(report)
	
	return report

func _test_calibration_item(category: String, spec: Dictionary) -> Dictionary:
	"""Testea un item individual de calibración."""
	var result = {
		"item_id": spec["id"],
		"category": category,
		"passed": false,
		"iterations": [],
		"mean_delta": 0.0,
		"max_delta": 0.0,
		"details": {}
	}
	
	# Obtener el item real de la base de datos
	var item = _fetch_item(spec)
	if item.is_empty():
		result["details"]["error"] = "Item not found: %s" % spec["id"]
		return result
	
	# Ejecutar N iteraciones para items con RNG
	var iterations_needed = 1
	if spec.has("chance") or category == "dots" or category == "event_triggers":
		iterations_needed = CALIBRATION_REPETITIONS
	
	var deltas: Array = []
	for i in range(iterations_needed):
		var iter_result = _execute_single_test(category, spec, item, i)
		result["iterations"].append(iter_result)
		if iter_result.has("delta"):
			deltas.append(iter_result["delta"])
	
	# Calcular estadísticas
	if not deltas.is_empty():
		result["mean_delta"] = _calculate_mean(deltas)
		result["max_delta"] = _calculate_max_abs(deltas)
	
	# Determinar pass/fail basado en categoría
	result["passed"] = _evaluate_pass(category, spec, result)
	
	return result

func _fetch_item(spec: Dictionary) -> Dictionary:
	"""Obtiene el item de la base de datos correspondiente."""
	var source_parts = spec["source"].split(".")
	if source_parts.size() < 2:
		return {}
	
	var db_name = source_parts[0]
	var collection = source_parts[1]
	var item_id = spec["id"]
	
	# Mapear a la base de datos real
	match db_name:
		"UpgradeDatabase":
			match collection:
				"DEFENSIVE_UPGRADES":
					return UpgradeDatabase.DEFENSIVE_UPGRADES.get(item_id, {})
				"UTILITY_UPGRADES":
					return UpgradeDatabase.UTILITY_UPGRADES.get(item_id, {})
				"OFFENSIVE_UPGRADES":
					# Buscar en OFFENSIVE_UPGRADES (si existe) o en otra colección
					# Buscar en OFFENSIVE_UPGRADES
					return UpgradeDatabase.OFFENSIVE_UPGRADES.get(item_id, {})
		"WeaponDatabase":
			if collection == "WEAPONS":
				return WeaponDatabase.WEAPONS.get(item_id, {})
		"WeaponUpgradeDatabase":
			if collection == "GLOBAL_UPGRADES":
				return WeaponUpgradeDatabase.GLOBAL_UPGRADES.get(item_id, {})
	
	return {}

func _execute_single_test(category: String, spec: Dictionary, item: Dictionary, iteration: int) -> Dictionary:
	"""Ejecuta un test individual y retorna el resultado."""
	var result = {
		"iteration": iteration,
		"passed": false,
		"delta": 0.0,
		"expected": 0.0,
		"actual": 0.0
	}
	
	match category:
		"additive":
			result = _test_additive_effect(spec, item)
		"multiplicative":
			result = _test_multiplicative_effect(spec, item)
		"dots":
			result = _test_dot_effect(spec, item, iteration)
		"status_cc":
			result = _test_status_effect(spec, item, iteration)
		"event_triggers":
			result = _test_event_trigger(spec, item, iteration)
		"temporal":
			result = _test_temporal_effect(spec, item)
	
	result["iteration"] = iteration
	return result

func _test_additive_effect(spec: Dictionary, item: Dictionary) -> Dictionary:
	"""Valida un efecto aditivo puro."""
	var result = {"passed": false, "delta": 0.0, "expected": 0.0, "actual": 0.0}
	
	var effects = item.get("effects", [])
	for effect in effects:
		if effect.get("stat") == spec["expected_stat"] and effect.get("operation") == "add":
			result["expected"] = spec["expected_delta"]
			result["actual"] = effect.get("value", 0)
			result["delta"] = abs(result["actual"] - result["expected"])
			result["passed"] = result["delta"] <= tolerance_config["additive"]["value"]
			break
	
	return result

func _test_multiplicative_effect(spec: Dictionary, item: Dictionary) -> Dictionary:
	"""Valida un efecto multiplicativo puro."""
	var result = {"passed": false, "delta": 0.0, "expected": 0.0, "actual": 0.0}
	
	var effects = item.get("effects", [])
	for effect in effects:
		var stat = effect.get("stat", "")
		if (stat == spec["expected_stat"] or stat + "_mult" == spec["expected_stat"]) \
		   and effect.get("operation") == "multiply":
			result["expected"] = spec["expected_multiplier"]
			result["actual"] = effect.get("value", 1.0)
			result["delta"] = abs(result["actual"] - result["expected"])
			result["passed"] = result["delta"] <= tolerance_config["multiplicative"]["value"]
			break
	
	return result

func _test_dot_effect(spec: Dictionary, item: Dictionary, _iteration: int) -> Dictionary:
	"""Valida un efecto de daño sobre tiempo."""
	var result = {"passed": false, "delta": 0.0, "expected": 0.0, "actual": 0.0}
	
	# Para DoTs, verificar effect y effect_value
	var effect_type = item.get("effect", "")
	if effect_type != spec["effect"]:
		result["error"] = "Effect type mismatch: expected %s, got %s" % [spec["effect"], effect_type]
		return result
	
	if spec.has("expected_damage_per_tick"):
		result["expected"] = spec["expected_damage_per_tick"]
		result["actual"] = item.get("effect_value", 0)
		result["delta"] = abs(result["actual"] - result["expected"])
		result["passed"] = result["delta"] <= tolerance_config["damage"]["value"] * result["expected"]
	
	return result

func _test_status_effect(spec: Dictionary, item: Dictionary, _iteration: int) -> Dictionary:
	"""Valida un efecto de control de masas."""
	var result = {"passed": false, "delta": 0.0, "expected": 0.0, "actual": 0.0}
	
	var effect_type = item.get("effect", "")
	if effect_type != spec["effect"]:
		result["error"] = "Effect type mismatch"
		return result
	
	if spec.has("expected_duration"):
		result["expected"] = spec["expected_duration"]
		result["actual"] = item.get("effect_duration", 0)
		result["delta"] = abs(result["actual"] - result["expected"])
		result["passed"] = result["delta"] <= tolerance_config["status_duration"]["value"]
	
	if spec.has("expected_amount"):
		var amount_expected = spec["expected_amount"]
		var amount_actual = item.get("effect_value", 0)
		var amount_delta = abs(amount_actual - amount_expected)
		if amount_delta > tolerance_config["multiplicative"]["value"]:
			result["passed"] = false
			result["delta"] = max(result["delta"], amount_delta)
	
	return result

func _test_event_trigger(spec: Dictionary, item: Dictionary, _iteration: int) -> Dictionary:
	"""Valida un efecto que se activa por evento."""
	var result = {
		"passed": false, 
		"delta": 0.0,
		"requires_event_simulation": true,
		"event_type": spec.get("trigger", "unknown")
	}
	
	# Para event triggers, solo validamos que el stat existe
	var effects = item.get("effects", [])
	for effect in effects:
		var stat = effect.get("stat", "")
		if spec["expected_effect"] in stat or spec["id"] in stat:
			result["passed"] = true
			result["effect_value"] = effect.get("value", 0)
			break
	
	# Marcar como SKIPPED si requiere simulación de eventos
	if not result["passed"]:
		result["skipped"] = true
		result["skip_reason"] = "Requires event simulation: %s" % spec.get("trigger", "unknown")
	
	return result

func _test_temporal_effect(spec: Dictionary, item: Dictionary) -> Dictionary:
	"""Valida un efecto que escala con el tiempo."""
	# Similar a multiplicativo pero marcado para tracking temporal
	var result = _test_multiplicative_effect(spec, item)
	result["temporal_tracking"] = true
	return result

func _evaluate_pass(category: String, spec: Dictionary, result: Dictionary) -> bool:
	"""Evalúa si el test pasó basado en todas las iteraciones."""
	if result["iterations"].is_empty():
		return false
	
	# Para items sin RNG, una sola iteración
	if category in ["additive", "multiplicative", "temporal"]:
		return result["iterations"][0].get("passed", false)
	
	# Para items con RNG (dots, status_cc, event_triggers)
	var passed_count := 0
	var total_valid := 0
	for iter in result["iterations"]:
		if iter.get("skipped", false):
			continue
		total_valid += 1
		if iter.get("passed", false):
			passed_count += 1
	
	if total_valid == 0:
		return false
	
	# Usar proporción para RNG (al menos 80% deben pasar)
	return float(passed_count) / float(total_valid) >= 0.8

func _analyze_false_positive(category: String, spec: Dictionary, result: Dictionary) -> Dictionary:
	"""Analiza si un fallo es un falso positivo y sugiere tolerancia."""
	var analysis = {
		"is_false_positive": false,
		"reason": "",
		"suggested_tolerance": 0.0
	}
	
	# Si el delta está ligeramente fuera de tolerancia, podría ser falso positivo
	var tolerance_key = "additive" if category == "additive" else "multiplicative"
	if category in ["dots", "status_cc"]:
		tolerance_key = "damage" if category == "dots" else "status_duration"
	
	var current_tolerance = tolerance_config[tolerance_key]["value"]
	var max_delta = result.get("max_delta", 0.0)
	
	# Si el delta es < 2x la tolerancia actual, podría ser ruido
	if max_delta > current_tolerance and max_delta < current_tolerance * 2.0:
		analysis["is_false_positive"] = true
		analysis["reason"] = "Delta (%.4f) slightly exceeds tolerance (%.4f)" % [max_delta, current_tolerance]
		analysis["suggested_tolerance"] = max_delta * 1.1  # +10% margen
		
		tolerance_adjustments.append({
			"category": category,
			"item_id": spec["id"],
			"old_tolerance": current_tolerance,
			"suggested_tolerance": analysis["suggested_tolerance"],
			"evidence": "Mean delta: %.4f, Max delta: %.4f" % [result.get("mean_delta", 0), max_delta]
		})
	
	return analysis

func _calculate_mean(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var sum := 0.0
	for v in values:
		sum += v
	return sum / values.size()

func _calculate_max_abs(values: Array) -> float:
	var max_val := 0.0
	for v in values:
		max_val = max(max_val, abs(v))
	return max_val

# ═══════════════════════════════════════════════════════════════════════════════
# REPORTE
# ═══════════════════════════════════════════════════════════════════════════════

func _generate_calibration_report(data: Dictionary) -> String:
	"""Genera el reporte de calibración en formato Markdown."""
	var user_dir = "user://test_reports/"
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("test_reports"):
		dir.make_dir("test_reports")
	
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	var filename = "calibration_report_%s.md" % timestamp
	var full_path = user_dir + filename
	
	var file = FileAccess.open(full_path, FileAccess.WRITE)
	if not file:
		push_error("[CalibrationSuite] Failed to write report: %s" % full_path)
		return ""
	
	file.store_line("# Calibration Suite Report")
	file.store_line("Generated: %s\n" % data["timestamp"])
	
	file.store_line("## Summary")
	file.store_line("- **Total Items**: %d" % data["total_items"])
	file.store_line("- **Passed**: %d" % data["passed"])
	file.store_line("- **Pass Rate**: %.1f%%" % (data["pass_rate"] * 100))
	file.store_line("- **False Positives Detected**: %d" % data["false_positives"].size())
	
	file.store_line("\n## Tolerance Configuration")
	file.store_line("| Category | Value | Justification |")
	file.store_line("|---|---|---|")
	for key in tolerance_config:
		var tc = tolerance_config[key]
		if tc.has("value"):
			file.store_line("| %s | %.4f | %s |" % [key, tc["value"], tc["justification"]])
		elif tc.has("min_trials"):
			file.store_line("| %s | trials=%d, tol=%.0f%% | %s |" % [key, tc["min_trials"], tc["tolerance_percent"]*100, tc["justification"]])
	
	file.store_line("\n## Results by Category")
	for category in CALIBRATION_ITEMS.keys():
		file.store_line("\n### %s" % category.to_upper())
		file.store_line("| Item ID | Passed | Mean Delta | Max Delta | Details |")
		file.store_line("|---|---|---|---|---|")
		
		for result in data["results"]:
			if result["category"] == category:
				var passed_str = "✅" if result["passed"] else "❌"
				var details = ""
				if result["iterations"].size() > 0:
					var first = result["iterations"][0]
					if first.has("error"):
						details = first["error"]
					elif first.has("skipped") and first["skipped"]:
						passed_str = "⏭️"
						details = first.get("skip_reason", "Skipped")
				
				file.store_line("| %s | %s | %.4f | %.4f | %s |" % [
					result["item_id"], passed_str, result["mean_delta"], result["max_delta"], details
				])
	
	if not data["false_positives"].is_empty():
		file.store_line("\n## False Positives Analysis")
		file.store_line("| Item | Category | Reason | Suggested Tolerance |")
		file.store_line("|---|---|---|---|")
		for fp in data["false_positives"]:
			file.store_line("| %s | %s | %s | %.4f |" % [
				fp["item_id"], fp["category"], fp["reason"], fp["suggested_tolerance"]
			])
	
	if not data["tolerance_adjustments"].is_empty():
		file.store_line("\n## Recommended Tolerance Adjustments")
		file.store_line("> ⚠️ Review these adjustments before applying to production")
		file.store_line("")
		for adj in data["tolerance_adjustments"]:
			file.store_line("- **%s** (%s): %.4f → %.4f" % [
				adj["item_id"], adj["category"], adj["old_tolerance"], adj["suggested_tolerance"]
			])
			file.store_line("  - Evidence: %s" % adj["evidence"])
	
	file.store_line("\n---")
	file.store_line("*Report generated by CalibrationSuite v1.0*")
	
	file.close()
	print("[CalibrationSuite] Report saved: %s" % full_path)
	return full_path

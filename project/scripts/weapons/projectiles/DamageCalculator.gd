# DamageCalculator.gd
# Utilidad centralizada para cálculo de daño y modificadores
# Evita duplicación de lógica entre diferentes tipos de proyectiles

class_name DamageCalculator

## Resultado de un cálculo de daño
class DamageResult:
	var base_damage: float = 0.0
	var final_damage: float = 0.0
	var pre_roulette_damage: float = 0.0  ## Daño antes de Russian Roulette (para Combustión)
	var is_crit: bool = false
	var russian_roulette_triggered: bool = false
	var bonus_applied: Array[String] = []

	func get_int_damage() -> int:
		return int(final_damage)

## Calcular daño final aplicando todos los modificadores
## Debe llamarse desde cualquier sistema que aplique daño (proyectiles, orbitales, cadenas, etc.)
## attacker: Nodo que causa el daño (proyectil, beam, etc.) — opcional, usado para weapon_id en audit
static func calculate_final_damage(
	base_damage: float,
	target: Node2D,
	player: Node2D,
	crit_chance: float = 0.0,
	crit_damage: float = 2.0,
	attacker: Node = null
) -> DamageResult:
	var result = DamageResult.new()
	result.base_damage = base_damage
	result.final_damage = base_damage

	if not is_instance_valid(target):
		return result

	# Player puede ser null (ej: tests sintéticos), pero stats pueden venir del group "player_stats"
	var tree = null
	if is_instance_valid(player):
		tree = player.get_tree()
	elif is_instance_valid(target):
		tree = target.get_tree()

	if not tree:
		return result

	# Obtener PlayerStats
	var ps = tree.get_first_node_in_group("player_stats")

	# 1. Bonificadores de distancia
	var player_to_enemy_distance = 0.0
	if is_instance_valid(player):
		player_to_enemy_distance = player.global_position.distance_to(target.global_position)

	if ps and ps.has_method("get_stat"):
		# Brawler: +daño si enemigo cerca (< 150 del jugador)
		var brawler_val = ps.get_stat("close_range_damage_bonus")
		if brawler_val > 0 and player_to_enemy_distance < 150:
			result.final_damage *= (1.0 + brawler_val)
			result.bonus_applied.append("brawler")

		# Sharpshooter: +daño si enemigo lejos (> 300 del jugador)
		var sharpshooter_val = ps.get_stat("long_range_damage_bonus")
		if sharpshooter_val > 0 and player_to_enemy_distance > 300:
			result.final_damage *= (1.0 + sharpshooter_val)
			result.bonus_applied.append("sharpshooter")

		# Executioner: +daño si enemigo Low HP (< 30%)
		var executioner_val = ps.get_stat("low_hp_damage_bonus")
		if executioner_val > 0:
			var hp_pct = _get_enemy_health_percent(target)
			if hp_pct < 0.30:
				result.final_damage *= (1.0 + executioner_val)
				result.bonus_applied.append("executioner")

		# Confianza Plena: +daño si el JUGADOR tiene HP máximo
		var full_hp_val = ps.get_stat("full_hp_damage_bonus")
		if full_hp_val > 0:
			var player_hp_pct = ps.get_health_percent() if ps.has_method("get_health_percent") else 0.0
			if player_hp_pct >= 1.0:
				result.final_damage *= (1.0 + full_hp_val)
				result.bonus_applied.append("full_hp")

	# 2. Bonus vs élites
	result.final_damage = _apply_elite_bonus(result.final_damage, target, ps)

	# 2.5 Bonus condicionales (Status Effects) - Migrado de ProjectileFactory
	if ps and ps.has_method("get_stat"):
		var cond_mult = 1.0

		# VS SLOWED
		var damage_vs_slowed = ps.get_stat("damage_vs_slowed")
		if damage_vs_slowed > 0:
			# Check internal property or method
			if ("_is_slowed" in target and target._is_slowed) or (target.has_method("is_slowed") and target.is_slowed()):
				cond_mult += damage_vs_slowed
				result.bonus_applied.append("vs_slowed")

		# VS BURNING
		var damage_vs_burning = ps.get_stat("damage_vs_burning")
		if damage_vs_burning > 0:
			if ("_is_burning" in target and target._is_burning) or (target.has_method("is_burning") and target.is_burning()):
				cond_mult += damage_vs_burning
				result.bonus_applied.append("vs_burning")

		# VS FROZEN
		var damage_vs_frozen = ps.get_stat("damage_vs_frozen")
		if damage_vs_frozen > 0:
			if ("_is_frozen" in target and target._is_frozen) or (target.has_method("is_frozen") and target.is_frozen()):
				cond_mult += damage_vs_frozen
				result.bonus_applied.append("vs_frozen")

		if cond_mult > 1.0:
			result.final_damage *= cond_mult

	# 2.7 AOE / Single Target multipliers (FIX-DEADSTAT: consumir aoe_damage_mult y single_target_mult)
	if ps and ps.has_method("get_stat"):
		var _is_aoe_attack = false
		if is_instance_valid(attacker) and attacker.has_meta("is_aoe"):
			_is_aoe_attack = attacker.get_meta("is_aoe")
		if _is_aoe_attack:
			var aoe_mult = ps.get_stat("aoe_damage_mult")
			if aoe_mult > 0:
				# FIX-G2: aoe_damage_mult base=0.0, upgrade adds +0.40
				# Antes: damage *= 0.40 → REDUCÍA daño 60%. Ahora: damage *= 1.40 → +40% bonus
				result.final_damage *= (1.0 + aoe_mult)
				result.bonus_applied.append("aoe_damage_mult")
		else:
			var st_mult = ps.get_stat("single_target_mult")
			if st_mult > 0 and absf(st_mult - 1.0) > 0.001:
				result.final_damage *= st_mult
				result.bonus_applied.append("single_target_mult")

	# 2.7 Russian Roulette: 1% chance de 10x daño
	result.pre_roulette_damage = result.final_damage
	if ps and ps.has_method("get_stat"):
		var russian_roulette = ps.get_stat("russian_roulette")
		if russian_roulette > 0:
			if randf() < 0.01:
				result.final_damage *= 10.0
				result.russian_roulette_triggered = true
				result.bonus_applied.append("russian_roulette")

	# 3. Crítico (al final para que aplique sobre todos los bonuses)
	if randf() < crit_chance:
		result.final_damage *= crit_damage
		result.is_crit = true

	# AUDIT HOOK (Static Check safe for execution)
	# Removed load() to prevent cyclic dependency crashes

	# Real implementation: Check if Logger singleton exists
	# Runner will add it to root.
	var logger = target.get_tree().root.get_node_or_null("DamageDeliveryLogger")
	if logger and logger.has_method("log_calculation"):
		var weapon_id = "unknown"
		if is_instance_valid(attacker) and attacker.has_meta("weapon_id"):
			weapon_id = attacker.get_meta("weapon_id")
		elif is_instance_valid(player) and player.has_meta("weapon_id"):
			weapon_id = player.get_meta("weapon_id")
		var id = logger.log_calculation("calc_event", target, int(result.final_damage), result.is_crit)
		target.set_meta("last_damage_event_id", id)

	return result

## Obtener porcentaje de vida del enemigo
static func _get_enemy_health_percent(target: Node) -> float:
	if target.has_method("get_health_percent"):
		return target.get_health_percent()
	elif "health_component" in target and target.health_component:
		if target.health_component.has_method("get_health_percent"):
			return target.health_component.get_health_percent()
	elif "hp" in target and "max_hp" in target:
		if target.max_hp > 0:
			return float(target.hp) / float(target.max_hp)
	return 1.0

## Aplicar bonus de daño contra élites
static func _apply_elite_bonus(damage: float, target: Node, ps: Node) -> float:
	var is_elite_target = false

	if target.has_method("is_elite") and target.is_elite():
		is_elite_target = true
	elif "is_elite" in target and target.is_elite:
		is_elite_target = true

	if is_elite_target and ps and ps.has_method("get_stat"):
		var elite_mult = ps.get_stat("elite_damage_mult")
		if elite_mult > 0:
			# FIX-G1: elite_damage_mult base=0.0, upgrades add +0.25/+0.50/+1.0
			# Antes: damage *= 0.25 → REDUCÍA daño 75%. Ahora: damage *= 1.25 → +25% bonus
			damage *= (1.0 + elite_mult)

	return damage

## Aplicar daño a un objetivo con todos los efectos secundarios (life steal, execute, etc.)
static func apply_damage_with_effects(
	tree: SceneTree,
	target: Node2D,
	damage_result: DamageResult,
	knockback_dir: Vector2 = Vector2.ZERO,
	knockback_force: float = 0.0,
	attacker: Node = null,
	element: String = "physical"
) -> void:
	if not is_instance_valid(target):
		return

	var final_damage = damage_result.get_int_damage()
	var ps = tree.get_first_node_in_group("player_stats")

	# Combustión Instantánea: daño extra de fuego antes del golpe principal
	if ps and ps.has_method("get_stat"):
		var combustion_active = ps.get_stat("combustion_active")
		if combustion_active > 0 and is_instance_valid(attacker):
			var is_fire = (element == "fire")
			if not is_fire and attacker.has_meta("burn_chance"):
				is_fire = attacker.get_meta("burn_chance") > 0
			if is_fire:
				var combustion_base = damage_result.pre_roulette_damage if damage_result.pre_roulette_damage > 0 else damage_result.final_damage
				var burn_dmg = int(combustion_base * 0.5)
				if burn_dmg > 0 and target.has_method("take_damage"):
					target.take_damage(burn_dmg, "fire", attacker)
				FloatingText.spawn_custom(target.global_position + Vector2(10, -40), "COMB!", Color.ORANGE_RED)

	# Aplicar daño principal
	var damage_applied = false
	# FIX-CRIT: Propagar is_crit al attacker para que EnemyBase.take_damage lo lea
	if is_instance_valid(attacker):
		attacker.set_meta("last_hit_was_crit", damage_result.is_crit)
	if target.has_method("take_damage"):
		target.take_damage(final_damage, element, attacker)
		damage_applied = true
	elif target.has_node("HealthComponent"):
		var hc = target.get_node("HealthComponent")
		if hc.has_method("take_damage"):
			hc.take_damage(final_damage, element)
			damage_applied = true

	if damage_applied:
		# FIX-DMG: Removed BalanceDebugger.log_damage_dealt here — EnemyBase.take_damage()
		# already logs the real post-mitigation damage. Logging here caused double-counting
		# (balance.jsonl showed 7-20% higher damage than summary.json).
		pass

	# Life steal
	ProjectileFactory.apply_life_steal(tree, damage_result.final_damage)

	# Execute threshold
	ProjectileFactory.check_execute(tree, target)

	# Efectos de estado por probabilidad
	ProjectileFactory.apply_status_effects_chance(tree, target)

	# Hemorragia (Bleed on Hit): chance de aplicar sangrado
	if ps and ps.has_method("get_stat"):
		var bleed_chance = ps.get_stat("bleed_on_hit_chance")
		if bleed_chance > 0 and randf() < bleed_chance:
			if is_instance_valid(target) and target.has_method("apply_bleed"):
				var bleed_dmg = max(1, damage_result.base_damage * 0.2)
				target.apply_bleed(bleed_dmg, 3.0)
				FloatingText.spawn_custom(target.global_position + Vector2(-10, -30), "BLEED", Color.RED)

	# Knockback
	if knockback_force != 0 and knockback_dir != Vector2.ZERO:
		if is_instance_valid(target) and target.has_method("apply_knockback"):
			target.apply_knockback(knockback_dir * knockback_force)
		elif is_instance_valid(target) and target is CharacterBody2D:
			target.velocity += knockback_dir * knockback_force

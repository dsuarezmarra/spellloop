# DamageCalculator.gd
# Utilidad centralizada para cálculo de daño y modificadores
# Evita duplicación de lógica entre diferentes tipos de proyectiles

class_name DamageCalculator

## Resultado de un cálculo de daño
class DamageResult:
	var base_damage: float = 0.0
	var final_damage: float = 0.0
	var is_crit: bool = false
	var bonus_applied: Array[String] = []
	
	func get_int_damage() -> int:
		return int(final_damage)

## Calcular daño final aplicando todos los modificadores
## Debe llamarse desde cualquier sistema que aplique daño (proyectiles, orbitales, cadenas, etc.)
static func calculate_final_damage(
	base_damage: float,
	target: Node2D,
	player: Node2D,
	crit_chance: float = 0.0,
	crit_damage: float = 2.0
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
	
	# 3. Crítico (al final para que aplique sobre todos los bonuses)
	if randf() < crit_chance:
		result.final_damage *= crit_damage
		result.is_crit = true
	
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
			if elite_mult < 0.1:
				elite_mult = 1.0  # Safety check
			damage *= elite_mult
	
	return damage

## Aplicar daño a un objetivo con todos los efectos secundarios (life steal, execute, etc.)
static func apply_damage_with_effects(
	tree: SceneTree,
	target: Node2D,
	damage_result: DamageResult,
	knockback_dir: Vector2 = Vector2.ZERO,
	knockback_force: float = 0.0
) -> void:
	if not is_instance_valid(target):
		return
	
	var final_damage = damage_result.get_int_damage()
	
	# Aplicar daño
	if target.has_method("take_damage"):
		target.take_damage(final_damage)
	
	# Life steal
	ProjectileFactory.apply_life_steal(tree, damage_result.final_damage)
	
	# Execute threshold
	ProjectileFactory.check_execute(tree, target)
	
	# Efectos de estado por probabilidad
	ProjectileFactory.apply_status_effects_chance(tree, target)
	
	# Knockback
	if knockback_force != 0 and knockback_dir != Vector2.ZERO and target.has_method("apply_knockback"):
		target.apply_knockback(knockback_dir * knockback_force)

# ChainProjectile.gd
# Proyectil que encadena entre múltiples enemigos (lightning, etc.)
# Extraído de ProjectileFactory.gd para mejor organización

extends Node2D
class_name ChainProjectile

var damage: float = 15.0
var chain_count: int = 2
var chain_range: float = 150.0
var color: Color = Color(1.0, 1.0, 0.3)
var knockback: float = 40.0
var crit_chance: float = 0.0
var crit_damage: float = 2.0
var effect: String = "none"
var effect_value: float = 0.0
var effect_duration: float = 2.0
var weapon_id: String = ""

var first_target: Node2D = null
var enemies_hit: Array = []

var _enhanced_visual: Node2D = null
var _use_enhanced: bool = false
var _chain_delay: float = 0.08

func setup(data: Dictionary) -> void:
	damage = data.get("damage", 15.0)
	chain_count = data.get("chain_count", 2)
	
	# Agregar bonus global de chain_count de PlayerStats
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		var attack_manager = tree.get_first_node_in_group("attack_manager")
		if attack_manager and attack_manager.has_method("get_player_stat"):
			var bonus_chains = attack_manager.get_player_stat("chain_count")
			if bonus_chains > 0:
				chain_count += int(bonus_chains)
	
	chain_range = data.get("range", 150.0) * 0.5
	color = data.get("color", Color(1.0, 1.0, 0.3))
	knockback = data.get("knockback", 40.0)
	crit_chance = data.get("crit_chance", 0.0)
	crit_damage = data.get("crit_damage", 2.0)
	effect = data.get("effect", "chain")
	effect_value = data.get("effect_value", 2)
	effect_duration = data.get("effect_duration", 2.0)
	weapon_id = data.get("weapon_id", "")

func start_chain() -> void:
	if first_target == null or not is_instance_valid(first_target):
		queue_free()
		return

	_create_chain_visual()
	_execute_chain_sequence()

func _create_chain_visual() -> void:
	if weapon_id != "" and ProjectileVisualManager.instance:
		var weapon_data = WeaponDatabase.get_weapon_data(weapon_id)
		if not weapon_data.is_empty():
			_enhanced_visual = ProjectileVisualManager.instance.create_chain_visual(
				weapon_id, chain_count, weapon_data)
			if _enhanced_visual:
				add_child(_enhanced_visual)
				_use_enhanced = true
				return

	# Fallback: crear visual simple
	_enhanced_visual = ChainLightningVisual.new()
	_enhanced_visual.setup(null, weapon_id, chain_count)
	add_child(_enhanced_visual)
	_use_enhanced = true

func _execute_chain_sequence() -> void:
	"""Ejecutar la secuencia de rayos encadenados"""
	var current_pos = global_position
	var current_target = first_target
	var chains_done = 0

	while chains_done < chain_count and current_target != null and is_instance_valid(current_target):
		var target_pos = current_target.global_position

		if _use_enhanced and _enhanced_visual:
			_enhanced_visual.fire_at(
				_enhanced_visual.to_local(current_pos),
				_enhanced_visual.to_local(target_pos)
			)

		_apply_damage_to_target(current_target)
		enemies_hit.append(current_target)

		if chains_done < chain_count - 1:
			await get_tree().create_timer(_chain_delay).timeout

		current_pos = target_pos
		current_target = _find_next_target(current_pos)
		chains_done += 1

	if _enhanced_visual and _enhanced_visual.has_signal("all_chains_finished"):
		await _enhanced_visual.all_chains_finished
	else:
		await get_tree().create_timer(1.0).timeout
		
	if is_instance_valid(self):
		queue_free()

func _apply_damage_to_target(target: Node2D) -> void:
	"""Aplicar daño usando DamageCalculator centralizado"""
	if not is_instance_valid(target):
		return

	var player = _get_player()
	var damage_result = DamageCalculator.calculate_final_damage(
		damage, target, player, crit_chance, crit_damage
	)

	if target.has_method("take_damage"):
		target.take_damage(damage_result.get_int_damage())
		ProjectileFactory.apply_life_steal(get_tree(), damage_result.final_damage)

	# Knockback
	if knockback != 0 and target.has_method("apply_knockback"):
		var kb_dir = (target.global_position - global_position).normalized()
		target.apply_knockback(kb_dir * knockback)
	
	_apply_chain_effect(target)

func _apply_chain_effect(target: Node2D) -> void:
	"""Aplicar efectos especiales de proyectiles encadenados"""
	if effect == "none" or effect == "chain":
		return
	
	match effect:
		"freeze_chain":
			if target.has_method("apply_freeze"):
				target.apply_freeze(effect_value, effect_duration)
			elif target.has_method("apply_slow"):
				target.apply_slow(effect_value, effect_duration)
		"burn_chain":
			if target.has_method("apply_burn"):
				target.apply_burn(effect_value, effect_duration)
		"lifesteal_chain":
			var player = _get_player()
			if player and player.has_method("heal"):
				var heal_amount = roundi(effect_value)
				player.heal(heal_amount)
				FloatingText.spawn_heal(player.global_position + Vector2(0, -30), heal_amount)
		"stun":
			if target.has_method("apply_stun"):
				target.apply_stun(effect_value)
		"slow":
			if target.has_method("apply_slow"):
				target.apply_slow(effect_value, effect_duration)
		"burn":
			if target.has_method("apply_burn"):
				target.apply_burn(effect_value, effect_duration)
		"freeze":
			if target.has_method("apply_freeze"):
				target.apply_freeze(effect_value, effect_duration)
			elif target.has_method("apply_slow"):
				target.apply_slow(effect_value, effect_duration)
		"pull":
			if target.has_method("apply_pull"):
				target.apply_pull(global_position, effect_value, effect_duration)
		"bleed":
			if target.has_method("apply_bleed"):
				target.apply_bleed(effect_value, effect_duration)
		"shadow_mark":
			if target.has_method("apply_shadow_mark"):
				target.apply_shadow_mark(effect_value, effect_duration)

func _get_player() -> Node:
	"""Obtener referencia al jugador"""
	if not get_tree():
		return null
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

func _find_next_target(from_pos: Vector2) -> Node2D:
	"""Buscar el siguiente objetivo válido para encadenar"""
	if not get_tree():
		return null

	var enemies = get_tree().get_nodes_in_group("enemies")
	var best_target: Node2D = null
	var best_dist: float = chain_range

	for enemy in enemies:
		if enemy in enemies_hit:
			continue
		if not is_instance_valid(enemy):
			continue

		var dist = from_pos.distance_to(enemy.global_position)
		if dist < best_dist:
			best_dist = dist
			best_target = enemy

	return best_target

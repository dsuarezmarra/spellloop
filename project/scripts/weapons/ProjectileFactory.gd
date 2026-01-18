# ProjectileFactory.gd
# Fábrica centralizada para crear proyectiles de todas las armas
# Se integra con SimpleProjectile existente y añade nuevos tipos

extends Node
class_name ProjectileFactory

# Referencia a la escena de proyectil base
static var _projectile_scene: PackedScene = null

# Acumulador de life steal para curar cuando llegue a 1+
static var _life_steal_accumulator: float = 0.0

# ═══════════════════════════════════════════════════════════════════════════════
# RESET PARA NUEVA PARTIDA
# ═══════════════════════════════════════════════════════════════════════════════

static func reset_for_new_game() -> void:
	"""Resetear estado estático para nueva partida"""
	_life_steal_accumulator = 0.0

# ═══════════════════════════════════════════════════════════════════════════════
# MAPEO DE ELEMENTOS
# ═══════════════════════════════════════════════════════════════════════════════

# Convertir elemento de WeaponDatabase a string para SimpleProjectile
const ELEMENT_TO_STRING: Dictionary = {
	0: "ice",       # ICE
	1: "fire",      # FIRE
	2: "lightning", # LIGHTNING
	3: "arcane",    # ARCANE
	4: "dark",      # SHADOW
	5: "nature",    # NATURE
	6: "ice",       # WIND (usar ice como fallback)
	7: "nature",    # EARTH (usar nature como fallback)
	8: "arcane",    # LIGHT (usar arcane como fallback)
	9: "dark"       # VOID (usar dark como fallback)
}

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER: EXECUTE THRESHOLD
# ═══════════════════════════════════════════════════════════════════════════════

static func check_execute(tree: SceneTree, enemy: Node) -> bool:
	"""
	Verificar si un enemigo debería ser ejecutado instantáneamente.
	Retorna true si el enemigo fue ejecutado.
	"""
	if not is_instance_valid(enemy):
		return false
	
	# Obtener execute_threshold de AttackManager/PlayerStats
	var attack_manager = tree.get_first_node_in_group("attack_manager")
	if attack_manager == null:
		return false
	
	var execute_threshold = attack_manager.get_player_stat("execute_threshold") if attack_manager.has_method("get_player_stat") else 0.0
	if execute_threshold <= 0:
		return false
	
	# Verificar HP del enemigo
	var current_hp = 0
	var max_hp = 1
	
	if enemy.has_method("get_health"):
		var health_data = enemy.get_health()
		current_hp = health_data.get("current", 0)
		max_hp = health_data.get("max", 1)
	elif "health_component" in enemy and is_instance_valid(enemy.health_component):
		current_hp = enemy.health_component.current_health
		max_hp = enemy.health_component.max_health
	elif "hp" in enemy and "max_hp" in enemy:
		current_hp = enemy.hp
		max_hp = enemy.max_hp
	else:
		return false
	
	# Calcular porcentaje de HP
	var hp_percent = float(current_hp) / float(max_hp) if max_hp > 0 else 0.0
	
	# Si está bajo el umbral, ejecutar
	if hp_percent <= execute_threshold and hp_percent > 0:
		# Matar instantáneamente
		if enemy.has_method("take_damage"):
			enemy.take_damage(current_hp)  # Hacer daño igual al HP restante
			# Mostrar texto de ejecución (usar class_name FloatingText)
			FloatingText.spawn_damage(enemy.global_position + Vector2(0, -30), current_hp, true)
			# Debug desactivado: print("[Execute] ☠️ Enemigo ejecutado")
		return true
	
	return false

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER: LIFE STEAL
# ═══════════════════════════════════════════════════════════════════════════════

static func apply_life_steal(tree: SceneTree, damage_dealt: float) -> void:
	"""Aplicar life steal al jugador basado en el daño causado - acumula hasta 1 HP"""
	if tree == null:
		return
	
	# Obtener life_steal de AttackManager
	var attack_manager = tree.get_first_node_in_group("attack_manager")
	if attack_manager == null:
		return
	
	var life_steal = attack_manager.get_player_stat("life_steal") if attack_manager.has_method("get_player_stat") else 0.0
	if life_steal <= 0:
		return
	
	# Obtener el jugador
	var player = tree.get_first_node_in_group("player")
	if player == null:
		return
	
	# Acumular el heal parcial
	var heal_amount = damage_dealt * life_steal
	_life_steal_accumulator += heal_amount
	
	# Solo curar cuando acumulemos al menos 1 HP completo
	if _life_steal_accumulator >= 1.0:
		var heal_int = int(_life_steal_accumulator)
		_life_steal_accumulator -= heal_int  # Guardar el residuo
		
		# Intentar curar al jugador
		if player.has_method("heal"):
			player.heal(heal_int)
			# Debug desactivado: print("[LifeSteal] Curado +%d HP" % heal_int)
		elif player.has_node("PlayerStats"):
			var stats = player.get_node("PlayerStats")
			if stats.has_method("heal"):
				stats.heal(heal_int)
				# Debug desactivado: print("[LifeSteal] Curado +%d HP" % heal_int)

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER: STATUS DURATION MULTIPLIER
# ═══════════════════════════════════════════════════════════════════════════════

static func get_modified_effect_duration(tree: SceneTree, base_duration: float) -> float:
	"""
	Obtener la duración del efecto modificada por status_duration_mult de PlayerStats.
	Esto afecta a efectos como slow, burn, freeze, stun, etc.
	"""
	if tree == null:
		return base_duration
	
	var player_stats_nodes = tree.get_nodes_in_group("player_stats")
	if player_stats_nodes.is_empty():
		return base_duration
	
	var player_stats = player_stats_nodes[0]
	if player_stats and player_stats.has_method("get_stat"):
		var duration_mult = player_stats.get_stat("status_duration_mult")
		if duration_mult > 0:
			return base_duration * duration_mult
	
	return base_duration

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER: STATUS EFFECTS CHANCE (burn, freeze, bleed from upgrades)
# ═══════════════════════════════════════════════════════════════════════════════

static func apply_status_effects_chance(tree: SceneTree, enemy: Node) -> void:
	"""
	Roll for burn/freeze/bleed chances from PlayerStats and apply if successful.
	This is called after damage to give player upgrade effects a chance to proc.
	"""
	if tree == null or enemy == null or not is_instance_valid(enemy):
		return
	
	# Obtener PlayerStats
	var player_stats_nodes = tree.get_nodes_in_group("player_stats")
	if player_stats_nodes.is_empty():
		return
	
	var player_stats = player_stats_nodes[0]
	if not player_stats or not player_stats.has_method("get_stat"):
		return
	
	# Obtener multiplicador de duración
	var status_duration_mult = player_stats.get_stat("status_duration_mult")
	if status_duration_mult <= 0:
		status_duration_mult = 1.0
	
	# === BURN CHANCE ===
	var burn_chance = player_stats.get_stat("burn_chance")
	if burn_chance > 0 and randf() < burn_chance:
		if enemy.has_method("apply_burn"):
			var burn_dmg = player_stats.get_stat("burn_damage") if player_stats.has_method("get_stat") else 3.0
			if burn_dmg <= 0:
				burn_dmg = 3.0
			enemy.apply_burn(burn_dmg, 3.0 * status_duration_mult)  # 3s base duration
			# print("[StatusEffect] 🔥 Burn aplicado! (chance: %.0f%%)" % (burn_chance * 100))
	
	# === FREEZE CHANCE ===
	var freeze_chance = player_stats.get_stat("freeze_chance")
	if freeze_chance > 0 and randf() < freeze_chance:
		if enemy.has_method("apply_freeze"):
			enemy.apply_freeze(1.0, 1.0 * status_duration_mult)  # 1s freeze
			# print("[StatusEffect] ❄️ Freeze aplicado! (chance: %.0f%%)" % (freeze_chance * 100))
		elif enemy.has_method("apply_slow"):
			enemy.apply_slow(0.5, 2.0 * status_duration_mult)  # Fallback: 50% slow 2s
	
	# === BLEED CHANCE ===
	var bleed_chance = player_stats.get_stat("bleed_chance")
	if bleed_chance > 0 and randf() < bleed_chance:
		if enemy.has_method("apply_bleed"):
			enemy.apply_bleed(2.0, 4.0 * status_duration_mult)  # 2 dmg/s for 4s
			# print("[StatusEffect] 🩸 Bleed aplicado! (chance: %.0f%%)" % (bleed_chance * 100))

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER: CONDITIONAL DAMAGE MULTIPLIER
# ═══════════════════════════════════════════════════════════════════════════════

static func get_conditional_damage_multiplier(tree: SceneTree, enemy: Node) -> float:
	"""
	Calculate extra damage multiplier based on enemy status effects.
	Returns a multiplier (1.0 = no bonus, 1.25 = +25% damage, etc.)
	Checks: damage_vs_slowed, damage_vs_burning, damage_vs_frozen
	"""
	if tree == null or enemy == null or not is_instance_valid(enemy):
		return 1.0
	
	# Obtener PlayerStats
	var player_stats_nodes = tree.get_nodes_in_group("player_stats")
	if player_stats_nodes.is_empty():
		return 1.0
	
	var player_stats = player_stats_nodes[0]
	if not player_stats or not player_stats.has_method("get_stat"):
		return 1.0
	
	var multiplier = 1.0
	
	# === DAMAGE VS SLOWED ===
	var damage_vs_slowed = player_stats.get_stat("damage_vs_slowed")
	if damage_vs_slowed > 0:
		if "_is_slowed" in enemy and enemy._is_slowed:
			multiplier += damage_vs_slowed
	
	# === DAMAGE VS BURNING ===
	var damage_vs_burning = player_stats.get_stat("damage_vs_burning")
	if damage_vs_burning > 0:
		if "_is_burning" in enemy and enemy._is_burning:
			multiplier += damage_vs_burning
	
	# === DAMAGE VS FROZEN ===
	var damage_vs_frozen = player_stats.get_stat("damage_vs_frozen")
	if damage_vs_frozen > 0:
		if "_is_frozen" in enemy and enemy._is_frozen:
			multiplier += damage_vs_frozen
	
	return multiplier

# ═══════════════════════════════════════════════════════════════════════════════
# CREACIÓN DE PROYECTILES
# ═══════════════════════════════════════════════════════════════════════════════
static func create_projectile(owner: Node2D, data: Dictionary) -> Node2D:
	"""
	Crear un proyectil básico
	data requiere: direction, start_position, damage, speed, pierce, etc.
	"""
	var projectile = _create_base_projectile(data)
	if projectile == null:
		return null

	projectile.global_position = data.get("start_position", owner.global_position)
	projectile.direction = data.get("direction", Vector2.RIGHT)

	# NOTA: NO rotar el nodo proyectil aquí.
	# El AnimatedProjectileSprite.set_direction() se encarga de la rotación del sprite.
	# Rotar el nodo padre causaría doble rotación cuando hay sprites animados.

	# Añadir al árbol
	var tree = owner.get_tree()
	if tree and tree.current_scene:
		tree.current_scene.add_child(projectile)
	else:
		owner.get_parent().add_child(projectile)

	return projectile

static func create_beam(owner: Node2D, data: Dictionary) -> Node2D:
	"""
	Crear un rayo instantáneo
	Daña todo en su camino inmediatamente
	"""
	var beam = BeamEffect.new()
	beam.setup(data)
	beam.global_position = data.get("start_position", owner.global_position)
	beam.direction = data.get("direction", Vector2.RIGHT)

	var tree = owner.get_tree()
	if tree and tree.current_scene:
		tree.current_scene.add_child(beam)

	# El beam se procesa instantáneamente y aplica daño
	beam.fire(owner)

	return beam

static func create_aoe(owner: Node2D, data: Dictionary) -> Node2D:
	"""
	Crear área de efecto
	"""
	var aoe = AOEEffect.new()
	aoe.setup(data)
	aoe.global_position = data.get("position", owner.global_position)

	var tree = owner.get_tree()
	if tree and tree.current_scene:
		tree.current_scene.add_child(aoe)

	# Activar el AOE
	aoe.activate(owner)

	return aoe

static func create_orbitals(owner: Node2D, data: Dictionary) -> void:
	"""
	Crear proyectiles orbitantes alrededor del jugador
	Verifica si ya existen orbitales del mismo tipo
	"""
	var weapon_id = data.get("weapon_id", "default")
	var manager_name = "OrbitalManager_" + weapon_id
	var orbital_manager = owner.get_node_or_null(manager_name)

	if orbital_manager == null:
		orbital_manager = OrbitalManager.new()
		orbital_manager.name = manager_name
		owner.add_child(orbital_manager)

	orbital_manager.update_orbitals(data)

static func create_chain_projectile(owner: Node2D, data: Dictionary) -> Node2D:
	"""
	Crear proyectil que encadena entre enemigos
	"""
	var chain = ChainProjectile.new()
	chain.setup(data)
	chain.global_position = owner.global_position
	chain.first_target = data.get("first_target")

	var tree = owner.get_tree()
	if tree and tree.current_scene:
		tree.current_scene.add_child(chain)

	chain.start_chain()

	return chain

# ═══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

static func _create_base_projectile(data: Dictionary) -> SimpleProjectile:
	"""Crear instancia base de SimpleProjectile con los datos"""
	var projectile = SimpleProjectile.new()

	# Stats básicos
	projectile.damage = int(data.get("damage", 10))
	projectile.speed = data.get("speed", 300.0)
	# Calcular lifetime basado en rango (evitar división por cero)
	var proj_speed = maxf(data.get("speed", 300.0), 1.0)
	projectile.lifetime = data.get("range", 300.0) / proj_speed
	projectile.knockback_force = data.get("knockback", 50.0)
	projectile.pierce_count = data.get("pierce", 0)

	# Elemento
	var element_int = data.get("element", 3)  # Default arcane
	projectile.element_type = ELEMENT_TO_STRING.get(element_int, "arcane")

	# Efecto especial (almacenar en metadata)
	projectile.set_meta("effect", data.get("effect", "none"))
	projectile.set_meta("effect_value", data.get("effect_value", 0.0))
	projectile.set_meta("effect_duration", data.get("effect_duration", 0.0))
	projectile.set_meta("crit_chance", data.get("crit_chance", 0.0))
	projectile.set_meta("weapon_id", data.get("weapon_id", ""))
	
	# Pasar el color del arma si está definido
	if data.has("color"):
		projectile.set_meta("weapon_color", data.get("color"))

	return projectile

static func get_element_string(element_enum: int) -> String:
	"""Convertir enum de elemento a string"""
	return ELEMENT_TO_STRING.get(element_enum, "arcane")


# ═══════════════════════════════════════════════════════════════════════════════
# CLASE INTERNA: BeamEffect
# ═══════════════════════════════════════════════════════════════════════════════

class BeamEffect extends Node2D:
	var damage: float = 25.0
	var beam_range: float = 600.0
	var beam_width: float = 10.0
	var duration: float = 0.3
	var pierce: int = 999
	var knockback: float = 0.0
	var color: Color = Color.WHITE
	var effect: String = "none"
	var effect_value: float = 0.0
	var effect_duration: float = 0.0
	var crit_chance: float = 0.0
	var crit_damage: float = 2.0  # Multiplicador de daño crítico
	var direction: Vector2 = Vector2.RIGHT
	var weapon_id: String = ""  # Para visuales mejorados

	var _timer: float = 0.0
	var _has_fired: bool = false
	var _enhanced_visual: BeamVisualEffect = null

	func setup(data: Dictionary) -> void:
		damage = data.get("damage", 25.0)
		beam_range = data.get("range", 600.0)
		beam_width = data.get("area", 1.0) * 20.0
		duration = data.get("duration", 0.3)
		knockback = data.get("knockback", 0.0)
		color = data.get("color", Color.WHITE)
		effect = data.get("effect", "none")
		effect_value = data.get("effect_value", 0.0)
		effect_duration = data.get("effect_duration", 0.0)
		crit_chance = data.get("crit_chance", 0.0)
		crit_damage = data.get("crit_damage", 2.0)
		weapon_id = data.get("weapon_id", "")

	func fire(owner: Node2D) -> void:
		if _has_fired:
			return
		_has_fired = true

		# Usar raycast para encontrar todos los enemigos en la línea
		var space_state = owner.get_world_2d().direct_space_state
		var end_pos = global_position + direction * beam_range

		# Query para el rayo
		var query = PhysicsRayQueryParameters2D.create(global_position, end_pos)
		query.collision_mask = 2 | 4 | 8 | 16 # Layers 2, 3, 4, 5 (Player/Enemy/World)
		query.collide_with_areas = true
		query.collide_with_bodies = true

		# Encontrar todos los enemigos en el camino
		var enemies_hit = []
		var current_pos = global_position

		for i in range(50):  # Límite de iteraciones
			var result = space_state.intersect_ray(query)
			if result.is_empty():
				break

			var collider = result.collider
			if collider.is_in_group("enemies"):
				enemies_hit.append(collider)
				_apply_damage(collider)

			# Mover el punto de inicio más allá
			current_pos = result.position + direction * 5.0
			query = PhysicsRayQueryParameters2D.create(current_pos, end_pos)
			query.collision_mask = 2 | 4 | 8 | 16 # Layers 2, 3, 4, 5 to be safe
			query.exclude = [collider.get_rid()]

		# Crear visual del rayo (mejorado si está disponible)
		_create_beam_visual(end_pos)

	func _apply_damage(enemy: Node) -> void:
		var final_damage = damage

		# Verificar crítico
		if randf() < crit_chance:
			final_damage *= crit_damage  # Usar multiplicador de crítico variable
		
		# Aplicar multiplicador de daño condicional (damage_vs_slowed/burning/frozen)
		var conditional_mult = ProjectileFactory.get_conditional_damage_multiplier(get_tree(), enemy)
		if conditional_mult > 1.0:
			final_damage *= conditional_mult

		if enemy.has_method("take_damage"):
			enemy.take_damage(int(final_damage))
			# Aplicar life steal
			ProjectileFactory.apply_life_steal(get_tree(), final_damage)
			# Verificar execute threshold después del daño
			ProjectileFactory.check_execute(get_tree(), enemy)
			# Aplicar efectos de estado por probabilidad (burn, freeze, bleed)
			ProjectileFactory.apply_status_effects_chance(get_tree(), enemy)

		# Aplicar knockback
		if knockback != 0 and enemy.has_method("apply_knockback"):
			var kb_dir = (enemy.global_position - global_position).normalized()
			enemy.apply_knockback(kb_dir * knockback)
		
		# Aplicar efectos especiales
		_apply_effect(enemy)
	
	func _apply_effect(enemy: Node) -> void:
		"""Aplicar efectos especiales del beam"""
		if effect == "none":
			return
		
		# Obtener duración modificada por status_duration_mult
		var modified_duration = ProjectileFactory.get_modified_effect_duration(get_tree(), effect_duration)
		var modified_value_as_duration = ProjectileFactory.get_modified_effect_duration(get_tree(), effect_value)
		
		match effect:
			"burn":
				if enemy.has_method("apply_burn"):
					enemy.apply_burn(effect_value, modified_duration)
			"freeze":
				if enemy.has_method("apply_freeze"):
					enemy.apply_freeze(effect_value, modified_duration)
				elif enemy.has_method("apply_slow"):
					enemy.apply_slow(effect_value, modified_duration)
			"slow":
				if enemy.has_method("apply_slow"):
					enemy.apply_slow(effect_value, modified_duration)
			"stun":
				if enemy.has_method("apply_stun"):
					enemy.apply_stun(modified_value_as_duration)  # effect_value = duración del stun
			"blind":
				if enemy.has_method("apply_blind"):
					enemy.apply_blind(modified_value_as_duration)  # effect_value = duración del blind
			"pull":
				if enemy.has_method("apply_pull"):
					enemy.apply_pull(global_position, effect_value, modified_duration)
			"execute":
				if enemy.has_method("get_info"):
					var info = enemy.get_info()
					var hp = info.get("hp", 100)
					var max_hp = info.get("max_hp", 100)
					var hp_percent = float(hp) / float(max_hp)
					if hp_percent <= effect_value:
						if enemy.has_method("take_damage"):
							enemy.take_damage(hp)
			"lifesteal":
				var player = _get_player()
				if player and player.has_method("heal"):
					var heal_amount = roundi(effect_value)
					player.heal(heal_amount)
					FloatingText.spawn_heal(player.global_position + Vector2(0, -30), heal_amount)
			"bleed":
				if enemy.has_method("apply_bleed"):
					enemy.apply_bleed(effect_value, modified_duration)
			"shadow_mark":
				if enemy.has_method("apply_shadow_mark"):
					enemy.apply_shadow_mark(effect_value, modified_duration)
	
	func _get_player() -> Node:
		"""Obtener referencia al jugador"""
		if not get_tree():
			return null
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			return players[0]
		return null

	func _create_beam_visual(end_pos: Vector2) -> void:
		# Intentar usar visual mejorado
		if weapon_id != "" and ProjectileVisualManager.instance:
			var weapon_data = WeaponDatabase.get_weapon_data(weapon_id)
			if not weapon_data.is_empty():
				_enhanced_visual = ProjectileVisualManager.instance.create_beam_visual(
					weapon_id, beam_range, direction, beam_width, weapon_data)
				if _enhanced_visual:
					add_child(_enhanced_visual)
					_enhanced_visual.fire(duration)
					return
				else:
					push_warning("[BeamEffect] create_beam_visual retornó null para: %s" % weapon_id)
			else:
				push_warning("[BeamEffect] weapon_data vacío para: %s" % weapon_id)
		else:
			if weapon_id == "":
				push_warning("[BeamEffect] weapon_id vacío")
			if not ProjectileVisualManager.instance:
				push_warning("[BeamEffect] ProjectileVisualManager.instance es null")

		# Fallback: visual simple
		var line = Line2D.new()
		line.width = beam_width
		line.default_color = color
		line.add_point(Vector2.ZERO)
		line.add_point(to_local(end_pos))
		add_child(line)

		# Efecto de fade out
		var tween = create_tween()
		tween.tween_property(line, "modulate:a", 0.0, duration)
		tween.tween_callback(queue_free)

	func _process(delta: float) -> void:
		_timer += delta
		if _timer >= duration:
			queue_free()


# ═══════════════════════════════════════════════════════════════════════════════
# CLASE INTERNA: AOEEffect
# Sistema de daño por tics - hace daño continuo mientras los enemigos estén dentro
# ═══════════════════════════════════════════════════════════════════════════════

class AOEEffect extends Node2D:
	var damage: float = 20.0
	var aoe_radius: float = 100.0
	var duration: float = 0.5
	var knockback: float = 150.0
	var color: Color = Color(0.6, 0.4, 0.2)
	var effect: String = "none"
	var effect_value: float = 0.0
	var effect_duration: float = 0.0
	var crit_chance: float = 0.0
	var crit_damage: float = 2.0  # Multiplicador de daño crítico
	var weapon_id: String = ""  # Para visuales mejorados
	
	# Sistema de tics de daño
	var tick_interval: float = 0.25  # Tiempo entre cada tic de daño
	var damage_per_tick: float = 5.0  # Daño por cada tic
	var total_ticks: int = 4  # Número total de tics durante la duración

	var _timer: float = 0.0
	var _tick_timer: float = 0.0
	var _ticks_applied: int = 0
	var _activated: bool = false
	var _enemies_damaged: Array = []  # Para el primer impacto
	var _enemies_in_area: Dictionary = {}  # {enemy_id: last_tick_time} para tics
	var _damage_applied: bool = false
	var _enhanced_visual: AOEVisualEffect = null
	var _use_enhanced: bool = false
	
	# Configuración de tics por arma (balanceado)
	# damage_per_tick, tick_interval, total_ticks
	const AOE_TICK_CONFIG: Dictionary = {
		# Armas base
		"earth_spike": {"damage_per_tick": 7, "tick_interval": 0.25, "total_ticks": 2},  # 14 total (burst)
		"void_pulse": {"damage_per_tick": 4, "tick_interval": 0.25, "total_ticks": 4},   # 16 total (sustained)
		
		# Fusiones AOE
		"rift_quake": {"damage_per_tick": 8, "tick_interval": 0.3, "total_ticks": 5},     # 40 total
		"glacier": {"damage_per_tick": 8, "tick_interval": 0.2, "total_ticks": 3},        # 24 total
		"absolute_zero": {"damage_per_tick": 5, "tick_interval": 0.3, "total_ticks": 4},  # 20 total
		"volcano": {"damage_per_tick": 10, "tick_interval": 0.25, "total_ticks": 3},      # 30 total
		"dark_flame": {"damage_per_tick": 5, "tick_interval": 0.25, "total_ticks": 5},    # 25 total (sustained burn)
		"seismic_bolt": {"damage_per_tick": 10, "tick_interval": 0.25, "total_ticks": 3}, # 30 total (burst)
		"void_storm": {"damage_per_tick": 4, "tick_interval": 0.25, "total_ticks": 8},    # 32 total (long duration)
		"gaia": {"damage_per_tick": 8, "tick_interval": 0.25, "total_ticks": 3},          # 24 total + lifesteal
		"decay": {"damage_per_tick": 4, "tick_interval": 0.25, "total_ticks": 6},         # 24 total (drain over time)
		"radiant_stone": {"damage_per_tick": 11, "tick_interval": 0.2, "total_ticks": 3}, # 33 total (burst + stun)
		"steam_cannon": {"damage_per_tick": 9, "tick_interval": 0.2, "total_ticks": 3},   # 27 total (fast burst)
	}

	func setup(data: Dictionary) -> void:
		damage = data.get("damage", 20.0)
		aoe_radius = data.get("area", 1.0) * 80.0  # Escalar área
		duration = max(data.get("duration", 0.5), 0.4)  # Mínimo 0.4s para ver el efecto
		knockback = data.get("knockback", 150.0)
		color = data.get("color", Color(0.6, 0.4, 0.2))
		effect = data.get("effect", "none")
		effect_value = data.get("effect_value", 0.0)
		effect_duration = data.get("effect_duration", 0.0)
		crit_chance = data.get("crit_chance", 0.0)
		crit_damage = data.get("crit_damage", 2.0)
		weapon_id = data.get("weapon_id", "")
		
		# Configurar tics según el arma
		_setup_tick_damage()
	
	func _setup_tick_damage() -> void:
		"""Configurar el daño por tics basado en el arma"""
		if AOE_TICK_CONFIG.has(weapon_id):
			var config = AOE_TICK_CONFIG[weapon_id]
			damage_per_tick = config.get("damage_per_tick", damage / 4.0)
			tick_interval = config.get("tick_interval", 0.25)
			total_ticks = config.get("total_ticks", 4)
		else:
			# Configuración por defecto: distribuir el daño en tics
			total_ticks = max(2, int(duration / 0.25))
			tick_interval = duration / float(total_ticks)
			damage_per_tick = damage / float(total_ticks)
		
		# Debug de tick config (desactivado en producción)
		# print("[AOE] Tick config para %s: %d daño/tick, %.2fs intervalo, %d ticks (total: %d)" % [
		#	weapon_id if weapon_id != "" else "default",
		#	int(damage_per_tick),
		#	tick_interval,
		#	total_ticks,
		#	int(damage_per_tick * total_ticks)
		# ])

	func _ready() -> void:
		# Activar automáticamente cuando entre al árbol
		_do_activate()

	func activate(_owner: Node2D) -> void:
		# DEPRECATED: Método legacy, ahora se activa automáticamente en _ready via _do_activate()
		pass

	func _do_activate() -> void:
		if _activated:
			return
		_activated = true

		# print("[AOE] Activado en posición: %s, radio: %.1f" % [global_position, aoe_radius])

		# Crear visual (mejorado si está disponible)
		_create_aoe_visual()

		# Aplicar primer tic de daño inmediatamente
		_apply_tick_damage()
		_ticks_applied = 1

	func _on_body_entered(body: Node2D) -> void:
		if body.is_in_group("enemies"):
			var enemy_id = body.get_instance_id()
			if not _enemies_in_area.has(enemy_id):
				_enemies_in_area[enemy_id] = 0.0  # Puede recibir daño inmediatamente
				# print("[AOE] Body entered: %s" % body.name)

	func _on_area_entered(area: Area2D) -> void:
		var parent = area.get_parent()
		if parent and parent.is_in_group("enemies"):
			var enemy_id = parent.get_instance_id()
			if not _enemies_in_area.has(enemy_id):
				_enemies_in_area[enemy_id] = 0.0
				# print("[AOE] Area entered: %s" % parent.name)

	func _apply_tick_damage() -> void:
		"""Aplicar un tic de daño a todos los enemigos en el área"""
		if not get_tree():
			return
		var enemies = get_tree().get_nodes_in_group("enemies")

		for enemy in enemies:
			if not is_instance_valid(enemy):
				continue
			
			var dist = global_position.distance_to(enemy.global_position)
			if dist <= aoe_radius:
				_apply_damage_tick(enemy)

	func _apply_damage_tick(enemy: Node) -> void:
		"""Aplicar daño de un tic a un enemigo"""
		var final_damage = damage_per_tick
		var is_crit = false
		
		if randf() < crit_chance:
			final_damage *= crit_damage  # Usar multiplicador de crítico variable
			is_crit = true
		
		# Aplicar multiplicador de daño condicional (damage_vs_slowed/burning/frozen)
		var conditional_mult = ProjectileFactory.get_conditional_damage_multiplier(get_tree(), enemy)
		if conditional_mult > 1.0:
			final_damage *= conditional_mult

		if enemy.has_method("take_damage"):
			enemy.take_damage(int(final_damage))
			# Aplicar life steal
			ProjectileFactory.apply_life_steal(get_tree(), final_damage)
			# Verificar execute threshold después del daño
			ProjectileFactory.check_execute(get_tree(), enemy)
			# Aplicar efectos de estado por probabilidad (solo primer hit)
			if not _enemies_damaged.has(enemy.get_instance_id()):
				ProjectileFactory.apply_status_effects_chance(get_tree(), enemy)
			# Debug de crítico (desactivado en producción)
			# if is_crit:
			#	print("[AOE] ⚡ CRIT! %s recibe %d daño (tick %d/%d)" % [enemy.name, int(final_damage), _ticks_applied, total_ticks])

		# Aplicar knockback solo en el primer tic (para no empujar continuamente)
		var enemy_id = enemy.get_instance_id()
		if not _enemies_damaged.has(enemy_id):
			_enemies_damaged.append(enemy_id)
			if knockback != 0 and enemy.has_method("apply_knockback"):
				var kb_dir = (enemy.global_position - global_position).normalized()
				enemy.apply_knockback(kb_dir * knockback)
			# Aplicar efectos especiales solo una vez
			_apply_effect(enemy)

	func _apply_damage(enemy: Node) -> void:
		"""Legacy: redirigir a tick damage"""
		_apply_damage_tick(enemy)

	func _damage_enemies_in_area() -> void:
		# DEPRECATED: Ahora se usa _apply_tick_damage() que itera sobre enemigos en rango
		pass

	func _apply_effect(enemy: Node) -> void:
		if effect == "none":
			return

		# Obtener duración modificada por status_duration_mult
		var modified_duration = ProjectileFactory.get_modified_effect_duration(get_tree(), effect_duration)
		var modified_value_as_duration = ProjectileFactory.get_modified_effect_duration(get_tree(), effect_value)

		match effect:
			"stun":
				if enemy.has_method("apply_stun"):
					enemy.apply_stun(modified_value_as_duration)  # effect_value = duración del stun
			"pull":
				if enemy.has_method("apply_pull"):
					enemy.apply_pull(global_position, effect_value, modified_duration)
			"freeze":
				if enemy.has_method("apply_freeze"):
					enemy.apply_freeze(effect_value, modified_duration)
				elif enemy.has_method("apply_slow"):
					enemy.apply_slow(effect_value, modified_duration)
			"slow":
				if enemy.has_method("apply_slow"):
					enemy.apply_slow(effect_value, modified_duration)
			"burn":
				var instant = _check_player_stat("instant_combustion")
				if instant > 0:
					if enemy.has_method("take_damage"):
						# Burn default: 3 dmg/s normally defined in WeaponDatabase or defaults
						# We should try to access damage per tick logic or strict definition.
						# Assuming effect_value is damage per second? 
						# In UpgradeDatabase: "3 daño/s por 3s" -> effect_value likely 3.
						var total_dmg = effect_value * modified_duration
						enemy.take_damage(total_dmg)
						# VFX for instant burn
						_spawn_instant_effect_visual(enemy.global_position, Color.ORANGE_RED)
				elif enemy.has_method("apply_burn"):
					enemy.apply_burn(effect_value, modified_duration)
			"blind":
				if enemy.has_method("apply_blind"):
					enemy.apply_blind(modified_value_as_duration)  # effect_value = duración del blind
			"steam":
				# Efecto combinado: slow + burn
				if enemy.has_method("apply_slow"):
					enemy.apply_slow(0.3, modified_duration)  # 30% slow
				if enemy.has_method("apply_burn"):
					enemy.apply_burn(effect_value, modified_duration)
			"freeze_chain":
				# Freeze que se propaga (el chain se maneja en otro lugar)
				if enemy.has_method("apply_freeze"):
					enemy.apply_freeze(effect_value, modified_duration)
				elif enemy.has_method("apply_slow"):
					enemy.apply_slow(effect_value, modified_duration)
			"burn_chain":
				# Burn que se propaga
				if enemy.has_method("apply_burn"):
					enemy.apply_burn(effect_value, modified_duration)
			"lifesteal":
				# Curar al jugador por cada tick
				var player = _get_player()
				if player and player.has_method("heal"):
					var heal_amount = roundi(effect_value)
					player.heal(heal_amount)
					FloatingText.spawn_heal(player.global_position + Vector2(0, -30), heal_amount)
			"lifesteal_chain":
				# Lifesteal (el chain se aplica en proyectiles, no en AOE)
				var player2 = _get_player()
				if player2 and player2.has_method("heal"):
					var heal_amount2 = roundi(effect_value)
					player2.heal(heal_amount2)
					FloatingText.spawn_heal(player2.global_position + Vector2(0, -30), heal_amount2)
			"execute":
				# Ejecutar si el enemigo tiene menos del X% de vida
				if enemy.has_method("get_info"):
					var info = enemy.get_info()
					var hp = info.get("hp", 100)
					var max_hp = info.get("max_hp", 100)
					var hp_percent = float(hp) / float(max_hp)
					if hp_percent <= effect_value:  # effect_value es el umbral (ej: 0.2 = 20%)
						if enemy.has_method("take_damage"):
							enemy.take_damage(hp)  # Matar instantáneamente
							# Debug desactivado: print("[AOE] EXECUTE!")
			"knockback_bonus":
				# Ya se maneja el knockback en otro lugar, esto solo incrementa
				pass
			"crit_chance":
				# Ya se maneja en _apply_damage_tick
				pass
			"bleed":
				var instant = _check_player_stat("instant_bleed")
				if instant > 0:
					if enemy.has_method("take_damage"):
						var total_dmg = effect_value * modified_duration
						enemy.take_damage(total_dmg)
						_spawn_instant_effect_visual(enemy.global_position, Color.DARK_RED)
				elif enemy.has_method("apply_bleed"):
					enemy.apply_bleed(effect_value, modified_duration)
			"shadow_mark":
				# Marcar enemigo para daño extra
				if enemy.has_method("apply_shadow_mark"):
					enemy.apply_shadow_mark(effect_value, modified_duration)
			"chain":
				# El chain se maneja en ChainProjectile, no aquí
				pass
	
	func _get_player() -> Node:
		"""Obtener referencia al jugador para lifesteal"""
		if not get_tree():
			return null
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			return players[0]
		return null

	func _check_player_stat(stat: String) -> float:
		"""Helper para verificar stat del player"""
		var ps = get_tree().get_first_node_in_group("player_stats")
		if ps and ps.has_method("get_stat"):
			return ps.get_stat(stat)
		return 0.0

	func _spawn_instant_effect_visual(pos: Vector2, color: Color) -> void:
		"""Visual simple para daño instantáneo"""
		# Podríamos usar FloatingText o crear una partícula simple
		# Por ahora usamos FloatingText con un símbolo
		FloatingText.spawn_text(pos + Vector2(0, -20), "💥", color)

	func _create_aoe_visual() -> void:
		# Intentar usar visual mejorado
		if weapon_id != "" and ProjectileVisualManager.instance:
			var weapon_data = WeaponDatabase.get_weapon_data(weapon_id)
			if not weapon_data.is_empty():
				_enhanced_visual = ProjectileVisualManager.instance.create_aoe_visual(
					weapon_id, aoe_radius, duration, weapon_data)
				if _enhanced_visual:
					add_child(_enhanced_visual)
					_enhanced_visual.play_appear()
					_use_enhanced = true
					# Auto-destruir después de la duración (con verificación de validez)
					await get_tree().create_timer(duration + 0.5).timeout
					if is_instance_valid(self):
						queue_free()
					return
				else:
					push_warning("[AOEEffect] create_aoe_visual retornó null para: %s" % weapon_id)
			else:
				push_warning("[AOEEffect] weapon_data vacío para: %s" % weapon_id)
		else:
			if weapon_id == "":
				push_warning("[AOEEffect] weapon_id vacío")
			if not ProjectileVisualManager.instance:
				push_warning("[AOEEffect] ProjectileVisualManager.instance es null")

		# Fallback: visual simple
		scale = Vector2(0.1, 0.1)
		modulate.a = 1.0

		var tween = create_tween()
		# Expandir rápidamente
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), duration * 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		# Mantener y luego desvanecer
		tween.tween_interval(duration * 0.3)
		tween.tween_property(self, "modulate:a", 0.0, duration * 0.4)
		tween.tween_callback(queue_free)

	func _draw() -> void:
		# Solo dibujar si no usamos visual mejorado
		if _use_enhanced:
			return
		# Dibujar círculo del AOE con múltiples capas para más visibilidad
		# Capa exterior (borde grueso)
		draw_arc(Vector2.ZERO, aoe_radius, 0, TAU, 48, color, 4.0)
		# Capa media (relleno semi-transparente)
		draw_circle(Vector2.ZERO, aoe_radius * 0.9, Color(color.r, color.g, color.b, 0.3))
		# Núcleo más brillante
		draw_circle(Vector2.ZERO, aoe_radius * 0.4, Color(color.r, color.g, color.b, 0.5))
		# Centro muy brillante
		draw_circle(Vector2.ZERO, aoe_radius * 0.15, Color(1.0, 1.0, 1.0, 0.7))

	func _process(delta: float) -> void:
		_timer += delta
		_tick_timer += delta
		
		# Aplicar tics de daño mientras dure el efecto
		if _ticks_applied < total_ticks and _tick_timer >= tick_interval:
			_tick_timer = 0.0
			_ticks_applied += 1
			_apply_tick_damage()
		
		# Terminar cuando se alcance la duración (si no usamos visual mejorado)
		if not _use_enhanced:
			queue_redraw()  # Redibujar para mantener el visual actualizado
			if _timer >= duration:
				queue_free()


# ═══════════════════════════════════════════════════════════════════════════════
# CLASE INTERNA: OrbitalManager
# ═══════════════════════════════════════════════════════════════════════════════

class OrbitalManager extends Node2D:
	var orbitals: Array = []
	var orbital_weapon_id: String = ""
	var orbital_count: int = 3
	var orbital_radius: float = 120.0
	var orbital_damage: float = 8.0
	var orbital_speed: float = 200.0
	var color: Color = Color(0.7, 0.3, 1.0)
	var crit_chance: float = 0.0
	var crit_damage: float = 2.0  # Multiplicador de daño crítico
	var knockback: float = 20.0  # Knockback base de orbitales
	
	# Efectos especiales
	var effect: String = "none"
	var effect_value: float = 0.0
	var effect_duration: float = 0.0

	var _rotation_angle: float = 0.0
	var _last_hit_times: Dictionary = {}  # enemy_id -> last_hit_time
	var _hit_cooldown: float = 0.5  # Tiempo entre hits al mismo enemigo
	var _cleanup_counter: int = 0  # Contador para limpiar _last_hit_times periódicamente
	var _enhanced_visual: OrbitalsVisualContainer = null
	var _use_enhanced: bool = false

	func update_orbitals(data: Dictionary) -> void:
		"""Actualizar o crear orbitales con nuevos datos"""
		var new_weapon_id = data.get("weapon_id", "")
		var new_count = data.get("orbital_count", 3)

		# Si es la misma arma, actualizar stats
		if new_weapon_id == orbital_weapon_id:
			orbital_damage = data.get("damage", orbital_damage)
			orbital_radius = data.get("orbital_radius", orbital_radius)

			# Actualizar conteo si cambió
			if new_count != orbital_count:
				orbital_count = new_count
				_recreate_orbitals()
			return

		# Nueva arma orbital
		orbital_weapon_id = new_weapon_id
		orbital_count = new_count
		orbital_radius = data.get("orbital_radius", 120.0)
		orbital_damage = data.get("damage", 8.0)
		orbital_speed = data.get("speed", 200.0)
		color = data.get("color", Color(0.7, 0.3, 1.0))
		crit_chance = data.get("crit_chance", 0.0)
		crit_damage = data.get("crit_damage", 2.0)
		knockback = data.get("knockback", 20.0)
		
		# Efectos especiales
		effect = data.get("effect", "none")
		effect_value = data.get("effect_value", 0.0)
		effect_duration = data.get("effect_duration", 0.0)

		_recreate_orbitals()

	func _recreate_orbitals() -> void:
		# Limpiar orbitales existentes
		for orbital in orbitals:
			if is_instance_valid(orbital):
				orbital.queue_free()
		orbitals.clear()

		# Limpiar visual mejorado anterior
		if _enhanced_visual:
			_enhanced_visual.queue_free()
			_enhanced_visual = null
			_use_enhanced = false

		# Intentar crear visual mejorado
		if orbital_weapon_id != "" and ProjectileVisualManager.instance:
			var weapon_data = WeaponDatabase.get_weapon_data(orbital_weapon_id)
			if not weapon_data.is_empty():
				_enhanced_visual = ProjectileVisualManager.instance.create_orbit_visual(
					orbital_weapon_id, orbital_count, orbital_radius, weapon_data)
				if _enhanced_visual:
					add_child(_enhanced_visual)
					_use_enhanced = true
				else:
					push_warning("[OrbitalManager] create_orbit_visual retornó null para: %s" % orbital_weapon_id)
			else:
				push_warning("[OrbitalManager] weapon_data vacío para: %s" % orbital_weapon_id)
		else:
			if orbital_weapon_id == "":
				push_warning("[OrbitalManager] weapon_id vacío")
			if not ProjectileVisualManager.instance:
				push_warning("[OrbitalManager] ProjectileVisualManager.instance es null")

		# Crear nuevos orbitales (siempre necesarios para detección de colisión)
		for i in range(orbital_count):
			var orbital = _create_orbital(i)
			orbitals.append(orbital)
			add_child(orbital)

	func _create_orbital(index: int) -> Node2D:
		var orbital = Area2D.new()
		orbital.name = "Orbital_%d" % index
		orbital.collision_layer = 0
		orbital.set_collision_layer_value(4, true)  # Proyectiles
		orbital.collision_mask = 0
		orbital.set_collision_mask_value(2, true)
		orbital.set_collision_mask_value(3, true)
		orbital.set_collision_mask_value(4, true)

		# Collision shape
		var shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 15.0
		shape.shape = circle
		orbital.add_child(shape)

		# Visual (solo si no usamos visual mejorado)
		if not _use_enhanced:
			var visual = _create_orbital_visual()
			orbital.add_child(visual)

		# Conectar señales
		orbital.body_entered.connect(_on_orbital_hit.bind(orbital))
		orbital.area_entered.connect(_on_orbital_area_hit.bind(orbital))
		
		# CRITICAL FIX: Añadir al grupo de proyectiles para que AttackManager pueda limpiarlos adecuadamente
		# Esto previene "ghost orbs" al refrescar stats
		if orbital_weapon_id != "":
			orbital.add_to_group("weapon_projectiles_" + orbital_weapon_id)
			orbital.add_to_group("projectiles") # Grupo general

		return orbital

	func _create_orbital_visual() -> Node2D:
		var sprite = Sprite2D.new()

		# Crear imagen circular
		var size = 30
		var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
		var center = Vector2(size / 2.0, size / 2.0)
		var radius = size / 2.0 - 2.0

		for x in range(size):
			for y in range(size):
				var pos = Vector2(x, y)
				var dist = pos.distance_to(center)
				if dist <= radius:
					var t = dist / radius
					var alpha = 1.0 - t * 0.5
					image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
				else:
					image.set_pixel(x, y, Color(0, 0, 0, 0))

		sprite.texture = ImageTexture.create_from_image(image)
		return sprite

	func _on_orbital_hit(body: Node2D, orbital: Node2D) -> void:
		if body.is_in_group("enemies"):
			_damage_enemy(body)

	func _on_orbital_area_hit(area: Area2D, orbital: Node2D) -> void:
		var parent = area.get_parent()
		if parent and parent.is_in_group("enemies"):
			_damage_enemy(parent)

	func _damage_enemy(enemy: Node) -> void:
		var enemy_id = enemy.get_instance_id()
		var current_time = Time.get_ticks_msec() / 1000.0

		# Verificar cooldown de hit
		if _last_hit_times.has(enemy_id):
			if current_time - _last_hit_times[enemy_id] < _hit_cooldown:
				return

		_last_hit_times[enemy_id] = current_time

		var final_damage = orbital_damage
		if randf() < crit_chance:
			final_damage *= crit_damage  # Usar multiplicador de crítico variable

		if enemy.has_method("take_damage"):
			enemy.take_damage(int(final_damage))
			# Aplicar life steal
			ProjectileFactory.apply_life_steal(get_tree(), final_damage)
			# Verificar execute threshold después del daño
			ProjectileFactory.check_execute(get_tree(), enemy)
			# Aplicar efectos de estado por probabilidad
			ProjectileFactory.apply_status_effects_chance(get_tree(), enemy)
		
		# Calcular knockback real (con bonus si aplica)
		var final_knockback = knockback
		if effect == "knockback_bonus":
			final_knockback *= effect_value  # effect_value es el multiplicador
		
		# Aplicar knockback hacia afuera (desde el centro del jugador)
		if final_knockback != 0 and enemy.has_method("apply_knockback"):
			var kb_dir = (enemy.global_position - global_position).normalized()
			enemy.apply_knockback(kb_dir * final_knockback)
		
		# Aplicar efectos especiales
		_apply_orbital_effect(enemy)
	
	func _apply_orbital_effect(enemy: Node) -> void:
		"""Aplicar efectos especiales de orbitales"""
		if effect == "none":
			return
		
		# Obtener duración modificada por status_duration_mult
		var modified_duration = ProjectileFactory.get_modified_effect_duration(get_tree(), effect_duration)
		var modified_value_as_duration = ProjectileFactory.get_modified_effect_duration(get_tree(), effect_value)
		
		match effect:
			"slow":
				if enemy.has_method("apply_slow"):
					enemy.apply_slow(effect_value, modified_duration)
			"burn":
				if enemy.has_method("apply_burn"):
					enemy.apply_burn(effect_value, modified_duration)
			"freeze":
				if enemy.has_method("apply_freeze"):	
					enemy.apply_freeze(effect_value, modified_duration)
				elif enemy.has_method("apply_slow"):
					enemy.apply_slow(effect_value, modified_duration)
			"stun":
				if enemy.has_method("apply_stun"):
					enemy.apply_stun(modified_value_as_duration)  # effect_value = duración del stun
			"pull":
				if enemy.has_method("apply_pull"):
					enemy.apply_pull(global_position, effect_value, modified_duration)
			"blind":
				if enemy.has_method("apply_blind"):
					enemy.apply_blind(modified_value_as_duration)  # effect_value = duración del blind
			"lifesteal":
				var player = _get_orbital_player()
				if player and player.has_method("heal"):
					var heal_amount = roundi(effect_value)
					player.heal(heal_amount)
					FloatingText.spawn_heal(player.global_position + Vector2(0, -30), heal_amount)
			"bleed":
				if enemy.has_method("apply_bleed"):
					enemy.apply_bleed(effect_value, modified_duration)
			"shadow_mark":
				if enemy.has_method("apply_shadow_mark"):
					enemy.apply_shadow_mark(effect_value, modified_duration)
			"chain":
				# Crear salto de daño a enemigos cercanos
				_apply_chain_damage(enemy, roundi(effect_value))
	
	func _apply_chain_damage(first_target: Node, chain_count: int) -> void:
		"""Aplicar daño encadenado a enemigos cercanos"""
		var enemies_hit = [first_target]
		var current_pos = first_target.global_position
		var chain_damage = orbital_damage * 0.6  # Daño reducido para chains
		
		for i in range(chain_count):
			var next_target = _find_chain_target(current_pos, enemies_hit)
			if next_target == null:
				break
			
			# Aplicar daño al siguiente objetivo
			if next_target.has_method("take_damage"):
				next_target.take_damage(int(chain_damage))
				# Aplicar life steal y execute para chains
				ProjectileFactory.apply_life_steal(get_tree(), chain_damage)
				ProjectileFactory.check_execute(get_tree(), next_target)
			
			# Crear efecto visual de rayo entre objetivos
			_spawn_chain_lightning_visual(current_pos, next_target.global_position)
			
			enemies_hit.append(next_target)
			current_pos = next_target.global_position
			chain_damage *= 0.8  # Reducir daño progresivamente
	
	func _find_chain_target(from_pos: Vector2, exclude: Array) -> Node:
		"""Buscar siguiente objetivo para chain"""
		var enemies = get_tree().get_nodes_in_group("enemies")
		var closest: Node = null
		var closest_dist = 200.0  # Rango máximo de chain
		
		for enemy in enemies:
			if enemy in exclude or not is_instance_valid(enemy):
				continue
			var dist = from_pos.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest = enemy
				closest_dist = dist
		
		return closest
	
	func _spawn_chain_lightning_visual(from_pos: Vector2, to_pos: Vector2) -> void:
		"""Crear efecto visual de rayo entre posiciones"""
		var line = Line2D.new()
		line.width = 3.0
		line.default_color = Color(0.8, 0.6, 1.0, 0.9)  # Púrpura arcano
		line.add_point(from_pos)
		line.add_point(to_pos)
		line.z_index = 100
		get_tree().current_scene.add_child(line)
		
		# Desvanecer y eliminar
		var tween = line.create_tween()
		tween.tween_property(line, "modulate:a", 0.0, 0.2)
		tween.tween_callback(line.queue_free)

	func _get_orbital_player() -> Node:
		"""Obtener referencia al jugador para lifesteal"""
		if not get_tree():
			return null
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			return players[0]
		return null

	func _process(delta: float) -> void:
		# Rotar orbitales
		_rotation_angle += orbital_speed * delta * 0.01

		# Posicionar cada orbital
		for i in range(orbitals.size()):
			if not is_instance_valid(orbitals[i]):
				continue

			var angle = _rotation_angle + (TAU / orbitals.size()) * i
			var pos = Vector2(
				cos(angle) * orbital_radius,
				sin(angle) * orbital_radius
			)
			orbitals[i].position = pos

		# Actualizar visual mejorado con las posiciones actuales
		if _use_enhanced and _enhanced_visual:
			var positions: Array[Vector2] = []
			for orbital in orbitals:
				if is_instance_valid(orbital):
					positions.append(orbital.position)
			_enhanced_visual.update_orbital_positions(positions)
		
		# Limpiar _last_hit_times cada 60 frames (~1 segundo) para evitar memory leak
		_cleanup_counter += 1
		if _cleanup_counter >= 60:
			_cleanup_counter = 0
			_cleanup_invalid_hit_times()
	
	func _cleanup_invalid_hit_times() -> void:
		"""Eliminar entradas de enemigos que ya no existen para prevenir memory leak"""
		var keys_to_remove: Array = []
		for enemy_id in _last_hit_times.keys():
			# is_instance_id_valid verifica si el object ID sigue siendo válido
			if not is_instance_id_valid(enemy_id):
				keys_to_remove.append(enemy_id)
		for key in keys_to_remove:
			_last_hit_times.erase(key)


# ═══════════════════════════════════════════════════════════════════════════════
# CLASE INTERNA: ChainProjectile
# Rayo encadenado INSTANTÁNEO que salta entre enemigos
# ═══════════════════════════════════════════════════════════════════════════════

class ChainProjectile extends Node2D:
	var damage: float = 15.0
	var chain_count: int = 2
	var chain_range: float = 150.0
	var color: Color = Color(1.0, 1.0, 0.3)
	var knockback: float = 40.0
	var crit_chance: float = 0.0
	var crit_damage: float = 2.0  # Multiplicador de daño crítico
	var effect: String = "none"
	var effect_value: float = 0.0
	var effect_duration: float = 2.0  # Duración de efectos
	var weapon_id: String = ""

	var first_target: Node2D = null
	var enemies_hit: Array = []

	var _enhanced_visual: Node2D = null  # ChainLightningVisual, FrozenThunderVisual, etc.
	var _use_enhanced: bool = false
	var _chain_delay: float = 0.08  # Delay entre cada salto de cadena

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

		# Crear visual mejorado
		_create_chain_visual()

		# Ejecutar la cadena de rayos instantáneos
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
		"""Ejecutar la secuencia de rayos encadenados de forma instantánea"""
		var current_pos = global_position
		var current_target = first_target
		var chains_done = 0

		while chains_done < chain_count and current_target != null and is_instance_valid(current_target):
			# Guardar posición para el rayo
			var target_pos = current_target.global_position

			# Mostrar rayo visual instantáneo
			if _use_enhanced and _enhanced_visual:
				_enhanced_visual.fire_at(
					_enhanced_visual.to_local(current_pos),
					_enhanced_visual.to_local(target_pos)
				)

			# Aplicar daño instantáneo
			_apply_damage_to_target(current_target)
			enemies_hit.append(current_target)

			# Esperar un poco antes del siguiente salto (efecto visual)
			if chains_done < chain_count - 1:
				await get_tree().create_timer(_chain_delay).timeout

			# Actualizar posición para el siguiente salto
			current_pos = target_pos

			# Buscar siguiente objetivo
			current_target = _find_next_target(current_pos)
			chains_done += 1

		# Esperar a que el visual termine y destruir
		# Esperar a que el visual termine y destruir
		if _enhanced_visual and _enhanced_visual.has_signal("all_chains_finished"):
			await _enhanced_visual.all_chains_finished
		else:
			# Fallback más generoso si no hay señal
			await get_tree().create_timer(1.0).timeout
			
		if is_instance_valid(self):
			queue_free()

	func _apply_damage_to_target(target: Node2D) -> void:
		"""Aplicar daño a un objetivo"""
		if not is_instance_valid(target):
			return

		var final_damage = damage
		if randf() < crit_chance:
			final_damage *= crit_damage  # Usar multiplicador de crítico variable

		if target.has_method("take_damage"):
			target.take_damage(int(final_damage))
			# Aplicar life steal
			ProjectileFactory.apply_life_steal(get_tree(), final_damage)

		# Aplicar knockback
		if knockback != 0 and target.has_method("apply_knockback"):
			var kb_dir = (target.global_position - global_position).normalized()
			target.apply_knockback(kb_dir * knockback)
		
		# Aplicar efectos especiales de cadena
		_apply_chain_effect(target)

	func _apply_chain_effect(target: Node2D) -> void:
		"""Aplicar efectos especiales de proyectiles encadenados"""
		if effect == "none" or effect == "chain":
			return
		
		# Usar la duración del efecto configurada (ya cargada en setup)
		match effect:
			"freeze_chain":
				# Congelar a cada enemigo en la cadena
				if target.has_method("apply_freeze"):
					target.apply_freeze(effect_value, effect_duration)
				elif target.has_method("apply_slow"):
					target.apply_slow(effect_value, effect_duration)
			"burn_chain":
				# Quemar a cada enemigo en la cadena
				if target.has_method("apply_burn"):
					target.apply_burn(effect_value, effect_duration)
			"lifesteal_chain":
				# Curar al jugador por cada enemigo
				var player = _get_player()
				if player and player.has_method("heal"):
					var heal_amount = roundi(effect_value)
					player.heal(heal_amount)
					FloatingText.spawn_heal(player.global_position + Vector2(0, -30), heal_amount)
			"stun":
				if target.has_method("apply_stun"):
					target.apply_stun(effect_value)  # effect_value = duración del stun
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
		"""Obtener referencia al jugador para lifesteal"""
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

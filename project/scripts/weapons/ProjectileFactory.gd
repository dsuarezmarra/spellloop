# ProjectileFactory.gd
# Fábrica centralizada para crear proyectiles de todas las armas
# Se integra con SimpleProjectile existente y añade nuevos tipos
#
# OPTIMIZACIÓN v2.0: Sistema de caching para referencias globales

extends Node
class_name ProjectileFactory

# Referencia a la escena de proyectil base
static var _projectile_scene: PackedScene = null

# Acumulador de life steal para curar cuando llegue a 1+
static var _life_steal_accumulator: float = 0.0

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE CACHING (OPTIMIZACIÓN)
# Evita llamar get_nodes_in_group() miles de veces por segundo
# ═══════════════════════════════════════════════════════════════════════════════

static var _cached_player_stats: Node = null
static var _cached_player: Node = null
static var _cache_frame: int = -1  # Frame en que se actualizó el cache

static func _get_cached_player_stats(tree: SceneTree) -> Node:
	"""Obtener PlayerStats con caching por frame"""
	if tree == null:
		return null
	
	# Actualizar cache solo una vez por frame
	var current_frame = Engine.get_process_frames()
	if _cache_frame != current_frame or not is_instance_valid(_cached_player_stats):
		var nodes = tree.get_nodes_in_group("player_stats")
		_cached_player_stats = nodes[0] if not nodes.is_empty() else null
		_cache_frame = current_frame
	
	return _cached_player_stats

static func _get_cached_player(tree: SceneTree) -> Node:
	"""Obtener Player con caching"""
	if tree == null:
		return null
	
	if not is_instance_valid(_cached_player):
		var nodes = tree.get_nodes_in_group("player")
		_cached_player = nodes[0] if not nodes.is_empty() else null
	
	return _cached_player

# ═══════════════════════════════════════════════════════════════════════════════
# RESET PARA NUEVA PARTIDA
# ═══════════════════════════════════════════════════════════════════════════════

static func reset_for_new_game() -> void:
	"""Resetear estado estático para nueva partida"""
	_life_steal_accumulator = 0.0
	# Limpiar cache
	_cached_player_stats = null
	_cached_player = null
	_cache_frame = -1


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
	
	# OPTIMIZACIÓN: Usar cache en lugar de get_nodes_in_group
	var player_stats = _get_cached_player_stats(tree)
	if player_stats and player_stats.has_method("get_stat"):
		var duration_mult = float(player_stats.get_stat("status_duration_mult"))
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
	
	# OPTIMIZACIÓN: Usar cache en lugar de get_nodes_in_group
	var player_stats = _get_cached_player_stats(tree)
	if not player_stats or not player_stats.has_method("get_stat"):
		return
	
	# Obtener multiplicador de duración
	var status_duration_mult = float(player_stats.get_stat("status_duration_mult"))
	if status_duration_mult <= 0:
		status_duration_mult = 1.0
	
	# === BURN CHANCE ===
	var burn_chance = float(player_stats.get_stat("burn_chance"))
	if burn_chance > 0 and randf() < burn_chance:
		if enemy.has_method("apply_burn"):
			var burn_dmg = float(player_stats.get_stat("burn_damage")) if player_stats.has_method("get_stat") else 3.0
			if burn_dmg <= 0:
				burn_dmg = 3.0
			enemy.apply_burn(burn_dmg, 3.0 * status_duration_mult)  # 3s base duration
			# print("[StatusEffect] 🔥 Burn aplicado! (chance: %.0f%%)" % (burn_chance * 100))
	
	# === FREEZE CHANCE ===
	var freeze_chance = float(player_stats.get_stat("freeze_chance"))
	if freeze_chance > 0 and randf() < freeze_chance:
		if enemy.has_method("apply_freeze"):
			enemy.apply_freeze(1.0, 1.0 * status_duration_mult)  # 1s freeze
			# print("[StatusEffect] ❄️ Freeze aplicado! (chance: %.0f%%)" % (freeze_chance * 100))
		elif enemy.has_method("apply_slow"):
			enemy.apply_slow(0.5, 2.0 * status_duration_mult)  # Fallback: 50% slow 2s
	
	# === BLEED CHANCE ===
	var bleed_chance = float(player_stats.get_stat("bleed_chance"))
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
	
	# OPTIMIZACIÓN: Usar cache en lugar de get_nodes_in_group
	var player_stats = _get_cached_player_stats(tree)
	if not player_stats or not player_stats.has_method("get_stat"):
		return 1.0
	
	var multiplier = 1.0
	
	# === DAMAGE VS SLOWED ===
	var damage_vs_slowed = float(player_stats.get_stat("damage_vs_slowed"))
	if damage_vs_slowed > 0:
		if "_is_slowed" in enemy and enemy._is_slowed:
			multiplier += damage_vs_slowed
	
	# === DAMAGE VS BURNING ===
	var damage_vs_burning = float(player_stats.get_stat("damage_vs_burning"))
	if damage_vs_burning > 0:
		if "_is_burning" in enemy and enemy._is_burning:
			multiplier += damage_vs_burning
	
	# === DAMAGE VS FROZEN ===
	var damage_vs_frozen = float(player_stats.get_stat("damage_vs_frozen"))
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

	# Añadir al árbol primero para asegurar ciclo de vida correcto
	var tree = owner.get_tree()
	if tree and tree.current_scene:
		tree.current_scene.add_child(projectile)
	else:
		owner.get_parent().add_child(projectile)

	# CRÍTICO: Usar configure_and_launch para inicialización ATÓMICA y UNIFICADA
	# Esto asegura que todos los stats, efectos y visuales se configuren en un solo paso
	var start_pos = data.get("start_position", owner.global_position)
	var dir = data.get("direction", Vector2.RIGHT)
	
	projectile.configure_and_launch(data, start_pos, dir, true)

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

static func _create_base_projectile(_data: Dictionary) -> SimpleProjectile:
	"""Crear instancia base de SimpleProjectile (Wrapper del Pool)"""
	# OPTIMIZACIÓN: Usar pool. La configuración completa ocurre en configure_and_launch
	return ProjectilePool.acquire()


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
		# Use cached player for calculators
		var player = _get_player()
		
		# Calcular daño final usando el sistema centralizado
		var damage_result = DamageCalculator.calculate_final_damage(
			damage, enemy, player, crit_chance, crit_damage
		)
		
		# Aplicar daño y todos los efectos asociados
		DamageCalculator.apply_damage_with_effects(
			get_tree(),
			enemy,
			damage_result,
			(enemy.global_position - global_position).normalized(), # Knockback direction
			knockback
		)
		
		# LOG: Registrar daño de beam (usando el valor final calculado)
		# Note: apply_damage_with_effects doesn't log specifically for "BEAM", so we keep explicit log here if needed
		# or move logging inside DamageCalculator (ideal for v2)
		# For now, we log here for consistency with debugging requirements
		DamageLogger.log_beam_damage(weapon_id, enemy.name, damage_result.get_int_damage(), damage_result.is_crit)

		# Aplicar efectos especiales (que no maneja DamageCalculator aún)
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
			# FIX: Ignorar damage_per_tick hardcodeado en config para permitir escalado
			# Usar la configuración solo para timing (intervalo) y conteo
			tick_interval = config.get("tick_interval", 0.25)
			total_ticks = config.get("total_ticks", 4)
			# Distribuir el daño total dinámico entre los tics
			damage_per_tick = damage / float(total_ticks)
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

		# Crear área de detección física (OPTIMIZACION PERFORMANCE)
		var area = Area2D.new()
		area.name = "DetectionArea"
		area.collision_layer = 0
		# FIX: Enemigos están en Layer 2 (EnemyBase), pero algunas configs pueden usar Layer 3 (4).
		# Usamos máscara 6 (2 + 4) para cubrir ambos casos.
		area.collision_mask = 6 
		add_child(area)
		
		var shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = aoe_radius
		shape.shape = circle
		area.add_child(shape)
		
		# Conectar señales para tracking eficiente
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
		
		# Crear visual (mejorado si está disponible)
		_create_aoe_visual()

		# Aplicar primer tic de daño inmediatamente
		# CRÍTICO: Esperar un frame físico para que el área detecte colisiones iniciales
		# o usar query manual si se necesita instantáneo. 
		# Para consistencia con old logic, forzamos un update manual del physics state o aceptamos 1 frame delay.
		# Aceptamos 1 frame delay para _enemies_in_area, pero para el primer tick usamos PhysicsDirectSpaceState
		# para dar feedback instantáneo al spawnear (importante para armas reactivas)
		
		_initial_burst_check()
		_ticks_applied = 1
	
	func _initial_burst_check() -> void:
		"""Check inicial instantáneo usando RayCast/ShapeCast para no esperar al frame de física"""
		var space = get_world_2d().direct_space_state
		var query = PhysicsShapeQueryParameters2D.new()
		var circle = CircleShape2D.new()
		circle.radius = aoe_radius
		query.shape = circle
		query.transform = global_transform
		query.collision_mask = 6 # Enemy layer (2 + 4)
		query.collide_with_bodies = true
		query.collide_with_areas = true
		
		var results = space.intersect_shape(query, 64) # Max 64 enemies burst detection
		for res in results:
			var collider = res.collider
			if collider and collider.is_in_group("enemies"):
				var id = collider.get_instance_id()
				_enemies_in_area[id] = collider
				_apply_damage_tick(collider)

	func _on_body_entered(body: Node2D) -> void:
		if body.is_in_group("enemies"):
			var enemy_id = body.get_instance_id()
			_enemies_in_area[enemy_id] = body

	func _on_body_exited(body: Node2D) -> void:
		var enemy_id = body.get_instance_id()
		_enemies_in_area.erase(enemy_id)

	func _on_area_entered(area: Area2D) -> void:
		# Fallback para enemigos que son areas
		var parent = area.get_parent()
		if parent and parent.is_in_group("enemies"):
			var enemy_id = parent.get_instance_id()
			_enemies_in_area[enemy_id] = parent

	func _apply_tick_damage() -> void:
		"""Aplicar un tic de daño a todos los enemigos ACTUALMENTE en el área"""
		# OPTIMIZACIÓN: Solo iterar sobre los enemigos detectados por física
		# Esto reduce complejidad de O(TotalEnemies) a O(EnemiesInRadius)
		
		var ids_to_remove = []
		
		for enemy_id in _enemies_in_area:
			var enemy = _enemies_in_area[enemy_id]
			
			# Validar que siga existiendo (pudo morir)
			if is_instance_valid(enemy):
				_apply_damage_tick(enemy)
			else:
				ids_to_remove.append(enemy_id)
		
		# Limpiar referencias inválidas
		for id in ids_to_remove:
			_enemies_in_area.erase(id)

	func _apply_damage_tick(enemy: Node) -> void:
		"""Aplicar daño de un tic a un enemigo"""
		# Use cached player for calculators
		var player = null
		if not get_tree():
			return
		
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
			
		# Calcular daño final usando el sistema centralizado
		# Nota: damage_per_tick ya debería incluir modificadores del arma, 
		# pero NO modificadores situacionales del jugador (brawler, etc.)
		var damage_result = DamageCalculator.calculate_final_damage(
			damage_per_tick, enemy, player, crit_chance, crit_damage
		)

		var final_damage = damage_result.get_int_damage()

		# Aplicar daño
		if enemy.has_method("take_damage"):
			enemy.take_damage(final_damage)
			
			# LOG: Registrar daño AOE con info de ticks
			DamageLogger.log_aoe_damage(weapon_id, enemy.name, final_damage, "tick %d/%d" % [_ticks_applied, total_ticks])
			
			# Modulo de efectos secundarios centralizado
			# No usamos apply_damage_with_effects DIRECTAMENTE porque AOE requiere lógica propia para logging y knockback
			# pero llamamos a los helpers individuales
			ProjectileFactory.apply_life_steal(get_tree(), damage_result.final_damage)
			ProjectileFactory.check_execute(get_tree(), enemy)
			
			if not _enemies_damaged.has(enemy.get_instance_id()):
				ProjectileFactory.apply_status_effects_chance(get_tree(), enemy)

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
			# OPTIMIZACIÓN: Removido queue_redraw() que se llamaba cada frame
			# El AOE es estático, no necesita redibujar constantemente
			if _timer >= duration:
				queue_free()

# ═══════════════════════════════════════════════════════════════════════════════
# NOTA: Las clases OrbitalManager y ChainProjectile han sido extraídas a:
# - scripts/weapons/projectiles/OrbitalManager.gd
# - scripts/weapons/projectiles/ChainProjectile.gd
# ═══════════════════════════════════════════════════════════════════════════════


# EnemyAttackSystem.gd
# Sistema de ataque para enemigos - Soporta todos los arquetipos
# Gestiona cooldowns, targeting y ejecuciÃ³n de ataques
#
# Nota: Este archivo usa lambdas con variables capturadas que se reasignan
# intencionalmente para mantener estado local en animaciones y timers.
@warning_ignore("confusable_capture_reassignment")

extends Node
class_name EnemyAttackSystem

signal attacked_player(damage: int, is_melee: bool)

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# VFX MANAGER INTEGRATION
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

## Intentar usar VFXManager para spawner efectos visuales
## Retorna true si VFXManager manejÃ³ el efecto, false para usar fallback procedural
func _try_spawn_via_vfxmanager(vfx_type: String, category: String, position: Vector2, radius: float = 100.0, duration: float = 0.5) -> bool:
	if not Engine.has_singleton("VFXManager"):
		# Intentar obtener desde el Ã¡rbol si no es singleton
		var vfx_mgr = get_node_or_null("/root/VFXManager")
		if vfx_mgr:
			match category:
				"aoe":
					vfx_mgr.spawn_aoe(vfx_type, position, radius, duration)
					return true
				"telegraph":
					vfx_mgr.spawn_telegraph(vfx_type, position, radius, duration)
					return true
				"boss":
					vfx_mgr.spawn_boss_vfx(vfx_type, position, radius / 100.0)
					return true
				"aura":
					if is_instance_valid(enemy):
						vfx_mgr.spawn_aura(vfx_type, enemy, true)
						return true
	return false

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

# Propiedades de ataque
var attack_cooldown: float = 1.5
var attack_timer: float = 0.0
var attack_range: float = 32.0
var attack_damage: int = 5
var is_ranged: bool = false
var projectile_scene: PackedScene = null
var projectile_speed: float = 200.0

# Propiedades de ataque especial
var archetype: String = "melee"
var element_type: String = "physical"
var special_abilities: Array = []
var modifiers: Dictionary = {}

# Habilidades Modulares (Phase 1 Refactor)
var abilities: Array = []

# AoE
var aoe_radius: float = 100.0
var aoe_damage_multiplier: float = 0.7

# Breath
var breath_cone_angle: float = 45.0  # grados
var breath_range: float = 150.0

# Multi-attack
var multi_attack_count: int = 3

# Referencias
var enemy: Node = null
var player: Node = null

# Referencia a EnemyProjectile script
var EnemyProjectileScript = null

func _ready() -> void:
	# CRÃƒÂTICO: Respetar la pausa del juego
	process_mode = Node.PROCESS_MODE_PAUSABLE

	enemy = get_parent()
	# Precargar script de proyectil
	EnemyProjectileScript = load("res://scripts/enemies/EnemyProjectile.gd")
	# print("[EnemyAttackSystem] Inicializado para: %s" % enemy.name)

func initialize(p_attack_cooldown: float, p_attack_range: float, p_damage: int, p_is_ranged: bool = false, p_projectile_scene: PackedScene = null) -> void:
	"""Configurar parÃƒÂ¡metros de ataque"""
	attack_cooldown = p_attack_cooldown
	attack_range = p_attack_range
	attack_damage = p_damage
	is_ranged = p_is_ranged
	projectile_scene = p_projectile_scene
	# print("[EnemyAttackSystem] Configurado: cooldown=%.2f, range=%.0f, damage=%d, ranged=%s" % [attack_cooldown, attack_range, attack_damage, is_ranged])

func initialize_full(config: Dictionary) -> void:
	"""InicializaciÃƒÂ³n completa con todos los parÃƒÂ¡metros"""
	attack_cooldown = config.get("attack_cooldown", 1.5)
	attack_range = config.get("attack_range", 32.0)
	attack_damage = config.get("damage", 5)
	is_ranged = config.get("is_ranged", false)
	archetype = config.get("archetype", "melee")
	element_type = config.get("element_type", "physical")
	special_abilities = config.get("special_abilities", [])
	modifiers = config.get("modifiers", {})

	# Configurar segÃƒÂºn arquetipo
	match archetype:
		"aoe":
			aoe_radius = modifiers.get("aoe_radius", 100.0)
			aoe_damage_multiplier = modifiers.get("aoe_damage_mult", 0.7)
		"breath":
			breath_cone_angle = modifiers.get("breath_angle", 45.0)
			breath_range = modifiers.get("breath_range", 150.0)
		"multi":
			multi_attack_count = modifiers.get("attack_count", 3)

	# print("[EnemyAttackSystem] Full config: %s (arch=%s, elem=%s)" % [enemy.name, archetype, element_type])

	# Phase 1 Migration: Setup Ability Objects
	_setup_modular_abilities()

func _setup_modular_abilities() -> void:
	abilities.clear()

	var ability: EnemyAbility = null

	# Mapear lÃ³gica legacy a objetos Ability
	if is_ranged or archetype == "ranged" or archetype == "teleporter" or archetype == "boss":
		# Bosses/Ranged/Teleporter usan proyectiles
		var ranged = EnemyAbility_Ranged.new()
		ranged.projectile_speed = projectile_speed
		ranged.projectile_scene = projectile_scene
		ranged.element_type = element_type
		# ConfiguraciÃ³n especÃ­fica
		if archetype == "multi":
			ranged.projectile_count = multi_attack_count
			ranged.spread_angle = 15.0
		ability = ranged

	elif archetype == "charger":
		# Phase 1: Usar Melee para mantener compatibilidad con EnemyBase movement logic
		# Phase 2: Migrar a EnemyAbility_Dash completo cuando deshabilitemos la lÃ³gica en EnemyBase
		var melee = EnemyAbility_Melee.new()
		ability = melee

	elif archetype == "melee" or archetype == "tank" or archetype == "agile":
		var melee = EnemyAbility_Melee.new()
		ability = melee

	# Si se creÃ³ una habilidad, configurarla y aÃ±adirla
	if ability:
		ability.id = "primary_" + archetype
		ability.cooldown = attack_cooldown
		ability.range_max = attack_range
		abilities.append(ability)
		# print("[EnemyAttackSystem] Migrada habilidad: %s" % ability.id)

	# Phase 2: Map special_abilities strings to active Ability objects
	for ab_name in special_abilities:
		var extra_ability: EnemyAbility = null

		match ab_name:
			"elite_nova", "nova":
				extra_ability = EnemyAbility_Nova.new()
				var cd = modifiers.get("nova_cooldown", modifiers.get("elite_nova_cooldown", 8.0))
				extra_ability.cooldown = cd
				extra_ability.projectile_count = modifiers.get("nova_projectile_count", modifiers.get("elite_nova_projectile_count", 12))

			"elite_summon", "summon":
				extra_ability = EnemyAbility_Summon.new()
				var cd = modifiers.get("summon_cooldown", modifiers.get("elite_summon_cooldown", 10.0))
				extra_ability.cooldown = cd
				extra_ability.summon_count = modifiers.get("summon_count", modifiers.get("elite_summon_count", 3))

			"teleport":
				extra_ability = EnemyAbility_Teleport.new()
				extra_ability.cooldown = modifiers.get("teleport_cooldown", 5.0)

			"poison_attack":
				# Modificar habilidad primaria si existe
				if ability:
					if ability is EnemyAbility_Melee or ability is EnemyAbility_Ranged:
						ability.element_type = "poison"

			"slow_attack":
				if ability:
					if ability is EnemyAbility_Melee or ability is EnemyAbility_Ranged:
						ability.element_type = "ice" # Ice aplica slow/freeze

			"freeze_projectile":
				if ability:
					if ability is EnemyAbility_Melee or ability is EnemyAbility_Ranged:
						ability.element_type = "ice"

			"burn_projectile":
				if ability:
					if ability is EnemyAbility_Melee or ability is EnemyAbility_Ranged:
						ability.element_type = "fire"

			"fire_trail":
				# TODO: Implementar Trail ability si es necesario,
				# o dejar que EnemyBase lo maneje si es movimiento.
				pass


			"stomp_attack", "elite_slam", "aoe_slam":
				extra_ability = EnemyAbility_Aoe.new()
				var cd = modifiers.get("stomp_cooldown", modifiers.get("slam_cooldown", modifiers.get("elite_slam_cooldown", 5.0)))
				extra_ability.cooldown = cd
				extra_ability.radius = modifiers.get("stomp_radius", modifiers.get("slam_radius", modifiers.get("elite_slam_radius", 100.0)))

			# FIX FASE 2: Habilidades fantasma implementadas minimalmente
			"split_on_death":
				# Marcador en enemy para que EnemyBase.die() haga spawn de 2 hijos
				if enemy and "split_on_death" not in enemy:
					enemy.set_meta("split_on_death", true)

			"evasion":
				# Marcador en enemy para que EnemyBase.take_damage() haga dodge check
				var evasion_chance = modifiers.get("evasion_chance", 0.25)
				if enemy:
					enemy.set_meta("evasion_chance", evasion_chance)

			"counter_attack":
				# Marcador en enemy para contraataque en take_damage
				var counter_damage_mult = modifiers.get("counter_damage_mult", 0.5)
				if enemy:
					enemy.set_meta("counter_attack", true)
					enemy.set_meta("counter_damage_mult", counter_damage_mult)

			"fire_zone":
				# Usar AoE ability con elemento fuego como zona persistente
				extra_ability = EnemyAbility_Aoe.new()
				extra_ability.cooldown = modifiers.get("fire_zone_cooldown", 6.0)
				extra_ability.radius = modifiers.get("fire_zone_radius", 80.0)
				extra_ability.element_type = "fire"

			"burn_aura":
				# Marcador para aura pasiva de fuego (daño por proximidad)
				if enemy:
					enemy.set_meta("burn_aura", true)
					enemy.set_meta("burn_aura_radius", modifiers.get("burn_aura_radius", 60.0))
					enemy.set_meta("burn_aura_dps", modifiers.get("burn_aura_dps", 5))

			"freeze_zone":
				# Usar AoE ability con elemento hielo
				extra_ability = EnemyAbility_Aoe.new()
				extra_ability.cooldown = modifiers.get("freeze_zone_cooldown", 7.0)
				extra_ability.radius = modifiers.get("freeze_zone_radius", 80.0)
				extra_ability.element_type = "ice"

			"ice_armor":
				# Marcador para reducción de daño + slow al atacante
				if enemy:
					enemy.set_meta("ice_armor", true)
					enemy.set_meta("ice_armor_reduction", modifiers.get("ice_armor_reduction", 0.2))

			"multi_element":
				# Ciclar elementos en cada ataque
				if enemy:
					enemy.set_meta("multi_element", true)
					enemy.set_meta("element_cycle", ["fire", "ice", "arcane", "void"])
					enemy.set_meta("element_cycle_idx", 0)

			"dive_attack":
				# Usar Dash ability como equivalente de dive
				extra_ability = EnemyAbility_Dash.new()
				extra_ability.cooldown = modifiers.get("dive_cooldown", 5.0)

			"keep_distance", "erratic_movement":
				# Estos son comportamientos de movimiento, no de ataque
				# Se manejan por el archetype en EnemyBase, no necesitan ability object
				pass

		if extra_ability:
			extra_ability.id = ab_name
			abilities.append(extra_ability)
			# print("[EnemyAttackSystem] Added extra ability: %s" % ab_name)

# Variables para el sistema de boss agresivo
var is_boss_enemy: bool = false
var boss_attack_timer: float = 0.0
var boss_aoe_timer: float = 0.0
var boss_orbital_spawned: bool = false
var boss_trail_timer: float = 0.0

func _process(delta: float) -> void:
	"""Procesar cooldown y ataque automÃƒÂ¡tico"""
	if not enemy or not is_instance_valid(enemy):
		return

	# Obtener player si no lo tiene
	if not player or not is_instance_valid(player):
		player = _get_player()
		if not player:
			# Solo debug una vez cada 60 frames para no saturar
			if Engine.get_process_frames() % 60 == 0:
				pass  # Debug
			# print("[EnemyAttackSystem] Ã¢Å¡Â Ã¯Â¸Â No se encontrÃƒÂ³ player para %s" % enemy.name)
			return

	# Detectar si es boss
	if not is_boss_enemy and archetype == "boss":
		is_boss_enemy = true
		_init_boss_aggressive_mode()

	# SISTEMA ESPECIAL PARA BOSSES - Atacan constantemente SIN depender del rango
	if is_boss_enemy:
		_process_boss_aggressive_attacks(delta)
		return

	# Sistema normal para enemigos comunes
	if attack_timer > 0:
		attack_timer -= delta
	else:
		pass  # Bloque else
		# Comprobar si el jugador estÃƒÂ¡ en rango
		if _player_in_range():
			_perform_attack()
			attack_timer = attack_cooldown

func _get_player() -> Node:
	"""Obtener referencia al jugador"""
	# MÃƒÂ©todo 1: Desde el enemigo padre (mÃƒÂ¡s directo y fiable)
	if enemy and enemy.has_method("get") and enemy.get("player_ref"):
		return enemy.player_ref

	# MÃƒÂ©todo 2: Buscar en GameManager
	if GameManager and GameManager.player_ref:
		return GameManager.player_ref

	# MÃƒÂ©todo 3: Buscar por grupos
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]

	# MÃƒÂ©todo 4: Buscar en la estructura del ÃƒÂ¡rbol
	var tree = Engine.get_main_loop()
	if tree and tree.root:
		# Buscar Game/PlayerContainer/LoopiaLikePlayer
		var sp = tree.root.get_node_or_null("Game/PlayerContainer/LoopiaLikePlayer")
		if sp:
			return sp

	return null

func _player_in_range() -> bool:
	"""Comprobar si el jugador estÃƒÂ¡ dentro del rango de ataque"""
	if not enemy or not player:
		return false

	var distance = enemy.global_position.distance_to(player.global_position)
	var in_range = distance <= attack_range

	# Debug ocasional (cada 2 segundos aprox) para ver distancias
	#if Engine.get_process_frames() % 120 == 0:
	#	print("[EnemyAttackSystem] %s: dist=%.1f, range=%.1f, in_range=%s" % [enemy.name, distance, attack_range, in_range])

	return in_range

func _perform_attack() -> void:
	"""Ejecutar el ataque segÃƒÂºn arquetipo"""
	if not enemy or not player:
		return

	# PHASE 1: Modular Ability Execution
	if not abilities.is_empty():
		var context = {
			"damage": attack_damage,
			"element_type": element_type,
			"modifiers": modifiers
		}

		# Ejecutar todas las habilidades disponibles (por ahora solo la primaria)
		for ability in abilities:
			# Usar el timer global attack_timer como cooldown compartido por ahora
			# En Phase 2, cada habilidad tendrÃ¡ su propio timer
			if ability.execute(enemy, player, context):
				# SeÃ±al de ataque exitoso
				if ability is EnemyAbility_Melee:
					attacked_player.emit(attack_damage, true)
				elif ability is EnemyAbility_Dash:
					pass # Dash maneja su collision
				elif ability is EnemyAbility_Ranged:
					attacked_player.emit(0, false) # SeÃ±al genÃ©rica para animaciones

		return # ðŸ”¥ Salir para no ejecutar lÃ³gica legacy


	# Obtener arquetipo del enemigo padre si existe
	if enemy.has_method("get") and "archetype" in enemy:
		archetype = enemy.archetype
	if enemy.has_method("get") and "modifiers" in enemy:
		modifiers = enemy.modifiers
	if enemy.has_method("get") and "special_abilities" in enemy:
		special_abilities = enemy.special_abilities

	# SISTEMA DE HABILIDADES Ãƒâ€°LITE - Verificar si es ÃƒÂ©lite y usar habilidades especiales
	var is_elite = enemy.get("is_elite") if "is_elite" in enemy else false
	if is_elite:
		var elite_ability = _try_elite_ability()
		if elite_ability:
			return  # UsÃƒÂ³ una habilidad ÃƒÂ©lite, no hacer ataque normal

	# Ejecutar ataque segÃƒÂºn arquetipo
	match archetype:
		"ranged":
			_perform_ranged_attack()
		"aoe":
			_perform_aoe_attack()
		"breath":
			_perform_breath_attack()
		"multi":
			_perform_multi_attack()
		"teleporter":
			_perform_ranged_attack()  # Los teleporters tambiÃƒÂ©n disparan
		"boss":
			# Los bosses usan el sistema agresivo en _process(), aquÃƒÂ­ solo disparan
			_perform_ranged_attack()
		_:
			# Melee por defecto
			push_warning("[EnemyAttackSystem] âš ï¸ FALLBACK ATTACK USED for %s (Archetype: %s) - Should use Modular Ability" % [enemy.name, archetype])
			if is_ranged:
				_perform_ranged_attack()
			else:
				_perform_melee_attack()

# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
# SISTEMA DE HABILIDADES Ãƒâ€°LITE - EXTREMADAMENTE MEJORADO
# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

var elite_slam_cooldown: float = 0.0
var elite_rage_active: bool = false
var elite_shield_charges: int = 0
var elite_shield_cooldown: float = 0.0
var elite_dash_cooldown: float = 0.0
var elite_nova_cooldown: float = 0.0
var elite_summon_cooldown: float = 0.0
var elite_is_dashing: bool = false
var elite_dash_target: Vector2 = Vector2.ZERO

func _process_elite_cooldowns(delta: float) -> void:
	"""Procesar cooldowns de habilidades ÃƒÂ©lite"""
	if elite_slam_cooldown > 0:
		elite_slam_cooldown -= delta
	if elite_shield_cooldown > 0:
		elite_shield_cooldown -= delta
	if elite_dash_cooldown > 0:
		elite_dash_cooldown -= delta
	if elite_nova_cooldown > 0:
		elite_nova_cooldown -= delta
	if elite_summon_cooldown > 0:
		elite_summon_cooldown -= delta

func _try_elite_ability() -> bool:
	"""Intentar usar una habilidad ÃƒÂ©lite. Retorna true si usÃƒÂ³ una."""
	var delta = get_process_delta_time()
	_process_elite_cooldowns(delta)

	# Verificar rage (se activa automÃƒÂ¡ticamente al bajar HP)
	if not elite_rage_active:
		var rage_threshold = modifiers.get("elite_rage_threshold", 0.5)
		var current_hp_percent = _get_enemy_hp_percent()
		if current_hp_percent <= rage_threshold and "elite_rage" in special_abilities:
			_activate_elite_rage()

	# Probabilidad de usar habilidad ÃƒÂ©lite (configurable, default 50%)
	var ability_chance = modifiers.get("elite_ability_chance", 0.50)
	if randf() > ability_chance:
		return false

	var dist = enemy.global_position.distance_to(player.global_position)

	# PRIORIDAD 1: Dash si el jugador estÃƒÂ¡ lejos (mÃƒÂ¡s agresivo)
	if "elite_dash" in special_abilities and elite_dash_cooldown <= 0:
		if dist > 100 and dist < 400:  # Entre 100 y 400 unidades
			_perform_elite_dash()
			return true

	# PRIORIDAD 2: Nova si hay jugador cerca (defensivo/ofensivo)
	if "elite_nova" in special_abilities and elite_nova_cooldown <= 0:
		if dist < 180:
			_perform_elite_nova()
			return true

	# PRIORIDAD 3: Slam si estÃƒÂ¡ muy cerca
	if "elite_slam" in special_abilities and elite_slam_cooldown <= 0:
		if dist < 150:
			_perform_elite_slam()
			return true

	# PRIORIDAD 4: Summon si el jugador estÃƒÂ¡ a distancia media
	if "elite_summon" in special_abilities and elite_summon_cooldown <= 0:
		if dist > 80 and dist < 300:
			_perform_elite_summon()
			return true

	# PRIORIDAD 5: Activar escudo si estÃƒÂ¡ bajo de vida
	if "elite_shield" in special_abilities and elite_shield_cooldown <= 0 and elite_shield_charges <= 0:
		var current_hp_percent = _get_enemy_hp_percent()
		if current_hp_percent < 0.7:
			_activate_elite_shield()
			return true

	return false

func _get_enemy_hp_percent() -> float:
	"""Obtener porcentaje de HP del enemigo"""
	if enemy.has_node("HealthComponent"):
		var hc = enemy.get_node("HealthComponent")
		return hc.current_health / max(1.0, hc.max_health)
	elif "hp" in enemy and "max_hp" in enemy:
		return float(enemy.hp) / max(1.0, float(enemy.max_hp))
	return 1.0

func _perform_elite_slam() -> void:
	"""Habilidad ÃƒÂ©lite: Slam de ÃƒÂ¡rea"""
	var slam_radius = modifiers.get("elite_slam_radius", 80.0)
	var slam_damage_mult = modifiers.get("elite_slam_damage_mult", 1.5)
	var slam_damage = int(attack_damage * slam_damage_mult)

	# FIX P0 #8: Visual PRIMERO como telegraph, luego daño con delay
	_spawn_elite_slam_visual(enemy.global_position, slam_radius)

	# Delay para dar tiempo de reacción al jugador
	var slam_pos = enemy.global_position
	get_tree().create_timer(0.4).timeout.connect(func():
		if not is_instance_valid(player) or not is_instance_valid(enemy):
			return
		var dist = slam_pos.distance_to(player.global_position)
		if dist <= slam_radius:
			if player.has_method("take_damage"):
				player.take_damage(slam_damage, "physical", enemy)
				attacked_player.emit(slam_damage, false)
			if player.has_method("apply_stun"):
				player.apply_stun(0.4)
	)

	# Aplicar cooldown
	elite_slam_cooldown = modifiers.get("elite_slam_cooldown", 5.0)
	# print("[Elite] Ã°Å¸â€˜â€˜Ã°Å¸â€™Â¥ %s usÃƒÂ³ Elite Slam! (daÃƒÂ±o: %d, radio: %.0f)" % [enemy.name, slam_damage, slam_radius])

func _activate_elite_rage() -> void:
	"""Activar modo rage de ÃƒÂ©lite"""
	elite_rage_active = true

	# FIX P2 #17: Guardar stats originales para poder revertir
	if not enemy.has_meta("pre_rage_damage"):
		enemy.set_meta("pre_rage_damage", attack_damage)
		if "base_speed" in enemy:
			enemy.set_meta("pre_rage_speed", enemy.base_speed)

	var damage_bonus = modifiers.get("elite_rage_damage_bonus", 0.5)
	var speed_bonus = modifiers.get("elite_rage_speed_bonus", 0.3)

	# Aplicar buffs
	attack_damage = int(attack_damage * (1 + damage_bonus))
	if "base_speed" in enemy:
		enemy.base_speed *= (1 + speed_bonus)

	# Visual ÃƒÂ©pico
	_spawn_elite_rage_visual()
	# print("[Elite] Ã°Å¸â€˜â€˜Ã°Å¸â€Â¥ %s entrÃƒÂ³ en RAGE! (+%.0f%% daÃƒÂ±o, +%.0f%% velocidad)" % [enemy.name, damage_bonus * 100, speed_bonus * 100])

func _activate_elite_shield() -> void:
	"""Activar escudo ÃƒÂ©lite"""
	elite_shield_charges = modifiers.get("elite_shield_charges", 3)
	elite_shield_cooldown = modifiers.get("elite_shield_cooldown", 15.0)

	# Visual de escudo
	_spawn_elite_shield_visual()
	# print("[Elite] Ã°Å¸â€˜â€˜Ã°Å¸â€ºÂ¡Ã¯Â¸Â %s activÃƒÂ³ Elite Shield! (%d cargas)" % [enemy.name, elite_shield_charges])

func _spawn_elite_slam_visual(center: Vector2, radius: float) -> void:
	"""Visual Ã‰PICO de slam Ã©lite - Usa VFXManager si disponible"""
	# Intentar VFXManager primero
	if _try_spawn_via_vfxmanager("elite_slam", "aoe", center, radius, 0.5):
		return

	# Fallback: Visual procedural
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 5
	effect.global_position = center

	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)

	var anim = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)

	# Colores mÃ¡s intensos
	var gold = Color(1.0, 0.8, 0.0)
	var red = Color(1.0, 0.2, 0.1)
	var bright = Color(1.0, 0.95, 0.6)

	visual.draw.connect(func():
		var expand = radius * 1.35 * anim

		# Ondas de choque mÃºltiples
		for i in range(4):
			var r = expand * (0.4 + i * 0.2)
			var a = (1.0 - anim) * (1.0 - i * 0.2)
			visual.draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(gold.r, gold.g, gold.b, a), 6.0 - i)
			visual.draw_arc(Vector2.ZERO, r * 0.9, 0, TAU, 32, Color(red.r, red.g, red.b, a * 0.5), 3.0)

		# Relleno explosivo
		var fill_a = (1.0 - anim * 1.2)
		if fill_a > 0:
			visual.draw_circle(Vector2.ZERO, expand * 0.9, Color(gold.r, gold.g, gold.b, fill_a * 0.3))
			visual.draw_circle(Vector2.ZERO, expand * 0.6, Color(red.r, 0.5, 0.0, fill_a * 0.5))

		# Grietas en el suelo (simuladas)
		for i in range(8):
			var angle = (TAU / 8) * i
			var crack_len = expand * 0.8
			var crack_end = Vector2(cos(angle), sin(angle)) * crack_len
			visual.draw_line(Vector2.ZERO, crack_end, Color(0.8, 0.4, 0.0, (1.0-anim)), 3.0)

		# Corona de estrellas/puntas
		var star_count = 12
		for i in range(star_count):
			var star_angle = (TAU / star_count) * i + anim * PI * 2
			var star_dist = expand * 0.9
			var star_pos = Vector2(cos(star_angle), sin(star_angle)) * star_dist

			# Destello en punta
			visual.draw_circle(star_pos, 5 * (1.0 - anim), bright)
	)

	# IMPORTANTE: Usar effect.create_tween() para que el tween se limpie con el nodo
	var tween = effect.create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.5) # MÃ¡s rÃ¡pido: 0.5s
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_elite_rage_visual() -> void:
	"""Visual Ã‰PICO de rage Ã©lite - Usa VFXManager si disponible"""
	if not is_instance_valid(enemy):
		return

	# Intentar VFXManager primero (aura que sigue al enemigo)
	if _try_spawn_via_vfxmanager("elite_rage", "aura", enemy.global_position, 75.0, 1.0):
		return

	# Fallback: Visual procedural
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 5
	effect.global_position = enemy.global_position

	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)

	var anim = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)

	visual.draw.connect(func():
		# Aura de furia ROJA INTENSA
		for i in range(5):
			var r = 75 + i * 20 + sin(anim * PI * 6 + i) * 15
			var a = (0.8 - i * 0.15) * (1.0 - anim * 0.3)
			var aura_color = Color(1.0, 0.1, 0.1, a) # Rojo puro
			visual.draw_arc(Vector2.ZERO, r, 0, TAU, 48, aura_color, 5.0)
			visual.draw_arc(Vector2.ZERO, r * 0.95, 0, TAU, 48, Color(1.0, 0.5, 0.0, a*0.5), 2.0)

		# SÃ­mbolo de calavera/rage simplificado
		var rage_scale = 1.2 + sin(anim * PI * 10) * 0.2
		var s = 20 * rage_scale * (1.0 - anim * 0.5)

		# Ojos
		visual.draw_circle(Vector2(-10, -5) * rage_scale, 6 * (1.0-anim), Color(1, 1, 0))
		visual.draw_circle(Vector2(10, -5) * rage_scale, 6 * (1.0-anim), Color(1, 1, 0))

		# Boca gritando
		var mouth_pts = PackedVector2Array([
			Vector2(-8, 5) * rage_scale,
			Vector2(8, 5) * rage_scale,
			Vector2(0, 15) * rage_scale
		])
		visual.draw_colored_polygon(mouth_pts, Color(0.2, 0, 0, 1.0-anim))

		# Rayos de ira
		var ray_count = 12
		for i in range(ray_count):
			var angle = (TAU/ray_count)*i + anim*5
			var start = Vector2(cos(angle), sin(angle)) * 30
			var end = Vector2(cos(angle), sin(angle)) * (60 + randf()*20)
			visual.draw_line(start, end, Color(1, 0.2, 0, 1.0-anim), 2.0)
	)

	# IMPORTANTE: Usar effect.create_tween() para que el tween se limpie con el nodo
	var tween = effect.create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 1.0)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_elite_shield_visual() -> void:
	"""Visual de escudo Ã©lite - Usa VFXManager si disponible"""
	if not is_instance_valid(enemy):
		return

	# Intentar VFXManager primero (aura que sigue al enemigo)
	if _try_spawn_via_vfxmanager("elite_shield", "aura", enemy.global_position, 50.0, 12.0):
		return

	# Fallback: El efecto se adjunta al enemigo
	var visual = Node2D.new()
	visual.name = "EliteShieldVisual"
	enemy.add_child(visual)

	var anim = 0.0
	var gold = Color(1.0, 0.85, 0.1)

	visual.draw.connect(func():
		# HexÃƒÂ¡gono de escudo dorado
		var radius = 50
		var pulse = 1.0 + sin(anim * 8) * 0.1
		var points = PackedVector2Array()
		for i in range(7):
			var angle = (TAU / 6) * i + anim * 0.8
			points.append(Vector2(cos(angle), sin(angle)) * radius * pulse)
		visual.draw_polyline(points, Color(gold.r, gold.g, gold.b, 0.9), 4.0)

		# Relleno semi-transparente
		visual.draw_circle(Vector2.ZERO, radius * 0.85 * pulse, Color(gold.r, gold.g, gold.b, 0.15))

		# Runas en cada vÃƒÂ©rtice
		for i in range(6):
			var angle = (TAU / 6) * i + anim * 0.8
			var pos = Vector2(cos(angle), sin(angle)) * radius * pulse
			visual.draw_circle(pos, 8, Color(1, 0.95, 0.5, 0.95))
			visual.draw_circle(pos, 5, gold)

		# Corona interior
		visual.draw_arc(Vector2.ZERO, radius * 0.5 * pulse, 0, TAU, 24, Color(1, 1, 0.8, 0.5), 2.0)
	)

	var timer = Timer.new()
	timer.wait_time = 0.033
	timer.autostart = true
	visual.add_child(timer)

	timer.timeout.connect(func():
		anim += 0.033
		if is_instance_valid(visual):
			visual.queue_redraw()
	)

	# Auto-destruir despuÃƒÂ©s de 12 segundos (duraciÃƒÂ³n del escudo)
	# FIX P2 #18: Usar timer como hijo del visual para que muera con el enemigo
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 12.0
	cleanup_timer.one_shot = true
	cleanup_timer.autostart = true
	visual.add_child(cleanup_timer)
	cleanup_timer.timeout.connect(func():
		if is_instance_valid(visual):
			visual.queue_free()
	)

# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
# NUEVAS HABILIDADES Ãƒâ€°LITE - DASH, NOVA, SUMMON
# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

func _perform_elite_dash() -> void:
	"""Habilidad ÃƒÂ©lite: Dash/embestida hacia el jugador"""
	if not is_instance_valid(enemy) or not is_instance_valid(player):
		return

	var _dash_speed = modifiers.get("elite_dash_speed", 600.0)
	var dash_damage_mult = modifiers.get("elite_dash_damage_mult", 1.8)
	var dash_damage = int(attack_damage * dash_damage_mult)

	elite_is_dashing = true
	elite_dash_target = player.global_position

	# Visual de preparaciÃƒÂ³n
	_spawn_elite_dash_visual_start()

	# DespuÃƒÂ©s de 0.3s de "wind-up", ejecutar dash
	get_tree().create_timer(0.3).timeout.connect(func():
		if not is_instance_valid(enemy) or not is_instance_valid(player):
			elite_is_dashing = false
			return

		# Calcular direcciÃƒÂ³n y posiciÃƒÂ³n final
		var direction = (elite_dash_target - enemy.global_position).normalized()
		var dash_distance = min(400.0, enemy.global_position.distance_to(elite_dash_target) + 50)
		var final_pos = enemy.global_position + direction * dash_distance

		# Crear tween para el movimiento
		var tween = enemy.create_tween()
		tween.tween_property(enemy, "global_position", final_pos, 0.25).set_ease(Tween.EASE_IN_OUT)

		# Spawn visual de estela
		_spawn_elite_dash_trail(enemy.global_position, final_pos)

		# Verificar colisiÃƒÂ³n con el jugador durante el dash
		tween.finished.connect(func():
			elite_is_dashing = false
			if is_instance_valid(player):
				var dist = enemy.global_position.distance_to(player.global_position)
				if dist < 60:  # ImpactÃƒÂ³
					if player.has_method("take_damage"):
						var elem = _get_enemy_element()
						player.call("take_damage", dash_damage, elem, enemy)
						attacked_player.emit(dash_damage, true)
						# print("[Elite] Ã°Å¸â€˜â€˜Ã°Å¸â€™Â¨ %s DASH IMPACTO! %d daÃƒÂ±o" % [enemy.name, dash_damage])
					if player.has_method("apply_knockback"):
						player.apply_knockback(direction * 200)
		)
	)

	elite_dash_cooldown = modifiers.get("elite_dash_cooldown", 3.0)
	# print("[Elite] Ã°Å¸â€˜â€˜Ã°Å¸â€™Â¨ %s prepara DASH hacia el jugador!" % enemy.name)

func _spawn_elite_dash_visual_start() -> void:
	"""Visual de preparaciÃƒÂ³n de dash"""
	if not is_instance_valid(enemy):
		return

	# VFXManager hook - elite dash trail AOE
	if _try_spawn_via_vfxmanager("elite_dash_trail", "aoe", enemy.global_position, 40.0, 0.3):
		return

	# Fallback procedural
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 5
	effect.global_position = enemy.global_position

	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)

	var anim = 0.0
	var gold = Color(1.0, 0.85, 0.1)
	var visual = Node2D.new()
	effect.add_child(visual)

	visual.draw.connect(func():
		# CÃƒÂ­rculo de carga creciente
		var radius = 40 * anim
		for i in range(3):
			var r = radius * (1.0 - i * 0.2)
			visual.draw_arc(Vector2.ZERO, r, 0, TAU * anim, 32, Color(gold.r, gold.g, gold.b, 0.8 - i * 0.2), 3.0)

		# Flecha direccional
		if is_instance_valid(player) and is_instance_valid(enemy):
			var dir = (player.global_position - enemy.global_position).normalized()
			var arrow_len = 50 * anim
			var arrow_end = dir * arrow_len
			visual.draw_line(Vector2.ZERO, arrow_end, Color(1, 0.9, 0.3, 0.9), 4.0)
			# Punta de flecha
			var perp = Vector2(-dir.y, dir.x) * 12
			visual.draw_line(arrow_end, arrow_end - dir * 20 + perp, gold, 3.0)
			visual.draw_line(arrow_end, arrow_end - dir * 20 - perp, gold, 3.0)
	)

	var tween = effect.create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.3)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_elite_dash_trail(from: Vector2, to: Vector2) -> void:
	"""Estela visual del dash"""
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 8
	effect.global_position = from

	var parent = enemy.get_parent() if is_instance_valid(enemy) else null
	if parent:
		parent.add_child(effect)
	else:
		return

	var gold = Color(1.0, 0.85, 0.1)
	var direction = (to - from).normalized()
	var length = from.distance_to(to)
	var anim = 0.0

	var visual = Node2D.new()
	effect.add_child(visual)

	visual.draw.connect(func():
		# Estela dorada
		var perp = Vector2(-direction.y, direction.x)
		var width = 30 * (1.0 - anim)
		var current_len = length * min(1.0, anim * 2)

		var p1 = perp * width
		var p2 = -perp * width
		var p3 = direction * current_len - perp * width * 0.5
		var p4 = direction * current_len + perp * width * 0.5

		visual.draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), Color(gold.r, gold.g, gold.b, 0.6 * (1.0 - anim)))

		# PartÃƒÂ­culas de chispa
		for i in range(8):
			var spark_pos = direction * (length * randf()) + perp * (randf() - 0.5) * width * 2
			visual.draw_circle(spark_pos, 4 * (1.0 - anim), Color(1, 1, 0.8, 0.8 * (1.0 - anim)))
	)

	var tween = effect.create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.4)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _perform_elite_nova() -> void:
	"""Habilidad ÃƒÂ©lite: ExplosiÃƒÂ³n de proyectiles en cÃƒÂ­rculo"""
	if not is_instance_valid(enemy):
		return

	var projectile_count = modifiers.get("elite_nova_projectile_count", 12)
	var nova_damage_mult = modifiers.get("elite_nova_damage_mult", 0.8)
	var nova_damage = int(attack_damage * nova_damage_mult)

	# Visual de carga
	_spawn_elite_nova_visual(enemy.global_position)

	# DespuÃƒÂ©s de 0.4s, disparar todos los proyectiles
	get_tree().create_timer(0.4).timeout.connect(func():
		if not is_instance_valid(enemy):
			return

		for i in range(projectile_count):
			var angle = (TAU / projectile_count) * i
			var direction = Vector2(cos(angle), sin(angle))
			_spawn_elite_nova_projectile(enemy.global_position, direction, nova_damage)

		# print("[Elite] Ã°Å¸â€˜â€˜Ã°Å¸â€™Â« %s dispara NOVA! %d proyectiles" % [enemy.name, projectile_count])
	)

	elite_nova_cooldown = modifiers.get("elite_nova_cooldown", 6.0)

func _spawn_elite_nova_visual(center: Vector2) -> void:
	"""Visual de carga de nova"""
	# VFXManager hook - arcane nova AOE
	if _try_spawn_via_vfxmanager("arcane_nova", "aoe", center, 80.0, 0.4):
		return

	# Fallback procedural
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 5
	effect.global_position = center

	var parent = enemy.get_parent() if is_instance_valid(enemy) else null
	if parent:
		parent.add_child(effect)
	else:
		return

	var anim = 0.0
	var gold = Color(1.0, 0.85, 0.1)
	var visual = Node2D.new()
	effect.add_child(visual)

	visual.draw.connect(func():
		# Anillos que se contraen
		for i in range(4):
			var r = 80 * (1.0 - anim) + i * 20
			visual.draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(gold.r, gold.g, gold.b, 0.7 * anim), 3.0)

		# Centro brillante
		visual.draw_circle(Vector2.ZERO, 20 * anim, Color(1, 0.95, 0.5, 0.9))
		visual.draw_circle(Vector2.ZERO, 12 * anim, gold)
	)

	var tween = effect.create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.4)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_elite_nova_projectile(from: Vector2, direction: Vector2, damage: int) -> void:
	"""Crear un proyectil de la nova ÃƒÂ©lite"""
	# Intentar usar el sistema de proyectiles existente
	if EnemyProjectileScript:
		var projectile = Area2D.new()
		projectile.set_script(EnemyProjectileScript)
		projectile.global_position = from

		var parent = enemy.get_parent() if is_instance_valid(enemy) else null
		if parent:
			parent.add_child(projectile)

			if projectile.has_method("initialize"):
				var elem = _get_enemy_element()
				projectile.initialize(direction, 280.0, damage, 3.0, elem)

			# Visual dorado especial - FIX: usar "Sprite" (nombre real en EnemyProjectile)
			var sprite = projectile.get_node_or_null("Sprite")
			if sprite:
				sprite.modulate = Color(1.0, 0.85, 0.1)

func _perform_elite_summon() -> void:
	"""Habilidad ÃƒÂ©lite: Invocar minions temporales"""
	if not is_instance_valid(enemy):
		return

	var summon_count = modifiers.get("elite_summon_count", 3)

	# Visual de invocaciÃƒÂ³n
	_spawn_elite_summon_visual(enemy.global_position)

	# DespuÃƒÂ©s de 0.5s, spawner los minions
	get_tree().create_timer(0.5).timeout.connect(func():
		if not is_instance_valid(enemy):
			return

		# Buscar el EnemyManager
		var enemy_manager = _find_enemy_manager()
		if not enemy_manager:
			# print("[Elite] Ã¢Å¡Â Ã¯Â¸Â No se encontrÃƒÂ³ EnemyManager para summon")
			return

		for i in range(summon_count):
			var angle = (TAU / summon_count) * i
			var offset = Vector2(cos(angle), sin(angle)) * 60
			var spawn_pos = enemy.global_position + offset

			# Spawner un minion tier 1 temporal
			if enemy_manager.has_method("spawn_specific_enemy"):
				var minion = enemy_manager.spawn_specific_enemy("tier_1_slime_arcano", spawn_pos)
				if minion:
					# Hacer el minion temporal (se destruye despuÃƒÂ©s de 8 segundos)
					minion.modulate = Color(1.0, 0.85, 0.1, 0.8)  # Tinte dorado
					get_tree().create_timer(8.0).timeout.connect(func():
						if is_instance_valid(minion):
							minion.queue_free()
					)

		# print("[Elite] Ã°Å¸â€˜â€˜Ã°Å¸â€˜Â¥ %s invocÃƒÂ³ %d minions!" % [enemy.name, summon_count])
	)

	elite_summon_cooldown = modifiers.get("elite_summon_cooldown", 10.0)

func _spawn_elite_summon_visual(center: Vector2) -> void:
	"""Visual de invocaciÃƒÂ³n ÃƒÂ©lite"""
	# VFXManager hook - summon circle boss VFX
	if _try_spawn_via_vfxmanager("summon_circle", "boss", center, 70.0, 0.5):
		return

	# Fallback procedural
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 5
	effect.global_position = center

	var parent = enemy.get_parent() if is_instance_valid(enemy) else null
	if parent:
		parent.add_child(effect)
	else:
		return

	var anim = 0.0
	var gold = Color(1.0, 0.85, 0.1)
	var purple = Color(0.7, 0.3, 1.0)
	var visual = Node2D.new()
	effect.add_child(visual)

	visual.draw.connect(func():
		# CÃƒÂ­rculo mÃƒÂ¡gico
		var radius = 70
		visual.draw_arc(Vector2.ZERO, radius, 0, TAU * anim, 48, gold, 3.0)
		visual.draw_arc(Vector2.ZERO, radius * 0.7, 0, TAU * anim, 36, purple, 2.0)

		# Runas girando
		var rune_count = 6
		for i in range(rune_count):
			var angle = (TAU / rune_count) * i + anim * PI * 2
			var pos = Vector2(cos(angle), sin(angle)) * radius * 0.85
			visual.draw_circle(pos, 8, Color(gold.r, gold.g, gold.b, anim))

		# PentÃƒÂ¡culo central
		var penta_radius = 35 * anim
		for i in range(5):
			var a1 = (TAU / 5) * i - PI/2
			var a2 = (TAU / 5) * ((i + 2) % 5) - PI/2
			var p1 = Vector2(cos(a1), sin(a1)) * penta_radius
			var p2 = Vector2(cos(a2), sin(a2)) * penta_radius
			visual.draw_line(p1, p2, purple, 2.0)
	)

	var tween = effect.create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.5)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _find_enemy_manager() -> Node:
	"""Buscar el EnemyManager en el ÃƒÂ¡rbol"""
	# MÃƒÂ©todo 1: GameManager
	if GameManager and GameManager.has_method("get") and "enemy_manager" in GameManager:
		return GameManager.enemy_manager

	# MÃƒÂ©todo 2: Buscar en el ÃƒÂ¡rbol
	var tree = Engine.get_main_loop()
	if tree and tree.root:
		var em = tree.root.get_node_or_null("Game/EnemyManager")
		if em:
			return em

	# MÃƒÂ©todo 3: Buscar por clase
	var nodes = get_tree().get_nodes_in_group("enemy_managers")
	if nodes.size() > 0:
		return nodes[0]

	return null

func _perform_melee_attack() -> void:
	"""Ataque melee: daño directo al jugador"""
	if not is_instance_valid(player) or not player.has_method("take_damage"):
		return

	var elem = _get_enemy_element()
	# Pasar referencia del enemigo para sistema de thorns
	player.call("take_damage", attack_damage, elem, enemy)
	# print("[EnemyAttackSystem] Ã¢Å¡â€Ã¯Â¸Â %s atacÃƒÂ³ melee a player por %d daÃƒÂ±o (%s)" % [enemy.name, attack_damage, elem])

	# Aplicar efectos segÃƒÂºn arquetipo y elemento
	_apply_melee_effects()

	# Emitir seÃƒÂ±al
	attacked_player.emit(attack_damage, true)

func _apply_melee_effects() -> void:
	"""Aplicar efectos de estado segÃƒÂºn arquetipo y elemento"""
	var elem = _get_enemy_element()

	# Efectos por arquetipo
	match archetype:
		"debuffer":  # AraÃƒÂ±a Venenosa
			if player.has_method("apply_poison"):
				var poison_dmg = modifiers.get("poison_damage", 2.0)
				var poison_dur = modifiers.get("poison_duration", 3.0)
				player.apply_poison(poison_dmg, poison_dur)
			if player.has_method("apply_slow"):
				var slow_amt = modifiers.get("slow_amount", 0.2)
				var slow_dur = modifiers.get("slow_duration", 2.0)
				player.apply_slow(slow_amt, slow_dur)
		"pack":  # Lobo de Cristal - causa bleed (implementado como burn menor)
			if player.has_method("apply_burn"):
				player.apply_burn(2.0, 2.0)  # Bleed como burn menor
		"phase":  # Sombra Flotante - aplica curse
			if player.has_method("apply_curse"):
				player.apply_curse(0.3, 4.0)  # -30% curaciÃƒÂ³n por 4s
		"charger":  # Caballero del VacÃƒÂ­o - stun en carga
			# El stun se aplica en el ataque de carga, no en melee normal
			pass

	# Efectos por elemento
	match elem:
		"fire":
			if player.has_method("apply_burn"):
				player.apply_burn(3.0, 2.0)  # 3 daÃƒÂ±o/tick por 2s
		"ice":
			if player.has_method("apply_slow"):
				player.apply_slow(0.25, 2.0)  # 25% slow por 2s
		"dark", "void":
			if player.has_method("apply_weakness"):
				player.apply_weakness(0.2, 3.0)  # +20% daÃƒÂ±o recibido por 3s
		"poison":
			if player.has_method("apply_poison"):
				player.apply_poison(2.0, 4.0)

func _perform_ranged_attack() -> void:
	"""Ataque ranged: disparar proyectil al jugador"""
	# Crear proyectil dinÃƒÂ¡micamente si no hay escena
	if not projectile_scene and EnemyProjectileScript:
		_create_dynamic_projectile()
		return

	if not projectile_scene:
		# print("[EnemyAttackSystem] Warning: %s no tiene projectile_scene ni script" % enemy.name)
		# Fallback a melee
		_perform_melee_attack()
		return

	var projectile = projectile_scene.instantiate()
	if not projectile:
		return

	# Posicionar en enemigo
	projectile.global_position = enemy.global_position

	# Calcular dirección hacia jugador
	var direction = (player.global_position - enemy.global_position).normalized()

	# PRIMERO añadir al árbol (necesario para que initialize() funcione correctamente)
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(projectile)
	else:
		get_tree().root.add_child(projectile)

	# DESPUÉS configurar proyectil (initialize crea visual que necesita estar en el árbol)
	if projectile.has_method("initialize"):
		projectile.initialize(direction, projectile_speed, attack_damage, 5.0, element_type)
	else:
		pass  # Bloque else
		if "direction" in projectile:
			projectile.direction = direction
		if "speed" in projectile:
			projectile.speed = projectile_speed
		if "damage" in projectile:
			projectile.damage = attack_damage

	attacked_player.emit(attack_damage, false)

func _create_dynamic_projectile() -> void:
	"""Crear proyectil dinÃƒÂ¡mico usando EnemyProjectile.gd"""
	var projectile = Area2D.new()
	projectile.set_script(EnemyProjectileScript)
	projectile.global_position = enemy.global_position

	var direction = (player.global_position - enemy.global_position).normalized()

	# Determinar elemento segÃƒÂºn enemigo
	var elem = _get_enemy_element()

	# AÃƒÂ±adir al ÃƒÂ¡rbol ANTES de initialize (necesario para _ready)
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(projectile)
	else:
		get_tree().root.add_child(projectile)

	# Inicializar
	if projectile.has_method("initialize"):
		projectile.initialize(direction, projectile_speed, attack_damage, 5.0, elem)

	# print("[EnemyAttackSystem] Ã°Å¸Å½Â¯ %s disparÃƒÂ³ proyectil dinÃƒÂ¡mico (%s)" % [enemy.name, elem])
	attacked_player.emit(attack_damage, false)

func _perform_aoe_attack() -> void:
	"""Ataque de área: daño en zona alrededor del enemigo"""
	if not player:
		return

	# FIX P0 #4: Centro del AoE debe ser el ENEMIGO, no el player
	var aoe_center = enemy.global_position
	var radius = modifiers.get("aoe_radius", 100.0)
	var aoe_damage = int(attack_damage * modifiers.get("aoe_damage_mult", 1.0))
	var elem = _get_enemy_element()

	# Efecto visual del AoE PRIMERO (telegraph)
	_spawn_aoe_visual(aoe_center, radius)

	# Verificar si player está en rango del AoE
	var dist_to_player = aoe_center.distance_to(player.global_position)
	if dist_to_player <= radius:
		if player.has_method("take_damage"):
			player.call("take_damage", aoe_damage, elem, enemy)
			attacked_player.emit(aoe_damage, false)
			# Aplicar efectos según elemento del AoE
			_apply_aoe_effects()

func _apply_aoe_effects() -> void:
	"""Aplicar efectos de estado en ataques AoE"""
	var elem = _get_enemy_element()

	# SeÃƒÂ±or de las Llamas - Burn
	if elem == "fire":
		if player.has_method("apply_burn"):
			player.apply_burn(5.0, 3.0)  # 5 daÃƒÂ±o/tick por 3s
			# print("[EnemyAttackSystem] Ã°Å¸â€Â¥ AoE aplica Burn!")
	# Reina del Hielo - Slow/Freeze
	elif elem == "ice":
		if player.has_method("apply_slow"):
			player.apply_slow(0.4, 3.0)  # 40% slow por 3s
			# print("[EnemyAttackSystem] Ã¢Ââ€žÃ¯Â¸Â AoE aplica Slow!")
	# TitÃƒÂ¡n Arcano - Stun
	elif "arcane" in enemy.name.to_lower() or "titan" in enemy.name.to_lower():
		if player.has_method("apply_stun"):
			player.apply_stun(0.5)  # 0.5s stun
			# print("[EnemyAttackSystem] Ã¢Å¡Â¡ AoE aplica Stun!")

func _perform_breath_attack() -> void:
	"""Ataque de aliento: daÃƒÂ±o en cono hacia el player"""
	if not player:
		return

	var direction = (player.global_position - enemy.global_position).normalized()
	var cone_angle = deg_to_rad(modifiers.get("breath_angle", 45.0))
	var cone_range = modifiers.get("breath_range", 150.0)
	var breath_damage = int(attack_damage * modifiers.get("breath_damage_mult", 1.2))

	# Verificar si player estÃƒÂ¡ en el cono
	var to_player = player.global_position - enemy.global_position
	var dist = to_player.length()
	var angle_to_player = direction.angle_to(to_player.normalized())

	if dist <= cone_range and abs(angle_to_player) <= cone_angle / 2:
		if player.has_method("take_damage"):
			player.take_damage(breath_damage, "fire", enemy)
			# print("[EnemyAttackSystem] Ã°Å¸Ââ€° %s Breath hit player por %d daÃƒÂ±o" % [enemy.name, breath_damage])
			attacked_player.emit(breath_damage, false)
			# Aplicar efectos de breath
			_apply_breath_effects()

	# Efecto visual del breath
	_spawn_breath_visual(enemy.global_position, direction, cone_range)

func _apply_breath_effects() -> void:
	"""Aplicar efectos del ataque breath"""
	var _elem = _get_enemy_element()

	# DragÃƒÂ³n EtÃƒÂ©reo es de tipo 'fire' o 'etereo'
	# Aplicar burn siempre en breath de dragÃƒÂ³n
	if player.has_method("apply_burn"):
		player.apply_burn(6.0, 2.5)  # 6 daÃƒÂ±o/tick por 2.5s
		# print("[EnemyAttackSystem] Ã°Å¸â€Â¥ Breath aplica Burn!")

func _perform_multi_attack() -> void:
	"""Ataque mÃƒÂºltiple: varios proyectiles o ataques en secuencia"""
	var count = modifiers.get("attack_count", 3)
	var spread_angle = deg_to_rad(modifiers.get("spread_angle", 30.0))
	var base_direction = (player.global_position - enemy.global_position).normalized()

	for i in range(count):
		# Calcular ÃƒÂ¡ngulo para este proyectil
		var angle_offset = spread_angle * (float(i) / float(count - 1) - 0.5) if count > 1 else 0.0
		var direction = base_direction.rotated(angle_offset)

		# Crear proyectil con delay visual
		_spawn_multi_projectile(direction, i * 0.1)

	# print("[EnemyAttackSystem] Ã°Å¸â€Â¥ %s Multi-attack: %d proyectiles" % [enemy.name, count])
	attacked_player.emit(attack_damage, false)

# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
# SISTEMA DE BOSS COMPLETO - ESTILO BINDING OF ISAAC
# Ataques constantes, AOE aleatorios, proyectiles perseguidores, orbitales
# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

# Tracking de cooldowns de habilidades de boss (por enemigo)
var boss_ability_cooldowns: Dictionary = {}  # {ability_name: tiempo_restante}
var boss_current_phase: int = 1
var boss_enraged: bool = false
var boss_fire_trail_active: bool = false
var boss_damage_aura_timer: float = 0.0
var _boss_aura_damage_accumulator: float = 0.0  # FIX P1 #15: acumulador fraccionario

# Sistema de habilidades limitadas por minuto
var boss_scaling_config: Dictionary = {}     # ConfiguraciÃƒÂ³n de escalado del minuto
var boss_unlocked_abilities: Array = []      # Habilidades desbloqueadas para este boss
var boss_combo_count: int = 0                # Habilidades usadas en el combo actual
var boss_combo_timer: float = 0.0            # Timer para resetear combo
var boss_global_cooldown: float = 0.0        # Cooldown global entre habilidades

# Nuevas variables para boss agresivo
var boss_homing_projectile_timer: float = 0.0
var boss_random_aoe_timer: float = 0.0
var boss_spread_shot_timer: float = 0.0
var boss_orbitals: Array = []
var boss_active_effects: Array = []  # Track de TODOS los efectos del boss (AOE, trails, etc.)

func cleanup_boss() -> void:
	"""Limpiar todos los nodos del boss (orbitales, trails, AOE warnings, etc.)"""
	# print("[Boss] Ã°Å¸Â§Â¹ Limpiando orbitales y efectos del boss...")

	# Limpiar orbitales
	for orbital in boss_orbitals:
		if is_instance_valid(orbital):
			orbital.queue_free()
	boss_orbitals.clear()

	# Limpiar todos los efectos activos (AOE warnings, explosiones, trails, etc.)
	for effect in boss_active_effects:
		if is_instance_valid(effect):
			effect.queue_free()
	boss_active_effects.clear()

	# Limpiar tambiÃƒÂ©n cualquier homing orb del boss en la escena
	var tree = get_tree()
	if tree:
		for node in tree.get_nodes_in_group("boss_effects"):
			if is_instance_valid(node):
				node.queue_free()

	is_boss_enemy = false
	# print("[Boss] Ã°Å¸Â§Â¹ Limpieza completada")

func _track_boss_effect(effect: Node) -> void:
	"""AÃƒÂ±adir un efecto a la lista de tracking para limpieza posterior"""
	if effect and is_instance_valid(effect):
		boss_active_effects.append(effect)
		effect.add_to_group("boss_effects")

func _init_boss_aggressive_mode() -> void:
	"""Inicializar modo agresivo del boss - estilo Binding of Isaac"""
	_init_boss_system()

	# Spawn orbitales iniciales
	var orbital_count = boss_scaling_config.get("orbital_count", 2)
	_spawn_boss_orbitals(orbital_count)

	# print("[Boss] Ã°Å¸â€˜Â¹Ã°Å¸â€Â¥ MODO AGRESIVO ACTIVADO - Orbitales: %d" % orbital_count)

func _process_boss_aggressive_attacks(delta: float) -> void:
	"""Procesar ataques constantes del boss - NO depende del rango"""
	if not enemy or not player or not is_instance_valid(enemy) or not is_instance_valid(player):
		return

	# Inicializar si es necesario
	if boss_scaling_config.is_empty():
		_init_boss_system()

	# Actualizar fase segÃƒÂºn HP
	_update_boss_phase()

	# Actualizar orbitales
	_update_boss_orbitals(delta)

	# === SISTEMA DE ATAQUES CONSTANTES ===

	# 1. Proyectiles hacia el jugador (ataque principal - siempre activo)
	boss_attack_timer -= delta
	if boss_attack_timer <= 0:
		_boss_fire_at_player()
		var interval = boss_scaling_config.get("attack_interval", 1.2)
		boss_attack_timer = interval * (0.8 if boss_current_phase >= 2 else 1.0)

	# 2. AOE aleatorios por el mapa (siempre activo)
	boss_aoe_timer -= delta
	if boss_aoe_timer <= 0:
		_boss_spawn_random_aoe()
		var aoe_interval = boss_scaling_config.get("aoe_spawn_interval", 5.0)
		boss_aoe_timer = aoe_interval * (0.7 if boss_current_phase >= 2 else 1.0)

	# 3. Proyectiles homing (solo si estÃƒÂ¡ habilitado en la config)
	var enable_homing = boss_scaling_config.get("enable_homing", false)
	if enable_homing:
		boss_homing_projectile_timer -= delta
		if boss_homing_projectile_timer <= 0:
			_boss_spawn_homing_projectile()
			var homing_interval = boss_scaling_config.get("homing_interval", 6.0)
			boss_homing_projectile_timer = homing_interval * (0.7 if boss_current_phase >= 2 else 1.0)

	# 4. Spread shot (solo si estÃƒÂ¡ habilitado en la config)
	var enable_spread = boss_scaling_config.get("enable_spread", false)
	if enable_spread:
		boss_spread_shot_timer -= delta
		if boss_spread_shot_timer <= 0:
			_boss_spread_shot()
			var spread_interval = boss_scaling_config.get("spread_interval", 8.0)
			boss_spread_shot_timer = spread_interval * (0.6 if boss_current_phase >= 3 else 1.0)

	# 5. Trail de daño solo en fase 2+ (para todos los bosses)
	if boss_current_phase >= 2:
		boss_trail_timer -= delta
		if boss_trail_timer <= 0:
			_boss_leave_damage_trail()
			boss_trail_timer = 0.4

	# FIX P0 #3: Actualizar efectos pasivos del boss (damage_aura, fire_trail)
	_update_boss_passive_effects()

	# 6. Habilidades especiales del boss (sistema original mejorado)
	_process_boss_special_abilities(delta)

func _boss_fire_at_player() -> void:
	"""Disparar proyectil directo al jugador"""
	if not is_instance_valid(player) or not is_instance_valid(enemy):
		return

	var direction = (player.global_position - enemy.global_position).normalized()
	var damage = int(attack_damage * 0.5)  # Proyectiles hacen 50% del daÃƒÂ±o base

	_spawn_boss_projectile(enemy.global_position, direction, damage, 220.0)  # Reducido de 350 a 220

func _boss_spawn_random_aoe() -> void:
	"""Spawn un AOE en posiciÃƒÂ³n aleatoria cerca del jugador"""
	if not is_instance_valid(player):
		return

	# PosiciÃƒÂ³n aleatoria dentro de un radio del jugador
	var offset = Vector2(randf_range(-200, 200), randf_range(-200, 200))
	var target_pos = player.global_position + offset

	# Warning visual antes del impacto - AUMENTADO para dar tiempo de reacciÃ³n
	_spawn_aoe_warning(target_pos, 80.0, 1.8)  # Aumentado de 1.0 a 1.8s

	# DespuÃƒÂ©s del warning, hacer daÃƒÂ±o
	get_tree().create_timer(1.8).timeout.connect(func():
		if is_instance_valid(player):
			var dist = target_pos.distance_to(player.global_position)
			if dist < 80:
				var damage = int(attack_damage * 0.7)
				if player.has_method("take_damage"):
					var elem = _get_enemy_element()
					player.call("take_damage", damage, elem, enemy)
					# print("[Boss] Ã°Å¸â€™Â¥ AOE RANDOM impactÃƒÂ³! %d daÃƒÂ±o" % damage)
		# Visual de explosiÃƒÂ³n
		_spawn_aoe_explosion(target_pos, 80.0)
	)

func _boss_spawn_homing_projectile() -> void:
	"""Spawn proyectil que persigue al jugador"""
	if not is_instance_valid(player) or not is_instance_valid(enemy):
		return

	var count = 1 + boss_current_phase  # MÃƒÂ¡s proyectiles en fases avanzadas

	for i in range(count):
		var angle_offset = (TAU / count) * i
		var spawn_offset = Vector2(cos(angle_offset), sin(angle_offset)) * 50
		var spawn_pos = enemy.global_position + spawn_offset

		_create_homing_projectile(spawn_pos)

	# print("[Boss] Ã°Å¸Å½Â¯ %d proyectiles HOMING lanzados!" % count)

func _create_homing_projectile(spawn_pos: Vector2) -> void:
	"""Crear un proyectil que persigue al jugador"""
	var projectile = Area2D.new()
	projectile.name = "BossHomingProjectile"
	projectile.collision_layer = 0
	projectile.collision_mask = 1  # Colisiona con player
	projectile.global_position = spawn_pos
	projectile.top_level = true

	# Collision shape
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 12
	shape.shape = circle
	projectile.add_child(shape)

	# Visual — intentar spritesheet via VFXManager, fallback procedural
	var _used_vfx := false
	var vfx_mgr = get_node_or_null("/root/VFXManager")
	if vfx_mgr and vfx_mgr.has_method("spawn_projectile_attached"):
		# Usar tipo de proyectil basado en elemento del enemigo
		var elem = _get_enemy_element()
		var proj_type = "void_homing"
		if "ELEMENT_TO_PROJECTILE" in vfx_mgr:
			proj_type = vfx_mgr.ELEMENT_TO_PROJECTILE.get(elem, "void_homing")
		var vfx_sprite = vfx_mgr.spawn_projectile_attached(proj_type, projectile)
		if not vfx_sprite:
			# Intentar con el tipo de elemento directo
			vfx_sprite = vfx_mgr.spawn_projectile_attached(elem, projectile)
		if vfx_sprite:
			_used_vfx = true

	if not _used_vfx:
		var visual = Node2D.new()
		projectile.add_child(visual)

		var elem = _get_enemy_element()
		var color = _get_element_color(elem)

		visual.draw.connect(func():
			visual.draw_circle(Vector2.ZERO, 15, Color(color.r, color.g, color.b, 0.3))
			visual.draw_circle(Vector2.ZERO, 10, color)
			visual.draw_circle(Vector2.ZERO, 5, Color(1, 1, 1, 0.9))
		)
		visual.queue_redraw()

	var parent = enemy.get_parent()
	if parent:
		parent.add_child(projectile)

	# Trackear para limpieza cuando muere el boss
	_track_boss_effect(projectile)

	# Comportamiento homing
	var lifetime = 6.0
	var speed = 120.0  # Reducido de 180 a 120 (jugador va a 100)
	var homing_strength = 1.8  # Reducido de 2.5 a 1.8 (mÃ¡s esquivable)
	var damage = int(attack_damage * 0.4)
	var hit = false

	# Timer de update
	var timer = Timer.new()
	timer.wait_time = 0.016
	timer.autostart = true
	projectile.add_child(timer)

	timer.timeout.connect(func():
		if hit or not is_instance_valid(projectile):
			return

		lifetime -= 0.016
		if lifetime <= 0:
			projectile.queue_free()
			return

		# Destruir si el boss/enemy ya no existe
		if not is_instance_valid(enemy):
			projectile.queue_free()
			return

		if not is_instance_valid(player):
			projectile.queue_free()
			return

		# Movimiento homing
		var target_dir = (player.global_position - projectile.global_position).normalized()
		var current_dir = Vector2.RIGHT.rotated(projectile.rotation)
		var new_dir = current_dir.lerp(target_dir, homing_strength * 0.016)

		projectile.rotation = new_dir.angle()
		projectile.global_position += new_dir * speed * 0.016

		# Check colisiÃƒÂ³n manual
		var dist = projectile.global_position.distance_to(player.global_position)
		if dist < 20:
			hit = true
			if player.has_method("take_damage"):
				var elem_type = _get_enemy_element()
				player.call("take_damage", damage, elem_type, enemy)
			projectile.queue_free()
	)

func _boss_spread_shot() -> void:
	"""RÃƒÂ¡faga de proyectiles en abanico"""
	if not is_instance_valid(player) or not is_instance_valid(enemy):
		return

	var count = 5 + boss_current_phase * 2  # MÃƒÂ¡s proyectiles en fases avanzadas
	var spread_angle = PI * 0.6  # 108 grados
	var base_direction = (player.global_position - enemy.global_position).normalized()
	var damage = int(attack_damage * 0.35)

	for i in range(count):
		var angle_offset = spread_angle * (float(i) / float(count - 1) - 0.5)
		var direction = base_direction.rotated(angle_offset)
		_spawn_boss_projectile(enemy.global_position, direction, damage, 280.0)

	# print("[Boss] Ã°Å¸â€Â¥ SPREAD SHOT: %d proyectiles!" % count)

func _boss_leave_damage_trail() -> void:
	"""Dejar trail de daÃƒÂ±o donde pasa el boss"""
	if not is_instance_valid(enemy):
		return

	var trail_pos = enemy.global_position
	var elem = _get_enemy_element()
	var color = _get_element_color(elem)

	# Crear zona de daÃƒÂ±o temporal
	var trail = Area2D.new()
	trail.name = "BossTrail"
	trail.collision_layer = 0
	trail.collision_mask = 1
	trail.global_position = trail_pos
	trail.top_level = true

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 30
	shape.shape = circle
	trail.add_child(shape)

	# Visual
	var visual = Node2D.new()
	trail.add_child(visual)
	var alpha = 0.6

	visual.draw.connect(func():
		visual.draw_circle(Vector2.ZERO, 30, Color(color.r, color.g, color.b, alpha * 0.3))
		visual.draw_circle(Vector2.ZERO, 20, Color(color.r, color.g, color.b, alpha * 0.5))
	)
	visual.queue_redraw()

	var parent = enemy.get_parent()
	if parent:
		parent.add_child(trail)

	# Trackear el efecto para limpieza
	_track_boss_effect(trail)

	# DaÃƒÂ±o y fade out
	var trail_damage = int(attack_damage * 0.2)
	var lifetime = 3.0
	var damage_cooldown = 0.0

	var timer = Timer.new()
	timer.wait_time = 0.05
	timer.autostart = true
	trail.add_child(timer)

	timer.timeout.connect(func():
		if not is_instance_valid(trail):
			return

		lifetime -= 0.05
		alpha = lifetime / 3.0
		visual.queue_redraw()

		if lifetime <= 0:
			trail.queue_free()
			return

		damage_cooldown -= 0.05
		if damage_cooldown <= 0 and is_instance_valid(player):
			var dist = trail_pos.distance_to(player.global_position)
			if dist < 30:
				if player.has_method("take_damage"):
					player.call("take_damage", trail_damage, elem, enemy)
				damage_cooldown = 0.5
	)

func _spawn_boss_orbitals(count: int) -> void:
	"""Crear orbitales que giran alrededor del boss - Usa VFXManager para visual"""
	if not is_instance_valid(enemy):
		return

	# Limpiar orbitales anteriores
	for orb in boss_orbitals:
		if is_instance_valid(orb):
			orb.queue_free()
	boss_orbitals.clear()

	var elem = _get_enemy_element()
	var color = _get_element_color(elem)
	var damage = int(attack_damage * 0.3)
	var vfx_mgr = get_node_or_null("/root/VFXManager")

	for i in range(count):
		var orbital = Area2D.new()
		orbital.name = "BossOrbital_%d" % i
		orbital.collision_layer = 0
		orbital.collision_mask = 1
		orbital.top_level = true

		var shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 15
		shape.shape = circle
		orbital.add_child(shape)

		# Intentar usar VFXManager para el visual
		var using_vfx = false
		if vfx_mgr and vfx_mgr.has_method("create_animated_sprite"):
			var sprite = vfx_mgr.create_animated_sprite("orbital", "boss")
			if sprite:
				sprite.scale = Vector2(0.3, 0.3)
				orbital.add_child(sprite)
				using_vfx = true

		# Visual fallback procedural
		if not using_vfx:
			var visual = Node2D.new()
			orbital.add_child(visual)
			var orb_color = color  # Capturar en scope local

			visual.draw.connect(func():
				visual.draw_circle(Vector2.ZERO, 18, Color(orb_color.r, orb_color.g, orb_color.b, 0.4))
				visual.draw_circle(Vector2.ZERO, 12, orb_color)
				visual.draw_circle(Vector2.ZERO, 6, Color(1, 1, 1, 0.9))
			)
			visual.queue_redraw()

		# Metadata para movimiento
		orbital.set_meta("angle", (TAU / count) * i)
		orbital.set_meta("radius", 80.0)
		orbital.set_meta("damage", damage)
		orbital.set_meta("damage_cooldown", 0.0)

		enemy.add_child(orbital)
		boss_orbitals.append(orbital)

func _update_boss_orbitals(delta: float) -> void:
	"""Actualizar posiciÃƒÂ³n y daÃƒÂ±o de orbitales"""
	var rotation_speed = 2.5 + boss_current_phase * 0.5
	var base_radius = 80.0 + boss_current_phase * 10

	for orbital in boss_orbitals:
		if not is_instance_valid(orbital):
			continue

		# Rotar
		var angle = orbital.get_meta("angle") + rotation_speed * delta
		orbital.set_meta("angle", angle)

		# Posicionar
		var radius = base_radius
		orbital.position = Vector2(cos(angle), sin(angle)) * radius

		# Check daÃƒÂ±o al jugador
		if is_instance_valid(player):
			var dist = orbital.global_position.distance_to(player.global_position)
			var cd = orbital.get_meta("damage_cooldown") - delta
			orbital.set_meta("damage_cooldown", max(0, cd))

			if dist < 25 and cd <= 0:
				var damage = orbital.get_meta("damage")
				if player.has_method("take_damage"):
					var elem = _get_enemy_element()
					player.call("take_damage", damage, elem, enemy)
				orbital.set_meta("damage_cooldown", 0.8)

func _spawn_aoe_warning(pos: Vector2, radius: float, duration: float) -> void:
	"""Mostrar warning de AOE antes del impacto"""
	# VFXManager hook - circle warning telegraph
	var vfx_mgr = get_node_or_null("/root/VFXManager")
	if vfx_mgr and vfx_mgr.has_method("spawn_circle_warning"):
		var vfx_node = vfx_mgr.spawn_circle_warning(pos, radius, duration)
		if vfx_node:
			_track_boss_effect(vfx_node)
			return

	# Fallback procedural
	var warning = Node2D.new()
	warning.name = "AOEWarning"
	warning.top_level = true
	warning.z_index = 5
	warning.global_position = pos

	var parent = enemy.get_parent() if is_instance_valid(enemy) else null
	if parent:
		parent.add_child(warning)
	else:
		return

	# Trackear el efecto para limpieza
	_track_boss_effect(warning)

	var elem = _get_enemy_element()
	var color = _get_element_color(elem)
	var anim = 0.0

	var visual = Node2D.new()
	warning.add_child(visual)

	visual.draw.connect(func():
		# CÃƒÂ­rculo pulsante
		var pulse = 0.5 + sin(anim * PI * 4) * 0.2
		visual.draw_arc(Vector2.ZERO, radius * pulse, 0, TAU, 32, Color(color.r, color.g, color.b, 0.5), 3.0)
		visual.draw_arc(Vector2.ZERO, radius * 0.7 * pulse, 0, TAU, 24, Color(1, 0.3, 0.3, 0.6), 2.0)
		# SÃƒÂ­mbolo de peligro
		visual.draw_circle(Vector2.ZERO, 10, Color(1, 0.2, 0.2, 0.8 * (1.0 - anim)))
	)

	var tween = warning.create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, duration)
	tween.tween_callback(func():
		if is_instance_valid(warning):
			warning.queue_free()
	)

func _spawn_aoe_explosion(pos: Vector2, radius: float) -> void:
	"""Visual de explosiÃƒÂ³n AOE"""
	var explosion = Node2D.new()
	explosion.name = "AOEExplosion"
	explosion.top_level = true
	explosion.z_index = 8
	explosion.global_position = pos

	var parent = enemy.get_parent() if is_instance_valid(enemy) else null
	if parent:
		parent.add_child(explosion)
	else:
		return

	# Trackear el efecto para limpieza
	_track_boss_effect(explosion)

	var elem = _get_enemy_element()
	var color = _get_element_color(elem)
	var anim = 0.0

	var visual = Node2D.new()
	explosion.add_child(visual)

	visual.draw.connect(func():
		var expand = radius * (0.5 + anim * 0.8)
		var alpha = 1.0 - anim

		# Ondas de explosiÃƒÂ³n
		for i in range(3):
			var r = expand * (1.0 - i * 0.2)
			visual.draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(color.r, color.g, color.b, alpha * (1.0 - i * 0.3)), 4.0 - i)

		# Relleno
		visual.draw_circle(Vector2.ZERO, expand * 0.5, Color(color.r, color.g, color.b, alpha * 0.4))
		visual.draw_circle(Vector2.ZERO, expand * 0.2, Color(1, 1, 1, alpha * 0.7))
	)

	var tween = explosion.create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.4)
	tween.tween_callback(func():
		if is_instance_valid(explosion):
			explosion.queue_free()
	)

func _spawn_boss_projectile(from: Vector2, direction: Vector2, damage: int, speed: float) -> void:
	"""Crear un proyectil del boss"""
	if EnemyProjectileScript:
		var projectile = Area2D.new()
		projectile.set_script(EnemyProjectileScript)
		projectile.global_position = from

		var parent = enemy.get_parent() if is_instance_valid(enemy) else null
		if parent:
			parent.add_child(projectile)

			if projectile.has_method("initialize"):
				var elem = _get_enemy_element()
				projectile.initialize(direction, speed, damage, 4.0, elem)

func _process_boss_special_abilities(delta: float) -> void:
	"""Procesar habilidades especiales del boss (sistema original)"""
	if boss_global_cooldown > 0:
		boss_global_cooldown -= delta
		return

	if boss_combo_timer > 0:
		boss_combo_timer -= delta
	else:
		boss_combo_count = 0

	var max_combo = boss_scaling_config.get("max_combo", 3)
	if boss_combo_count >= max_combo:
		return

	var available_abilities = _get_available_boss_abilities()
	if available_abilities.is_empty():
		return

	var selected_ability = _select_boss_ability(available_abilities)
	_execute_boss_ability(selected_ability)
	_apply_ability_cooldown(selected_ability)

	boss_combo_count += 1
	var combo_delay = boss_scaling_config.get("combo_delay", 1.0)
	boss_combo_timer = 4.0
	boss_global_cooldown = combo_delay

	# print("[Boss] debug")

func _init_boss_system() -> void:
	"""Inicializar sistema de boss con configuraciÃƒÂ³n de escalado"""
	if not boss_scaling_config.is_empty():
		return

	# Obtener minuto de spawn del boss
	var spawn_minute = 5
	if enemy and "enemy_data" in enemy:
		spawn_minute = enemy.enemy_data.get("spawn_minute", 5)
	elif modifiers.has("spawn_minute"):
		spawn_minute = modifiers.get("spawn_minute", 5)

	# Obtener configuraciÃƒÂ³n de escalado
	boss_scaling_config = SpawnConfig.get_boss_scaling_for_minute(spawn_minute)

	# Determinar habilidades desbloqueadas
	var max_abilities = boss_scaling_config.get("abilities_unlocked", 2)
	boss_unlocked_abilities = _get_prioritized_abilities(max_abilities)

	# Inicializar cooldowns solo para habilidades desbloqueadas
	for ability in boss_unlocked_abilities:
		boss_ability_cooldowns[ability] = 0.0

	# print("[Boss] debug")
	# print("[Boss] Ã°Å¸â€˜Â¹ Habilidades: %s" % str(boss_unlocked_abilities))

func _get_prioritized_abilities(max_count: int) -> Array:
	"""Obtener las habilidades priorizadas para desbloquear"""
	# Prioridad de habilidades (las bÃƒÂ¡sicas primero, las mÃƒÂ¡s poderosas despuÃƒÂ©s)
	var priority_order = {
		# Conjurador - bÃƒÂ¡sicas primero
		"arcane_barrage": 1,
		"summon_minions": 3,
		"teleport_strike": 2,
		"arcane_nova": 4,
		"curse_aura": 5,

		# CorazÃƒÂ³n del VacÃƒÂ­o
		"void_orbs": 1,
		"void_pull": 2,
		"void_explosion": 3,
		"reality_tear": 4,
		"void_beam": 5,
		"damage_aura": 6,

		# GuardiÃƒÂ¡n de Runas
		"rune_blast": 1,
		"rune_barrage": 2,
		"ground_slam": 3,
		"rune_prison": 4,
		"rune_shield": 5,
		"counter_stance": 6,

		# Minotauro
		"fire_stomp": 1,
		"charge_attack": 2,
		"flame_breath": 3,
		"meteor_call": 4,
		"enrage": 5,
		"fire_trail": 6
	}

	# Filtrar solo las habilidades de este boss
	var boss_abilities = special_abilities.duplicate()

	# Ordenar por prioridad
	boss_abilities.sort_custom(func(a, b):
		return priority_order.get(a, 10) < priority_order.get(b, 10)
	)

	# Tomar las primeras N
	var unlocked = []
	for i in range(min(max_count, boss_abilities.size())):
		unlocked.append(boss_abilities[i])

	return unlocked

func _apply_ability_cooldown(ability: String) -> void:
	"""Aplicar cooldown a una habilidad usada"""
	var ability_cooldowns = modifiers.get("ability_cooldowns", {})
	if ability_cooldowns.is_empty():
		var boss_data = _get_boss_data()
		if boss_data:
			ability_cooldowns = boss_data.get("ability_cooldowns", {})

	var base_cd = ability_cooldowns.get(ability, 5.0)

	# Aplicar modificador de cooldown del escalado por minuto
	var cooldown_mult = boss_scaling_config.get("cooldown_mult", 1.0)

	# Reducir cooldowns adicionales en fases avanzadas
	var phase_mult = 1.0 - (boss_current_phase - 1) * 0.1  # -10% por fase

	boss_ability_cooldowns[ability] = base_cd * cooldown_mult * phase_mult

func _update_boss_phase() -> void:
	"""Actualizar la fase del boss segÃƒÂºn su HP actual"""
	if not enemy:
		return

	# Obtener HP actual - usar health_component si existe, sino variable hp directa
	var current_hp: float = 0.0
	var max_hp_val: float = 1.0  # Evitar divisiÃƒÂ³n por cero

	if enemy.has_node("HealthComponent"):
		var hc = enemy.get_node("HealthComponent")
		current_hp = hc.current_health
		max_hp_val = max(1.0, hc.max_health)
	elif "hp" in enemy and "max_hp" in enemy:
		current_hp = enemy.hp
		max_hp_val = max(1.0, enemy.max_hp)
	else:
		return

	var hp_percent = current_hp / max_hp_val

	# Obtener umbrales de fase (ajustados por escalado del minuto)
	var phase_mult = boss_scaling_config.get("phase_threshold_mult", 1.0)
	var phase_2_threshold = modifiers.get("phase_2_hp", 0.6) / phase_mult
	var phase_3_threshold = modifiers.get("phase_3_hp", 0.3) / phase_mult

	# Clamp para evitar valores imposibles
	phase_2_threshold = clamp(phase_2_threshold, 0.3, 0.8)
	phase_3_threshold = clamp(phase_3_threshold, 0.1, 0.4)

	var new_phase = 1
	if hp_percent <= phase_3_threshold:
		new_phase = 3
	elif hp_percent <= phase_2_threshold:
		new_phase = 2

	if new_phase != boss_current_phase:
		var old_phase = boss_current_phase
		boss_current_phase = new_phase
		_on_boss_phase_change(old_phase, new_phase)

func _on_boss_phase_change(_old_phase: int, new_phase: int) -> void:
	"""Evento cuando el boss cambia de fase"""
	# print("[EnemyAttackSystem] Ã°Å¸â€˜Â¹Ã°Å¸â€™â‚¬ %s CAMBIÃƒâ€œ A FASE %d!" % [enemy.name, new_phase])

	# Efecto visual de cambio de fase
	_spawn_phase_change_effect()

	# Algunos bosses tienen efectos especiales al cambiar de fase
	var enemy_id = enemy.get("enemy_id") if "enemy_id" in enemy else ""

	# Minotauro se enfurece en fase 3
	if "minotauro" in enemy_id.to_lower() and new_phase == 3:
		_activate_boss_enrage()

	# CorazÃƒÂ³n del VacÃƒÂ­o activa aura de daÃƒÂ±o permanente en fase 2+
	if "corazon" in enemy_id.to_lower() and new_phase >= 2:
		boss_damage_aura_timer = 999.0  # Aura permanente
		# Spawn visual de aura de daÃ±o void via VFXManager
		_try_spawn_via_vfxmanager("damage_void", "aura", enemy.global_position, 0, 0)

	# Minotauro activa fire trail en fase 3
	if "minotauro" in enemy_id.to_lower() and new_phase == 3:
		boss_fire_trail_active = true

func _update_boss_passive_effects() -> void:
	"""Actualizar efectos pasivos de boss (auras, trails)"""
	if not enemy or not player:
		return

	# Damage Aura (Corazón del Vacío)
	if boss_damage_aura_timer > 0:
		var aura_radius = modifiers.get("aura_radius", 100.0)
		if boss_current_phase >= 3:
			aura_radius = modifiers.get("phase_3_aura_radius", aura_radius * 1.5)

		var dist = enemy.global_position.distance_to(player.global_position)
		if dist <= aura_radius:
			var aura_dps = modifiers.get("aura_damage", 8)
			# FIX P1 #15: Acumular daño fraccionario para que aura_dps*delta < 1 no se pierda
			_boss_aura_damage_accumulator += aura_dps * get_process_delta_time()
			if player.has_method("take_damage") and _boss_aura_damage_accumulator >= 1.0:
				var int_damage = int(_boss_aura_damage_accumulator)
				player.take_damage(int_damage, "void", enemy)
				_boss_aura_damage_accumulator -= int_damage
		else:
			_boss_aura_damage_accumulator = 0.0  # Reset si fuera de rango

	# Fire Trail (Minotauro fase 3)
	if boss_fire_trail_active:
		_spawn_fire_trail()

func _get_available_boss_abilities() -> Array:
	"""Obtener lista de habilidades disponibles (desbloqueadas y fuera de cooldown)"""
	var available = []
	var delta = get_process_delta_time()

	# Solo considerar habilidades desbloqueadas
	for ability in boss_unlocked_abilities:
		# Decrementar cooldown
		if ability in boss_ability_cooldowns:
			boss_ability_cooldowns[ability] = max(0, boss_ability_cooldowns[ability] - delta)

		# Verificar si estÃƒÂ¡ disponible
		if boss_ability_cooldowns.get(ability, 0) <= 0:
			# Algunas habilidades solo estÃƒÂ¡n disponibles en ciertas fases
			if _is_ability_available_in_phase(ability):
				available.append(ability)

	return available

func _is_ability_available_in_phase(ability: String) -> bool:
	"""Verificar si una habilidad estÃƒÂ¡ disponible en la fase actual"""
	# Habilidades mÃƒÂ¡s poderosas solo en fases avanzadas
	match ability:
		"void_beam", "meteor_call", "ground_slam":
			return boss_current_phase >= 2
		"enrage", "fire_trail", "damage_aura":
			return boss_current_phase >= 3
		_:
			return true

func _select_boss_ability(available: Array) -> String:
	"""Seleccionar habilidad con pesos basados en situaciÃƒÂ³n"""
	if available.is_empty():
		return ""

	var dist = enemy.global_position.distance_to(player.global_position)
	var weights = {}

	for ability in available:
		var weight = 1.0

		# Ajustar peso segÃƒÂºn distancia
		match ability:
			# Habilidades de rango cercano
			"fire_stomp", "void_explosion", "ground_slam", "arcane_nova":
				if dist < 150:
					weight = 3.0
				else:
					weight = 0.5

			# Habilidades de rango medio
			"rune_blast", "flame_breath", "void_pull":
				if dist < 200:
					weight = 2.0
				else:
					weight = 1.0

			# Habilidades de rango largo
			"arcane_barrage", "void_orbs", "meteor_call", "rune_barrage":
				if dist > 100:
					weight = 2.5
				else:
					weight = 1.0

			# Habilidades de gap-closer
			"charge_attack", "teleport_strike":
				if dist > 150:
					weight = 3.5
				else:
					weight = 0.5

			# Habilidades de utilidad
			"summon_minions", "rune_shield":
				weight = 1.5

			# Habilidades de control
			"rune_prison", "void_pull", "curse_aura":
				weight = 2.0

		# Bonus en fases avanzadas para habilidades mÃƒÂ¡s agresivas
		if boss_current_phase >= 2:
			if ability in ["void_explosion", "fire_stomp", "charge_attack", "meteor_call"]:
				weight *= 1.5

		weights[ability] = weight

	# SelecciÃƒÂ³n ponderada
	var total_weight = 0.0
	for w in weights.values():
		total_weight += w

	var roll = randf() * total_weight
	var accumulated = 0.0

	for ability in weights:
		accumulated += weights[ability]
		if roll <= accumulated:
			return ability

	return available[0]  # Fallback

func _execute_boss_ability(ability: String) -> void:
	"""Ejecutar una habilidad de boss especÃƒÂ­fica"""
	match ability:
		# El Conjurador Primigenio
		"arcane_barrage":
			_boss_arcane_barrage()
		"summon_minions":
			_boss_summon_minions()
		"teleport_strike":
			_boss_teleport_strike()
		"arcane_nova":
			_boss_arcane_nova()
		"curse_aura":
			_boss_curse_aura()

		# El CorazÃƒÂ³n del VacÃƒÂ­o
		"void_pull":
			_boss_void_pull()
		"void_explosion":
			_perform_boss_void_explosion()
		"void_orbs":
			_boss_void_orbs()
		"reality_tear":
			_boss_reality_tear()
		"void_beam":
			_boss_void_beam()

		# El GuardiÃƒÂ¡n de Runas
		"rune_shield":
			_boss_rune_shield()
		"rune_blast":
			_perform_boss_rune_blast()
		"rune_prison":
			_boss_rune_prison()
		"counter_stance":
			_boss_counter_stance()
		"rune_barrage":
			_boss_rune_barrage()
		"ground_slam":
			_boss_ground_slam()

		# Minotauro de Fuego
		"charge_attack":
			_boss_charge_attack()
		"fire_stomp":
			_perform_boss_fire_stomp()
		"flame_breath":
			_boss_flame_breath()
		"meteor_call":
			_boss_meteor_call()

		_:
			# Habilidad no implementada, usar ataque bÃƒÂ¡sico
			_perform_boss_melee_attack()

func _get_boss_data() -> Dictionary:
	"""Obtener datos del boss desde EnemyDatabase"""
	var enemy_id = enemy.get("enemy_id") if "enemy_id" in enemy else ""

	# Intentar obtener desde EnemyDatabase
	if EnemyDatabase:
		for boss_key in EnemyDatabase.BOSSES:
			var boss = EnemyDatabase.BOSSES[boss_key]
			if boss.get("id", "") == enemy_id or boss_key in enemy_id.to_lower():
				return boss

	return {}

# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
# HABILIDADES DE EL CONJURADOR PRIMIGENIO
# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

func _boss_arcane_barrage() -> void:
	"""RÃƒÂ¡faga de mÃƒÂºltiples proyectiles arcanos"""
	var count = modifiers.get("barrage_count", 5)
	var damage = modifiers.get("barrage_damage", 15)
	var spread = modifiers.get("barrage_spread", 30.0)

	if boss_current_phase >= 2:
		count = modifiers.get("phase_2_barrage_count", 7)

	var direction = (player.global_position - enemy.global_position).normalized()
	var spread_rad = deg_to_rad(spread)

	for i in range(count):
		var angle_offset = spread_rad * (float(i) / float(count - 1) - 0.5) if count > 1 else 0.0
		var proj_dir = direction.rotated(angle_offset)
		_spawn_boss_projectile_delayed(proj_dir, damage, "arcane", 0.05 * i)

	# print("[EnemyAttackSystem] Ã¢Å“Â¨ Arcane Barrage: %d proyectiles" % count)

func _boss_summon_minions() -> void:
	"""Invocar enemigos menores"""
	var count = modifiers.get("summon_count", 2)
	var tier = modifiers.get("summon_tier", 1)

	if boss_current_phase >= 2:
		count = modifiers.get("phase_2_summon_count", 3)
	if boss_current_phase >= 3:
		tier = modifiers.get("phase_3_summon_tier", 2)

	# Efecto visual de invocaciÃƒÂ³n
	_spawn_summon_visual()

	# Notificar al spawner para crear enemigos
	var spawner = _get_enemy_spawner()
	if spawner and spawner.has_method("spawn_minions_around"):
		spawner.spawn_minions_around(enemy.global_position, count, tier)
		# print("[EnemyAttackSystem] Ã°Å¸â€˜Â¹ Summon: %d minions tier %d" % [count, tier])
	else:
		pass
		# print("[EnemyAttackSystem] Ã¢Å¡Â Ã¯Â¸Â No se encontrÃƒÂ³ spawner para summon")

func _boss_teleport_strike() -> void:
	"""Teleport hacia el jugador + ataque tras telegraph"""
	var _teleport_range = modifiers.get("teleport_range", 200.0)
	var damage_mult = modifiers.get("teleport_damage_mult", 1.5)

	# Calcular posición de teleport (detrás del jugador)
	var to_player = (player.global_position - enemy.global_position).normalized()
	var teleport_pos = player.global_position - to_player * 50  # Aparecer cerca

	# Efecto de desaparición
	_spawn_teleport_effect(enemy.global_position, false)

	# Mover al enemigo
	enemy.global_position = teleport_pos

	# Efecto de aparición (TELEGRAPH: el jugador ve el destello)
	_spawn_teleport_effect(teleport_pos, true)

	# FIX P0 #1: Delay 0.4s entre teleport y daño para dar tiempo de reacción
	# FIX: Elemento corregido de "physical" a "arcane" (es Conjurador Arcano)
	var strike_range = 80.0
	get_tree().create_timer(0.4).timeout.connect(func():
		if not is_instance_valid(player) or not is_instance_valid(enemy):
			return
		var dist = enemy.global_position.distance_to(player.global_position)
		if dist <= strike_range:
			if player.has_method("take_damage"):
				var damage = int(attack_damage * damage_mult)
				player.take_damage(damage, "arcane", enemy)
				attacked_player.emit(damage, true)
	)

func _boss_arcane_nova() -> void:
	"""Nova de daño arcano en área con telegraph"""
	var radius = modifiers.get("nova_radius", 120.0)
	var damage = modifiers.get("nova_damage", 40)

	if boss_current_phase >= 3:
		damage = modifiers.get("phase_3_nova_damage", 60)

	# FIX P0 #5: Visual PRIMERO como telegraph
	var nova_center = enemy.global_position
	_spawn_arcane_nova_visual(nova_center, radius)

	# Daño tras delay de 0.5s para que el jugador pueda reaccionar
	get_tree().create_timer(0.5).timeout.connect(func():
		if not is_instance_valid(player) or not is_instance_valid(enemy):
			return
		var dist = nova_center.distance_to(player.global_position)
		if dist <= radius:
			if player.has_method("take_damage"):
				player.take_damage(damage, "arcane", enemy)
				attacked_player.emit(damage, false)
	)

func _boss_curse_aura() -> void:
	"""Aplicar aura de maldiciÃƒÂ³n que reduce curaciÃƒÂ³n"""
	var radius = modifiers.get("curse_radius", 150.0)
	var reduction = modifiers.get("curse_reduction", 0.5)
	var duration = modifiers.get("curse_duration", 8.0)

	var dist = enemy.global_position.distance_to(player.global_position)
	if dist <= radius:
		if player.has_method("apply_curse"):
			player.apply_curse(reduction, duration)
			# print("[EnemyAttackSystem] Ã¢ËœÂ Ã¯Â¸Â Curse Aura: -%.0f%% curaciÃƒÂ³n por %.1fs" % [reduction * 100, duration])

	# Visual
	_spawn_curse_aura_visual(enemy.global_position, radius)

# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
# HABILIDADES DE EL CORAZÃƒâ€œN DEL VACÃƒÂO
# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

func _boss_void_pull() -> void:
	"""Atraer al jugador hacia el boss"""
	var pull_radius = modifiers.get("pull_radius", 350.0)
	var pull_force = modifiers.get("pull_force", 150.0)
	var pull_duration = modifiers.get("pull_duration", 2.5)

	if boss_current_phase >= 2:
		pull_force = modifiers.get("phase_2_pull_force", 200.0)

	var dist = enemy.global_position.distance_to(player.global_position)
	if dist <= pull_radius:
		# Aplicar efecto de pull al jugador
		if player.has_method("apply_pull"):
			player.apply_pull(enemy.global_position, pull_force, pull_duration)
			# print("[EnemyAttackSystem] Ã°Å¸Å’â‚¬ Void Pull activado")
		else:
			pass  # Bloque else
			# Fallback: mover directamente al jugador
			var pull_dir = (enemy.global_position - player.global_position).normalized()
			_apply_knockback_to_player(pull_dir, pull_force * 0.5)

	# Visual
	_spawn_void_pull_visual(enemy.global_position, pull_radius)

func _boss_void_orbs() -> void:
	"""Lanzar orbes que persiguen al jugador"""
	var count = modifiers.get("orb_count", 3)
	var damage = modifiers.get("orb_damage", 25)
	var speed = modifiers.get("orb_speed", 120.0)
	var duration = modifiers.get("orb_duration", 5.0)

	if boss_current_phase >= 2:
		count = modifiers.get("phase_2_orb_count", 5)

	for i in range(count):
		var angle = (TAU / count) * i
		var spawn_offset = Vector2(cos(angle), sin(angle)) * 30
		_spawn_homing_orb(enemy.global_position + spawn_offset, damage, speed, duration, "dark")

	# print("[EnemyAttackSystem] Ã°Å¸â€™Å“ Void Orbs: %d orbes perseguidores" % count)

func _boss_reality_tear() -> void:
	"""Crear zona de daÃƒÂ±o persistente"""
	var radius = modifiers.get("tear_radius", 80.0)
	var damage = modifiers.get("tear_damage", 15)
	var duration = modifiers.get("tear_duration", 6.0)

	# _spawn_damage_zone ya invoca VFXManager internamente, no duplicar
	_spawn_damage_zone(player.global_position, radius, damage, duration, "dark")
	# print("[EnemyAttackSystem] Ã°Å¸Å’Å’ Reality Tear creado")

func _boss_void_beam() -> void:
	"""Rayo canalizado de alto daÃƒÂ±o"""
	var damage = modifiers.get("beam_damage", 30)
	var duration = modifiers.get("beam_duration", 3.0)
	var _width = modifiers.get("beam_width", 40.0)

	# FIX P0 #2: Verificar que el player está en el camino del beam (rectángulo)
	var direction = (player.global_position - enemy.global_position).normalized()
	var beam_length = 300.0
	var beam_width = 40.0

	# Crear visual del beam
	_spawn_void_beam_visual(enemy.global_position, direction, beam_length, duration)

	# Daño basado en ticks con comprobación de dirección del beam
	var beam_origin = enemy.global_position
	var ticks = int(duration / 0.5)
	for i in range(ticks):
		get_tree().create_timer(0.5 * i + 0.3).timeout.connect(func():
			if not is_instance_valid(player) or not is_instance_valid(enemy):
				return
			# Comprobar que player está dentro del rectángulo del beam
			var to_player = player.global_position - beam_origin
			var proj_length = to_player.dot(direction)
			if proj_length < 0 or proj_length > beam_length:
				return  # Fuera del alcance del beam
			var perp_dist = abs(to_player.cross(direction))
			if perp_dist > beam_width:
				return  # Fuera del ancho del beam
			if player.has_method("take_damage"):
				var tick_damage = int(damage / ticks)
				player.take_damage(tick_damage, "void", enemy)
				attacked_player.emit(tick_damage, false)
		)

# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
# HABILIDADES DE EL GUARDIÃƒÂN DE RUNAS
# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

func _boss_rune_shield() -> void:
	"""Activar escudo que absorbe hits"""
	var charges = modifiers.get("shield_charges", 4)
	var duration = modifiers.get("shield_duration", 10.0)

	if boss_current_phase >= 2:
		charges = modifiers.get("phase_2_shield_charges", 6)

	# FIX P1 #11: Implementar escudo via meta en lugar de método inexistente
	if enemy:
		enemy.set_meta("shield_charges", charges)
		enemy.set_meta("shield_active", true)
		# Auto-expirar
		get_tree().create_timer(duration).timeout.connect(func():
			if is_instance_valid(enemy):
				enemy.set_meta("shield_active", false)
				enemy.set_meta("shield_charges", 0)
		)

	# Visual
	_spawn_rune_shield_visual()

func _boss_rune_prison() -> void:
	"""Atrapar al jugador brevemente (con check de rango)"""
	var duration = modifiers.get("prison_duration", 1.5)
	var damage = modifiers.get("prison_damage", 20)
	var prison_range = modifiers.get("prison_range", 200.0)

	# FIX P1 #14: Verificar distancia antes de aplicar prisión
	var dist = enemy.global_position.distance_to(player.global_position)
	if dist > prison_range:
		return

	# Aplicar stun/root al jugador
	if player.has_method("apply_root"):
		player.apply_root(duration)
	elif player.has_method("apply_stun"):
		player.apply_stun(duration)

	# Daño al escapar (al final) con guards de validez
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(player) and is_instance_valid(enemy) and player.has_method("take_damage"):
			player.take_damage(damage, "arcane", enemy)
	)

	# Visual
	_spawn_rune_prison_visual(player.global_position, duration)

func _boss_counter_stance() -> void:
	"""Postura de contraataque"""
	var window = modifiers.get("counter_window", 2.0)
	var damage_mult = modifiers.get("counter_damage_mult", 2.5)

	if boss_current_phase >= 3:
		damage_mult = modifiers.get("phase_3_counter_damage_mult", 3.5)

	# FIX P1 #12: Activar counter_stance via meta en vez de metodo inexistente
	if enemy:
		enemy.set_meta("counter_stance_active", true)
		enemy.set_meta("counter_damage_mult", damage_mult)
		# Desactivar tras la ventana de tiempo
		get_tree().create_timer(window).timeout.connect(func():
			if is_instance_valid(enemy):
				enemy.set_meta("counter_stance_active", false)
		)

	# Visual
	_spawn_counter_stance_visual()
	# print("[EnemyAttackSystem] Ã¢Å¡â€Ã¯Â¸Â Counter Stance: %.1fs window, x%.1f daÃƒÂ±o" % [window, damage_mult])

func _boss_rune_barrage() -> void:
	"""MÃƒÂºltiples runas disparadas"""
	var count = modifiers.get("barrage_count", 6)
	var damage = modifiers.get("barrage_damage", 20)

	var direction = (player.global_position - enemy.global_position).normalized()
	var spread_rad = deg_to_rad(40.0)

	for i in range(count):
		var angle_offset = spread_rad * (float(i) / float(count - 1) - 0.5) if count > 1 else 0.0
		var proj_dir = direction.rotated(angle_offset)
		_spawn_boss_projectile_delayed(proj_dir, damage, "arcane", 0.08 * i)

	# print("[EnemyAttackSystem] Ã¢Å“Â¨ Rune Barrage: %d proyectiles" % count)

func _boss_ground_slam() -> void:
	"""Golpe de tierra con ondas expansivas y telegraph"""
	var radius = modifiers.get("slam_radius", 150.0)
	var damage = modifiers.get("slam_damage", 45)
	var stun = modifiers.get("slam_stun", 0.5)

	if boss_current_phase >= 3:
		damage = modifiers.get("phase_3_slam_damage", 70)

	# FIX P0 #7: Visual PRIMERO como telegraph
	var slam_center = enemy.global_position
	_spawn_ground_slam_visual(slam_center, radius)

	# Daño tras delay de 0.5s
	get_tree().create_timer(0.5).timeout.connect(func():
		if not is_instance_valid(player) or not is_instance_valid(enemy):
			return
		var dist = slam_center.distance_to(player.global_position)
		if dist <= radius:
			if player.has_method("take_damage"):
				player.take_damage(damage, "physical", enemy)
				attacked_player.emit(damage, false)
			if player.has_method("apply_stun"):
				player.apply_stun(stun)
	)

# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
# HABILIDADES DE MINOTAURO DE FUEGO
# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

func _boss_charge_attack() -> void:
	"""Carga devastadora hacia el jugador con telegraph"""
	var charge_speed = modifiers.get("charge_speed", 450.0)
	var damage_mult = modifiers.get("charge_damage_mult", 2.5)
	var stun = modifiers.get("charge_stun", 0.8)

	if boss_current_phase >= 2:
		damage_mult = modifiers.get("phase_2_charge_damage_mult", 3.0)

	# Calcular direccion y distancia
	var direction = (player.global_position - enemy.global_position).normalized()
	var charge_distance = enemy.global_position.distance_to(player.global_position) + 100

	# Visual de preparacion (TELEGRAPH)
	_spawn_charge_warning_visual(enemy.global_position, direction)

	# FIX P1 #13: Implementar carga inline con tween en vez de start_charge() inexistente
	var target_pos = enemy.global_position + direction * charge_distance
	var charge_time = charge_distance / charge_speed

	# Delay de telegraph antes de cargar
	get_tree().create_timer(0.5).timeout.connect(func():
		if not is_instance_valid(enemy) or not is_instance_valid(player):
			return
		# Mover enemigo con tween
		var tween = enemy.create_tween()
		tween.tween_property(enemy, "global_position", target_pos, charge_time)
		# Al finalizar la carga, comprobar si impacto al player
		tween.tween_callback(func():
			if not is_instance_valid(player) or not is_instance_valid(enemy):
				return
			var dist = enemy.global_position.distance_to(player.global_position)
			if dist < 80:
				var damage = int(attack_damage * damage_mult)
				if player.has_method("take_damage"):
					player.take_damage(damage, "physical", enemy)
					attacked_player.emit(damage, true)
				if player.has_method("apply_stun"):
					player.apply_stun(stun)
		)
	)
func _boss_flame_breath() -> void:
	"""Aliento de fuego en cono"""
	var angle = modifiers.get("breath_angle", 50.0)
	var range_dist = modifiers.get("breath_range", 180.0)
	var damage = modifiers.get("breath_damage", 25)
	var duration = modifiers.get("breath_duration", 2.0)

	if boss_current_phase >= 3:
		damage = modifiers.get("phase_3_breath_damage", 40)

	var direction = (player.global_position - enemy.global_position).normalized()

	# Verificar si player estÃƒÂ¡ en el cono
	var to_player = player.global_position - enemy.global_position
	var dist = to_player.length()
	var angle_to_player = abs(rad_to_deg(direction.angle_to(to_player.normalized())))

	if dist <= range_dist and angle_to_player <= angle / 2:
		if player.has_method("take_damage"):
			player.take_damage(damage, "fire", enemy)
			attacked_player.emit(damage, false)
		if player.has_method("apply_burn"):
			player.apply_burn(damage * 0.5, duration)

	# Visual
	_spawn_flame_breath_visual(enemy.global_position, direction, range_dist)
	# print("[EnemyAttackSystem] Ã°Å¸â€Â¥ Flame Breath: %d daÃƒÂ±o en cono" % damage)

func _boss_meteor_call() -> void:
	"""Invocar meteoros del cielo"""
	var count = modifiers.get("meteor_count", 5)
	var damage = modifiers.get("meteor_damage", 50)
	var radius = modifiers.get("meteor_radius", 60.0)
	var delay = modifiers.get("meteor_delay", 1.5)

	if boss_current_phase >= 3:
		count = modifiers.get("phase_3_meteor_count", 8)

	# Crear varios meteoros alrededor del jugador
	for i in range(count):
		var offset = Vector2(randf_range(-150, 150), randf_range(-150, 150))
		var target_pos = player.global_position + offset

		# Indicador de impacto
		_spawn_meteor_warning(target_pos, radius, delay)

		# Meteoro real despuÃƒÂ©s del delay
		get_tree().create_timer(delay + i * 0.2).timeout.connect(func():
			_spawn_meteor_impact(target_pos, radius, damage)
		)

	# print("[EnemyAttackSystem] Ã¢Ëœâ€žÃ¯Â¸Â Meteor Call: %d meteoros" % count)

func _activate_boss_enrage() -> void:
	"""Activar estado de furia del boss"""
	if boss_enraged:
		return

	boss_enraged = true

	var damage_bonus = modifiers.get("enrage_damage_bonus", 0.5)
	var speed_bonus = modifiers.get("enrage_speed_bonus", 0.3)

	# Aplicar buffs al enemigo
	if enemy.has_method("apply_enrage"):
		enemy.apply_enrage(damage_bonus, speed_bonus)
	else:
		pass  # Bloque else
		# Fallback: modificar stats directamente
		attack_damage = int(attack_damage * (1 + damage_bonus))
		if "base_speed" in enemy:
			enemy.base_speed *= (1 + speed_bonus)

	# Visual
	_spawn_enrage_visual()
	# print("[EnemyAttackSystem] Ã°Å¸â€Â¥Ã°Å¸â€™Â¢ BOSS ENRAGED! +%.0f%% daÃƒÂ±o, +%.0f%% velocidad" % [damage_bonus * 100, speed_bonus * 100])

func _spawn_fire_trail() -> void:
	"""Dejar rastro de fuego al caminar"""
	var trail_damage = modifiers.get("trail_damage", 10)
	var trail_duration = modifiers.get("trail_duration", 3.0)

	# Solo crear trail cada cierto tiempo
	if Engine.get_process_frames() % 10 != 0:
		return

	_spawn_damage_zone(enemy.global_position, 25.0, trail_damage, trail_duration, "fire")

func _perform_boss_melee_attack() -> void:
	"""Ataque melee especial de boss con efecto visual grande"""
	if not player or not player.has_method("take_damage"):
		return

	# Verificar que el player está en rango melee del boss (radio generoso para bosses)
	var dist_to_player = enemy.global_position.distance_to(player.global_position)
	if dist_to_player > 80.0:  # Rango melee amplio para bosses
		return

	var boss_damage = int(attack_damage * 1.2)  # Bosses hacen mÃƒÂ¡s daÃƒÂ±o
	player.take_damage(boss_damage, "physical", enemy)
	# print("[EnemyAttackSystem] Ã°Å¸â€˜Â¹ %s (Boss) melee devastador por %d daÃƒÂ±o" % [enemy.name, boss_damage])

	# Aplicar efecto segÃƒÂºn el boss
	_apply_boss_melee_effects()

	attacked_player.emit(boss_damage, true)

	# Efecto visual de impacto de boss (mÃƒÂ¡s grande)
	_spawn_boss_impact_effect()

func _apply_boss_melee_effects() -> void:
	"""Efectos de estado en ataques melee de boss"""
	var enemy_name_lower = enemy.name.to_lower()

	# Minotauro - Burn
	if "minotauro" in enemy_name_lower or "fuego" in enemy_name_lower:
		if player.has_method("apply_burn"):
			player.apply_burn(8.0, 3.0)  # 8 daÃƒÂ±o/tick por 3s
	# CorazÃƒÂ³n del VacÃƒÂ­o - Weakness
	elif "corazon" in enemy_name_lower or "vacio" in enemy_name_lower:
		if player.has_method("apply_weakness"):
			player.apply_weakness(0.3, 4.0)  # +30% daÃƒÂ±o recibido por 4s
	# GuardiÃƒÂ¡n de Runas - Stun breve
	elif "guardian" in enemy_name_lower or "runas" in enemy_name_lower:
		if player.has_method("apply_stun"):
			player.apply_stun(0.3)  # 0.3s stun
	# Conjurador - Curse
	elif "conjurador" in enemy_name_lower:
		if player.has_method("apply_curse"):
			player.apply_curse(0.4, 5.0)  # -40% curaciÃƒÂ³n por 5s

func _perform_boss_void_explosion() -> void:
	"""El Corazón del Vacío - explosión de vacío con telegraph"""
	if not player:
		return

	var explosion_radius = modifiers.get("explosion_radius", 150.0)
	var explosion_damage = modifiers.get("explosion_damage", 60)

	# FIX P0 #6: Visual PRIMERO como telegraph
	var explosion_center = enemy.global_position
	_spawn_void_explosion_visual(explosion_center, explosion_radius)

	# Daño tras delay de 0.5s
	get_tree().create_timer(0.5).timeout.connect(func():
		if not is_instance_valid(player) or not is_instance_valid(enemy):
			return
		var dist = explosion_center.distance_to(player.global_position)
		if dist <= explosion_radius:
			if player.has_method("take_damage"):
				player.take_damage(explosion_damage, "void", enemy)
				attacked_player.emit(explosion_damage, false)
				if player.has_method("apply_weakness"):
					player.apply_weakness(0.4, 5.0)
	)

func _perform_boss_rune_blast() -> void:
	"""El Guardián de Runas - explosión de runas con telegraph"""
	if not player:
		return

	var blast_radius = modifiers.get("blast_radius", 100.0)
	var blast_damage = modifiers.get("blast_damage", 45)

	# FIX: Visual PRIMERO como telegraph
	var blast_center = enemy.global_position
	_spawn_rune_blast_visual(blast_center, blast_radius)

	# Daño tras delay de 0.5s
	get_tree().create_timer(0.5).timeout.connect(func():
		if not is_instance_valid(player) or not is_instance_valid(enemy):
			return
		var dist = blast_center.distance_to(player.global_position)
		if dist <= blast_radius:
			if player.has_method("take_damage"):
				player.take_damage(blast_damage, "arcane", enemy)
				attacked_player.emit(blast_damage, false)
				if player.has_method("apply_stun"):
					player.apply_stun(0.5)
	)

func _perform_boss_fire_stomp() -> void:
	"""Minotauro de Fuego - pisoton de fuego con telegraph"""
	if not player:
		return

	var stomp_radius = modifiers.get("stomp_radius", 120.0)
	var stomp_damage = modifiers.get("stomp_damage", 50)

	# FIX: Visual PRIMERO como telegraph
	var stomp_center = enemy.global_position
	_spawn_fire_stomp_visual(stomp_center, stomp_radius)

	# Dano tras delay de 0.5s
	get_tree().create_timer(0.5).timeout.connect(func():
		if not is_instance_valid(player) or not is_instance_valid(enemy):
			return
		var dist = stomp_center.distance_to(player.global_position)
		if dist <= stomp_radius:
			if player.has_method("take_damage"):
				player.take_damage(stomp_damage, "fire", enemy)
				attacked_player.emit(stomp_damage, false)
				if player.has_method("apply_burn"):
					player.apply_burn(10.0, 4.0)
				if player.has_method("apply_stun"):
					player.apply_stun(0.3)
	)

func _spawn_boss_impact_effect() -> void:
	"""Efecto de impacto de ataque de boss"""
	if not enemy or not player:
		return

	# VFXManager hook - boss melee impact AOE
	if _try_spawn_via_vfxmanager("boss_melee_impact", "aoe", player.global_position, 50.0, 0.3):
		return

	# Fallback procedural
	var impact_pos = player.global_position
	var effect = Node2D.new()
	effect.global_position = impact_pos

	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)

	var anim_progress = 0.0
	var elem = _get_enemy_element()
	var color = _get_element_color(elem)

	var visual = Node2D.new()
	effect.add_child(visual)

	visual.draw.connect(func():
		# Impacto masivo
		var radius = 50 * anim_progress

		# Ondas de choque - alpha reducido
		for i in range(3):
			var wave_radius = radius * (1.0 + i * 0.3)
			var wave_alpha = (1.0 - anim_progress) * (0.25 - i * 0.06)
			visual.draw_arc(Vector2.ZERO, wave_radius, 0, TAU, 32, Color(color.r, color.g, color.b, wave_alpha), 2.5 - i * 0.5)

		# Cruz de impacto - alpha reducido
		var cross_size = radius * 1.2
		var cross_alpha = (1.0 - anim_progress) * 0.3
		visual.draw_line(Vector2(-cross_size, 0), Vector2(cross_size, 0), Color(1, 1, 1, cross_alpha), 2.0)
		visual.draw_line(Vector2(0, -cross_size), Vector2(0, cross_size), Color(1, 1, 1, cross_alpha), 2.0)
	)

	# IMPORTANTE: Usar effect.create_tween() para que el tween se limpie con el nodo
	var tween = effect.create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.3)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_void_explosion_visual(center: Vector2, radius: float) -> void:
	"""Visual de explosion de vacio - Usa VFXManager si disponible"""
	# Intentar VFXManager primero
	if _try_spawn_via_vfxmanager("void_explosion", "aoe", center, radius, 0.6):
		return

	# Clamp radius to prevent screen-covering effects
	var clamped_radius = minf(radius, 120.0)

	# Fallback procedural
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 5
	effect.global_position = center

	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)

	var anim_progress = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)

	visual.draw.connect(func():
		var phase = anim_progress

		if phase < 0.35:
			var absorb_phase = phase / 0.35
			var absorb_radius = clamped_radius * (1.0 - absorb_phase * 0.6)

			# Single absorb ring instead of 2
			var layer_alpha = 0.04 * absorb_phase
			visual.draw_circle(Vector2.ZERO, absorb_radius, Color(0.4, 0.05, 0.7, layer_alpha))

			var particle_count = 4
			for i in range(particle_count):
				var angle = (TAU / particle_count) * i + phase * PI * 2
				var dist = absorb_radius * (1.2 - absorb_phase * 0.5)
				var pos = Vector2(cos(angle), sin(angle)) * dist
				visual.draw_circle(pos, 2, Color(0.85, 0.4, 1.0, 0.15))
		else:
			var explode_phase = (phase - 0.35) / 0.65
			var explode_radius = clamped_radius * explode_phase

			# Single wave arc
			var wave_alpha = (1.0 - explode_phase) * 0.12
			visual.draw_arc(Vector2.ZERO, explode_radius, 0, TAU, 48, Color(0.6, 0.1, 0.95, wave_alpha), 1.5)

			# Subtle fill
			var fill_r = explode_radius * 0.6
			var fill_alpha = (1.0 - explode_phase) * 0.03
			visual.draw_circle(Vector2.ZERO, fill_r, Color(0.5, 0.1, 0.8, fill_alpha))

			# Fewer rays with lower alpha
			var ray_count = 3
			for i in range(ray_count):
				var ray_angle = (TAU / ray_count) * i + explode_phase * PI * 0.5
				var ray_length = explode_radius * 0.7
				var ray_end = Vector2(cos(ray_angle), sin(ray_angle)) * ray_length
				visual.draw_line(Vector2.ZERO, ray_end, Color(0.9, 0.5, 1.0, (1.0 - explode_phase) * 0.1), 1.0)

			var core_size = 10 * (1.0 - explode_phase * 0.7)
			visual.draw_circle(Vector2.ZERO, core_size, Color(0.15, 0, 0.25, 0.15 * (1.0 - explode_phase)))
	)

	# IMPORTANTE: Usar effect.create_tween() para que el tween se limpie con el nodo
	var tween = effect.create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.9)  # MÃƒÂ¡s largo para ser ÃƒÂ©pico
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_rune_blast_visual(center: Vector2, radius: float) -> void:
	"""Visual de explosiÃƒÂ³n de runas Ãƒâ€°PICA - sÃƒÂ­mbolos brillantes"""
	# Intentar usar VFXManager primero
	if _try_spawn_via_vfxmanager("rune_blast", "aoe", center, radius, 0.5):
		return  # VFXManager manejÃ³ el efecto

	# Fallback procedural si no hay spritesheet
	var effect = Node2D.new()
	effect.top_level = true  # Independiente del enemigo
	effect.z_index = 5  # MUY alto para boss
	effect.global_position = center

	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)

	var anim_progress = 0.0
	var rune_count = 8
	var visual = Node2D.new()
	effect.add_child(visual)

	visual.draw.connect(func():
		var expand = radius * 1.2 * anim_progress

		# CÃƒÂ­rculos mÃƒÂ¡gicos concÃƒÂ©ntricos (nuevo)
		for c in range(3):
			var circle_r = expand * (0.4 + c * 0.25)
			var circle_alpha = 0.5 * (1.0 - anim_progress) * (1.0 - c * 0.25)
			visual.draw_arc(Vector2.ZERO, circle_r, 0, TAU, 48, Color(0.95, 0.85, 0.15, circle_alpha), 3.0)

		# Relleno dorado con gradiente
		for i in range(4):
			var fill_r = expand * (0.9 - i * 0.15)
			var fill_alpha = (1.0 - anim_progress) * (0.3 - i * 0.06)
			visual.draw_circle(Vector2.ZERO, fill_r, Color(1, 0.9, 0.2, fill_alpha))

		# Runas individuales que se expanden - MÃƒÂS Y MÃƒÂS GRANDES
		for i in range(rune_count):
			var angle = (TAU / rune_count) * i + anim_progress * PI * 0.7
			var dist = expand * (0.45 + anim_progress * 0.55)
			var pos = Vector2(cos(angle), sin(angle)) * dist

			# Dibujar runa como forma geomÃƒÂ©trica - MÃƒÂS GRANDE
			var rune_size = 18 * (1.0 - anim_progress * 0.4)

			# TriÃƒÂ¡ngulo exterior
			var rune_points = PackedVector2Array([
				pos + Vector2(0, -rune_size),
				pos + Vector2(rune_size * 0.85, rune_size * 0.6),
				pos + Vector2(-rune_size * 0.85, rune_size * 0.6)
			])
			visual.draw_colored_polygon(rune_points, Color(1, 0.92, 0.35, 0.9 * (1.0 - anim_progress)))

			# TriÃƒÂ¡ngulo interior invertido
			var inner_size = rune_size * 0.5
			var inner_points = PackedVector2Array([
				pos + Vector2(0, inner_size * 0.5),
				pos + Vector2(inner_size * 0.4, -inner_size * 0.3),
				pos + Vector2(-inner_size * 0.4, -inner_size * 0.3)
			])
			visual.draw_colored_polygon(inner_points, Color(1, 1, 0.8, 0.95 * (1.0 - anim_progress)))

			# Brillo alrededor - MÃƒÂS GRANDE
			visual.draw_circle(pos, rune_size * 2.0, Color(1, 1, 0.5, 0.25 * (1.0 - anim_progress)))
			visual.draw_circle(pos, rune_size * 1.3, Color(1, 0.95, 0.4, 0.4 * (1.0 - anim_progress)))

		# LÃƒÂ­neas de conexiÃƒÂ³n entre runas (nuevo)
		for i in range(rune_count):
			var angle1 = (TAU / rune_count) * i + anim_progress * PI * 0.7
			var angle2 = (TAU / rune_count) * ((i + 1) % rune_count) + anim_progress * PI * 0.7
			var dist = expand * (0.45 + anim_progress * 0.55)
			var pos1 = Vector2(cos(angle1), sin(angle1)) * dist
			var pos2 = Vector2(cos(angle2), sin(angle2)) * dist
			visual.draw_line(pos1, pos2, Color(1, 0.9, 0.3, 0.4 * (1.0 - anim_progress)), 2.0)

		# Rayos desde el centro (nuevo)
		for i in range(rune_count):
			var ray_angle = (TAU / rune_count) * i + anim_progress * PI * 0.3
			var ray_length = expand * 0.9
			var ray_end = Vector2(cos(ray_angle), sin(ray_angle)) * ray_length
			visual.draw_line(Vector2.ZERO, ray_end, Color(1, 1, 0.7, 0.5 * (1.0 - anim_progress)), 2.0)

		# Onda de expansiÃƒÂ³n final - MÃƒÂS BRILLANTE
		visual.draw_arc(Vector2.ZERO, expand, 0, TAU, 64, Color(1, 1, 1, 0.7 * (1.0 - anim_progress)), 4.0)

		# Centro brillante
		var core_size = 20 * (1.0 - anim_progress * 0.5)
		visual.draw_circle(Vector2.ZERO, core_size, Color(1, 1, 0.9, 0.9 * (1.0 - anim_progress)))
	)

	# IMPORTANTE: Usar effect.create_tween() para que el tween se limpie con el nodo
	var tween = effect.create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.6)  # MÃƒÂ¡s largo
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_fire_stomp_visual(center: Vector2, radius: float) -> void:
	"""Visual de pisoton de fuego - Usa VFXManager si disponible"""
	# Intentar VFXManager primero
	if _try_spawn_via_vfxmanager("fire_stomp", "aoe", center, radius, 0.6):
		return

	# Fallback procedural
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 5
	effect.global_position = center

	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)

	var anim_progress = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)

	visual.draw.connect(func():
		var expand = radius * 1.2 * anim_progress

		# CrÃƒÂ¡ter central - MÃƒÂS DETALLADO
		var crater_size = expand * 0.35
		visual.draw_circle(Vector2.ZERO, crater_size, Color(0.2, 0.05, 0, 0.8 * (1.0 - anim_progress)))
		visual.draw_arc(Vector2.ZERO, crater_size * 0.7, 0, TAU, 24, Color(0.4, 0.1, 0, 0.6), 3.0)

		# Anillos de fuego - MÃƒÂS Y MÃƒÂS GRUESOS
		for i in range(5):
			var ring_r = expand * (0.35 + i * 0.18)
			var ring_alpha = (1.0 - anim_progress) * (0.85 - i * 0.14)
			var ring_color = Color(1.0 - i * 0.08, 0.45 - i * 0.08, 0.05, ring_alpha)
			visual.draw_arc(Vector2.ZERO, ring_r, 0, TAU, 48, ring_color, 6.0 - i)

		# Relleno de fuego con gradiente
		for i in range(4):
			var fill_r = expand * (0.9 - i * 0.15)
			var fill_alpha = (1.0 - anim_progress) * (0.35 - i * 0.07)
			visual.draw_circle(Vector2.ZERO, fill_r, Color(1.0, 0.3, 0.05, fill_alpha))

		# Llamas alrededor - MÃƒÂS Y MÃƒÂS GRANDES
		var flame_count = 16
		for i in range(flame_count):
			var angle = (TAU / flame_count) * i
			var flame_dist = expand * 0.75
			var flame_base = Vector2(cos(angle), sin(angle)) * flame_dist

			# Altura de llama animada - mÃƒÂ¡s dramÃƒÂ¡tica
			var flame_height = 25 * (1.0 - anim_progress * 0.6) * (0.7 + sin(anim_progress * PI * 5 + i * 1.2) * 0.3)
			var flame_width = 10

			var flame_tip = flame_base + Vector2(0, -flame_height)
			var flame_left = flame_base + Vector2(-flame_width, 0)
			var flame_right = flame_base + Vector2(flame_width, 0)

			# Llama exterior (roja)
			visual.draw_colored_polygon(
				PackedVector2Array([flame_tip, flame_left, flame_right]),
				Color(1, 0.35, 0.08, 0.85 * (1.0 - anim_progress))
			)

			# NÃƒÂºcleo de llama (amarillo)
			var inner_tip = flame_base + Vector2(0, -flame_height * 0.6)
			var inner_left = flame_base + Vector2(-flame_width * 0.5, 0)
			var inner_right = flame_base + Vector2(flame_width * 0.5, 0)
			visual.draw_colored_polygon(
				PackedVector2Array([inner_tip, inner_left, inner_right]),
				Color(1, 0.8, 0.2, 0.9 * (1.0 - anim_progress))
			)

		# Chispas voladoras (nuevo)
		var spark_count = 20
		for i in range(spark_count):
			var spark_angle = (TAU / spark_count) * i + anim_progress * PI
			var spark_dist = expand * (0.5 + anim_progress * 0.8)
			var spark_pos = Vector2(cos(spark_angle), sin(spark_angle)) * spark_dist
			spark_pos.y -= anim_progress * 30 * sin(i * 0.7)  # Chispas que suben
			var spark_size = 4.0 * (1.0 - anim_progress * 0.6)
			visual.draw_circle(spark_pos, spark_size, Color(1, 0.9, 0.3, 0.8 * (1.0 - anim_progress)))

		# Onda de calor exterior
		visual.draw_arc(Vector2.ZERO, expand, 0, TAU, 64, Color(1, 0.5, 0.1, 0.5 * (1.0 - anim_progress)), 4.0)
	)

	# IMPORTANTE: Usar effect.create_tween() para que el tween se limpie con el nodo
	var tween = effect.create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.7)  # MÃƒÂ¡s largo para ser ÃƒÂ©pico
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_multi_projectile(direction: Vector2, delay: float) -> void:
	"""Crear un proyectil del multi-attack con delay"""
	if delay > 0:
		get_tree().create_timer(delay).timeout.connect(func(): _create_single_projectile(direction))
	else:
		_create_single_projectile(direction)

func _create_single_projectile(direction: Vector2) -> void:
	"""Crear un ÃƒÂºnico proyectil"""
	if not EnemyProjectileScript or not is_instance_valid(enemy):
		return

	var projectile = Area2D.new()
	projectile.set_script(EnemyProjectileScript)
	projectile.global_position = enemy.global_position

	var elem = _get_enemy_element()
	var proj_damage = int(attack_damage * 0.7)  # Multi tiene menos daÃƒÂ±o por proyectil

	var parent = enemy.get_parent()
	if parent:
		parent.add_child(projectile)
	else:
		get_tree().root.add_child(projectile)

	if projectile.has_method("initialize"):
		projectile.initialize(direction, projectile_speed, proj_damage, 5.0, elem)

func _get_enemy_element() -> String:
	"""Obtener elemento del enemigo basado en su ID o archetype"""
	if not enemy:
		return "physical"

	# FIX FASE 2: Multi-element cycling (Archimago)
	if enemy.has_meta("multi_element") and enemy.get_meta("multi_element"):
		var cycle = enemy.get_meta("element_cycle") if enemy.has_meta("element_cycle") else ["fire", "ice", "arcane"]
		var idx = enemy.get_meta("element_cycle_idx") if enemy.has_meta("element_cycle_idx") else 0
		var elem = cycle[idx % cycle.size()]
		enemy.set_meta("element_cycle_idx", (idx + 1) % cycle.size())
		return elem

	var enemy_id = enemy.get("enemy_id") if "enemy_id" in enemy else ""
	var name_lower = enemy_id.to_lower()

	# Casos especiales primero (antes de la detecciÃ³n genÃ©rica)
	# Hechicero Desgastado es un mago de fuego corrupto
	if "hechicero_desgastado" in name_lower or "hechicero" in name_lower:
		return "fire"

	# Bosses especÃ­ficos
	if "guardian" in name_lower and "runas" in name_lower:
		return "arcane"  # GuardiÃ¡n de Runas usa magia arcana
	if "conjurador" in name_lower:
		return "arcane"  # El Conjurador es mago arcano
	if "minotauro" in name_lower:
		return "fire"    # Minotauro de Fuego

	if "fuego" in name_lower or "llamas" in name_lower or "fire" in name_lower:
		return "fire"
	if "hielo" in name_lower or "ice" in name_lower or "frost" in name_lower or "cristal" in name_lower:
		return "ice"
	if "void" in name_lower or "vacio" in name_lower or "shadow" in name_lower or "sombra" in name_lower or "corazon" in name_lower:
		return "dark"
	if "arcano" in name_lower or "arcane" in name_lower or "mago" in name_lower or "runas" in name_lower:
		return "arcane"
	if "veneno" in name_lower or "poison" in name_lower:
		return "poison"
	if "rayo" in name_lower or "lightning" in name_lower or "thunder" in name_lower:
		return "lightning"

	return "physical"

func _spawn_aoe_visual(center: Vector2, radius: float) -> void:
	"""Crear efecto visual de AoE - Usa VFXManager si disponible"""
	var elem = _get_enemy_element()

	# Mapear elemento a tipo de AOE para VFXManager
	var aoe_type = "arcane_nova"
	match elem:
		"fire": aoe_type = "fire_stomp"
		"ice": aoe_type = "freeze_zone"
		"void", "dark", "shadow": aoe_type = "void_explosion"
		"earth": aoe_type = "ground_slam"
		"arcane", "magic": aoe_type = "arcane_nova"

	# Intentar VFXManager primero
	if _try_spawn_via_vfxmanager(aoe_type, "aoe", center, radius, 0.5):
		return

	# Fallback procedural
	var base_color = _get_element_color(elem)
	var bright_color = Color(min(base_color.r + 0.4, 1.0), min(base_color.g + 0.4, 1.0), min(base_color.b + 0.4, 1.0), 1.0)

	# Crear contenedor principal - INDEPENDIENTE del enemigo
	var container = Node2D.new()
	container.name = "AoE_Visual"
	container.top_level = true  # No se mueve con el padre
	container.z_index = 5  # Visible pero no encima de todo
	container.global_position = center

	var parent = enemy.get_parent()
	if parent:
		parent.add_child(container)

	# Determinar si es ÃƒÂ©lite para efectos mÃƒÂ¡s grandes
	var is_elite = enemy.get("is_elite") if "is_elite" in enemy else false
	var size_mult = 1.3 if is_elite else 1.0
	var actual_radius = minf(radius * size_mult, 150.0)  # Clamp to prevent screen-covering

	# Variables de animaciÃƒÂ³n
	var anim_progress = 0.0
	var ring_count = 4

	# Nodo visual para dibujar
	var visual = Node2D.new()
	container.add_child(visual)

	visual.draw.connect(func():
		var expand_radius = actual_radius * anim_progress

		# Glow exterior - single subtle ring only
		if expand_radius > 0:
			visual.draw_arc(Vector2.ZERO, expand_radius, 0, TAU, 48, Color(base_color.r, base_color.g, base_color.b, 0.15 * (1.0 - anim_progress)), 2.0)

		# Single subtle fill instead of 3 layered gradients
		if expand_radius > 0:
			visual.draw_circle(Vector2.ZERO, expand_radius * 0.7, Color(base_color.r, base_color.g, base_color.b, 0.05 * (1.0 - anim_progress)))

		# Anillos de onda expansiva (reduced to 2)
		for i in range(2):
			var ring_phase = fmod(anim_progress * 2.5 + i * 0.4, 1.0)
			var ring_radius = actual_radius * ring_phase
			var ring_alpha = (1.0 - ring_phase) * 0.25
			if ring_radius > 0:
				visual.draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 48, Color(bright_color.r, bright_color.g, bright_color.b, ring_alpha), 1.5)

		# Particulas decorativas (reducidas)
		var particle_count = 4
		for i in range(particle_count):
			var angle = (TAU / particle_count) * i + anim_progress * PI * 1.5
			var dist = expand_radius * (0.7 + sin(anim_progress * PI * 3 + i) * 0.2)
			var particle_pos = Vector2(cos(angle), sin(angle)) * dist
			var particle_size = (2.0 + sin(anim_progress * PI * 5 + i) * 1.5) * size_mult
			visual.draw_circle(particle_pos, particle_size, Color(bright_color.r, bright_color.g, bright_color.b, 0.3))

		# Borde exterior
		if expand_radius > 0:
			visual.draw_arc(Vector2.ZERO, expand_radius, 0, TAU, 64, Color(1, 1, 1, 0.3 * (1.0 - anim_progress)), 1.5)

		# Centro de impacto
		var core_size = expand_radius * 0.1 * (1.0 - anim_progress * 0.5)
		if core_size > 0:
			visual.draw_circle(Vector2.ZERO, core_size, Color(1, 1, 1, 0.3 * (1.0 - anim_progress)))
	)

	# AnimaciÃƒÂ³n de expansiÃƒÂ³n - MÃƒÂS LARGA para ser muy visible
	# IMPORTANTE: Usar container.create_tween() para que el tween se limpie con el nodo
	var tween = container.create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.8)  # 0.8 segundos (antes 0.6)

	# Fade out suave y destruir
	tween.tween_property(container, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func():
		if is_instance_valid(container):
			container.queue_free()
	)

func _spawn_breath_visual(origin: Vector2, direction: Vector2, range_dist: float) -> void:
	"""Crear efecto visual de breath attack Ãƒâ€°PICO con animaciÃƒÂ³n de expansiÃƒÂ³n"""
	# VFXManager hook - flame breath beam
	var vfx_mgr = get_node_or_null("/root/VFXManager")
	if vfx_mgr and vfx_mgr.has_method("spawn_beam"):
		var beam = vfx_mgr.spawn_beam("flame_breath", origin, direction, range_dist)
		if beam:
			return

	# Fallback procedural
	var container = Node2D.new()
	container.name = "Breath_Visual"
	container.top_level = true  # No se mueve con el padre
	container.z_index = 8  # MUY visible encima de otros elementos
	container.global_position = origin
	container.rotation = direction.angle()

	var elem = _get_enemy_element()
	var base_color = _get_element_color(elem)
	var bright_color = Color(min(base_color.r + 0.5, 1.0), min(base_color.g + 0.5, 1.0), min(base_color.b + 0.3, 1.0), 1.0)

	var parent = enemy.get_parent()
	if parent:
		parent.add_child(container)

	# Determinar si es ÃƒÂ©lite/boss para efectos mÃƒÂ¡s grandes
	var is_elite = enemy.get("is_elite") if "is_elite" in enemy else false
	var is_boss = enemy.get("archetype") == "boss" if "archetype" in enemy else false
	var size_mult = 1.5 if is_boss else (1.3 if is_elite else 1.0)
	var actual_range = range_dist * size_mult

	var anim_progress = 0.0
	var visual = Node2D.new()
	container.add_child(visual)

	visual.draw.connect(func():
		var current_range = actual_range * anim_progress
		var cone_width = 0.45  # Ancho del cono mÃƒÂ¡s amplio

		if current_range < 5:
			return

		# GLOW EXTERIOR DEL CONO (nuevo)
		for g in range(3):
			var glow_range = current_range * (1.0 + g * 0.08)
			var glow_width = cone_width * (1.0 + g * 0.15)
			var glow_alpha = 0.2 * (1.0 - anim_progress * 0.3) * (1.0 - g * 0.3)
			var glow_points = PackedVector2Array([
				Vector2.ZERO,
				Vector2(glow_range, -glow_range * glow_width),
				Vector2(glow_range * 1.1, 0),
				Vector2(glow_range, glow_range * glow_width)
			])
			visual.draw_colored_polygon(glow_points, Color(base_color.r, base_color.g, base_color.b, glow_alpha))

		# MÃƒÂºltiples capas del cono para efecto de gradiente
		for i in range(6):
			var layer_mult = 1.0 - i * 0.12
			var layer_range = current_range * layer_mult
			var layer_width = cone_width * (1.0 + i * 0.08)
			var layer_alpha = (0.6 - i * 0.08) * (1.0 - anim_progress * 0.25)

			var cone_points = PackedVector2Array([
				Vector2.ZERO,
				Vector2(layer_range, -layer_range * layer_width),
				Vector2(layer_range * 1.1, 0),
				Vector2(layer_range, layer_range * layer_width)
			])
			visual.draw_colored_polygon(cone_points, Color(base_color.r, base_color.g, base_color.b, layer_alpha))

		# NÃƒÂºcleo brillante central - MÃƒÂS INTENSO
		var core_points = PackedVector2Array([
			Vector2.ZERO,
			Vector2(current_range * 0.85, -current_range * cone_width * 0.35),
			Vector2(current_range * 0.9, 0),
			Vector2(current_range * 0.85, current_range * cone_width * 0.35)
		])
		visual.draw_colored_polygon(core_points, Color(bright_color.r, bright_color.g, bright_color.b, 0.85))

		# Centro super brillante
		var inner_core = PackedVector2Array([
			Vector2.ZERO,
			Vector2(current_range * 0.6, -current_range * cone_width * 0.15),
			Vector2(current_range * 0.65, 0),
			Vector2(current_range * 0.6, current_range * cone_width * 0.15)
		])
		visual.draw_colored_polygon(inner_core, Color(1, 1, 1, 0.7 * (1.0 - anim_progress * 0.5)))

		# PartÃƒÂ­culas a lo largo del breath - MÃƒÂS Y MÃƒÂS GRANDES
		var particle_count = int(15 * anim_progress)
		for i in range(particle_count):
			var t = float(i) / max(particle_count, 1)
			var particle_dist = current_range * t
			var wobble = sin(anim_progress * PI * 5 + i * 1.2) * cone_width * particle_dist * 0.35
			var particle_pos = Vector2(particle_dist, wobble)
			var particle_size = (7.0 * (1.0 - t * 0.4)) * size_mult
			visual.draw_circle(particle_pos, particle_size, bright_color)
			# Mini glow
			visual.draw_circle(particle_pos, particle_size * 1.4, Color(bright_color.r, bright_color.g, bright_color.b, 0.3))

		# Borde brillante del cono - MÃƒÂS GRUESO
		visual.draw_line(Vector2.ZERO, Vector2(current_range, -current_range * cone_width), Color(1, 1, 1, 0.7), 3.0)
		visual.draw_line(Vector2.ZERO, Vector2(current_range, current_range * cone_width), Color(1, 1, 1, 0.7), 3.0)

		# Arco frontal del cono (nuevo)
		var arc_radius = current_range * cone_width * 0.3
		visual.draw_arc(Vector2(current_range, 0), arc_radius, -PI/2, PI/2, 12, Color(1, 1, 1, 0.5 * (1.0 - anim_progress)), 2.0)
	)

	# AnimaciÃƒÂ³n de expansiÃƒÂ³n - MÃƒÂS LARGA
	# IMPORTANTE: Usar container.create_tween() para que el tween se limpie con el nodo
	var tween = container.create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.45)  # MÃƒÂ¡s tiempo para la expansiÃƒÂ³n

	# Mantener un momento y fade out suave
	tween.tween_interval(0.25)
	tween.tween_property(container, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func():
		if is_instance_valid(container):
			container.queue_free()
	)

func _get_element_color(elem: String) -> Color:
	"""Obtener color segÃƒÂºn elemento - Colores visibles pero no invasivos"""
	match elem:
		"fire": return Color(1.0, 0.3, 0.05, 0.3)      # Rojo fuego brillante
		"ice": return Color(0.2, 0.7, 1.0, 0.3)        # Azul hielo claro
		"dark": return Color(0.5, 0.2, 0.7, 0.25)      # PÃƒÂºrpura oscuro - alpha bajo
		"arcane": return Color(0.7, 0.3, 0.9, 0.25)    # Magenta arcano - alpha bajo
		"poison": return Color(0.2, 0.9, 0.2, 0.3)     # Verde venenoso
		"lightning": return Color(1.0, 1.0, 0.2, 0.3)  # Amarillo elÃƒÂ©ctrico
		_: return Color(0.9, 0.9, 0.9, 0.3)            # Blanco fÃƒÂ­sico

func _emit_melee_effect() -> void:
	"""Emitir efecto visual de ataque melee Ãƒâ€°PICO con slash animado"""
	if not enemy or not player:
		return

	var direction = (player.global_position - enemy.global_position).normalized()
	var slash_pos = enemy.global_position + direction * 25

	# VFXManager hook - melee slash AOE
	if _try_spawn_via_vfxmanager("melee_slash", "aoe", slash_pos, 30.0, 0.25):
		return

	# Fallback procedural - Crear visual de slash - INDEPENDIENTE del enemigo
	var slash = Node2D.new()
	slash.name = "MeleeSlash"
	slash.top_level = true  # No se mueve con el padre
	slash.z_index = 8  # MUY visible encima de otros elementos
	slash.global_position = slash_pos
	slash.rotation = direction.angle()

	var parent = enemy.get_parent()
	if parent:
		parent.add_child(slash)

	var elem = _get_enemy_element()
	var base_color = _get_element_color(elem)
	var bright_color = Color(min(base_color.r + 0.4, 1.0), min(base_color.g + 0.4, 1.0), min(base_color.b + 0.4, 1.0), 1.0)
	var anim_progress = 0.0

	# Determinar si es ÃƒÂ©lite para efectos mÃƒÂ¡s grandes
	var is_elite = enemy.get("is_elite") if "is_elite" in enemy else false
	var size_mult = 1.5 if is_elite else 1.0

	var visual = Node2D.new()
	slash.add_child(visual)

	visual.draw.connect(func():
		var arc_angle = PI * 0.85  # ÃƒÂngulo del arco de slash mÃƒÂ¡s amplio
		var arc_radius = 45.0 * (0.5 + anim_progress * 0.5) * size_mult
		var arc_start = -arc_angle / 2 + (1.0 - anim_progress) * arc_angle * 0.3
		var arc_end = arc_angle / 2 - (1.0 - anim_progress) * arc_angle * 0.3

		# GLOW EXTERIOR (nuevo)
		for g in range(3):
			var glow_radius = arc_radius * (1.2 + g * 0.15)
			var glow_alpha = 0.2 * (1.0 - anim_progress) * (1.0 - g * 0.25)
			if glow_radius > 0:
				visual.draw_arc(Vector2.ZERO, glow_radius, arc_start, arc_end, 20, Color(base_color.r, base_color.g, base_color.b, glow_alpha), 8.0 - g * 2)

		# MÃƒÂºltiples arcos para efecto de estela - MÃƒÂS GRUESOS
		for i in range(5):
			var layer_radius = arc_radius * (1.0 - i * 0.12)
			var layer_alpha = (1.0 - i * 0.18) * (1.0 - anim_progress * 0.5)
			var layer_width = (8.0 - i * 1.5) * (1.0 - anim_progress * 0.3) * size_mult
			if layer_width > 0:
				visual.draw_arc(Vector2.ZERO, layer_radius, arc_start, arc_end, 20, Color(base_color.r, base_color.g, base_color.b, layer_alpha), layer_width)

		# NÃƒÂºcleo brillante blanco
		visual.draw_arc(Vector2.ZERO, arc_radius * 0.7, arc_start * 0.8, arc_end * 0.8, 16, Color(1, 1, 1, 0.9 * (1.0 - anim_progress)), 4.0 * size_mult)

		# Destello en el borde del slash - MÃƒÂS GRANDE
		var flash_pos = Vector2(cos(arc_end), sin(arc_end)) * arc_radius
		var flash_size = 12.0 * (1.0 - anim_progress) * size_mult
		visual.draw_circle(flash_pos, flash_size, Color(1, 1, 1, 0.95 * (1.0 - anim_progress)))
		visual.draw_circle(flash_pos, flash_size * 0.5, bright_color)

		# Chispas mÃƒÂºltiples que vuelan
		var spark_count = 8
		for i in range(spark_count):
			var spark_angle = arc_start + (arc_end - arc_start) * (float(i) / spark_count)
			var spark_dist = arc_radius * (0.6 + anim_progress * 0.8)
			var spark_pos = Vector2(cos(spark_angle), sin(spark_angle)) * spark_dist
			var spark_size = (4.0 - i * 0.3) * (1.0 - anim_progress) * size_mult
			visual.draw_circle(spark_pos, spark_size, Color(1, 1, 0.7, 0.8 * (1.0 - anim_progress)))

		# LÃƒÂ­neas de energÃƒÂ­a desde el centro (nuevo)
		for i in range(5):
			var line_angle = arc_start + (arc_end - arc_start) * (float(i) / 4)
			var line_end = Vector2(cos(line_angle), sin(line_angle)) * arc_radius * (0.5 + anim_progress * 0.5)
			visual.draw_line(Vector2.ZERO, line_end, Color(bright_color.r, bright_color.g, bright_color.b, 0.5 * (1.0 - anim_progress)), 2.0)
	)

	# AnimaciÃƒÂ³n MÃƒÂS LARGA para ser visible
	# IMPORTANTE: Usar slash.create_tween() para que el tween se limpie con el nodo
	var tween = slash.create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.5)  # 0.5 segundos (antes 0.35)

	tween.tween_callback(func():
		if is_instance_valid(slash):
			slash.queue_free()
	)

func _get_particle_manager() -> Node:
	"""Obtener ParticleManager"""
	var tree = Engine.get_main_loop()
	if tree and tree.root:
		return tree.root.get_node_or_null("ParticleManager")
	return null

func set_attack_enabled(enabled: bool) -> void:
	"""Habilitar/deshabilitar ataques"""
	set_process(enabled)

func reset_cooldown() -> void:
	"""Resetear el cooldown de ataque"""
	attack_timer = attack_cooldown

# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
# FUNCIONES AUXILIARES PARA BOSSES
# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

func _get_enemy_spawner() -> Node:
	"""Obtener referencia al spawner de enemigos"""
	var tree = Engine.get_main_loop()
	if tree and tree.root:
		var game = tree.root.get_node_or_null("Game")
		if game:
			return game.get_node_or_null("EnemySpawner")
	return null

func _apply_knockback_to_player(direction: Vector2, force: float) -> void:
	"""Aplicar knockback/pull al jugador"""
	if player and player.has_method("apply_knockback"):
		player.apply_knockback(direction, force)

func _spawn_boss_projectile_delayed(direction: Vector2, damage: int, element: String, delay: float = 0.0) -> void:
	"""Crear proyectil de boss con delay opcional"""
	if delay > 0:
		get_tree().create_timer(delay).timeout.connect(func():
			_create_boss_projectile_internal(direction, damage, element)
		)
	else:
		_create_boss_projectile_internal(direction, damage, element)

func _create_boss_projectile_internal(direction: Vector2, damage: int, element: String) -> void:
	if not EnemyProjectileScript or not is_instance_valid(enemy):
		return

	var projectile = Area2D.new()
	projectile.set_script(EnemyProjectileScript)
	projectile.global_position = enemy.global_position

	var parent = enemy.get_parent()
	if parent:
		parent.add_child(projectile)

	if projectile.has_method("initialize"):
		projectile.initialize(direction, projectile_speed * 1.2, damage, 5.0, element)

func _spawn_homing_orb(pos: Vector2, damage: int, speed: float, duration: float, element: String) -> void:
	"""Crear orbe Ã‰PICO que persigue al jugador - Usa VFXManager para visual"""
	if not is_instance_valid(enemy) or not is_instance_valid(player):
		return

	var orb = Node2D.new()
	orb.name = "HomingOrb"
	orb.top_level = true
	orb.global_position = pos
	orb.z_index = 5

	# Variables de visual (declaradas a nivel de funciÃ³n para acceso en lambdas)
	var color = _get_element_color(element)
	var bright_color = Color(min(color.r + 0.4, 1.0), min(color.g + 0.4, 1.0), min(color.b + 0.4, 1.0), 1.0)
	var orb_visual: Node2D = null
	var trail_positions: Array = []
	var max_trail = 12
	var orb_time_ref = {"value": 0.0}

	# Intentar usar VFXManager para el visual del orbe
	var vfx_mgr = get_node_or_null("/root/VFXManager")
	var using_vfx = false
	if vfx_mgr and vfx_mgr.has_method("spawn_projectile_attached"):
		# Primero intentar homing_orb, luego el tipo de elemento
		var proj_type = "homing_orb"
		if "ELEMENT_TO_PROJECTILE" in vfx_mgr:
			var elem_type = vfx_mgr.ELEMENT_TO_PROJECTILE.get(element, element)
			# Usar el tipo de elemento si existe en PROJECTILE_CONFIG
			if "PROJECTILE_CONFIG" in vfx_mgr and vfx_mgr.PROJECTILE_CONFIG.has(elem_type):
				proj_type = elem_type
		var sprite = vfx_mgr.spawn_projectile_attached(proj_type, orb)
		if sprite:
			using_vfx = true

	# Visual fallback procedural
	if not using_vfx:
		orb_visual = Node2D.new()
		orb.add_child(orb_visual)

		orb_visual.draw.connect(func():
			var pulse = 1.0 + sin(orb_time_ref.value * 8) * 0.25

			# Dibujar trail
			for i in range(trail_positions.size()):
				var trail_pos = trail_positions[i] - orb.global_position
				var trail_alpha = float(i) / max_trail * 0.5
				var trail_size = 8 * (float(i) / max_trail)
				orb_visual.draw_circle(trail_pos, trail_size, Color(color.r, color.g, color.b, trail_alpha))

			# Glow exterior
			orb_visual.draw_circle(Vector2.ZERO, 35 * pulse, Color(color.r, color.g, color.b, 0.15))
			orb_visual.draw_circle(Vector2.ZERO, 28 * pulse, Color(color.r, color.g, color.b, 0.25))
			orb_visual.draw_circle(Vector2.ZERO, 22 * pulse, Color(color.r, color.g, color.b, 0.4))

			# Cuerpo principal
			orb_visual.draw_circle(Vector2.ZERO, 18 * pulse, color)

			# Anillo de energÃ­a
			var ring_angle = orb_time_ref.value * 5
			orb_visual.draw_arc(Vector2.ZERO, 22 * pulse, ring_angle, ring_angle + PI * 1.5, 16, bright_color, 2.0)

			# NÃºcleo brillante
			orb_visual.draw_circle(Vector2.ZERO, 12 * pulse, bright_color)
			orb_visual.draw_circle(Vector2.ZERO, 6, Color(1, 1, 1, 0.98))

			# PartÃ­culas orbitando
			for i in range(4):
				var orbit_angle = orb_time_ref.value * 6 + (TAU / 4) * i
				var orbit_pos = Vector2(cos(orbit_angle), sin(orbit_angle)) * 25 * pulse
				orb_visual.draw_circle(orbit_pos, 4, bright_color)
		)
		orb_visual.queue_redraw()

	var parent = enemy.get_parent()
	if parent:
		parent.add_child(orb)

	_track_boss_effect(orb)

	# Variables para tracking
	var time_alive_ref = {"value": 0.0}
	var player_ref = player
	var has_hit_ref = {"value": false}
	var hit_radius = 28.0

	# Timer para movimiento
	var timer = Timer.new()
	timer.wait_time = 0.016
	timer.autostart = true
	orb.add_child(timer)

	timer.timeout.connect(func():
		if not is_instance_valid(orb) or has_hit_ref.value:
			return
		if not is_instance_valid(player_ref):
			orb.queue_free()
			return

		time_alive_ref.value += 0.016
		orb_time_ref.value += 0.016

		# Trail
		trail_positions.push_front(orb.global_position)
		if trail_positions.size() > max_trail:
			trail_positions.pop_back()

		# Check duraciÃ³n
		if time_alive_ref.value >= duration:
			var tween = orb.create_tween()
			tween.tween_property(orb, "modulate:a", 0.0, 0.4)
			tween.tween_callback(orb.queue_free)
			return

		# Mover hacia player
		var dir = (player_ref.global_position - orb.global_position).normalized()
		var current_speed = speed * (1.0 + time_alive_ref.value * 0.3)
		orb.global_position += dir * current_speed * 0.016

		# Actualizar visual
		if orb_visual and is_instance_valid(orb_visual):
			orb_visual.queue_redraw()

		# Check colisiÃ³n
		var dist = orb.global_position.distance_to(player_ref.global_position)
		if dist < hit_radius:
			has_hit_ref.value = true
			if player_ref.has_method("take_damage"):
				player_ref.call("take_damage", damage, element, enemy)
			_spawn_orb_impact_effect(orb.global_position, color)
			orb.queue_free()
			return
	)


func _spawn_orb_impact_effect(pos: Vector2, color: Color) -> void:
	"""Crear efecto visual de impacto de orbe Ãƒâ€°PICO"""
	# VFXManager hook - orb impact AOE
	if _try_spawn_via_vfxmanager("orb_impact", "aoe", pos, 45.0, 0.3):
		return

	# Fallback procedural
	var effect = Node2D.new()
	effect.global_position = pos
	effect.top_level = true
	effect.z_index = 5

	if is_instance_valid(enemy):
		var parent = enemy.get_parent()
		if parent:
			parent.add_child(effect)

	var anim_progress = 0.0
	var bright_color = Color(min(color.r + 0.4, 1.0), min(color.g + 0.4, 1.0), min(color.b + 0.4, 1.0), 1.0)

	effect.draw.connect(func():
		var radius = 45 * anim_progress
		var alpha = (1.0 - anim_progress) * 0.9

		# MÃƒÂºltiples ondas de expansiÃƒÂ³n
		for i in range(4):
			var wave_r = radius * (0.4 + i * 0.2)
			var wave_alpha = alpha * (1.0 - i * 0.2)
			effect.draw_circle(Vector2.ZERO, wave_r, Color(color.r, color.g, color.b, wave_alpha * 0.4))

		# Anillos de energÃƒÂ­a
		for i in range(3):
			var ring_r = radius * (0.7 + i * 0.15)
			effect.draw_arc(Vector2.ZERO, ring_r, 0, TAU, 24, Color(bright_color.r, bright_color.g, bright_color.b, alpha * (0.8 - i * 0.2)), 3.0 - i)

		# Rayos de impacto
		var ray_count = 8
		for i in range(ray_count):
			var ray_angle = (TAU / ray_count) * i + anim_progress * PI * 0.5
			var ray_length = radius * 0.9
			var ray_end = Vector2(cos(ray_angle), sin(ray_angle)) * ray_length
			effect.draw_line(Vector2.ZERO, ray_end, Color(1, 1, 1, alpha * 0.7), 2.0)

		# Centro brillante
		var core_size = 15 * (1.0 - anim_progress)
		effect.draw_circle(Vector2.ZERO, core_size, Color(1, 1, 1, alpha))
	)

	var tween = effect.create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(effect):
			effect.queue_redraw()
	, 0.0, 1.0, 0.4)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_damage_zone(pos: Vector2, radius: float, dps: int, duration: float, element: String) -> void:
	"""Crear zona de daÃ±o persistente - Usa VFXManager para visual"""
	if not is_instance_valid(enemy) or not is_instance_valid(player):
		return

	# Determinar tipo de zona segÃºn elemento
	var zone_type: String
	match element:
		"fire":
			zone_type = "fire_zone"       # Zona de fuego pura (aoe_fire_zone)
		"lava":
			zone_type = "damage_zone_fire" # Zona de daÃ±o de lava
		_:
			zone_type = "damage_zone_void"

	# Intentar spawn visual via VFXManager (solo para el efecto visual)
	var vfx_handled = _try_spawn_via_vfxmanager(zone_type, "aoe", pos, radius, duration)

	# Crear zona de daño (lógica de daño siempre se ejecuta)
	var zone = Node2D.new()
	zone.name = "DamageZone"
	zone.global_position = pos

	# Visual fallback SOLO si VFXManager no lo manejó
	if not vfx_handled:
		var visual = Node2D.new()
		zone.add_child(visual)
		var color = _get_element_color(element)
		var anim_time_ref = [0.0]

		visual.draw.connect(func():
			var pulse = 0.8 + sin(anim_time_ref[0] * 4) * 0.2
			visual.draw_circle(Vector2.ZERO, radius * pulse, Color(color.r, color.g, color.b, 0.15))
			visual.draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(color.r, color.g, color.b, 0.3), 2.0)
		)
		visual.queue_redraw()

	var parent = enemy.get_parent()
	if parent:
		parent.add_child(zone)

	# DaÃƒÂ±o por tick
	var player_ref = player
	var time_alive = 0.0
	var damage_accumulator = 0.0

	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.autostart = true
	zone.add_child(timer)

	timer.timeout.connect(func():
		if not is_instance_valid(zone) or not is_instance_valid(player_ref):
			if is_instance_valid(zone):
				zone.queue_free()
			return

		time_alive += 0.1

		if time_alive >= duration:
			zone.queue_free()
			return

		var dist = zone.global_position.distance_to(player_ref.global_position)
		if dist <= radius:
			damage_accumulator += dps * 0.1
			if damage_accumulator >= 1 and player_ref.has_method("take_damage"):
				player_ref.take_damage(int(damage_accumulator), "fire", enemy)
				damage_accumulator = fmod(damage_accumulator, 1.0)
	)

# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â
# EFECTOS VISUALES DE BOSS
# Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â

func _spawn_phase_change_effect() -> void:
	"""Efecto visual de cambio de fase - Usa VFXManager si disponible"""
	if not is_instance_valid(enemy):
		return

	# Intentar VFXManager primero
	if _try_spawn_via_vfxmanager("phase_change", "boss", enemy.global_position, 150.0, 1.0):
		return

	# Fallback: Visual procedural Ã©pico
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 5
	effect.global_position = enemy.global_position

	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)

	var anim = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)

	visual.draw.connect(func():
		# Ondas expansivas (reducidas)
		for i in range(2):
			var r = 100 * anim * (1 + i * 0.3)
			var a = (1.0 - anim) * (0.4 - i * 0.1)
			visual.draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(1, 0.15, 0.15, a), 3.0 - i)

		# Single subtle fill
		var fill_r = 60 * anim
		visual.draw_circle(Vector2.ZERO, fill_r, Color(1, 0.3, 0.1, (1.0 - anim) * 0.08))

		# Rayos desde el centro (reducidos)
		var ray_count = 6
		for i in range(ray_count):
			var angle = (TAU / ray_count) * i + anim * PI * 1.5
			var length = 120 * anim
			var end = Vector2(cos(angle), sin(angle)) * length
			visual.draw_line(Vector2.ZERO, end, Color(1, 0.6, 0.1, (1.0 - anim) * 0.4), 2.0)

		# Centro
		var text_radius = 30 * (1.0 - anim * 0.3)
		visual.draw_circle(Vector2.ZERO, text_radius, Color(1, 0.2, 0.1, (1.0 - anim) * 0.3))
		visual.draw_arc(Vector2.ZERO, text_radius, 0, TAU, 32, Color(1, 1, 0.5, (1.0 - anim) * 0.5), 2.0)

		# Particulas (reducidas)
		var particle_count = 6
		for i in range(particle_count):
			var p_angle = (TAU / particle_count) * i
			var p_dist = 50 * anim + sin(anim * PI * 4 + i) * 15
			var p_pos = Vector2(cos(p_angle), sin(p_angle)) * p_dist
			visual.draw_circle(p_pos, 3 * (1.0 - anim * 0.5), Color(1, 0.8, 0.2, (1.0 - anim) * 0.4))
	)

	# IMPORTANTE: Usar effect.create_tween() para que el tween se limpie con el nodo
	var tween = effect.create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.8)  # MÃƒÂ¡s largo para ser ÃƒÂ©pico
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_summon_visual() -> void:
	"""Efecto de invocacion - Usa VFXManager si disponible"""
	if not is_instance_valid(enemy):
		return

	# Intentar VFXManager primero
	if _try_spawn_via_vfxmanager("summon_circle", "boss", enemy.global_position, 80.0, 1.5):
		return

	# Fallback procedural
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 5
	effect.global_position = enemy.global_position

	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)

	var anim = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)

	visual.draw.connect(func():
		# CÃƒÂ­rculo mÃƒÂ¡gico
		visual.draw_arc(Vector2.ZERO, 80, 0, TAU, 32, Color(0.5, 0, 0.8, 0.6 * (1.0 - anim)), 3.0)
		# PentÃƒÂ¡gono
		var points = 5
		for i in range(points):
			var a1 = (TAU / points) * i - PI/2 + anim * PI
			var a2 = (TAU / points) * ((i + 2) % points) - PI/2 + anim * PI
			var p1 = Vector2(cos(a1), sin(a1)) * 60
			var p2 = Vector2(cos(a2), sin(a2)) * 60
			visual.draw_line(p1, p2, Color(0.8, 0.2, 1, 0.7 * (1.0 - anim)), 2.0)
	)

	# IMPORTANTE: Usar effect.create_tween() para que el tween se limpie con el nodo
	var tween = effect.create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 1.0)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_teleport_effect(pos: Vector2, is_arrival: bool) -> void:
	"""Efecto de teleport"""
	# VFXManager hook - boss teleport VFX
	if _try_spawn_via_vfxmanager("teleport", "boss", pos, 50.0, 0.5):
		return

	# Fallback procedural
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 5
	effect.global_position = pos

	var parent = enemy.get_parent() if is_instance_valid(enemy) else null
	if parent:
		parent.add_child(effect)
	else:
		return

	var anim = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)
	var color = Color(0.5, 0, 1) if not is_arrival else Color(1, 0.5, 0)

	visual.draw.connect(func():
		if is_arrival:
			# ExpansiÃƒÂ³n
			var r = 50 * anim
			visual.draw_circle(Vector2.ZERO, r, Color(color.r, color.g, color.b, 0.5 * (1.0 - anim)))
		else:
			pass  # Bloque else
			# ContracciÃƒÂ³n
			var r = 50 * (1.0 - anim)
			visual.draw_circle(Vector2.ZERO, r, Color(color.r, color.g, color.b, 0.5 * anim))
	)

	# IMPORTANTE: Usar effect.create_tween() para que el tween se limpie con el nodo
	var tween = effect.create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.3)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_arcane_nova_visual(center: Vector2, radius: float) -> void:
	"""Visual de nova arcana - Usa VFXManager si disponible"""
	# Intentar VFXManager primero
	if _try_spawn_via_vfxmanager("arcane_nova", "aoe", center, radius, 0.5):
		return

	# Fallback procedural
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 5
	effect.global_position = center

	var parent = enemy.get_parent() if is_instance_valid(enemy) else null
	if parent:
		parent.add_child(effect)
	else:
		return

	var anim = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)

	visual.draw.connect(func():
		var r = radius * anim
		for i in range(2):
			var layer_r = r * (1.0 - i * 0.2)
			var a = (1.0 - anim) * (0.3 - i * 0.1)
			visual.draw_arc(Vector2.ZERO, layer_r, 0, TAU, 32, Color(0.9, 0.5, 1, a), 1.5)
		# Single subtle fill
		visual.draw_circle(Vector2.ZERO, r * 0.5, Color(0.8, 0.3, 1, (1.0 - anim) * 0.06))
	)

	# IMPORTANTE: Usar effect.create_tween() para que el tween se limpie con el nodo
	var tween = effect.create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.4)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_curse_aura_visual(center: Vector2, radius: float) -> void:
	"""Visual de aura de maldiciÃƒÂ³n"""
	# VFXManager hook - corruption aura
	if is_instance_valid(enemy) and _try_spawn_via_vfxmanager("buff_corruption", "aura", center, radius, 1.5):
		return

	# Fallback procedural
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 5
	effect.global_position = center

	var parent = enemy.get_parent() if is_instance_valid(enemy) else null
	if parent:
		parent.add_child(effect)
	else:
		return

	var anim = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)

	visual.draw.connect(func():
		# Aura oscura pulsante
		var pulse = 0.9 + sin(anim * PI * 4) * 0.1
		visual.draw_circle(Vector2.ZERO, radius * pulse, Color(0.2, 0, 0.2, 0.08 * (1.0 - anim)))
		visual.draw_arc(Vector2.ZERO, radius * pulse, 0, TAU, 32, Color(0.5, 0, 0.5, 0.25 * (1.0 - anim)), 1.5)
		# SÃƒÂ­mbolos de maldiciÃƒÂ³n
		var symbol_count = 6
		for i in range(symbol_count):
			var angle = (TAU / symbol_count) * i + anim * PI * 2
			var pos = Vector2(cos(angle), sin(angle)) * radius * 0.7
			visual.draw_circle(pos, 3, Color(0.5, 0, 0.5, 0.3 * (1.0 - anim)))
	)

	# IMPORTANTE: Usar effect.create_tween() para que el tween se limpie con el nodo
	var tween = effect.create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 1.5)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_void_pull_visual(center: Vector2, radius: float) -> void:
	"""Visual de void pull - Usa VFXManager si disponible"""
	# Intentar VFXManager primero
	if _try_spawn_via_vfxmanager("void_pull", "boss", center, radius, 2.0):
		return

	# Fallback procedural
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 5
	effect.global_position = center

	var parent = enemy.get_parent() if is_instance_valid(enemy) else null
	if parent:
		parent.add_child(effect)
	else:
		return

	var anim = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)

	visual.draw.connect(func():
		# Espirales que se contraen
		var spiral_count = 4
		for s in range(spiral_count):
			var points = PackedVector2Array()
			for i in range(30):
				var t = float(i) / 30.0
				var r = radius * (1.0 - t) * (1.0 - anim * 0.5)
				var angle = t * PI * 4 + (TAU / spiral_count) * s + anim * PI * 2
				points.append(Vector2(cos(angle), sin(angle)) * r)
			if points.size() > 1:
				visual.draw_polyline(points, Color(0.6, 0.1, 0.9, 0.2 * (1.0 - anim)), 1.5)

		# Centro oscuro
		visual.draw_circle(Vector2.ZERO, 15 * (1.0 + anim * 0.5), Color(0.1, 0, 0.2, 0.3 * (1.0 - anim * 0.5)))
	)

	# IMPORTANTE: Usar effect.create_tween() para que el tween se limpie con el nodo
	var tween = effect.create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 2.0)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_void_beam_visual(origin: Vector2, direction: Vector2, length: float, duration: float) -> void:
	"""Visual de void beam"""
	# VFXManager hook - void beam
	var vfx_mgr = get_node_or_null("/root/VFXManager")
	if vfx_mgr and vfx_mgr.has_method("spawn_beam"):
		var beam = vfx_mgr.spawn_beam("void_beam", origin, direction, length, duration)
		if beam:
			return

	# Fallback procedural
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 5
	effect.global_position = origin
	effect.rotation = direction.angle()

	var parent = enemy.get_parent() if is_instance_valid(enemy) else null
	if parent:
		parent.add_child(effect)
	else:
		return

	var anim = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)

	# Usar color del elemento del enemigo en vez de púrpura fijo
	var elem = _get_enemy_element()
	var beam_color = _get_element_color(elem)
	var core_color = Color(min(beam_color.r + 0.3, 1.0), min(beam_color.g + 0.3, 1.0), min(beam_color.b + 0.3, 1.0), 0.9)

	visual.draw.connect(func():
		var width = 30 * (0.8 + sin(anim * PI * 8) * 0.2)
		# Beam principal
		visual.draw_rect(Rect2(0, -width/2, length, width), Color(beam_color.r, beam_color.g, beam_color.b, 0.7))
		# Núcleo brillante
		visual.draw_rect(Rect2(0, -width/4, length, width/2), core_color)
	)

	# IMPORTANTE: Usar effect.create_tween() para que el tween se limpie con el nodo
	var tween = effect.create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, duration)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_rune_shield_visual() -> void:
	"""Visual de escudo de runas - Usa VFXManager si disponible"""
	if not is_instance_valid(enemy):
		return

	# Intentar VFXManager primero
	if _try_spawn_via_vfxmanager("rune_shield", "boss", enemy.global_position, 60.0, 12.0):
		return

	# Fallback: El efecto se adjunta al enemigo
	var visual = Node2D.new()
	visual.name = "RuneShieldVisual"
	enemy.add_child(visual)

	var anim = 0.0

	visual.draw.connect(func():
		# Hexagono de escudo
		var radius = 40
		var points = PackedVector2Array()
		for i in range(7):
			var angle = (TAU / 6) * i + anim * 0.5
			points.append(Vector2(cos(angle), sin(angle)) * radius)
		visual.draw_polyline(points, Color(0.9, 0.8, 0.2, 0.8), 3.0)

		# Runas en cada vÃƒÂ©rtice
		for i in range(6):
			var angle = (TAU / 6) * i + anim * 0.5
			var pos = Vector2(cos(angle), sin(angle)) * radius
			visual.draw_circle(pos, 6, Color(1, 0.9, 0.3, 0.9))
	)

	var timer = Timer.new()
	timer.wait_time = 0.05
	timer.autostart = true
	visual.add_child(timer)

	timer.timeout.connect(func():
		anim += 0.05
		if is_instance_valid(visual):
			visual.queue_redraw()
	)

	# Auto-destruir despuÃƒÂ©s de 10 segundos
	get_tree().create_timer(10.0).timeout.connect(func():
		if is_instance_valid(visual):
			visual.queue_free()
	)

func _spawn_rune_prison_visual(pos: Vector2, duration: float) -> void:
	"""Visual de prision de runas - Usa VFXManager si disponible"""
	# Intentar VFXManager primero
	if _try_spawn_via_vfxmanager("rune_prison", "telegraph", pos, 40.0, duration):
		return

	# Fallback procedural
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 8
	effect.global_position = pos

	var parent = enemy.get_parent() if is_instance_valid(enemy) else null
	if parent:
		parent.add_child(effect)
	else:
		return

	var anim = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)

	visual.draw.connect(func():
		# Jaula de runas
		var radius = 30 + sin(anim * PI * 6) * 5
		# Barras verticales
		for i in range(8):
			var angle = (TAU / 8) * i
			var top = Vector2(cos(angle), sin(angle)) * radius + Vector2(0, -40)
			var bottom = Vector2(cos(angle), sin(angle)) * radius + Vector2(0, 40)
			visual.draw_line(top, bottom, Color(1, 0.8, 0.2, 0.8), 2.0)
		# Anillos
		visual.draw_arc(Vector2(0, -30), radius, 0, TAU, 16, Color(1, 0.9, 0.3, 0.7), 2.0)
		visual.draw_arc(Vector2(0, 30), radius, 0, TAU, 16, Color(1, 0.9, 0.3, 0.7), 2.0)
	)

	# IMPORTANTE: Usar effect.create_tween() para que el tween se limpie con el nodo
	var tween = effect.create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, duration)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_counter_stance_visual() -> void:
	"""Visual de postura de contraataque"""
	if not is_instance_valid(enemy):
		return

	# VFXManager hook - counter stance boss VFX
	if _try_spawn_via_vfxmanager("counter_stance", "boss", enemy.global_position, 35.0, 2.0):
		return

	# Fallback procedural
	var visual = Node2D.new()
	visual.name = "CounterStanceVisual"
	enemy.add_child(visual)

	var anim = 0.0

	visual.draw.connect(func():
		# Aura amenazante
		var pulse = 0.8 + sin(anim * 10) * 0.2
		visual.draw_arc(Vector2.ZERO, 35 * pulse, 0, TAU, 16, Color(1, 0.3, 0.1, 0.6), 3.0)
		# SÃƒÂ­mbolo de espada
		visual.draw_line(Vector2(0, -25), Vector2(0, 15), Color(1, 1, 1, 0.8), 3.0)
		visual.draw_line(Vector2(-10, -10), Vector2(10, -10), Color(1, 1, 1, 0.8), 3.0)
	)

	var timer = Timer.new()
	timer.wait_time = 0.05
	timer.autostart = true
	visual.add_child(timer)

	timer.timeout.connect(func():
		anim += 0.05
		if is_instance_valid(visual):
			visual.queue_redraw()
	)

	# Auto-destruir despuÃƒÂ©s de 2 segundos
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(visual):
			visual.queue_free()
	)

func _spawn_ground_slam_visual(center: Vector2, radius: float) -> void:
	"""Visual de golpe de tierra - Usa VFXManager si disponible"""
	# Intentar VFXManager primero
	if _try_spawn_via_vfxmanager("ground_slam", "aoe", center, radius, 0.5):
		return

	# Fallback procedural
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 5
	effect.global_position = center

	var parent = enemy.get_parent() if is_instance_valid(enemy) else null
	if parent:
		parent.add_child(effect)
	else:
		return

	var anim = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)

	visual.draw.connect(func():
		var expand_radius = radius * 1.2 * anim

		# Ondas de choque - MÃƒÂS Y MÃƒÂS GRUESAS
		for i in range(5):
			var r = expand_radius * (0.3 + i * 0.18)
			var a = (1.0 - anim) * (0.85 - i * 0.14)
			visual.draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(0.65, 0.45, 0.2, a), 6.0 - i)

		# Relleno de tierra
		for i in range(3):
			var fill_r = expand_radius * (0.8 - i * 0.2)
			var fill_a = (1.0 - anim) * (0.35 - i * 0.08)
			visual.draw_circle(Vector2.ZERO, fill_r, Color(0.5, 0.35, 0.15, fill_a))

		# Grietas radiales - MÃƒÂS Y MÃƒÂS DETALLADAS
		var crack_count = 12
		for i in range(crack_count):
			var angle = (TAU / crack_count) * i
			var length = expand_radius * 0.95
			var end = Vector2(cos(angle), sin(angle)) * length

			# Grieta principal
			visual.draw_line(Vector2.ZERO, end, Color(0.25, 0.15, 0.05, (1.0 - anim) * 0.9), 3.0)

			# Sub-grietas
			if i % 2 == 0:
				var sub_start = end * 0.5
				var sub_angle = angle + PI / 8
				var sub_end = sub_start + Vector2(cos(sub_angle), sin(sub_angle)) * length * 0.3
				visual.draw_line(sub_start, sub_end, Color(0.3, 0.2, 0.1, (1.0 - anim) * 0.7), 2.0)

		# Rocas voladoras (nuevo)
		var rock_count = 10
		for i in range(rock_count):
			var rock_angle = (TAU / rock_count) * i + anim * 0.5
			var rock_dist = expand_radius * (0.4 + anim * 0.5)
			var rock_pos = Vector2(cos(rock_angle), sin(rock_angle)) * rock_dist
			rock_pos.y -= anim * 35 * (1.0 + sin(i * 1.3))  # Rocas que vuelan
			var rock_size = (8 - anim * 4) * (0.7 + float(i % 3) * 0.2)

			# Dibujar roca como polÃƒÂ­gono irregular
			var rock_points = PackedVector2Array([
				rock_pos + Vector2(-rock_size, -rock_size * 0.5),
				rock_pos + Vector2(rock_size * 0.3, -rock_size * 0.8),
				rock_pos + Vector2(rock_size, rock_size * 0.2),
				rock_pos + Vector2(-rock_size * 0.2, rock_size * 0.6)
			])
			visual.draw_colored_polygon(rock_points, Color(0.45, 0.35, 0.25, (1.0 - anim) * 0.9))

		# Polvo levantÃƒÂ¡ndose
		var dust_count = 16
		for i in range(dust_count):
			var dust_angle = (TAU / dust_count) * i
			var dust_dist = expand_radius * (0.6 + anim * 0.3)
			var dust_pos = Vector2(cos(dust_angle), sin(dust_angle)) * dust_dist
			dust_pos.y -= anim * 20
			var dust_size = 5 * (1.0 - anim * 0.6)
			visual.draw_circle(dust_pos, dust_size, Color(0.6, 0.5, 0.4, (1.0 - anim) * 0.5))

		# Centro de impacto
		var crater_size = expand_radius * 0.2
		visual.draw_circle(Vector2.ZERO, crater_size, Color(0.2, 0.12, 0.05, (1.0 - anim) * 0.8))
	)

	# IMPORTANTE: Usar effect.create_tween() para que el tween se limpie con el nodo
	var tween = effect.create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.7)  # MÃƒÂ¡s largo
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_charge_warning_visual(pos: Vector2, direction: Vector2) -> void:
	"""Visual de advertencia de carga - Usa VFXManager si disponible"""
	# Intentar VFXManager primero (charge_line telegraph)
	if _try_spawn_via_vfxmanager("charge_line", "telegraph", pos, 100.0, 0.5):
		return

	# Fallback procedural
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 8
	effect.global_position = pos
	effect.rotation = direction.angle()

	var parent = enemy.get_parent() if is_instance_valid(enemy) else null
	if parent:
		parent.add_child(effect)
	else:
		return

	var anim = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)

	visual.draw.connect(func():
		# Flecha indicando direcciÃƒÂ³n
		var flash = (sin(anim * PI * 8) + 1) / 2
		var color = Color(1, 0.3, 0, 0.5 + flash * 0.3)

		# Flecha grande
		var points = PackedVector2Array([
			Vector2(0, 0),
			Vector2(100, -20),
			Vector2(80, 0),
			Vector2(100, 20)
		])
		visual.draw_colored_polygon(points, color)
	)

	# IMPORTANTE: Usar effect.create_tween() para que el tween se limpie con el nodo
	var tween = effect.create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.5)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_flame_breath_visual(origin: Vector2, direction: Vector2, range_dist: float) -> void:
	"""Visual de aliento de fuego - reutiliza el breath existente"""
	_spawn_breath_visual(origin, direction, range_dist)

func _spawn_meteor_warning(pos: Vector2, radius: float, delay: float) -> void:
	"""Visual de advertencia de meteoro - Usa VFXManager si disponible"""
	# Intentar VFXManager primero
	if _try_spawn_via_vfxmanager("meteor_warning", "telegraph", pos, radius, delay):
		return

	# Fallback procedural
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 8
	effect.global_position = pos

	var parent = enemy.get_parent() if is_instance_valid(enemy) else null
	if parent:
		parent.add_child(effect)
	else:
		return

	var anim = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)

	visual.draw.connect(func():
		# CÃƒÂ­rculo de advertencia parpadeante
		var flash = (sin(anim * PI * 6) + 1) / 2
		visual.draw_circle(Vector2.ZERO, radius, Color(1, 0.2, 0, 0.2 + flash * 0.3))
		visual.draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(1, 0.5, 0, 0.5 + flash * 0.4), 2.0)
	)

	# IMPORTANTE: Usar effect.create_tween() para que el tween se limpie con el nodo
	var tween = effect.create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, delay)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_meteor_impact(pos: Vector2, radius: float, damage: int) -> void:
	"""Impacto real del meteoro con daÃƒÂ±o"""
	if not is_instance_valid(player):
		return

	# Verificar daÃƒÂ±o
	var dist = pos.distance_to(player.global_position)
	if dist <= radius:
		if player.has_method("take_damage"):
			player.take_damage(damage, "fire", enemy)
		if player.has_method("apply_burn"):
			player.apply_burn(damage * 0.3, 3.0)

	# VFXManager hook - meteor impact AOE
	if _try_spawn_via_vfxmanager("meteor_impact", "aoe", pos, radius, 0.4):
		return

	# Fallback procedural - Visual de impacto
	var effect = Node2D.new()
	effect.global_position = pos

	var parent = enemy.get_parent() if is_instance_valid(enemy) else null
	if parent:
		parent.add_child(effect)
	else:
		return

	var anim = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)

	visual.draw.connect(func():
		# ExplosiÃƒÂ³n de fuego
		var r = radius * (0.5 + anim * 0.5)
		for i in range(4):
			var layer_r = r * (1.0 - i * 0.2)
			var a = (1.0 - anim) * (0.8 - i * 0.15)
			var color = Color(1.0 - i * 0.1, 0.4 - i * 0.1, 0.05, a)
			visual.draw_circle(Vector2.ZERO, layer_r, color)

		# Centro de impacto
		visual.draw_circle(Vector2.ZERO, r * 0.3, Color(1, 1, 0.5, (1.0 - anim) * 0.9))
	)

	# IMPORTANTE: Usar effect.create_tween() para que el tween se limpie con el nodo
	var tween = effect.create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.4)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_enrage_visual() -> void:
	"""Visual de enrage del boss - Usa VFXManager si disponible"""
	if not is_instance_valid(enemy):
		return

	# Intentar VFXManager primero (aura de enrage)
	if _try_spawn_via_vfxmanager("enrage", "aura", enemy.global_position, 60.0, 3.0):
		return

	# Fallback procedural
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 8
	effect.global_position = enemy.global_position

	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)

	var anim = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)

	visual.draw.connect(func():
		# Aura de furia roja
		for i in range(5):
			var r = 60 + i * 15 + sin(anim * PI * 4 + i) * 10
			var a = (0.6 - i * 0.1) * (1.0 - anim * 0.3)
			visual.draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(1, 0.1, 0, a), 3.0)

		# Llamas alrededor
		var flame_count = 12
		for i in range(flame_count):
			var angle = (TAU / flame_count) * i + anim * PI
			var dist = 50 + sin(anim * PI * 6 + i) * 15
			var pos = Vector2(cos(angle), sin(angle)) * dist
			var size = 8 + sin(anim * PI * 8 + i * 0.5) * 4
			visual.draw_circle(pos, size, Color(1, 0.5, 0, 0.8 * (1.0 - anim * 0.5)))
	)

	# IMPORTANTE: Usar effect.create_tween() para que el tween se limpie con el nodo
	var tween = effect.create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 1.5)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

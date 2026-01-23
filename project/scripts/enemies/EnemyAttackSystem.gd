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
	# CRÃTICO: Respetar la pausa del juego
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	enemy = get_parent()
	# Precargar script de proyectil
	EnemyProjectileScript = load("res://scripts/enemies/EnemyProjectile.gd")
	# print("[EnemyAttackSystem] Inicializado para: %s" % enemy.name)

func initialize(p_attack_cooldown: float, p_attack_range: float, p_damage: int, p_is_ranged: bool = false, p_projectile_scene: PackedScene = null) -> void:
	"""Configurar parÃ¡metros de ataque"""
	attack_cooldown = p_attack_cooldown
	attack_range = p_attack_range
	attack_damage = p_damage
	is_ranged = p_is_ranged
	projectile_scene = p_projectile_scene
	# print("[EnemyAttackSystem] Configurado: cooldown=%.2f, range=%.0f, damage=%d, ranged=%s" % [attack_cooldown, attack_range, attack_damage, is_ranged])

func initialize_full(config: Dictionary) -> void:
	"""InicializaciÃ³n completa con todos los parÃ¡metros"""
	attack_cooldown = config.get("attack_cooldown", 1.5)
	attack_range = config.get("attack_range", 32.0)
	attack_damage = config.get("damage", 5)
	is_ranged = config.get("is_ranged", false)
	archetype = config.get("archetype", "melee")
	element_type = config.get("element_type", "physical")
	special_abilities = config.get("special_abilities", [])
	modifiers = config.get("modifiers", {})
	
	# Configurar segÃºn arquetipo
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
	
	# Mapear lógica legacy a objetos Ability
	if is_ranged or archetype == "ranged" or archetype == "teleporter" or archetype == "boss":
		# Bosses/Ranged/Teleporter usan proyectiles
		var ranged = EnemyAbility_Ranged.new()
		ranged.projectile_speed = projectile_speed
		ranged.projectile_scene = projectile_scene
		ranged.element_type = element_type
		# Configuración específica
		if archetype == "multi":
			ranged.projectile_count = multi_attack_count
			ranged.spread_angle = 15.0
		ability = ranged
		
	elif archetype == "charger":
		# Phase 1: Usar Melee para mantener compatibilidad con EnemyBase movement logic
		# Phase 2: Migrar a EnemyAbility_Dash completo cuando deshabilitemos la lógica en EnemyBase
		var melee = EnemyAbility_Melee.new()
		ability = melee
		
	elif archetype == "melee" or archetype == "tank" or archetype == "agile":
		var melee = EnemyAbility_Melee.new()
		ability = melee
	
	# Si se creó una habilidad, configurarla y añadirla
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

				
			"stomp_attack", "elite_slam":
				extra_ability = EnemyAbility_Aoe.new()
				var cd = modifiers.get("stomp_cooldown", modifiers.get("slam_cooldown", modifiers.get("elite_slam_cooldown", 5.0)))
				extra_ability.cooldown = cd
				extra_ability.radius = modifiers.get("stomp_radius", modifiers.get("slam_radius", modifiers.get("elite_slam_radius", 100.0)))
				
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
	"""Procesar cooldown y ataque automÃ¡tico"""
	if not enemy or not is_instance_valid(enemy):
		return
	
	# Obtener player si no lo tiene
	if not player or not is_instance_valid(player):
		player = _get_player()
		if not player:
			# Solo debug una vez cada 60 frames para no saturar
			if Engine.get_process_frames() % 60 == 0:
				pass  # Debug
			# print("[EnemyAttackSystem] âš ï¸ No se encontrÃ³ player para %s" % enemy.name)
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
		# Comprobar si el jugador estÃ¡ en rango
		if _player_in_range():
			_perform_attack()
			attack_timer = attack_cooldown

func _get_player() -> Node:
	"""Obtener referencia al jugador"""
	# MÃ©todo 1: Desde el enemigo padre (mÃ¡s directo y fiable)
	if enemy and enemy.has_method("get") and enemy.get("player_ref"):
		return enemy.player_ref
	
	# MÃ©todo 2: Buscar en GameManager
	if GameManager and GameManager.player_ref:
		return GameManager.player_ref
	
	# MÃ©todo 3: Buscar por grupos
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	
	# MÃ©todo 4: Buscar en la estructura del Ã¡rbol
	var tree = Engine.get_main_loop()
	if tree and tree.root:
		# Buscar Game/PlayerContainer/SpellloopPlayer
		var sp = tree.root.get_node_or_null("Game/PlayerContainer/SpellloopPlayer")
		if sp:
			return sp
	
	return null

func _player_in_range() -> bool:
	"""Comprobar si el jugador estÃ¡ dentro del rango de ataque"""
	if not enemy or not player:
		return false
	
	var distance = enemy.global_position.distance_to(player.global_position)
	var in_range = distance <= attack_range
	
	# Debug ocasional (cada 2 segundos aprox) para ver distancias
	#if Engine.get_process_frames() % 120 == 0:
	#	print("[EnemyAttackSystem] %s: dist=%.1f, range=%.1f, in_range=%s" % [enemy.name, distance, attack_range, in_range])
	
	return in_range

func _perform_attack() -> void:
	"""Ejecutar el ataque segÃºn arquetipo"""
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
			# En Phase 2, cada habilidad tendrá su propio timer
			if ability.execute(enemy, player, context):
				# Señal de ataque exitoso
				if ability is EnemyAbility_Melee:
					attacked_player.emit(attack_damage, true)
				elif ability is EnemyAbility_Dash:
					pass # Dash maneja su collision
				elif ability is EnemyAbility_Ranged:
					attacked_player.emit(0, false) # Señal genérica para animaciones
		
		return # 🔥 Salir para no ejecutar lógica legacy

	
	# Obtener arquetipo del enemigo padre si existe
	if enemy.has_method("get") and "archetype" in enemy:
		archetype = enemy.archetype
	if enemy.has_method("get") and "modifiers" in enemy:
		modifiers = enemy.modifiers
	if enemy.has_method("get") and "special_abilities" in enemy:
		special_abilities = enemy.special_abilities
	
	# SISTEMA DE HABILIDADES Ã‰LITE - Verificar si es Ã©lite y usar habilidades especiales
	var is_elite = enemy.get("is_elite") if "is_elite" in enemy else false
	if is_elite:
		var elite_ability = _try_elite_ability()
		if elite_ability:
			return  # UsÃ³ una habilidad Ã©lite, no hacer ataque normal
	
	# Ejecutar ataque segÃºn arquetipo
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
			_perform_ranged_attack()  # Los teleporters tambiÃ©n disparan
		"boss":
			# Los bosses usan el sistema agresivo en _process(), aquÃ­ solo disparan
			_perform_ranged_attack()
		_:
			# Melee por defecto
			if is_ranged:
				_perform_ranged_attack()
			else:
				_perform_melee_attack()

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# SISTEMA DE HABILIDADES Ã‰LITE - EXTREMADAMENTE MEJORADO
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

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
	"""Procesar cooldowns de habilidades Ã©lite"""
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
	"""Intentar usar una habilidad Ã©lite. Retorna true si usÃ³ una."""
	var delta = get_process_delta_time()
	_process_elite_cooldowns(delta)
	
	# Verificar rage (se activa automÃ¡ticamente al bajar HP)
	if not elite_rage_active:
		var rage_threshold = modifiers.get("elite_rage_threshold", 0.5)
		var current_hp_percent = _get_enemy_hp_percent()
		if current_hp_percent <= rage_threshold and "elite_rage" in special_abilities:
			_activate_elite_rage()
	
	# Probabilidad de usar habilidad Ã©lite (configurable, default 50%)
	var ability_chance = modifiers.get("elite_ability_chance", 0.50)
	if randf() > ability_chance:
		return false
	
	var dist = enemy.global_position.distance_to(player.global_position)
	
	# PRIORIDAD 1: Dash si el jugador estÃ¡ lejos (mÃ¡s agresivo)
	if "elite_dash" in special_abilities and elite_dash_cooldown <= 0:
		if dist > 100 and dist < 400:  # Entre 100 y 400 unidades
			_perform_elite_dash()
			return true
	
	# PRIORIDAD 2: Nova si hay jugador cerca (defensivo/ofensivo)
	if "elite_nova" in special_abilities and elite_nova_cooldown <= 0:
		if dist < 180:
			_perform_elite_nova()
			return true
	
	# PRIORIDAD 3: Slam si estÃ¡ muy cerca
	if "elite_slam" in special_abilities and elite_slam_cooldown <= 0:
		if dist < 150:
			_perform_elite_slam()
			return true
	
	# PRIORIDAD 4: Summon si el jugador estÃ¡ a distancia media
	if "elite_summon" in special_abilities and elite_summon_cooldown <= 0:
		if dist > 80 and dist < 300:
			_perform_elite_summon()
			return true
	
	# PRIORIDAD 5: Activar escudo si estÃ¡ bajo de vida
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
	"""Habilidad Ã©lite: Slam de Ã¡rea"""
	var slam_radius = modifiers.get("elite_slam_radius", 80.0)
	var slam_damage_mult = modifiers.get("elite_slam_damage_mult", 1.5)
	var slam_damage = int(attack_damage * slam_damage_mult)
	
	# Aplicar daÃ±o si el player estÃ¡ en rango
	var dist = enemy.global_position.distance_to(player.global_position)
	if dist <= slam_radius:
		if player.has_method("take_damage"):
			player.take_damage(slam_damage, "physical", enemy)
			attacked_player.emit(slam_damage, false)
		if player.has_method("apply_stun"):
			player.apply_stun(0.4)
	
	# Visual Ã©pico
	_spawn_elite_slam_visual(enemy.global_position, slam_radius)
	
	# Aplicar cooldown
	elite_slam_cooldown = modifiers.get("elite_slam_cooldown", 5.0)
	# print("[Elite] ðŸ‘‘ðŸ’¥ %s usÃ³ Elite Slam! (daÃ±o: %d, radio: %.0f)" % [enemy.name, slam_damage, slam_radius])

func _activate_elite_rage() -> void:
	"""Activar modo rage de Ã©lite"""
	elite_rage_active = true
	
	var damage_bonus = modifiers.get("elite_rage_damage_bonus", 0.5)
	var speed_bonus = modifiers.get("elite_rage_speed_bonus", 0.3)
	
	# Aplicar buffs
	attack_damage = int(attack_damage * (1 + damage_bonus))
	if "base_speed" in enemy:
		enemy.base_speed *= (1 + speed_bonus)
	
	# Visual Ã©pico
	_spawn_elite_rage_visual()
	# print("[Elite] ðŸ‘‘ðŸ”¥ %s entrÃ³ en RAGE! (+%.0f%% daÃ±o, +%.0f%% velocidad)" % [enemy.name, damage_bonus * 100, speed_bonus * 100])

func _activate_elite_shield() -> void:
	"""Activar escudo Ã©lite"""
	elite_shield_charges = modifiers.get("elite_shield_charges", 3)
	elite_shield_cooldown = modifiers.get("elite_shield_cooldown", 15.0)
	
	# Visual de escudo
	_spawn_elite_shield_visual()
	# print("[Elite] ðŸ‘‘ðŸ›¡ï¸ %s activÃ³ Elite Shield! (%d cargas)" % [enemy.name, elite_shield_charges])

func _spawn_elite_slam_visual(center: Vector2, radius: float) -> void:
	"""Visual ÉPICO de slam élite (Mejorado)"""
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 65
	effect.global_position = center
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)
	
	var anim = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)
	
	# Colores más intensos
	var gold = Color(1.0, 0.8, 0.0)
	var red = Color(1.0, 0.2, 0.1)
	var bright = Color(1.0, 0.95, 0.6)
	
	visual.draw.connect(func():
		var expand = radius * 1.35 * anim
		
		# Ondas de choque múltiples
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
	, 0.0, 1.0, 0.5) # Más rápido: 0.5s
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_elite_rage_visual() -> void:
	"""Visual ÉPICO de rage élite (Mejorado)"""
	if not is_instance_valid(enemy):
		return
	
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 65
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
		
		# Símbolo de calavera/rage simplificado
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
	"""Visual de escudo Ã©lite"""
	if not is_instance_valid(enemy):
		return
	
	# El efecto se adjunta al enemigo
	var visual = Node2D.new()
	visual.name = "EliteShieldVisual"
	enemy.add_child(visual)
	
	var anim = 0.0
	var gold = Color(1.0, 0.85, 0.1)
	
	visual.draw.connect(func():
		# HexÃ¡gono de escudo dorado
		var radius = 50
		var pulse = 1.0 + sin(anim * 8) * 0.1
		var points = PackedVector2Array()
		for i in range(7):
			var angle = (TAU / 6) * i + anim * 0.8
			points.append(Vector2(cos(angle), sin(angle)) * radius * pulse)
		visual.draw_polyline(points, Color(gold.r, gold.g, gold.b, 0.9), 4.0)
		
		# Relleno semi-transparente
		visual.draw_circle(Vector2.ZERO, radius * 0.85 * pulse, Color(gold.r, gold.g, gold.b, 0.15))
		
		# Runas en cada vÃ©rtice
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
	
	# Auto-destruir despuÃ©s de 12 segundos (duraciÃ³n del escudo)
	get_tree().create_timer(12.0).timeout.connect(func():
		if is_instance_valid(visual):
			visual.queue_free()
	)

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# NUEVAS HABILIDADES Ã‰LITE - DASH, NOVA, SUMMON
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _perform_elite_dash() -> void:
	"""Habilidad Ã©lite: Dash/embestida hacia el jugador"""
	if not is_instance_valid(enemy) or not is_instance_valid(player):
		return
	
	var _dash_speed = modifiers.get("elite_dash_speed", 600.0)
	var dash_damage_mult = modifiers.get("elite_dash_damage_mult", 1.8)
	var dash_damage = int(attack_damage * dash_damage_mult)
	
	elite_is_dashing = true
	elite_dash_target = player.global_position
	
	# Visual de preparaciÃ³n
	_spawn_elite_dash_visual_start()
	
	# DespuÃ©s de 0.3s de "wind-up", ejecutar dash
	get_tree().create_timer(0.3).timeout.connect(func():
		if not is_instance_valid(enemy) or not is_instance_valid(player):
			elite_is_dashing = false
			return
		
		# Calcular direcciÃ³n y posiciÃ³n final
		var direction = (elite_dash_target - enemy.global_position).normalized()
		var dash_distance = min(400.0, enemy.global_position.distance_to(elite_dash_target) + 50)
		var final_pos = enemy.global_position + direction * dash_distance
		
		# Crear tween para el movimiento
		var tween = enemy.create_tween()
		tween.tween_property(enemy, "global_position", final_pos, 0.25).set_ease(Tween.EASE_IN_OUT)
		
		# Spawn visual de estela
		_spawn_elite_dash_trail(enemy.global_position, final_pos)
		
		# Verificar colisiÃ³n con el jugador durante el dash
		tween.finished.connect(func():
			elite_is_dashing = false
			if is_instance_valid(player):
				var dist = enemy.global_position.distance_to(player.global_position)
				if dist < 60:  # ImpactÃ³
					if player.has_method("take_damage"):
						var elem = _get_enemy_element()
						player.call("take_damage", dash_damage, elem, enemy)
						attacked_player.emit(dash_damage, true)
						# print("[Elite] ðŸ‘‘ðŸ’¨ %s DASH IMPACTO! %d daÃ±o" % [enemy.name, dash_damage])
					if player.has_method("apply_knockback"):
						player.apply_knockback(direction * 200)
		)
	)
	
	elite_dash_cooldown = modifiers.get("elite_dash_cooldown", 3.0)
	# print("[Elite] ðŸ‘‘ðŸ’¨ %s prepara DASH hacia el jugador!" % enemy.name)

func _spawn_elite_dash_visual_start() -> void:
	"""Visual de preparaciÃ³n de dash"""
	if not is_instance_valid(enemy):
		return
	
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 60
	effect.global_position = enemy.global_position
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)
	
	var anim = 0.0
	var gold = Color(1.0, 0.85, 0.1)
	var visual = Node2D.new()
	effect.add_child(visual)
	
	visual.draw.connect(func():
		# CÃ­rculo de carga creciente
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
	effect.z_index = 55
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
		
		# PartÃ­culas de chispa
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
	"""Habilidad Ã©lite: ExplosiÃ³n de proyectiles en cÃ­rculo"""
	if not is_instance_valid(enemy):
		return
	
	var projectile_count = modifiers.get("elite_nova_projectile_count", 12)
	var nova_damage_mult = modifiers.get("elite_nova_damage_mult", 0.8)
	var nova_damage = int(attack_damage * nova_damage_mult)
	
	# Visual de carga
	_spawn_elite_nova_visual(enemy.global_position)
	
	# DespuÃ©s de 0.4s, disparar todos los proyectiles
	get_tree().create_timer(0.4).timeout.connect(func():
		if not is_instance_valid(enemy):
			return
		
		for i in range(projectile_count):
			var angle = (TAU / projectile_count) * i
			var direction = Vector2(cos(angle), sin(angle))
			_spawn_elite_nova_projectile(enemy.global_position, direction, nova_damage)
		
		# print("[Elite] ðŸ‘‘ðŸ’« %s dispara NOVA! %d proyectiles" % [enemy.name, projectile_count])
	)
	
	elite_nova_cooldown = modifiers.get("elite_nova_cooldown", 6.0)

func _spawn_elite_nova_visual(center: Vector2) -> void:
	"""Visual de carga de nova"""
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 65
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
	"""Crear un proyectil de la nova Ã©lite"""
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
			
			# Visual dorado especial
			var sprite = projectile.get_node_or_null("Sprite2D")
			if sprite:
				sprite.modulate = Color(1.0, 0.85, 0.1)

func _perform_elite_summon() -> void:
	"""Habilidad Ã©lite: Invocar minions temporales"""
	if not is_instance_valid(enemy):
		return
	
	var summon_count = modifiers.get("elite_summon_count", 3)
	
	# Visual de invocaciÃ³n
	_spawn_elite_summon_visual(enemy.global_position)
	
	# DespuÃ©s de 0.5s, spawner los minions
	get_tree().create_timer(0.5).timeout.connect(func():
		if not is_instance_valid(enemy):
			return
		
		# Buscar el EnemyManager
		var enemy_manager = _find_enemy_manager()
		if not enemy_manager:
			# print("[Elite] âš ï¸ No se encontrÃ³ EnemyManager para summon")
			return
		
		for i in range(summon_count):
			var angle = (TAU / summon_count) * i
			var offset = Vector2(cos(angle), sin(angle)) * 60
			var spawn_pos = enemy.global_position + offset
			
			# Spawner un minion tier 1 temporal
			if enemy_manager.has_method("spawn_specific_enemy"):
				var minion = enemy_manager.spawn_specific_enemy("tier_1_slime_arcano", spawn_pos)
				if minion:
					# Hacer el minion temporal (se destruye despuÃ©s de 8 segundos)
					minion.modulate = Color(1.0, 0.85, 0.1, 0.8)  # Tinte dorado
					get_tree().create_timer(8.0).timeout.connect(func():
						if is_instance_valid(minion):
							minion.queue_free()
					)
		
		# print("[Elite] ðŸ‘‘ðŸ‘¥ %s invocÃ³ %d minions!" % [enemy.name, summon_count])
	)
	
	elite_summon_cooldown = modifiers.get("elite_summon_cooldown", 10.0)

func _spawn_elite_summon_visual(center: Vector2) -> void:
	"""Visual de invocaciÃ³n Ã©lite"""
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 60
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
		# CÃ­rculo mÃ¡gico
		var radius = 70
		visual.draw_arc(Vector2.ZERO, radius, 0, TAU * anim, 48, gold, 3.0)
		visual.draw_arc(Vector2.ZERO, radius * 0.7, 0, TAU * anim, 36, purple, 2.0)
		
		# Runas girando
		var rune_count = 6
		for i in range(rune_count):
			var angle = (TAU / rune_count) * i + anim * PI * 2
			var pos = Vector2(cos(angle), sin(angle)) * radius * 0.85
			visual.draw_circle(pos, 8, Color(gold.r, gold.g, gold.b, anim))
			
		# PentÃ¡culo central
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
	"""Buscar el EnemyManager en el Ã¡rbol"""
	# MÃ©todo 1: GameManager
	if GameManager and GameManager.has_method("get") and "enemy_manager" in GameManager:
		return GameManager.enemy_manager
	
	# MÃ©todo 2: Buscar en el Ã¡rbol
	var tree = Engine.get_main_loop()
	if tree and tree.root:
		var em = tree.root.get_node_or_null("Game/EnemyManager")
		if em:
			return em
	
	# MÃ©todo 3: Buscar por clase
	var nodes = get_tree().get_nodes_in_group("enemy_managers")
	if nodes.size() > 0:
		return nodes[0]
	
	return null

func _perform_melee_attack() -> void:
	"""Ataque melee: daÃ±o directo al jugador"""
	if not player.has_method("take_damage"):
		return
	
	var elem = _get_enemy_element()
	# Pasar referencia del enemigo para sistema de thorns
	player.call("take_damage", attack_damage, elem, enemy)
	# print("[EnemyAttackSystem] âš”ï¸ %s atacÃ³ melee a player por %d daÃ±o (%s)" % [enemy.name, attack_damage, elem])
	
	# Aplicar efectos segÃºn arquetipo y elemento
	_apply_melee_effects()
	
	# Emitir seÃ±al
	attacked_player.emit(attack_damage, true)
	
	# Efecto visual removido - el feedback ahora es vÃ­a DamageVignette
	# _emit_melee_effect()

func _apply_melee_effects() -> void:
	"""Aplicar efectos de estado segÃºn arquetipo y elemento"""
	var elem = _get_enemy_element()
	
	# Efectos por arquetipo
	match archetype:
		"debuffer":  # AraÃ±a Venenosa
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
				player.apply_curse(0.3, 4.0)  # -30% curaciÃ³n por 4s
		"charger":  # Caballero del VacÃ­o - stun en carga
			# El stun se aplica en el ataque de carga, no en melee normal
			pass
	
	# Efectos por elemento
	match elem:
		"fire":
			if player.has_method("apply_burn"):
				player.apply_burn(3.0, 2.0)  # 3 daÃ±o/tick por 2s
		"ice":
			if player.has_method("apply_slow"):
				player.apply_slow(0.25, 2.0)  # 25% slow por 2s
		"dark", "void":
			if player.has_method("apply_weakness"):
				player.apply_weakness(0.2, 3.0)  # +20% daÃ±o recibido por 3s
		"poison":
			if player.has_method("apply_poison"):
				player.apply_poison(2.0, 4.0)

func _perform_ranged_attack() -> void:
	"""Ataque ranged: disparar proyectil al jugador"""
	# Crear proyectil dinÃ¡micamente si no hay escena
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
	
	# Calcular direcciÃ³n hacia jugador
	var direction = (player.global_position - enemy.global_position).normalized()
	
	# Configurar proyectil
	if projectile.has_method("initialize"):
		projectile.initialize(direction, projectile_speed, attack_damage, 5.0, element_type)
	else:
		pass  # Bloque else
		# AsignaciÃ³n directa
		if "direction" in projectile:
			projectile.direction = direction
		if "speed" in projectile:
			projectile.speed = projectile_speed
		if "damage" in projectile:
			projectile.damage = attack_damage
	
	# AÃ±adir al Ã¡rbol
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(projectile)
	else:
		get_tree().root.add_child(projectile)
	
	# print("[EnemyAttackSystem] ðŸŽ¯ %s disparÃ³ proyectil hacia player" % enemy.name)
	attacked_player.emit(attack_damage, false)

func _create_dynamic_projectile() -> void:
	"""Crear proyectil dinÃ¡mico usando EnemyProjectile.gd"""
	var projectile = Area2D.new()
	projectile.set_script(EnemyProjectileScript)
	projectile.global_position = enemy.global_position
	
	var direction = (player.global_position - enemy.global_position).normalized()
	
	# Determinar elemento segÃºn enemigo
	var elem = _get_enemy_element()
	
	# AÃ±adir al Ã¡rbol ANTES de initialize (necesario para _ready)
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(projectile)
	else:
		get_tree().root.add_child(projectile)
	
	# Inicializar
	if projectile.has_method("initialize"):
		projectile.initialize(direction, projectile_speed, attack_damage, 5.0, elem)
	
	# print("[EnemyAttackSystem] ðŸŽ¯ %s disparÃ³ proyectil dinÃ¡mico (%s)" % [enemy.name, elem])
	attacked_player.emit(attack_damage, false)

func _perform_aoe_attack() -> void:
	"""Ataque de Ã¡rea: daÃ±o en zona alrededor del enemigo o player"""
	if not player:
		return
	
	# PosiciÃ³n del AoE (en el player o en el enemigo)
	var aoe_center = player.global_position
	var radius = modifiers.get("aoe_radius", 100.0)
	var aoe_damage = int(attack_damage * modifiers.get("aoe_damage_mult", 1.0))
	var elem = _get_enemy_element()
	
	# Verificar si player estÃ¡ en rango del AoE
	var dist_to_player = aoe_center.distance_to(player.global_position)
	if dist_to_player <= radius:
		if player.has_method("take_damage"):
			player.call("take_damage", aoe_damage, elem)
			# print("[EnemyAttackSystem] ðŸ’¥ %s AoE hit player por %d daÃ±o (%s, radio=%.0f)" % [enemy.name, aoe_damage, elem, radius])
			attacked_player.emit(aoe_damage, false)
			# Aplicar efectos segÃºn elemento del AoE
			_apply_aoe_effects()
	
	# Efecto visual del AoE
	_spawn_aoe_visual(enemy.global_position, radius)

func _apply_aoe_effects() -> void:
	"""Aplicar efectos de estado en ataques AoE"""
	var elem = _get_enemy_element()
	
	# SeÃ±or de las Llamas - Burn
	if elem == "fire":
		if player.has_method("apply_burn"):
			player.apply_burn(5.0, 3.0)  # 5 daÃ±o/tick por 3s
			# print("[EnemyAttackSystem] ðŸ”¥ AoE aplica Burn!")
	# Reina del Hielo - Slow/Freeze
	elif elem == "ice":
		if player.has_method("apply_slow"):
			player.apply_slow(0.4, 3.0)  # 40% slow por 3s
			# print("[EnemyAttackSystem] â„ï¸ AoE aplica Slow!")
	# TitÃ¡n Arcano - Stun
	elif "arcane" in enemy.name.to_lower() or "titan" in enemy.name.to_lower():
		if player.has_method("apply_stun"):
			player.apply_stun(0.5)  # 0.5s stun
			# print("[EnemyAttackSystem] âš¡ AoE aplica Stun!")

func _perform_breath_attack() -> void:
	"""Ataque de aliento: daÃ±o en cono hacia el player"""
	if not player:
		return
	
	var direction = (player.global_position - enemy.global_position).normalized()
	var cone_angle = deg_to_rad(modifiers.get("breath_angle", 45.0))
	var cone_range = modifiers.get("breath_range", 150.0)
	var breath_damage = int(attack_damage * modifiers.get("breath_damage_mult", 1.2))
	
	# Verificar si player estÃ¡ en el cono
	var to_player = player.global_position - enemy.global_position
	var dist = to_player.length()
	var angle_to_player = direction.angle_to(to_player.normalized())
	
	if dist <= cone_range and abs(angle_to_player) <= cone_angle / 2:
		if player.has_method("take_damage"):
			player.take_damage(breath_damage, "fire", enemy)
			# print("[EnemyAttackSystem] ðŸ‰ %s Breath hit player por %d daÃ±o" % [enemy.name, breath_damage])
			attacked_player.emit(breath_damage, false)
			# Aplicar efectos de breath
			_apply_breath_effects()
	
	# Efecto visual del breath
	_spawn_breath_visual(enemy.global_position, direction, cone_range)

func _apply_breath_effects() -> void:
	"""Aplicar efectos del ataque breath"""
	var _elem = _get_enemy_element()
	
	# DragÃ³n EtÃ©reo es de tipo 'fire' o 'etereo'
	# Aplicar burn siempre en breath de dragÃ³n
	if player.has_method("apply_burn"):
		player.apply_burn(6.0, 2.5)  # 6 daÃ±o/tick por 2.5s
		# print("[EnemyAttackSystem] ðŸ”¥ Breath aplica Burn!")

func _perform_multi_attack() -> void:
	"""Ataque mÃºltiple: varios proyectiles o ataques en secuencia"""
	var count = modifiers.get("attack_count", 3)
	var spread_angle = deg_to_rad(modifiers.get("spread_angle", 30.0))
	var base_direction = (player.global_position - enemy.global_position).normalized()
	
	for i in range(count):
		# Calcular Ã¡ngulo para este proyectil
		var angle_offset = spread_angle * (float(i) / float(count - 1) - 0.5) if count > 1 else 0.0
		var direction = base_direction.rotated(angle_offset)
		
		# Crear proyectil con delay visual
		_spawn_multi_projectile(direction, i * 0.1)
	
	# print("[EnemyAttackSystem] ðŸ”¥ %s Multi-attack: %d proyectiles" % [enemy.name, count])
	attacked_player.emit(attack_damage, false)

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# SISTEMA DE BOSS COMPLETO - ESTILO BINDING OF ISAAC
# Ataques constantes, AOE aleatorios, proyectiles perseguidores, orbitales
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

# Tracking de cooldowns de habilidades de boss (por enemigo)
var boss_ability_cooldowns: Dictionary = {}  # {ability_name: tiempo_restante}
var boss_current_phase: int = 1
var boss_enraged: bool = false
var boss_fire_trail_active: bool = false
var boss_damage_aura_timer: float = 0.0

# Sistema de habilidades limitadas por minuto
var boss_scaling_config: Dictionary = {}     # ConfiguraciÃ³n de escalado del minuto
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
	# print("[Boss] ðŸ§¹ Limpiando orbitales y efectos del boss...")
	
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
	
	# Limpiar tambiÃ©n cualquier homing orb del boss en la escena
	var tree = get_tree()
	if tree:
		for node in tree.get_nodes_in_group("boss_effects"):
			if is_instance_valid(node):
				node.queue_free()
	
	is_boss_enemy = false
	# print("[Boss] ðŸ§¹ Limpieza completada")

func _track_boss_effect(effect: Node) -> void:
	"""AÃ±adir un efecto a la lista de tracking para limpieza posterior"""
	if effect and is_instance_valid(effect):
		boss_active_effects.append(effect)
		effect.add_to_group("boss_effects")

func _init_boss_aggressive_mode() -> void:
	"""Inicializar modo agresivo del boss - estilo Binding of Isaac"""
	_init_boss_system()
	
	# Spawn orbitales iniciales
	var orbital_count = boss_scaling_config.get("orbital_count", 2)
	_spawn_boss_orbitals(orbital_count)
	
	# print("[Boss] ðŸ‘¹ðŸ”¥ MODO AGRESIVO ACTIVADO - Orbitales: %d" % orbital_count)

func _process_boss_aggressive_attacks(delta: float) -> void:
	"""Procesar ataques constantes del boss - NO depende del rango"""
	if not enemy or not player or not is_instance_valid(enemy) or not is_instance_valid(player):
		return
	
	# Inicializar si es necesario
	if boss_scaling_config.is_empty():
		_init_boss_system()
	
	# Actualizar fase segÃºn HP
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
	
	# 3. Proyectiles homing (solo si estÃ¡ habilitado en la config)
	var enable_homing = boss_scaling_config.get("enable_homing", false)
	if enable_homing:
		boss_homing_projectile_timer -= delta
		if boss_homing_projectile_timer <= 0:
			_boss_spawn_homing_projectile()
			var homing_interval = boss_scaling_config.get("homing_interval", 6.0)
			boss_homing_projectile_timer = homing_interval * (0.7 if boss_current_phase >= 2 else 1.0)
	
	# 4. Spread shot (solo si estÃ¡ habilitado en la config)
	var enable_spread = boss_scaling_config.get("enable_spread", false)
	if enable_spread:
		boss_spread_shot_timer -= delta
		if boss_spread_shot_timer <= 0:
			_boss_spread_shot()
			var spread_interval = boss_scaling_config.get("spread_interval", 8.0)
			boss_spread_shot_timer = spread_interval * (0.6 if boss_current_phase >= 3 else 1.0)
	
	# 5. Trail de daÃ±o solo en fase 2+ (para todos los bosses)
	if boss_current_phase >= 2:
		boss_trail_timer -= delta
		if boss_trail_timer <= 0:
			_boss_leave_damage_trail()
			boss_trail_timer = 0.4
	
	# 6. Habilidades especiales del boss (sistema original mejorado)
	_process_boss_special_abilities(delta)

func _boss_fire_at_player() -> void:
	"""Disparar proyectil directo al jugador"""
	if not is_instance_valid(player) or not is_instance_valid(enemy):
		return
	
	var direction = (player.global_position - enemy.global_position).normalized()
	var damage = int(attack_damage * 0.5)  # Proyectiles hacen 50% del daÃ±o base
	
	_spawn_boss_projectile(enemy.global_position, direction, damage, 220.0)  # Reducido de 350 a 220

func _boss_spawn_random_aoe() -> void:
	"""Spawn un AOE en posiciÃ³n aleatoria cerca del jugador"""
	if not is_instance_valid(player):
		return
	
	# PosiciÃ³n aleatoria dentro de un radio del jugador
	var offset = Vector2(randf_range(-200, 200), randf_range(-200, 200))
	var target_pos = player.global_position + offset
	
	# Warning visual antes del impacto - AUMENTADO para dar tiempo de reacción
	_spawn_aoe_warning(target_pos, 80.0, 1.8)  # Aumentado de 1.0 a 1.8s
	
	# DespuÃ©s del warning, hacer daÃ±o
	get_tree().create_timer(1.8).timeout.connect(func():
		if is_instance_valid(player):
			var dist = target_pos.distance_to(player.global_position)
			if dist < 80:
				var damage = int(attack_damage * 0.7)
				if player.has_method("take_damage"):
					var elem = _get_enemy_element()
					player.call("take_damage", damage, elem)
					# print("[Boss] ðŸ’¥ AOE RANDOM impactÃ³! %d daÃ±o" % damage)
		# Visual de explosiÃ³n
		_spawn_aoe_explosion(target_pos, 80.0)
	)

func _boss_spawn_homing_projectile() -> void:
	"""Spawn proyectil que persigue al jugador"""
	if not is_instance_valid(player) or not is_instance_valid(enemy):
		return
	
	var count = 1 + boss_current_phase  # MÃ¡s proyectiles en fases avanzadas
	
	for i in range(count):
		var angle_offset = (TAU / count) * i
		var spawn_offset = Vector2(cos(angle_offset), sin(angle_offset)) * 50
		var spawn_pos = enemy.global_position + spawn_offset
		
		_create_homing_projectile(spawn_pos)
	
	# print("[Boss] ðŸŽ¯ %d proyectiles HOMING lanzados!" % count)

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
	
	# Visual
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
	
	# Comportamiento homing
	var lifetime = 6.0
	var speed = 120.0  # Reducido de 180 a 120 (jugador va a 100)
	var homing_strength = 1.8  # Reducido de 2.5 a 1.8 (más esquivable)
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
		
		if not is_instance_valid(player):
			projectile.queue_free()
			return
		
		# Movimiento homing
		var target_dir = (player.global_position - projectile.global_position).normalized()
		var current_dir = Vector2.RIGHT.rotated(projectile.rotation)
		var new_dir = current_dir.lerp(target_dir, homing_strength * 0.016)
		
		projectile.rotation = new_dir.angle()
		projectile.global_position += new_dir * speed * 0.016
		
		# Check colisiÃ³n manual
		var dist = projectile.global_position.distance_to(player.global_position)
		if dist < 20:
			hit = true
			if player.has_method("take_damage"):
				var elem_type = _get_enemy_element()
				player.call("take_damage", damage, elem_type)
			projectile.queue_free()
	)

func _boss_spread_shot() -> void:
	"""RÃ¡faga de proyectiles en abanico"""
	if not is_instance_valid(player) or not is_instance_valid(enemy):
		return
	
	var count = 5 + boss_current_phase * 2  # MÃ¡s proyectiles en fases avanzadas
	var spread_angle = PI * 0.6  # 108 grados
	var base_direction = (player.global_position - enemy.global_position).normalized()
	var damage = int(attack_damage * 0.35)
	
	for i in range(count):
		var angle_offset = spread_angle * (float(i) / float(count - 1) - 0.5)
		var direction = base_direction.rotated(angle_offset)
		_spawn_boss_projectile(enemy.global_position, direction, damage, 280.0)
	
	# print("[Boss] ðŸ”¥ SPREAD SHOT: %d proyectiles!" % count)

func _boss_leave_damage_trail() -> void:
	"""Dejar trail de daÃ±o donde pasa el boss"""
	if not is_instance_valid(enemy):
		return
	
	var trail_pos = enemy.global_position
	var elem = _get_enemy_element()
	var color = _get_element_color(elem)
	
	# Crear zona de daÃ±o temporal
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
	
	# DaÃ±o y fade out
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
					player.call("take_damage", trail_damage, elem)
				damage_cooldown = 0.5
	)

func _spawn_boss_orbitals(count: int) -> void:
	"""Crear orbitales que giran alrededor del boss"""
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
		
		# Visual
		var visual = Node2D.new()
		orbital.add_child(visual)
		
		visual.draw.connect(func():
			visual.draw_circle(Vector2.ZERO, 18, Color(color.r, color.g, color.b, 0.4))
			visual.draw_circle(Vector2.ZERO, 12, color)
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
	"""Actualizar posiciÃ³n y daÃ±o de orbitales"""
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
		
		# Check daÃ±o al jugador
		if is_instance_valid(player):
			var dist = orbital.global_position.distance_to(player.global_position)
			var cd = orbital.get_meta("damage_cooldown") - delta
			orbital.set_meta("damage_cooldown", max(0, cd))
			
			if dist < 25 and cd <= 0:
				var damage = orbital.get_meta("damage")
				if player.has_method("take_damage"):
					var elem = _get_enemy_element()
					player.call("take_damage", damage, elem)
				orbital.set_meta("damage_cooldown", 0.8)

func _spawn_aoe_warning(pos: Vector2, radius: float, duration: float) -> void:
	"""Mostrar warning de AOE antes del impacto"""
	var warning = Node2D.new()
	warning.name = "AOEWarning"
	warning.top_level = true
	warning.z_index = 50
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
		# CÃ­rculo pulsante
		var pulse = 0.5 + sin(anim * PI * 4) * 0.2
		warning.draw_arc(Vector2.ZERO, radius * pulse, 0, TAU, 32, Color(color.r, color.g, color.b, 0.5), 3.0)
		warning.draw_arc(Vector2.ZERO, radius * 0.7 * pulse, 0, TAU, 24, Color(1, 0.3, 0.3, 0.6), 2.0)
		# SÃ­mbolo de peligro
		warning.draw_circle(Vector2.ZERO, 10, Color(1, 0.2, 0.2, 0.8 * (1.0 - anim)))
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
	"""Visual de explosiÃ³n AOE"""
	var explosion = Node2D.new()
	explosion.name = "AOEExplosion"
	explosion.top_level = true
	explosion.z_index = 55
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
		
		# Ondas de explosiÃ³n
		for i in range(3):
			var r = expand * (1.0 - i * 0.2)
			explosion.draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(color.r, color.g, color.b, alpha * (1.0 - i * 0.3)), 4.0 - i)
		
		# Relleno
		explosion.draw_circle(Vector2.ZERO, expand * 0.5, Color(color.r, color.g, color.b, alpha * 0.4))
		explosion.draw_circle(Vector2.ZERO, expand * 0.2, Color(1, 1, 1, alpha * 0.7))
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
	"""Inicializar sistema de boss con configuraciÃ³n de escalado"""
	if not boss_scaling_config.is_empty():
		return
	
	# Obtener minuto de spawn del boss
	var spawn_minute = 5
	if enemy and "enemy_data" in enemy:
		spawn_minute = enemy.enemy_data.get("spawn_minute", 5)
	elif modifiers.has("spawn_minute"):
		spawn_minute = modifiers.get("spawn_minute", 5)
	
	# Obtener configuraciÃ³n de escalado
	boss_scaling_config = SpawnConfig.get_boss_scaling_for_minute(spawn_minute)
	
	# Determinar habilidades desbloqueadas
	var max_abilities = boss_scaling_config.get("abilities_unlocked", 2)
	boss_unlocked_abilities = _get_prioritized_abilities(max_abilities)
	
	# Inicializar cooldowns solo para habilidades desbloqueadas
	for ability in boss_unlocked_abilities:
		boss_ability_cooldowns[ability] = 0.0
	
	# print("[Boss] debug")
	# print("[Boss] ðŸ‘¹ Habilidades: %s" % str(boss_unlocked_abilities))

func _get_prioritized_abilities(max_count: int) -> Array:
	"""Obtener las habilidades priorizadas para desbloquear"""
	# Prioridad de habilidades (las bÃ¡sicas primero, las mÃ¡s poderosas despuÃ©s)
	var priority_order = {
		# Conjurador - bÃ¡sicas primero
		"arcane_barrage": 1,
		"summon_minions": 3,
		"teleport_strike": 2,
		"arcane_nova": 4,
		"curse_aura": 5,
		
		# CorazÃ³n del VacÃ­o
		"void_orbs": 1,
		"void_pull": 2,
		"void_explosion": 3,
		"reality_tear": 4,
		"void_beam": 5,
		"damage_aura": 6,
		
		# GuardiÃ¡n de Runas
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
	"""Actualizar la fase del boss segÃºn su HP actual"""
	if not enemy:
		return
	
	# Obtener HP actual - usar health_component si existe, sino variable hp directa
	var current_hp: float = 0.0
	var max_hp_val: float = 1.0  # Evitar divisiÃ³n por cero
	
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
	# print("[EnemyAttackSystem] ðŸ‘¹ðŸ’€ %s CAMBIÃ“ A FASE %d!" % [enemy.name, new_phase])
	
	# Efecto visual de cambio de fase
	_spawn_phase_change_effect()
	
	# Algunos bosses tienen efectos especiales al cambiar de fase
	var enemy_id = enemy.get("enemy_id") if "enemy_id" in enemy else ""
	
	# Minotauro se enfurece en fase 3
	if "minotauro" in enemy_id.to_lower() and new_phase == 3:
		_activate_boss_enrage()
	
	# CorazÃ³n del VacÃ­o activa aura de daÃ±o permanente en fase 2+
	if "corazon" in enemy_id.to_lower() and new_phase >= 2:
		boss_damage_aura_timer = 999.0  # Aura permanente
	
	# Minotauro activa fire trail en fase 3
	if "minotauro" in enemy_id.to_lower() and new_phase == 3:
		boss_fire_trail_active = true

func _update_boss_passive_effects() -> void:
	"""Actualizar efectos pasivos de boss (auras, trails)"""
	if not enemy or not player:
		return
	
	# Damage Aura (CorazÃ³n del VacÃ­o)
	if boss_damage_aura_timer > 0:
		var aura_radius = modifiers.get("aura_radius", 100.0)
		if boss_current_phase >= 3:
			aura_radius = modifiers.get("phase_3_aura_radius", aura_radius * 1.5)
		
		var dist = enemy.global_position.distance_to(player.global_position)
		if dist <= aura_radius:
			var aura_dps = modifiers.get("aura_damage", 8)
			var frame_damage = aura_dps * get_process_delta_time()
			if player.has_method("take_damage") and frame_damage >= 1:
				player.take_damage(int(frame_damage))
	
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
		
		# Verificar si estÃ¡ disponible
		if boss_ability_cooldowns.get(ability, 0) <= 0:
			# Algunas habilidades solo estÃ¡n disponibles en ciertas fases
			if _is_ability_available_in_phase(ability):
				available.append(ability)
	
	return available

func _is_ability_available_in_phase(ability: String) -> bool:
	"""Verificar si una habilidad estÃ¡ disponible en la fase actual"""
	# Habilidades mÃ¡s poderosas solo en fases avanzadas
	match ability:
		"void_beam", "meteor_call", "ground_slam":
			return boss_current_phase >= 2
		"enrage", "fire_trail", "damage_aura":
			return boss_current_phase >= 3
		_:
			return true

func _select_boss_ability(available: Array) -> String:
	"""Seleccionar habilidad con pesos basados en situaciÃ³n"""
	if available.is_empty():
		return ""
	
	var dist = enemy.global_position.distance_to(player.global_position)
	var weights = {}
	
	for ability in available:
		var weight = 1.0
		
		# Ajustar peso segÃºn distancia
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
		
		# Bonus en fases avanzadas para habilidades mÃ¡s agresivas
		if boss_current_phase >= 2:
			if ability in ["void_explosion", "fire_stomp", "charge_attack", "meteor_call"]:
				weight *= 1.5
		
		weights[ability] = weight
	
	# SelecciÃ³n ponderada
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
	"""Ejecutar una habilidad de boss especÃ­fica"""
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
		
		# El CorazÃ³n del VacÃ­o
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
		
		# El GuardiÃ¡n de Runas
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
			# Habilidad no implementada, usar ataque bÃ¡sico
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

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# HABILIDADES DE EL CONJURADOR PRIMIGENIO
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _boss_arcane_barrage() -> void:
	"""RÃ¡faga de mÃºltiples proyectiles arcanos"""
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
	
	# print("[EnemyAttackSystem] âœ¨ Arcane Barrage: %d proyectiles" % count)

func _boss_summon_minions() -> void:
	"""Invocar enemigos menores"""
	var count = modifiers.get("summon_count", 2)
	var tier = modifiers.get("summon_tier", 1)
	
	if boss_current_phase >= 2:
		count = modifiers.get("phase_2_summon_count", 3)
	if boss_current_phase >= 3:
		tier = modifiers.get("phase_3_summon_tier", 2)
	
	# Efecto visual de invocaciÃ³n
	_spawn_summon_visual()
	
	# Notificar al spawner para crear enemigos
	var spawner = _get_enemy_spawner()
	if spawner and spawner.has_method("spawn_minions_around"):
		spawner.spawn_minions_around(enemy.global_position, count, tier)
		# print("[EnemyAttackSystem] ðŸ‘¹ Summon: %d minions tier %d" % [count, tier])
	else:
		pass
		# print("[EnemyAttackSystem] âš ï¸ No se encontrÃ³ spawner para summon")

func _boss_teleport_strike() -> void:
	"""Teleport hacia el jugador + ataque inmediato"""
	var _teleport_range = modifiers.get("teleport_range", 200.0)
	var damage_mult = modifiers.get("teleport_damage_mult", 1.5)
	
	# Calcular posiciÃ³n de teleport (detrÃ¡s del jugador)
	var to_player = (player.global_position - enemy.global_position).normalized()
	var teleport_pos = player.global_position - to_player * 50  # Aparecer cerca
	
	# Efecto de desapariciÃ³n
	_spawn_teleport_effect(enemy.global_position, false)
	
	# Mover al enemigo
	enemy.global_position = teleport_pos
	
	# Efecto de apariciÃ³n
	_spawn_teleport_effect(teleport_pos, true)
	
	# Ataque inmediato con daÃ±o bonus
	if player.has_method("take_damage"):
		var damage = int(attack_damage * damage_mult)
		player.take_damage(damage)
		attacked_player.emit(damage, true)
		# print("[EnemyAttackSystem] âš¡ Teleport Strike por %d daÃ±o" % damage)

func _boss_arcane_nova() -> void:
	"""Nova de daÃ±o arcano en Ã¡rea"""
	var radius = modifiers.get("nova_radius", 120.0)
	var damage = modifiers.get("nova_damage", 40)
	
	if boss_current_phase >= 3:
		damage = modifiers.get("phase_3_nova_damage", 60)
	
	var dist = enemy.global_position.distance_to(player.global_position)
	if dist <= radius:
		if player.has_method("take_damage"):
			player.take_damage(damage)
			attacked_player.emit(damage, false)
	
	# Visual
	_spawn_arcane_nova_visual(enemy.global_position, radius)
	# print("[EnemyAttackSystem] ðŸ’œ Arcane Nova por %d daÃ±o (radio %.0f)" % [damage, radius])

func _boss_curse_aura() -> void:
	"""Aplicar aura de maldiciÃ³n que reduce curaciÃ³n"""
	var radius = modifiers.get("curse_radius", 150.0)
	var reduction = modifiers.get("curse_reduction", 0.5)
	var duration = modifiers.get("curse_duration", 8.0)
	
	var dist = enemy.global_position.distance_to(player.global_position)
	if dist <= radius:
		if player.has_method("apply_curse"):
			player.apply_curse(reduction, duration)
			# print("[EnemyAttackSystem] â˜ ï¸ Curse Aura: -%.0f%% curaciÃ³n por %.1fs" % [reduction * 100, duration])
	
	# Visual
	_spawn_curse_aura_visual(enemy.global_position, radius)

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# HABILIDADES DE EL CORAZÃ“N DEL VACÃO
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

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
			# print("[EnemyAttackSystem] ðŸŒ€ Void Pull activado")
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
	
	# print("[EnemyAttackSystem] ðŸ’œ Void Orbs: %d orbes perseguidores" % count)

func _boss_reality_tear() -> void:
	"""Crear zona de daÃ±o persistente"""
	var radius = modifiers.get("tear_radius", 80.0)
	var damage = modifiers.get("tear_damage", 15)
	var duration = modifiers.get("tear_duration", 6.0)
	
	# Crear en la posiciÃ³n del jugador
	_spawn_damage_zone(player.global_position, radius, damage, duration, "dark")
	# print("[EnemyAttackSystem] ðŸŒŒ Reality Tear creado")

func _boss_void_beam() -> void:
	"""Rayo canalizado de alto daÃ±o"""
	var damage = modifiers.get("beam_damage", 30)
	var duration = modifiers.get("beam_duration", 3.0)
	var _width = modifiers.get("beam_width", 40.0)
	
	# Este ataque es canalizado - simplificado para aplicar daÃ±o por tick
	var direction = (player.global_position - enemy.global_position).normalized()
	
	# Crear visual del beam
	_spawn_void_beam_visual(enemy.global_position, direction, 300.0, duration)
	
	# Aplicar daÃ±o inicial
	if player.has_method("take_damage"):
		player.take_damage(damage)
		attacked_player.emit(damage, false)
	
	# print("[EnemyAttackSystem] ðŸ’œ Void Beam: %d DPS por %.1fs" % [damage, duration])

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# HABILIDADES DE EL GUARDIÃN DE RUNAS
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _boss_rune_shield() -> void:
	"""Activar escudo que absorbe hits"""
	var charges = modifiers.get("shield_charges", 4)
	var duration = modifiers.get("shield_duration", 10.0)
	
	if boss_current_phase >= 2:
		charges = modifiers.get("phase_2_shield_charges", 6)
	
	# Aplicar escudo al enemigo
	if enemy.has_method("apply_shield"):
		enemy.apply_shield(charges, duration)
		# print("[EnemyAttackSystem] ðŸ›¡ï¸ Rune Shield: %d cargas por %.1fs" % [charges, duration])
	
	# Visual
	_spawn_rune_shield_visual()

func _boss_rune_prison() -> void:
	"""Atrapar al jugador brevemente"""
	var duration = modifiers.get("prison_duration", 1.5)
	var damage = modifiers.get("prison_damage", 20)
	
	# Aplicar stun/root al jugador
	if player.has_method("apply_root"):
		player.apply_root(duration)
	elif player.has_method("apply_stun"):
		player.apply_stun(duration)
	
	# DaÃ±o al escapar (al final)
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(player) and player.has_method("take_damage"):
			player.take_damage(damage)
	)
	
	# Visual
	_spawn_rune_prison_visual(player.global_position, duration)
	# print("[EnemyAttackSystem] â›“ï¸ Rune Prison: %.1fs" % duration)

func _boss_counter_stance() -> void:
	"""Postura de contraataque"""
	var window = modifiers.get("counter_window", 2.0)
	var damage_mult = modifiers.get("counter_damage_mult", 2.5)
	
	if boss_current_phase >= 3:
		damage_mult = modifiers.get("phase_3_counter_damage_mult", 3.5)
	
	# Activar estado de counter en el enemigo
	if enemy.has_method("activate_counter_stance"):
		enemy.activate_counter_stance(window, damage_mult)
	
	# Visual
	_spawn_counter_stance_visual()
	# print("[EnemyAttackSystem] âš”ï¸ Counter Stance: %.1fs window, x%.1f daÃ±o" % [window, damage_mult])

func _boss_rune_barrage() -> void:
	"""MÃºltiples runas disparadas"""
	var count = modifiers.get("barrage_count", 6)
	var damage = modifiers.get("barrage_damage", 20)
	
	var direction = (player.global_position - enemy.global_position).normalized()
	var spread_rad = deg_to_rad(40.0)
	
	for i in range(count):
		var angle_offset = spread_rad * (float(i) / float(count - 1) - 0.5) if count > 1 else 0.0
		var proj_dir = direction.rotated(angle_offset)
		_spawn_boss_projectile_delayed(proj_dir, damage, "arcane", 0.08 * i)
	
	# print("[EnemyAttackSystem] âœ¨ Rune Barrage: %d proyectiles" % count)

func _boss_ground_slam() -> void:
	"""Golpe de tierra con ondas expansivas"""
	var radius = modifiers.get("slam_radius", 150.0)
	var damage = modifiers.get("slam_damage", 45)
	var stun = modifiers.get("slam_stun", 0.5)
	
	if boss_current_phase >= 3:
		damage = modifiers.get("phase_3_slam_damage", 70)
	
	var dist = enemy.global_position.distance_to(player.global_position)
	if dist <= radius:
		if player.has_method("take_damage"):
			player.take_damage(damage)
			attacked_player.emit(damage, false)
		if player.has_method("apply_stun"):
			player.apply_stun(stun)
	
	# Visual
	_spawn_ground_slam_visual(enemy.global_position, radius)
	# print("[EnemyAttackSystem] ðŸ’¥ Ground Slam por %d daÃ±o" % damage)

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# HABILIDADES DE MINOTAURO DE FUEGO
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _boss_charge_attack() -> void:
	"""Carga devastadora hacia el jugador"""
	var charge_speed = modifiers.get("charge_speed", 450.0)
	var damage_mult = modifiers.get("charge_damage_mult", 2.5)
	var stun = modifiers.get("charge_stun", 0.8)
	
	if boss_current_phase >= 2:
		damage_mult = modifiers.get("phase_2_charge_damage_mult", 3.0)
	
	# Calcular direcciÃ³n y distancia
	var direction = (player.global_position - enemy.global_position).normalized()
	var charge_distance = enemy.global_position.distance_to(player.global_position) + 100
	
	# Marcar que el boss estÃ¡ cargando
	if enemy.has_method("start_charge"):
		enemy.start_charge(direction, charge_speed, charge_distance)
	
	# Visual de preparaciÃ³n
	_spawn_charge_warning_visual(enemy.global_position, direction)
	
	# El daÃ±o se aplica cuando el boss impacta (manejado por el enemy)
	# AquÃ­ aplicamos el efecto si estÃ¡ cerca
	var dist = enemy.global_position.distance_to(player.global_position)
	if dist < 80:
		var damage = int(attack_damage * damage_mult)
		if player.has_method("take_damage"):
			player.take_damage(damage)
			attacked_player.emit(damage, true)
		if player.has_method("apply_stun"):
			player.apply_stun(stun)
	
	# print("[EnemyAttackSystem] ðŸ‚ Charge Attack: velocidad %.0f" % charge_speed)

func _boss_flame_breath() -> void:
	"""Aliento de fuego en cono"""
	var angle = modifiers.get("breath_angle", 50.0)
	var range_dist = modifiers.get("breath_range", 180.0)
	var damage = modifiers.get("breath_damage", 25)
	var duration = modifiers.get("breath_duration", 2.0)
	
	if boss_current_phase >= 3:
		damage = modifiers.get("phase_3_breath_damage", 40)
	
	var direction = (player.global_position - enemy.global_position).normalized()
	
	# Verificar si player estÃ¡ en el cono
	var to_player = player.global_position - enemy.global_position
	var dist = to_player.length()
	var angle_to_player = abs(rad_to_deg(direction.angle_to(to_player.normalized())))
	
	if dist <= range_dist and angle_to_player <= angle / 2:
		if player.has_method("take_damage"):
			player.take_damage(damage)
			attacked_player.emit(damage, false)
		if player.has_method("apply_burn"):
			player.apply_burn(damage * 0.5, duration)
	
	# Visual
	_spawn_flame_breath_visual(enemy.global_position, direction, range_dist)
	# print("[EnemyAttackSystem] ðŸ”¥ Flame Breath: %d daÃ±o en cono" % damage)

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
		
		# Meteoro real despuÃ©s del delay
		get_tree().create_timer(delay + i * 0.2).timeout.connect(func():
			_spawn_meteor_impact(target_pos, radius, damage)
		)
	
	# print("[EnemyAttackSystem] â˜„ï¸ Meteor Call: %d meteoros" % count)

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
	# print("[EnemyAttackSystem] ðŸ”¥ðŸ’¢ BOSS ENRAGED! +%.0f%% daÃ±o, +%.0f%% velocidad" % [damage_bonus * 100, speed_bonus * 100])

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
	
	var boss_damage = int(attack_damage * 1.2)  # Bosses hacen mÃ¡s daÃ±o
	player.take_damage(boss_damage)
	# print("[EnemyAttackSystem] ðŸ‘¹ %s (Boss) melee devastador por %d daÃ±o" % [enemy.name, boss_damage])
	
	# Aplicar efecto segÃºn el boss
	_apply_boss_melee_effects()
	
	attacked_player.emit(boss_damage, true)
	
	# Efecto visual de impacto de boss (mÃ¡s grande)
	_spawn_boss_impact_effect()

func _apply_boss_melee_effects() -> void:
	"""Efectos de estado en ataques melee de boss"""
	var enemy_name_lower = enemy.name.to_lower()
	
	# Minotauro - Burn
	if "minotauro" in enemy_name_lower or "fuego" in enemy_name_lower:
		if player.has_method("apply_burn"):
			player.apply_burn(8.0, 3.0)  # 8 daÃ±o/tick por 3s
	# CorazÃ³n del VacÃ­o - Weakness
	elif "corazon" in enemy_name_lower or "vacio" in enemy_name_lower:
		if player.has_method("apply_weakness"):
			player.apply_weakness(0.3, 4.0)  # +30% daÃ±o recibido por 4s
	# GuardiÃ¡n de Runas - Stun breve
	elif "guardian" in enemy_name_lower or "runas" in enemy_name_lower:
		if player.has_method("apply_stun"):
			player.apply_stun(0.3)  # 0.3s stun
	# Conjurador - Curse
	elif "conjurador" in enemy_name_lower:
		if player.has_method("apply_curse"):
			player.apply_curse(0.4, 5.0)  # -40% curaciÃ³n por 5s

func _perform_boss_void_explosion() -> void:
	"""El CorazÃ³n del VacÃ­o - explosiÃ³n de vacÃ­o"""
	if not player:
		return
	
	var explosion_radius = modifiers.get("explosion_radius", 150.0)
	var explosion_damage = modifiers.get("explosion_damage", 60)
	
	# Verificar si player estÃ¡ en rango
	var dist = enemy.global_position.distance_to(player.global_position)
	if dist <= explosion_radius:
		if player.has_method("take_damage"):
			player.take_damage(explosion_damage)
			# print("[EnemyAttackSystem] ðŸ’œ %s Void Explosion por %d daÃ±o!" % [enemy.name, explosion_damage])
			attacked_player.emit(explosion_damage, false)
			# Aplicar Weakness fuerte
			if player.has_method("apply_weakness"):
				player.apply_weakness(0.4, 5.0)  # +40% daÃ±o recibido por 5s
				# print("[EnemyAttackSystem] ðŸ’œ Void Explosion aplica Weakness!")
	
	# Visual de explosiÃ³n de vacÃ­o
	_spawn_void_explosion_visual(enemy.global_position, explosion_radius)

func _perform_boss_rune_blast() -> void:
	"""El GuardiÃ¡n de Runas - explosiÃ³n de runas"""
	if not player:
		return
	
	var blast_radius = modifiers.get("blast_radius", 100.0)
	var blast_damage = modifiers.get("blast_damage", 45)
	
	var dist = enemy.global_position.distance_to(player.global_position)
	if dist <= blast_radius:
		if player.has_method("take_damage"):
			player.take_damage(blast_damage)
			# print("[EnemyAttackSystem] âœ¨ %s Rune Blast por %d daÃ±o!" % [enemy.name, blast_damage])
			attacked_player.emit(blast_damage, false)
			# Aplicar Stun
			if player.has_method("apply_stun"):
				player.apply_stun(0.5)  # 0.5s stun
				# print("[EnemyAttackSystem] âœ¨ Rune Blast aplica Stun!")
	
	# Visual de runas
	_spawn_rune_blast_visual(enemy.global_position, blast_radius)

func _perform_boss_fire_stomp() -> void:
	"""Minotauro de Fuego - pisotÃ³n de fuego"""
	if not player:
		return
	
	var stomp_radius = modifiers.get("stomp_radius", 120.0)
	var stomp_damage = modifiers.get("stomp_damage", 50)
	
	var dist = enemy.global_position.distance_to(player.global_position)
	if dist <= stomp_radius:
		if player.has_method("take_damage"):
			player.take_damage(stomp_damage)
			# print("[EnemyAttackSystem] ðŸ”¥ %s Fire Stomp por %d daÃ±o!" % [enemy.name, stomp_damage])
			attacked_player.emit(stomp_damage, false)
			# Aplicar Burn fuerte + Stun breve
			if player.has_method("apply_burn"):
				player.apply_burn(10.0, 4.0)  # 10 daÃ±o/tick por 4s (muy fuerte)
				# print("[EnemyAttackSystem] ðŸ”¥ Fire Stomp aplica Burn!")
			if player.has_method("apply_stun"):
				player.apply_stun(0.3)  # 0.3s stun
	
	# Visual de pisotÃ³n de fuego
	_spawn_fire_stomp_visual(enemy.global_position, stomp_radius)

func _spawn_boss_impact_effect() -> void:
	"""Efecto de impacto de ataque de boss"""
	if not enemy or not player:
		return
	
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
		
		# Ondas de choque
		for i in range(3):
			var wave_radius = radius * (1.0 + i * 0.3)
			var wave_alpha = (1.0 - anim_progress) * (0.6 - i * 0.15)
			visual.draw_arc(Vector2.ZERO, wave_radius, 0, TAU, 32, Color(color.r, color.g, color.b, wave_alpha), 4.0 - i)
		
		# Cruz de impacto
		var cross_size = radius * 1.5
		var cross_alpha = (1.0 - anim_progress) * 0.7
		visual.draw_line(Vector2(-cross_size, 0), Vector2(cross_size, 0), Color(1, 1, 1, cross_alpha), 3.0)
		visual.draw_line(Vector2(0, -cross_size), Vector2(0, cross_size), Color(1, 1, 1, cross_alpha), 3.0)
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
	"""Visual de explosiÃ³n de vacÃ­o Ã‰PICA - pÃºrpura con absorciÃ³n"""
	var effect = Node2D.new()
	effect.top_level = true  # Independiente del enemigo
	effect.z_index = 60  # MUY alto para boss
	effect.global_position = center
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)
	
	var anim_progress = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)
	
	visual.draw.connect(func():
		# ExplosiÃ³n inversa (desde fuera hacia dentro, luego explota)
		var phase = anim_progress
		
		if phase < 0.35:
			# Fase de absorciÃ³n - MÃS DRAMÃTICA
			var absorb_phase = phase / 0.35
			var absorb_radius = radius * (1.2 - absorb_phase * 0.8)
			
			# MÃºltiples capas de absorciÃ³n
			for i in range(5):
				var layer_r = absorb_radius * (1.0 + i * 0.15)
				var layer_alpha = 0.3 * absorb_phase * (1.0 - i * 0.15)
				visual.draw_circle(Vector2.ZERO, layer_r, Color(0.4, 0.05, 0.7, layer_alpha))
			
			# Espirales siendo absorbidas
			var spiral_count = 6
			for s in range(spiral_count):
				var spiral_points = PackedVector2Array()
				for i in range(20):
					var t = float(i) / 20.0
					var r = absorb_radius * (1.3 - t) * (1.0 - absorb_phase * 0.6)
					var angle = t * PI * 3 + (TAU / spiral_count) * s + phase * PI * 4
					spiral_points.append(Vector2(cos(angle), sin(angle)) * r)
				if spiral_points.size() > 1:
					visual.draw_polyline(spiral_points, Color(0.7, 0.2, 1.0, 0.7 * absorb_phase), 3.0)
			
			# PartÃ­culas siendo absorbidas - MÃS
			var particle_count = 16
			for i in range(particle_count):
				var angle = (TAU / particle_count) * i + phase * PI * 2
				var dist = absorb_radius * (1.4 - absorb_phase * 0.7)
				var pos = Vector2(cos(angle), sin(angle)) * dist
				visual.draw_circle(pos, 6, Color(0.85, 0.4, 1.0, 0.9))
				visual.draw_circle(pos, 9, Color(0.85, 0.4, 1.0, 0.3))
		else:
			pass  # Bloque else
			# Fase de explosiÃ³n - MUCHO MÃS Ã‰PICA
			var explode_phase = (phase - 0.35) / 0.65
			var explode_radius = radius * 1.3 * explode_phase
			
			# Ondas de vacÃ­o mÃºltiples
			for i in range(5):
				var wave_r = explode_radius * (0.25 + i * 0.2)
				var wave_alpha = (1.0 - explode_phase) * (0.7 - i * 0.12)
				visual.draw_arc(Vector2.ZERO, wave_r, 0, TAU, 48, Color(0.6, 0.1, 0.95, wave_alpha), 5.0 - i)
			
			# Relleno de explosiÃ³n
			for i in range(4):
				var fill_r = explode_radius * (1.0 - i * 0.2)
				var fill_alpha = (1.0 - explode_phase) * (0.4 - i * 0.08)
				visual.draw_circle(Vector2.ZERO, fill_r, Color(0.5, 0.1, 0.8, fill_alpha))
			
			# Rayos de energÃ­a oscura
			var ray_count = 12
			for i in range(ray_count):
				var ray_angle = (TAU / ray_count) * i + explode_phase * PI * 0.5
				var ray_length = explode_radius * (0.8 + sin(explode_phase * PI * 3 + i) * 0.3)
				var ray_end = Vector2(cos(ray_angle), sin(ray_angle)) * ray_length
				visual.draw_line(Vector2.ZERO, ray_end, Color(0.9, 0.5, 1.0, (1.0 - explode_phase) * 0.8), 3.0)
			
			# Centro oscuro pulsante
			var core_size = 30 * (1.0 - explode_phase * 0.7)
			visual.draw_circle(Vector2.ZERO, core_size, Color(0.15, 0, 0.25, 0.95 * (1.0 - explode_phase)))
			visual.draw_circle(Vector2.ZERO, core_size * 0.5, Color(0.3, 0, 0.5, 0.8))
	)
	
	# IMPORTANTE: Usar effect.create_tween() para que el tween se limpie con el nodo
	var tween = effect.create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.9)  # MÃ¡s largo para ser Ã©pico
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_rune_blast_visual(center: Vector2, radius: float) -> void:
	"""Visual de explosiÃ³n de runas Ã‰PICA - sÃ­mbolos brillantes"""
	var effect = Node2D.new()
	effect.top_level = true  # Independiente del enemigo
	effect.z_index = 60  # MUY alto para boss
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
		
		# CÃ­rculos mÃ¡gicos concÃ©ntricos (nuevo)
		for c in range(3):
			var circle_r = expand * (0.4 + c * 0.25)
			var circle_alpha = 0.5 * (1.0 - anim_progress) * (1.0 - c * 0.25)
			visual.draw_arc(Vector2.ZERO, circle_r, 0, TAU, 48, Color(0.95, 0.85, 0.15, circle_alpha), 3.0)
		
		# Relleno dorado con gradiente
		for i in range(4):
			var fill_r = expand * (0.9 - i * 0.15)
			var fill_alpha = (1.0 - anim_progress) * (0.3 - i * 0.06)
			visual.draw_circle(Vector2.ZERO, fill_r, Color(1, 0.9, 0.2, fill_alpha))
		
		# Runas individuales que se expanden - MÃS Y MÃS GRANDES
		for i in range(rune_count):
			var angle = (TAU / rune_count) * i + anim_progress * PI * 0.7
			var dist = expand * (0.45 + anim_progress * 0.55)
			var pos = Vector2(cos(angle), sin(angle)) * dist
			
			# Dibujar runa como forma geomÃ©trica - MÃS GRANDE
			var rune_size = 18 * (1.0 - anim_progress * 0.4)
			
			# TriÃ¡ngulo exterior
			var rune_points = PackedVector2Array([
				pos + Vector2(0, -rune_size),
				pos + Vector2(rune_size * 0.85, rune_size * 0.6),
				pos + Vector2(-rune_size * 0.85, rune_size * 0.6)
			])
			visual.draw_colored_polygon(rune_points, Color(1, 0.92, 0.35, 0.9 * (1.0 - anim_progress)))
			
			# TriÃ¡ngulo interior invertido
			var inner_size = rune_size * 0.5
			var inner_points = PackedVector2Array([
				pos + Vector2(0, inner_size * 0.5),
				pos + Vector2(inner_size * 0.4, -inner_size * 0.3),
				pos + Vector2(-inner_size * 0.4, -inner_size * 0.3)
			])
			visual.draw_colored_polygon(inner_points, Color(1, 1, 0.8, 0.95 * (1.0 - anim_progress)))
			
			# Brillo alrededor - MÃS GRANDE
			visual.draw_circle(pos, rune_size * 2.0, Color(1, 1, 0.5, 0.25 * (1.0 - anim_progress)))
			visual.draw_circle(pos, rune_size * 1.3, Color(1, 0.95, 0.4, 0.4 * (1.0 - anim_progress)))
		
		# LÃ­neas de conexiÃ³n entre runas (nuevo)
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
		
		# Onda de expansiÃ³n final - MÃS BRILLANTE
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
	, 0.0, 1.0, 0.6)  # MÃ¡s largo
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_fire_stomp_visual(center: Vector2, radius: float) -> void:
	"""Visual de pisotÃ³n de fuego Ã‰PICO - onda de fuego expansiva"""
	var effect = Node2D.new()
	effect.top_level = true  # Independiente del enemigo
	effect.z_index = 60  # MUY alto para boss
	effect.global_position = center
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)
	
	var anim_progress = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)
	
	visual.draw.connect(func():
		var expand = radius * 1.2 * anim_progress
		
		# CrÃ¡ter central - MÃS DETALLADO
		var crater_size = expand * 0.35
		visual.draw_circle(Vector2.ZERO, crater_size, Color(0.2, 0.05, 0, 0.8 * (1.0 - anim_progress)))
		visual.draw_arc(Vector2.ZERO, crater_size * 0.7, 0, TAU, 24, Color(0.4, 0.1, 0, 0.6), 3.0)
		
		# Anillos de fuego - MÃS Y MÃS GRUESOS
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
		
		# Llamas alrededor - MÃS Y MÃS GRANDES
		var flame_count = 16
		for i in range(flame_count):
			var angle = (TAU / flame_count) * i
			var flame_dist = expand * 0.75
			var flame_base = Vector2(cos(angle), sin(angle)) * flame_dist
			
			# Altura de llama animada - mÃ¡s dramÃ¡tica
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
			
			# NÃºcleo de llama (amarillo)
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
	, 0.0, 1.0, 0.7)  # MÃ¡s largo para ser Ã©pico
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
	"""Crear un Ãºnico proyectil"""
	if not EnemyProjectileScript or not is_instance_valid(enemy):
		return
	
	var projectile = Area2D.new()
	projectile.set_script(EnemyProjectileScript)
	projectile.global_position = enemy.global_position
	
	var elem = _get_enemy_element()
	var proj_damage = int(attack_damage * 0.7)  # Multi tiene menos daÃ±o por proyectil
	
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
	
	var enemy_id = enemy.get("enemy_id") if "enemy_id" in enemy else ""
	var name_lower = enemy_id.to_lower()
	
	# Casos especiales primero (antes de la detecciÃ³n genÃ©rica)
	# Hechicero Desgastado es un mago de fuego corrupto
	if "hechicero_desgastado" in name_lower or "hechicero" in name_lower:
		return "fire"
	
	if "fuego" in name_lower or "llamas" in name_lower or "fire" in name_lower:
		return "fire"
	if "hielo" in name_lower or "ice" in name_lower or "frost" in name_lower or "cristal" in name_lower:
		return "ice"
	if "void" in name_lower or "vacio" in name_lower or "shadow" in name_lower or "sombra" in name_lower:
		return "dark"
	if "arcano" in name_lower or "arcane" in name_lower or "mago" in name_lower:
		return "arcane"
	if "veneno" in name_lower or "poison" in name_lower:
		return "poison"
	if "rayo" in name_lower or "lightning" in name_lower or "thunder" in name_lower:
		return "lightning"
	
	return "physical"

func _spawn_aoe_visual(center: Vector2, radius: float) -> void:
	"""Crear efecto visual de AoE Ã‰PICO con animaciÃ³n de expansiÃ³n"""
	var elem = _get_enemy_element()
	var base_color = _get_element_color(elem)
	var bright_color = Color(min(base_color.r + 0.4, 1.0), min(base_color.g + 0.4, 1.0), min(base_color.b + 0.4, 1.0), 1.0)
	
	# Crear contenedor principal - INDEPENDIENTE del enemigo
	var container = Node2D.new()
	container.name = "AoE_Visual"
	container.top_level = true  # No se mueve con el padre
	container.z_index = 55  # MUY visible encima de otros elementos
	container.global_position = center
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(container)
	
	# Determinar si es Ã©lite para efectos mÃ¡s grandes
	var is_elite = enemy.get("is_elite") if "is_elite" in enemy else false
	var size_mult = 1.3 if is_elite else 1.0
	var actual_radius = radius * size_mult
	
	# Variables de animaciÃ³n
	var anim_progress = 0.0
	var ring_count = 4
	
	# Nodo visual para dibujar
	var visual = Node2D.new()
	container.add_child(visual)
	
	visual.draw.connect(func():
		# CÃ­rculo de impacto central que se expande
		var expand_radius = actual_radius * anim_progress
		
		# GLOW EXTERIOR GRANDE (nuevo)
		for g in range(4):
			var glow_r = expand_radius * (1.0 + g * 0.1)
			var glow_alpha = 0.15 * (1.0 - anim_progress) * (1.0 - g * 0.2)
			if glow_r > 0:
				visual.draw_circle(Vector2.ZERO, glow_r, Color(base_color.r, base_color.g, base_color.b, glow_alpha))
		
		# CÃ­rculo exterior con gradiente simulado (mÃºltiples capas)
		for i in range(6):
			var layer_radius = expand_radius * (1.0 - i * 0.12)
			var layer_alpha = (0.5 - i * 0.07) * (1.0 - anim_progress * 0.4)
			if layer_radius > 0:
				visual.draw_circle(Vector2.ZERO, layer_radius, Color(base_color.r, base_color.g, base_color.b, layer_alpha))
		
		# Anillos de onda expansiva - MÃS GRUESOS
		for i in range(ring_count):
			var ring_phase = fmod(anim_progress * 2.5 + i * 0.25, 1.0)
			var ring_radius = actual_radius * ring_phase
			var ring_alpha = (1.0 - ring_phase) * 0.9
			if ring_radius > 0:
				visual.draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 48, Color(bright_color.r, bright_color.g, bright_color.b, ring_alpha), 4.0)
		
		# PartÃ­culas decorativas alrededor - MÃS Y MÃS GRANDES
		var particle_count = 12
		for i in range(particle_count):
			var angle = (TAU / particle_count) * i + anim_progress * PI * 1.5
			var dist = expand_radius * (0.7 + sin(anim_progress * PI * 3 + i) * 0.2)
			var particle_pos = Vector2(cos(angle), sin(angle)) * dist
			var particle_size = (5.0 + sin(anim_progress * PI * 5 + i) * 3.0) * size_mult
			visual.draw_circle(particle_pos, particle_size, bright_color)
			# Glow de partÃ­cula
			visual.draw_circle(particle_pos, particle_size * 1.5, Color(bright_color.r, bright_color.g, bright_color.b, 0.3))
		
		# Rayos desde el centro (nuevo)
		var ray_count = 8
		for i in range(ray_count):
			var ray_angle = (TAU / ray_count) * i + anim_progress * PI * 0.5
			var ray_length = expand_radius * (0.3 + anim_progress * 0.7)
			var ray_end = Vector2(cos(ray_angle), sin(ray_angle)) * ray_length
			visual.draw_line(Vector2.ZERO, ray_end, Color(1, 1, 1, 0.5 * (1.0 - anim_progress)), 2.0)
		
		# Borde exterior final - MÃS BRILLANTE
		if expand_radius > 0:
			visual.draw_arc(Vector2.ZERO, expand_radius, 0, TAU, 64, Color(1, 1, 1, 0.8 * (1.0 - anim_progress)), 4.0)
		
		# Centro de impacto
		var core_size = expand_radius * 0.15 * (1.0 - anim_progress * 0.5)
		if core_size > 0:
			visual.draw_circle(Vector2.ZERO, core_size, Color(1, 1, 1, 0.9 * (1.0 - anim_progress)))
	)
	
	# AnimaciÃ³n de expansiÃ³n - MÃS LARGA para ser muy visible
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
	"""Crear efecto visual de breath attack Ã‰PICO con animaciÃ³n de expansiÃ³n"""
	var container = Node2D.new()
	container.name = "Breath_Visual"
	container.top_level = true  # No se mueve con el padre
	container.z_index = 55  # MUY visible encima de otros elementos
	container.global_position = origin
	container.rotation = direction.angle()
	
	var elem = _get_enemy_element()
	var base_color = _get_element_color(elem)
	var bright_color = Color(min(base_color.r + 0.5, 1.0), min(base_color.g + 0.5, 1.0), min(base_color.b + 0.3, 1.0), 1.0)
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(container)
	
	# Determinar si es Ã©lite/boss para efectos mÃ¡s grandes
	var is_elite = enemy.get("is_elite") if "is_elite" in enemy else false
	var is_boss = enemy.get("archetype") == "boss" if "archetype" in enemy else false
	var size_mult = 1.5 if is_boss else (1.3 if is_elite else 1.0)
	var actual_range = range_dist * size_mult
	
	var anim_progress = 0.0
	var visual = Node2D.new()
	container.add_child(visual)
	
	visual.draw.connect(func():
		var current_range = actual_range * anim_progress
		var cone_width = 0.45  # Ancho del cono mÃ¡s amplio
		
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
		
		# MÃºltiples capas del cono para efecto de gradiente
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
		
		# NÃºcleo brillante central - MÃS INTENSO
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
		
		# PartÃ­culas a lo largo del breath - MÃS Y MÃS GRANDES
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
		
		# Borde brillante del cono - MÃS GRUESO
		visual.draw_line(Vector2.ZERO, Vector2(current_range, -current_range * cone_width), Color(1, 1, 1, 0.7), 3.0)
		visual.draw_line(Vector2.ZERO, Vector2(current_range, current_range * cone_width), Color(1, 1, 1, 0.7), 3.0)
		
		# Arco frontal del cono (nuevo)
		var arc_radius = current_range * cone_width * 0.3
		visual.draw_arc(Vector2(current_range, 0), arc_radius, -PI/2, PI/2, 12, Color(1, 1, 1, 0.5 * (1.0 - anim_progress)), 2.0)
	)
	
	# AnimaciÃ³n de expansiÃ³n - MÃS LARGA
	# IMPORTANTE: Usar container.create_tween() para que el tween se limpie con el nodo
	var tween = container.create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.45)  # MÃ¡s tiempo para la expansiÃ³n
	
	# Mantener un momento y fade out suave
	tween.tween_interval(0.25)
	tween.tween_property(container, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func():
		if is_instance_valid(container):
			container.queue_free()
	)

func _get_element_color(elem: String) -> Color:
	"""Obtener color segÃºn elemento - Colores mÃ¡s vibrantes y atractivos"""
	match elem:
		"fire": return Color(1.0, 0.3, 0.05, 0.8)      # Rojo fuego brillante
		"ice": return Color(0.2, 0.7, 1.0, 0.8)        # Azul hielo claro
		"dark": return Color(0.6, 0.1, 0.9, 0.8)       # PÃºrpura oscuro
		"arcane": return Color(0.9, 0.3, 1.0, 0.8)     # Magenta arcano
		"poison": return Color(0.2, 0.9, 0.2, 0.8)     # Verde venenoso
		"lightning": return Color(1.0, 1.0, 0.2, 0.8)  # Amarillo elÃ©ctrico
		_: return Color(0.9, 0.9, 0.9, 0.8)            # Blanco fÃ­sico

func _emit_melee_effect() -> void:
	"""Emitir efecto visual de ataque melee Ã‰PICO con slash animado"""
	if not enemy or not player:
		return
	
	var direction = (player.global_position - enemy.global_position).normalized()
	var slash_pos = enemy.global_position + direction * 25
	
	# Crear visual de slash - INDEPENDIENTE del enemigo
	var slash = Node2D.new()
	slash.name = "MeleeSlash"
	slash.top_level = true  # No se mueve con el padre
	slash.z_index = 55  # MUY visible encima de otros elementos
	slash.global_position = slash_pos
	slash.rotation = direction.angle()
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(slash)
	
	var elem = _get_enemy_element()
	var base_color = _get_element_color(elem)
	var bright_color = Color(min(base_color.r + 0.4, 1.0), min(base_color.g + 0.4, 1.0), min(base_color.b + 0.4, 1.0), 1.0)
	var anim_progress = 0.0
	
	# Determinar si es Ã©lite para efectos mÃ¡s grandes
	var is_elite = enemy.get("is_elite") if "is_elite" in enemy else false
	var size_mult = 1.5 if is_elite else 1.0
	
	var visual = Node2D.new()
	slash.add_child(visual)
	
	visual.draw.connect(func():
		var arc_angle = PI * 0.85  # Ãngulo del arco de slash mÃ¡s amplio
		var arc_radius = 45.0 * (0.5 + anim_progress * 0.5) * size_mult
		var arc_start = -arc_angle / 2 + (1.0 - anim_progress) * arc_angle * 0.3
		var arc_end = arc_angle / 2 - (1.0 - anim_progress) * arc_angle * 0.3
		
		# GLOW EXTERIOR (nuevo)
		for g in range(3):
			var glow_radius = arc_radius * (1.2 + g * 0.15)
			var glow_alpha = 0.2 * (1.0 - anim_progress) * (1.0 - g * 0.25)
			if glow_radius > 0:
				visual.draw_arc(Vector2.ZERO, glow_radius, arc_start, arc_end, 20, Color(base_color.r, base_color.g, base_color.b, glow_alpha), 8.0 - g * 2)
		
		# MÃºltiples arcos para efecto de estela - MÃS GRUESOS
		for i in range(5):
			var layer_radius = arc_radius * (1.0 - i * 0.12)
			var layer_alpha = (1.0 - i * 0.18) * (1.0 - anim_progress * 0.5)
			var layer_width = (8.0 - i * 1.5) * (1.0 - anim_progress * 0.3) * size_mult
			if layer_width > 0:
				visual.draw_arc(Vector2.ZERO, layer_radius, arc_start, arc_end, 20, Color(base_color.r, base_color.g, base_color.b, layer_alpha), layer_width)
		
		# NÃºcleo brillante blanco
		visual.draw_arc(Vector2.ZERO, arc_radius * 0.7, arc_start * 0.8, arc_end * 0.8, 16, Color(1, 1, 1, 0.9 * (1.0 - anim_progress)), 4.0 * size_mult)
		
		# Destello en el borde del slash - MÃS GRANDE
		var flash_pos = Vector2(cos(arc_end), sin(arc_end)) * arc_radius
		var flash_size = 12.0 * (1.0 - anim_progress) * size_mult
		visual.draw_circle(flash_pos, flash_size, Color(1, 1, 1, 0.95 * (1.0 - anim_progress)))
		visual.draw_circle(flash_pos, flash_size * 0.5, bright_color)
		
		# Chispas mÃºltiples que vuelan
		var spark_count = 8
		for i in range(spark_count):
			var spark_angle = arc_start + (arc_end - arc_start) * (float(i) / spark_count)
			var spark_dist = arc_radius * (0.6 + anim_progress * 0.8)
			var spark_pos = Vector2(cos(spark_angle), sin(spark_angle)) * spark_dist
			var spark_size = (4.0 - i * 0.3) * (1.0 - anim_progress) * size_mult
			visual.draw_circle(spark_pos, spark_size, Color(1, 1, 0.7, 0.8 * (1.0 - anim_progress)))
		
		# LÃ­neas de energÃ­a desde el centro (nuevo)
		for i in range(5):
			var line_angle = arc_start + (arc_end - arc_start) * (float(i) / 4)
			var line_end = Vector2(cos(line_angle), sin(line_angle)) * arc_radius * (0.5 + anim_progress * 0.5)
			visual.draw_line(Vector2.ZERO, line_end, Color(bright_color.r, bright_color.g, bright_color.b, 0.5 * (1.0 - anim_progress)), 2.0)
	)
	
	# AnimaciÃ³n MÃS LARGA para ser visible
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

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# FUNCIONES AUXILIARES PARA BOSSES
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

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
	"""Crear orbe Ã‰PICO que persigue al jugador"""
	if not is_instance_valid(enemy) or not is_instance_valid(player):
		return
	
	var orb = Node2D.new()  # Usar Node2D simple, colisiÃ³n por distancia
	orb.name = "HomingOrb"
	orb.top_level = true  # No se mueve con el enemigo si este muere
	orb.global_position = pos
	orb.z_index = 65  # MUY visible, encima de casi todo
	
	# Visual mejorado - MUY GRANDE Y BRILLANTE
	var visual = Node2D.new()
	orb.add_child(visual)
	var color = _get_element_color(element)
	var bright_color = Color(min(color.r + 0.4, 1.0), min(color.g + 0.4, 1.0), min(color.b + 0.4, 1.0), 1.0)
	var orb_time = 0.0
	
	# Trail del orbe
	var trail_positions: Array = []
	var max_trail = 12
	
	visual.draw.connect(func():
		var pulse = 1.0 + sin(orb_time * 8) * 0.25
		
		# Dibujar trail primero (detrÃ¡s del orbe)
		for i in range(trail_positions.size()):
			var trail_pos = trail_positions[i] - orb.global_position
			var trail_alpha = float(i) / max_trail * 0.5
			var trail_size = 8 * (float(i) / max_trail)
			visual.draw_circle(trail_pos, trail_size, Color(color.r, color.g, color.b, trail_alpha))
		
		# Glow exterior MUY grande
		visual.draw_circle(Vector2.ZERO, 35 * pulse, Color(color.r, color.g, color.b, 0.15))
		visual.draw_circle(Vector2.ZERO, 28 * pulse, Color(color.r, color.g, color.b, 0.25))
		visual.draw_circle(Vector2.ZERO, 22 * pulse, Color(color.r, color.g, color.b, 0.4))
		
		# Cuerpo principal mÃ¡s grande
		visual.draw_circle(Vector2.ZERO, 18 * pulse, color)
		
		# Anillo de energÃ­a rotando
		var ring_angle = orb_time * 5
		visual.draw_arc(Vector2.ZERO, 22 * pulse, ring_angle, ring_angle + PI * 1.5, 16, bright_color, 2.0)
		
		# NÃºcleo brillante
		visual.draw_circle(Vector2.ZERO, 12 * pulse, bright_color)
		
		# Centro blanco brillante
		visual.draw_circle(Vector2.ZERO, 6, Color(1, 1, 1, 0.98))
		
		# PartÃ­culas orbitando
		for i in range(4):
			var orbit_angle = orb_time * 6 + (TAU / 4) * i
			var orbit_pos = Vector2(cos(orbit_angle), sin(orbit_angle)) * 25 * pulse
			visual.draw_circle(orbit_pos, 4, bright_color)
	)
	visual.queue_redraw()
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(orb)
	
	# Trackear el efecto para limpieza cuando muera el boss
	_track_boss_effect(orb)
	
	# Variables para tracking
	var time_alive = 0.0
	var player_ref = player
	var has_hit = false
	var hit_radius = 28.0  # Radio de colisiÃ³n mÃ¡s grande
	
	# Usar timer para movimiento y colisiÃ³n por distancia
	var timer = Timer.new()
	timer.wait_time = 0.016
	timer.autostart = true
	orb.add_child(timer)
	
	timer.timeout.connect(func():
		if not is_instance_valid(orb) or has_hit:
			return
		if not is_instance_valid(player_ref):
			orb.queue_free()
			return
		
		time_alive += 0.016
		orb_time += 0.016
		
		# Guardar posiciÃ³n para trail
		trail_positions.push_front(orb.global_position)
		if trail_positions.size() > max_trail:
			trail_positions.pop_back()
		
		# Check duraciÃ³n
		if time_alive >= duration:
			# Efecto de desvanecimiento
			var tween = orb.create_tween()
			tween.tween_property(orb, "modulate:a", 0.0, 0.4)
			tween.tween_callback(orb.queue_free)
			return
		
		# Mover hacia player con aceleraciÃ³n
		var dir = (player_ref.global_position - orb.global_position).normalized()
		var current_speed = speed * (1.0 + time_alive * 0.3)  # Acelera con el tiempo
		orb.global_position += dir * current_speed * 0.016
		
		# Actualizar visual
		visual.queue_redraw()
		
		# CHECK POR DISTANCIA (mÃ¡s fiable que Area2D)
		var dist = orb.global_position.distance_to(player_ref.global_position)
		if dist < hit_radius:
			has_hit = true
			if player_ref.has_method("take_damage"):
				player_ref.call("take_damage", damage, element)
				# print("[HomingOrb] ðŸ”® Impacto en player: %d daÃ±o (%s)" % [damage, element])
			# Efecto de impacto Ã‰PICO
			_spawn_orb_impact_effect(orb.global_position, color)
			orb.queue_free()
			return
	)

func _spawn_orb_impact_effect(pos: Vector2, color: Color) -> void:
	"""Crear efecto visual de impacto de orbe Ã‰PICO"""
	var effect = Node2D.new()
	effect.global_position = pos
	effect.top_level = true
	effect.z_index = 65
	
	if is_instance_valid(enemy):
		var parent = enemy.get_parent()
		if parent:
			parent.add_child(effect)
	
	var anim_progress = 0.0
	var bright_color = Color(min(color.r + 0.4, 1.0), min(color.g + 0.4, 1.0), min(color.b + 0.4, 1.0), 1.0)
	
	effect.draw.connect(func():
		var radius = 45 * anim_progress
		var alpha = (1.0 - anim_progress) * 0.9
		
		# MÃºltiples ondas de expansiÃ³n
		for i in range(4):
			var wave_r = radius * (0.4 + i * 0.2)
			var wave_alpha = alpha * (1.0 - i * 0.2)
			effect.draw_circle(Vector2.ZERO, wave_r, Color(color.r, color.g, color.b, wave_alpha * 0.4))
		
		# Anillos de energÃ­a
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
	"""Crear zona de daÃ±o persistente"""
	if not is_instance_valid(enemy) or not is_instance_valid(player):
		return
	
	var zone = Node2D.new()
	zone.name = "DamageZone"
	zone.global_position = pos
	
	# Visual
	var visual = Node2D.new()
	zone.add_child(visual)
	var color = _get_element_color(element)
	var anim_time = 0.0
	
	visual.draw.connect(func():
		var pulse = 0.8 + sin(anim_time * 4) * 0.2
		visual.draw_circle(Vector2.ZERO, radius * pulse, Color(color.r, color.g, color.b, 0.3))
		visual.draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(color.r, color.g, color.b, 0.6), 2.0)
	)
	visual.queue_redraw()
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(zone)
	
	# DaÃ±o por tick
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
		anim_time += 0.1
		visual.queue_redraw()
		
		if time_alive >= duration:
			zone.queue_free()
			return
		
		var dist = zone.global_position.distance_to(player_ref.global_position)
		if dist <= radius:
			damage_accumulator += dps * 0.1
			if damage_accumulator >= 1 and player_ref.has_method("take_damage"):
				player_ref.take_damage(int(damage_accumulator))
				damage_accumulator = fmod(damage_accumulator, 1.0)
	)

# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
# EFECTOS VISUALES DE BOSS
# â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

func _spawn_phase_change_effect() -> void:
	"""Efecto visual de cambio de fase Ã‰PICO"""
	if not is_instance_valid(enemy):
		return
	
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 70  # Encima de todo
	effect.global_position = enemy.global_position
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)
	
	var anim = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)
	
	visual.draw.connect(func():
		# Ondas expansivas rojas MASIVAS
		for i in range(5):
			var r = 150 * anim * (1 + i * 0.25)
			var a = (1.0 - anim) * (0.9 - i * 0.15)
			visual.draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(1, 0.15, 0.15, a), 6.0 - i)
		
		# Relleno de energÃ­a
		for i in range(3):
			var fill_r = 100 * anim * (1.0 - i * 0.25)
			var fill_a = (1.0 - anim) * (0.4 - i * 0.1)
			visual.draw_circle(Vector2.ZERO, fill_r, Color(1, 0.3, 0.1, fill_a))
		
		# Rayos desde el centro - MÃS Y MÃS BRILLANTES
		var ray_count = 12
		for i in range(ray_count):
			var angle = (TAU / ray_count) * i + anim * PI * 1.5
			var length = 200 * anim
			var end = Vector2(cos(angle), sin(angle)) * length
			visual.draw_line(Vector2.ZERO, end, Color(1, 0.6, 0.1, (1.0 - anim) * 0.9), 4.0)
			# LÃ­nea interior blanca
			visual.draw_line(Vector2.ZERO, end * 0.8, Color(1, 1, 0.8, (1.0 - anim) * 0.7), 2.0)
		
		# Texto de fase (simulado con cÃ­rculos)
		var text_radius = 50 * (1.0 - anim * 0.3)
		visual.draw_circle(Vector2.ZERO, text_radius, Color(1, 0.2, 0.1, (1.0 - anim) * 0.8))
		visual.draw_arc(Vector2.ZERO, text_radius, 0, TAU, 32, Color(1, 1, 0.5, (1.0 - anim)), 4.0)
		
		# PartÃ­culas de energÃ­a volando
		var particle_count = 16
		for i in range(particle_count):
			var p_angle = (TAU / particle_count) * i
			var p_dist = 80 * anim + sin(anim * PI * 4 + i) * 20
			var p_pos = Vector2(cos(p_angle), sin(p_angle)) * p_dist
			p_pos.y -= anim * 40 * (float(i % 3) / 2)  # Algunas suben
			visual.draw_circle(p_pos, 6 * (1.0 - anim * 0.5), Color(1, 0.8, 0.2, (1.0 - anim) * 0.9))
	)
	
	# IMPORTANTE: Usar effect.create_tween() para que el tween se limpie con el nodo
	var tween = effect.create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.8)  # MÃ¡s largo para ser Ã©pico
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_summon_visual() -> void:
	"""Efecto de invocaciÃ³n"""
	if not is_instance_valid(enemy):
		return
	
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 50
	effect.global_position = enemy.global_position
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)
	
	var anim = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)
	
	visual.draw.connect(func():
		# CÃ­rculo mÃ¡gico
		visual.draw_arc(Vector2.ZERO, 80, 0, TAU, 32, Color(0.5, 0, 0.8, 0.6 * (1.0 - anim)), 3.0)
		# PentÃ¡gono
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
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 50
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
			# ExpansiÃ³n
			var r = 50 * anim
			visual.draw_circle(Vector2.ZERO, r, Color(color.r, color.g, color.b, 0.5 * (1.0 - anim)))
		else:
			pass  # Bloque else
			# ContracciÃ³n
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
	"""Visual de nova arcana"""
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 50
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
		for i in range(4):
			var layer_r = r * (1.0 - i * 0.15)
			var a = (1.0 - anim) * (0.6 - i * 0.1)
			visual.draw_circle(Vector2.ZERO, layer_r, Color(0.8, 0.3, 1, a * 0.5))
			visual.draw_arc(Vector2.ZERO, layer_r, 0, TAU, 32, Color(0.9, 0.5, 1, a), 2.0)
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
	"""Visual de aura de maldiciÃ³n"""
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 50
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
		visual.draw_circle(Vector2.ZERO, radius * pulse, Color(0.2, 0, 0.2, 0.3 * (1.0 - anim)))
		# SÃ­mbolos de maldiciÃ³n
		var symbol_count = 6
		for i in range(symbol_count):
			var angle = (TAU / symbol_count) * i + anim * PI * 2
			var pos = Vector2(cos(angle), sin(angle)) * radius * 0.7
			visual.draw_circle(pos, 5, Color(0.5, 0, 0.5, 0.8 * (1.0 - anim)))
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
	"""Visual de void pull - espiral hacia el centro"""
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 50
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
				visual.draw_polyline(points, Color(0.6, 0.1, 0.9, 0.6 * (1.0 - anim)), 2.0)
		
		# Centro oscuro
		visual.draw_circle(Vector2.ZERO, 20 * (1.0 + anim * 0.5), Color(0.1, 0, 0.2, 0.8 * (1.0 - anim * 0.5)))
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
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 50
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
	
	visual.draw.connect(func():
		var width = 30 * (0.8 + sin(anim * PI * 8) * 0.2)
		# Beam principal
		visual.draw_rect(Rect2(0, -width/2, length, width), Color(0.5, 0, 0.8, 0.7))
		# NÃºcleo brillante
		visual.draw_rect(Rect2(0, -width/4, length, width/2), Color(0.8, 0.5, 1, 0.9))
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
	"""Visual de escudo de runas"""
	if not is_instance_valid(enemy):
		return
	
	# El efecto se adjunta al enemigo
	var visual = Node2D.new()
	visual.name = "RuneShieldVisual"
	enemy.add_child(visual)
	
	var anim = 0.0
	
	visual.draw.connect(func():
		# HexÃ¡gono de escudo
		var radius = 40
		var points = PackedVector2Array()
		for i in range(7):
			var angle = (TAU / 6) * i + anim * 0.5
			points.append(Vector2(cos(angle), sin(angle)) * radius)
		visual.draw_polyline(points, Color(0.9, 0.8, 0.2, 0.8), 3.0)
		
		# Runas en cada vÃ©rtice
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
	
	# Auto-destruir despuÃ©s de 10 segundos
	get_tree().create_timer(10.0).timeout.connect(func():
		if is_instance_valid(visual):
			visual.queue_free()
	)

func _spawn_rune_prison_visual(pos: Vector2, duration: float) -> void:
	"""Visual de prisiÃ³n de runas"""
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 55  # Encima del jugador
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
	
	var visual = Node2D.new()
	visual.name = "CounterStanceVisual"
	enemy.add_child(visual)
	
	var anim = 0.0
	
	visual.draw.connect(func():
		# Aura amenazante
		var pulse = 0.8 + sin(anim * 10) * 0.2
		visual.draw_arc(Vector2.ZERO, 35 * pulse, 0, TAU, 16, Color(1, 0.3, 0.1, 0.6), 3.0)
		# SÃ­mbolo de espada
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
	
	# Auto-destruir despuÃ©s de 2 segundos
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(visual):
			visual.queue_free()
	)

func _spawn_ground_slam_visual(center: Vector2, radius: float) -> void:
	"""Visual de golpe de tierra Ã‰PICO"""
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 60
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
		
		# Ondas de choque - MÃS Y MÃS GRUESAS
		for i in range(5):
			var r = expand_radius * (0.3 + i * 0.18)
			var a = (1.0 - anim) * (0.85 - i * 0.14)
			visual.draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(0.65, 0.45, 0.2, a), 6.0 - i)
		
		# Relleno de tierra
		for i in range(3):
			var fill_r = expand_radius * (0.8 - i * 0.2)
			var fill_a = (1.0 - anim) * (0.35 - i * 0.08)
			visual.draw_circle(Vector2.ZERO, fill_r, Color(0.5, 0.35, 0.15, fill_a))
		
		# Grietas radiales - MÃS Y MÃS DETALLADAS
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
			
			# Dibujar roca como polÃ­gono irregular
			var rock_points = PackedVector2Array([
				rock_pos + Vector2(-rock_size, -rock_size * 0.5),
				rock_pos + Vector2(rock_size * 0.3, -rock_size * 0.8),
				rock_pos + Vector2(rock_size, rock_size * 0.2),
				rock_pos + Vector2(-rock_size * 0.2, rock_size * 0.6)
			])
			visual.draw_colored_polygon(rock_points, Color(0.45, 0.35, 0.25, (1.0 - anim) * 0.9))
		
		# Polvo levantÃ¡ndose
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
	, 0.0, 1.0, 0.7)  # MÃ¡s largo
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_charge_warning_visual(pos: Vector2, direction: Vector2) -> void:
	"""Visual de advertencia de carga"""
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 55  # Muy visible - es advertencia
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
		# Flecha indicando direcciÃ³n
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
	"""Visual de advertencia de meteoro"""
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 55  # Muy visible - es advertencia
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
		# CÃ­rculo de advertencia parpadeante
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
	"""Impacto real del meteoro con daÃ±o"""
	if not is_instance_valid(player):
		return
	
	# Verificar daÃ±o
	var dist = pos.distance_to(player.global_position)
	if dist <= radius:
		if player.has_method("take_damage"):
			player.take_damage(damage)
		if player.has_method("apply_burn"):
			player.apply_burn(damage * 0.3, 3.0)
	
	# Visual de impacto
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
		# ExplosiÃ³n de fuego
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
	"""Visual de enrage del boss"""
	if not is_instance_valid(enemy):
		return
	
	var effect = Node2D.new()
	effect.top_level = true
	effect.z_index = 55
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

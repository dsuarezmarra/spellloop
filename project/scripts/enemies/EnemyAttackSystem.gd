# EnemyAttackSystem.gd
# Sistema de ataque para enemigos - Soporta todos los arquetipos
# Gestiona cooldowns, targeting y ejecución de ataques

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
	enemy = get_parent()
	# Precargar script de proyectil
	EnemyProjectileScript = load("res://scripts/enemies/EnemyProjectile.gd")
	print("[EnemyAttackSystem] Inicializado para: %s" % enemy.name)

func initialize(p_attack_cooldown: float, p_attack_range: float, p_damage: int, p_is_ranged: bool = false, p_projectile_scene: PackedScene = null) -> void:
	"""Configurar parámetros de ataque"""
	attack_cooldown = p_attack_cooldown
	attack_range = p_attack_range
	attack_damage = p_damage
	is_ranged = p_is_ranged
	projectile_scene = p_projectile_scene
	print("[EnemyAttackSystem] Configurado: cooldown=%.2f, range=%.0f, damage=%d, ranged=%s" % [attack_cooldown, attack_range, attack_damage, is_ranged])

func initialize_full(config: Dictionary) -> void:
	"""Inicialización completa con todos los parámetros"""
	attack_cooldown = config.get("attack_cooldown", 1.5)
	attack_range = config.get("attack_range", 32.0)
	attack_damage = config.get("damage", 5)
	is_ranged = config.get("is_ranged", false)
	archetype = config.get("archetype", "melee")
	element_type = config.get("element_type", "physical")
	special_abilities = config.get("special_abilities", [])
	modifiers = config.get("modifiers", {})
	
	# Configurar según arquetipo
	match archetype:
		"aoe":
			aoe_radius = modifiers.get("aoe_radius", 100.0)
			aoe_damage_multiplier = modifiers.get("aoe_damage_mult", 0.7)
		"breath":
			breath_cone_angle = modifiers.get("breath_angle", 45.0)
			breath_range = modifiers.get("breath_range", 150.0)
		"multi":
			multi_attack_count = modifiers.get("attack_count", 3)
	
	print("[EnemyAttackSystem] Full config: %s (arch=%s, elem=%s)" % [enemy.name, archetype, element_type])

func _process(delta: float) -> void:
	"""Procesar cooldown y ataque automático"""
	if not enemy or not is_instance_valid(enemy):
		return
	
	# Obtener player si no lo tiene
	if not player or not is_instance_valid(player):
		player = _get_player()
		if not player:
			# Solo debug una vez cada 60 frames para no saturar
			if Engine.get_process_frames() % 60 == 0:
				print("[EnemyAttackSystem] ⚠️ No se encontró player para %s" % enemy.name)
			return
	
	# Decrementar cooldown
	if attack_timer > 0:
		attack_timer -= delta
	else:
		# Comprobar si el jugador está en rango
		if _player_in_range():
			_perform_attack()
			attack_timer = attack_cooldown

func _get_player() -> Node:
	"""Obtener referencia al jugador"""
	# Método 1: Desde el enemigo padre (más directo y fiable)
	if enemy and enemy.has_method("get") and enemy.get("player_ref"):
		return enemy.player_ref
	
	# Método 2: Buscar en GameManager
	if GameManager and GameManager.player_ref:
		return GameManager.player_ref
	
	# Método 3: Buscar por grupos
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	
	# Método 4: Buscar en la estructura del árbol
	var tree = Engine.get_main_loop()
	if tree and tree.root:
		# Buscar Game/PlayerContainer/SpellloopPlayer
		var sp = tree.root.get_node_or_null("Game/PlayerContainer/SpellloopPlayer")
		if sp:
			return sp
	
	return null

func _player_in_range() -> bool:
	"""Comprobar si el jugador está dentro del rango de ataque"""
	if not enemy or not player:
		return false
	
	var distance = enemy.global_position.distance_to(player.global_position)
	var in_range = distance <= attack_range
	
	# Debug ocasional (cada 2 segundos aprox) para ver distancias
	#if Engine.get_process_frames() % 120 == 0:
	#	print("[EnemyAttackSystem] %s: dist=%.1f, range=%.1f, in_range=%s" % [enemy.name, distance, attack_range, in_range])
	
	return in_range

func _perform_attack() -> void:
	"""Ejecutar el ataque según arquetipo"""
	if not enemy or not player:
		return
	
	# Obtener arquetipo del enemigo padre si existe
	if enemy.has_method("get") and "archetype" in enemy:
		archetype = enemy.archetype
	if enemy.has_method("get") and "modifiers" in enemy:
		modifiers = enemy.modifiers
	if enemy.has_method("get") and "special_abilities" in enemy:
		special_abilities = enemy.special_abilities
	
	# Ejecutar ataque según arquetipo
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
			_perform_ranged_attack()  # Los teleporters también disparan
		"boss":
			_perform_boss_attack()
		_:
			# Melee por defecto
			if is_ranged:
				_perform_ranged_attack()
			else:
				_perform_melee_attack()

func _perform_melee_attack() -> void:
	"""Ataque melee: daño directo al jugador"""
	if not player.has_method("take_damage"):
		return
	
	var elem = _get_enemy_element()
	player.call("take_damage", attack_damage, elem)
	print("[EnemyAttackSystem] ⚔️ %s atacó melee a player por %d daño (%s)" % [enemy.name, attack_damage, elem])
	
	# Aplicar efectos según arquetipo y elemento
	_apply_melee_effects()
	
	# Emitir señal
	attacked_player.emit(attack_damage, true)
	
	# Efecto visual
	_emit_melee_effect()

func _apply_melee_effects() -> void:
	"""Aplicar efectos de estado según arquetipo y elemento"""
	var elem = _get_enemy_element()
	
	# Efectos por arquetipo
	match archetype:
		"debuffer":  # Araña Venenosa
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
				player.apply_curse(0.3, 4.0)  # -30% curación por 4s
		"charger":  # Caballero del Vacío - stun en carga
			# El stun se aplica en el ataque de carga, no en melee normal
			pass
	
	# Efectos por elemento
	match elem:
		"fire":
			if player.has_method("apply_burn"):
				player.apply_burn(3.0, 2.0)  # 3 daño/tick por 2s
		"ice":
			if player.has_method("apply_slow"):
				player.apply_slow(0.25, 2.0)  # 25% slow por 2s
		"dark", "void":
			if player.has_method("apply_weakness"):
				player.apply_weakness(0.2, 3.0)  # +20% daño recibido por 3s
		"poison":
			if player.has_method("apply_poison"):
				player.apply_poison(2.0, 4.0)

func _perform_ranged_attack() -> void:
	"""Ataque ranged: disparar proyectil al jugador"""
	# Crear proyectil dinámicamente si no hay escena
	if not projectile_scene and EnemyProjectileScript:
		_create_dynamic_projectile()
		return
	
	if not projectile_scene:
		print("[EnemyAttackSystem] Warning: %s no tiene projectile_scene ni script" % enemy.name)
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
	
	# Configurar proyectil
	if projectile.has_method("initialize"):
		projectile.initialize(direction, projectile_speed, attack_damage, 5.0, element_type)
	else:
		# Asignación directa
		if "direction" in projectile:
			projectile.direction = direction
		if "speed" in projectile:
			projectile.speed = projectile_speed
		if "damage" in projectile:
			projectile.damage = attack_damage
	
	# Añadir al árbol
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(projectile)
	else:
		get_tree().root.add_child(projectile)
	
	print("[EnemyAttackSystem] 🎯 %s disparó proyectil hacia player" % enemy.name)
	attacked_player.emit(attack_damage, false)

func _create_dynamic_projectile() -> void:
	"""Crear proyectil dinámico usando EnemyProjectile.gd"""
	var projectile = Area2D.new()
	projectile.set_script(EnemyProjectileScript)
	projectile.global_position = enemy.global_position
	
	var direction = (player.global_position - enemy.global_position).normalized()
	
	# Determinar elemento según enemigo
	var elem = _get_enemy_element()
	
	# Añadir al árbol ANTES de initialize (necesario para _ready)
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(projectile)
	else:
		get_tree().root.add_child(projectile)
	
	# Inicializar
	if projectile.has_method("initialize"):
		projectile.initialize(direction, projectile_speed, attack_damage, 5.0, elem)
	
	print("[EnemyAttackSystem] 🎯 %s disparó proyectil dinámico (%s)" % [enemy.name, elem])
	attacked_player.emit(attack_damage, false)

func _perform_aoe_attack() -> void:
	"""Ataque de área: daño en zona alrededor del enemigo o player"""
	if not player:
		return
	
	# Posición del AoE (en el player o en el enemigo)
	var aoe_center = player.global_position
	var radius = modifiers.get("aoe_radius", 100.0)
	var aoe_damage = int(attack_damage * modifiers.get("aoe_damage_mult", 1.0))
	var elem = _get_enemy_element()
	
	# Verificar si player está en rango del AoE
	var dist_to_player = aoe_center.distance_to(player.global_position)
	if dist_to_player <= radius:
		if player.has_method("take_damage"):
			player.call("take_damage", aoe_damage, elem)
			print("[EnemyAttackSystem] 💥 %s AoE hit player por %d daño (%s, radio=%.0f)" % [enemy.name, aoe_damage, elem, radius])
			attacked_player.emit(aoe_damage, false)
			# Aplicar efectos según elemento del AoE
			_apply_aoe_effects()
	
	# Efecto visual del AoE
	_spawn_aoe_visual(enemy.global_position, radius)

func _apply_aoe_effects() -> void:
	"""Aplicar efectos de estado en ataques AoE"""
	var elem = _get_enemy_element()
	
	# Señor de las Llamas - Burn
	if elem == "fire":
		if player.has_method("apply_burn"):
			player.apply_burn(5.0, 3.0)  # 5 daño/tick por 3s
			print("[EnemyAttackSystem] 🔥 AoE aplica Burn!")
	# Reina del Hielo - Slow/Freeze
	elif elem == "ice":
		if player.has_method("apply_slow"):
			player.apply_slow(0.4, 3.0)  # 40% slow por 3s
			print("[EnemyAttackSystem] ❄️ AoE aplica Slow!")
	# Titán Arcano - Stun
	elif "arcane" in enemy.name.to_lower() or "titan" in enemy.name.to_lower():
		if player.has_method("apply_stun"):
			player.apply_stun(0.5)  # 0.5s stun
			print("[EnemyAttackSystem] ⚡ AoE aplica Stun!")

func _perform_breath_attack() -> void:
	"""Ataque de aliento: daño en cono hacia el player"""
	if not player:
		return
	
	var direction = (player.global_position - enemy.global_position).normalized()
	var cone_angle = deg_to_rad(modifiers.get("breath_angle", 45.0))
	var cone_range = modifiers.get("breath_range", 150.0)
	var breath_damage = int(attack_damage * modifiers.get("breath_damage_mult", 1.2))
	
	# Verificar si player está en el cono
	var to_player = player.global_position - enemy.global_position
	var dist = to_player.length()
	var angle_to_player = direction.angle_to(to_player.normalized())
	
	if dist <= cone_range and abs(angle_to_player) <= cone_angle / 2:
		if player.has_method("take_damage"):
			player.take_damage(breath_damage)
			print("[EnemyAttackSystem] 🐉 %s Breath hit player por %d daño" % [enemy.name, breath_damage])
			attacked_player.emit(breath_damage, false)
			# Aplicar efectos de breath
			_apply_breath_effects()
	
	# Efecto visual del breath
	_spawn_breath_visual(enemy.global_position, direction, cone_range)

func _apply_breath_effects() -> void:
	"""Aplicar efectos del ataque breath"""
	var elem = _get_enemy_element()
	
	# Dragón Etéreo es de tipo 'fire' o 'etereo'
	# Aplicar burn siempre en breath de dragón
	if player.has_method("apply_burn"):
		player.apply_burn(6.0, 2.5)  # 6 daño/tick por 2.5s
		print("[EnemyAttackSystem] 🔥 Breath aplica Burn!")

func _perform_multi_attack() -> void:
	"""Ataque múltiple: varios proyectiles o ataques en secuencia"""
	var count = modifiers.get("attack_count", 3)
	var spread_angle = deg_to_rad(modifiers.get("spread_angle", 30.0))
	var base_direction = (player.global_position - enemy.global_position).normalized()
	
	for i in range(count):
		# Calcular ángulo para este proyectil
		var angle_offset = spread_angle * (float(i) / float(count - 1) - 0.5) if count > 1 else 0.0
		var direction = base_direction.rotated(angle_offset)
		
		# Crear proyectil con delay visual
		_spawn_multi_projectile(direction, i * 0.1)
	
	print("[EnemyAttackSystem] 🔥 %s Multi-attack: %d proyectiles" % [enemy.name, count])
	attacked_player.emit(attack_damage, false)

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE BOSS COMPLETO - Habilidades escaladas por minuto de aparición
# ═══════════════════════════════════════════════════════════════════════════════

# Tracking de cooldowns de habilidades de boss (por enemigo)
var boss_ability_cooldowns: Dictionary = {}  # {ability_name: tiempo_restante}
var boss_current_phase: int = 1
var boss_enraged: bool = false
var boss_fire_trail_active: bool = false
var boss_damage_aura_timer: float = 0.0

# Sistema de habilidades limitadas por minuto
var boss_scaling_config: Dictionary = {}     # Configuración de escalado del minuto
var boss_unlocked_abilities: Array = []      # Habilidades desbloqueadas para este boss
var boss_combo_count: int = 0                # Habilidades usadas en el combo actual
var boss_combo_timer: float = 0.0            # Timer para resetear combo
var boss_global_cooldown: float = 0.0        # Cooldown global entre habilidades

func _perform_boss_attack() -> void:
	"""Sistema de ataque de boss con habilidades limitadas según minuto de spawn"""
	if not enemy or not player:
		return
	
	# Inicializar sistema si es necesario
	_init_boss_system()
	
	# Actualizar timers
	var delta = get_process_delta_time()
	if boss_global_cooldown > 0:
		boss_global_cooldown -= delta
	if boss_combo_timer > 0:
		boss_combo_timer -= delta
	else:
		boss_combo_count = 0  # Resetear combo si pasó el tiempo
	
	# Actualizar fase del boss según HP
	_update_boss_phase()
	
	# Actualizar efectos pasivos (auras, trails)
	_update_boss_passive_effects()
	
	# Verificar si puede atacar (global cooldown)
	if boss_global_cooldown > 0:
		return
	
	# Verificar límite de combo
	var max_combo = boss_scaling_config.get("max_combo", 1)
	if boss_combo_count >= max_combo:
		# Esperar a que se resetee el combo
		return
	
	# Obtener habilidades disponibles (desbloqueadas y fuera de cooldown)
	var available_abilities = _get_available_boss_abilities()
	
	if available_abilities.is_empty():
		# Ataque básico si no hay habilidades disponibles
		_perform_boss_melee_attack()
		boss_global_cooldown = 1.5
		return
	
	# Seleccionar y ejecutar habilidad
	var selected_ability = _select_boss_ability(available_abilities)
	_execute_boss_ability(selected_ability)
	
	# Actualizar cooldowns
	_apply_ability_cooldown(selected_ability)
	
	# Actualizar combo
	boss_combo_count += 1
	var combo_delay = boss_scaling_config.get("combo_delay", 2.0)
	boss_combo_timer = 4.0  # Ventana de combo
	boss_global_cooldown = combo_delay  # Delay hasta la siguiente habilidad
	
	print("[Boss] 👹 %s usó %s (combo %d/%d, fase %d)" % [
		enemy.name, selected_ability, boss_combo_count, max_combo, boss_current_phase
	])

func _init_boss_system() -> void:
	"""Inicializar sistema de boss con configuración de escalado"""
	if not boss_scaling_config.is_empty():
		return
	
	# Obtener minuto de spawn del boss
	var spawn_minute = 5
	if enemy and "enemy_data" in enemy:
		spawn_minute = enemy.enemy_data.get("spawn_minute", 5)
	elif modifiers.has("spawn_minute"):
		spawn_minute = modifiers.get("spawn_minute", 5)
	
	# Obtener configuración de escalado
	boss_scaling_config = SpawnConfig.get_boss_scaling_for_minute(spawn_minute)
	
	# Determinar habilidades desbloqueadas
	var max_abilities = boss_scaling_config.get("abilities_unlocked", 2)
	boss_unlocked_abilities = _get_prioritized_abilities(max_abilities)
	
	# Inicializar cooldowns solo para habilidades desbloqueadas
	for ability in boss_unlocked_abilities:
		boss_ability_cooldowns[ability] = 0.0
	
	print("[Boss] 👹 Inicializado para minuto %d: %d habilidades, combo max %d" % [
		spawn_minute, boss_unlocked_abilities.size(), boss_scaling_config.get("max_combo", 1)
	])
	print("[Boss] 👹 Habilidades: %s" % str(boss_unlocked_abilities))

func _get_prioritized_abilities(max_count: int) -> Array:
	"""Obtener las habilidades priorizadas para desbloquear"""
	# Prioridad de habilidades (las básicas primero, las más poderosas después)
	var priority_order = {
		# Conjurador - básicas primero
		"arcane_barrage": 1,
		"summon_minions": 3,
		"teleport_strike": 2,
		"arcane_nova": 4,
		"curse_aura": 5,
		
		# Corazón del Vacío
		"void_orbs": 1,
		"void_pull": 2,
		"void_explosion": 3,
		"reality_tear": 4,
		"void_beam": 5,
		"damage_aura": 6,
		
		# Guardián de Runas
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
	"""Actualizar la fase del boss según su HP actual"""
	if not enemy or not "current_hp" in enemy or not "max_hp" in enemy:
		return
	
	var hp_percent = float(enemy.current_hp) / float(enemy.max_hp)
	
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

func _on_boss_phase_change(old_phase: int, new_phase: int) -> void:
	"""Evento cuando el boss cambia de fase"""
	print("[EnemyAttackSystem] 👹💀 %s CAMBIÓ A FASE %d!" % [enemy.name, new_phase])
	
	# Efecto visual de cambio de fase
	_spawn_phase_change_effect()
	
	# Algunos bosses tienen efectos especiales al cambiar de fase
	var enemy_id = enemy.get("enemy_id") if "enemy_id" in enemy else ""
	
	# Minotauro se enfurece en fase 3
	if "minotauro" in enemy_id.to_lower() and new_phase == 3:
		_activate_boss_enrage()
	
	# Corazón del Vacío activa aura de daño permanente en fase 2+
	if "corazon" in enemy_id.to_lower() and new_phase >= 2:
		boss_damage_aura_timer = 999.0  # Aura permanente
	
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
		
		# Verificar si está disponible
		if boss_ability_cooldowns.get(ability, 0) <= 0:
			# Algunas habilidades solo están disponibles en ciertas fases
			if _is_ability_available_in_phase(ability):
				available.append(ability)
	
	return available

func _is_ability_available_in_phase(ability: String) -> bool:
	"""Verificar si una habilidad está disponible en la fase actual"""
	# Habilidades más poderosas solo en fases avanzadas
	match ability:
		"void_beam", "meteor_call", "ground_slam":
			return boss_current_phase >= 2
		"enrage", "fire_trail", "damage_aura":
			return boss_current_phase >= 3
		_:
			return true

func _select_boss_ability(available: Array) -> String:
	"""Seleccionar habilidad con pesos basados en situación"""
	if available.is_empty():
		return ""
	
	var dist = enemy.global_position.distance_to(player.global_position)
	var weights = {}
	
	for ability in available:
		var weight = 1.0
		
		# Ajustar peso según distancia
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
		
		# Bonus en fases avanzadas para habilidades más agresivas
		if boss_current_phase >= 2:
			if ability in ["void_explosion", "fire_stomp", "charge_attack", "meteor_call"]:
				weight *= 1.5
		
		weights[ability] = weight
	
	# Selección ponderada
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
	"""Ejecutar una habilidad de boss específica"""
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
		
		# El Corazón del Vacío
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
		
		# El Guardián de Runas
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
			# Habilidad no implementada, usar ataque básico
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

# ═══════════════════════════════════════════════════════════════════════════════
# HABILIDADES DE EL CONJURADOR PRIMIGENIO
# ═══════════════════════════════════════════════════════════════════════════════

func _boss_arcane_barrage() -> void:
	"""Ráfaga de múltiples proyectiles arcanos"""
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
		_spawn_boss_projectile(proj_dir, damage, "arcane", 0.05 * i)
	
	print("[EnemyAttackSystem] ✨ Arcane Barrage: %d proyectiles" % count)

func _boss_summon_minions() -> void:
	"""Invocar enemigos menores"""
	var count = modifiers.get("summon_count", 2)
	var tier = modifiers.get("summon_tier", 1)
	
	if boss_current_phase >= 2:
		count = modifiers.get("phase_2_summon_count", 3)
	if boss_current_phase >= 3:
		tier = modifiers.get("phase_3_summon_tier", 2)
	
	# Efecto visual de invocación
	_spawn_summon_visual()
	
	# Notificar al spawner para crear enemigos
	var spawner = _get_enemy_spawner()
	if spawner and spawner.has_method("spawn_minions_around"):
		spawner.spawn_minions_around(enemy.global_position, count, tier)
		print("[EnemyAttackSystem] 👹 Summon: %d minions tier %d" % [count, tier])
	else:
		print("[EnemyAttackSystem] ⚠️ No se encontró spawner para summon")

func _boss_teleport_strike() -> void:
	"""Teleport hacia el jugador + ataque inmediato"""
	var teleport_range = modifiers.get("teleport_range", 200.0)
	var damage_mult = modifiers.get("teleport_damage_mult", 1.5)
	
	# Calcular posición de teleport (detrás del jugador)
	var to_player = (player.global_position - enemy.global_position).normalized()
	var teleport_pos = player.global_position - to_player * 50  # Aparecer cerca
	
	# Efecto de desaparición
	_spawn_teleport_effect(enemy.global_position, false)
	
	# Mover al enemigo
	enemy.global_position = teleport_pos
	
	# Efecto de aparición
	_spawn_teleport_effect(teleport_pos, true)
	
	# Ataque inmediato con daño bonus
	if player.has_method("take_damage"):
		var damage = int(attack_damage * damage_mult)
		player.take_damage(damage)
		attacked_player.emit(damage, true)
		print("[EnemyAttackSystem] ⚡ Teleport Strike por %d daño" % damage)

func _boss_arcane_nova() -> void:
	"""Nova de daño arcano en área"""
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
	print("[EnemyAttackSystem] 💜 Arcane Nova por %d daño (radio %.0f)" % [damage, radius])

func _boss_curse_aura() -> void:
	"""Aplicar aura de maldición que reduce curación"""
	var radius = modifiers.get("curse_radius", 150.0)
	var reduction = modifiers.get("curse_reduction", 0.5)
	var duration = modifiers.get("curse_duration", 8.0)
	
	var dist = enemy.global_position.distance_to(player.global_position)
	if dist <= radius:
		if player.has_method("apply_curse"):
			player.apply_curse(reduction, duration)
			print("[EnemyAttackSystem] ☠️ Curse Aura: -%.0f%% curación por %.1fs" % [reduction * 100, duration])
	
	# Visual
	_spawn_curse_aura_visual(enemy.global_position, radius)

# ═══════════════════════════════════════════════════════════════════════════════
# HABILIDADES DE EL CORAZÓN DEL VACÍO
# ═══════════════════════════════════════════════════════════════════════════════

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
			print("[EnemyAttackSystem] 🌀 Void Pull activado")
		else:
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
	
	print("[EnemyAttackSystem] 💜 Void Orbs: %d orbes perseguidores" % count)

func _boss_reality_tear() -> void:
	"""Crear zona de daño persistente"""
	var radius = modifiers.get("tear_radius", 80.0)
	var damage = modifiers.get("tear_damage", 15)
	var duration = modifiers.get("tear_duration", 6.0)
	
	# Crear en la posición del jugador
	_spawn_damage_zone(player.global_position, radius, damage, duration, "dark")
	print("[EnemyAttackSystem] 🌌 Reality Tear creado")

func _boss_void_beam() -> void:
	"""Rayo canalizado de alto daño"""
	var damage = modifiers.get("beam_damage", 30)
	var duration = modifiers.get("beam_duration", 3.0)
	var width = modifiers.get("beam_width", 40.0)
	
	# Este ataque es canalizado - simplificado para aplicar daño por tick
	var direction = (player.global_position - enemy.global_position).normalized()
	
	# Crear visual del beam
	_spawn_void_beam_visual(enemy.global_position, direction, 300.0, duration)
	
	# Aplicar daño inicial
	if player.has_method("take_damage"):
		player.take_damage(damage)
		attacked_player.emit(damage, false)
	
	print("[EnemyAttackSystem] 💜 Void Beam: %d DPS por %.1fs" % [damage, duration])

# ═══════════════════════════════════════════════════════════════════════════════
# HABILIDADES DE EL GUARDIÁN DE RUNAS
# ═══════════════════════════════════════════════════════════════════════════════

func _boss_rune_shield() -> void:
	"""Activar escudo que absorbe hits"""
	var charges = modifiers.get("shield_charges", 4)
	var duration = modifiers.get("shield_duration", 10.0)
	
	if boss_current_phase >= 2:
		charges = modifiers.get("phase_2_shield_charges", 6)
	
	# Aplicar escudo al enemigo
	if enemy.has_method("apply_shield"):
		enemy.apply_shield(charges, duration)
		print("[EnemyAttackSystem] 🛡️ Rune Shield: %d cargas por %.1fs" % [charges, duration])
	
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
	
	# Daño al escapar (al final)
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(player) and player.has_method("take_damage"):
			player.take_damage(damage)
	)
	
	# Visual
	_spawn_rune_prison_visual(player.global_position, duration)
	print("[EnemyAttackSystem] ⛓️ Rune Prison: %.1fs" % duration)

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
	print("[EnemyAttackSystem] ⚔️ Counter Stance: %.1fs window, x%.1f daño" % [window, damage_mult])

func _boss_rune_barrage() -> void:
	"""Múltiples runas disparadas"""
	var count = modifiers.get("barrage_count", 6)
	var damage = modifiers.get("barrage_damage", 20)
	
	var direction = (player.global_position - enemy.global_position).normalized()
	var spread_rad = deg_to_rad(40.0)
	
	for i in range(count):
		var angle_offset = spread_rad * (float(i) / float(count - 1) - 0.5) if count > 1 else 0.0
		var proj_dir = direction.rotated(angle_offset)
		_spawn_boss_projectile(proj_dir, damage, "arcane", 0.08 * i)
	
	print("[EnemyAttackSystem] ✨ Rune Barrage: %d proyectiles" % count)

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
	print("[EnemyAttackSystem] 💥 Ground Slam por %d daño" % damage)

# ═══════════════════════════════════════════════════════════════════════════════
# HABILIDADES DE MINOTAURO DE FUEGO
# ═══════════════════════════════════════════════════════════════════════════════

func _boss_charge_attack() -> void:
	"""Carga devastadora hacia el jugador"""
	var charge_speed = modifiers.get("charge_speed", 450.0)
	var damage_mult = modifiers.get("charge_damage_mult", 2.5)
	var stun = modifiers.get("charge_stun", 0.8)
	
	if boss_current_phase >= 2:
		damage_mult = modifiers.get("phase_2_charge_damage_mult", 3.0)
	
	# Calcular dirección y distancia
	var direction = (player.global_position - enemy.global_position).normalized()
	var charge_distance = enemy.global_position.distance_to(player.global_position) + 100
	
	# Marcar que el boss está cargando
	if enemy.has_method("start_charge"):
		enemy.start_charge(direction, charge_speed, charge_distance)
	
	# Visual de preparación
	_spawn_charge_warning_visual(enemy.global_position, direction)
	
	# El daño se aplica cuando el boss impacta (manejado por el enemy)
	# Aquí aplicamos el efecto si está cerca
	var dist = enemy.global_position.distance_to(player.global_position)
	if dist < 80:
		var damage = int(attack_damage * damage_mult)
		if player.has_method("take_damage"):
			player.take_damage(damage)
			attacked_player.emit(damage, true)
		if player.has_method("apply_stun"):
			player.apply_stun(stun)
	
	print("[EnemyAttackSystem] 🐂 Charge Attack: velocidad %.0f" % charge_speed)

func _boss_flame_breath() -> void:
	"""Aliento de fuego en cono"""
	var angle = modifiers.get("breath_angle", 50.0)
	var range_dist = modifiers.get("breath_range", 180.0)
	var damage = modifiers.get("breath_damage", 25)
	var duration = modifiers.get("breath_duration", 2.0)
	
	if boss_current_phase >= 3:
		damage = modifiers.get("phase_3_breath_damage", 40)
	
	var direction = (player.global_position - enemy.global_position).normalized()
	
	# Verificar si player está en el cono
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
	print("[EnemyAttackSystem] 🔥 Flame Breath: %d daño en cono" % damage)

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
		
		# Meteoro real después del delay
		get_tree().create_timer(delay + i * 0.2).timeout.connect(func():
			_spawn_meteor_impact(target_pos, radius, damage)
		)
	
	print("[EnemyAttackSystem] ☄️ Meteor Call: %d meteoros" % count)

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
		# Fallback: modificar stats directamente
		attack_damage = int(attack_damage * (1 + damage_bonus))
		if "base_speed" in enemy:
			enemy.base_speed *= (1 + speed_bonus)
	
	# Visual
	_spawn_enrage_visual()
	print("[EnemyAttackSystem] 🔥💢 BOSS ENRAGED! +%.0f%% daño, +%.0f%% velocidad" % [damage_bonus * 100, speed_bonus * 100])

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
	
	var boss_damage = int(attack_damage * 1.2)  # Bosses hacen más daño
	player.take_damage(boss_damage)
	print("[EnemyAttackSystem] 👹 %s (Boss) melee devastador por %d daño" % [enemy.name, boss_damage])
	
	# Aplicar efecto según el boss
	_apply_boss_melee_effects()
	
	attacked_player.emit(boss_damage, true)
	
	# Efecto visual de impacto de boss (más grande)
	_spawn_boss_impact_effect()

func _apply_boss_melee_effects() -> void:
	"""Efectos de estado en ataques melee de boss"""
	var enemy_name_lower = enemy.name.to_lower()
	
	# Minotauro - Burn
	if "minotauro" in enemy_name_lower or "fuego" in enemy_name_lower:
		if player.has_method("apply_burn"):
			player.apply_burn(8.0, 3.0)  # 8 daño/tick por 3s
	# Corazón del Vacío - Weakness
	elif "corazon" in enemy_name_lower or "vacio" in enemy_name_lower:
		if player.has_method("apply_weakness"):
			player.apply_weakness(0.3, 4.0)  # +30% daño recibido por 4s
	# Guardián de Runas - Stun breve
	elif "guardian" in enemy_name_lower or "runas" in enemy_name_lower:
		if player.has_method("apply_stun"):
			player.apply_stun(0.3)  # 0.3s stun
	# Conjurador - Curse
	elif "conjurador" in enemy_name_lower:
		if player.has_method("apply_curse"):
			player.apply_curse(0.4, 5.0)  # -40% curación por 5s

func _perform_boss_void_explosion() -> void:
	"""El Corazón del Vacío - explosión de vacío"""
	if not player:
		return
	
	var explosion_radius = modifiers.get("explosion_radius", 150.0)
	var explosion_damage = modifiers.get("explosion_damage", 60)
	
	# Verificar si player está en rango
	var dist = enemy.global_position.distance_to(player.global_position)
	if dist <= explosion_radius:
		if player.has_method("take_damage"):
			player.take_damage(explosion_damage)
			print("[EnemyAttackSystem] 💜 %s Void Explosion por %d daño!" % [enemy.name, explosion_damage])
			attacked_player.emit(explosion_damage, false)
			# Aplicar Weakness fuerte
			if player.has_method("apply_weakness"):
				player.apply_weakness(0.4, 5.0)  # +40% daño recibido por 5s
				print("[EnemyAttackSystem] 💜 Void Explosion aplica Weakness!")
	
	# Visual de explosión de vacío
	_spawn_void_explosion_visual(enemy.global_position, explosion_radius)

func _perform_boss_rune_blast() -> void:
	"""El Guardián de Runas - explosión de runas"""
	if not player:
		return
	
	var blast_radius = modifiers.get("blast_radius", 100.0)
	var blast_damage = modifiers.get("blast_damage", 45)
	
	var dist = enemy.global_position.distance_to(player.global_position)
	if dist <= blast_radius:
		if player.has_method("take_damage"):
			player.take_damage(blast_damage)
			print("[EnemyAttackSystem] ✨ %s Rune Blast por %d daño!" % [enemy.name, blast_damage])
			attacked_player.emit(blast_damage, false)
			# Aplicar Stun
			if player.has_method("apply_stun"):
				player.apply_stun(0.5)  # 0.5s stun
				print("[EnemyAttackSystem] ✨ Rune Blast aplica Stun!")
	
	# Visual de runas
	_spawn_rune_blast_visual(enemy.global_position, blast_radius)

func _perform_boss_fire_stomp() -> void:
	"""Minotauro de Fuego - pisotón de fuego"""
	if not player:
		return
	
	var stomp_radius = modifiers.get("stomp_radius", 120.0)
	var stomp_damage = modifiers.get("stomp_damage", 50)
	
	var dist = enemy.global_position.distance_to(player.global_position)
	if dist <= stomp_radius:
		if player.has_method("take_damage"):
			player.take_damage(stomp_damage)
			print("[EnemyAttackSystem] 🔥 %s Fire Stomp por %d daño!" % [enemy.name, stomp_damage])
			attacked_player.emit(stomp_damage, false)
			# Aplicar Burn fuerte + Stun breve
			if player.has_method("apply_burn"):
				player.apply_burn(10.0, 4.0)  # 10 daño/tick por 4s (muy fuerte)
				print("[EnemyAttackSystem] 🔥 Fire Stomp aplica Burn!")
			if player.has_method("apply_stun"):
				player.apply_stun(0.3)  # 0.3s stun
	
	# Visual de pisotón de fuego
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
	
	var tween = create_tween()
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
	"""Visual de explosión de vacío - púrpura con absorción"""
	var effect = Node2D.new()
	effect.global_position = center
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)
	
	var anim_progress = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)
	
	visual.draw.connect(func():
		# Explosión inversa (desde fuera hacia dentro, luego explota)
		var phase = anim_progress
		
		if phase < 0.4:
			# Fase de absorción
			var absorb_phase = phase / 0.4
			var absorb_radius = radius * (1.0 - absorb_phase * 0.7)
			visual.draw_circle(Vector2.ZERO, absorb_radius, Color(0.5, 0.1, 0.8, 0.4 * absorb_phase))
			
			# Partículas siendo absorbidas
			var particle_count = 12
			for i in range(particle_count):
				var angle = (TAU / particle_count) * i + phase * PI
				var dist = absorb_radius * (1.2 - absorb_phase * 0.5)
				var pos = Vector2(cos(angle), sin(angle)) * dist
				visual.draw_circle(pos, 4, Color(0.8, 0.3, 1.0, 0.8))
		else:
			# Fase de explosión
			var explode_phase = (phase - 0.4) / 0.6
			var explode_radius = radius * explode_phase
			
			# Ondas de vacío
			for i in range(4):
				var wave_r = explode_radius * (0.3 + i * 0.2)
				var wave_alpha = (1.0 - explode_phase) * (0.5 - i * 0.1)
				visual.draw_arc(Vector2.ZERO, wave_r, 0, TAU, 32, Color(0.6, 0.15, 0.9, wave_alpha), 3.0)
			
			# Centro oscuro
			visual.draw_circle(Vector2.ZERO, 20 * (1.0 - explode_phase), Color(0.2, 0, 0.3, 0.8))
	)
	
	var tween = create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.6)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_rune_blast_visual(center: Vector2, radius: float) -> void:
	"""Visual de explosión de runas - símbolos brillantes"""
	var effect = Node2D.new()
	effect.global_position = center
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)
	
	var anim_progress = 0.0
	var rune_count = 6
	var visual = Node2D.new()
	effect.add_child(visual)
	
	visual.draw.connect(func():
		var expand = radius * anim_progress
		
		# Círculo central de runas
		visual.draw_arc(Vector2.ZERO, expand * 0.5, 0, TAU, 32, Color(0.9, 0.8, 0.2, 0.6 * (1.0 - anim_progress)), 2.0)
		
		# Runas individuales que se expanden
		for i in range(rune_count):
			var angle = (TAU / rune_count) * i + anim_progress * PI * 0.5
			var dist = expand * (0.5 + anim_progress * 0.5)
			var pos = Vector2(cos(angle), sin(angle)) * dist
			
			# Dibujar runa como forma geométrica
			var rune_size = 10 * (1.0 - anim_progress * 0.5)
			var rune_points = PackedVector2Array([
				pos + Vector2(0, -rune_size),
				pos + Vector2(rune_size * 0.7, rune_size * 0.5),
				pos + Vector2(-rune_size * 0.7, rune_size * 0.5)
			])
			visual.draw_colored_polygon(rune_points, Color(1, 0.9, 0.3, 0.8 * (1.0 - anim_progress)))
			
			# Brillo alrededor
			visual.draw_circle(pos, rune_size * 1.5, Color(1, 1, 0.5, 0.3 * (1.0 - anim_progress)))
		
		# Onda de expansión final
		visual.draw_arc(Vector2.ZERO, expand, 0, TAU, 48, Color(1, 1, 1, 0.5 * (1.0 - anim_progress)), 3.0)
	)
	
	var tween = create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.4)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_fire_stomp_visual(center: Vector2, radius: float) -> void:
	"""Visual de pisotón de fuego - onda de fuego expansiva"""
	var effect = Node2D.new()
	effect.global_position = center
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)
	
	var anim_progress = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)
	
	visual.draw.connect(func():
		var expand = radius * anim_progress
		
		# Cráter central
		visual.draw_circle(Vector2.ZERO, expand * 0.3, Color(0.3, 0.1, 0, 0.7 * (1.0 - anim_progress)))
		
		# Anillos de fuego
		for i in range(4):
			var ring_r = expand * (0.4 + i * 0.2)
			var ring_alpha = (1.0 - anim_progress) * (0.7 - i * 0.15)
			var ring_color = Color(1.0 - i * 0.1, 0.4 - i * 0.1, 0.05, ring_alpha)
			visual.draw_arc(Vector2.ZERO, ring_r, 0, TAU, 32, ring_color, 4.0 - i)
		
		# Llamas alrededor
		var flame_count = 12
		for i in range(flame_count):
			var angle = (TAU / flame_count) * i
			var flame_dist = expand * 0.8
			var flame_base = Vector2(cos(angle), sin(angle)) * flame_dist
			
			# Altura de llama animada
			var flame_height = 15 * (1.0 - anim_progress) * (0.8 + sin(anim_progress * PI * 4 + i) * 0.2)
			var flame_width = 6
			
			var flame_tip = flame_base + Vector2(0, -flame_height)
			var flame_left = flame_base + Vector2(-flame_width, 0)
			var flame_right = flame_base + Vector2(flame_width, 0)
			
			visual.draw_colored_polygon(
				PackedVector2Array([flame_tip, flame_left, flame_right]),
				Color(1, 0.5, 0.1, 0.8 * (1.0 - anim_progress))
			)
	)
	
	var tween = create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.5)
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
	"""Crear un único proyectil"""
	if not EnemyProjectileScript or not is_instance_valid(enemy):
		return
	
	var projectile = Area2D.new()
	projectile.set_script(EnemyProjectileScript)
	projectile.global_position = enemy.global_position
	
	var elem = _get_enemy_element()
	var proj_damage = int(attack_damage * 0.7)  # Multi tiene menos daño por proyectil
	
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
	
	# Casos especiales primero (antes de la detección genérica)
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
	"""Crear efecto visual de AoE mejorado con animación de expansión"""
	var elem = _get_enemy_element()
	var base_color = _get_element_color(elem)
	var bright_color = Color(base_color.r + 0.3, base_color.g + 0.3, base_color.b + 0.3, 0.9)
	
	# Crear contenedor principal
	var container = Node2D.new()
	container.name = "AoE_Visual"
	container.global_position = center
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(container)
	
	# Variables de animación
	var anim_progress = 0.0
	var ring_count = 3
	
	# Nodo visual para dibujar
	var visual = Node2D.new()
	container.add_child(visual)
	
	visual.draw.connect(func():
		# Círculo de impacto central que se expande
		var expand_radius = radius * anim_progress
		
		# Círculo exterior con gradiente simulado (múltiples capas)
		for i in range(5):
			var layer_radius = expand_radius * (1.0 - i * 0.15)
			var layer_alpha = (0.4 - i * 0.08) * (1.0 - anim_progress * 0.5)
			if layer_radius > 0:
				visual.draw_circle(Vector2.ZERO, layer_radius, Color(base_color.r, base_color.g, base_color.b, layer_alpha))
		
		# Anillos de onda expansiva
		for i in range(ring_count):
			var ring_phase = fmod(anim_progress * 2 + i * 0.3, 1.0)
			var ring_radius = radius * ring_phase
			var ring_alpha = (1.0 - ring_phase) * 0.8
			if ring_radius > 0:
				visual.draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 32, Color(bright_color.r, bright_color.g, bright_color.b, ring_alpha), 2.0)
		
		# Partículas decorativas alrededor
		var particle_count = 8
		for i in range(particle_count):
			var angle = (TAU / particle_count) * i + anim_progress * PI
			var dist = expand_radius * 0.8
			var particle_pos = Vector2(cos(angle), sin(angle)) * dist
			var particle_size = 3.0 + sin(anim_progress * PI * 4 + i) * 2.0
			visual.draw_circle(particle_pos, particle_size, bright_color)
		
		# Borde exterior final
		if expand_radius > 0:
			visual.draw_arc(Vector2.ZERO, expand_radius, 0, TAU, 48, Color(1, 1, 1, 0.6 * (1.0 - anim_progress)), 3.0)
	)
	
	# Animación de expansión
	var tween = create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.4)
	
	# Fade out y destruir
	tween.tween_property(container, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		if is_instance_valid(container):
			container.queue_free()
	)

func _spawn_breath_visual(origin: Vector2, direction: Vector2, range_dist: float) -> void:
	"""Crear efecto visual de breath attack mejorado con animación de expansión"""
	var container = Node2D.new()
	container.name = "Breath_Visual"
	container.global_position = origin
	container.rotation = direction.angle()
	
	var elem = _get_enemy_element()
	var base_color = _get_element_color(elem)
	var bright_color = Color(base_color.r + 0.4, base_color.g + 0.4, base_color.b + 0.2, 0.9)
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(container)
	
	var anim_progress = 0.0
	var visual = Node2D.new()
	container.add_child(visual)
	
	visual.draw.connect(func():
		var current_range = range_dist * anim_progress
		var cone_width = 0.35  # Ancho del cono (porcentaje del rango)
		
		if current_range < 5:
			return
		
		# Múltiples capas del cono para efecto de gradiente
		for i in range(5):
			var layer_mult = 1.0 - i * 0.15
			var layer_range = current_range * layer_mult
			var layer_width = cone_width * (1.0 + i * 0.1)
			var layer_alpha = (0.5 - i * 0.08) * (1.0 - anim_progress * 0.3)
			
			var cone_points = PackedVector2Array([
				Vector2.ZERO,
				Vector2(layer_range, -layer_range * layer_width),
				Vector2(layer_range * 1.1, 0),
				Vector2(layer_range, layer_range * layer_width)
			])
			visual.draw_colored_polygon(cone_points, Color(base_color.r, base_color.g, base_color.b, layer_alpha))
		
		# Núcleo brillante central
		var core_points = PackedVector2Array([
			Vector2.ZERO,
			Vector2(current_range * 0.9, -current_range * cone_width * 0.3),
			Vector2(current_range * 0.95, 0),
			Vector2(current_range * 0.9, current_range * cone_width * 0.3)
		])
		visual.draw_colored_polygon(core_points, Color(bright_color.r, bright_color.g, bright_color.b, 0.7))
		
		# Partículas a lo largo del breath
		var particle_count = int(8 * anim_progress)
		for i in range(particle_count):
			var t = float(i) / max(particle_count, 1)
			var particle_dist = current_range * t
			var wobble = sin(anim_progress * PI * 4 + i * 0.8) * cone_width * particle_dist * 0.3
			var particle_pos = Vector2(particle_dist, wobble)
			var particle_size = 4.0 * (1.0 - t * 0.5)
			visual.draw_circle(particle_pos, particle_size, bright_color)
		
		# Borde brillante del cono
		visual.draw_line(Vector2.ZERO, Vector2(current_range, -current_range * cone_width), Color(1, 1, 1, 0.5), 2.0)
		visual.draw_line(Vector2.ZERO, Vector2(current_range, current_range * cone_width), Color(1, 1, 1, 0.5), 2.0)
	)
	
	# Animación de expansión rápida
	var tween = create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.3)
	
	# Mantener un momento y fade out
	tween.tween_interval(0.15)
	tween.tween_property(container, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func():
		if is_instance_valid(container):
			container.queue_free()
	)

func _get_element_color(elem: String) -> Color:
	"""Obtener color según elemento - Colores más vibrantes y atractivos"""
	match elem:
		"fire": return Color(1.0, 0.3, 0.05, 0.8)      # Rojo fuego brillante
		"ice": return Color(0.2, 0.7, 1.0, 0.8)        # Azul hielo claro
		"dark": return Color(0.6, 0.1, 0.9, 0.8)       # Púrpura oscuro
		"arcane": return Color(0.9, 0.3, 1.0, 0.8)     # Magenta arcano
		"poison": return Color(0.2, 0.9, 0.2, 0.8)     # Verde venenoso
		"lightning": return Color(1.0, 1.0, 0.2, 0.8)  # Amarillo eléctrico
		_: return Color(0.9, 0.9, 0.9, 0.8)            # Blanco físico

func _emit_melee_effect() -> void:
	"""Emitir efecto visual de ataque melee con slash animado"""
	if not enemy or not player:
		return
	
	var direction = (player.global_position - enemy.global_position).normalized()
	var slash_pos = enemy.global_position + direction * 25
	
	# Crear visual de slash
	var slash = Node2D.new()
	slash.name = "MeleeSlash"
	slash.global_position = slash_pos
	slash.rotation = direction.angle()
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(slash)
	
	var elem = _get_enemy_element()
	var base_color = _get_element_color(elem)
	var anim_progress = 0.0
	
	var visual = Node2D.new()
	slash.add_child(visual)
	
	visual.draw.connect(func():
		var arc_angle = PI * 0.7  # Ángulo del arco de slash
		var arc_radius = 30.0 * (0.5 + anim_progress * 0.5)
		var arc_start = -arc_angle / 2 + (1.0 - anim_progress) * arc_angle * 0.3
		var arc_end = arc_angle / 2 - (1.0 - anim_progress) * arc_angle * 0.3
		
		# Múltiples arcos para efecto de estela
		for i in range(4):
			var layer_radius = arc_radius * (1.0 - i * 0.15)
			var layer_alpha = (0.9 - i * 0.2) * (1.0 - anim_progress * 0.7)
			var layer_width = (5.0 - i * 1.0) * (1.0 - anim_progress * 0.5)
			if layer_width > 0:
				visual.draw_arc(Vector2.ZERO, layer_radius, arc_start, arc_end, 16, Color(base_color.r, base_color.g, base_color.b, layer_alpha), layer_width)
		
		# Destello en el borde del slash
		var flash_pos = Vector2(cos(arc_end), sin(arc_end)) * arc_radius
		var flash_size = 6.0 * (1.0 - anim_progress)
		visual.draw_circle(flash_pos, flash_size, Color(1, 1, 1, 0.8 * (1.0 - anim_progress)))
		
		# Chispas
		var spark_count = 4
		for i in range(spark_count):
			var spark_angle = arc_start + (arc_end - arc_start) * (float(i) / spark_count)
			var spark_dist = arc_radius * (0.7 + anim_progress * 0.5)
			var spark_pos = Vector2(cos(spark_angle), sin(spark_angle)) * spark_dist
			var spark_size = 2.0 * (1.0 - anim_progress)
			visual.draw_circle(spark_pos, spark_size, Color(1, 1, 0.8, 0.7 * (1.0 - anim_progress)))
	)
	
	# Animación rápida
	var tween = create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.15)
	
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

# ═══════════════════════════════════════════════════════════════════════════════
# FUNCIONES AUXILIARES PARA BOSSES
# ═══════════════════════════════════════════════════════════════════════════════

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

func _spawn_boss_projectile(direction: Vector2, damage: int, element: String, delay: float = 0.0) -> void:
	"""Crear proyectil de boss"""
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
	"""Crear orbe que persigue al jugador"""
	if not is_instance_valid(enemy) or not is_instance_valid(player):
		return
	
	var orb = Node2D.new()  # Usar Node2D simple, colisión por distancia
	orb.name = "HomingOrb"
	orb.global_position = pos
	orb.z_index = 10
	
	# Visual mejorado
	var visual = Node2D.new()
	orb.add_child(visual)
	var color = _get_element_color(element)
	var orb_time = 0.0
	
	visual.draw.connect(func():
		var pulse = 1.0 + sin(orb_time * 6) * 0.15
		# Glow exterior
		visual.draw_circle(Vector2.ZERO, 16 * pulse, Color(color.r, color.g, color.b, 0.2))
		# Cuerpo principal
		visual.draw_circle(Vector2.ZERO, 12 * pulse, color)
		# Núcleo brillante
		visual.draw_circle(Vector2.ZERO, 7 * pulse, Color(color.r + 0.3, color.g + 0.3, color.b + 0.3, 0.9).clamp())
		# Centro blanco
		visual.draw_circle(Vector2.ZERO, 3, Color(1, 1, 1, 0.9))
	)
	visual.queue_redraw()
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(orb)
	
	# Variables para tracking
	var time_alive = 0.0
	var player_ref = player
	var has_hit = false
	var hit_radius = 25.0  # Radio de colisión
	
	# Usar timer para movimiento y colisión por distancia
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
		
		# Check duración
		if time_alive >= duration:
			# Efecto de desvanecimiento
			var tween = orb.create_tween()
			tween.tween_property(orb, "modulate:a", 0.0, 0.3)
			tween.tween_callback(orb.queue_free)
			return
		
		# Mover hacia player
		var dir = (player_ref.global_position - orb.global_position).normalized()
		orb.global_position += dir * speed * 0.016
		
		# Actualizar visual
		visual.queue_redraw()
		
		# CHECK POR DISTANCIA (más fiable que Area2D)
		var dist = orb.global_position.distance_to(player_ref.global_position)
		if dist < hit_radius:
			has_hit = true
			if player_ref.has_method("take_damage"):
				player_ref.call("take_damage", damage, element)
				print("[HomingOrb] 🔮 Impacto en player: %d daño (%s)" % [damage, element])
			# Efecto de impacto
			_spawn_orb_impact_effect(orb.global_position, color)
			orb.queue_free()
			return
	)

func _spawn_orb_impact_effect(pos: Vector2, color: Color) -> void:
	"""Crear efecto visual de impacto de orbe"""
	var effect = Node2D.new()
	effect.global_position = pos
	effect.top_level = true
	
	if is_instance_valid(enemy):
		var parent = enemy.get_parent()
		if parent:
			parent.add_child(effect)
	
	var anim_progress = 0.0
	effect.draw.connect(func():
		var radius = 25 * anim_progress
		var alpha = (1.0 - anim_progress) * 0.8
		effect.draw_circle(Vector2.ZERO, radius, Color(color.r, color.g, color.b, alpha * 0.4))
		effect.draw_arc(Vector2.ZERO, radius * 0.8, 0, TAU, 16, Color(1, 1, 1, alpha), 2.0)
	)
	
	var tween = effect.create_tween()
	tween.tween_method(func(val):
		anim_progress = val
		if is_instance_valid(effect):
			effect.queue_redraw()
	, 0.0, 1.0, 0.25)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_damage_zone(pos: Vector2, radius: float, dps: int, duration: float, element: String) -> void:
	"""Crear zona de daño persistente"""
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
	
	# Daño por tick
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

# ═══════════════════════════════════════════════════════════════════════════════
# EFECTOS VISUALES DE BOSS
# ═══════════════════════════════════════════════════════════════════════════════

func _spawn_phase_change_effect() -> void:
	"""Efecto visual de cambio de fase"""
	if not is_instance_valid(enemy):
		return
	
	var effect = Node2D.new()
	effect.global_position = enemy.global_position
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)
	
	var anim = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)
	
	visual.draw.connect(func():
		# Ondas expansivas rojas
		for i in range(3):
			var r = 100 * anim * (1 + i * 0.3)
			var a = (1.0 - anim) * (0.8 - i * 0.2)
			visual.draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(1, 0.2, 0.2, a), 4.0 - i)
		
		# Rayos desde el centro
		var ray_count = 8
		for i in range(ray_count):
			var angle = (TAU / ray_count) * i + anim * PI
			var length = 150 * anim
			var end = Vector2(cos(angle), sin(angle)) * length
			visual.draw_line(Vector2.ZERO, end, Color(1, 0.5, 0, (1.0 - anim) * 0.8), 3.0)
	)
	
	var tween = create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.5)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_summon_visual() -> void:
	"""Efecto de invocación"""
	if not is_instance_valid(enemy):
		return
	
	var effect = Node2D.new()
	effect.global_position = enemy.global_position
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(effect)
	
	var anim = 0.0
	var visual = Node2D.new()
	effect.add_child(visual)
	
	visual.draw.connect(func():
		# Círculo mágico
		visual.draw_arc(Vector2.ZERO, 80, 0, TAU, 32, Color(0.5, 0, 0.8, 0.6 * (1.0 - anim)), 3.0)
		# Pentágono
		var points = 5
		for i in range(points):
			var a1 = (TAU / points) * i - PI/2 + anim * PI
			var a2 = (TAU / points) * ((i + 2) % points) - PI/2 + anim * PI
			var p1 = Vector2(cos(a1), sin(a1)) * 60
			var p2 = Vector2(cos(a2), sin(a2)) * 60
			visual.draw_line(p1, p2, Color(0.8, 0.2, 1, 0.7 * (1.0 - anim)), 2.0)
	)
	
	var tween = create_tween()
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
			# Expansión
			var r = 50 * anim
			visual.draw_circle(Vector2.ZERO, r, Color(color.r, color.g, color.b, 0.5 * (1.0 - anim)))
		else:
			# Contracción
			var r = 50 * (1.0 - anim)
			visual.draw_circle(Vector2.ZERO, r, Color(color.r, color.g, color.b, 0.5 * anim))
	)
	
	var tween = create_tween()
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
	
	var tween = create_tween()
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
	"""Visual de aura de maldición"""
	var effect = Node2D.new()
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
		# Símbolos de maldición
		var symbol_count = 6
		for i in range(symbol_count):
			var angle = (TAU / symbol_count) * i + anim * PI * 2
			var pos = Vector2(cos(angle), sin(angle)) * radius * 0.7
			visual.draw_circle(pos, 5, Color(0.5, 0, 0.5, 0.8 * (1.0 - anim)))
	)
	
	var tween = create_tween()
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
	
	var tween = create_tween()
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
		# Núcleo brillante
		visual.draw_rect(Rect2(0, -width/4, length, width/2), Color(0.8, 0.5, 1, 0.9))
	)
	
	var tween = create_tween()
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
		# Hexágono de escudo
		var radius = 40
		var points = PackedVector2Array()
		for i in range(7):
			var angle = (TAU / 6) * i + anim * 0.5
			points.append(Vector2(cos(angle), sin(angle)) * radius)
		visual.draw_polyline(points, Color(0.9, 0.8, 0.2, 0.8), 3.0)
		
		# Runas en cada vértice
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
	
	# Auto-destruir después de 10 segundos
	get_tree().create_timer(10.0).timeout.connect(func():
		if is_instance_valid(visual):
			visual.queue_free()
	)

func _spawn_rune_prison_visual(pos: Vector2, duration: float) -> void:
	"""Visual de prisión de runas"""
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
	
	var tween = create_tween()
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
		# Símbolo de espada
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
	
	# Auto-destruir después de 2 segundos
	get_tree().create_timer(2.0).timeout.connect(func():
		if is_instance_valid(visual):
			visual.queue_free()
	)

func _spawn_ground_slam_visual(center: Vector2, radius: float) -> void:
	"""Visual de golpe de tierra"""
	var effect = Node2D.new()
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
		# Ondas de choque
		for i in range(4):
			var r = radius * anim * (1.0 - i * 0.2)
			var a = (1.0 - anim) * (0.7 - i * 0.15)
			visual.draw_arc(Vector2.ZERO, r, 0, TAU, 32, Color(0.6, 0.4, 0.2, a), 4.0 - i)
		
		# Grietas radiales
		var crack_count = 8
		for i in range(crack_count):
			var angle = (TAU / crack_count) * i
			var length = radius * anim * 0.9
			var end = Vector2(cos(angle), sin(angle)) * length
			visual.draw_line(Vector2.ZERO, end, Color(0.3, 0.2, 0.1, (1.0 - anim) * 0.8), 2.0)
	)
	
	var tween = create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 0.5)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

func _spawn_charge_warning_visual(pos: Vector2, direction: Vector2) -> void:
	"""Visual de advertencia de carga"""
	var effect = Node2D.new()
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
		# Flecha indicando dirección
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
	
	var tween = create_tween()
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
		# Círculo de advertencia parpadeante
		var flash = (sin(anim * PI * 6) + 1) / 2
		visual.draw_circle(Vector2.ZERO, radius, Color(1, 0.2, 0, 0.2 + flash * 0.3))
		visual.draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(1, 0.5, 0, 0.5 + flash * 0.4), 2.0)
	)
	
	var tween = create_tween()
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
	"""Impacto real del meteoro con daño"""
	if not is_instance_valid(player):
		return
	
	# Verificar daño
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
		# Explosión de fuego
		var r = radius * (0.5 + anim * 0.5)
		for i in range(4):
			var layer_r = r * (1.0 - i * 0.2)
			var a = (1.0 - anim) * (0.8 - i * 0.15)
			var color = Color(1.0 - i * 0.1, 0.4 - i * 0.1, 0.05, a)
			visual.draw_circle(Vector2.ZERO, layer_r, color)
		
		# Centro de impacto
		visual.draw_circle(Vector2.ZERO, r * 0.3, Color(1, 1, 0.5, (1.0 - anim) * 0.9))
	)
	
	var tween = create_tween()
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
	
	var tween = create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, 1.5)
	tween.tween_callback(func():
		if is_instance_valid(effect):
			effect.queue_free()
	)

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
	
	player.take_damage(attack_damage)
	print("[EnemyAttackSystem] ⚔️ %s atacó melee a player por %d daño" % [enemy.name, attack_damage])
	
	# Emitir señal
	attacked_player.emit(attack_damage, true)
	
	# Efecto visual
	_emit_melee_effect()

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
	
	# Verificar si player está en rango del AoE
	var dist_to_player = aoe_center.distance_to(player.global_position)
	if dist_to_player <= radius:
		if player.has_method("take_damage"):
			player.take_damage(aoe_damage)
			print("[EnemyAttackSystem] 💥 %s AoE hit player por %d daño (radio=%.0f)" % [enemy.name, aoe_damage, radius])
			attacked_player.emit(aoe_damage, false)
	
	# Efecto visual del AoE
	_spawn_aoe_visual(enemy.global_position, radius)

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
	
	# Efecto visual del breath
	_spawn_breath_visual(enemy.global_position, direction, cone_range)

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

func _perform_boss_attack() -> void:
	"""Ataque de boss: combina varios tipos según habilidades"""
	# Bosses tienen ataques variados basados en sus habilidades
	if "summon" in special_abilities:
		# TODO: Implementar invocación de minions
		print("[EnemyAttackSystem] 👹 %s intenta invocar minions (no implementado)" % enemy.name)
	
	if "multi_attack" in special_abilities:
		_perform_multi_attack()
		return
	
	if "aoe_attack" in special_abilities:
		_perform_aoe_attack()
		return
	
	# Default: ataque poderoso melee
	_perform_melee_attack()

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
	"""Crear efecto visual de AoE"""
	# Crear un nodo temporal para el efecto visual
	var visual = Node2D.new()
	visual.global_position = center
	
	var elem = _get_enemy_element()
	var color = _get_element_color(elem)
	
	# Añadir al árbol
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(visual)
	
	# Dibujar círculo de AoE
	visual.draw.connect(func():
		visual.draw_arc(Vector2.ZERO, radius, 0, TAU, 32, color, 3.0)
		visual.draw_circle(Vector2.ZERO, radius * 0.1, color)
	)
	visual.queue_redraw()
	
	# Auto-destruir después de un tiempo
	get_tree().create_timer(0.5).timeout.connect(func():
		if is_instance_valid(visual):
			visual.queue_free()
	)

func _spawn_breath_visual(origin: Vector2, direction: Vector2, range_dist: float) -> void:
	"""Crear efecto visual de breath attack"""
	var visual = Node2D.new()
	visual.global_position = origin
	visual.rotation = direction.angle()
	
	var elem = _get_enemy_element()
	var color = _get_element_color(elem)
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(visual)
	
	# Dibujar cono de breath
	visual.draw.connect(func():
		var cone_points = PackedVector2Array([
			Vector2.ZERO,
			Vector2(range_dist, -range_dist * 0.3),
			Vector2(range_dist, range_dist * 0.3)
		])
		visual.draw_colored_polygon(cone_points, Color(color, 0.3))
	)
	visual.queue_redraw()
	
	# Fade out y destruir
	var tween = create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func():
		if is_instance_valid(visual):
			visual.queue_free()
	)

func _get_element_color(elem: String) -> Color:
	"""Obtener color según elemento"""
	match elem:
		"fire": return Color(1, 0.4, 0.1, 0.6)
		"ice": return Color(0.3, 0.7, 1.0, 0.6)
		"dark": return Color(0.5, 0.2, 0.8, 0.6)
		"arcane": return Color(0.8, 0.3, 1.0, 0.6)
		"poison": return Color(0.3, 0.8, 0.2, 0.6)
		"lightning": return Color(1.0, 1.0, 0.3, 0.6)
		_: return Color(0.8, 0.8, 0.8, 0.6)

func _emit_melee_effect() -> void:
	"""Emitir efecto visual de ataque melee"""
	var pm = _get_particle_manager()
	if pm and pm.has_method("emit_element_effect"):
		pm.emit_element_effect("physical", enemy.global_position)

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

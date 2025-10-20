# EnemyAttackSystem.gd
# Sistema de ataque para enemigos (melee y ranged)
# Gestiona cooldowns de ataque, targeting y ejecución

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

# Referencias
var enemy: Node = null
var player: Node = null

func _ready() -> void:
	enemy = get_parent()
	print("[EnemyAttackSystem] Inicializado para: %s" % enemy.name)

func initialize(p_attack_cooldown: float, p_attack_range: float, p_damage: int, p_is_ranged: bool = false, p_projectile_scene: PackedScene = null) -> void:
	"""Configurar parámetros de ataque"""
	attack_cooldown = p_attack_cooldown
	attack_range = p_attack_range
	attack_damage = p_damage
	is_ranged = p_is_ranged
	projectile_scene = p_projectile_scene
	print("[EnemyAttackSystem] Configurado: cooldown=%.2f, range=%.0f, damage=%d, ranged=%s" % [attack_cooldown, attack_range, attack_damage, is_ranged])

func _process(delta: float) -> void:
	"""Procesar cooldown y ataque automático"""
	if not enemy or not is_instance_valid(enemy):
		return
	
	# Obtener player si no lo tiene
	if not player or not is_instance_valid(player):
		player = _get_player()
		if not player:
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
	var tree = Engine.get_main_loop()
	if tree and tree.root:
		var sp = tree.root.get_node_or_null("SpellloopGame/SpellloopPlayer")
		if not sp:
			# Buscar en GameManager
			var gm = tree.root.get_node_or_null("GameManager")
			if gm and gm.has_meta("player"):
				sp = gm.get_meta("player")
		return sp
	return null

func _player_in_range() -> bool:
	"""Comprobar si el jugador está dentro del rango de ataque"""
	if not enemy or not player:
		return false
	
	var distance = enemy.global_position.distance_to(player.global_position)
	return distance <= attack_range

func _perform_attack() -> void:
	"""Ejecutar el ataque (melee o ranged)"""
	if not enemy or not player:
		return
	
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
	if not projectile_scene:
		print("[EnemyAttackSystem] Warning: %s no tiene projectile_scene" % enemy.name)
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
		projectile.initialize(direction, projectile_speed, attack_damage, 5.0, "physical")
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

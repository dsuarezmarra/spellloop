# IceWand.gd
# Varita de hielo - Dispara proyectiles simples hacia enemigos
# Sistema simplificado estilo Vampire Survivors

extends RefCounted

var id: String = "ice_wand"
var name: String = "Ice Wand"
var damage: int = 10
var attack_range: float = 500.0
var base_cooldown: float = 0.5
var current_cooldown: float = 0.0
var projectile_speed: float = 400.0
var projectile_count: int = 1
var is_active: bool = true
var element_type: String = "ice"

# Referencia al script de proyectil
var SimpleProjectileScript: Script = null

func _init() -> void:
	# Cargar script de proyectil simple
	if ResourceLoader.exists("res://scripts/entities/weapons/projectiles/SimpleProjectile.gd"):
		SimpleProjectileScript = load("res://scripts/entities/weapons/projectiles/SimpleProjectile.gd")

func perform_attack(owner: Node2D) -> void:
	"""Disparar proyectil hacia el enemigo más cercano"""
	if not owner or not is_active:
		return
	
	# Cargar script si aún no está cargado
	if not SimpleProjectileScript:
		if ResourceLoader.exists("res://scripts/entities/weapons/projectiles/SimpleProjectile.gd"):
			SimpleProjectileScript = load("res://scripts/entities/weapons/projectiles/SimpleProjectile.gd")
	
	if not SimpleProjectileScript:
		print("[IceWand] ✗ Error: SimpleProjectile.gd no disponible")
		return
	
	# Obtener enemigo más cercano
	var target = _find_nearest_enemy(owner)
	if not target:
		return
	
	var start_pos = owner.global_position
	var target_pos = target.global_position
	
	print("[IceWand] ⚡ Disparando hacia enemigo en %s" % target_pos)
	
	# Crear proyectil
	for i in range(projectile_count):
		var projectile = Area2D.new()
		projectile.set_script(SimpleProjectileScript)
		
		# PRIMERO añadir al árbol de escena
		var game_root = owner.get_tree().current_scene
		if not game_root:
			print("[IceWand] ✗ Error: No se pudo obtener current_scene")
			projectile.queue_free()
			return
		
		game_root.add_child(projectile)
		
		# AHORA configurar posición y propiedades
		projectile.global_position = start_pos
		projectile.damage = damage
		projectile.speed = projectile_speed
		projectile.element_type = element_type  # "ice" - esquirla de hielo
		projectile.knockback_force = 120.0
		
		# Calcular dirección
		var direction = (target_pos - start_pos).normalized()
		if projectile_count > 1 and i > 0:
			var spread = (float(i) / float(projectile_count - 1) - 0.5) * 0.5
			direction = direction.rotated(spread)
		
		projectile.direction = direction

func _find_nearest_enemy(owner: Node2D) -> Node:
	"""Encontrar el enemigo más cercano"""
	var nearest: Node = null
	var nearest_dist: float = attack_range
	
	for enemy in owner.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var dist = owner.global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	
	return nearest

func tick_cooldown(delta: float) -> void:
	"""Decrementar cooldown (llamado por AttackManager)"""
	if current_cooldown > 0:
		current_cooldown -= delta

func is_ready_to_fire() -> bool:
	"""Verificar si puede disparar"""
	return current_cooldown <= 0

func reset_cooldown() -> void:
	"""Resetear cooldown"""
	current_cooldown = base_cooldown

func get_info() -> Dictionary:
	"""Info para UI"""
	return {
		"id": id,
		"name": name,
		"damage": damage,
		"cooldown": base_cooldown,
		"element": element_type
	}

func apply_upgrade(upgrade_type: String, amount: float) -> void:
	"""Aplicar mejora al arma"""
	match upgrade_type:
		"damage":
			damage += int(amount)
		"speed":
			projectile_speed += amount * 50
		"cooldown":
			base_cooldown = max(0.1, base_cooldown - amount * 0.1)

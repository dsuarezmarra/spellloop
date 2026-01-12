# FireWand.gd
# Varita de fuego - Dispara proyectiles de fuego hacia enemigos
# Sistema simplificado estilo Vampire Survivors

extends RefCounted

var id: String = "fire_wand"
var name: String = "Fire Wand"
var damage: int = 12  # Ligeramente mas dano que ice_wand
var attack_range: float = 450.0
var base_cooldown: float = 1.0  # Ligeramente mas rapido
var current_cooldown: float = 0.0
var projectile_speed: float = 450.0
var projectile_count: int = 1
var pierce: int = 0
var crit_chance: float = 0.10  # Mayor probabilidad de critico
var crit_damage: float = 2.5   # Mayor dano critico
var is_active: bool = true
var element_type: String = "fire"

# Referencia al script de proyectil
var SimpleProjectileScript: Script = null

func _init() -> void:
	# Cargar script de proyectil simple
	if ResourceLoader.exists("res://scripts/entities/weapons/projectiles/SimpleProjectile.gd"):
		SimpleProjectileScript = load("res://scripts/entities/weapons/projectiles/SimpleProjectile.gd")

func perform_attack(owner: Node2D) -> bool:
	"""Disparar proyectil hacia el enemigo mas cercano. Retorna true si disparo."""
	if not owner or not is_active:
		return false
	
	# Cargar script si aun no esta cargado
	if not SimpleProjectileScript:
		if ResourceLoader.exists("res://scripts/entities/weapons/projectiles/SimpleProjectile.gd"):
			SimpleProjectileScript = load("res://scripts/entities/weapons/projectiles/SimpleProjectile.gd")
	
	if not SimpleProjectileScript:
		push_warning("[FireWand] Error: SimpleProjectile.gd no disponible")
		return false
	
	# Obtener enemigo mas cercano
	var target = _find_nearest_enemy(owner)
	if not target:
		return false
	
	var start_pos = owner.global_position
	var target_pos = target.global_position
	
	# Crear proyectil
	for i in range(projectile_count):
		var projectile = Area2D.new()
		projectile.set_script(SimpleProjectileScript)
		
		# Configurar propiedades ANTES de anadir al arbol
		projectile.damage = damage
		projectile.speed = projectile_speed
		projectile.element_type = element_type  # "fire" - bola de fuego
		projectile.knockback_force = 100.0
		projectile.pierce_count = pierce
		projectile.set_meta("weapon_id", id)
		
		# Configurar efecto burn (dano por tiempo)
		projectile.set_meta("effect", "burn")
		projectile.set_meta("effect_value", 3.0)  # 3 dano por tick
		projectile.set_meta("effect_duration", 3.0)  # 3 segundos de quemadura
		
		# Configurar criticos
		projectile.set_meta("crit_chance", crit_chance)
		projectile.set_meta("crit_damage", crit_damage)
		
		# Calcular direccion
		var direction = (target_pos - start_pos).normalized()
		if projectile_count > 1 and i > 0:
			var spread = (float(i) / float(projectile_count - 1) - 0.5) * 0.5
			direction = direction.rotated(spread)
		projectile.direction = direction
		
		# Anadir al arbol de escena
		var game_root = owner.get_tree().current_scene
		if not game_root:
			push_warning("[FireWand] Error: No se pudo obtener current_scene")
			projectile.queue_free()
			return false
		
		game_root.add_child(projectile)
		projectile.global_position = start_pos
	
	return true

func _find_nearest_enemy(owner: Node2D) -> Node:
	"""Encontrar el enemigo mas cercano"""
	var nearest: Node = null
	var nearest_dist: float = attack_range
	
	if not owner or not owner.get_tree():
		return null
	
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

func apply_upgrade(upgrade_data, amount: float = 0.0) -> void:
	"""Aplicar mejora al arma"""
	var upgrade_type: String = ""
	var upgrade_amount: float = amount
	
	if upgrade_data is String:
		upgrade_type = upgrade_data
	elif upgrade_data is Dictionary:
		var effects = upgrade_data.get("effects", [])
		for effect in effects:
			var stat = effect.get("stat", "")
			var value = effect.get("value", 0.0)
			match stat:
				"damage", "damage_mult", "damage_flat":
					damage += int(value) if stat == "damage_flat" else int(damage * value)
				"projectile_speed", "projectile_speed_mult":
					projectile_speed += value * 50
				"cooldown_mult", "attack_speed_mult":
					base_cooldown = max(0.1, base_cooldown * (1.0 / value if value > 0 else 1.0))
		return
	
	match upgrade_type:
		"damage":
			damage += int(upgrade_amount)
		"speed":
			projectile_speed += upgrade_amount * 50
		"cooldown":
			base_cooldown = max(0.1, base_cooldown - upgrade_amount * 0.1)

# IceWand.gd
# Varita de hielo - Dispara proyectiles simples hacia enemigos
# Sistema simplificado estilo Vampire Survivors

extends RefCounted

var id: String = "ice_wand"
var name: String = "Ice Wand"
var damage: int = 10
var attack_range: float = 500.0
var base_cooldown: float = 1.2  # Balanceado: antes 0.5, ahora más lento
var current_cooldown: float = 0.0
var projectile_speed: float = 400.0
var projectile_count: int = 1
var pierce: int = 0  # Cantidad de enemigos que atraviesa (0 = ninguno)
var crit_chance: float = 0.05  # Probabilidad de crítico (aplicada por AttackManager)
var crit_damage: float = 2.0   # Multiplicador de daño crítico
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
		push_warning("[IceWand] ✗ Error: SimpleProjectile.gd no disponible")
		return
	
	# Obtener enemigo más cercano
	var target = _find_nearest_enemy(owner)
	if not target:
		return
	
	var start_pos = owner.global_position
	var target_pos = target.global_position
	
	# print("[IceWand] ⚡ Disparando hacia enemigo en %s" % target_pos)
	
	# Crear proyectil
	for i in range(projectile_count):
		var projectile = Area2D.new()
		projectile.set_script(SimpleProjectileScript)
		
		# Configurar propiedades ANTES de añadir al árbol
		# (el _ready() del proyectil necesita weapon_id para crear visuales animados)
		projectile.damage = damage
		projectile.speed = projectile_speed
		projectile.element_type = element_type  # "ice" - esquirla de hielo
		projectile.knockback_force = 120.0
		projectile.pierce_count = pierce  # Penetración (atravesar enemigos)
		projectile.set_meta("weapon_id", id)
		
		# Configurar efecto slow (30% por 2 segundos)
		projectile.set_meta("effect", "slow")
		projectile.set_meta("effect_value", 0.30)
		projectile.set_meta("effect_duration", 2.0)
		
		# Configurar críticos
		projectile.set_meta("crit_chance", crit_chance)
		projectile.set_meta("crit_damage", crit_damage)
		
		# print("[IceWand] DEBUG: Configurado weapon_id='%s' antes de add_child" % id)
		# print("[IceWand] DEBUG: get_meta('weapon_id')='%s'" % projectile.get_meta("weapon_id", "NULL"))
		
		# Calcular dirección
		var direction = (target_pos - start_pos).normalized()
		if projectile_count > 1 and i > 0:
			var spread = (float(i) / float(projectile_count - 1) - 0.5) * 0.5
			direction = direction.rotated(spread)
		projectile.direction = direction
		
		# AHORA añadir al árbol de escena (después de configurar todo)
		var game_root = owner.get_tree().current_scene
		if not game_root:
			push_warning("[IceWand] ✗ Error: No se pudo obtener current_scene")
			projectile.queue_free()
			return
		
		game_root.add_child(projectile)
		projectile.global_position = start_pos

func _find_nearest_enemy(owner: Node2D) -> Node:
	"""Encontrar el enemigo más cercano"""
	var nearest: Node = null
	var nearest_dist: float = attack_range
	
	# Verificar que el árbol de escena existe
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

func apply_upgrade(upgrade_type: String, amount: float) -> void:
	"""Aplicar mejora al arma"""
	match upgrade_type:
		"damage":
			damage += int(amount)
		"speed":
			projectile_speed += amount * 50
		"cooldown":
			base_cooldown = max(0.1, base_cooldown - amount * 0.1)

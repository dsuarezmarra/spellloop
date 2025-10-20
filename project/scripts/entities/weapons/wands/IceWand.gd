# IceWand.gd
# Varita de hielo - Arma frost que dispara carámbanos
# Causa ralentización a enemigos golpeados

extends RefCounted
# class_name removido para evitar conflictos - usar load() en su lugar

# Hereda de WeaponBase, redefine algunos parámetros
var id: String = "ice_wand"
var name: String = "Ice Wand"
var damage: int = 8  # Menos daño que basic
var attack_range: float = 350.0
var base_cooldown: float = 0.4  # Más rápido
var current_cooldown: float = 0.0

# Sistema de proyectiles
var projectile_scene: PackedScene = null
var projectile_speed: float = 350.0  # Más rápido que basic
var projectile_lifetime: float = 4.0  # Dura menos
var projectile_count: int = 1

# Tipo de elemento
var element_type: String = "ice"  # ESPECIAL: ice

# Estadísticas adicionales
var critical_chance: float = 0.15  # 15% de crítico
var knockback: float = 80.0  # Menos retroceso
var is_melee: bool = false

# Flags
var is_active: bool = true
var pierces_enemies: bool = false
var pierces_count: int = 0

# Efecto especial: ralentización
var slow_duration: float = 2.0
var slow_percentage: float = 0.5  # 50% ralentización

func _init() -> void:
	"""Inicializar varita de hielo"""
	pass

func perform_attack(owner: Node2D) -> void:
	"""Realizar ataque con varita de hielo"""
	if not owner or not is_active:
		return
	
	if not projectile_scene:
		print("[IceWand] Warning: No projectile_scene asignada")
		return
	
	# Obtener objetivo
	var target_position = _get_target_position(owner)
	
	# Crear proyectiles
	for i in range(projectile_count):
		var projectile = projectile_scene.instantiate()
		
		if not projectile:
			print("[IceWand] Error: No se pudo instanciar projectile")
			continue
		
		# Calcular dirección
		var direction = (target_position - owner.global_position).normalized()
		
		# Para múltiples proyectiles, dispersar
		if projectile_count > 1:
			var spread_angle = (PI / 4.0) * (float(i) / float(projectile_count - 1) - 0.5)
			direction = direction.rotated(spread_angle)
		
		# Configurar proyectil
		projectile.global_position = owner.global_position
		projectile.direction = direction
		projectile.speed = projectile_speed
		projectile.damage = damage
		projectile.lifetime = projectile_lifetime
		projectile.element_type = element_type
		
		# ✨ NUEVO: Rotar proyectil según dirección
		projectile.rotation = direction.angle()
		
		# Si es IceProjectile, configurar efecto de hielo
		if projectile.has_meta("slow_duration"):
			projectile.set_meta("slow_duration", slow_duration)
			projectile.set_meta("slow_percentage", slow_percentage)
		
		# Agregar a la escena
		# CRÍTICO: Agregar a ChunksRoot (que se mueve con el mundo), NO a la raíz global
		var chunks_root = owner.get_tree().root.get_node_or_null("SpellloopGame/ChunksRoot")
		if chunks_root:
			chunks_root.add_child(projectile)
		else:
			# Fallback: Buscar WorldRoot
			var world_root = owner.get_tree().root.get_node_or_null("SpellloopGame/WorldRoot")
			if world_root:
				world_root.add_child(projectile)
			else:
				# Último recurso: Agregar a owner.parent (probablemente InfiniteWorldManager)
				owner.add_sibling(projectile)
		
		print("[IceWand] ❄️ Proyectil de hielo disparado")

func _get_target_position(owner: Node2D) -> Vector2:
	"""Obtener posición del objetivo - SIEMPRE apunta al más cercano"""
	var nearest_enemy = null
	var nearest_distance = INF  # Infinito para encontrar el más cercano SIEMPRE
	
	# Buscar enemigo más cercano (sin límite de rango inicial)
	for enemy in owner.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		
		var distance = owner.global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_enemy = enemy
			nearest_distance = distance
	
	# CAMBIO CRÍTICO: Si hay enemigos, SIEMPRE apuntar al más cercano
	if nearest_enemy:
		print("[IceWand] 🎯 Apuntando a: %s (distancia: %.1f)" % [nearest_enemy.name, nearest_distance])
		return nearest_enemy.global_position
	
	# Si NO hay enemigos, disparar hacia la derecha
	return owner.global_position + Vector2.RIGHT * attack_range

func tick_cooldown(delta: float) -> void:
	"""Decrementar cooldown"""
	if current_cooldown > 0:
		current_cooldown -= delta

func is_ready_to_fire() -> bool:
	"""Verificar si puede disparar"""
	return current_cooldown <= 0

func reset_cooldown() -> void:
	"""Resetear cooldown"""
	current_cooldown = base_cooldown

func get_info() -> Dictionary:
	"""Información del arma para UI"""
	return {
		"id": id,
		"name": name,
		"damage": damage,
		"range": attack_range,
		"cooldown": base_cooldown,
		"element": element_type,
		"projectiles": projectile_count,
		"special": "Ralentiza enemigos un %d%%" % int(slow_percentage * 100)
	}

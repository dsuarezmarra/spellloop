# ProjectilePool.gd
# Sistema de Object Pooling para proyectiles
# Evita crear/destruir proyectiles constantemente, reutilizándolos
#
# USO:
# - ProjectilePool.get_projectile() en lugar de SimpleProjectile.new()
# - ProjectilePool.return_projectile(proj) en lugar de queue_free()

extends Node
# NOTA: No usar class_name aquí porque es un autoload

# Singleton instance (usamos Node como tipo ya que no tenemos class_name)
static var instance: Node = null

# Pool de proyectiles disponibles
var _available_pool: Array[SimpleProjectile] = []

# Proyectiles actualmente en uso (para tracking)
var _active_count: int = 0

# Configuración
const INITIAL_POOL_SIZE: int = 50
const MAX_POOL_SIZE: int = 500
const GROW_AMOUNT: int = 20

# Estadísticas para debug
var stats_created: int = 0
var stats_reused: int = 0
var stats_returned: int = 0

func _ready() -> void:
	# Establecer singleton
	ProjectilePool.instance = self
	
	# Añadir al grupo para fácil acceso
	add_to_group("projectile_pool")
	
	# Pre-crear pool inicial
	_prewarm_pool(INITIAL_POOL_SIZE)
	
	# Debug
	# print("[ProjectilePool] ✓ Inicializado con %d proyectiles" % INITIAL_POOL_SIZE)

func _prewarm_pool(count: int) -> void:
	"""Pre-crear proyectiles para el pool"""
	for i in range(count):
		var projectile = _create_new_projectile()
		_available_pool.append(projectile)
	stats_created += count

func _create_new_projectile() -> SimpleProjectile:
	"""Crear un nuevo proyectil (solo cuando el pool está vacío)"""
	var projectile = SimpleProjectile.new()
	
	# Configurar para pooling
	projectile.set_meta("_pooled", true)
	
	# NO añadirlo al árbol todavía - se añade cuando se solicita
	return projectile

# ═══════════════════════════════════════════════════════════════════════════════
# API PÚBLICA
# ═══════════════════════════════════════════════════════════════════════════════

func get_projectile() -> SimpleProjectile:
	"""
	Obtener un proyectil del pool (o crear uno nuevo si está vacío).
	El proyectil viene sin parent - el llamador debe añadirlo al árbol.
	"""
	var projectile: SimpleProjectile
	
	if _available_pool.is_empty():
		# Pool vacío - crear más proyectiles
		if stats_created < MAX_POOL_SIZE:
			_prewarm_pool(mini(GROW_AMOUNT, MAX_POOL_SIZE - stats_created))
		
		# Si sigue vacío, crear uno de emergencia
		if _available_pool.is_empty():
			projectile = _create_new_projectile()
			stats_created += 1
		else:
			projectile = _available_pool.pop_back()
			stats_reused += 1
	else:
		projectile = _available_pool.pop_back()
		stats_reused += 1
	
	# Resetear estado del proyectil
	_reset_projectile(projectile)
	
	_active_count += 1
	if PerfTracker: PerfTracker.track_projectile_spawned()
	return projectile

func return_projectile(projectile: SimpleProjectile) -> void:
	"""
	Devolver un proyectil al pool para reutilización.
	IMPORTANTE: El proyectil debe ser removido del árbol antes de llamar esto.
	"""
	if projectile == null or not is_instance_valid(projectile):
		return
	
	# Remover del árbol si todavía está
	if projectile.is_inside_tree():
		projectile.get_parent().remove_child(projectile)
	
	# Limpiar estado
	_cleanup_projectile(projectile)
	
	# Devolver al pool (si no está lleno)
	if _available_pool.size() < MAX_POOL_SIZE:
		_available_pool.append(projectile)
		stats_returned += 1
	else:
		# Pool lleno - destruir el proyectil
		projectile.queue_free()
	
	_active_count -= 1
	if PerfTracker: PerfTracker.track_projectile_destroyed()

func _reset_projectile(projectile: SimpleProjectile) -> void:
	"""Resetear un proyectil a su estado inicial"""
	# Stats por defecto
	projectile.damage = 10
	projectile.speed = 400.0
	projectile.lifetime = 3.0
	projectile.knockback_force = 150.0
	projectile.pierce_count = 0
	projectile.element_type = "ice"
	
	# Estado
	projectile.direction = Vector2.RIGHT
	projectile.current_lifetime = 0.0
	projectile.enemies_hit.clear()
	projectile.pierces_remaining = 0
	projectile.start_pos = Vector2.ZERO
	
	# Limpiar metas
	projectile.remove_meta("effect") if projectile.has_meta("effect") else null
	projectile.remove_meta("effect_value") if projectile.has_meta("effect_value") else null
	projectile.remove_meta("effect_duration") if projectile.has_meta("effect_duration") else null
	projectile.remove_meta("crit_chance") if projectile.has_meta("crit_chance") else null
	projectile.remove_meta("crit_damage") if projectile.has_meta("crit_damage") else null
	projectile.remove_meta("weapon_id") if projectile.has_meta("weapon_id") else null
	projectile.remove_meta("weapon_color") if projectile.has_meta("weapon_color") else null
	
	# Visual - resetear modulate
	projectile.modulate = Color.WHITE
	projectile.visible = true
	projectile.global_position = Vector2.ZERO

func _cleanup_projectile(projectile: SimpleProjectile) -> void:
	"""Limpiar un proyectil antes de devolverlo al pool"""
	# Desconectar señales que podrían haberse conectado
	if projectile.body_entered.is_connected(projectile._on_body_entered):
		projectile.body_entered.disconnect(projectile._on_body_entered)
	if projectile.area_entered.is_connected(projectile._on_area_entered):
		projectile.area_entered.disconnect(projectile._on_area_entered)
	
	# Limpiar hijos dinámicos (partículas, sprites generados)
	for child in projectile.get_children():
		if child.name == "Trail" or child.name == "Sprite" or child is AnimatedProjectileSprite:
			child.queue_free()
	
	# Remover de grupos de armas
	for group in projectile.get_groups():
		if group.begins_with("weapon_projectiles_"):
			projectile.remove_from_group(group)

# ═══════════════════════════════════════════════════════════════════════════════
# DEBUG / ESTADÍSTICAS
# ═══════════════════════════════════════════════════════════════════════════════

func get_stats() -> Dictionary:
	"""Obtener estadísticas del pool para debug"""
	return {
		"available": _available_pool.size(),
		"active": _active_count,
		"total_created": stats_created,
		"total_reused": stats_reused,
		"total_returned": stats_returned,
		"reuse_rate": float(stats_reused) / float(stats_reused + stats_created) if (stats_reused + stats_created) > 0 else 0.0
	}

func print_stats() -> void:
	"""Imprimir estadísticas del pool"""
	var s = get_stats()
	print("[ProjectilePool] 📊 Pool: %d disponibles, %d activos | Creados: %d, Reutilizados: %d (%.1f%%)" % [
		s.available, s.active, s.total_created, s.total_reused, s.reuse_rate * 100
	])

func reset_stats() -> void:
	"""Resetear estadísticas"""
	stats_created = _available_pool.size()
	stats_reused = 0
	stats_returned = 0

# ═══════════════════════════════════════════════════════════════════════════════
# LIMPIEZA
# ═══════════════════════════════════════════════════════════════════════════════

func clear_pool() -> void:
	"""Limpiar completamente el pool (usar al cambiar de escena)"""
	for projectile in _available_pool:
		if is_instance_valid(projectile):
			# Use call_deferred to avoid physics callback errors
			projectile.call_deferred("queue_free")
	_available_pool.clear()
	_active_count = 0

func _exit_tree() -> void:
	clear_pool()
	ProjectilePool.instance = null

# ═══════════════════════════════════════════════════════════════════════════════
# STATIC HELPERS (para acceso fácil sin instancia)
# ═══════════════════════════════════════════════════════════════════════════════

static func acquire() -> SimpleProjectile:
	"""Obtener proyectil del pool singleton"""
	if instance:
		return instance.get_projectile()
	# Fallback si no hay pool
	return SimpleProjectile.new()

static func release(projectile: SimpleProjectile) -> void:
	"""Devolver proyectil al pool singleton"""
	if instance:
		instance.return_projectile(projectile)
	elif is_instance_valid(projectile):
		projectile.queue_free()

# ProjectilePool.gd
# Sistema de Object Pooling para proyectiles
# Evita crear/destruir proyectiles constantemente, reutilizándolos
#
# USO:
# - ProjectilePool.get_projectile() en lugar de SimpleProjectile.new()
# - ProjectilePool.return_projectile(proj) en lugar de queue_free()
#
# OPTIMIZACIÓN: Sistema de degradación progresiva para mantener FPS estable
# cuando hay demasiados proyectiles activos.

extends Node
# NOTA: No usar class_name aquí porque es un autoload

# Singleton instance (usamos Node como tipo ya que no tenemos class_name)
static var instance: Node = null

# Pool de proyectiles disponibles
var _available_pool: Array = []  # Generic array to avoid eager loading in headless

# Proyectiles actualmente en uso (para tracking)
var _active_count: int = 0

# Configuración
# Configuración
const INITIAL_POOL_SIZE: int = 200 # Aumentado de 50 para evitar spikes iniciales
const MAX_POOL_SIZE: int = 500
const GROW_AMOUNT: int = 50  # Aumentado de 20 para menos reallocations

# === SISTEMA DE DEGRADACIÓN PROGRESIVA ===
# Umbrales para controlar la explosión de proyectiles
const SOFT_LIMIT: int = 120      # Aumentada agresividad (antes 150)
const HARD_LIMIT: int = 220      # A partir de aquí: denegar nuevos proyectiles de baja prioridad
const CRITICAL_LIMIT: int = 280  # A partir de aquí: forzar cleanup agresivo

# Estado de degradación (0=normal, 1=soft, 2=hard, 3=critical)
var degradation_level: int = 0

# Estadísticas para debug
var stats_created: int = 0
var stats_reused: int = 0
var stats_returned: int = 0
var stats_denied: int = 0  # Proyectiles denegados por límite

# Track if pool has been initialized (lazy init to avoid headless deadlock)
var _pool_initialized: bool = false

func _ready() -> void:
	# Establecer singleton
	ProjectilePool.instance = self
	
	# Añadir al grupo para fácil acceso
	add_to_group("projectile_pool")
	
	# NOTE: Pool prewarming is now LAZY - happens on first get_projectile() call
	# This avoids headless deadlock where SimpleProjectile.new() is called before engine is ready

func _prewarm_pool(count: int) -> void:
	"""Pre-crear proyectiles para el pool"""
	for i in range(count):
		var projectile = _create_new_projectile()
		_available_pool.append(projectile)
	stats_created += count

func _create_new_projectile():
	"""Crear un nuevo proyectil (solo cuando el pool está vacío)"""
	var ProjectileScript = preload("res://scripts/entities/weapons/projectiles/SimpleProjectile.gd")
	var projectile = ProjectileScript.new()
	
	# Configurar para pooling
	projectile.set_meta("_pooled", true)
	
	# NO añadirlo al árbol todavía - se añade cuando se solicita
	return projectile

# ═══════════════════════════════════════════════════════════════════════════════
# API PÚBLICA
# ═══════════════════════════════════════════════════════════════════════════════

func get_projectile():
	"""
	Obtener un proyectil del pool (o crear uno nuevo si está vacío).
	El proyectil viene sin parent - el llamador debe añadirlo al árbol.
	
	NOTA: Este método NUNCA devuelve null. Si necesitas prioridad,
	usa get_projectile_prioritized() que sí puede denegar.
	"""
	# Lazy init pool on first call
	if not _pool_initialized:
		_prewarm_pool(INITIAL_POOL_SIZE)
		_pool_initialized = true
	
	var projectile
	
	# Actualizar nivel de degradación
	_update_degradation_level()
	
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

func get_projectile_prioritized(priority: int = 1):
	"""
	Obtener proyectil con sistema de prioridad.
	
	PRIORIDAD:
	- 0 = Baja (ej: sub-proyectiles, fragmentos): Denegado en HARD_LIMIT
	- 1 = Normal (ej: proyectiles de arma principal): Siempre permitido
	- 2 = Alta (ej: proyectiles del player, especiales): Siempre permitido
	
	Returns: SimpleProjectile o null si la solicitud es denegada por límites.
	"""
	_update_degradation_level()
	
	# Aplicar throttling según prioridad y nivel de degradación
	if degradation_level >= 2 and priority == 0:
		# HARD LIMIT: Denegar proyectiles de baja prioridad
		stats_denied += 1
		return null
	
	if degradation_level >= 3:
		# CRITICAL: Denegar TODO excepto prioridad alta
		if priority < 2:
			stats_denied += 1
			return null
		# Forzar cleanup de proyectiles más viejos
		_force_cleanup_oldest(10)
	
	return get_projectile()

func _update_degradation_level() -> void:
	"""Actualizar nivel de degradación basado en proyectiles activos"""
	var old_level = degradation_level
	
	if _active_count >= CRITICAL_LIMIT:
		degradation_level = 3
	elif _active_count >= HARD_LIMIT:
		degradation_level = 2
	elif _active_count >= SOFT_LIMIT:
		degradation_level = 1
	else:
		degradation_level = 0
	
	# Log cambio de nivel (solo una vez)
	if degradation_level != old_level and degradation_level > 0:
		print("[ProjectilePool] ⚠️ Degradation level: %d (active: %d)" % [degradation_level, _active_count])

func _force_cleanup_oldest(count: int) -> void:
	"""Forzar limpieza de los proyectiles más viejos en el árbol"""
	# Buscar proyectiles activos y destruir los más viejos
	var projectiles_node = get_tree().get_first_node_in_group("projectiles_container")
	if not projectiles_node:
		return
	
	var children = projectiles_node.get_children()
	var cleaned = 0
	for child in children:
		if child.has_method("configure_and_launch") and cleaned < count:  # Duck-type check instead of is SimpleProjectile
			return_projectile(child)
			cleaned += 1
	
	if cleaned > 0:
		print("[ProjectilePool] 🧹 Forced cleanup: %d projectiles" % cleaned)

func is_soft_limited() -> bool:
	"""Check if visual effects should be reduced (trails, particles)"""
	return degradation_level >= 1

func is_hard_limited() -> bool:
	"""Check if low-priority projectiles should be denied"""
	return degradation_level >= 2

func return_projectile(projectile) -> void:
	"""
	Devolver un proyectil al pool para reutilización.
	IMPORTANTE: El proyectil debe ser removido del árbol antes de llamar esto.
	"""
	if projectile == null or not is_instance_valid(projectile):
		return
	
	# Desactivar el proyectil inmediatamente para evitar más callbacks
	projectile.set_deferred("monitoring", false)
	projectile.set_deferred("monitorable", false)
	
	# Diferir la remoción del árbol para evitar errores en callbacks de física
	if projectile.is_inside_tree():
		projectile.get_parent().call_deferred("remove_child", projectile)
	
	# Limpiar estado (diferido para que ocurra después de remove_child)
	call_deferred("_complete_return", projectile)

func _complete_return(projectile) -> void:
	"""Completa el retorno del proyectil al pool (llamado diferidamente)"""
	if projectile == null or not is_instance_valid(projectile):
		return
	
	# Limpiar estado
	_cleanup_projectile(projectile)
	
	# Devolver al pool (si no está lleno)
	if _available_pool.size() < MAX_POOL_SIZE:
		_available_pool.append(projectile)
		stats_returned += 1
	else:
		# Pool lleno - destruir el proyectil (ya diferido aquí)
		projectile.call_deferred("queue_free")
	
	_active_count -= 1
	if PerfTracker: PerfTracker.track_projectile_destroyed()

func _reset_projectile(projectile) -> void:
	"""Resetear un proyectil a su estado inicial"""
	# CRÍTICO: Re-habilitar detección de colisiones (deshabilitada en return_projectile)
	projectile.monitoring = true
	projectile.monitorable = true
	projectile.set_process(true)
	projectile.set_physics_process(true)
	
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
	if projectile.has_meta("effect"):
		projectile.remove_meta("effect")
	if projectile.has_meta("effect_value"):
		projectile.remove_meta("effect_value")
	if projectile.has_meta("effect_duration"):
		projectile.remove_meta("effect_duration")
	if projectile.has_meta("crit_chance"):
		projectile.remove_meta("crit_chance")
	if projectile.has_meta("crit_damage"):
		projectile.remove_meta("crit_damage")
	if projectile.has_meta("weapon_id"):
		projectile.remove_meta("weapon_id")
	if projectile.has_meta("weapon_color"):
		projectile.remove_meta("weapon_color")
	
	# Visual - resetear modulate
	projectile.modulate = Color.WHITE
	projectile.visible = true
	projectile.global_position = Vector2.ZERO

func _cleanup_projectile(projectile) -> void:
	"""Limpiar un proyectil antes de devolverlo al pool"""
	# Desconectar señales que podrían haberse conectado
	if projectile.body_entered.is_connected(projectile._on_body_entered):
		projectile.body_entered.disconnect(projectile._on_body_entered)
	if projectile.area_entered.is_connected(projectile._on_area_entered):
		projectile.area_entered.disconnect(projectile._on_area_entered)
	
	# Limpiar hijos dinámicos (partículas, sprites generados)
	for child in projectile.get_children():
		if child.name == "Trail" or child.name == "Sprite" or child.has_method("play_flight"):  # Duck-type instead of is AnimatedProjectileSprite
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
		"total_denied": stats_denied,
		"degradation_level": degradation_level,
		"soft_limit": SOFT_LIMIT,
		"hard_limit": HARD_LIMIT,
		"critical_limit": CRITICAL_LIMIT,
		"reuse_rate": float(stats_reused) / float(stats_reused + stats_created) if (stats_reused + stats_created) > 0 else 0.0
	}

func print_stats() -> void:
	"""Imprimir estadísticas del pool"""
	var s = get_stats()
	print("[ProjectilePool] 📊 Pool: %d disponibles, %d activos (deg:%d) | Creados: %d, Reutilizados: %d (%.1f%%), Denegados: %d" % [
		s.available, s.active, s.degradation_level, s.total_created, s.total_reused, s.reuse_rate * 100, s.total_denied
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

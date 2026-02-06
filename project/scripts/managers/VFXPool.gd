# VFXPool.gd
# Sistema de Object Pooling para efectos visuales (partículas de impacto, lifesteal, etc.)
# OPTIMIZACIÓN CRÍTICA: Evita crear/destruir cientos de CPUParticles2D por segundo
#
# USO:
# - VFXPool.get_hit_particles() en lugar de CPUParticles2D.new()
# - VFXPool.return_particles(particles) en lugar de queue_free()

extends Node
class_name VFXPool

# Singleton
static var instance: VFXPool = null

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

const INITIAL_HIT_PARTICLES: int = 30
const INITIAL_LIFESTEAL_PARTICLES: int = 15
const MAX_POOL_SIZE: int = 100

# Spawn budget: máximo de VFX que se pueden crear por frame
const MAX_VFX_PER_FRAME: int = 8
var _vfx_spawned_this_frame: int = 0

# ═══════════════════════════════════════════════════════════════════════════════
# POOLS
# ═══════════════════════════════════════════════════════════════════════════════

var _hit_particles_pool: Array[CPUParticles2D] = []
var _lifesteal_particles_pool: Array[CPUParticles2D] = []
var _generic_particles_pool: Array[CPUParticles2D] = []

# Active tracking para debug
var _active_count: int = 0

# Stats
var stats: Dictionary = {
	"hits_created": 0,
	"hits_reused": 0,
	"hits_returned": 0,
	"lifesteal_created": 0,
	"lifesteal_reused": 0,
	"lifesteal_returned": 0,
	"budget_exceeded_count": 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	VFXPool.instance = self
	add_to_group("vfx_pool")
	
	# Verificar si estamos en modo headless
	if Headless.is_headless():
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	
	# Pre-warm pools
	_prewarm_hit_particles(INITIAL_HIT_PARTICLES)
	_prewarm_lifesteal_particles(INITIAL_LIFESTEAL_PARTICLES)
	
	print("[VFXPool] Inicializado - Hit:%d, Lifesteal:%d" % [
		_hit_particles_pool.size(), _lifesteal_particles_pool.size()
	])

func _process(_delta: float) -> void:
	# Reset budget cada frame
	_vfx_spawned_this_frame = 0

func _exit_tree() -> void:
	clear_all_pools()
	VFXPool.instance = null

# ═══════════════════════════════════════════════════════════════════════════════
# PREWARM
# ═══════════════════════════════════════════════════════════════════════════════

func _prewarm_hit_particles(count: int) -> void:
	for i in range(count):
		var p = _create_hit_particles_template()
		_hit_particles_pool.append(p)
	stats["hits_created"] += count

func _prewarm_lifesteal_particles(count: int) -> void:
	for i in range(count):
		var p = _create_lifesteal_particles_template()
		_lifesteal_particles_pool.append(p)
	stats["lifesteal_created"] += count

# ═══════════════════════════════════════════════════════════════════════════════
# TEMPLATES
# ═══════════════════════════════════════════════════════════════════════════════

func _create_hit_particles_template() -> CPUParticles2D:
	var particles = CPUParticles2D.new()
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 5  # Default, configurable
	particles.lifetime = 0.25
	particles.spread = 40.0
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 80.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 1.5
	particles.scale_amount_max = 3.0
	particles.emitting = false
	particles.set_meta("pooled", true)
	particles.set_meta("pool_type", "hit")
	return particles

func _create_lifesteal_particles_template() -> CPUParticles2D:
	var particles = CPUParticles2D.new()
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = 12
	particles.lifetime = 0.5
	particles.spread = 25.0
	particles.initial_velocity_min = 150.0
	particles.initial_velocity_max = 250.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 5.0
	particles.color = Color(0.3, 1.0, 0.4, 1.0)
	particles.emitting = false
	particles.set_meta("pooled", true)
	particles.set_meta("pool_type", "lifesteal")
	
	# Gradient para fade out
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.3, 1.0, 0.4, 1.0))
	gradient.set_color(1, Color(0.2, 0.8, 0.3, 0.0))
	particles.color_ramp = gradient
	
	return particles

# ═══════════════════════════════════════════════════════════════════════════════
# API PÚBLICA - HIT PARTICLES
# ═══════════════════════════════════════════════════════════════════════════════

func get_hit_particles(pos: Vector2, color: Color, direction: Vector2 = Vector2.LEFT, amount: int = 5, low_particle: bool = false) -> CPUParticles2D:
	"""
	Obtener partículas de impacto del pool.
	Retorna null si se excede el budget del frame.
	"""
	# Budget check
	if _vfx_spawned_this_frame >= MAX_VFX_PER_FRAME:
		stats["budget_exceeded_count"] += 1
		return null
	
	var particles: CPUParticles2D
	
	if _hit_particles_pool.is_empty():
		if stats["hits_created"] < MAX_POOL_SIZE:
			particles = _create_hit_particles_template()
			stats["hits_created"] += 1
		else:
			# Pool lleno, skip este VFX
			return null
	else:
		particles = _hit_particles_pool.pop_back()
		stats["hits_reused"] += 1
	
	# Configurar
	particles.global_position = pos
	particles.color = color
	particles.direction = direction
	particles.amount = 4 if low_particle else amount
	particles.lifetime = 0.2 if low_particle else 0.25
	
	# Añadir al árbol si no está
	if not particles.is_inside_tree():
		var tree = get_tree()
		if tree and tree.current_scene:
			tree.current_scene.add_child(particles)
	
	particles.emitting = true
	_active_count += 1
	_vfx_spawned_this_frame += 1
	
	# Auto-return después de lifetime
	var cleanup_time = particles.lifetime + 0.15
	_schedule_return(particles, cleanup_time, "hit")
	
	# Instrumentación
	if PerfTracker and PerfTracker.enabled:
		PerfTracker.log_event("vfx_spawn", {"type": "hit"})
	
	return particles

# ═══════════════════════════════════════════════════════════════════════════════
# API PÚBLICA - LIFESTEAL PARTICLES
# ═══════════════════════════════════════════════════════════════════════════════

func get_lifesteal_particles(start_pos: Vector2, target_pos: Vector2) -> CPUParticles2D:
	"""
	Obtener partículas de lifesteal del pool.
	Retorna null si se excede el budget del frame.
	"""
	# Budget check
	if _vfx_spawned_this_frame >= MAX_VFX_PER_FRAME:
		stats["budget_exceeded_count"] += 1
		return null
	
	var particles: CPUParticles2D
	
	if _lifesteal_particles_pool.is_empty():
		if stats["lifesteal_created"] < MAX_POOL_SIZE:
			particles = _create_lifesteal_particles_template()
			stats["lifesteal_created"] += 1
		else:
			return null
	else:
		particles = _lifesteal_particles_pool.pop_back()
		stats["lifesteal_reused"] += 1
	
	# Configurar dirección
	var dir_to_target = (target_pos - start_pos).normalized()
	particles.direction = dir_to_target
	particles.global_position = start_pos
	
	# Añadir al árbol si no está
	if not particles.is_inside_tree():
		var tree = get_tree()
		if tree and tree.current_scene:
			tree.current_scene.add_child(particles)
	
	particles.emitting = true
	_active_count += 1
	_vfx_spawned_this_frame += 1
	
	# Auto-return
	_schedule_return(particles, 0.65, "lifesteal")
	
	# Instrumentación
	if PerfTracker and PerfTracker.enabled:
		PerfTracker.log_event("vfx_spawn", {"type": "lifesteal"})
	
	return particles

# ═══════════════════════════════════════════════════════════════════════════════
# RETURN TO POOL
# ═══════════════════════════════════════════════════════════════════════════════

func _schedule_return(particles: CPUParticles2D, delay: float, pool_type: String) -> void:
	"""Programar retorno al pool después de un delay"""
	var timer = get_tree().create_timer(delay)
	timer.timeout.connect(func():
		_return_particles(particles, pool_type)
	)

func _return_particles(particles: CPUParticles2D, pool_type: String) -> void:
	"""Devolver partículas al pool correspondiente"""
	if not is_instance_valid(particles):
		return
	
	particles.emitting = false
	_active_count = maxi(0, _active_count - 1)
	
	# Remover del árbol para evitar draw calls
	if particles.get_parent():
		particles.get_parent().remove_child(particles)
	
	# Devolver al pool correcto
	match pool_type:
		"hit":
			if _hit_particles_pool.size() < MAX_POOL_SIZE:
				_hit_particles_pool.append(particles)
				stats["hits_returned"] += 1
			else:
				particles.queue_free()
		"lifesteal":
			if _lifesteal_particles_pool.size() < MAX_POOL_SIZE:
				_lifesteal_particles_pool.append(particles)
				stats["lifesteal_returned"] += 1
			else:
				particles.queue_free()
		_:
			if _generic_particles_pool.size() < MAX_POOL_SIZE:
				_generic_particles_pool.append(particles)
			else:
				particles.queue_free()
	
	# Instrumentación
	if PerfTracker and PerfTracker.enabled:
		PerfTracker.log_event("vfx_return", {"type": pool_type})

# ═══════════════════════════════════════════════════════════════════════════════
# API PÚBLICA - GENERIC PARTICLES (para otros usos)
# ═══════════════════════════════════════════════════════════════════════════════

func get_generic_particles() -> CPUParticles2D:
	"""Obtener partículas genéricas configurables"""
	if _vfx_spawned_this_frame >= MAX_VFX_PER_FRAME:
		return null
	
	var particles: CPUParticles2D
	
	if _generic_particles_pool.is_empty():
		particles = CPUParticles2D.new()
		particles.one_shot = true
		particles.set_meta("pooled", true)
		particles.set_meta("pool_type", "generic")
	else:
		particles = _generic_particles_pool.pop_back()
	
	_vfx_spawned_this_frame += 1
	_active_count += 1
	return particles

func return_generic_particles(particles: CPUParticles2D, delay: float = 0.5) -> void:
	"""Devolver partículas genéricas al pool"""
	_schedule_return(particles, delay, "generic")

# ═══════════════════════════════════════════════════════════════════════════════
# STATS & CLEANUP
# ═══════════════════════════════════════════════════════════════════════════════

func get_stats() -> Dictionary:
	"""Obtener estadísticas del pool para debug/telemetría"""
	return {
		"hit_pool_available": _hit_particles_pool.size(),
		"lifesteal_pool_available": _lifesteal_particles_pool.size(),
		"generic_pool_available": _generic_particles_pool.size(),
		"active_count": _active_count,
		"hits_created": stats["hits_created"],
		"hits_reused": stats["hits_reused"],
		"lifesteal_created": stats["lifesteal_created"],
		"lifesteal_reused": stats["lifesteal_reused"],
		"budget_exceeded": stats["budget_exceeded_count"],
		"hit_reuse_rate": float(stats["hits_reused"]) / float(stats["hits_created"] + stats["hits_reused"]) if (stats["hits_created"] + stats["hits_reused"]) > 0 else 0.0
	}

func clear_all_pools() -> void:
	"""Limpiar todos los pools (al cambiar de escena)"""
	for p in _hit_particles_pool:
		if is_instance_valid(p):
			p.queue_free()
	_hit_particles_pool.clear()
	
	for p in _lifesteal_particles_pool:
		if is_instance_valid(p):
			p.queue_free()
	_lifesteal_particles_pool.clear()
	
	for p in _generic_particles_pool:
		if is_instance_valid(p):
			p.queue_free()
	_generic_particles_pool.clear()
	
	_active_count = 0

# ═══════════════════════════════════════════════════════════════════════════════
# STATIC HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

static func spawn_hit(pos: Vector2, color: Color, direction: Vector2 = Vector2.LEFT, low_particle: bool = false) -> void:
	"""Helper estático para spawnar partículas de impacto"""
	if instance:
		instance.get_hit_particles(pos, color, direction, 5, low_particle)

static func spawn_lifesteal(start_pos: Vector2, target_pos: Vector2) -> void:
	"""Helper estático para spawnar partículas de lifesteal"""
	if instance:
		instance.get_lifesteal_particles(start_pos, target_pos)

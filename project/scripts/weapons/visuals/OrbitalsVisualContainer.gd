# OrbitalsVisualContainer.gd
# Contenedor que maneja múltiples OrbitVisualEffect
# Sincroniza las posiciones de los orbes con el OrbitalManager

class_name OrbitalsVisualContainer
extends Node2D

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

var visual_data: ProjectileVisualData
var _orbitals: Array[OrbitVisualEffect] = []
var _orbital_count: int = 0
var _orbit_radius: float = 60.0
var _orb_size: float = 24.0

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func setup(data: ProjectileVisualData, orbital_count: int, orbit_radius: float, orb_size: float = 24.0) -> void:
	"""Configurar el contenedor con múltiples orbes"""
	visual_data = data
	_orbital_count = orbital_count
	_orbit_radius = orbit_radius
	_orb_size = orb_size
	
	# Crear los orbes visuales
	_create_orbitals()

func _create_orbitals() -> void:
	"""Crear múltiples orbes distribuidos equitativamente"""
	# Limpiar orbes anteriores
	for orb in _orbitals:
		if is_instance_valid(orb):
			orb.queue_free()
	_orbitals.clear()
	
	# Crear nuevos orbes
	for i in range(_orbital_count):
		var initial_angle = (TAU / _orbital_count) * i
		var orb = OrbitVisualEffect.new()
		orb.setup(visual_data, _orbit_radius, initial_angle, _orb_size)
		# Desactivar la rotación automática - usaremos update_orbital_positions
		orb.set_process(false)
		add_child(orb)
		_orbitals.append(orb)
		
		# Spawn con animación
		orb.spawn()

# ═══════════════════════════════════════════════════════════════════════════════
# ACTUALIZACIÓN DE POSICIONES
# ═══════════════════════════════════════════════════════════════════════════════

func update_orbital_positions(positions: Array[Vector2]) -> void:
	"""Actualizar las posiciones de todos los orbes desde OrbitalManager"""
	for i in range(min(positions.size(), _orbitals.size())):
		if is_instance_valid(_orbitals[i]):
			_orbitals[i].position = positions[i]

func get_orbital_count() -> int:
	"""Obtener el número de orbes"""
	return _orbitals.size()

func destroy() -> void:
	"""Destruir todos los orbes con animación"""
	for orb in _orbitals:
		if is_instance_valid(orb):
			orb.destroy()

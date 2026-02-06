# SpawnBudgetManager.gd
# Sistema centralizado de control de instanciación por frame
# CRÍTICO: Previene stutters por crear demasiados nodos en un solo frame
#
# USO:
# - SpawnBudgetManager.request_spawn("enemy") -> true/false
# - SpawnBudgetManager.get_remaining("projectile") -> int

extends Node
class_name SpawnBudgetManager

# Singleton
static var instance: SpawnBudgetManager = null

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN DE BUDGETS POR TIPO
# ═══════════════════════════════════════════════════════════════════════════════

# Budget máximo por tipo de objeto por frame
# Estos valores son conservadores; pueden ajustarse según hardware
const BUDGETS: Dictionary = {
	"enemy": 5,        # Máximo 5 enemigos nuevos por frame
	"projectile": 20,  # Proyectiles son baratos (pool existente)
	"pickup": 10,      # Pickups son baratos (pool existente)
	"vfx": 8,          # VFX con nuevo pool
	"ui_text": 10,     # FloatingText ya tiene pool
	"generic": 5       # Cualquier otro tipo
}

# Budget global (suma de todos los tipos)
const GLOBAL_BUDGET: int = 30

# ═══════════════════════════════════════════════════════════════════════════════
# ESTADO POR FRAME
# ═══════════════════════════════════════════════════════════════════════════════

var _frame_counts: Dictionary = {}
var _global_count: int = 0
var _last_frame: int = -1

# Estadísticas
var stats: Dictionary = {
	"requests_total": 0,
	"requests_denied": 0,
	"budget_exhaustions": {},  # type -> count
	"peak_frame_spawns": 0
}

# Modo de desarrollo (logging extra)
var dev_mode: bool = false

# ═══════════════════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	SpawnBudgetManager.instance = self
	add_to_group("spawn_budget")
	
	# Inicializar contadores
	for key in BUDGETS.keys():
		_frame_counts[key] = 0
		stats["budget_exhaustions"][key] = 0
	
	# Leer configuración de dev mode
	dev_mode = ProjectSettings.get_setting("debug/perf/spawn_budget_logging", false)
	
	print("[SpawnBudgetManager] Inicializado con budgets: ", BUDGETS)

func _process(_delta: float) -> void:
	var current_frame = Engine.get_process_frames()
	if current_frame != _last_frame:
		# Nuevo frame: reset contadores
		_reset_frame_counts()
		_last_frame = current_frame

func _exit_tree() -> void:
	SpawnBudgetManager.instance = null

# ═══════════════════════════════════════════════════════════════════════════════
# API PÚBLICA
# ═══════════════════════════════════════════════════════════════════════════════

func request_spawn(spawn_type: String, count: int = 1) -> bool:
	"""
	Solicitar permiso para instanciar objetos.
	Retorna true si hay budget disponible, false si se excede.
	
	Uso típico:
	if SpawnBudgetManager.instance.request_spawn("enemy"):
		_do_spawn_enemy()
	else:
		_queue_for_next_frame(enemy_data)
	"""
	stats["requests_total"] += 1
	
	# Verificar frame actual
	var current_frame = Engine.get_process_frames()
	if current_frame != _last_frame:
		_reset_frame_counts()
		_last_frame = current_frame
	
	# Verificar budget global
	if _global_count + count > GLOBAL_BUDGET:
		stats["requests_denied"] += 1
		_log_budget_exceeded("global", count)
		return false
	
	# Verificar budget por tipo
	var type_budget = BUDGETS.get(spawn_type, BUDGETS["generic"])
	var current_type_count = _frame_counts.get(spawn_type, 0)
	
	if current_type_count + count > type_budget:
		stats["requests_denied"] += 1
		stats["budget_exhaustions"][spawn_type] = stats["budget_exhaustions"].get(spawn_type, 0) + 1
		_log_budget_exceeded(spawn_type, count)
		return false
	
	# Aprobar y registrar
	_frame_counts[spawn_type] = current_type_count + count
	_global_count += count
	
	# Track peak
	if _global_count > stats["peak_frame_spawns"]:
		stats["peak_frame_spawns"] = _global_count
	
	return true

func get_remaining(spawn_type: String) -> int:
	"""Obtener budget restante para un tipo específico"""
	var current_frame = Engine.get_process_frames()
	if current_frame != _last_frame:
		_reset_frame_counts()
		_last_frame = current_frame
	
	var type_budget = BUDGETS.get(spawn_type, BUDGETS["generic"])
	var current_count = _frame_counts.get(spawn_type, 0)
	return maxi(0, type_budget - current_count)

func get_global_remaining() -> int:
	"""Obtener budget global restante"""
	return maxi(0, GLOBAL_BUDGET - _global_count)

func force_allow(spawn_type: String, count: int = 1) -> void:
	"""
	Forzar registro de spawn sin verificar límites.
	USAR SOLO para spawns críticos que no pueden ser denegados (ej: boss).
	"""
	var current_frame = Engine.get_process_frames()
	if current_frame != _last_frame:
		_reset_frame_counts()
		_last_frame = current_frame
	
	_frame_counts[spawn_type] = _frame_counts.get(spawn_type, 0) + count
	_global_count += count

# ═══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

func _reset_frame_counts() -> void:
	"""Resetear contadores para nuevo frame"""
	for key in _frame_counts.keys():
		_frame_counts[key] = 0
	_global_count = 0

func _log_budget_exceeded(budget_type: String, count: int) -> void:
	"""Log cuando se excede budget (solo en dev mode)"""
	if dev_mode:
		print_rich("[color=yellow][SpawnBudget] ⚠️ Budget exceeded: %s (requested %d, available %d)[/color]" % [
			budget_type, count, get_remaining(budget_type) if budget_type != "global" else get_global_remaining()
		])

func get_stats() -> Dictionary:
	"""Obtener estadísticas para telemetría"""
	return {
		"requests_total": stats["requests_total"],
		"requests_denied": stats["requests_denied"],
		"denial_rate": float(stats["requests_denied"]) / float(stats["requests_total"]) if stats["requests_total"] > 0 else 0.0,
		"peak_frame_spawns": stats["peak_frame_spawns"],
		"budget_exhaustions": stats["budget_exhaustions"].duplicate()
	}

func reset_stats() -> void:
	"""Resetear estadísticas (para nueva sesión)"""
	stats["requests_total"] = 0
	stats["requests_denied"] = 0
	stats["peak_frame_spawns"] = 0
	for key in stats["budget_exhaustions"].keys():
		stats["budget_exhaustions"][key] = 0

# ═══════════════════════════════════════════════════════════════════════════════
# STATIC HELPERS
# ═══════════════════════════════════════════════════════════════════════════════

static func can_spawn(spawn_type: String, count: int = 1) -> bool:
	"""Helper estático para verificar sin consumir budget"""
	if not instance:
		return true  # Fallback permisivo si no hay instancia
	return instance.get_remaining(spawn_type) >= count

static func consume(spawn_type: String, count: int = 1) -> bool:
	"""Helper estático para request_spawn"""
	if not instance:
		return true
	return instance.request_spawn(spawn_type, count)

# Instrumentation.gd
# Sistema de scopes para medir tiempo de ejecución por sistema
# Uso: Instrumentation.begin_scope("EnemyAI"); ... ; Instrumentation.end_scope("EnemyAI")
# Overhead objetivo: < 0.1ms por scope call
extends RefCounted
class_name Instrumentation

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

const MAX_SCOPES: int = 50  # Límite de scopes únicos para prevenir memory leak
const TOP_N_SCOPES: int = 10  # Top scopes a reportar

# ═══════════════════════════════════════════════════════════════════════════════
# SCOPE DATA STRUCTURE
# ═══════════════════════════════════════════════════════════════════════════════

class ScopeData:
	var name: String = ""
	var start_time_usec: int = 0
	var total_time_usec: int = 0
	var call_count: int = 0
	var max_time_usec: int = 0
	var min_time_usec: int = 9999999999
	
	func get_avg_time_ms() -> float:
		if call_count == 0:
			return 0.0
		return (total_time_usec / float(call_count)) / 1000.0
	
	func get_total_time_ms() -> float:
		return total_time_usec / 1000.0
	
	func get_max_time_ms() -> float:
		return max_time_usec / 1000.0
	
	func get_min_time_ms() -> float:
		if min_time_usec == 9999999999:
			return 0.0
		return min_time_usec / 1000.0
	
	func reset() -> void:
		total_time_usec = 0
		call_count = 0
		max_time_usec = 0
		min_time_usec = 9999999999

# ═══════════════════════════════════════════════════════════════════════════════
# SINGLETON STATE (Static)
# ═══════════════════════════════════════════════════════════════════════════════

# Current minute scopes (reset each minute)
static var _minute_scopes: Dictionary = {}  # name -> ScopeData

# Run-total scopes (reset at run start)
static var _run_scopes: Dictionary = {}  # name -> ScopeData

# Active scope starts (for nested scopes)
static var _active_starts: Dictionary = {}  # name -> start_time_usec

# Enabled flag (disable for release builds)
static var enabled: bool = true

# ═══════════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════════════════════

static func begin_scope(scope_name: String) -> void:
	"""Comenzar a medir un scope. Llamar al inicio del código a medir."""
	if not enabled:
		return
	
	_active_starts[scope_name] = Time.get_ticks_usec()

static func end_scope(scope_name: String) -> void:
	"""Finalizar medición de un scope. Llamar al final del código medido."""
	if not enabled:
		return
	
	if not _active_starts.has(scope_name):
		return  # No matching begin
	
	var end_time = Time.get_ticks_usec()
	var start_time = _active_starts[scope_name]
	var elapsed_usec = end_time - start_time
	_active_starts.erase(scope_name)
	
	# Update minute scope
	_update_scope(_minute_scopes, scope_name, elapsed_usec)
	
	# Update run scope
	_update_scope(_run_scopes, scope_name, elapsed_usec)

static func _update_scope(scopes: Dictionary, scope_name: String, elapsed_usec: int) -> void:
	"""Actualizar datos de un scope."""
	if not scopes.has(scope_name):
		if scopes.size() >= MAX_SCOPES:
			return  # Límite alcanzado
		var data = ScopeData.new()
		data.name = scope_name
		scopes[scope_name] = data
	
	var data: ScopeData = scopes[scope_name]
	data.total_time_usec += elapsed_usec
	data.call_count += 1
	data.max_time_usec = maxi(data.max_time_usec, elapsed_usec)
	data.min_time_usec = mini(data.min_time_usec, elapsed_usec)

# ═══════════════════════════════════════════════════════════════════════════════
# SCOPE QUERY METHODS
# ═══════════════════════════════════════════════════════════════════════════════

static func get_minute_snapshot() -> Array[Dictionary]:
	"""Obtener snapshot de scopes del último minuto (ordenados por total_time desc)."""
	return _get_top_scopes(_minute_scopes, TOP_N_SCOPES)

static func get_run_snapshot() -> Array[Dictionary]:
	"""Obtener snapshot de scopes de toda la run (ordenados por total_time desc)."""
	return _get_top_scopes(_run_scopes, TOP_N_SCOPES)

static func get_top_scopes_minute(n: int = TOP_N_SCOPES) -> Array[Dictionary]:
	"""Obtener top N scopes por coste en el último minuto."""
	return _get_top_scopes(_minute_scopes, n)

static func get_top_scopes_run(n: int = TOP_N_SCOPES) -> Array[Dictionary]:
	"""Obtener top N scopes por coste en toda la run."""
	return _get_top_scopes(_run_scopes, n)

static func _get_top_scopes(scopes: Dictionary, n: int) -> Array[Dictionary]:
	"""Helper: Obtener top N scopes ordenados por total_time_ms."""
	var result: Array[Dictionary] = []
	
	for scope_name in scopes:
		var data: ScopeData = scopes[scope_name]
		result.append({
			"name": data.name,
			"total_ms": data.get_total_time_ms(),
			"avg_ms": data.get_avg_time_ms(),
			"max_ms": data.get_max_time_ms(),
			"min_ms": data.get_min_time_ms(),
			"calls": data.call_count
		})
	
	# Sort by total_ms descending
	result.sort_custom(func(a, b): return a.total_ms > b.total_ms)
	
	# Return top N
	if result.size() > n:
		result.resize(n)
	
	return result

static func get_all_scopes_minute() -> Dictionary:
	"""Obtener todos los scopes del minuto como diccionario."""
	var result: Dictionary = {}
	for scope_name in _minute_scopes:
		var data: ScopeData = _minute_scopes[scope_name]
		result[scope_name] = {
			"total_ms": data.get_total_time_ms(),
			"avg_ms": data.get_avg_time_ms(),
			"max_ms": data.get_max_time_ms(),
			"calls": data.call_count
		}
	return result

static func get_all_scopes_run() -> Dictionary:
	"""Obtener todos los scopes de la run como diccionario."""
	var result: Dictionary = {}
	for scope_name in _run_scopes:
		var data: ScopeData = _run_scopes[scope_name]
		result[scope_name] = {
			"total_ms": data.get_total_time_ms(),
			"avg_ms": data.get_avg_time_ms(),
			"max_ms": data.get_max_time_ms(),
			"calls": data.call_count
		}
	return result

# ═══════════════════════════════════════════════════════════════════════════════
# RESET METHODS
# ═══════════════════════════════════════════════════════════════════════════════

static func reset_minute_scopes() -> void:
	"""Resetear scopes del minuto. Llamar al inicio de cada minuto."""
	for scope_name in _minute_scopes:
		var data: ScopeData = _minute_scopes[scope_name]
		data.reset()

static func reset_run_scopes() -> void:
	"""Resetear scopes de la run. Llamar al inicio de cada run."""
	_run_scopes.clear()
	_minute_scopes.clear()
	_active_starts.clear()

static func set_enabled(value: bool) -> void:
	"""Activar/desactivar instrumentación."""
	enabled = value

# ═══════════════════════════════════════════════════════════════════════════════
# CONVENIENCE METHODS FOR COMMON SCOPES
# ═══════════════════════════════════════════════════════════════════════════════

# Pre-defined scope names for consistency
const SCOPE_ENEMY_SPAWN: String = "EnemySpawn"
const SCOPE_ENEMY_AI: String = "EnemyAI"
const SCOPE_PROJECTILE_UPDATE: String = "ProjectileUpdate"
const SCOPE_DAMAGE_CALC: String = "DamageCalc"
const SCOPE_STATUS_APPLY: String = "StatusApply"
const SCOPE_LOOT_GEN: String = "LootGen"
const SCOPE_UI_UPDATE: String = "UIUpdate"
const SCOPE_PHYSICS: String = "Physics"
const SCOPE_WAVE_UPDATE: String = "WaveUpdate"
const SCOPE_PICKUP_MAGNET: String = "PickupMagnet"
const SCOPE_VFX_SPAWN: String = "VFXSpawn"
const SCOPE_CHUNK_LOAD: String = "ChunkLoad"

# ═══════════════════════════════════════════════════════════════════════════════
# SCOPED EXECUTION HELPER
# ═══════════════════════════════════════════════════════════════════════════════

class ScopedTimer:
	"""Helper para usar con 'var _timer = Instrumentation.ScopedTimer.new("Scope")'
	   Se auto-cierra cuando sale de scope (RAII pattern)."""
	var _scope_name: String
	
	func _init(scope_name: String) -> void:
		_scope_name = scope_name
		Instrumentation.begin_scope(_scope_name)
	
	func _notification(what: int) -> void:
		if what == NOTIFICATION_PREDELETE:
			Instrumentation.end_scope(_scope_name)

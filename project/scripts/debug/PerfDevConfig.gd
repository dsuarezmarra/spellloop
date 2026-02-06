# PerfDevConfig.gd
# Configuración de desarrollo para diagnóstico de rendimiento
# IMPORTANTE: Estos valores son para desarrollo/debug, NO para producción
#
# USO:
# - Añadir a project.godot como autoload (opcional)
# - O acceder desde cualquier script: PerfDevConfig.property

extends Node
class_name PerfDevConfig

# ═══════════════════════════════════════════════════════════════════════════════
# TOGGLES GLOBALES
# ═══════════════════════════════════════════════════════════════════════════════

## Activar/desactivar pooling por tipo
static var pooling_enabled: Dictionary = {
	"projectiles": true,
	"enemies": true,
	"pickups": true,
	"vfx": true,
	"floating_text": true
}

## Activar/desactivar spawn budget
static var spawn_budget_enabled: bool = true

## Modo diagnóstico (logs extra)
static var diagnostics_mode: bool = false

# ═══════════════════════════════════════════════════════════════════════════════
# UMBRALES DE RENDIMIENTO
# ═══════════════════════════════════════════════════════════════════════════════

## Umbral de frame time para detectar spike (ms)
static var spike_threshold_ms: float = 22.0

## Umbral de draw calls para warning
static var draw_calls_warning_threshold: int = 350

## Umbral de nodos creados por frame para warning
static var nodes_per_frame_warning: int = 50

## Umbral de crecimiento de memoria para warning (MB/minuto)
static var memory_growth_warning_mb: float = 20.0

# ═══════════════════════════════════════════════════════════════════════════════
# SPAWN BUDGET
# ═══════════════════════════════════════════════════════════════════════════════

## Budget máximo por tipo de entidad por frame
static var spawn_budgets: Dictionary = {
	"enemy": 5,
	"projectile": 20,
	"pickup": 10,
	"vfx": 8,
	"ui_text": 10,
	"generic": 5
}

## Budget global (suma de todos los tipos)
static var global_spawn_budget: int = 30

# ═══════════════════════════════════════════════════════════════════════════════
# VFX POOL
# ═══════════════════════════════════════════════════════════════════════════════

## Tamaño inicial del pool de partículas de impacto
static var vfx_hit_pool_initial: int = 30

## Tamaño inicial del pool de partículas de lifesteal
static var vfx_lifesteal_pool_initial: int = 15

## Tamaño máximo de pools de VFX
static var vfx_pool_max_size: int = 100

## Máximo VFX por frame
static var vfx_per_frame_max: int = 8

# ═══════════════════════════════════════════════════════════════════════════════
# PROJECTILE POOL
# ═══════════════════════════════════════════════════════════════════════════════

## Tamaño inicial del pool de proyectiles
static var projectile_pool_initial: int = 200

## Tamaño máximo del pool
static var projectile_pool_max: int = 500

## Proyectiles a crear por frame durante prewarm progresivo
static var projectile_prewarm_per_frame: int = 15

# ═══════════════════════════════════════════════════════════════════════════════
# CRITERIOS DE ÉXITO (TARGETS)
# ═══════════════════════════════════════════════════════════════════════════════

## Objetivo: frame_time_ms máximo en spikes
static var target_max_frame_time_ms: float = 50.0

## Objetivo: máximo de nodos creados por frame
static var target_max_nodes_per_frame: int = 50

## Objetivo: máximo de draw calls
static var target_max_draw_calls: int = 350

## Objetivo: tasa de reuso de pools mínima
static var target_min_pool_reuse_rate: float = 0.8

# ═══════════════════════════════════════════════════════════════════════════════
# API
# ═══════════════════════════════════════════════════════════════════════════════

static func is_pool_enabled(pool_type: String) -> bool:
	"""Verificar si un tipo de pool está habilitado"""
	return pooling_enabled.get(pool_type, true)

static func get_spawn_budget(spawn_type: String) -> int:
	"""Obtener budget de spawn para un tipo específico"""
	if not spawn_budget_enabled:
		return 999999  # Sin límite
	return spawn_budgets.get(spawn_type, spawn_budgets["generic"])

static func should_warn_draw_calls(count: int) -> bool:
	"""Verificar si el conteo de draw calls debería generar warning"""
	return diagnostics_mode and count > draw_calls_warning_threshold

static func should_warn_memory_growth(growth_mb: float) -> bool:
	"""Verificar si el crecimiento de memoria debería generar warning"""
	return diagnostics_mode and growth_mb > memory_growth_warning_mb

static func should_warn_nodes_created(count: int) -> bool:
	"""Verificar si los nodos creados deberían generar warning"""
	return diagnostics_mode and count > nodes_per_frame_warning

static func print_config() -> void:
	"""Imprimir configuración actual"""
	print("═══════════════════════════════════════════════════════════")
	print("           PERF DEV CONFIG - CURRENT SETTINGS")
	print("═══════════════════════════════════════════════════════════")
	print("Pooling enabled: ", pooling_enabled)
	print("Spawn budget enabled: ", spawn_budget_enabled)
	print("Diagnostics mode: ", diagnostics_mode)
	print("")
	print("Thresholds:")
	print("  Spike: %.1f ms | DrawCalls: %d | Nodes/frame: %d" % [
		spike_threshold_ms, draw_calls_warning_threshold, nodes_per_frame_warning
	])
	print("")
	print("Targets:")
	print("  Max frame time: %.1f ms | Max draw calls: %d" % [
		target_max_frame_time_ms, target_max_draw_calls
	])
	print("  Max nodes/frame: %d | Min pool reuse: %.0f%%" % [
		target_max_nodes_per_frame, target_min_pool_reuse_rate * 100
	])
	print("═══════════════════════════════════════════════════════════")

# ═══════════════════════════════════════════════════════════════════════════════
# VALIDACIÓN DE MÉTRICAS
# ═══════════════════════════════════════════════════════════════════════════════

static func validate_metrics(metrics: Dictionary) -> Dictionary:
	"""
	Validar métricas contra los objetivos y retornar reporte.
	
	Uso:
	var metrics = {
		"max_frame_time_ms": 45.0,
		"max_nodes_per_frame": 30,
		"max_draw_calls": 280,
		"pool_reuse_rate": 0.85
	}
	var report = PerfDevConfig.validate_metrics(metrics)
	"""
	var report = {
		"passed": true,
		"failures": [],
		"warnings": []
	}
	
	# Frame time
	var ft = metrics.get("max_frame_time_ms", 0)
	if ft > target_max_frame_time_ms:
		report["passed"] = false
		report["failures"].append("frame_time: %.1f ms (target: < %.1f)" % [ft, target_max_frame_time_ms])
	
	# Nodes per frame
	var npf = metrics.get("max_nodes_per_frame", 0)
	if npf > target_max_nodes_per_frame:
		report["passed"] = false
		report["failures"].append("nodes_per_frame: %d (target: < %d)" % [npf, target_max_nodes_per_frame])
	
	# Draw calls
	var dc = metrics.get("max_draw_calls", 0)
	if dc > target_max_draw_calls:
		report["warnings"].append("draw_calls: %d (target: < %d)" % [dc, target_max_draw_calls])
	
	# Pool reuse rate
	var prr = metrics.get("pool_reuse_rate", 0)
	if prr < target_min_pool_reuse_rate:
		report["warnings"].append("pool_reuse: %.0f%% (target: > %.0f%%)" % [prr * 100, target_min_pool_reuse_rate * 100])
	
	return report

static func print_validation_report(metrics: Dictionary) -> void:
	"""Imprimir reporte de validación de métricas"""
	var report = validate_metrics(metrics)
	
	print("")
	print("═══════════════════════════════════════════════════════════")
	print("           PERF VALIDATION REPORT")
	print("═══════════════════════════════════════════════════════════")
	
	if report["passed"]:
		print_rich("[color=green]✅ ALL CRITICAL TARGETS PASSED[/color]")
	else:
		print_rich("[color=red]❌ CRITICAL FAILURES:[/color]")
		for failure in report["failures"]:
			print_rich("   [color=red]• %s[/color]" % failure)
	
	if report["warnings"].size() > 0:
		print_rich("[color=yellow]⚠️ WARNINGS:[/color]")
		for warning in report["warnings"]:
			print_rich("   [color=yellow]• %s[/color]" % warning)
	
	print("═══════════════════════════════════════════════════════════")

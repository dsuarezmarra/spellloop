extends Node

# ═══════════════════════════════════════════════════════════════════════════════
# PERFORMANCE TRACKER (DIAGNOSTICS & OPTIMIZATION)
# ═══════════════════════════════════════════════════════════════════════════════
# Central hub for monitoring game performance, detecting spikes, and logging metrics.
# Intended to be an Autoload (Singleton).

# --- CONFIGURATION (Toggle via code or console) ---
var enabled: bool = true
var log_spikes: bool = true
var frame_time_threshold_ms: float = 22.0 # ~45 FPS warning threshold
var spike_cooldown_ms: int = 1000 # Minimum time between spike logs
var metrics_history_size: int = 600 # Keep last 10 seconds (at 60fps)

# --- STATE ---
var _metrics_history: Array = []
var _event_buffer: Array = [] # Circular buffer of last events
const MAX_EVENT_BUFFER: int = 20

var _last_spike_time: int = 0
var _frame_count: int = 0
var _last_metrics_pack: Dictionary = {}

# --- COUNTERS ---
var counters: Dictionary = {
	"enemies_alive": 0,
	"enemies_spawned_total": 0,
	"projectiles_alive": 0,
	"projectiles_spawned_total": 0,
	"pickups_alive": 0,
	"particles_alive": 0,
	"draw_calls": 0
}

# --- LOGGING PATH ---
const LOG_DIR = "user://perf_logs"
var _current_log_file: String = ""

func _ready() -> void:
	if Headless.is_headless():
		enabled = false
		process_mode = Node.PROCESS_MODE_DISABLED
		return

	process_mode = Node.PROCESS_MODE_ALWAYS # Run even when paused
	_init_logs()
	print("[PerfTracker] Initialized. Logs at: ", ProjectSettings.globalize_path(LOG_DIR))
	
	# Auto-instantiate Overlay
	call_deferred("_add_overlay")

func _add_overlay() -> void:
	var overlay_script = load("res://scripts/debug/PerfOverlay.gd")
	if overlay_script:
		var node = overlay_script.new()
		node.name = "PerfOverlay"
		get_tree().root.add_child(node)

func _init_logs() -> void:
	if not DirAccess.dir_exists_absolute(LOG_DIR):
		DirAccess.make_dir_absolute(LOG_DIR)
	
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	_current_log_file = LOG_DIR.path_join("perf_session_%s.jsonl" % timestamp)
	
	_log_system_info()

func _log_system_info() -> void:
	var info = {
		"event": "session_start",
		"os": OS.get_name(),
		"cpu": OS.get_processor_name(),
		"gpu": RenderingServer.get_video_adapter_name(),
		"godot_version": Engine.get_version_info().string,
		"timestamp": Time.get_unix_time_from_system()
	}
	_append_to_log(info)

func _process(delta: float) -> void:
	if not enabled: return
	
	_frame_count += 1
	var frame_time_ms = delta * 1000.0
	var now = Time.get_ticks_msec()
	
	# 1. Update Engine Monitors
	var current_node_count = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var nodes_created_delta = current_node_count - counters.get("objects_nodes", current_node_count)
	counters["objects_nodes"] = current_node_count
	# Store delta for spike analysis
	counters["nodes_created_delta"] = nodes_created_delta
	
	counters["draw_calls"] = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	counters["memory_static_mb"] = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0
	counters["physics_time_ms"] = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	counters["node_count"] = get_tree().get_node_count()
	
	# 2. Check for Spikes
	if log_spikes and frame_time_ms > frame_time_threshold_ms:
		if now - _last_spike_time > spike_cooldown_ms:
			_capture_spike_snapshot(frame_time_ms)
			_last_spike_time = now
	
	# 3. Store History
	_last_metrics_pack = {
		"fps": Engine.get_frames_per_second(),
		"ft_ms": frame_time_ms,
		"counters": counters.duplicate()
	}
	
	_metrics_history.append(_last_metrics_pack)
	if _metrics_history.size() > metrics_history_size:
		_metrics_history.pop_front()

# --- PUBLIC API FOR INSTRUMENTATION ---

func track_enemy_spawned() -> void:
	counters["enemies_alive"] += 1
	counters["enemies_spawned_total"] += 1
	log_event("enemy_spawn", {"total": counters["enemies_alive"]})

func track_enemy_death() -> void:
	counters["enemies_alive"] = maxi(0, counters["enemies_alive"] - 1)

func track_projectile_spawned() -> void:
	counters["projectiles_alive"] += 1
	counters["projectiles_spawned_total"] += 1

func track_projectile_destroyed() -> void:
	counters["projectiles_alive"] = maxi(0, counters["projectiles_alive"] - 1)

func track_pickup_spawned() -> void:
	counters["pickups_alive"] += 1

func track_pickup_collected() -> void:
	counters["pickups_alive"] = maxi(0, counters["pickups_alive"] - 1)

func log_event(event_name: String, data: Dictionary = {}) -> void:
	if not enabled: return
	var timestamp = Time.get_ticks_msec()
	var entry = {
		"event": event_name,
		"timestamp": timestamp,
		"frame": _frame_count,
		"data": data,
		"context": {
			"enemies": counters["enemies_alive"],
			"projectiles": counters["projectiles_alive"],
			"fps": Engine.get_frames_per_second()
		}
	}
	
	# Add to buffer
	_event_buffer.append(entry)
	if _event_buffer.size() > MAX_EVENT_BUFFER:
		_event_buffer.pop_front()
		
	# Write specific major events to log immediately? Or keep buffer mostly?
	# We only write if spike or critical event.
	# For now, buffer is enough for spikes.

# --- INTERNAL ---

func _capture_spike_snapshot(frame_time: float) -> void:
	var snapshot = {
		"event": "perf_spike",
		"timestamp": Time.get_ticks_msec(),
		"frame_time_ms": frame_time,
		"fps": Engine.get_frames_per_second(),
		"counters": counters.duplicate(),
		"memory_mb": counters.get("memory_static_mb", 0),
		"recent_events": _event_buffer.duplicate() # Include context
	}
	
	var pool_stats = {}
	if ProjectilePool and ProjectilePool.instance:
		pool_stats = ProjectilePool.instance.get_stats()

	print_rich("[color=orange][PerfTracker] ⚠️ LAG SPIKE DETECTED: %.2f ms (FPS: %d)[/color]" % [frame_time, snapshot.fps])
	print("   Analysis: Nodes +%d | DrawCalls: %d | PhysTime: %.2f ms" % [
		counters.get("nodes_created_delta", 0), 
		counters.get("draw_calls",0),
		counters.get("physics_time_ms", 0)
	])
	if not pool_stats.is_empty():
		print("   Pool State: Active: %d | Pooled: %d | DegradeLvl: %d" % [
			pool_stats.get("active", -1), 
			pool_stats.get("pooled", -1), 
			pool_stats.get("degradation_level", -1)
		])
	
	snapshot["projectile_pool"] = pool_stats
	_append_to_log(snapshot)


func _append_to_log(data: Dictionary) -> void:
	var json_string = JSON.stringify(data)
	var file = FileAccess.open(_current_log_file, FileAccess.READ_WRITE)
	if not file:
		# Try write mode if file doesn't exist equivalent (READ_WRITE requires existing?)
		file = FileAccess.open(_current_log_file, FileAccess.WRITE)
	
	if file:
		file.seek_end()
		file.store_line(json_string)
		file.close()

# --- UTILS ---
func get_current_metrics() -> Dictionary:
	return _last_metrics_pack

# ═══════════════════════════════════════════════════════════════════════════════
# METRICS AGGREGATION (Minute-by-Minute Report)
# ═══════════════════════════════════════════════════════════════════════════════

var _minute_timer: float = 0.0
var _minute_samples: Array = []
const MINUTE_REPORT_INTERVAL: float = 60.0

func _aggregate_minute_metrics() -> void:
	"""Agregar métricas del último minuto y generar reporte"""
	if _minute_samples.is_empty():
		return
	
	var fps_values = []
	var ft_values = []
	var projectile_values = []
	var enemy_values = []
	var draw_call_values = []
	
	for sample in _minute_samples:
		fps_values.append(sample.get("fps", 0))
		ft_values.append(sample.get("ft_ms", 0))
		var c = sample.get("counters", {})
		projectile_values.append(c.get("projectiles_alive", 0))
		enemy_values.append(c.get("enemies_alive", 0))
		draw_call_values.append(c.get("draw_calls", 0))
	
	var report = {
		"event": "minute_report",
		"timestamp": Time.get_unix_time_from_system(),
		"samples": _minute_samples.size(),
		"fps": {
			"min": fps_values.min() if fps_values.size() > 0 else 0,
			"max": fps_values.max() if fps_values.size() > 0 else 0,
			"avg": _array_avg(fps_values)
		},
		"frame_time_ms": {
			"min": ft_values.min() if ft_values.size() > 0 else 0,
			"max": ft_values.max() if ft_values.size() > 0 else 0,
			"avg": _array_avg(ft_values)
		},
		"projectiles": {
			"min": projectile_values.min() if projectile_values.size() > 0 else 0,
			"max": projectile_values.max() if projectile_values.size() > 0 else 0,
			"avg": _array_avg(projectile_values)
		},
		"enemies": {
			"min": enemy_values.min() if enemy_values.size() > 0 else 0,
			"max": enemy_values.max() if enemy_values.size() > 0 else 0,
			"avg": _array_avg(enemy_values)
		},
		"draw_calls": {
			"min": draw_call_values.min() if draw_call_values.size() > 0 else 0,
			"max": draw_call_values.max() if draw_call_values.size() > 0 else 0,
			"avg": _array_avg(draw_call_values)
		}
	}
	
	# Agregar stats de subsistemas si están disponibles
	if ProjectilePool and ProjectilePool.instance:
		report["projectile_pool"] = ProjectilePool.instance.get_stats()
	
	# Agregar stats del ResourceManager
	var rm = get_tree().get_first_node_in_group("resource_manager")
	if rm and rm.has_method("get_precache_stats"):
		report["resource_manager"] = rm.get_precache_stats()
	
	# Log report
	print_rich("[color=cyan][PerfTracker] 📊 MINUTE REPORT (samples: %d)[/color]" % _minute_samples.size())
	print("   FPS: min=%d avg=%.1f max=%d" % [report.fps.min, report.fps.avg, report.fps.max])
	print("   Projectiles: max=%d | Enemies: max=%d | DrawCalls: max=%d" % [
		report.projectiles.max, report.enemies.max, report.draw_calls.max
	])
	
	_append_to_log(report)
	_minute_samples.clear()

func _array_avg(arr: Array) -> float:
	if arr.is_empty():
		return 0.0
	var total = 0.0
	for v in arr:
		total += v
	return total / arr.size()

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	
	# Agregar sample cada 10 frames físicos (~6 samples/seg a 60fps)
	if _frame_count % 10 == 0:
		_minute_samples.append(_last_metrics_pack.duplicate(true))
	
	# Generar reporte cada minuto
	_minute_timer += delta
	if _minute_timer >= MINUTE_REPORT_INTERVAL:
		_minute_timer = 0.0
		_aggregate_minute_metrics()

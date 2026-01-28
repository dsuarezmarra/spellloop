extends Node
class_name PerfTracker

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
	counters["draw_calls"] = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	counters["memory_static_mb"] = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0
	counters["objects_nodes"] = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	# Note: PHYSICS_PROCESS_FRAME_TIME is only valid in physics_process, using TIME_PHYSICS_PROCESS often returns 0 in process
	# We rely on an estimate or reading inside physics process if needed, but Monitor works usually.
	counters["physics_time_ms"] = Performance.get_monitor(Performance.PHYSICS_PROCESS_FRAME_TIME) * 1000.0
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
	
	print_rich("[color=orange][PerfTracker] ⚠️ LAG SPIKE DETECTED: %.2f ms (FPS: %d)[/color]" % [frame_time, snapshot.fps])
	print("   Context: Nodes: %d | Enm: %d | Proj: %d | Draw: %d" % [counters.get("node_count", 0), counters.get("enemies_alive",0), counters.get("projectiles_alive",0), counters.get("draw_calls",0)])
	
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

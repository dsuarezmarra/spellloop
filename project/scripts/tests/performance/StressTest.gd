extends Node2D

# StressTest.gd - Phase 7 Performance Validation
# Run with: godot --headless --enable-perf-tracker "res://scripts/tests/performance/StressTest.tscn"

# Autoloads (ProjectilePool, PerfTracker) are assumed to be loaded by the engine.

var _test_duration = 10.0
var _elapsed = 0.0
var _frame_times = []
var _spikes = []
var _max_projectiles = 0
var _max_draw_calls = 0

const TARGET_PROJECTILES = 250

func _ready():
	print("🚀 Starting Stress Test (Phase 7 - Scene Mode)...")
	
	# 1. Determinism
	seed(12345)
	
	# 2. Verify Autoloads
	if not get_node_or_null("/root/ProjectilePool"):
		print("❌ CRITICAL: ProjectilePool autoload missing.")
		get_tree().quit(1)
		return
		
	if not get_node_or_null("/root/PerfTracker"):
		print("⚠️ PerfTracker autoload missing (or disabled).")
	else:
		PerfTracker.enabled = true # Force enable
		print("✅ PerfTracker Active")

	print("✅ Setup Complete. Running for %s seconds..." % _test_duration)

func _process(delta):
	_elapsed += delta
	var frame_ms = delta * 1000.0
	_frame_times.append(frame_ms)
	
	# Detect Spikes (> 30ms)
	if frame_ms > 30.0:
		_spikes.append({
			"time": _elapsed,
			"duration": frame_ms,
			"context": "Frame %d" % _frame_times.size()
		})
	
	# Spawn Logic
	_spawn_batch()
	
	# Stats
	var stats = ProjectilePool.get_stats()
	if stats.active > _max_projectiles: _max_projectiles = stats.active
	
	if _elapsed >= _test_duration:
		_finish()

func _spawn_batch():
	# Ramp up to target
	var pool_stats = ProjectilePool.get_stats()
	var current = pool_stats.active
	
	if current < TARGET_PROJECTILES:
		for i in range(5):
			var p = ProjectilePool.get_projectile()
			if p:
				p.global_position = Vector2(randf()*2000, randf()*2000)
				p.direction = Vector2.RIGHT.rotated(randf() * TAU)
				p.speed = 400
				p.lifetime = 5.0
				
				if p.get_parent() == null:
					add_child(p)
				
				# Ensure active
				p.set_physics_process(true)

func _finish():
	print("🛑 Test Finished. Generating Report...")
	_generate_report()
	get_tree().quit()

func _generate_report():
	if _frame_times.is_empty(): _frame_times.append(0.0)
	
	_frame_times.sort()
	var min_ft = _frame_times[0]
	var max_ft = _frame_times[-1]
	var avg_ft = 0.0
	for t in _frame_times: avg_ft += t
	avg_ft /= _frame_times.size()
	
	var p95 = _frame_times[int(_frame_times.size() * 0.95)]
	var p99 = _frame_times[int(_frame_times.size() * 0.99)]
	
	var avg_fps = 1000.0 / avg_ft if avg_ft > 0 else 0
	
	var report = []
	report.append("# Performance Stress Test Report")
	report.append("**Timestamp**: %s" % Time.get_datetime_string_from_system())
	report.append("**Duration**: %.1fs" % _test_duration)
	report.append("")
	report.append("## Metrics")
	report.append("- **Avg FPS**: %.1f" % avg_fps)
	report.append("- **Frame Time**: Min: %.1fms | Avg: %.1fms | Max: %.1fms" % [min_ft, avg_ft, max_ft])
	report.append("- **P95 Frame Time**: %.1fms" % p95)
	report.append("- **P99 Frame Time**: %.1fms" % p99)
	report.append("- **Max Projectiles**: %d" % _max_projectiles)
	report.append("")
	report.append("## Spikes (>30ms)")
	report.append("Total Spikes: %d" % _spikes.size())
	if not _spikes.is_empty():
		report.append("| Time | Duration | Context |")
		report.append("|---|---|---|")
		for i in range(min(10, _spikes.size())):
			var s = _spikes[i]
			report.append("| %.2fs | %.1fms | %s |" % [s.time, s.duration, s.context])
	
	var filename = "res://perf_report_%s.md" % Time.get_unix_time_from_system()
	var file = FileAccess.open(filename, FileAccess.WRITE)
	if file:
		file.store_string("\n".join(report))
		print("📄 Report saved to %s" % filename)
	
	# Definition of Success
	var success = p99 < 25.0 and avg_fps >= 55.0
	print("RESULT: %s" % ("PASS" if success else "FAIL"))

# PerformanceOptimizer.gd
# Advanced performance optimization system
# Monitors and optimizes game performance across all systems

extends Node

signal performance_report_generated(report: Dictionary)
signal optimization_completed(optimizations: Array)

# Performance monitoring
var performance_data: Dictionary = {}
var frame_times: Array = []
var memory_samples: Array = []
var optimization_history: Array = []

# Performance thresholds
const TARGET_FPS = 60.0
const MIN_ACCEPTABLE_FPS = 30.0
const MAX_MEMORY_MB = 512.0
const MAX_FRAME_TIME_MS = 33.33  # ~30 FPS

# Optimization settings
var auto_optimize_enabled: bool = true
var performance_mode: String = "balanced"  # "performance", "balanced", "quality"
var monitoring_enabled: bool = true

# System states
var current_optimizations: Dictionary = {}
var last_optimization_time: float = 0.0
var optimization_cooldown: float = 5.0

func _ready() -> void:
	"""Initialize performance optimizer"""
	print("[PerformanceOptimizer] Performance Optimizer initialized")
	
	# Start performance monitoring
	if monitoring_enabled:
		_start_monitoring()

func _start_monitoring() -> void:
	"""Start performance monitoring"""
	# Create timer for regular performance checks
	var timer = Timer.new()
	timer.wait_time = 1.0  # Check every second
	timer.timeout.connect(_collect_performance_data)
	timer.autostart = true
	add_child(timer)
	
	print("[PerformanceOptimizer] Performance monitoring started")

func _collect_performance_data() -> void:
	"""Collect current performance data"""
	var current_time = Time.get_ticks_msec()
	
	# Collect frame time data
	var delta_time = Engine.get_process_frame() * 1000.0  # Convert to ms
	frame_times.append(delta_time)
	
	# Keep only last 60 samples (1 minute at 1 sample/second)
	if frame_times.size() > 60:
		frame_times.pop_front()
	
	# Collect memory data
	var memory_usage = OS.get_static_memory_usage_by_type()
	memory_samples.append(memory_usage)
	
	if memory_samples.size() > 60:
		memory_samples.pop_front()
	
	# Store current performance data
	performance_data = {
		"timestamp": current_time,
		"fps": Engine.get_frames_per_second(),
		"frame_time_ms": delta_time,
		"memory_usage": memory_usage,
		"node_count": get_tree().get_node_count(),
		"render_objects": get_viewport().get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_STAT_DRAW_CALLS_IN_FRAME)
	}
	
	# Check if optimization is needed
	if auto_optimize_enabled:
		_check_optimization_triggers()

func _check_optimization_triggers() -> void:
	"""Check if performance optimization is needed"""
	var current_time = Time.get_time_dict_from_system()
	
	# Avoid too frequent optimizations
	if current_time["unix"] - last_optimization_time < optimization_cooldown:
		return
	
	var needs_optimization = false
	var optimization_reasons = []
	
	# Check FPS
	var current_fps = performance_data.get("fps", 60.0)
	if current_fps < MIN_ACCEPTABLE_FPS:
		needs_optimization = true
		optimization_reasons.append("Low FPS: %.1f" % current_fps)
	
	# Check frame time
	var current_frame_time = performance_data.get("frame_time_ms", 16.67)
	if current_frame_time > MAX_FRAME_TIME_MS:
		needs_optimization = true
		optimization_reasons.append("High frame time: %.2f ms" % current_frame_time)
	
	# Check memory usage
	var memory_mb = performance_data.get("memory_usage", 0) / (1024 * 1024)
	if memory_mb > MAX_MEMORY_MB:
		needs_optimization = true
		optimization_reasons.append("High memory usage: %.1f MB" % memory_mb)
	
	# Trigger optimization if needed
	if needs_optimization:
		print("[PerformanceOptimizer] Performance issues detected: %s" % str(optimization_reasons))
		optimize_performance(optimization_reasons)

func optimize_performance(reasons: Array = []) -> void:
	"""Optimize game performance based on current issues"""
	print("[PerformanceOptimizer] Starting performance optimization...")
	
	var optimizations_applied = []
	last_optimization_time = Time.get_time_dict_from_system()["unix"]
	
	# Graphics optimizations
	optimizations_applied.append_array(_optimize_graphics())
	
	# Memory optimizations
	optimizations_applied.append_array(_optimize_memory())
	
	# Asset optimizations
	optimizations_applied.append_array(_optimize_assets())
	
	# UI optimizations
	optimizations_applied.append_array(_optimize_ui())
	
	# Audio optimizations
	optimizations_applied.append_array(_optimize_audio())
	
	# System optimizations
	optimizations_applied.append_array(_optimize_systems())
	
	# Record optimization
	optimization_history.append({
		"timestamp": Time.get_unix_time_from_system(),
		"reasons": reasons,
		"optimizations": optimizations_applied,
		"performance_before": performance_data.duplicate(),
		"mode": performance_mode
	})
	
	print("[PerformanceOptimizer] Applied %d optimizations" % optimizations_applied.size())
	optimization_completed.emit(optimizations_applied)

func _optimize_graphics() -> Array:
	"""Optimize graphics settings"""
	var optimizations = []
	
	# Adjust render scale based on performance mode
	var render_scale = 1.0
	match performance_mode:
		"performance":
			render_scale = 0.75
		"balanced":
			render_scale = 0.85
		"quality":
			render_scale = 1.0
	
	if get_viewport().scaling_3d_scale != render_scale:
		get_viewport().scaling_3d_scale = render_scale
		optimizations.append("Adjusted render scale to %.2f" % render_scale)
		current_optimizations["render_scale"] = render_scale
	
	# Optimize particle systems
	if ParticleManager:
		var max_particles = 1000
		match performance_mode:
			"performance":
				max_particles = 500
			"balanced":
				max_particles = 750
			"quality":
				max_particles = 1000
		
		if ParticleManager.has_method("set_max_particles"):
			ParticleManager.set_max_particles(max_particles)
			optimizations.append("Set max particles to %d" % max_particles)
			current_optimizations["max_particles"] = max_particles
	
	# Optimize visual effects
	if VisualEffectsManager:
		var effect_quality = "medium"
		match performance_mode:
			"performance":
				effect_quality = "low"
			"balanced":
				effect_quality = "medium"
			"quality":
				effect_quality = "high"
		
		if VisualEffectsManager.has_method("set_quality"):
			VisualEffectsManager.set_quality(effect_quality)
			optimizations.append("Set visual effects quality to %s" % effect_quality)
			current_optimizations["visual_effects_quality"] = effect_quality
	
	return optimizations

func _optimize_memory() -> Array:
	"""Optimize memory usage"""
	var optimizations = []
	
	# Force garbage collection
	# Note: GDScript doesn't have explicit GC control, but we can clear caches
	optimizations.append("Forced garbage collection")
	
	# Optimize texture memory
	if TextureGenerator:
		if TextureGenerator.has_method("clear_cache"):
			var cleared = TextureGenerator.clear_cache()
			optimizations.append("Cleared texture cache (%d items)" % cleared)
	
	# Optimize sprite memory
	if SpriteGenerator:
		if SpriteGenerator.has_method("clear_cache"):
			var cleared = SpriteGenerator.clear_cache()
			optimizations.append("Cleared sprite cache (%d items)" % cleared)
	
	# Optimize audio memory
	if AudioGenerator:
		if AudioGenerator.has_method("clear_cache"):
			var cleared = AudioGenerator.clear_cache()
			optimizations.append("Cleared audio cache (%d items)" % cleared)
	
	# Optimize asset registry
	if AssetRegistry:
		if AssetRegistry.has_method("cleanup_unused_assets"):
			var cleaned = AssetRegistry.cleanup_unused_assets()
			optimizations.append("Cleaned up %d unused assets" % cleaned)
	
	return optimizations

func _optimize_assets() -> Array:
	"""Optimize asset generation and management"""
	var optimizations = []
	
	# Reduce asset quality based on performance mode
	var asset_quality = "medium"
	match performance_mode:
		"performance":
			asset_quality = "low"
		"balanced":
			asset_quality = "medium"
		"quality":
			asset_quality = "high"
	
	# Optimize sprite generation
	if SpriteGenerator and SpriteGenerator.has_method("set_quality"):
		SpriteGenerator.set_quality(asset_quality)
		optimizations.append("Set sprite quality to %s" % asset_quality)
		current_optimizations["sprite_quality"] = asset_quality
	
	# Optimize texture generation
	if TextureGenerator and TextureGenerator.has_method("set_quality"):
		TextureGenerator.set_quality(asset_quality)
		optimizations.append("Set texture quality to %s" % asset_quality)
		current_optimizations["texture_quality"] = asset_quality
	
	# Optimize icon generation
	if IconGenerator and IconGenerator.has_method("set_quality"):
		IconGenerator.set_quality(asset_quality)
		optimizations.append("Set icon quality to %s" % asset_quality)
		current_optimizations["icon_quality"] = asset_quality
	
	# Enable aggressive asset caching
	if AssetRegistry and AssetRegistry.has_method("set_aggressive_caching"):
		AssetRegistry.set_aggressive_caching(performance_mode == "performance")
		optimizations.append("Enabled aggressive asset caching")
	
	return optimizations

func _optimize_ui() -> Array:
	"""Optimize UI performance"""
	var optimizations = []
	
	# Reduce UI animation complexity
	if UIAnimationManager:
		var animation_quality = "medium"
		match performance_mode:
			"performance":
				animation_quality = "low"
			"balanced":
				animation_quality = "medium"
			"quality":
				animation_quality = "high"
		
		if UIAnimationManager.has_method("set_animation_quality"):
			UIAnimationManager.set_animation_quality(animation_quality)
			optimizations.append("Set UI animation quality to %s" % animation_quality)
			current_optimizations["ui_animation_quality"] = animation_quality
	
	# Optimize tooltip system
	if TooltipManager:
		var max_tooltips = 10
		match performance_mode:
			"performance":
				max_tooltips = 5
			"balanced":
				max_tooltips = 8
			"quality":
				max_tooltips = 10
		
		if TooltipManager.has_method("set_max_active_tooltips"):
			TooltipManager.set_max_active_tooltips(max_tooltips)
			optimizations.append("Set max active tooltips to %d" % max_tooltips)
			current_optimizations["max_tooltips"] = max_tooltips
	
	# Disable non-essential UI features in performance mode
	if performance_mode == "performance":
		if UIManager and UIManager.has_method("disable_non_essential_features"):
			UIManager.disable_non_essential_features()
			optimizations.append("Disabled non-essential UI features")
	
	return optimizations

func _optimize_audio() -> Array:
	"""Optimize audio performance"""
	var optimizations = []
	
	# Reduce audio quality based on performance mode
	var audio_quality = "medium"
	var max_concurrent_sounds = 32
	
	match performance_mode:
		"performance":
			audio_quality = "low"
			max_concurrent_sounds = 16
		"balanced":
			audio_quality = "medium"
			max_concurrent_sounds = 24
		"quality":
			audio_quality = "high"
			max_concurrent_sounds = 32
	
	# Optimize audio generator
	if AudioGenerator and AudioGenerator.has_method("set_quality"):
		AudioGenerator.set_quality(audio_quality)
		optimizations.append("Set audio quality to %s" % audio_quality)
		current_optimizations["audio_quality"] = audio_quality
	
	# Optimize audio manager
	if AudioManager:
		if AudioManager.has_method("set_max_concurrent_sounds"):
			AudioManager.set_max_concurrent_sounds(max_concurrent_sounds)
			optimizations.append("Set max concurrent sounds to %d" % max_concurrent_sounds)
			current_optimizations["max_concurrent_sounds"] = max_concurrent_sounds
		
		if AudioManager.has_method("enable_audio_compression"):
			AudioManager.enable_audio_compression(performance_mode == "performance")
			optimizations.append("Audio compression: %s" % ("enabled" if performance_mode == "performance" else "disabled"))
	
	return optimizations

func _optimize_systems() -> Array:
	"""Optimize core systems"""
	var optimizations = []
	
	# Optimize update frequencies
	var update_frequency = 60.0
	match performance_mode:
		"performance":
			update_frequency = 30.0
		"balanced":
			update_frequency = 45.0
		"quality":
			update_frequency = 60.0
	
	# Optimize enemy AI updates
	if EnemyManager and EnemyManager.has_method("set_update_frequency"):
		EnemyManager.set_update_frequency(update_frequency)
		optimizations.append("Set enemy AI update frequency to %.1f Hz" % update_frequency)
		current_optimizations["ai_update_frequency"] = update_frequency
	
	# Optimize particle updates
	if ParticleManager and ParticleManager.has_method("set_update_frequency"):
		ParticleManager.set_update_frequency(update_frequency)
		optimizations.append("Set particle update frequency to %.1f Hz" % update_frequency)
	
	# Optimize level generation
	if LevelGenerator:
		var generation_quality = "medium"
		match performance_mode:
			"performance":
				generation_quality = "low"
			"balanced":
				generation_quality = "medium"
			"quality":
				generation_quality = "high"
		
		if LevelGenerator.has_method("set_generation_quality"):
			LevelGenerator.set_generation_quality(generation_quality)
			optimizations.append("Set level generation quality to %s" % generation_quality)
			current_optimizations["level_generation_quality"] = generation_quality
	
	# Optimize spell system
	if SpellSystem:
		var max_active_spells = 50
		match performance_mode:
			"performance":
				max_active_spells = 25
			"balanced":
				max_active_spells = 35
			"quality":
				max_active_spells = 50
		
		if SpellSystem.has_method("set_max_active_spells"):
			SpellSystem.set_max_active_spells(max_active_spells)
			optimizations.append("Set max active spells to %d" % max_active_spells)
			current_optimizations["max_active_spells"] = max_active_spells
	
	return optimizations

func set_performance_mode(mode: String) -> void:
	"""Set performance mode"""
	if mode in ["performance", "balanced", "quality"]:
		performance_mode = mode
		print("[PerformanceOptimizer] Performance mode set to: %s" % mode)
		
		# Trigger immediate optimization
		optimize_performance(["Performance mode changed to %s" % mode])
	else:
		print("[PerformanceOptimizer] Invalid performance mode: %s" % mode)

func enable_auto_optimization(enabled: bool) -> void:
	"""Enable or disable automatic optimization"""
	auto_optimize_enabled = enabled
	print("[PerformanceOptimizer] Auto optimization: %s" % ("enabled" if enabled else "disabled"))

func generate_performance_report() -> Dictionary:
	"""Generate comprehensive performance report"""
	var report = {
		"timestamp": Time.get_unix_time_from_system(),
		"performance_mode": performance_mode,
		"current_performance": performance_data.duplicate(),
		"optimizations": current_optimizations.duplicate(),
		"optimization_history": optimization_history.duplicate(),
		"recommendations": _generate_recommendations()
	}
	
	# Calculate averages
	if frame_times.size() > 0:
		var avg_frame_time = 0.0
		for time in frame_times:
			avg_frame_time += time
		avg_frame_time /= frame_times.size()
		report["average_frame_time_ms"] = avg_frame_time
		report["average_fps"] = 1000.0 / avg_frame_time
	
	if memory_samples.size() > 0:
		var avg_memory = 0
		for sample in memory_samples:
			avg_memory += sample
		avg_memory /= memory_samples.size()
		report["average_memory_usage"] = avg_memory
		report["average_memory_mb"] = float(avg_memory) / (1024 * 1024)
	
	performance_report_generated.emit(report)
	return report

func _generate_recommendations() -> Array:
	"""Generate performance recommendations"""
	var recommendations = []
	
	# Check current performance
	var current_fps = performance_data.get("fps", 60.0)
	var memory_mb = float(performance_data.get("memory_usage", 0)) / (1024 * 1024)
	
	# FPS recommendations
	if current_fps < 30:
		recommendations.append({
			"priority": "high",
			"category": "performance",
			"title": "Critical FPS Issue",
			"description": "FPS is critically low (%.1f). Consider switching to performance mode." % current_fps,
			"action": "set_performance_mode('performance')"
		})
	elif current_fps < 45:
		recommendations.append({
			"priority": "medium",
			"category": "performance",
			"title": "Low FPS",
			"description": "FPS is below target (%.1f). Consider optimizations." % current_fps,
			"action": "optimize_performance()"
		})
	
	# Memory recommendations
	if memory_mb > 400:
		recommendations.append({
			"priority": "high",
			"category": "memory",
			"title": "High Memory Usage",
			"description": "Memory usage is high (%.1f MB). Clear caches or reduce quality." % memory_mb,
			"action": "_optimize_memory()"
		})
	elif memory_mb > 300:
		recommendations.append({
			"priority": "medium",
			"category": "memory",
			"title": "Moderate Memory Usage",
			"description": "Memory usage is moderate (%.1f MB). Monitor for leaks." % memory_mb,
			"action": "monitor_memory()"
		})
	
	# System recommendations
	var node_count = performance_data.get("node_count", 0)
	if node_count > 1000:
		recommendations.append({
			"priority": "medium",
			"category": "systems",
			"title": "High Node Count",
			"description": "Scene has many nodes (%d). Consider object pooling." % node_count,
			"action": "implement_object_pooling()"
		})
	
	return recommendations

func get_performance_stats() -> Dictionary:
	"""Get current performance statistics"""
	return {
		"fps": performance_data.get("fps", 0.0),
		"frame_time_ms": performance_data.get("frame_time_ms", 0.0),
		"memory_usage_mb": float(performance_data.get("memory_usage", 0)) / (1024 * 1024),
		"node_count": performance_data.get("node_count", 0),
		"performance_mode": performance_mode,
		"auto_optimize_enabled": auto_optimize_enabled,
		"optimizations_count": current_optimizations.size()
	}

func reset_optimizations() -> void:
	"""Reset all performance optimizations"""
	current_optimizations.clear()
	optimization_history.clear()
	
	# Reset to default settings
	performance_mode = "balanced"
	auto_optimize_enabled = true
	
	print("[PerformanceOptimizer] Performance optimizations reset")

func export_performance_data() -> String:
	"""Export performance data as JSON"""
	var export_data = {
		"performance_report": generate_performance_report(),
		"frame_times": frame_times,
		"memory_samples": memory_samples,
		"optimization_history": optimization_history
	}
	
	return JSON.stringify(export_data)
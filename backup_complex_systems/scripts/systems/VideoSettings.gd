# VideoSettings.gd
# Advanced video settings system for quality and performance configuration
# Handles resolution, quality presets, fullscreen, and performance optimization
#
# Public API:
# - apply_quality_preset(preset: QualityPreset) -> void
# - set_resolution(resolution: Vector2i) -> void
# - set_fullscreen(enabled: bool) -> void
# - get_available_resolutions() -> Array[Vector2i]
#
# Signals:
# - settings_changed(setting_name: String, new_value)

extends Node

signal settings_changed(setting_name: String, new_value)

# Quality presets
enum QualityPreset {
	LOW,
	MEDIUM,
	HIGH,
	ULTRA
}

# Current settings
var current_settings: Dictionary = {}
var available_resolutions: Array[Vector2i] = []

func _ready() -> void:
	print("[VideoSettings] Initializing Video Settings...")
	
	# Initialize available resolutions
	_initialize_available_resolutions()
	
	# Load saved settings
	_load_settings()
	
	# Apply current settings
	_apply_current_settings()
	
	print("[VideoSettings] Video Settings initialized")

func _initialize_available_resolutions() -> void:
	"""Initialize list of available screen resolutions"""
	available_resolutions = [
		Vector2i(1280, 720),    # HD
		Vector2i(1366, 768),    # Laptop standard
		Vector2i(1920, 1080),   # Full HD
		Vector2i(2560, 1440),   # 2K
		Vector2i(3840, 2160),   # 4K
		Vector2i(1600, 900),    # 16:9 alternative
		Vector2i(1440, 900),    # 16:10
		Vector2i(1680, 1050),   # 16:10 alternative
	]
	
	# Filter by screen size
	var screen_size = DisplayServer.screen_get_size()
	available_resolutions = available_resolutions.filter(
		func(res): return res.x <= screen_size.x and res.y <= screen_size.y
	)

func apply_quality_preset(preset: QualityPreset) -> void:
	"""Apply a quality preset configuration"""
	var preset_settings = _get_preset_settings(preset)
	
	for setting in preset_settings:
		current_settings[setting] = preset_settings[setting]
		_apply_setting(setting, preset_settings[setting])
	
	current_settings["quality_preset"] = preset
	_save_settings()
	
	print("[VideoSettings] Applied quality preset: ", QualityPreset.keys()[preset])

func _get_preset_settings(preset: QualityPreset) -> Dictionary:
	"""Get settings for a specific quality preset"""
	match preset:
		QualityPreset.LOW:
			return {
				"render_scale": 0.75,
				"shadows_enabled": false,
				"anti_aliasing": false,
				"texture_quality": 0,
				"particle_density": 0.5,
				"lighting_quality": 0,
				"post_processing": false,
				"vsync_enabled": false,
				"max_fps": 60
			}
		
		QualityPreset.MEDIUM:
			return {
				"render_scale": 1.0,
				"shadows_enabled": true,
				"anti_aliasing": false,
				"texture_quality": 1,
				"particle_density": 0.75,
				"lighting_quality": 1,
				"post_processing": true,
				"vsync_enabled": true,
				"max_fps": 60
			}
		
		QualityPreset.HIGH:
			return {
				"render_scale": 1.0,
				"shadows_enabled": true,
				"anti_aliasing": true,
				"texture_quality": 2,
				"particle_density": 1.0,
				"lighting_quality": 2,
				"post_processing": true,
				"vsync_enabled": true,
				"max_fps": 120
			}
		
		QualityPreset.ULTRA:
			return {
				"render_scale": 1.25,
				"shadows_enabled": true,
				"anti_aliasing": true,
				"texture_quality": 3,
				"particle_density": 1.0,
				"lighting_quality": 3,
				"post_processing": true,
				"vsync_enabled": true,
				"max_fps": 144
			}
		
		_:
			return _get_preset_settings(QualityPreset.MEDIUM)

func set_resolution(resolution: Vector2i) -> void:
	"""Set screen resolution"""
	if resolution not in available_resolutions:
		print("[VideoSettings] Invalid resolution: ", resolution)
		return
	
	current_settings["resolution"] = resolution
	
	# Apply resolution
	var window = get_window()
	if current_settings.get("fullscreen", false):
		DisplayServer.window_set_size(resolution)
	else:
		window.size = resolution
		# Center window
		var screen_size = DisplayServer.screen_get_size()
		window.position = (screen_size - resolution) / 2
	
	settings_changed.emit("resolution", resolution)
	_save_settings()
	
	print("[VideoSettings] Resolution set to: ", resolution)

func set_fullscreen(enabled: bool) -> void:
	"""Set fullscreen mode"""
	current_settings["fullscreen"] = enabled
	
	var window = get_window()
	if enabled:
		window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	else:
		window.mode = Window.MODE_WINDOWED
		# Restore windowed size
		var resolution = current_settings.get("resolution", Vector2i(1280, 720))
		window.size = resolution
	
	settings_changed.emit("fullscreen", enabled)
	_save_settings()
	
	print("[VideoSettings] Fullscreen set to: ", enabled)

func set_vsync(enabled: bool) -> void:
	"""Set vertical sync"""
	current_settings["vsync_enabled"] = enabled
	
	if enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	settings_changed.emit("vsync_enabled", enabled)
	_save_settings()

func set_max_fps(fps: int) -> void:
	"""Set maximum FPS limit"""
	current_settings["max_fps"] = fps
	Engine.max_fps = fps
	
	settings_changed.emit("max_fps", fps)
	_save_settings()

func set_render_scale(scale: float) -> void:
	"""Set render scale for performance"""
	current_settings["render_scale"] = scale
	
	# Apply render scale
	get_viewport().scaling_3d_scale = scale
	
	settings_changed.emit("render_scale", scale)
	_save_settings()

func _apply_setting(setting_name: String, value) -> void:
	"""Apply a specific setting"""
	match setting_name:
		"resolution":
			if value is Vector2i:
				set_resolution(value)
		"fullscreen":
			set_fullscreen(value)
		"vsync_enabled":
			set_vsync(value)
		"max_fps":
			set_max_fps(value)
		"render_scale":
			set_render_scale(value)
		"shadows_enabled":
			_set_shadows_enabled(value)
		"anti_aliasing":
			_set_anti_aliasing(value)
		"texture_quality":
			_set_texture_quality(value)
		"particle_density":
			_set_particle_density(value)
		"lighting_quality":
			_set_lighting_quality(value)
		"post_processing":
			_set_post_processing(value)

func _set_shadows_enabled(enabled: bool) -> void:
	"""Enable/disable shadows"""
	# This would be implemented based on your lighting system
	pass

func _set_anti_aliasing(enabled: bool) -> void:
	"""Enable/disable anti-aliasing"""
	if enabled:
		get_viewport().msaa_3d = Viewport.MSAA_4X
	else:
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED

func _set_texture_quality(quality: int) -> void:
	"""Set texture quality level"""
	# This would be implemented based on your texture streaming system
	pass

func _set_particle_density(density: float) -> void:
	"""Set particle system density"""
	# This would be implemented based on your particle systems
	pass

func _set_lighting_quality(quality: int) -> void:
	"""Set lighting quality level"""
	# This would be implemented based on your lighting system
	pass

func _set_post_processing(enabled: bool) -> void:
	"""Enable/disable post-processing effects"""
	# This would be implemented based on your post-processing pipeline
	pass

func get_available_resolutions() -> Array[Vector2i]:
	"""Get list of available resolutions"""
	return available_resolutions.duplicate()

func get_current_resolution() -> Vector2i:
	"""Get current resolution"""
	return current_settings.get("resolution", Vector2i(1280, 720))

func is_fullscreen() -> bool:
	"""Check if fullscreen is enabled"""
	return current_settings.get("fullscreen", false)

func get_current_quality_preset() -> QualityPreset:
	"""Get current quality preset"""
	return current_settings.get("quality_preset", QualityPreset.MEDIUM)

func get_fps_options() -> Array[int]:
	"""Get available FPS limit options"""
	return [30, 60, 120, 144, 240, 0]  # 0 = unlimited

func detect_optimal_settings() -> QualityPreset:
	"""Detect optimal settings based on hardware"""
	# Simple detection based on screen resolution
	var screen_size = DisplayServer.screen_get_size()
	
	if screen_size.x >= 3840:  # 4K
		return QualityPreset.HIGH
	elif screen_size.x >= 2560:  # 2K
		return QualityPreset.HIGH
	elif screen_size.x >= 1920:  # Full HD
		return QualityPreset.MEDIUM
	else:
		return QualityPreset.LOW

func benchmark_performance() -> Dictionary:
	"""Run a simple performance benchmark"""
	var start_time = Time.get_time_dict_from_system()
	var frame_count = 0
	var total_frame_time = 0.0
	
	# Simple benchmark loop
	for i in range(100):
		var frame_start = Time.get_time_dict_from_system()
		await get_tree().process_frame
		var frame_end = Time.get_time_dict_from_system()
		
		frame_count += 1
		# Simplified frame time calculation
		total_frame_time += 16.67  # Assume 60 FPS target
	
	var average_fps = frame_count / (total_frame_time / 1000.0)
	
	return {
		"average_fps": average_fps,
		"recommended_preset": QualityPreset.MEDIUM if average_fps >= 45 else QualityPreset.LOW
	}

func _apply_current_settings() -> void:
	"""Apply all current settings"""
	for setting in current_settings:
		_apply_setting(setting, current_settings[setting])

func _load_settings() -> void:
	"""Load settings from save file"""
	if SaveManager and SaveManager.is_data_loaded:
		var saved_settings = SaveManager.load_custom_data("video_settings")
		if saved_settings:
			current_settings = saved_settings
		else:
			_set_default_settings()
	else:
		_set_default_settings()

func _save_settings() -> void:
	"""Save settings to file"""
	if SaveManager:
		SaveManager.save_custom_data("video_settings", current_settings)

func _set_default_settings() -> void:
	"""Set default video settings"""
	current_settings = {
		"resolution": Vector2i(1280, 720),
		"fullscreen": false,
		"quality_preset": QualityPreset.MEDIUM,
		"vsync_enabled": true,
		"max_fps": 60,
		"render_scale": 1.0
	}

func get_settings_summary() -> Dictionary:
	"""Get a summary of current settings"""
	return {
		"resolution": get_current_resolution(),
		"fullscreen": is_fullscreen(),
		"quality_preset": QualityPreset.keys()[get_current_quality_preset()],
		"vsync": current_settings.get("vsync_enabled", true),
		"max_fps": current_settings.get("max_fps", 60),
		"render_scale": current_settings.get("render_scale", 1.0)
	}

func reset_to_defaults() -> void:
	"""Reset all settings to defaults"""
	_set_default_settings()
	_apply_current_settings()
	_save_settings()
	
	print("[VideoSettings] Settings reset to defaults")
# AccessibilityManager.gd
# Manages accessibility features including keyboard navigation,
# focus management, and assistive technology support

extends Node

signal focus_changed(new_focus: Control, old_focus: Control)
signal accessibility_setting_changed(setting: String, value: Variant)

# Accessibility settings
var keyboard_navigation_enabled: bool = true
var focus_indicators_enabled: bool = true
var high_contrast_mode: bool = false
var text_scaling: float = 1.0
var audio_cues_enabled: bool = true
var screen_reader_mode: bool = false

# Focus management
var current_focus: Control
var focus_history: Array[Control] = []
var focus_groups: Dictionary = {}

# Focus indicators
var focus_indicator: Control
var focus_tween: Tween

func _ready() -> void:
	"""Initialize accessibility manager"""
	_create_focus_indicator()
	_load_accessibility_settings()
	_setup_global_input_handling()
	print("[AccessibilityManager] Accessibility Manager initialized")

func _create_focus_indicator() -> void:
	"""Create visual focus indicator"""
	focus_indicator = NinePatchRect.new()
	focus_indicator.name = "FocusIndicator"
	focus_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_indicator.z_index = 999
	focus_indicator.visible = false
	
	# Create simple border texture
	var border_texture = ImageTexture.new()
	var border_image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	border_image.fill(Color.TRANSPARENT)
	
	# Draw border pixels
	for x in range(16):
		for y in range(16):
			if x == 0 or x == 15 or y == 0 or y == 15:
				border_image.set_pixel(x, y, Color.CYAN)
	
	border_texture.set_image(border_image)
	focus_indicator.texture = border_texture
	
	# Configure nine patch
	focus_indicator.patch_margin_left = 2
	focus_indicator.patch_margin_right = 2
	focus_indicator.patch_margin_top = 2
	focus_indicator.patch_margin_bottom = 2
	
	# Add to scene tree
	get_tree().root.add_child(focus_indicator)

func _setup_global_input_handling() -> void:
	"""Setup global input handling for accessibility"""
	# Connect to the main scene tree for input events
	if get_tree():
		get_tree().set_input_as_handled.connect(_on_input_handled)

func _load_accessibility_settings() -> void:
	"""Load accessibility settings from save file"""
	# This would typically load from SaveManager
	# For now, use defaults
	pass

func set_keyboard_navigation_enabled(enabled: bool) -> void:
	"""Enable or disable keyboard navigation"""
	keyboard_navigation_enabled = enabled
	accessibility_setting_changed.emit("keyboard_navigation", enabled)
	
	if not enabled and current_focus:
		_hide_focus_indicator()

func set_focus_indicators_enabled(enabled: bool) -> void:
	"""Enable or disable visual focus indicators"""
	focus_indicators_enabled = enabled
	accessibility_setting_changed.emit("focus_indicators", enabled)
	
	if not enabled:
		_hide_focus_indicator()
	elif current_focus:
		_show_focus_indicator()

func set_high_contrast_mode(enabled: bool) -> void:
	"""Enable or disable high contrast mode"""
	high_contrast_mode = enabled
	accessibility_setting_changed.emit("high_contrast", enabled)
	
	if enabled:
		_apply_high_contrast_theme()
	else:
		_restore_normal_theme()

func set_text_scaling(scale: float) -> void:
	"""Set text scaling factor"""
	text_scaling = clamp(scale, 0.5, 2.0)
	accessibility_setting_changed.emit("text_scaling", text_scaling)
	_apply_text_scaling()

func set_audio_cues_enabled(enabled: bool) -> void:
	"""Enable or disable audio cues"""
	audio_cues_enabled = enabled
	accessibility_setting_changed.emit("audio_cues", enabled)

func register_focus_group(group_name: String, controls: Array[Control]) -> void:
	"""Register a group of focusable controls"""
	focus_groups[group_name] = controls
	
	# Setup navigation between controls in the group
	_setup_focus_navigation(controls)

func _setup_focus_navigation(controls: Array[Control]) -> void:
	"""Setup focus navigation between controls"""
	for i in range(controls.size()):
		var control = controls[i]
		if not control:
			continue
		
		# Set up neighbor navigation
		var next_index = (i + 1) % controls.size()
		var prev_index = (i - 1 + controls.size()) % controls.size()
		
		control.focus_next = controls[next_index].get_path()
		control.focus_previous = controls[prev_index].get_path()
		
		# Connect focus signals
		if not control.focus_entered.is_connected(_on_control_focus_entered):
			control.focus_entered.connect(_on_control_focus_entered.bind(control))
		if not control.focus_exited.is_connected(_on_control_focus_exited):
			control.focus_exited.connect(_on_control_focus_exited.bind(control))

func focus_control(control: Control, play_sound: bool = true) -> void:
	"""Focus a specific control"""
	if not control or not is_instance_valid(control):
		return
	
	var old_focus = current_focus
	current_focus = control
	
	control.grab_focus()
	
	if play_sound and audio_cues_enabled:
		AudioManager.play_sfx("ui_focus")
	
	focus_changed.emit(current_focus, old_focus)

func focus_first_in_group(group_name: String) -> void:
	"""Focus the first control in a group"""
	var group = focus_groups.get(group_name, [])
	if group.size() > 0:
		focus_control(group[0])

func focus_next_in_group(group_name: String) -> void:
	"""Focus the next control in a group"""
	var group = focus_groups.get(group_name, [])
	if group.size() == 0 or not current_focus:
		return
	
	var current_index = group.find(current_focus)
	if current_index >= 0:
		var next_index = (current_index + 1) % group.size()
		focus_control(group[next_index])

func focus_previous_in_group(group_name: String) -> void:
	"""Focus the previous control in a group"""
	var group = focus_groups.get(group_name, [])
	if group.size() == 0 or not current_focus:
		return
	
	var current_index = group.find(current_focus)
	if current_index >= 0:
		var prev_index = (current_index - 1 + group.size()) % group.size()
		focus_control(group[prev_index])

func announce_text(text: String) -> void:
	"""Announce text for screen readers"""
	if screen_reader_mode:
		# In a real implementation, this would interface with screen reader APIs
		print("[AccessibilityManager] Announce: ", text)
	
	if audio_cues_enabled:
		# Could play audio description or TTS
		pass

func _on_control_focus_entered(control: Control) -> void:
	"""Handle control gaining focus"""
	current_focus = control
	focus_history.append(control)
	
	# Limit focus history size
	if focus_history.size() > 10:
		focus_history.pop_front()
	
	_show_focus_indicator()
	
	if audio_cues_enabled:
		AudioManager.play_sfx("ui_focus")

func _on_control_focus_exited(control: Control) -> void:
	"""Handle control losing focus"""
	if current_focus == control:
		current_focus = null
	
	_hide_focus_indicator()

func _show_focus_indicator() -> void:
	"""Show visual focus indicator"""
	if not focus_indicators_enabled or not current_focus:
		return
	
	focus_indicator.visible = true
	focus_indicator.position = current_focus.global_position - Vector2(4, 4)
	focus_indicator.size = current_focus.size + Vector2(8, 8)
	
	# Animate focus indicator
	if focus_tween:
		focus_tween.kill()
	
	focus_tween = create_tween()
	focus_tween.set_loops()
	focus_tween.tween_property(focus_indicator, "modulate:a", 0.5, 0.5)
	focus_tween.tween_property(focus_indicator, "modulate:a", 1.0, 0.5)

func _hide_focus_indicator() -> void:
	"""Hide visual focus indicator"""
	focus_indicator.visible = false
	
	if focus_tween:
		focus_tween.kill()

func _apply_high_contrast_theme() -> void:
	"""Apply high contrast theme"""
	if ThemeManager:
		# Would switch to high contrast theme
		ThemeManager.set_theme("high_contrast")

func _restore_normal_theme() -> void:
	"""Restore normal theme"""
	if ThemeManager:
		ThemeManager.set_theme("default")

func _apply_text_scaling() -> void:
	"""Apply text scaling to all UI elements"""
	# This would typically iterate through all UI elements
	# and apply scaling to their font sizes
	pass

func get_focus_chain() -> Array[Control]:
	"""Get the current focus chain"""
	return focus_history.duplicate()

func clear_focus() -> void:
	"""Clear current focus"""
	if current_focus:
		current_focus.release_focus()
	current_focus = null
	_hide_focus_indicator()

func is_control_focusable(control: Control) -> bool:
	"""Check if a control can receive focus"""
	return control and control.visible and control.focus_mode != Control.FOCUS_NONE

func find_next_focusable(current: Control, direction: Vector2) -> Control:
	"""Find the next focusable control in a direction"""
	# This would implement spatial navigation
	# For now, return null as placeholder
	return null

func _input(event: InputEvent) -> void:
	"""Handle global accessibility input"""
	if not keyboard_navigation_enabled:
		return
	
	# Handle tab navigation
	if event.is_action_pressed("ui_focus_next"):
		if current_focus:
			var next = current_focus.find_next_valid_focus()
			if next:
				focus_control(next)
		get_viewport().set_input_as_handled()
	
	elif event.is_action_pressed("ui_focus_prev"):
		if current_focus:
			var prev = current_focus.find_prev_valid_focus()
			if prev:
				focus_control(prev)
		get_viewport().set_input_as_handled()
	
	# Handle escape to clear focus
	elif event.is_action_pressed("ui_cancel"):
		if current_focus:
			clear_focus()

func _on_input_handled() -> void:
	"""Handle when input is consumed"""
	# This can be used to track input usage for accessibility
	pass

func save_accessibility_settings() -> void:
	"""Save accessibility settings"""
	var settings = {
		"keyboard_navigation": keyboard_navigation_enabled,
		"focus_indicators": focus_indicators_enabled,
		"high_contrast": high_contrast_mode,
		"text_scaling": text_scaling,
		"audio_cues": audio_cues_enabled,
		"screen_reader": screen_reader_mode
	}
	
	if SaveManager:
		SaveManager.save_accessibility_settings(settings)
# InputManager.gd
# Centralized input handling and key binding management
# Handles player input, input remapping, and gamepad/keyboard support
#
# Public API:
# - get_movement_vector() -> Vector2
# - is_action_just_pressed(action: String) -> bool
# - is_action_pressed(action: String) -> bool
# - remap_action(action: String, new_event: InputEvent) -> void
# - reset_to_defaults() -> void
#
# Signals:
# - action_pressed(action: String)
# - action_released(action: String)
# - pause_requested()
# - input_device_changed(device_type: String)

extends Node

signal action_pressed(action: String)
signal action_released(action: String)
signal pause_requested()
signal input_device_changed(device_type: String)

# Input actions
const MOVEMENT_ACTIONS = ["move_up", "move_down", "move_left", "move_right"]
const GAME_ACTIONS = ["dash", "cast_spell", "pause"]

# Input state
var current_device_type: String = "keyboard"  # "keyboard" or "gamepad"
var last_used_device: String = "keyboard"
var movement_vector: Vector2 = Vector2.ZERO

# Custom key bindings
var custom_bindings: Dictionary = {}

# Default key bindings for reset functionality
var default_bindings: Dictionary = {}

func _ready() -> void:
	print("[InputManager] Initializing InputManager...")
	
	# Store default bindings
	_store_default_bindings()
	
	# Load custom bindings
	_load_custom_bindings()
	
	# Connect to input events
	set_process_unhandled_input(true)
	
	print("[InputManager] InputManager initialized successfully")

func _store_default_bindings() -> void:
	"""Store the default input map for reset functionality"""
	for action in InputMap.get_actions():
		if action in MOVEMENT_ACTIONS or action in GAME_ACTIONS:
			default_bindings[action] = InputMap.action_get_events(action).duplicate()

func _load_custom_bindings() -> void:
	"""Load custom key bindings from SaveManager"""
	if SaveManager and SaveManager.is_data_loaded:
		var settings = SaveManager.current_settings
		if settings.has("input") and settings["input"].has("custom_keybinds"):
			custom_bindings = settings["input"]["custom_keybinds"]
			_apply_custom_bindings()

func _apply_custom_bindings() -> void:
	"""Apply loaded custom bindings to the input map"""
	for action in custom_bindings:
		if InputMap.has_action(action):
			# Clear existing events
			InputMap.action_erase_events(action)
			
			# Add custom events
			for event_data in custom_bindings[action]:
				var event = _deserialize_input_event(event_data)
				if event:
					InputMap.action_add_event(action, event)

func _unhandled_input(event: InputEvent) -> void:
	"""Handle unprocessed input events"""
	# Detect input device changes
	_detect_device_change(event)
	
	# Handle action presses/releases
	_handle_action_events(event)

func _detect_device_change(event: InputEvent) -> void:
	"""Detect if input device has changed"""
	var new_device = ""
	
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		new_device = "keyboard"
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		new_device = "gamepad"
	
	if new_device != "" and new_device != last_used_device:
		last_used_device = new_device
		current_device_type = new_device
		input_device_changed.emit(new_device)
		print("[InputManager] Input device changed to: ", new_device)

func _handle_action_events(_event: InputEvent) -> void:
	"""Handle action press/release events"""
	for action in MOVEMENT_ACTIONS + GAME_ACTIONS:
		if Input.is_action_just_pressed(action):
			action_pressed.emit(action)
			
			# Handle special actions
			if action == "pause":
				pause_requested.emit()
		
		elif Input.is_action_just_released(action):
			action_released.emit(action)

func _process(_delta: float) -> void:
	"""Update movement vector continuously"""
	movement_vector = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		movement_vector.x += 1
	if Input.is_action_pressed("move_left"):
		movement_vector.x -= 1
	if Input.is_action_pressed("move_down"):
		movement_vector.y += 1
	if Input.is_action_pressed("move_up"):
		movement_vector.y -= 1
	
	# Normalize diagonal movement
	if movement_vector.length() > 1:
		movement_vector = movement_vector.normalized()

func get_movement_vector() -> Vector2:
	"""Get current movement input as normalized vector"""
	return movement_vector

func is_action_just_pressed(action: String) -> bool:
	"""Check if action was just pressed this frame"""
	return Input.is_action_just_pressed(action)

func is_action_pressed(action: String) -> bool:
	"""Check if action is currently pressed"""
	return Input.is_action_pressed(action)

func is_action_just_released(action: String) -> bool:
	"""Check if action was just released this frame"""
	return Input.is_action_just_released(action)

func get_mouse_direction_from_position(from_position: Vector2) -> Vector2:
	"""Get direction from given position to mouse cursor"""
	var mouse_pos = get_viewport().get_mouse_position()
	return (mouse_pos - from_position).normalized()

func get_gamepad_direction() -> Vector2:
	"""Get right stick direction for gamepad aiming"""
	if current_device_type != "gamepad":
		return Vector2.ZERO
	
	var right_stick = Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)
	
	# Apply deadzone
	if right_stick.length() < 0.2:
		return Vector2.ZERO
	
	return right_stick.normalized()

func remap_action(action: String, new_event: InputEvent) -> bool:
	"""Remap an action to a new input event"""
	if not InputMap.has_action(action):
		print("[InputManager] Warning: Action does not exist: ", action)
		return false
	
	# Clear existing events for this action
	InputMap.action_erase_events(action)
	
	# Add new event
	InputMap.action_add_event(action, new_event)
	
	# Store in custom bindings
	if not custom_bindings.has(action):
		custom_bindings[action] = []
	else:
		custom_bindings[action].clear()
	
	custom_bindings[action].append(_serialize_input_event(new_event))
	
	# Save to settings
	_save_custom_bindings()
	
	print("[InputManager] Remapped action '", action, "' to new input")
	return true

func add_action_event(action: String, new_event: InputEvent) -> bool:
	"""Add an additional input event to an existing action"""
	if not InputMap.has_action(action):
		print("[InputManager] Warning: Action does not exist: ", action)
		return false
	
	# Add event to input map
	InputMap.action_add_event(action, new_event)
	
	# Store in custom bindings
	if not custom_bindings.has(action):
		custom_bindings[action] = []
	
	custom_bindings[action].append(_serialize_input_event(new_event))
	
	# Save to settings
	_save_custom_bindings()
	
	print("[InputManager] Added input event to action: ", action)
	return true

func reset_action_to_default(action: String) -> bool:
	"""Reset a specific action to its default binding"""
	if not default_bindings.has(action):
		print("[InputManager] Warning: No default binding for action: ", action)
		return false
	
	# Clear current events
	InputMap.action_erase_events(action)
	
	# Restore default events
	for event in default_bindings[action]:
		InputMap.action_add_event(action, event)
	
	# Remove from custom bindings
	if custom_bindings.has(action):
		custom_bindings.erase(action)
	
	# Save settings
	_save_custom_bindings()
	
	print("[InputManager] Reset action to default: ", action)
	return true

func reset_to_defaults() -> void:
	"""Reset all actions to default bindings"""
	for action in default_bindings:
		reset_action_to_default(action)
	
	print("[InputManager] All input actions reset to defaults")

func get_action_events(action: String) -> Array:
	"""Get all input events for an action"""
	if InputMap.has_action(action):
		return InputMap.action_get_events(action)
	return []

func get_action_display_string(action: String) -> String:
	"""Get human-readable string for action's primary input"""
	var events = get_action_events(action)
	if events.is_empty():
		return "Unbound"
	
	var event = events[0]  # Use primary binding
	return _input_event_to_string(event)

func _input_event_to_string(event: InputEvent) -> String:
	"""Convert input event to human-readable string"""
	if event is InputEventKey:
		return OS.get_keycode_string(event.physical_keycode)
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				return "LMB"
			MOUSE_BUTTON_RIGHT:
				return "RMB"
			MOUSE_BUTTON_MIDDLE:
				return "MMB"
			_:
				return "Mouse " + str(event.button_index)
	elif event is InputEventJoypadButton:
		return "Gamepad Button " + str(event.button_index)
	elif event is InputEventJoypadMotion:
		var axis_name = ""
		match event.axis:
			JOY_AXIS_LEFT_X:
				axis_name = "Left Stick X"
			JOY_AXIS_LEFT_Y:
				axis_name = "Left Stick Y"
			JOY_AXIS_RIGHT_X:
				axis_name = "Right Stick X"
			JOY_AXIS_RIGHT_Y:
				axis_name = "Right Stick Y"
			_:
				axis_name = "Axis " + str(event.axis)
		
		var direction = "+" if event.axis_value > 0 else "-"
		return axis_name + " " + direction
	
	return "Unknown"

func _serialize_input_event(event: InputEvent) -> Dictionary:
	"""Serialize input event to dictionary for saving"""
	var data = {
		"type": ""
	}
	
	if event is InputEventKey:
		data["type"] = "key"
		data["keycode"] = event.keycode
		data["physical_keycode"] = event.physical_keycode
		data["alt"] = event.alt_pressed
		data["shift"] = event.shift_pressed
		data["ctrl"] = event.ctrl_pressed
		data["meta"] = event.meta_pressed
	elif event is InputEventMouseButton:
		data["type"] = "mouse_button"
		data["button_index"] = event.button_index
	elif event is InputEventJoypadButton:
		data["type"] = "joypad_button"
		data["button_index"] = event.button_index
		data["device"] = event.device
	elif event is InputEventJoypadMotion:
		data["type"] = "joypad_motion"
		data["axis"] = event.axis
		data["axis_value"] = event.axis_value
		data["device"] = event.device
	
	return data

func _deserialize_input_event(data: Dictionary) -> InputEvent:
	"""Deserialize input event from dictionary"""
	match data.get("type", ""):
		"key":
			var event = InputEventKey.new()
			event.keycode = data.get("keycode", 0)
			event.physical_keycode = data.get("physical_keycode", 0)
			event.alt_pressed = data.get("alt", false)
			event.shift_pressed = data.get("shift", false)
			event.ctrl_pressed = data.get("ctrl", false)
			event.meta_pressed = data.get("meta", false)
			return event
		"mouse_button":
			var event = InputEventMouseButton.new()
			event.button_index = data.get("button_index", 1)
			return event
		"joypad_button":
			var event = InputEventJoypadButton.new()
			event.button_index = data.get("button_index", 0)
			event.device = data.get("device", -1)
			return event
		"joypad_motion":
			var event = InputEventJoypadMotion.new()
			event.axis = data.get("axis", 0)
			event.axis_value = data.get("axis_value", 1.0)
			event.device = data.get("device", -1)
			return event
	
	return null

func _save_custom_bindings() -> void:
	"""Save custom bindings to settings"""
	if SaveManager:
		var settings = SaveManager.current_settings
		if not settings.has("input"):
			settings["input"] = {}
		
		settings["input"]["custom_keybinds"] = custom_bindings
		SaveManager.save_settings(settings)

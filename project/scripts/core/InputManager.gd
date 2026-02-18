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

signal pause_requested()
signal input_device_changed(device_type: String)

# Input actions
const MOVEMENT_ACTIONS = ["move_up", "move_down", "move_left", "move_right"]
const GAME_ACTIONS = ["dash", "cast_spell", "pause", "toggle_minimap"]

# Input state
var current_device_type: String = "keyboard"  # "keyboard" or "gamepad"
var last_used_device: String = "keyboard"
var movement_vector: Vector2 = Vector2.ZERO

# Custom key bindings
var custom_bindings: Dictionary = {}

# Default key bindings for reset functionality
var default_bindings: Dictionary = {}

func _ready() -> void:
	# Debug desactivado: print("[InputManager] Initializing InputManager...")
	
	# Store default bindings
	_store_default_bindings()

	# Ensure basic movement actions exist and have sensible defaults (WASD + arrows)
	var movement_defaults = {
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT]
	}
	for action in movement_defaults.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		# Ensure at least one binding exists
		if InputMap.action_get_events(action).size() == 0:
			for keycode in movement_defaults[action]:
				var ev = InputEventKey.new()
				ev.physical_keycode = keycode
				ev.pressed = false
				InputMap.action_add_event(action, ev)
	# Ensure toggle_minimap action exists (default to M)
	if not InputMap.has_action("toggle_minimap"):
		InputMap.add_action("toggle_minimap")
		var ev = InputEventKey.new()
		ev.physical_keycode = KEY_M
		ev.pressed = false
		InputMap.action_add_event("toggle_minimap", ev)
	
	# Load custom bindings
	_load_custom_bindings()
	
	# Connect to input events
	set_process_unhandled_input(true)
	# Ensure _process is called to update movement_vector
	set_process(true)
	# Debug desactivado: print("[InputManager] set_process(true) called - will update movement_vector each frame")
	
	# Debug desactivado: print("[InputManager] InputManager initialized successfully")

func _store_default_bindings() -> void:
	"""Store the default input map for reset functionality"""
	for action in InputMap.get_actions():
		if action in MOVEMENT_ACTIONS or action in GAME_ACTIONS:
			default_bindings[action] = InputMap.action_get_events(action).duplicate()

func _load_custom_bindings() -> void:
	"""Load custom key bindings from SaveManager"""
	var save_manager = null
	var _gt = get_tree()
	if _gt and _gt.root:
		save_manager = _gt.root.get_node_or_null("SaveManager")
	if save_manager and save_manager.is_data_loaded:
		var settings = save_manager.current_settings
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
		# Debug desactivado: print("[InputManager] Input device changed to: ", new_device)

# Dedup de pause: evitar emitir pause_requested múltiples veces en el mismo frame
var _pause_emitted_this_frame: bool = false

func _process(_delta: float) -> void:
	"""Update movement vector and per-frame actions"""
	# Emitir pause una sola vez por frame (is_action_just_pressed es per-frame safe en _process)
	if Input.is_action_just_pressed("pause"):
		if not _pause_emitted_this_frame:
			_pause_emitted_this_frame = true
			pause_requested.emit()
	else:
		_pause_emitted_this_frame = false
	# Prefer Input.get_vector for concise movement handling
	movement_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# Note: Input.get_vector returns a Vector2 with Y positive for down; normalize if needed
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
		push_warning("[InputManager] Action does not exist: %s" % action)
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
	
	# Debug desactivado: print("[InputManager] Remapped action '", action, "' to new input")
	return true

func add_action_event(action: String, new_event: InputEvent) -> bool:
	"""Add an additional input event to an existing action"""
	if not InputMap.has_action(action):
		push_warning("[InputManager] Action does not exist: %s" % action)
		return false
	
	# Add event to input map
	InputMap.action_add_event(action, new_event)
	
	# Store in custom bindings
	if not custom_bindings.has(action):
		custom_bindings[action] = []
	
	custom_bindings[action].append(_serialize_input_event(new_event))
	
	# Save to settings
	_save_custom_bindings()
	
	# Debug desactivado: print("[InputManager] Added input event to action: ", action)
	return true

func reset_action_to_default(action: String) -> bool:
	"""Reset a specific action to its default binding"""
	if not default_bindings.has(action):
		push_warning("[InputManager] No default binding for action: %s" % action)
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
	
	# Debug desactivado: print("[InputManager] Reset action to default: ", action)
	return true

func reset_to_defaults() -> void:
	"""Reset all actions to default bindings"""
	for action in default_bindings:
		reset_action_to_default(action)
	
	# Debug desactivado: print("[InputManager] All input actions reset to defaults")

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
	var save_manager = null
	var _gt = get_tree()
	if _gt and _gt.root:
		save_manager = _gt.root.get_node_or_null("SaveManager")
	if save_manager:
		var settings = save_manager.current_settings
		if not settings.has("input"):
			settings["input"] = {}
		
		settings["input"]["custom_keybinds"] = custom_bindings
		save_manager.save_settings(settings)


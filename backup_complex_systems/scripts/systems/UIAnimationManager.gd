# UIAnimationManager.gd
# Manages UI animations and transitions throughout the game
# Provides consistent animation patterns and timing for better UX

extends Node

signal animation_started(animation_name: String)
signal animation_finished(animation_name: String)

# Animation presets
const FAST_DURATION = 0.2
const NORMAL_DURATION = 0.3
const SLOW_DURATION = 0.5

# Easing presets
const EASE_OUT = Tween.EASE_OUT
const EASE_IN = Tween.EASE_IN
const EASE_IN_OUT = Tween.EASE_IN_OUT

# Scale presets
const HOVER_SCALE = 1.05
const PRESS_SCALE = 0.95
const BOUNCE_SCALE = 1.15

# Animation types
enum AnimationType {
	FADE_IN,
	FADE_OUT,
	SLIDE_IN_LEFT,
	SLIDE_IN_RIGHT,
	SLIDE_IN_UP,
	SLIDE_IN_DOWN,
	SLIDE_OUT_LEFT,
	SLIDE_OUT_RIGHT,
	SLIDE_OUT_UP,
	SLIDE_OUT_DOWN,
	SCALE_IN,
	SCALE_OUT,
	BOUNCE,
	PULSE,
	SHAKE,
	ROTATE
}

# Active tweens for cleanup
var active_tweens: Dictionary = {}

func _ready() -> void:
	"""Initialize UI Animation Manager"""
	print("[UIAnimationManager] UI Animation Manager initialized")

func animate_control(control: Control, animation_type: AnimationType, duration: float = NORMAL_DURATION, delay: float = 0.0) -> Tween:
	"""Animate a control with specified animation type"""
	if not control or not is_instance_valid(control):
		print("[UIAnimationManager] Invalid control for animation")
		return null
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Store tween for cleanup
	var animation_id = str(control.get_instance_id()) + "_" + str(animation_type)
	active_tweens[animation_id] = tween
	
	# Clean up when animation finishes
	tween.finished.connect(func(): _cleanup_tween(animation_id))
	
	if delay > 0.0:
		tween.tween_delay(delay)
	
	var animation_name = _get_animation_name(animation_type)
	animation_started.emit(animation_name)
	
	match animation_type:
		AnimationType.FADE_IN:
			_animate_fade_in(control, tween, duration)
		AnimationType.FADE_OUT:
			_animate_fade_out(control, tween, duration)
		AnimationType.SLIDE_IN_LEFT:
			_animate_slide_in_left(control, tween, duration)
		AnimationType.SLIDE_IN_RIGHT:
			_animate_slide_in_right(control, tween, duration)
		AnimationType.SLIDE_IN_UP:
			_animate_slide_in_up(control, tween, duration)
		AnimationType.SLIDE_IN_DOWN:
			_animate_slide_in_down(control, tween, duration)
		AnimationType.SLIDE_OUT_LEFT:
			_animate_slide_out_left(control, tween, duration)
		AnimationType.SLIDE_OUT_RIGHT:
			_animate_slide_out_right(control, tween, duration)
		AnimationType.SLIDE_OUT_UP:
			_animate_slide_out_up(control, tween, duration)
		AnimationType.SLIDE_OUT_DOWN:
			_animate_slide_out_down(control, tween, duration)
		AnimationType.SCALE_IN:
			_animate_scale_in(control, tween, duration)
		AnimationType.SCALE_OUT:
			_animate_scale_out(control, tween, duration)
		AnimationType.BOUNCE:
			_animate_bounce(control, tween, duration)
		AnimationType.PULSE:
			_animate_pulse(control, tween, duration)
		AnimationType.SHAKE:
			_animate_shake(control, tween, duration)
		AnimationType.ROTATE:
			_animate_rotate(control, tween, duration)
	
	tween.finished.connect(func(): animation_finished.emit(animation_name))
	return tween

func setup_button_animations(button: Button) -> void:
	"""Setup hover and press animations for a button"""
	if not button:
		return
	
	var original_scale = button.scale
	
	# Hover effects
	button.mouse_entered.connect(func():
		animate_button_hover(button, true)
		AudioManager.play_sfx("ui_hover")
	)
	
	button.mouse_exited.connect(func():
		animate_button_hover(button, false)
	)
	
	# Press effects
	button.button_down.connect(func():
		animate_button_press(button, true)
	)
	
	button.button_up.connect(func():
		animate_button_press(button, false)
		AudioManager.play_sfx("ui_click")
	)

func animate_button_hover(button: Button, hover: bool) -> void:
	"""Animate button hover state"""
	if not button:
		return
	
	var target_scale = Vector2.ONE * HOVER_SCALE if hover else Vector2.ONE
	var tween = create_tween()
	tween.tween_property(button, "scale", target_scale, FAST_DURATION)
	tween.tween_property(button, "modulate", Color.WHITE if hover else Color(0.9, 0.9, 0.9), FAST_DURATION)

func animate_button_press(button: Button, pressed: bool) -> void:
	"""Animate button press state"""
	if not button:
		return
	
	var target_scale = Vector2.ONE * PRESS_SCALE if pressed else Vector2.ONE * HOVER_SCALE
	var tween = create_tween()
	tween.tween_property(button, "scale", target_scale, FAST_DURATION / 2)

func show_popup_animated(popup: Control, animation_type: AnimationType = AnimationType.SCALE_IN) -> void:
	"""Show popup with animation"""
	if not popup:
		return
	
	popup.visible = true
	popup.modulate.a = 0.0
	popup.scale = Vector2.ZERO if animation_type == AnimationType.SCALE_IN else Vector2.ONE
	
	animate_control(popup, animation_type, NORMAL_DURATION)

func hide_popup_animated(popup: Control, animation_type: AnimationType = AnimationType.SCALE_OUT) -> void:
	"""Hide popup with animation"""
	if not popup:
		return
	
	var tween = animate_control(popup, animation_type, NORMAL_DURATION)
	if tween:
		tween.finished.connect(func(): popup.visible = false)

func animate_notification(notification: Control, message: String, duration: float = 3.0) -> void:
	"""Animate a notification appearing and disappearing"""
	if not notification:
		return
	
	# Set message if it's a label
	if notification is Label:
		notification.text = message
	elif notification.has_method("set_text"):
		notification.set_text(message)
	
	# Slide in from top
	var original_position = notification.position
	notification.position.y -= 50
	notification.visible = true
	notification.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Slide in and fade in
	tween.tween_property(notification, "position", original_position, NORMAL_DURATION)
	tween.tween_property(notification, "modulate:a", 1.0, NORMAL_DURATION)
	
	# Wait and then slide out
	tween.tween_delay(duration)
	tween.tween_property(notification, "position:y", original_position.y - 50, NORMAL_DURATION).set_delay(duration)
	tween.tween_property(notification, "modulate:a", 0.0, NORMAL_DURATION).set_delay(duration)
	
	# Hide when done
	tween.finished.connect(func(): notification.visible = false)

func animate_progress_bar(progress_bar: ProgressBar, target_value: float, duration: float = SLOW_DURATION) -> void:
	"""Animate progress bar to target value"""
	if not progress_bar:
		return
	
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", target_value, duration)

func animate_spell_cooldown(control: Control, cooldown_duration: float) -> void:
	"""Animate spell cooldown overlay"""
	if not control:
		return
	
	# Create cooldown overlay if it doesn't exist
	var overlay = control.get_node_or_null("CooldownOverlay")
	if not overlay:
		overlay = ColorRect.new()
		overlay.name = "CooldownOverlay"
		overlay.color = Color(0, 0, 0, 0.6)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		control.add_child(overlay)
	
	# Animate the overlay
	overlay.visible = true
	overlay.modulate.a = 0.6
	
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, cooldown_duration)
	tween.finished.connect(func(): overlay.visible = false)

# Private animation methods
func _animate_fade_in(control: Control, tween: Tween, duration: float) -> void:
	control.modulate.a = 0.0
	control.visible = true
	tween.tween_property(control, "modulate:a", 1.0, duration)

func _animate_fade_out(control: Control, tween: Tween, duration: float) -> void:
	tween.tween_property(control, "modulate:a", 0.0, duration)

func _animate_slide_in_left(control: Control, tween: Tween, duration: float) -> void:
	var original_pos = control.position
	control.position.x -= control.size.x
	control.visible = true
	tween.tween_property(control, "position", original_pos, duration).set_ease(EASE_OUT)

func _animate_slide_in_right(control: Control, tween: Tween, duration: float) -> void:
	var original_pos = control.position
	control.position.x += control.size.x
	control.visible = true
	tween.tween_property(control, "position", original_pos, duration).set_ease(EASE_OUT)

func _animate_slide_in_up(control: Control, tween: Tween, duration: float) -> void:
	var original_pos = control.position
	control.position.y -= control.size.y
	control.visible = true
	tween.tween_property(control, "position", original_pos, duration).set_ease(EASE_OUT)

func _animate_slide_in_down(control: Control, tween: Tween, duration: float) -> void:
	var original_pos = control.position
	control.position.y += control.size.y
	control.visible = true
	tween.tween_property(control, "position", original_pos, duration).set_ease(EASE_OUT)

func _animate_slide_out_left(control: Control, tween: Tween, duration: float) -> void:
	var target_pos = control.position
	target_pos.x -= control.size.x
	tween.tween_property(control, "position", target_pos, duration).set_ease(EASE_IN)

func _animate_slide_out_right(control: Control, tween: Tween, duration: float) -> void:
	var target_pos = control.position
	target_pos.x += control.size.x
	tween.tween_property(control, "position", target_pos, duration).set_ease(EASE_IN)

func _animate_slide_out_up(control: Control, tween: Tween, duration: float) -> void:
	var target_pos = control.position
	target_pos.y -= control.size.y
	tween.tween_property(control, "position", target_pos, duration).set_ease(EASE_IN)

func _animate_slide_out_down(control: Control, tween: Tween, duration: float) -> void:
	var target_pos = control.position
	target_pos.y += control.size.y
	tween.tween_property(control, "position", target_pos, duration).set_ease(EASE_IN)

func _animate_scale_in(control: Control, tween: Tween, duration: float) -> void:
	control.scale = Vector2.ZERO
	control.visible = true
	tween.tween_property(control, "scale", Vector2.ONE, duration).set_ease(EASE_OUT)

func _animate_scale_out(control: Control, tween: Tween, duration: float) -> void:
	tween.tween_property(control, "scale", Vector2.ZERO, duration).set_ease(EASE_IN)

func _animate_bounce(control: Control, tween: Tween, duration: float) -> void:
	var original_scale = control.scale
	tween.tween_property(control, "scale", original_scale * BOUNCE_SCALE, duration * 0.3)
	tween.tween_property(control, "scale", original_scale, duration * 0.7).set_ease(EASE_OUT)

func _animate_pulse(control: Control, tween: Tween, duration: float) -> void:
	var original_scale = control.scale
	tween.set_loops()
	tween.tween_property(control, "scale", original_scale * 1.1, duration * 0.5)
	tween.tween_property(control, "scale", original_scale, duration * 0.5)

func _animate_shake(control: Control, tween: Tween, duration: float) -> void:
	var original_pos = control.position
	var shake_amount = 5.0
	var shake_count = 10
	
	for i in range(shake_count):
		var offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		tween.tween_property(control, "position", original_pos + offset, duration / shake_count)
	
	tween.tween_property(control, "position", original_pos, duration / shake_count)

func _animate_rotate(control: Control, tween: Tween, duration: float) -> void:
	tween.tween_property(control, "rotation", control.rotation + TAU, duration)

func _get_animation_name(animation_type: AnimationType) -> String:
	"""Get string name for animation type"""
	match animation_type:
		AnimationType.FADE_IN: return "fade_in"
		AnimationType.FADE_OUT: return "fade_out"
		AnimationType.SLIDE_IN_LEFT: return "slide_in_left"
		AnimationType.SLIDE_IN_RIGHT: return "slide_in_right"
		AnimationType.SLIDE_IN_UP: return "slide_in_up"
		AnimationType.SLIDE_IN_DOWN: return "slide_in_down"
		AnimationType.SLIDE_OUT_LEFT: return "slide_out_left"
		AnimationType.SLIDE_OUT_RIGHT: return "slide_out_right"
		AnimationType.SLIDE_OUT_UP: return "slide_out_up"
		AnimationType.SLIDE_OUT_DOWN: return "slide_out_down"
		AnimationType.SCALE_IN: return "scale_in"
		AnimationType.SCALE_OUT: return "scale_out"
		AnimationType.BOUNCE: return "bounce"
		AnimationType.PULSE: return "pulse"
		AnimationType.SHAKE: return "shake"
		AnimationType.ROTATE: return "rotate"
		_: return "unknown"

func _cleanup_tween(animation_id: String) -> void:
	"""Clean up finished tween"""
	active_tweens.erase(animation_id)

func stop_all_animations() -> void:
	"""Stop all active animations"""
	for tween in active_tweens.values():
		if tween and is_instance_valid(tween):
			tween.kill()
	active_tweens.clear()

func is_animating(control: Control) -> bool:
	"""Check if a control is currently animating"""
	var instance_id = str(control.get_instance_id())
	for animation_id in active_tweens.keys():
		if animation_id.begins_with(instance_id):
			return true
	return false
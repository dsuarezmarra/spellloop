class_name WarningIndicator
extends Node2D

# Visual feedback for AOE attacks (Red Circle + Scaling Fill)
# Drawn via code for performance and perfect radius matching.

var radius: float = 100.0
var duration: float = 1.0
var warning_color: Color = Color(1.0, 0.2, 0.2, 0.4)
var auto_cleanup: bool = true  # Auto-destroy when duration ends
var _current_time: float = 0.0

func setup(r: float, d: float, c: Color = Color(1.0, 0.2, 0.2, 0.4)) -> void:
	radius = r
	duration = d
	warning_color = c
	queue_redraw()

func _ready() -> void:
	# Ensure z-index is below enemies/player but above ground
	z_index = -1 

func _process(delta: float) -> void:
	_current_time += delta
	if _current_time >= duration:
		if auto_cleanup:
			queue_free()  # FIX: Auto-cleanup to prevent orphans
			return
		# If not auto-cleanup, stay full until removed by caller
		_current_time = duration
	
	queue_redraw()

func _draw() -> void:
	if duration <= 0: return
	
	var progress = clampf(_current_time / duration, 0.0, 1.0)
	
	# 1. Outer Border (Pulsing)
	var pulse = 0.8 + 0.2 * sin(_current_time * 15.0)
	var border_color = warning_color
	border_color.a = 0.8 * pulse
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, border_color, 2.0)
	
	# 2. Expanding Fill (Inner)
	# Fills from center to radius over duration
	var fill_color = warning_color
	fill_color.a = 0.3 * progress
	var fill_radius = radius * progress
	draw_circle(Vector2.ZERO, fill_radius, fill_color)
	
	# 3. Static faint background
	var bg_color = warning_color
	bg_color.a = 0.1
	draw_circle(Vector2.ZERO, radius, bg_color)

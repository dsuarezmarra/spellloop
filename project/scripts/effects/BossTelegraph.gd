extends Node2D

@export var radius: float = 96.0
@export var color: Color = Color(1, 0.2, 0.2, 0.7)
@export var duration: float = 1.2
@export var pulse_scale: float = 1.5

var _tween: Tween = null
var _scale: float = 1.0

func _ready() -> void:
	# Start a tween that scales up and fades out, then queue_free
	_scale = 1.0
	if not Engine.is_editor_hint():
		_tween = create_tween()
		_tween.tween_property(self, "_scale", pulse_scale, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self, "color:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		# Ensure the node is freed after duration
		_tween.tween_callback(Callable(self, "queue_free"))
		_tween.play()

func _draw() -> void:
	var r = radius * _scale
	# Base fill with current alpha
	draw_circle(Vector2.ZERO, r, Color(color.r, color.g, color.b, color.a))
	# Outline
	draw_arc(Vector2.ZERO, r * 0.95, 0.0, PI * 2.0, 64, Color(color.r, color.g, color.b, color.a * 0.9), 4)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW:
		# nothing special, _draw handles
		pass


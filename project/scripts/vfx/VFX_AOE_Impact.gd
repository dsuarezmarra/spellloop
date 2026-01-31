class_name VFX_AOE_Impact
extends Node2D

func _ready() -> void:
	# Start a simple animation via code or just auto-free
	# Ideally we'd play a particle system or tween a sprite.
	# For simplicity/performance: Draw a flash and fade out.
	var tween = create_tween()
	scale = Vector2.ZERO
	tween.tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func _draw() -> void:
	# Simple white flash ring
	draw_circle(Vector2.ZERO, 1.0, Color(1, 1, 1, 0.5)) # Radius will be scaled by node scale
	draw_arc(Vector2.ZERO, 1.0, 0, TAU, 16, Color.WHITE, 0.1)

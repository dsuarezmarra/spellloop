extends CharacterBody2D
class_name MockPlayer

# Signals expected by some managers
signal health_changed(current, max)
signal level_changed(new_level)

var global_position_mock = Vector2.ZERO

func _ready():
	add_to_group("player")

func play_cast_animation():
	pass

class_name VFX_AOE_Impact
extends Node2D

func _ready() -> void:
	# Use new Spritesheet asset
	var sprite = Sprite2D.new()
	var tex = load("res://assets/vfx/explosion_magic_sheet.png")
	if tex:
		sprite.texture = tex
		sprite.hframes = 8
		sprite.z_index = 10 # Place above most things
		# Center sprite
		sprite.centered = true
		
		add_child(sprite)
		
		# Animate frames
		var tween = create_tween()
		tween.tween_property(sprite, "frame", 7, 0.4).from(0)
		tween.tween_callback(queue_free)
	else:
		# Fallback if texture missing
		queue_free()

func _draw() -> void:
	pass

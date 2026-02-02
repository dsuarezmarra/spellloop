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

	# 3. Static faint background (REMOVED - Sprite handles this)
	queue_redraw()

func _ready() -> void:
	z_index = -1
	_setup_visuals()

var _rune_sprite: Sprite2D
var _fill_sprite: Sprite2D

func _setup_visuals() -> void:
	# Create Main Rune Sprite (Border/Static)
	_rune_sprite = Sprite2D.new()
	_rune_sprite.texture = load("res://assets/vfx/circle_warning_rune.png")
	add_child(_rune_sprite)
	
	# Create Fill Sprite (duplicate for expanding effect)
	_fill_sprite = Sprite2D.new()
	_fill_sprite.texture = _rune_sprite.texture
	_fill_sprite.modulate = warning_color
	_fill_sprite.modulate.a = 0.5
	_fill_sprite.scale = Vector2.ZERO # Start empty
	add_child(_fill_sprite)
	
	# Adjust scale of main rune to match desired radius
	if _rune_sprite.texture:
		var tex_size = _rune_sprite.texture.get_size()
		# Radius is half-width. Tex size is full width.
		var desired_scale = (radius * 2.0) / tex_size.x
		_rune_sprite.scale = Vector2(desired_scale, desired_scale)
		
		# Set base color
		_rune_sprite.modulate = warning_color

func _process(delta: float) -> void:
	_current_time += delta
	if _current_time >= duration:
		if auto_cleanup:
			queue_free()
			return
		_current_time = duration
	
	var progress = clampf(_current_time / duration, 0.0, 1.0)
	
	# Animate Pulse on Border
	var pulse = 0.8 + 0.2 * sin(_current_time * 15.0)
	if _rune_sprite:
		_rune_sprite.modulate.a = warning_color.a * pulse
		
	# Animate Fill Expansion (Scale 0 -> Target Scale)
	if _fill_sprite and _rune_sprite:
		_fill_sprite.scale = _rune_sprite.scale * progress

# Removed _draw() completely as we rely on sprites now.
func _draw() -> void:
	pass

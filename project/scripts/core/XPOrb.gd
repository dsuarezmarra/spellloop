extends Area2D
class_name XPOrbEffect

signal orb_collected(orb: Node, exp_value: int)

@export var exp_value: int = 1
@export var speed: float = 0.0
var player_ref: Node = null

func initialize(pos: Vector2, _exp: int, player):
	global_position = pos
	exp_value = _exp
	player_ref = player
	set_process(true)

func move_towards_player(player_position: Vector2, _speed: float, delta: float):
	var dir = (player_position - global_position)
	if dir.length() == 0:
		return
	dir = dir.normalized()
	global_position += dir * speed * delta

func _process(delta):
	if player_ref:
		var dist = global_position.distance_to(player_ref.global_position)
		if dist < player_ref.pickup_radius * player_ref.magnet:
			# Magnet: orb acelera hacia el player
			var dir = (player_ref.global_position - global_position).normalized()
			global_position += dir * lerp(80.0, 320.0, clamp(1.0 - dist / 300.0, 0.0, 1.0)) * delta

func _on_body_entered(body):
	if body == player_ref:
		# Emitir orb junto al valor para que los managers lo procesen
		emit_signal("orb_collected", self, exp_value)
		queue_free()

func _ready():
	if has_signal("body_entered"):
		connect("body_entered", Callable(self, "_on_body_entered"))


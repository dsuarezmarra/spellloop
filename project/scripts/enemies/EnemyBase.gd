extends CharacterBody2D
class_name EnemyBase

signal enemy_died(enemy_node, enemy_type_id, exp_value)

var enemy_id: String = "generic"
var max_hp: int = 10
var hp: int = 10
var speed: float = 60.0
var damage: int = 5
var exp_value: int = 1
var player_ref: Node = null

func initialize(data: Dictionary, player):
	enemy_id = data.get("id", enemy_id)
	max_hp = int(data.get("health", max_hp))
	hp = max_hp
	speed = float(data.get("speed", speed))
	damage = int(data.get("damage", damage))
	exp_value = int(data.get("exp_value", exp_value))
	player_ref = player
	# Capas/máscaras: layer=2 (Enemy), mask=3 (PlayerProjectiles) y 1 (Player)
	set_collision_layer_value(2, true)
	set_collision_mask_value(3, true)
	set_collision_mask_value(1, true)

func _physics_process(delta: float) -> void:
	if not player_ref:
		return
	# Seek + leve separación
	var dir = (player_ref.global_position - global_position)
	# Separación de otros enemigos
	var separation = Vector2.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other != self and other is CharacterBody2D:
			var dist = global_position.distance_to(other.global_position)
			if dist < 32 and dist > 0:
				separation -= (other.global_position - global_position).normalized() * (32 - dist) * 0.05
	var move_vec = dir.normalized() * speed + separation
	if move_vec.length() > 1:
		move_vec = move_vec.normalized() * speed
		translate(move_vec * delta)

func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		die()

func die() -> void:
	emit_signal("enemy_died", self, enemy_id, exp_value)
	queue_free()

func get_info() -> Dictionary:
	return {"id": enemy_id, "hp": hp, "max_hp": max_hp}

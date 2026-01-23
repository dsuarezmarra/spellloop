class_name EnemyAbility_Teleport
extends EnemyAbility

@export var teleport_range: float = 200.0

func execute(attacker: Node2D, target: Node2D, context: Dictionary = {}) -> bool:
	if not is_instance_valid(attacker):
		return false
		
	var final_range = context.get("modifiers", {}).get("teleport_range", teleport_range)
	
	# Teleport aleatorio o lejos del player?
	# "Teleporter" archetype suele huir o flanquear.
	# Hacemos blink aleatorio cercano
	
	var angle = randf() * TAU
	var dist = randf_range(100.0, final_range)
	var offset = Vector2(cos(angle), sin(angle)) * dist
	var target_pos = attacker.global_position + offset
	
	# Visual pre-teleport?
	# Aquí solo movemos.
	attacker.global_position = target_pos
	
	return true

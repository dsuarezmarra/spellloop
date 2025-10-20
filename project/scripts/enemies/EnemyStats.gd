extends Resource
class_name EnemyStats

@export var id: String = ""
@export var tier: int = 1
@export var max_hp: int = 10
@export var speed: float = 60.0
@export var xp_value: int = 1
@export var sprite_path: String = ""

func to_dict() -> Dictionary:
	return {
		"id": id,
		"tier": tier,
		"health": max_hp,
		"speed": speed,
		"exp_value": xp_value,
		"sprite": sprite_path
	}


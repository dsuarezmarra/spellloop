class_name EnemyAbility_Summon
extends EnemyAbility

@export var summon_count: int = 3
@export var summon_radius: float = 60.0
@export var minion_id: String = "tier_1_esqueleto_aprendiz"

func execute(attacker: Node2D, target: Node2D, context: Dictionary = {}) -> bool:
	if not is_instance_valid(attacker):
		return false
		
	var final_count = context.get("modifiers", {}).get("summon_count", summon_count)
	var final_id = context.get("modifiers", {}).get("summon_minion_id", minion_id)
	
	# Buscar EnemyManager (generalmente en Core o Game)
	var tree = attacker.get_tree()
	var enemy_manager = tree.get_first_node_in_group("enemy_manager")
	
	if not enemy_manager:
		return false
		
	# Spawnear minions en círculo
	for i in range(final_count):
		var angle = (TAU / final_count) * i
		var offset = Vector2(cos(angle), sin(angle)) * summon_radius
		var pos = attacker.global_position + offset
		
		# Llamar a spawn_enemy (asumido que existe en EnemyManager)
		if enemy_manager.has_method("spawn_enemy"):
			enemy_manager.spawn_enemy(final_id, pos)
			
	return true

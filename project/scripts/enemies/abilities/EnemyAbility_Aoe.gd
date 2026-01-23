class_name EnemyAbility_Aoe
extends EnemyAbility

@export var radius: float = 100.0
@export var damage: int = 15
@export var damage_mult: float = 1.0
@export var element_type: String = "physical"
@export var visual_color: Color = Color.RED

# Signal (if needed for parent system)
# signal area_attack(center, radius, damage, element)

func execute(attacker: Node2D, target: Node2D, context: Dictionary = {}) -> bool:
	if not is_instance_valid(attacker):
		return false
	
	# Usar radius del contexto si existe (modifiers)
	var final_radius = context.get("modifiers", {}).get("aoe_radius", radius)
	var final_damage = int(context.get("damage", damage) * context.get("modifiers", {}).get("aoe_damage_mult", damage_mult))
	
	# Detectar objetivos en rango
	# Nota: Esto es simplificado. En un sistema real usaríamos Area2D + query.
	# Asumimos que "target" es el player. Si hay minions del player, deberíamos buscar en grupo "player_allies".
	
	if is_instance_valid(target):
		var dist = attacker.global_position.distance_to(target.global_position)
		if dist <= final_radius:
			if target.has_method("take_damage"):
				target.take_damage(final_damage, element_type, attacker)
				
	# Feedback Visual
	_spawn_visual(attacker.global_position, final_radius)
	return true

func _spawn_visual(pos: Vector2, r: float) -> void:
	# En un sistema completo, instanciaríamos una escena de explosión.
	# Como fallback, usamos FloatingText o similar si existe, o confiamos en que el EnemyAttackSystem dibuje algo.
	# EnemyAttackSystem.gd tiene lógica "_spawn_elite_slam_visual" que podríamos refactorizar aquí.
	pass

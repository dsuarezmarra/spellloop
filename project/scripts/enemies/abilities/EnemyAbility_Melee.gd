class_name EnemyAbility_Melee
extends EnemyAbility

@export var damage: int = 10
@export var knockback_force: float = 0.0

signal attacked_player(damage: int, is_melee: bool)

func execute(attacker: Node2D, target: Node2D, context: Dictionary = {}) -> bool:
	if not is_instance_valid(target):
		return false
	
	var final_damage = context.get("damage", damage)
	
	if target.has_method("take_damage"):
		# Determinar elemento (fallback a physical)
		var elem = context.get("element_type", "physical")
		
		# Aplicar daño
		target.call("take_damage", final_damage, elem, attacker)
		
		# Señal manual (si estamos conectados al sistema padre)
		# En la versión final, esto debería ser un evento, pero por ahora simulamos
		return true
		
	return false

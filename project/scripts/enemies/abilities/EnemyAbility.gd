class_name EnemyAbility
extends Resource

## Clase base para todas las habilidades enemigas
## Define comportamiento, cooldowns y parámetros visuales

@export_group("Configuration")
@export var id: String = "base_ability"
@export var cooldown: float = 2.0
@export var range_min: float = 0.0
@export var range_max: float = 100.0
@export var ability_name: String = "Base Ability"

@export_group("Visuals")
@export var telegraph_time: float = 0.5 # Tiempo de advertencia antes de ejecutar

## Ejecutar la habilidad
## Retorna true si se ejecutó con éxito
func execute(attacker: Node2D, target: Node2D, context: Dictionary = {}) -> bool:
	push_warning("Only base execute called for %s" % id)
	return false

## Verificar si puede ejecutarse (además del cooldown)
func can_execute(attacker: Node2D, target: Node2D) -> bool:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return false
	
	var dist = attacker.global_position.distance_to(target.global_position)
	if dist < range_min or dist > range_max:
		return false
		
	return true

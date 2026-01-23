class_name EnemyAbility_Dash
extends EnemyAbility

@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.5
@export var damage: int = 15
@export var damage_mult: float = 1.0

# Estado interno (necesita ser reseteado o usar nueva instancia)
var _is_dashing: bool = false
var _dash_timer: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO

## Nota: Las habilidades de movimiento como Dash son complejas de abstraer 
## porque requieren actualizar la física del enemigo frame a frame.
## En esta Fase 1, este script actúa más como configurador/iniciador.

func execute(attacker: Node2D, target: Node2D, context: Dictionary = {}) -> bool:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return false
	
	# La lógica de movimiento frame-a-frame suele manejarse en el script del enemigo (physics_process)
	# O usamos un Tween aquí para "simular" el dash sin física compleja.
	# Por simplicidad y robustez, usaremos Tween.
	
	var final_speed = context.get("dash_speed", dash_speed)
	var dir = (target.global_position - attacker.global_position).normalized()
	var dist = final_speed * dash_duration
	var target_pos = attacker.global_position + dir * dist
	
	# Usar Tween para mover
	var tween = attacker.create_tween()
	tween.tween_property(attacker, "global_position", target_pos, dash_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Activar hitbox de daño durante el dash (simplificado)
	# En una implementación ideal, usaríamos un Area2D hijo que se activa.
	# Aquí hacemos un check simple al final o durante.
	
	tween.finished.connect(func():
		_check_collision(attacker, target, context)
	)
	
	return true

func _check_collision(attacker: Node2D, target: Node2D, context: Dictionary):
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return
		
	var dist = attacker.global_position.distance_to(target.global_position)
	if dist < 60.0: # Hitbox generosa de dash
		var dmg = int(context.get("damage", damage) * context.get("damage_mult", damage_mult))
		if target.has_method("take_damage"):
			target.take_damage(dmg, "physical", attacker)

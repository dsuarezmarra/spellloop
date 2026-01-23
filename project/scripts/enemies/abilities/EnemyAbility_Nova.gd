class_name EnemyAbility_Nova
extends EnemyAbility

@export var projectile_count: int = 12
@export var damage_mult: float = 0.8
@export var projectile_speed: float = 250.0
@export var element_type: String = "physical"
@export var projectile_scene: PackedScene

const EnemyProjectileScript = preload("res://scripts/enemies/EnemyProjectile.gd")

func execute(attacker: Node2D, target: Node2D, context: Dictionary = {}) -> bool:
	if not is_instance_valid(attacker):
		return false
		
	var final_count = context.get("modifiers", {}).get("nova_projectile_count", projectile_count)
	var final_damage = int(context.get("damage", 10) * context.get("modifiers", {}).get("nova_damage_mult", damage_mult))
	var elem = context.get("element_type", element_type)
	
	var center = attacker.global_position
	
	for i in range(final_count):
		var angle = (TAU / final_count) * i
		var dir = Vector2(cos(angle), sin(angle))
		
		# Crear proyectil
		var proj = null
		if projectile_scene:
			proj = projectile_scene.instantiate()
		else:
			proj = Area2D.new()
			proj.set_script(EnemyProjectileScript)
			
		proj.global_position = center
		
		var parent = attacker.get_parent()
		if parent:
			parent.add_child(proj)
			if proj.has_method("initialize"):
				proj.initialize(dir, projectile_speed, final_damage, 3.0, elem)
				
	return true

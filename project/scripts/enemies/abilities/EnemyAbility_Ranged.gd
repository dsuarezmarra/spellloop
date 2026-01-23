class_name EnemyAbility_Ranged
extends EnemyAbility

@export var damage: int = 10
@export var projectile_speed: float = 300.0
@export var projectile_count: int = 1
@export var spread_angle: float = 15.0 # Grados
@export var element_type: String = "physical"
@export var projectile_scene: PackedScene

# Dependencia: Script de proyectil enemigo
const EnemyProjectileScript = preload("res://scripts/enemies/EnemyProjectile.gd")

func execute(attacker: Node2D, target: Node2D, context: Dictionary = {}) -> bool:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return false
		
	# Calcular dirección al objetivo
	var dir = (target.global_position - attacker.global_position).normalized()
	
	# Ajustar origen (centro del atacante)
	var spawn_pos = attacker.global_position
	
	# Usar overrides de contexto si existen (ej: Boss overrides)
	var final_damage = context.get("damage", damage)
	var final_count = context.get("projectile_count", projectile_count)
	var final_element = context.get("element_type", element_type)
	
	# Disparar proyectiles
	if final_count == 1:
		_spawn_projectile(attacker, spawn_pos, dir, final_damage, final_element)
	else:
		var start_angle = -deg_to_rad(spread_angle) * (final_count - 1) / 2.0
		var base_angle = dir.angle()
		
		for i in range(final_count):
			var angle_offset = start_angle + i * deg_to_rad(spread_angle)
			var final_dir = Vector2(cos(base_angle + angle_offset), sin(base_angle + angle_offset))
			_spawn_projectile(attacker, spawn_pos, final_dir, final_damage, final_element)
			
	return true

func _spawn_projectile(attacker: Node2D, pos: Vector2, dir: Vector2, dmg: int, elem: String) -> void:
	var projectile = null
	
	# Usar escena custom o fallback manual
	if projectile_scene:
		projectile = projectile_scene.instantiate()
	else:
		projectile = Area2D.new()
		projectile.set_script(EnemyProjectileScript)
	
	projectile.global_position = pos
	
	# Añadir al árbol (usar padre del atacante para no moverse con él)
	var parent = attacker.get_parent()
	if parent:
		parent.add_child(projectile)
		
		if projectile.has_method("initialize"):
			projectile.initialize(dir, projectile_speed, dmg, 3.0, elem)
		
		# Ajustar visual si es necesario
		var sprite = projectile.get_node_or_null("Sprite2D")
		if sprite:
			# Aquí podríamos tintar según elemento
			pass

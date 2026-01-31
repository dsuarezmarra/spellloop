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
	
	# === 1. TELEGRAPH PHASE ===
	if telegraph_time > 0.0:
		var warning = _spawn_warning(attacker.global_position, final_radius, telegraph_time)
		if warning:
			# Esperar wind-up
			await attacker.get_tree().create_timer(telegraph_time).timeout
			
			# Verificar si el ataque fue cancelado (attacker murió o warning borrado)
			if not is_instance_valid(attacker) or not is_instance_valid(warning):
				if is_instance_valid(warning): warning.queue_free()
				return false
				
			warning.queue_free()
	
	# === 2. DAMAGE PHASE ===
	# Re-validar posición y existencia (el target pudo moverse, pero AOE es en posición del attacker o target?)
	# Lógica actual: AOE centrado en Attacker.
	if not is_instance_valid(attacker): return false
	
	# Detectar objetivos en rango
	if is_instance_valid(target):
		var dist = attacker.global_position.distance_to(target.global_position)
		if dist <= final_radius:
			if target.has_method("take_damage"):
				target.take_damage(final_damage, element_type, attacker)
				
	# === 3. VISUAL IMPACT ===
	_spawn_visual(attacker.global_position, final_radius)
	return true

func _spawn_warning(pos: Vector2, r: float, duration: float) -> Node2D:
	var scene = load("res://scenes/vfx/warning_indicator.tscn")
	if scene:
		var instance = scene.instantiate()
		instance.global_position = pos
		instance.setup(r, duration)
		# Añadir al árbol (en el mismo contenedor que projectiles o root)
		var root = Engine.get_main_loop().root
		root.add_child(instance)
		return instance
	return null

func _spawn_visual(pos: Vector2, r: float) -> void:
	var scene = load("res://scenes/vfx/vfx_aoe_impact.tscn")
	if scene:
		var instance = scene.instantiate()
		instance.global_position = pos
		instance.scale = Vector2(r, r) # Escalar el efecto al radio
		var root = Engine.get_main_loop().root
		root.add_child(instance)

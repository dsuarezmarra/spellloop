# BasicSlime.gd
# Simple aggressive enemy that chases and performs melee attacks
# Good for testing basic AI and combat mechanics

extends Enemy
class_name BasicSlime

func _ready() -> void:
	super._ready()
	
	# Configure basic slime stats
	ai_behavior = AIBehavior.AGGRESSIVE
	max_health = 30
	current_health = max_health
	base_speed = 80.0
	
	# AI parameters
	detection_range = 120.0
	attack_range = 40.0
	attack_damage = 10
	attack_cooldown = 1.2
	chase_speed = 100.0
	patrol_speed = 40.0
	
	# Apply slime sprite
	_setup_slime_appearance()
	
	print("[BasicSlime] Basic Slime initialized")

func _setup_slime_appearance() -> void:
	"""Setup slime visual appearance"""
	if sprite:
		# Apply procedural slime sprite
		SpriteGenerator.apply_sprite_to_node(self, "enemy")
		sprite.modulate = Color.GREEN
	
	# Adjust collision shape for slime
	if entity_collision_shape and entity_collision_shape.shape is CircleShape2D:
		entity_collision_shape.shape.radius = 12.0

func _perform_melee_attack() -> void:
	"""Override melee attack for slime-specific behavior"""
	super._perform_melee_attack()
	
	# Slime bounces back after attack
	if target:
		var bounce_direction = (global_position - target.global_position).normalized()
		velocity += bounce_direction * 150
	
	print("[BasicSlime] Slime bounce attack!")

func _on_death() -> void:
	"""Override death for slime-specific effects"""
	# Slime split effect (for future implementation)
	print("[BasicSlime] Slime dissolved!")
	
	super._on_death()
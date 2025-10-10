# SentinelOrb.gd
# Defensive ranged enemy that maintains distance and shoots projectiles
# Good for testing ranged AI and spell counter-play

extends Enemy
class_name SentinelOrb

# Ranged behavior parameters
var maintain_distance: float = 120.0
var spell_system  # Reference to spell system

func _ready() -> void:
	super._ready()
	
	# Configure sentinel stats
	ai_behavior = AIBehavior.RANGED
	max_health = 20
	current_health = max_health
	base_speed = 60.0
	
	# AI parameters - longer range, stays back
	detection_range = 180.0
	attack_range = 150.0
	attack_damage = 8
	attack_cooldown = 2.0
	chase_speed = 70.0
	patrol_speed = 30.0
	
	# Ranged specific parameters
	maintain_distance = 120.0  # Keep this distance from player
	
	# Apply orb appearance
	_setup_orb_appearance()
	
	print("[SentinelOrb] Sentinel Orb initialized")

func _setup_orb_appearance() -> void:
	"""Setup orb visual appearance"""
	if sprite:
		# Apply procedural orb sprite
		SpriteGeneratorUtils.apply_sprite_to_node(self, "enemy")
		sprite.modulate = Color.CYAN
		# Orbs are slightly smaller
		sprite.scale = Vector2(0.8, 0.8)
	
	# Adjust collision for floating orb
	if entity_collision_shape and entity_collision_shape.shape is CircleShape2D:
		entity_collision_shape.shape.radius = 8.0
	
	# Initialize spell system reference
	spell_system = SpellSystem

func _perform_ranged_attack() -> void:
	"""Override ranged attack for orb-specific projectiles"""
	if not target or not spell_system:
		return
	
	var direction = (target.global_position - global_position).normalized()
	
	# Create energy bolt projectile
	var projectile_data = {
		"name": "Energy Bolt",
		"damage": attack_damage,
		"speed": 200,
		"range": 300,
		"size": 0.6,
		"color": Color.CYAN,
		"piercing": false
	}
	
	spell_system.create_projectile(
		global_position,
		direction,
		projectile_data,
		false  # enemy projectile
	)
	
	print("[SentinelOrb] Energy bolt fired!")

func _physics_process(delta: float) -> void:
	"""Override physics to add floating behavior"""
	super._physics_process(delta)
	
	# Add floating oscillation
	var float_offset = sin(Time.get_unix_time_from_system() * 2.0) * 5.0
	position.y += float_offset * delta

func _on_death() -> void:
	"""Override death for orb-specific effects"""
	print("[SentinelOrb] Orb energy dissipated!")
	
	# Add energy explosion effect (visual only for now)
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(2.0, 2.0), 0.3)
		tween.parallel().tween_property(sprite, "modulate", Color.TRANSPARENT, 0.3)
	
	super._on_death()
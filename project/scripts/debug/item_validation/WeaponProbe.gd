extends Node
class_name WeaponProbe

# Metrics
var shots_fired = 0
var hits_registered = 0
var damage_dealt = 0.0
var status_effects_applied = {}

func attach(weapon_node: Node):
	# Connect to weapon signals if they exist
	if weapon_node.has_signal("projectile_fired"):
		weapon_node.projectile_fired.connect(_on_projectile_fired)
	
	# We might need to inject ourselves into the weapon logic or listen to global events
	# For now, we assume direct signal connection capability or polling
	pass

func log_hit(damage: float, is_crit: bool, enemy_id: int):
	hits_registered += 1
	damage_dealt += damage

func log_effect(effect_name: String):
	if not status_effects_applied.has(effect_name):
		status_effects_applied[effect_name] = 0
	status_effects_applied[effect_name] += 1
	
func _on_projectile_fired(_projectile):
	shots_fired += 1

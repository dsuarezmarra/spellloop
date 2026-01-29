extends CharacterBody2D
class_name DummyEnemy

signal damage_taken(amount, is_crit)

@onready var health_component = $HealthComponent

func _ready():
	add_to_group("enemies")
	add_to_group("test_dummy")

func take_damage(amount: float, _knockback_force: Vector2 = Vector2.ZERO, source = null):
	# Forward to health component
	# Determine critical logic (mock or rely on source)
	var is_crit = false 
	if source and source.has("crit_chance"):
		# Mock logic, usually handled by AttackManager/Projectile before calling take_damage
		pass
		
	# In real game, AttackManager calculates damage and calls take_damage on HealthComponent
	# Or Projectile calls it.
	if health_component:
		health_component.take_damage(int(amount))
		damage_taken.emit(amount, is_crit)
		
	# Show Floating Text removed to avoid UI dependency crashes

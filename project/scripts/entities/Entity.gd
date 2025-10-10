extends CharacterBody2D

# Entity.gd - Base class for all game entities
class_name Entity

# Health system
@export var max_health: int = 100
var current_health: int

# Movement
@export var base_speed: float = 200.0

# Status
var is_alive: bool = true
var entity_type: String = "base"

# Signals
signal health_changed(old_health: int, new_health: int)
signal died(entity: Entity)

func _ready():
	current_health = max_health

func take_damage(amount: int):
	if not is_alive:
		return
		
	var old_health = current_health
	current_health -= amount
	current_health = max(0, current_health)
	
	health_changed.emit(old_health, current_health)
	
	if current_health <= 0:
		die()

func die():
	is_alive = false
	died.emit(self)

func get_health_percentage() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)

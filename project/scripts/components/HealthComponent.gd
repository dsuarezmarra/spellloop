# HealthComponent.gd
# Sistema genérico de salud para jugador, enemigos y entidades
# Proporciona un componente reutilizable de HP con señales

extends Node
class_name HealthComponent

signal health_changed(new_health: int, max_health: int)
signal damaged(amount: int, element_type: String)
signal died

var max_health: int = 100
var current_health: int = 100
var is_alive: bool = true

# Referencia al nodo propietario (para debugging)
var owner_node: Node = null

func _ready() -> void:
	owner_node = get_parent()
	current_health = max_health
	# print("[HealthComponent] Inicializado para %s: HP %d/%d" % [owner_node.name, current_health, max_health])

func initialize(max_hp: int) -> void:
	"""Inicializar el componente con HP máximo"""
	max_health = max_hp
	current_health = max_hp
	is_alive = true
	# print("[HealthComponent] Inicializado: %s HP" % max_health)

func take_damage(amount: int, element_type: String = "physical") -> void:
	"""Recibir daño y emitir señales"""
	if not is_alive:
		return
	
	current_health -= amount
	current_health = max(current_health, 0)
	
	damaged.emit(amount, element_type)
	health_changed.emit(current_health, max_health)
	
	# Debug (comentado para producción)
	# if current_health > 0:
	#	print("[HealthComponent] %s recibió %d de daño (%s). HP: %d/%d" % [owner_node.name, amount, element_type, current_health, max_health])
	
	# Comprobar si murió
	if current_health <= 0:
		die()

func heal(amount: int) -> void:
	"""Sanar el componente"""
	if not is_alive:
		return
	
	current_health = min(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)
	# print("[HealthComponent] %s sanado %d HP. HP: %d/%d" % [owner_node.name, amount, current_health, max_health])

func die() -> void:
	"""Procesar la muerte"""
	is_alive = false
	# print("[HealthComponent] %s ha muerto" % owner_node.name)
	died.emit()
	# No eliminar el nodo automáticamente; dejar que el propietario lo maneje

func get_health_percent() -> float:
	"""Obtener porcentaje de salud (0.0 a 1.0)"""
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)

func set_max_health(new_max: int) -> void:
	"""Ajustar HP máximo y actual"""
	max_health = new_max
	current_health = min(current_health, max_health)
	health_changed.emit(current_health, max_health)

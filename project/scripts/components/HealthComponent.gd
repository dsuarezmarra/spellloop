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

func take_damage(amount: int, element_type: String = "physical", is_pre_mitigated: bool = false) -> void:
	"""Recibir daño y emitir señales"""
	if not is_alive:
		return
	
	# P0.2: Check invulnerability
	if is_invulnerable():
		return
	
	# FIX-SHIELD: Check for PlayerStats shield/mitigation
	var final_damage = amount
	if not is_pre_mitigated and owner_node.is_in_group("player"):
		var player_stats = get_tree().get_first_node_in_group("player_stats")
		if player_stats and player_stats.has_method("take_damage"):
			# PlayerStats handles Dodge, Armor, Shield reduction internally.
			# It returns the damage that remains to be taken by HP.
			final_damage = int(player_stats.take_damage(float(amount)))

	current_health -= final_damage
	current_health = max(current_health, 0)
	
	
	damaged.emit(amount, element_type)
	health_changed.emit(current_health, max_health)
	
	# AUDIT HOOK
	if is_instance_valid(owner_node) and owner_node.has_meta("last_damage_event_id"):
		var logger = get_tree().root.get_node_or_null("DamageDeliveryLogger")
		if logger:
			var event_id = owner_node.get_meta("last_damage_event_id")
			logger.log_application(event_id, amount)
			owner_node.remove_meta("last_damage_event_id") # Clean up
	
	# Visualizar daño - FloatingText handles headless/diagnostics logic
	if owner_node is Node2D:
		FloatingText.spawn_damage(owner_node.global_position, amount)
	
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

# ═══════════════════════════════════════════════════════════════════════════════
# P0.2: INVULNERABILITY SYSTEM (for I-Frame Visual Feedback)
# ═══════════════════════════════════════════════════════════════════════════════
var _invulnerability_timer: float = 0.0

func _process(delta: float) -> void:
	if _invulnerability_timer > 0.0:
		_invulnerability_timer -= delta

func set_invulnerable(duration: float) -> void:
	"""Set invulnerability for specified duration"""
	_invulnerability_timer = duration

func is_invulnerable() -> bool:
	"""Check if currently invulnerable"""
	return _invulnerability_timer > 0.0

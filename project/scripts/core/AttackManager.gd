# AttackManager.gd
# Sistema central de auto-ataque para el jugador
# Mantiene lista de armas, gestiona cooldowns, dispara automáticamente

extends Node
class_name AttackManager

signal weapon_added(weapon)
signal weapon_removed(weapon)
signal weapon_fired(weapon, target_pos: Vector2)

# Referencias
var player: CharacterBody2D = null
var weapons: Array = []
var is_active: bool = true

func _ready() -> void:
	print("[AttackManager] Inicializado")

func initialize(player_ref: CharacterBody2D) -> void:
	"""Inicializar con referencia al jugador"""
	player = player_ref
	print("[AttackManager] Inicializado para player: %s" % player.name)
	
	# Iniciar actualización de cooldowns
	set_process(true)

func add_weapon(weapon) -> void:
	"""Añadir arma a la lista de ataque"""
	if not weapon:
		print("[AttackManager] Error: Intento de añadir arma nula")
		return
	
	# Evitar duplicados
	if weapon in weapons:
		print("[AttackManager] Warning: Arma ya está equipada: %s" % weapon.id)
		return
	
	weapons.append(weapon)
	weapon.reset_cooldown()
	
	print("[AttackManager] ⚔️ Arma equipada: %s (total: %d)" % [weapon.name, weapons.size()])
	weapon_added.emit(weapon)

func remove_weapon(weapon) -> void:
	"""Remover arma de la lista"""
	if weapon in weapons:
		weapons.erase(weapon)
		print("[AttackManager] ⚔️ Arma removida: %s (total: %d)" % [weapon.name, weapons.size()])
		weapon_removed.emit(weapon)

func replace_weapon(old_weapon, new_weapon) -> void:
	"""Reemplazar un arma con otra"""
	if old_weapon in weapons:
		var idx = weapons.find(old_weapon)
		weapons[idx] = new_weapon
		new_weapon.reset_cooldown()
		print("[AttackManager] ⚔️ Arma reemplazada: %s -> %s" % [old_weapon.name, new_weapon.name])

func get_weapon_count() -> int:
	"""Obtener número de armas activas"""
	return weapons.size()

func get_weapons() -> Array:
	"""Obtener lista de armas"""
	return weapons.duplicate()

func _process(delta: float) -> void:
	"""Actualizar cooldowns y disparar armas"""
	if not is_active or not player or not is_instance_valid(player):
		return
	
	# Iterar sobre todas las armas
	for weapon in weapons:
		if not weapon or not weapon.is_active:
			continue
		
		# Decrementar cooldown
		weapon.tick_cooldown(delta)
		
		# Comprobar si está lista para disparar
		if weapon.is_ready_to_fire():
			# Disparar
			weapon.perform_attack(player)
			weapon_fired.emit(weapon, player.global_position)
			
			# Resetear cooldown
			weapon.reset_cooldown()

func enable() -> void:
	"""Activar ataque automático"""
	is_active = true
	set_process(true)
	print("[AttackManager] Ataque activado")

func disable() -> void:
	"""Desactivar ataque automático"""
	is_active = false
	set_process(false)
	print("[AttackManager] Ataque desactivado")

func clear_weapons() -> void:
	"""Remover todas las armas"""
	weapons.clear()
	print("[AttackManager] Todas las armas removidas")

func upgrade_weapon(weapon_index: int, upgrade_type: String, amount: float = 1.0) -> bool:
	"""Mejorar un arma específica"""
	if weapon_index < 0 or weapon_index >= weapons.size():
		print("[AttackManager] Error: Índice de arma inválido: %d" % weapon_index)
		return false
	
	var weapon = weapons[weapon_index]
	weapon.apply_upgrade(upgrade_type, amount)
	print("[AttackManager] ⬆️ Mejora aplicada a %s: %s+%.1f" % [weapon.name, upgrade_type, amount])
	return true

func upgrade_all_weapons(upgrade_type: String, amount: float = 1.0) -> void:
	"""Mejorar todas las armas"""
	for weapon in weapons:
		weapon.apply_upgrade(upgrade_type, amount)
	print("[AttackManager] ⬆️ Mejora masiva: %s+%.1f a %d armas" % [upgrade_type, amount, weapons.size()])

func get_total_damage() -> int:
	"""Obtener daño total de todas las armas"""
	var total = 0
	for weapon in weapons:
		total += weapon.damage
	return total

func get_weapons_by_element(element: String) -> Array:
	"""Obtener armas de un elemento específico"""
	var result: Array = []
	for weapon in weapons:
		if weapon.element_type == element:
			result.append(weapon)
	return result

func get_info() -> Dictionary:
	"""Obtener información del atacante para UI"""
	var weapon_infos = []
	for weapon in weapons:
		weapon_infos.append(weapon.get_info())
	
	return {
		"total_weapons": weapons.size(),
		"total_damage": get_total_damage(),
		"weapons": weapon_infos
	}

func _notification(what: int) -> void:
	"""Limpiar al eliminar nodo"""
	if what == NOTIFICATION_PREDELETE:
		weapons.clear()

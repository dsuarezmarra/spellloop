# AttackManager.gd
# Sistema central de auto-ataque para el jugador
# Mantiene lista de armas, gestiona cooldowns, dispara automáticamente
#
# NUEVO SISTEMA DE STATS (v2.0):
# - GlobalWeaponStats: Mejoras que afectan a TODAS las armas
# - WeaponStats: Stats individuales por arma (para mejoras específicas)
# - Sistema de fusión con herencia de mejoras
#
# SLOTS DE ARMAS:
# - 6 slots máximos iniciales
# - Al fusionar armas, se pierde 1 slot permanentemente
# - Las armas fusionadas ocupan 1 solo slot

extends Node
class_name AttackManager

signal weapon_added(weapon, slot_index: int)
signal weapon_removed(weapon, slot_index: int)
signal weapon_fired(weapon, target_pos: Vector2)
signal weapon_leveled_up(weapon, new_level: int)
signal slots_updated(current: int, max_slots: int)
signal fusion_available(weapon_a, weapon_b, result: Dictionary)
signal global_stats_changed()  # Nueva señal para UI

# Referencias
var player: CharacterBody2D = null
var weapons: Array = []  # Acepta BaseWeapon y armas legacy (RefCounted)
var is_active: bool = true

# Sistema de fusión
var fusion_manager: WeaponFusionManager = null

# ═══════════════════════════════════════════════════════════════════════════════
# NUEVO SISTEMA DE STATS
# ═══════════════════════════════════════════════════════════════════════════════

# Stats GLOBALES de armas (afectan a todas las armas)
var global_weapon_stats: GlobalWeaponStats = null

# Stats INDIVIDUALES por arma (mejoras específicas)
# weapon_id -> WeaponStats
var weapon_stats_map: Dictionary = {}

# Compatibilidad: Diccionario legacy para código existente
# Este dict se sincroniza automáticamente con global_weapon_stats
var player_stats: Dictionary:
	get:
		if global_weapon_stats:
			return global_weapon_stats.get_all_stats()
		return _legacy_player_stats
	set(value):
		# Para compatibilidad con código que asigna al dict directamente
		_legacy_player_stats = value
		if global_weapon_stats:
			_sync_legacy_to_global(value)

var _legacy_player_stats: Dictionary = {
	"damage_mult": 1.0,
	"attack_speed_mult": 1.0,  # Renombrado de cooldown_mult
	"crit_chance": 0.0,
	"crit_damage": 2.0,
	"area_mult": 1.0,
	"projectile_speed_mult": 1.0,
	"duration_mult": 1.0,
	"extra_projectiles": 0,
	"knockback_mult": 1.0,
	"life_steal": 0.0
}

# ═══════════════════════════════════════════════════════════════════════════════
# PROPIEDADES
# ═══════════════════════════════════════════════════════════════════════════════

var max_weapon_slots: int:
	get:
		if fusion_manager:
			return fusion_manager.current_max_slots
		return WeaponFusionManager.STARTING_MAX_SLOTS

var current_weapon_count: int:
	get:
		return weapons.size()

var has_available_slot: bool:
	get:
		return current_weapon_count < max_weapon_slots

# ═══════════════════════════════════════════════════════════════════════════════
# FUNCIONES HELPER PARA COMPATIBILIDAD
# ═══════════════════════════════════════════════════════════════════════════════

func _sync_legacy_to_global(legacy: Dictionary) -> void:
	"""Sincronizar diccionario legacy con GlobalWeaponStats"""
	if not global_weapon_stats:
		return
	for key in legacy:
		if key in global_weapon_stats.stats:
			global_weapon_stats.stats[key] = legacy[key]

func _get_weapon_id(weapon) -> String:
	"""Obtener ID del arma de forma compatible con ambos sistemas"""
	if weapon == null:
		return ""
	if "id" in weapon:
		return weapon.id
	return ""

func _get_weapon_name(weapon) -> String:
	"""Obtener nombre del arma de forma compatible con ambos sistemas"""
	if weapon == null:
		return "Unknown"
	if weapon is BaseWeapon:
		return weapon.weapon_name
	if "name" in weapon:
		return weapon.name
	if "weapon_name" in weapon:
		return weapon.weapon_name
	return "Unknown"

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	# Crear el manager de fusiones
	fusion_manager = WeaponFusionManager.new()
	fusion_manager.fusion_completed.connect(_on_fusion_completed)
	fusion_manager.fusion_failed.connect(_on_fusion_failed)
	
	# Crear sistema de stats globales
	global_weapon_stats = GlobalWeaponStats.new()
	global_weapon_stats.stats_changed.connect(_on_global_stats_changed)

	print("[AttackManager] Inicializado con sistema de fusiones y GlobalWeaponStats")

func _on_global_stats_changed(stat_name: String) -> void:
	"""Callback cuando cambian los stats globales"""
	global_stats_changed.emit()

func initialize(player_ref: CharacterBody2D) -> void:
	"""Inicializar con referencia al jugador"""
	player = player_ref
	print("[AttackManager] Inicializado para player: %s" % player.name)
	print("[AttackManager] Slots disponibles: %d/%d" % [current_weapon_count, max_weapon_slots])

	# Iniciar actualización de cooldowns
	set_process(true)

# ═══════════════════════════════════════════════════════════════════════════════
# GESTIÓN DE ARMAS
# ═══════════════════════════════════════════════════════════════════════════════

func add_weapon(weapon) -> bool:
	"""
	Añadir arma a un slot disponible
	Acepta tanto BaseWeapon como armas legacy (RefCounted como IceWand)
	Retorna: true si se añadió exitosamente
	"""
	if weapon == null:
		push_error("[AttackManager] Error: Intento de añadir arma nula")
		return false

	# Verificar si hay slots disponibles
	if not has_available_slot:
		print("[AttackManager] ⚠️ No hay slots disponibles (%d/%d)" % [current_weapon_count, max_weapon_slots])
		return false

	# Obtener ID del arma (compatible con ambos sistemas)
	var weapon_id = _get_weapon_id(weapon)
	var weapon_display_name = _get_weapon_name(weapon)

	# Verificar si ya tenemos esta arma
	for existing in weapons:
		if _get_weapon_id(existing) == weapon_id:
			print("[AttackManager] ℹ️ Ya tienes %s, subiendo de nivel..." % weapon_display_name)
			return level_up_weapon_by_id(weapon_id)

	# Añadir a la lista
	weapons.append(weapon)
	var slot_index = weapons.size() - 1
	
	# Crear WeaponStats para esta arma (nuevo sistema)
	_create_weapon_stats_for(weapon)

	# Conectar señales del arma (solo si es BaseWeapon)
	if weapon is BaseWeapon and weapon.has_signal("weapon_leveled_up"):
		weapon.weapon_leveled_up.connect(_on_weapon_leveled_up)

	print("[AttackManager] ⚔️ Arma equipada: %s [Slot %d] (total: %d/%d)" % [
		weapon_display_name, slot_index, current_weapon_count, max_weapon_slots
	])

	weapon_added.emit(weapon, slot_index)
	slots_updated.emit(current_weapon_count, max_weapon_slots)

	# Verificar fusiones disponibles (solo para BaseWeapon)
	if weapon is BaseWeapon:
		_check_available_fusions()

	return true

func add_weapon_by_id(weapon_id: String) -> bool:
	"""Añadir arma por su ID"""
	var weapon = BaseWeapon.new(weapon_id)
	if weapon.id.is_empty():
		push_error("[AttackManager] No se pudo crear arma: %s" % weapon_id)
		return false
	return add_weapon(weapon)

func remove_weapon(weapon) -> bool:
	"""Remover arma de la lista"""
	if weapon not in weapons:
		return false

	var slot_index = weapons.find(weapon)
	weapons.erase(weapon)
	
	# Remover WeaponStats (nuevo sistema)
	_remove_weapon_stats_for(weapon)

	# Desconectar señales (solo si es BaseWeapon)
	if weapon is BaseWeapon and weapon.has_signal("weapon_leveled_up"):
		if weapon.weapon_leveled_up.is_connected(_on_weapon_leveled_up):
			weapon.weapon_leveled_up.disconnect(_on_weapon_leveled_up)

	print("[AttackManager] ⚔️ Arma removida: %s (total: %d/%d)" % [
		_get_weapon_name(weapon), current_weapon_count, max_weapon_slots
	])

	weapon_removed.emit(weapon, slot_index)
	slots_updated.emit(current_weapon_count, max_weapon_slots)

	return true

func remove_weapon_at_slot(slot_index: int) -> bool:
	"""Remover arma por índice de slot"""
	if slot_index < 0 or slot_index >= weapons.size():
		return false
	return remove_weapon(weapons[slot_index])

func replace_weapon(old_weapon, new_weapon) -> bool:
	"""Reemplazar un arma con otra"""
	if old_weapon not in weapons:
		return false

	var idx = weapons.find(old_weapon)

	# Desconectar señales del arma antigua
	if old_weapon is BaseWeapon and old_weapon.has_signal("weapon_leveled_up"):
		if old_weapon.weapon_leveled_up.is_connected(_on_weapon_leveled_up):
			old_weapon.weapon_leveled_up.disconnect(_on_weapon_leveled_up)

	# Reemplazar
	weapons[idx] = new_weapon

	# Conectar señales del arma nueva
	if new_weapon is BaseWeapon and new_weapon.has_signal("weapon_leveled_up"):
		new_weapon.weapon_leveled_up.connect(_on_weapon_leveled_up)

	print("[AttackManager] ⚔️ Arma reemplazada: %s -> %s" % [
		_get_weapon_name(old_weapon), _get_weapon_name(new_weapon)
	])
	return true

func get_weapon_count() -> int:
	"""Obtener número de armas activas"""
	return weapons.size()

func get_weapons() -> Array:
	"""Obtener lista de armas"""
	return weapons.duplicate()

func get_weapon_at_slot(slot_index: int):
	"""Obtener arma en un slot específico"""
	if slot_index < 0 or slot_index >= weapons.size():
		return null
	return weapons[slot_index]

func get_weapon_by_id(weapon_id: String):
	"""Obtener arma por ID"""
	for weapon in weapons:
		if _get_weapon_id(weapon) == weapon_id:
			return weapon
	return null

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE NIVELES
# ═══════════════════════════════════════════════════════════════════════════════

func level_up_weapon(weapon) -> bool:
	"""Subir de nivel un arma"""
	if weapon not in weapons:
		return false

	# Solo armas BaseWeapon soportan level_up
	if weapon is BaseWeapon:
		if not weapon.can_level_up():
			print("[AttackManager] %s ya está al nivel máximo" % _get_weapon_name(weapon))
			return false
		return weapon.level_up()

	# Armas legacy no tienen sistema de niveles
	print("[AttackManager] %s es un arma legacy sin sistema de niveles" % _get_weapon_name(weapon))
	return false

func level_up_weapon_by_id(weapon_id: String) -> bool:
	"""Subir de nivel un arma por ID"""
	var weapon = get_weapon_by_id(weapon_id)
	if weapon == null:
		return false
	return level_up_weapon(weapon)

func level_up_weapon_at_slot(slot_index: int) -> bool:
	"""Subir de nivel un arma por slot"""
	var weapon = get_weapon_at_slot(slot_index)
	if weapon == null:
		return false
	return level_up_weapon(weapon)

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE FUSIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func can_fuse(weapon_a: BaseWeapon, weapon_b: BaseWeapon) -> Dictionary:
	"""Verificar si dos armas pueden fusionarse"""
	return fusion_manager.can_fuse_weapons(weapon_a, weapon_b)

func fuse_weapons(weapon_a: BaseWeapon, weapon_b: BaseWeapon) -> BaseWeapon:
	"""
	Fusionar dos armas
	Retorna el arma fusionada si tiene éxito, null si falla
	"""
	# Verificar que ambas armas están equipadas
	if weapon_a not in weapons or weapon_b not in weapons:
		push_error("[AttackManager] Las armas a fusionar deben estar equipadas")
		return null

	# Ejecutar fusión
	var fused = fusion_manager.fuse_weapons(weapon_a, weapon_b)
	if fused == null:
		return null

	# Remover las armas originales
	remove_weapon(weapon_a)
	remove_weapon(weapon_b)

	# Añadir arma fusionada
	add_weapon(fused)

	# Actualizar slots (ya se redujo en el fusion_manager)
	slots_updated.emit(current_weapon_count, max_weapon_slots)

	return fused

func fuse_weapons_by_ids(weapon_id_a: String, weapon_id_b: String) -> BaseWeapon:
	"""Fusionar armas por sus IDs"""
	var weapon_a = get_weapon_by_id(weapon_id_a)
	var weapon_b = get_weapon_by_id(weapon_id_b)

	if weapon_a == null or weapon_b == null:
		push_error("[AttackManager] No se encontraron las armas para fusionar")
		return null

	return fuse_weapons(weapon_a, weapon_b)

func get_available_fusions() -> Array:
	"""Obtener todas las fusiones disponibles con las armas actuales"""
	return fusion_manager.get_available_fusions(weapons)

func get_fusion_preview(weapon_a: BaseWeapon, weapon_b: BaseWeapon) -> Dictionary:
	"""Obtener preview de una fusión para UI"""
	return fusion_manager.get_fusion_preview(weapon_a, weapon_b)

func _check_available_fusions() -> void:
	"""Verificar y emitir señales de fusiones disponibles"""
	var fusions = get_available_fusions()
	for fusion in fusions:
		fusion_available.emit(fusion.weapon_a, fusion.weapon_b, fusion.result)

# ═══════════════════════════════════════════════════════════════════════════════
# CALLBACKS
# ═══════════════════════════════════════════════════════════════════════════════

func _on_weapon_leveled_up(weapon_id: String, new_level: int) -> void:
	"""Callback cuando un arma sube de nivel"""
	var weapon = get_weapon_by_id(weapon_id)
	if weapon:
		weapon_leveled_up.emit(weapon, new_level)
		print("[AttackManager] ⬆️ %s subió a nivel %d" % [_get_weapon_name(weapon), new_level])

func _on_fusion_completed(fused_weapon, lost_slot: bool) -> void:
	"""Callback cuando se completa una fusión"""
	print("[AttackManager] 🔥 Fusión completada: %s" % _get_weapon_name(fused_weapon))
	if lost_slot:
		print("[AttackManager] ⚠️ Slots reducidos: %d/%d" % [current_weapon_count, max_weapon_slots])

func _on_fusion_failed(reason: String) -> void:
	"""Callback cuando falla una fusión"""
	print("[AttackManager] ❌ Fusión fallida: %s" % reason)

# ═══════════════════════════════════════════════════════════════════════════════
# PROCESAMIENTO
# ═══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	"""Actualizar cooldowns y disparar armas"""
	if not is_active or not player or not is_instance_valid(player):
		return

	# Verificar que el árbol de escena existe (evita error al cambiar de escena)
	if not player.get_tree():
		return

	# Iterar sobre todas las armas
	for weapon in weapons:
		if weapon == null:
			continue

		# Verificar si el arma tiene los métodos necesarios
		if not weapon.has_method("tick_cooldown") or not weapon.has_method("is_ready_to_fire"):
			# Arma legacy: manejar cooldown manualmente
			_process_legacy_weapon(weapon, delta)
			continue

		# Decrementar cooldown
		weapon.tick_cooldown(delta)

		# Comprobar si está lista para disparar
		if weapon.is_ready_to_fire():
			# Verificar que el árbol siga válido antes de disparar
			if not player.get_tree():
				return
			# Disparar con stats del jugador (solo BaseWeapon soporta esto)
			if weapon is BaseWeapon:
				weapon.perform_attack(player, player_stats)
			else:
				weapon.perform_attack(player)
				# Para armas NO-BaseWeapon, resetear cooldown manualmente
				if weapon.has_method("reset_cooldown"):
					weapon.reset_cooldown()
				elif "current_cooldown" in weapon and "base_cooldown" in weapon:
					weapon.current_cooldown = weapon.base_cooldown
			weapon_fired.emit(weapon, player.global_position)

func _process_legacy_weapon(weapon, delta: float) -> void:
	"""Procesar arma legacy (como IceWand original)"""
	# Las armas legacy tienen current_cooldown y base_cooldown
	if weapon.has_method("perform_attack"):
		if "current_cooldown" in weapon:
			weapon.current_cooldown -= delta
			if weapon.current_cooldown <= 0:
				# Verificar que el árbol siga válido
				if not player.get_tree():
					return
				weapon.perform_attack(player)
				weapon.current_cooldown = weapon.base_cooldown if "base_cooldown" in weapon else 1.0
				weapon_fired.emit(weapon, player.global_position)

# ═══════════════════════════════════════════════════════════════════════════════
# CONTROL
# ═══════════════════════════════════════════════════════════════════════════════

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
	"""Remover todas las armas y limpiar orbitales activos"""
	for weapon in weapons:
		if weapon is BaseWeapon and weapon.has_signal("weapon_leveled_up"):
			if weapon.weapon_leveled_up.is_connected(_on_weapon_leveled_up):
				weapon.weapon_leveled_up.disconnect(_on_weapon_leveled_up)
	weapons.clear()

	# Limpiar OrbitalManager del jugador si existe
	if player:
		var orbital_manager = player.get_node_or_null("OrbitalManager")
		if orbital_manager:
			orbital_manager.queue_free()
			print("[AttackManager] OrbitalManager eliminado")

	print("[AttackManager] Todas las armas removidas")

# ═══════════════════════════════════════════════════════════════════════════════
# STATS GLOBALES DE ARMAS (Nuevo sistema)
# ═══════════════════════════════════════════════════════════════════════════════

func apply_global_upgrade(upgrade_data: Dictionary) -> void:
	"""
	Aplicar mejora global que afecta a TODAS las armas.
	Usado por LevelUpPanel para mejoras genéricas.
	"""
	if global_weapon_stats:
		global_weapon_stats.apply_upgrade(upgrade_data)
		print("[AttackManager] ⬆️ Mejora global aplicada: %s" % upgrade_data.get("id", "unknown"))

func get_global_weapon_stats() -> GlobalWeaponStats:
	"""Obtener referencia a los stats globales"""
	return global_weapon_stats

func get_global_stat(stat_name: String) -> float:
	"""Obtener un stat global específico"""
	if global_weapon_stats:
		return global_weapon_stats.get_stat(stat_name)
	return _legacy_player_stats.get(stat_name, 0.0)

# ═══════════════════════════════════════════════════════════════════════════════
# STATS POR ARMA INDIVIDUAL (Nuevo sistema)
# ═══════════════════════════════════════════════════════════════════════════════

func get_weapon_stats(weapon_id: String) -> WeaponStats:
	"""Obtener WeaponStats de un arma específica"""
	return weapon_stats_map.get(weapon_id, null)

func apply_weapon_upgrade(weapon_id: String, upgrade_data: Dictionary) -> bool:
	"""
	Aplicar mejora específica a UN arma.
	Usado por cofres/bosses/élites para mejoras asignables.
	"""
	if not weapon_stats_map.has(weapon_id):
		push_error("[AttackManager] Arma %s no tiene WeaponStats" % weapon_id)
		return false
	
	var ws: WeaponStats = weapon_stats_map[weapon_id]
	ws.apply_upgrade(upgrade_data)
	print("[AttackManager] ⬆️ Mejora específica aplicada a %s: %s" % [weapon_id, upgrade_data.get("id", "unknown")])
	return true

func _create_weapon_stats_for(weapon) -> void:
	"""Crear WeaponStats para un arma al añadirla"""
	var weapon_id = _get_weapon_id(weapon)
	if weapon_id.is_empty():
		return
	
	# Crear WeaponStats desde los datos del arma
	var ws = WeaponStats.new()
	if weapon is BaseWeapon:
		# Usar datos del BaseWeapon
		ws.weapon_id = weapon.id
		ws.base_stats["damage"] = weapon.damage
		ws.base_stats["attack_speed"] = 1.0 / weapon.cooldown if weapon.cooldown > 0 else 1.0
		ws.base_stats["projectile_speed"] = weapon.projectile_speed
		ws.base_stats["area"] = weapon.area
		ws.base_stats["range"] = weapon.weapon_range
		ws.base_stats["projectile_count"] = weapon.projectile_count
		ws.base_stats["pierce"] = weapon.pierce
		ws.base_stats["duration"] = weapon.duration
		ws.base_stats["knockback"] = weapon.knockback
	else:
		# Arma legacy
		ws.weapon_id = weapon_id
		if "damage" in weapon:
			ws.base_stats["damage"] = weapon.damage
		if "base_cooldown" in weapon:
			ws.base_stats["attack_speed"] = 1.0 / weapon.base_cooldown if weapon.base_cooldown > 0 else 1.0
	
	weapon_stats_map[weapon_id] = ws
	print("[AttackManager] WeaponStats creado para: %s" % weapon_id)

func _remove_weapon_stats_for(weapon) -> void:
	"""Remover WeaponStats de un arma al quitarla"""
	var weapon_id = _get_weapon_id(weapon)
	if weapon_stats_map.has(weapon_id):
		weapon_stats_map.erase(weapon_id)

# ═══════════════════════════════════════════════════════════════════════════════
# STATS DEL JUGADOR (Compatibilidad legacy)
# ═══════════════════════════════════════════════════════════════════════════════

func set_player_stat(stat_name: String, value: float) -> void:
	"""Establecer stat del jugador (usa GlobalWeaponStats)"""
	# Convertir cooldown_mult a attack_speed_mult si viene del sistema legacy
	if stat_name == "cooldown_mult":
		stat_name = "attack_speed_mult"
		# Invertir: cooldown 0.8 = attack_speed 1.25
		value = 1.0 / value if value > 0 else 1.0
	
	if global_weapon_stats:
		global_weapon_stats.set_stat(stat_name, value)
	else:
		_legacy_player_stats[stat_name] = value
	print("[AttackManager] Stat actualizado: %s = %.2f" % [stat_name, value])

func modify_player_stat(stat_name: String, delta: float) -> void:
	"""Modificar stat del jugador (sumar/restar)"""
	if stat_name == "cooldown_mult":
		# Convertir delta de cooldown a attack_speed
		stat_name = "attack_speed_mult"
		# Invertir lógica: -0.1 cooldown = +X attack_speed
		delta = -delta  # Simplificación
	
	if global_weapon_stats:
		global_weapon_stats.add_stat(stat_name, delta)
	else:
		if not _legacy_player_stats.has(stat_name):
			_legacy_player_stats[stat_name] = 0.0
		_legacy_player_stats[stat_name] += delta
	print("[AttackManager] Stat modificado: %s += %.2f" % [stat_name, delta])

func get_player_stat(stat_name: String) -> float:
	"""Obtener stat del jugador"""
	# Convertir cooldown_mult a attack_speed_mult
	if stat_name == "cooldown_mult":
		var attack_speed = get_global_stat("attack_speed_mult")
		# Devolver como cooldown_mult para compatibilidad
		return 1.0 / attack_speed if attack_speed > 0 else 1.0
	return get_global_stat(stat_name)

# ═══════════════════════════════════════════════════════════════════════════════
# UTILIDADES
# ═══════════════════════════════════════════════════════════════════════════════

func get_total_damage() -> float:
	"""Obtener daño total de todas las armas"""
	var total: float = 0.0
	for weapon in weapons:
		total += weapon.damage
	return total * player_stats.damage_mult

func get_weapons_by_element(element) -> Array:
	"""Obtener armas de un elemento específico"""
	var result: Array = []
	for weapon in weapons:
		var weapon_element = weapon.element if weapon is BaseWeapon else weapon.get("element_type", "")
		if weapon_element == element:
			result.append(weapon)
	return result

func get_info() -> Dictionary:
	"""Obtener información del atacante para UI"""
	var weapon_infos = []
	var global_stats = global_weapon_stats.get_all_stats() if global_weapon_stats else _legacy_player_stats
	
	for weapon in weapons:
		var weapon_id = _get_weapon_id(weapon)
		var ws = weapon_stats_map.get(weapon_id, null)
		
		if weapon is BaseWeapon:
			# Calcular stats finales con mejoras globales
			var base_damage = weapon.damage
			var base_cooldown = weapon.cooldown
			var base_attack_speed = 1.0 / base_cooldown if base_cooldown > 0 else 1.0
			
			# Aplicar mejoras globales
			var final_damage = base_damage * global_stats.get("damage_mult", 1.0)
			var final_attack_speed = base_attack_speed * global_stats.get("attack_speed_mult", 1.0)
			
			# Aplicar mejoras específicas del arma si existen
			if ws:
				final_damage = ws.get_final_stat("damage", global_stats)
				final_attack_speed = ws.get_final_attack_speed(global_stats)
			
			weapon_infos.append({
				"id": weapon.id,
				"name": weapon.weapon_name,
				"name_es": weapon.weapon_name_es,
				"level": weapon.level,
				"max_level": weapon.max_level,
				"damage": base_damage,
				"damage_final": final_damage,
				"cooldown": base_cooldown,
				"attack_speed": base_attack_speed,
				"attack_speed_final": final_attack_speed,
				"icon": weapon.icon,
				"is_fused": weapon.is_fused,
				"can_level_up": weapon.can_level_up(),
				"next_upgrade": weapon.get_next_upgrade_description(),
				"has_specific_upgrades": ws != null and ws.get_applied_upgrades().size() > 0,
				"specific_upgrades": ws.get_applied_upgrades() if ws else []
			})
		else:
			# Arma legacy
			var base_cd = weapon.base_cooldown if "base_cooldown" in weapon else 1.0
			var base_as = 1.0 / base_cd if base_cd > 0 else 1.0
			
			weapon_infos.append({
				"id": weapon_id,
				"name": _get_weapon_name(weapon),
				"name_es": _get_weapon_name(weapon),
				"level": 1,
				"max_level": 1,
				"damage": weapon.damage if "damage" in weapon else 0,
				"damage_final": (weapon.damage if "damage" in weapon else 0) * global_stats.get("damage_mult", 1.0),
				"cooldown": base_cd,
				"attack_speed": base_as,
				"attack_speed_final": base_as * global_stats.get("attack_speed_mult", 1.0),
				"icon": null,
				"is_fused": false,
				"can_level_up": false,
				"next_upgrade": "N/A",
				"has_specific_upgrades": false,
				"specific_upgrades": []
			})

	return {
		"total_weapons": current_weapon_count,
		"max_slots": max_weapon_slots,
		"slots_used": current_weapon_count,
		"total_damage": get_total_damage(),
		"global_stats": global_stats.duplicate(),
		"player_stats": global_stats.duplicate(),  # Alias para compatibilidad
		"weapons": weapon_infos,
		"available_fusions": get_available_fusions().size()
	}

# ═══════════════════════════════════════════════════════════════════════════════
# SERIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func to_dict() -> Dictionary:
	"""Serializar para guardado"""
	var weapons_data = []
	for weapon in weapons:
		if weapon is BaseWeapon:
			weapons_data.append(weapon.to_dict())
		else:
			# Arma legacy - serialización básica
			weapons_data.append({
				"id": _get_weapon_id(weapon),
				"name": _get_weapon_name(weapon),
				"is_legacy": true
			})
	
	# Serializar WeaponStats individuales
	var weapon_stats_data = {}
	for weapon_id in weapon_stats_map:
		var ws: WeaponStats = weapon_stats_map[weapon_id]
		weapon_stats_data[weapon_id] = ws.to_dict()

	return {
		"weapons": weapons_data,
		"global_weapon_stats": global_weapon_stats.to_dict() if global_weapon_stats else {},
		"weapon_stats": weapon_stats_data,
		"player_stats": player_stats.duplicate(),  # Compatibilidad
		"fusion_manager": fusion_manager.to_dict()
	}

func from_dict(data: Dictionary) -> void:
	"""Restaurar desde datos guardados"""
	# Limpiar estado actual
	clear_weapons()

	# Restaurar fusion manager
	if data.has("fusion_manager"):
		fusion_manager.from_dict(data.fusion_manager)
	
	# Restaurar global weapon stats
	if data.has("global_weapon_stats") and global_weapon_stats:
		global_weapon_stats.from_dict(data.global_weapon_stats)
	elif data.has("player_stats"):
		# Compatibilidad con saves antiguos
		_sync_legacy_to_global(data.player_stats)

	# Restaurar armas
	if data.has("weapons"):
		for weapon_data in data.weapons:
			var weapon = BaseWeapon.from_dict(weapon_data)
			if weapon:
				add_weapon(weapon)
	
	# Restaurar WeaponStats individuales
	if data.has("weapon_stats"):
		for weapon_id in data.weapon_stats:
			if weapon_stats_map.has(weapon_id):
				# Crear nuevo WeaponStats desde datos guardados
				var ws = WeaponStats.from_dict(data.weapon_stats[weapon_id])
				if ws:
					weapon_stats_map[weapon_id] = ws

func _notification(what: int) -> void:
	"""Limpiar al eliminar nodo"""
	if what == NOTIFICATION_PREDELETE:
		clear_weapons()

# ═══════════════════════════════════════════════════════════════════════════════
# DEBUG
# ═══════════════════════════════════════════════════════════════════════════════

func get_debug_info() -> String:
	var global_stats = global_weapon_stats.get_all_stats() if global_weapon_stats else _legacy_player_stats
	
	var lines = [
		"=== ATTACK MANAGER (v2.0) ===",
		"Slots: %d / %d" % [current_weapon_count, max_weapon_slots],
		"Active: %s" % is_active,
		"",
		"🌍 Stats Globales de Armas:",
	]

	for stat in global_stats:
		var value = global_stats[stat]
		var display = ""
		if stat.ends_with("_mult"):
			display = "+%.0f%%" % ((value - 1.0) * 100) if value != 1.0 else "base"
		elif stat == "extra_projectiles":
			display = "+%d" % value if value > 0 else "base"
		else:
			display = "%.2f" % value
		lines.append("  %s: %s" % [stat, display])

	lines.append("")
	lines.append("⚔️ Armas Equipadas:")

	for i in range(weapons.size()):
		var w = weapons[i]
		var weapon_id = _get_weapon_id(w)
		var ws = weapon_stats_map.get(weapon_id, null)
		
		# Calcular stats finales
		var base_damage = w.damage if "damage" in w else 0
		var base_cooldown = w.cooldown if w is BaseWeapon else (w.base_cooldown if "base_cooldown" in w else 1.0)
		var base_attack_speed = 1.0 / base_cooldown if base_cooldown > 0 else 1.0
		
		var final_damage = base_damage * global_stats.get("damage_mult", 1.0)
		var final_attack_speed = base_attack_speed * global_stats.get("attack_speed_mult", 1.0)
		
		if ws:
			final_damage = ws.get_final_stat("damage", global_stats)
			final_attack_speed = ws.get_final_attack_speed(global_stats)
		
		var weapon_name = w.weapon_name if w is BaseWeapon else _get_weapon_name(w)
		var weapon_icon = w.icon if w is BaseWeapon else "🔫"
		var weapon_level = w.level if w is BaseWeapon else 1
		var is_fused = w.is_fused if w is BaseWeapon else false
		
		lines.append("  [%d] %s %s Lv.%d" % [i, weapon_icon, weapon_name, weapon_level])
		lines.append("      DMG: %.0f → %.0f | VEL: %.2f → %.2f ataques/s%s" % [
			base_damage, final_damage, base_attack_speed, final_attack_speed,
			" [FUSED]" if is_fused else ""
		])
		
		# Mostrar mejoras específicas si existen
		if ws and ws.get_applied_upgrades().size() > 0:
			var upgrades = ws.get_applied_upgrades()
			lines.append("      📦 Mejoras: %s" % ", ".join(upgrades))

	var fusions = get_available_fusions()
	if not fusions.is_empty():
		lines.append("")
		lines.append("🔥 Fusiones disponibles: %d" % fusions.size())
	return "\n".join(lines)

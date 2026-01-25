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
		return _get_combined_global_stats()
		# Legacy fallback handled in _get_combined_global_stats
	set(value):
		# Para compatibilidad con código que asigna al dict directamente
		_legacy_player_stats = value
		if global_weapon_stats:
			_sync_legacy_to_global(value)

var _legacy_player_stats: Dictionary = {
	"damage_mult": 1.0,
	"attack_speed_mult": 1.0,
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
# HELPER PARA FILTRADO DE MEJORAS
# ═══════════════════════════════════════════════════════════════════════════════

func get_weapon_tags() -> Dictionary:
	"""
	Obtiene los tags de todas las armas equipadas para filtrar mejoras.
	Retorna:
	{
		"all": Array con TODOS los tags presentes en AL MENOS UN arma
		"common": Array con los tags presentes en TODAS las armas
	}
	"""
	var all_tags = []
	var common_tags = []
	var first_weapon = true
	
	if weapons.is_empty():
		return {"all": [], "common": []}
		
	for weapon in weapons:
		# Obtener tags del arma
		var w_tags = []
		if "tags" in weapon:
			w_tags = weapon.tags
		elif weapon.has_method("get_tags"):
			w_tags = weapon.get_tags()
			
		# Añadir a all_tags (sin duplicados)
		for tag in w_tags:
			if tag not in all_tags:
				all_tags.append(tag)
		
		# Calcular common_tags
		if first_weapon:
			common_tags = w_tags.duplicate()
			first_weapon = false
		else:
			# Intersección: mantener solo los que están en ambos
			var new_common = []
			for tag in common_tags:
				if tag in w_tags:
					new_common.append(tag)
			common_tags = new_common
			
	return {
		"all": all_tags,
		"common": common_tags
	}

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

func _get_combined_global_stats() -> Dictionary:
	"""
	Obtener stats globales de armas desde GlobalWeaponStats.
	
	ARQUITECTURA UNIFICADA (v3.0):
	- TODOS los stats de armas (damage_mult, attack_speed_mult, crit_*, life_steal, etc.)
	  están EXCLUSIVAMENTE en GlobalWeaponStats
	- PlayerStats solo contiene stats del jugador (max_health, armor, move_speed, etc.)
	- Esto elimina duplicación y simplifica el sistema
	"""
	if global_weapon_stats:
		return global_weapon_stats.get_all_stats()
	return _legacy_player_stats.duplicate()

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
	# Asegurar que AttackManager respete la pausa del juego
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	# Añadir al grupo para que ProjectileFactory pueda encontrarnos
	add_to_group("attack_manager")
	
	# Crear el manager de fusiones (como hijo para gestión automática de memoria)
	fusion_manager = WeaponFusionManager.new()
	fusion_manager.name = "FusionManager"
	add_child(fusion_manager)
	fusion_manager.fusion_completed.connect(_on_fusion_completed)
	fusion_manager.fusion_failed.connect(_on_fusion_failed)
	
	# Crear sistema de stats globales (como hijo para gestión automática de memoria)
	global_weapon_stats = GlobalWeaponStats.new()
	global_weapon_stats.name = "GlobalWeaponStats"
	add_child(global_weapon_stats)
	global_weapon_stats.global_stat_changed.connect(_on_global_stats_changed)

	# Debug desactivado: print("[AttackManager] Inicializado con sistema de fusiones y GlobalWeaponStats")

func _on_global_stats_changed(stat_name: String, _old_value: float, _new_value: float) -> void:
	"""Callback cuando cambian los stats globales"""
	global_stats_changed.emit()
	
	# REFRESCAR ORBITALES (Fix para bug de auditoría)
	# Los orbitales son persistentes, así que si cambian stats clave (daño, cantidad, área),
	# debemos destruirlos y recrearlos para que se actualicen.
	var refresh_stats = [
		"damage_mult", "damage_flat", "crit_chance", "crit_damage", 
		"extra_projectiles", "area_mult", "projectile_speed_mult", 
		"knockback_mult", "duration_mult"
	]
	
	if stat_name in refresh_stats:
		_refresh_active_orbital_weapons()

func _refresh_active_orbital_weapons() -> void:
	"""Reiniciar armas orbitales para aplicar nuevos stats"""
	if not player or not is_instance_valid(player) or not player.get_tree():
		return
		
	for weapon in weapons:
		if weapon is BaseWeapon:
			var is_orbital = weapon.projectile_type == WeaponDatabase.ProjectileType.ORBIT or \
							 weapon.target_type == WeaponDatabase.TargetType.ORBIT
			
			if is_orbital:
				# 1. Destruir proyectiles del grupo
				var group_name = "weapon_projectiles_" + weapon.id
				player.get_tree().call_group(group_name, "queue_free")
				
				# 2. CRÍTICO: También destruir el OrbitalManager
				# Si no lo destruimos, update_orbitals() detectará el mismo weapon_id
				# y solo actualizará stats, NO recreará los orbitales destruidos
				var orbital_mgr_name = "OrbitalManager_" + weapon.id
				var orbital_mgr = player.get_node_or_null(orbital_mgr_name)
				if orbital_mgr:
					orbital_mgr.queue_free()
				
				# 3. Forzar disparo inmediato (re-spawn completo)
				weapon.ready_to_fire = true
				# Usar call_deferred para dar tiempo a que se borren los viejos
				call_deferred("_force_respawn_orbital", weapon)

func _force_respawn_orbital(weapon: BaseWeapon) -> void:
	"""Helper para respawnear orbital en el siguiente frame"""
	if is_instance_valid(player) and is_active:
		weapon.perform_attack(player, player_stats)

func _exit_tree() -> void:
	"""Limpiar referencias cuando el nodo se elimina del árbol"""
	# Los hijos se liberan automáticamente, solo limpiamos referencias
	fusion_manager = null
	global_weapon_stats = null
	player = null

func initialize(player_ref: CharacterBody2D) -> void:
	"""Inicializar con referencia al jugador"""
	player = player_ref
	# Debug desactivado: print("[AttackManager] Inicializado para player: %s" % player.name)
	# Debug desactivado: print("[AttackManager] Slots disponibles: %d/%d" % [current_weapon_count, max_weapon_slots])

	# Activar el sistema de ataque
	is_active = true
	
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
		print("[AttackManager] ❌ No hay slots disponibles (%d/%d)" % [current_weapon_count, max_weapon_slots])
		return false

	# Obtener ID del arma (compatible con ambos sistemas)
	var weapon_id = _get_weapon_id(weapon)
	var weapon_display_name = _get_weapon_name(weapon)

	# Verificar si ya tenemos esta arma
	for existing in weapons:
		if _get_weapon_id(existing) == weapon_id:
			print("[AttackManager] ℹ️ Ya tienes %s, subiendo de nivel..." % weapon_display_name)
			var lvl_result = level_up_weapon_by_id(weapon_id)
			print("[AttackManager] ⬆️ Level up result for %s: %s" % [weapon_id, lvl_result])
			return lvl_result

	# Añadir a la lista
	weapons.append(weapon)
	var slot_index = weapons.size() - 1
	
	# Crear WeaponStats para esta arma (nuevo sistema)
	_create_weapon_stats_for(weapon)

	# Conectar señales del arma (solo si es BaseWeapon)
	if weapon is BaseWeapon and weapon.has_signal("weapon_leveled_up"):
		weapon.weapon_leveled_up.connect(_on_weapon_leveled_up)

	# Debug desactivado: print("[AttackManager] ⚔️ Arma equipada: %s [Slot %d] (total: %d/%d)" % [
	#	weapon_display_name, slot_index, current_weapon_count, max_weapon_slots
	# ])

	weapon_added.emit(weapon, slot_index)
	slots_updated.emit(current_weapon_count, max_weapon_slots)

	# Verificar fusiones disponibles (solo para BaseWeapon)
	if weapon is BaseWeapon:
		_check_available_fusions()

	return true

func add_weapon_by_id(weapon_id: String) -> bool:
	"""Añadir arma por su ID"""
	print("[AttackManager] ➡️ add_weapon_by_id START: ", weapon_id)
	var weapon = BaseWeapon.new(weapon_id)
	
	if weapon.id.is_empty():
		push_error("[AttackManager] ❌ No se pudo crear arma: %s (ID vacío)" % weapon_id)
		print("[AttackManager] ❌ Failed to instantiate BaseWeapon with ID: ", weapon_id)
		return false
		
	var result = add_weapon(weapon)
	print("[AttackManager] ⬅️ add_weapon_by_id END: ", weapon_id, " | Result: ", result)
	return result

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

	# Debug desactivado: print("[AttackManager] ⚔️ Arma removida: %s (total: %d/%d)" % [
	#	_get_weapon_name(weapon), current_weapon_count, max_weapon_slots
	# ])

	weapon_removed.emit(weapon, slot_index)
	slots_updated.emit(current_weapon_count, max_weapon_slots)

	# LIMPIEZA DE NODOS PERSISTENTES (Fix Ghost Orbs)
	if player and is_instance_valid(player):
		var wid = _get_weapon_id(weapon)
		if not wid.is_empty():
			# 1. Borrar OrbitalManager si existe (proyectiles que orbitan adheridos al player)
			var orbital_mgr = player.get_node_or_null("OrbitalManager_" + wid)
			if orbital_mgr:
				orbital_mgr.queue_free()
				print("[AttackManager] 🧹 Limpiado OrbitalManager para: ", wid)
			
			# 2. Borrar proyectiles sueltos en el grupo especifico (proyectiles de vuelo libre)
			# Usamos call_deferred para asegurar limpieza segura physics-safe
			if player.get_tree():
				player.get_tree().call_group("weapon_projectiles_" + wid, "queue_free")

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

	# Debug desactivado: print("[AttackManager] ⚔️ Arma reemplazada: %s -> %s" % [
	#	_get_weapon_name(old_weapon), _get_weapon_name(new_weapon)
	# ])
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
			# Debug desactivado: print("[AttackManager] %s ya está al nivel máximo" % _get_weapon_name(weapon))
			return false
		
		var success = weapon.level_up()
		if success:
			# CRÍTICO: Sincronizar WeaponStats con los nuevos valores del arma
			_sync_weapon_stats_after_levelup(weapon)
			# Actualizar metas de valores originales para aplicar stats globales correctamente
			_update_weapon_original_metas(weapon)
		return success

	# Armas legacy no tienen sistema de niveles
	# Debug desactivado: print("[AttackManager] %s es un arma legacy sin sistema de niveles" % _get_weapon_name(weapon))
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

	# Verificar que sean BaseWeapon antes de fusionar
	if not weapon_a is BaseWeapon:
		push_error("[AttackManager] %s es un arma legacy y no puede fusionarse" % weapon_id_a)
		return null
	if not weapon_b is BaseWeapon:
		push_error("[AttackManager] %s es un arma legacy y no puede fusionarse" % weapon_id_b)
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
		# Debug desactivado: print("[AttackManager] ⬆️ %s subió a nivel %d" % [_get_weapon_name(weapon), new_level])

func _on_fusion_completed(fused_weapon, lost_slot: bool) -> void:
	"""Callback cuando se completa una fusión"""
	# Debug desactivado: print("[AttackManager] 🔥 Fusión completada: %s" % _get_weapon_name(fused_weapon))
	if lost_slot:
		# Debug desactivado: print("[AttackManager] ⚠️ Slots reducidos: %d/%d" % [current_weapon_count, max_weapon_slots])
		pass

func _on_fusion_failed(reason: String) -> void:
	"""Callback cuando falla una fusión"""
	# Debug desactivado: print("[AttackManager] ❌ Fusión fallida: %s" % reason)

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



		# Decrementar cooldown
		weapon.tick_cooldown(delta)

		# Comprobar si está lista para disparar
		if weapon.is_ready_to_fire():
			# Verificar que el árbol siga válido antes de disparar
			if not player.get_tree():
				return
			# Disparar con stats del jugador (solo BaseWeapon soporta esto)
			var did_fire = false
			if weapon is BaseWeapon:
				did_fire = weapon.perform_attack(player, player_stats)
				# CRÍTICO: Aplicar attack_speed_mult global al cooldown del arma
				if did_fire and "current_cooldown" in weapon:
					var gs = _get_combined_global_stats()
					var attack_speed_mult = maxf(gs.get("attack_speed_mult", 1.0), 0.1)
					# Siempre aplicar el multiplicador (tanto buffs como debuffs)
					# Mayor attack_speed = menor cooldown (atacas más rápido)
					# Menor attack_speed = mayor cooldown (atacas más lento)
					weapon.current_cooldown = weapon.cooldown / attack_speed_mult

			
			# Solo activar animación de cast si realmente disparó y NO es orbital
			if did_fire and _should_play_cast_animation(weapon):
				_trigger_cast_animation()
			if did_fire:
				weapon_fired.emit(weapon, player.global_position)



func _should_play_cast_animation(weapon) -> bool:
	"""Determinar si el arma debe activar la animación de cast al disparar"""
	# Las armas orbitales no requieren animación de cast (orbitan automáticamente)
	if weapon is BaseWeapon:
		if weapon.projectile_type == WeaponDatabase.ProjectileType.ORBIT:
			return false
		if weapon.target_type == WeaponDatabase.TargetType.ORBIT:
			return false
	

	
	# También excluir armas de aura/pasivas si las hay
	if weapon.has_method("is_passive_weapon") and weapon.is_passive_weapon():
		return false
	
	return true

func _trigger_cast_animation() -> void:
	"""Activar animación de cast en el player si está disponible"""
	if player and player.has_method("play_cast_animation"):
		player.play_cast_animation()
	# También intentar con WizardPlayer si está anidado
	elif player:
		var wizard = player.get_node_or_null("WizardPlayer")
		if wizard and wizard.has_method("play_cast_animation"):
			wizard.play_cast_animation()



# ═══════════════════════════════════════════════════════════════════════════════
# CONTROL
# ═══════════════════════════════════════════════════════════════════════════════

func enable() -> void:
	"""Activar ataque automático"""
	is_active = true
	set_process(true)
	# Debug desactivado: print("[AttackManager] Ataque activado")

func disable() -> void:
	"""Desactivar ataque automático"""
	is_active = false
	set_process(false)
	# Debug desactivado: print("[AttackManager] Ataque desactivado")

func clear_weapons() -> void:
	"""Remover todas las armas y limpiar orbitales activos"""
	for weapon in weapons:
		if weapon is BaseWeapon and weapon.has_signal("weapon_leveled_up"):
			if weapon.weapon_leveled_up.is_connected(_on_weapon_leveled_up):
				weapon.weapon_leveled_up.disconnect(_on_weapon_leveled_up)
	weapons.clear()

	# Limpiar TODOS los OrbitalManager del jugador (buscar por prefijo)
	if player and is_instance_valid(player):
		for child in player.get_children():
			if child.name.begins_with("OrbitalManager"):
				child.queue_free()
				# Debug: print("[AttackManager] OrbitalManager eliminado: %s" % child.name)

	# Debug desactivado: print("[AttackManager] Todas las armas removidas")

func reset_for_new_game() -> void:
	"""
	CRÍTICO: Resetear completamente el estado para una nueva partida.
	Debe llamarse al iniciar una nueva partida para evitar que el estado
	de la partida anterior persista.
	"""
	print("[AttackManager] 🔄 Reseteando estado para nueva partida...")
	
	# 1. Limpiar todas las armas
	clear_weapons()
	
	# 2. Limpiar el mapa de stats por arma
	weapon_stats_map.clear()
	
	# 3. Resetear GlobalWeaponStats a sus valores por defecto
	if global_weapon_stats:
		global_weapon_stats.reset()
	
	# 4. Resetear legacy player stats
	_legacy_player_stats = {
		"damage_mult": 1.0,
		"attack_speed_mult": 1.0,
		"crit_chance": 0.0,
		"crit_damage": 2.0,
		"area_mult": 1.0,
		"projectile_speed_mult": 1.0,
		"duration_mult": 1.0,
		"extra_projectiles": 0,
		"knockback_mult": 1.0,
		"life_steal": 0.0
	}
	
	# 5. Resetear FusionManager (slots perdidos, historial)
	if fusion_manager:
		fusion_manager.reset()
	
	# 6. Resetear estado estático de ProjectileFactory
	ProjectileFactory.reset_for_new_game()
	
	# 7. Resetear referencia al jugador
	player = null
	
	# 8. Desactivar temporalmente hasta que se reinicialice
	is_active = false
	
	print("[AttackManager] ✓ Estado reseteado completamente")

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
		# Debug desactivado: print("[AttackManager] ⬆️ Mejora global aplicada: %s" % upgrade_data.get("id", "unknown"))

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
	# Debug desactivado: print("[AttackManager] ⬆️ Mejora específica aplicada a %s: %s" % [weapon_id, upgrade_data.get("id", "unknown")])
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
		pass  # Bloque else
		# Arma legacy
		ws.weapon_id = weapon_id
		if "damage" in weapon:
			ws.base_stats["damage"] = weapon.damage
		if "base_cooldown" in weapon:
			ws.base_stats["attack_speed"] = 1.0 / weapon.base_cooldown if weapon.base_cooldown > 0 else 1.0
	
	# CRÍTICO: Recalcular modified_stats después de establecer base_stats
	ws._recalculate_stats()
	
	weapon_stats_map[weapon_id] = ws
	# Debug desactivado: print("[AttackManager] WeaponStats creado para: %s" % weapon_id)

func _remove_weapon_stats_for(weapon) -> void:
	"""Remover WeaponStats de un arma al quitarla"""
	var weapon_id = _get_weapon_id(weapon)
	if weapon_stats_map.has(weapon_id):
		weapon_stats_map.erase(weapon_id)

func _sync_weapon_stats_after_levelup(weapon) -> void:
	"""Sincronizar WeaponStats con los nuevos valores del arma después de subir de nivel"""
	var weapon_id = _get_weapon_id(weapon)
	if weapon_id.is_empty():
		return
	
	var ws = weapon_stats_map.get(weapon_id, null)
	if ws == null:
		# Si no existe, crearlo
		_create_weapon_stats_for(weapon)
		return
	
	# Actualizar base_stats con los nuevos valores del arma
	if weapon is BaseWeapon:
		ws.weapon_level = weapon.level
		ws.base_stats["damage"] = weapon.damage
		ws.base_stats["attack_speed"] = 1.0 / weapon.cooldown if weapon.cooldown > 0 else 1.0
		ws.base_stats["projectile_speed"] = weapon.projectile_speed
		ws.base_stats["area"] = weapon.area
		ws.base_stats["range"] = weapon.weapon_range
		ws.base_stats["projectile_count"] = weapon.projectile_count
		ws.base_stats["pierce"] = weapon.pierce
		ws.base_stats["duration"] = weapon.duration
		ws.base_stats["knockback"] = weapon.knockback
		ws.base_stats["effect_value"] = weapon.effect_value
	
	# Recalcular modified_stats
	ws._recalculate_stats()
	# print("[AttackManager] WeaponStats sincronizado para %s nivel %d" % [weapon_id, weapon.level])

func _update_weapon_original_metas(weapon) -> void:
	"""Actualizar los valores originales guardados en meta cuando el arma sube de nivel"""
	# CRÍTICO: Cuando el arma sube de nivel y gana stats (ej: +1 proyectil),
	# debemos actualizar los metas para que los stats globales se apliquen correctamente
	if weapon is BaseWeapon:
		weapon.set_meta("_original_damage", weapon.damage)
		weapon.set_meta("_original_projectile_speed", weapon.projectile_speed)
		weapon.set_meta("_original_projectile_count", weapon.projectile_count)
		weapon.set_meta("_original_knockback", weapon.knockback)
		weapon.set_meta("_original_pierce", weapon.pierce)
	elif "damage" in weapon:
		# Arma legacy
		weapon.set_meta("_original_damage", weapon.damage)
		if "projectile_speed" in weapon:
			weapon.set_meta("_original_projectile_speed", weapon.projectile_speed)
		if "projectile_count" in weapon:
			weapon.set_meta("_original_projectile_count", weapon.projectile_count)
		if "knockback_force" in weapon:
			weapon.set_meta("_original_knockback", weapon.knockback_force)
		if "pierce" in weapon:
			weapon.set_meta("_original_pierce", weapon.pierce)

# ═══════════════════════════════════════════════════════════════════════════════
# STATS DEL JUGADOR (Compatibilidad legacy)
# ═══════════════════════════════════════════════════════════════════════════════

func set_player_stat(stat_name: String, value: float) -> void:
	"""Establecer stat del jugador (usa GlobalWeaponStats)"""
	# Convertir cooldown_mult a attack_speed_mult si viene del sistema legacy

	
	if global_weapon_stats:
		global_weapon_stats.set_stat(stat_name, value)
	else:
		_legacy_player_stats[stat_name] = value
	# Debug desactivado: print("[AttackManager] Stat actualizado: %s = %.2f" % [stat_name, value])

func modify_player_stat(stat_name: String, delta: float) -> void:
	"""Modificar stat del jugador (sumar/restar)"""

	
	if global_weapon_stats:
		global_weapon_stats.add_stat(stat_name, delta)
	else:
		if not _legacy_player_stats.has(stat_name):
			_legacy_player_stats[stat_name] = 0.0
		_legacy_player_stats[stat_name] += delta
	# Debug desactivado: print("[AttackManager] Stat modificado: %s += %.2f" % [stat_name, delta])

func get_player_stat(stat_name: String) -> float:
	"""Obtener stat del jugador o de armas desde GlobalWeaponStats"""
	# Convertir cooldown_mult a attack_speed_mult

	
	# ARQUITECTURA v3.0:
	# - WEAPON_STATS (damage_mult, crit_*, life_steal, chain_count, etc.) -> GlobalWeaponStats
	# - PLAYER_STATS (max_health, armor, move_speed, etc.) -> PlayerStats
	# Primero buscar en GlobalWeaponStats (incluye life_steal y todos los weapon stats)
	var value = get_global_stat(stat_name)
	
	# Si es 0 o no existe, buscar en PlayerStats para stats del jugador
	# (NO para weapon stats como life_steal - esos siempre están en GlobalWeaponStats)
	if value == 0.0:
		var game_stats = get_tree().get_first_node_in_group("player_stats")
		if game_stats and game_stats.has_method("get_stat"):
			var ps_value = game_stats.get_stat(stat_name)
			if ps_value != 0.0:
				return ps_value
	
	return value

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

func get_weapon_full_stats(weapon) -> Dictionary:
	"""
	Obtener TODOS los stats de un arma con valores base y finales (con globales aplicados).
	Para uso en UI de detalles de armas.
	
	IMPORTANTE:
	- "base" = valores ORIGINALES del arma desde WeaponDatabase (nivel 1)
	- "current" = valores ACTUALES del arma (con mejoras de nivel aplicadas)
	- "final" = valores finales = current * multiplicadores globales
	"""
	if weapon == null:
		return {}
	
	var weapon_id = _get_weapon_id(weapon)
	var gs = _get_combined_global_stats()
	
	# ═══════════════════════════════════════════════════════════════════════════
	# VALORES ORIGINALES (nivel 1 desde WeaponDatabase - FUENTE CANÓNICA)
	# ═══════════════════════════════════════════════════════════════════════════
	# SIEMPRE usar WeaponDatabase para valores originales para evitar cualquier
	# posible modificación accidental de weapon.base_stats
	var original_data = WeaponDatabase.get_weapon_data(weapon_id)
	if original_data.is_empty() and weapon is BaseWeapon and weapon.base_stats:
		# Fallback solo si no existe en DB (armas custom/fusiones)
		original_data = weapon.base_stats.duplicate()  # Copiar para seguridad
		print("[DEBUG] get_weapon_full_stats: Usando base_stats como fallback para %s" % weapon_id)
	
	var original_damage = original_data.get("damage", 10)
	var original_cooldown = original_data.get("cooldown", 1.0)
	var original_attack_speed = 1.0 / original_cooldown if original_cooldown > 0 else 1.0
	var original_projectile_count = original_data.get("projectile_count", 1)
	var original_pierce = original_data.get("pierce", 0)
	var original_area = original_data.get("area", 1.0)
	var original_projectile_speed = original_data.get("projectile_speed", 300.0)
	var original_range = original_data.get("range", 300.0)
	var original_knockback = original_data.get("knockback", 50.0)
	var original_duration = original_data.get("duration", 0.0)
	
	# DEBUG: Verificar valores de velocidad de ataque
	# print("[DEBUG] %s: original_cooldown=%.2f, original_attack_speed=%.4f" % [weapon_id, original_cooldown, original_attack_speed])
	
	# ═══════════════════════════════════════════════════════════════════════════
	# VALORES ACTUALES DEL ARMA (con mejoras de nivel ya aplicadas)
	# ═══════════════════════════════════════════════════════════════════════════
	var current_damage = weapon.damage if "damage" in weapon else original_damage
	var current_cooldown = weapon.cooldown if "cooldown" in weapon else original_cooldown
	var current_attack_speed = 1.0 / current_cooldown if current_cooldown > 0 else 1.0
	var current_projectile_count = weapon.projectile_count if "projectile_count" in weapon else original_projectile_count
	var current_pierce = weapon.pierce if "pierce" in weapon else original_pierce
	var current_area = weapon.area if "area" in weapon else original_area
	var current_projectile_speed = weapon.projectile_speed if "projectile_speed" in weapon else original_projectile_speed
	var current_range = weapon.weapon_range if "weapon_range" in weapon else original_range
	var current_knockback = weapon.knockback if "knockback" in weapon else original_knockback
	var current_duration = weapon.duration if "duration" in weapon else original_duration
	
	# ═══════════════════════════════════════════════════════════════════════════
	# MULTIPLICADORES GLOBALES (de PlayerStats/mejoras globales)
	# ═══════════════════════════════════════════════════════════════════════════
	var damage_mult = gs.get("damage_mult", 1.0)
	var damage_flat = gs.get("damage_flat", 0)
	var attack_speed_mult = gs.get("attack_speed_mult", 1.0)
	var projectile_speed_mult = gs.get("projectile_speed_mult", 1.0)
	var area_mult = gs.get("area_mult", 1.0)
	var range_mult = gs.get("range_mult", 1.0)
	var knockback_mult = gs.get("knockback_mult", 1.0)
	var duration_mult = gs.get("duration_mult", 1.0)
	var extra_projectiles = int(gs.get("extra_projectiles", 0))
	var extra_pierce = int(gs.get("extra_pierce", 0))
	var crit_chance = gs.get("crit_chance", 0.05)
	var crit_damage = gs.get("crit_damage", 2.0)
	
	# ═══════════════════════════════════════════════════════════════════════════
	# VALORES FINALES = current * multiplicadores globales
	# ═══════════════════════════════════════════════════════════════════════════
	var final_damage = int((current_damage + damage_flat) * damage_mult)
	var final_attack_speed = current_attack_speed * attack_speed_mult
	var final_cooldown = 1.0 / final_attack_speed if final_attack_speed > 0 else 1.0
	var final_projectile_count = current_projectile_count + extra_projectiles
	var final_pierce = current_pierce + extra_pierce
	var final_area = current_area * area_mult
	var final_projectile_speed = current_projectile_speed * projectile_speed_mult
	var final_range = current_range * range_mult
	var final_knockback = current_knockback * knockback_mult
	var final_duration = current_duration * duration_mult
	
	return {
		# Identificadores
		"weapon_id": weapon_id,
		"weapon_name": weapon.weapon_name if "weapon_name" in weapon else _get_weapon_name(weapon),
		"weapon_name_es": weapon.weapon_name_es if "weapon_name_es" in weapon else _get_weapon_name(weapon),
		"element": weapon.element if "element" in weapon else 0,
		"icon": weapon.icon if "icon" in weapon else "🔮",
		"level": weapon.level if "level" in weapon else 1,
		"max_level": weapon.max_level if "max_level" in weapon else 8,
		
		# Daño: original (nivel 1) → final (con todo aplicado)
		"damage_base": original_damage,
		"damage_current": current_damage,
		"damage_final": final_damage,
		"damage_mult": damage_mult,
		"damage_flat": damage_flat,
		
		# Velocidad de ataque
		"attack_speed_base": original_attack_speed,
		"attack_speed_current": current_attack_speed,
		"attack_speed_final": final_attack_speed,
		"attack_speed_mult": attack_speed_mult,
		"cooldown_base": original_cooldown,
		"cooldown_current": current_cooldown,
		"cooldown_final": final_cooldown,
		
		# Proyectiles
		"projectile_count_base": original_projectile_count,
		"projectile_count_current": current_projectile_count,
		"projectile_count_final": final_projectile_count,
		"extra_projectiles": extra_projectiles,
		
		# Velocidad de proyectil
		"projectile_speed_base": original_projectile_speed,
		"projectile_speed_current": current_projectile_speed,
		"projectile_speed_final": final_projectile_speed,
		"projectile_speed_mult": projectile_speed_mult,
		
		# Penetración
		"pierce_base": original_pierce,
		"pierce_current": current_pierce,
		"pierce_final": final_pierce,
		"extra_pierce": extra_pierce,
		
		# Área
		"area_base": original_area,
		"area_current": current_area,
		"area_final": final_area,
		"area_mult": area_mult,
		
		# Alcance
		"range_base": original_range,
		"range_current": current_range,
		"range_final": final_range,
		"range_mult": range_mult,
		
		# Empuje
		"knockback_base": original_knockback,
		"knockback_current": current_knockback,
		"knockback_final": final_knockback,
		"knockback_mult": knockback_mult,
		
		# Duración
		"duration_base": original_duration,
		"duration_current": current_duration,
		"duration_final": final_duration,
		"duration_mult": duration_mult,
		
		# Críticos (globales)
		"crit_chance": crit_chance,
		"crit_damage": crit_damage
	}

func get_info() -> Dictionary:
	"""Obtener información del atacante para UI"""
	var weapon_infos = []
	var global_stats = _get_combined_global_stats()
	
	for weapon in weapons:
		var weapon_id = _get_weapon_id(weapon)
		
		if weapon is BaseWeapon:
			# Valores actuales del arma (ya con mejoras de nivel aplicadas)
			var current_damage = weapon.damage
			var current_cooldown = weapon.cooldown
			var current_attack_speed = 1.0 / current_cooldown if current_cooldown > 0 else 1.0
			
			# Valores originales (nivel 1)
			var original_damage = weapon.base_stats.get("damage", current_damage) if weapon.base_stats else current_damage
			
			# Aplicar mejoras globales - FÓRMULA: (current + flat) * mult
			var damage_flat = global_stats.get("damage_flat", 0)
			var final_damage = int((current_damage + damage_flat) * global_stats.get("damage_mult", 1.0))
			var final_attack_speed = current_attack_speed * global_stats.get("attack_speed_mult", 1.0)
			
			weapon_infos.append({
				"id": weapon.id,
				"name": weapon.weapon_name,
				"name_es": weapon.weapon_name_es,
				"level": weapon.level,
				"max_level": weapon.max_level,
				"damage": current_damage,  # Daño actual (con mejoras de nivel)
				"damage_base": original_damage,  # Daño original nivel 1
				"damage_final": final_damage,  # Daño con multiplicadores globales
				"cooldown": current_cooldown,
				"attack_speed": current_attack_speed,
				"attack_speed_final": final_attack_speed,
				"icon": weapon.icon,
				"is_fused": weapon.is_fused,
				"can_level_up": weapon.can_level_up(),
				"next_upgrade": weapon.get_next_upgrade_description()
			})
		else:
			# Arma legacy
			var base_cd = weapon.base_cooldown if "base_cooldown" in weapon else 1.0
			var base_as = 1.0 / base_cd if base_cd > 0 else 1.0
			var legacy_damage = weapon.damage if "damage" in weapon else 0
			var damage_flat = global_stats.get("damage_flat", 0)
			
			weapon_infos.append({
				"id": weapon_id,
				"name": _get_weapon_name(weapon),
				"name_es": _get_weapon_name(weapon),
				"level": 1,
				"max_level": 1,
				"damage": legacy_damage,
				"damage_base": legacy_damage,
				"damage_final": int((legacy_damage + damage_flat) * global_stats.get("damage_mult", 1.0)),
				"cooldown": base_cd,
				"attack_speed": base_as,
				"attack_speed_final": base_as * global_stats.get("attack_speed_mult", 1.0),
				"icon": null,
				"is_fused": false,
				"can_level_up": false,
				"next_upgrade": "N/A"
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
			pass  # Bloque else
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
	var global_stats = _get_combined_global_stats()
	
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
		
		# FÓRMULA CORRECTA: (base + flat) * mult
		var damage_flat_val = global_stats.get("damage_flat", 0)
		var final_damage = (base_damage + damage_flat_val) * global_stats.get("damage_mult", 1.0)
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
		if ws and ws.get_upgrades().size() > 0:
			var upgrades = ws.get_upgrades()
			lines.append("      📦 Mejoras: %s" % ", ".join(upgrades))

	var fusions = get_available_fusions()
	if not fusions.is_empty():
		lines.append("")
		lines.append("🔥 Fusiones disponibles: %d" % fusions.size())
	return "\n".join(lines)




func set_active(active: bool) -> void:
	"""Activar o desactivar el sistema de ataques"""
	is_active = active
	set_process(active)
	if not active:
		# Detener todas las armas si se desactiva
		for weapon in weapons:
			if weapon.has_method("stop_firing"):
				weapon.stop_firing()

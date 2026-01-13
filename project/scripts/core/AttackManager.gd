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

func _get_combined_global_stats() -> Dictionary:
	"""
	Obtener stats globales COMBINADOS de GlobalWeaponStats y PlayerStats.
	Los multiplicadores se multiplican entre sí, los valores planos se suman.
	"""
	var gs = global_weapon_stats.get_all_stats() if global_weapon_stats else _legacy_player_stats.duplicate()
	
	# Buscar PlayerStats para combinar sus stats ofensivos
	var ps = get_tree().get_first_node_in_group("player_stats") if is_inside_tree() else null
	if ps and ps.has_method("get_stat"):
		# Multiplicadores: se multiplican
		gs["damage_mult"] = gs.get("damage_mult", 1.0) * ps.get_stat("damage_mult")
		gs["attack_speed_mult"] = gs.get("attack_speed_mult", 1.0) * ps.get_stat("attack_speed_mult")
		gs["area_mult"] = gs.get("area_mult", 1.0) * ps.get_stat("area_mult")
		gs["projectile_speed_mult"] = gs.get("projectile_speed_mult", 1.0) * ps.get_stat("projectile_speed_mult")
		gs["duration_mult"] = gs.get("duration_mult", 1.0) * ps.get_stat("duration_mult")
		gs["knockback_mult"] = gs.get("knockback_mult", 1.0) * ps.get_stat("knockback_mult")
		gs["range_mult"] = gs.get("range_mult", 1.0) * ps.get_stat("range_mult")
		
		# Valores planos: se suman
		gs["damage_flat"] = gs.get("damage_flat", 0.0) + ps.get_stat("damage_flat")
		gs["extra_projectiles"] = int(gs.get("extra_projectiles", 0)) + int(ps.get_stat("extra_projectiles"))
		gs["extra_pierce"] = int(gs.get("extra_pierce", 0)) + int(ps.get_stat("extra_pierce"))
		gs["chain_count"] = int(gs.get("chain_count", 0)) + int(ps.get_stat("chain_count"))
		
		# Críticos: se suman (son porcentajes)
		gs["crit_chance"] = gs.get("crit_chance", 0.05) + ps.get_stat("crit_chance") - 0.05  # Restar el base de PlayerStats
		gs["crit_damage"] = gs.get("crit_damage", 2.0) + ps.get_stat("crit_damage") - 2.0  # Restar el base de PlayerStats
		
		# Life steal
		gs["life_steal"] = gs.get("life_steal", 0.0) + ps.get_stat("life_steal")
	
	return gs

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
		# Debug desactivado: print("[AttackManager] ⚠️ No hay slots disponibles (%d/%d)" % [current_weapon_count, max_weapon_slots])
		return false

	# Obtener ID del arma (compatible con ambos sistemas)
	var weapon_id = _get_weapon_id(weapon)
	var weapon_display_name = _get_weapon_name(weapon)

	# Verificar si ya tenemos esta arma
	for existing in weapons:
		if _get_weapon_id(existing) == weapon_id:
			# Debug desactivado: print("[AttackManager] ℹ️ Ya tienes %s, subiendo de nivel..." % weapon_display_name)
			return level_up_weapon_by_id(weapon_id)

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

	# Debug desactivado: print("[AttackManager] ⚔️ Arma removida: %s (total: %d/%d)" % [
	#	_get_weapon_name(weapon), current_weapon_count, max_weapon_slots
	# ])

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
			var did_fire = false
			if weapon is BaseWeapon:
				did_fire = weapon.perform_attack(player, player_stats)
			else:
				# Arma NO-BaseWeapon pero con métodos tick_cooldown/is_ready_to_fire
				var gs = _get_combined_global_stats()
				_apply_global_stats_to_legacy_weapon(weapon, gs)
				# Capturar si el arma realmente disparó (si retorna bool)
				var result = weapon.perform_attack(player)
				_restore_legacy_weapon_base_stats(weapon)
				# Si perform_attack retorna bool, usar ese valor; si no, asumir que disparó
				did_fire = result if typeof(result) == TYPE_BOOL else true
				
				# Para armas NO-BaseWeapon, resetear cooldown manualmente con mejora de atk speed
				var attack_speed_mult = maxf(gs.get("attack_speed_mult", 1.0), 0.1)
				if weapon.has_method("reset_cooldown"):
					weapon.reset_cooldown()
					# Ajustar cooldown por velocidad de ataque
					if "current_cooldown" in weapon and "base_cooldown" in weapon:
						weapon.current_cooldown = weapon.base_cooldown / attack_speed_mult
				elif "current_cooldown" in weapon and "base_cooldown" in weapon:
					weapon.current_cooldown = weapon.base_cooldown / attack_speed_mult
			
			# Solo activar animación de cast si realmente disparó y NO es orbital
			if did_fire and _should_play_cast_animation(weapon):
				_trigger_cast_animation()
			if did_fire:
				weapon_fired.emit(weapon, player.global_position)

func _process_legacy_weapon(weapon, delta: float) -> void:
	"""Procesar arma legacy (como IceWand original) con stats globales aplicados"""
	# Las armas legacy tienen current_cooldown y base_cooldown
	if weapon.has_method("perform_attack"):
		# Obtener stats globales para aplicar (incluye PlayerStats)
		var gs = _get_combined_global_stats()
		
		# Aplicar multiplicador de velocidad de ataque al cooldown (evitar división por cero)
		var attack_speed_mult = maxf(gs.get("attack_speed_mult", 1.0), 0.1)
		var effective_cooldown = weapon.base_cooldown / attack_speed_mult if "base_cooldown" in weapon else 1.0 / attack_speed_mult
		
		if "current_cooldown" in weapon:
			weapon.current_cooldown -= delta
			if weapon.current_cooldown <= 0:
				# Verificar que el árbol siga válido
				if not player.get_tree():
					return
				
				# Aplicar stats globales ANTES de disparar
				_apply_global_stats_to_legacy_weapon(weapon, gs)
				
				# Capturar si el arma realmente disparó
				var result = weapon.perform_attack(player)
				var did_fire_legacy = result if typeof(result) == TYPE_BOOL else true
				
				# Restaurar valores base después de disparar
				_restore_legacy_weapon_base_stats(weapon)
				
				# Usar cooldown efectivo (con mejoras de velocidad)
				weapon.current_cooldown = effective_cooldown
				
				# Solo activar animación de cast si realmente disparó y no es orbital
				if did_fire_legacy and _should_play_cast_animation(weapon):
					_trigger_cast_animation()
				if did_fire_legacy:
					weapon_fired.emit(weapon, player.global_position)

func _should_play_cast_animation(weapon) -> bool:
	"""Determinar si el arma debe activar la animación de cast al disparar"""
	# Las armas orbitales no requieren animación de cast (orbitan automáticamente)
	if weapon is BaseWeapon:
		if weapon.projectile_type == WeaponDatabase.ProjectileType.ORBIT:
			return false
		if weapon.target_type == WeaponDatabase.TargetType.ORBIT:
			return false
	
	# Para armas legacy, verificar por nombre o propiedades
	if "projectile_type" in weapon:
		var ptype = weapon.projectile_type
		if ptype == WeaponDatabase.ProjectileType.ORBIT:
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

func _apply_global_stats_to_legacy_weapon(weapon, gs: Dictionary) -> void:
	"""Aplicar stats globales temporalmente a un arma legacy antes de disparar"""
	# Guardar valores originales si no los tenemos
	if not weapon.has_meta("_original_damage"):
		weapon.set_meta("_original_damage", weapon.damage if "damage" in weapon else 0)
		weapon.set_meta("_original_projectile_speed", weapon.projectile_speed if "projectile_speed" in weapon else 400.0)
		weapon.set_meta("_original_projectile_count", weapon.projectile_count if "projectile_count" in weapon else 1)
		weapon.set_meta("_original_knockback", weapon.knockback_force if "knockback_force" in weapon else 100.0)
		weapon.set_meta("_original_pierce", weapon.pierce if "pierce" in weapon else 0)
		weapon.set_meta("_original_crit_chance", weapon.crit_chance if "crit_chance" in weapon else 0.05)
		weapon.set_meta("_original_crit_damage", weapon.crit_damage if "crit_damage" in weapon else 2.0)
	
	# Obtener valores originales
	var base_damage = weapon.get_meta("_original_damage", weapon.damage if "damage" in weapon else 0)
	var base_proj_speed = weapon.get_meta("_original_projectile_speed", weapon.projectile_speed if "projectile_speed" in weapon else 400.0)
	var base_proj_count = weapon.get_meta("_original_projectile_count", weapon.projectile_count if "projectile_count" in weapon else 1)
	var base_knockback = weapon.get_meta("_original_knockback", weapon.knockback_force if "knockback_force" in weapon else 100.0)
	var base_pierce = weapon.get_meta("_original_pierce", weapon.pierce if "pierce" in weapon else 0)
	
	# Aplicar multiplicadores globales
	# FÓRMULA CORRECTA: (base + flat) * mult
	if "damage" in weapon:
		var damage_flat = gs.get("damage_flat", 0)
		var damage_mult = gs.get("damage_mult", 1.0)
		weapon.damage = int((base_damage + damage_flat) * damage_mult)
	if "projectile_speed" in weapon:
		weapon.projectile_speed = base_proj_speed * gs.get("projectile_speed_mult", 1.0)
	if "projectile_count" in weapon:
		weapon.projectile_count = base_proj_count + int(gs.get("extra_projectiles", 0))
	if "knockback_force" in weapon:
		weapon.knockback_force = base_knockback * gs.get("knockback_mult", 1.0)
	if "pierce" in weapon:
		weapon.pierce = base_pierce + int(gs.get("extra_pierce", 0))
	# Aplicar críticos globales
	if "crit_chance" in weapon:
		weapon.crit_chance = gs.get("crit_chance", 0.05)
	if "crit_damage" in weapon:
		weapon.crit_damage = gs.get("crit_damage", 2.0)

func _restore_legacy_weapon_base_stats(weapon) -> void:
	"""Restaurar valores base del arma legacy después de disparar"""
	if weapon.has_meta("_original_damage") and "damage" in weapon:
		weapon.damage = weapon.get_meta("_original_damage")
	if weapon.has_meta("_original_projectile_speed") and "projectile_speed" in weapon:
		weapon.projectile_speed = weapon.get_meta("_original_projectile_speed")
	if weapon.has_meta("_original_projectile_count") and "projectile_count" in weapon:
		weapon.projectile_count = weapon.get_meta("_original_projectile_count")
	if weapon.has_meta("_original_knockback") and "knockback_force" in weapon:
		weapon.knockback_force = weapon.get_meta("_original_knockback")

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

	# Limpiar OrbitalManager del jugador si existe
	if player:
		var orbital_manager = player.get_node_or_null("OrbitalManager")
		if orbital_manager:
			orbital_manager.queue_free()
			# Debug desactivado: print("[AttackManager] OrbitalManager eliminado")

	# Debug desactivado: print("[AttackManager] Todas las armas removidas")

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
	if stat_name == "cooldown_mult":
		stat_name = "attack_speed_mult"
		# Invertir: cooldown 0.8 = attack_speed 1.25
		value = 1.0 / value if value > 0 else 1.0
	
	if global_weapon_stats:
		global_weapon_stats.set_stat(stat_name, value)
	else:
		_legacy_player_stats[stat_name] = value
	# Debug desactivado: print("[AttackManager] Stat actualizado: %s = %.2f" % [stat_name, value])

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
	# Debug desactivado: print("[AttackManager] Stat modificado: %s += %.2f" % [stat_name, delta])

func get_player_stat(stat_name: String) -> float:
	"""Obtener stat del jugador"""
	# Convertir cooldown_mult a attack_speed_mult
	if stat_name == "cooldown_mult":
		var attack_speed = get_global_stat("attack_speed_mult")
		# Devolver como cooldown_mult para compatibilidad
		return 1.0 / attack_speed if attack_speed > 0 else 1.0
	
	# Primero buscar en GlobalWeaponStats
	var value = get_global_stat(stat_name)
	
	# Si es 0 o no existe, buscar en PlayerStats (nodo del juego)
	# Esto es necesario para stats como life_steal que están en PlayerStats
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
	"""
	if weapon == null:
		return {}
	
	var weapon_id = _get_weapon_id(weapon)
	var gs = _get_combined_global_stats()
	var ws = weapon_stats_map.get(weapon_id, null)
	
	# Obtener valores base del arma
	var base_damage = weapon.damage if "damage" in weapon else 0
	var base_cooldown = 1.0
	if weapon is BaseWeapon:
		base_cooldown = weapon.cooldown
	elif "base_cooldown" in weapon:
		base_cooldown = weapon.base_cooldown
	elif "cooldown" in weapon:
		base_cooldown = weapon.cooldown
	
	var base_attack_speed = 1.0 / base_cooldown if base_cooldown > 0 else 1.0
	var base_projectile_speed = weapon.projectile_speed if "projectile_speed" in weapon else 400.0
	var base_projectile_count = weapon.projectile_count if "projectile_count" in weapon else 1
	var base_pierce = weapon.pierce if "pierce" in weapon else 0
	var base_area = weapon.area if "area" in weapon else 1.0
	var base_range = weapon.attack_range if "attack_range" in weapon else (weapon.weapon_range if "weapon_range" in weapon else 500.0)
	var base_knockback = weapon.knockback_force if "knockback_force" in weapon else (weapon.knockback if "knockback" in weapon else 100.0)
	var base_duration = weapon.duration if "duration" in weapon else 1.0
	
	# Obtener multiplicadores globales
	var damage_mult = gs.get("damage_mult", 1.0)
	var attack_speed_mult = gs.get("attack_speed_mult", 1.0)
	var projectile_speed_mult = gs.get("projectile_speed_mult", 1.0)
	var area_mult = gs.get("area_mult", 1.0)
	var range_mult = gs.get("range_mult", 1.0)
	var knockback_mult = gs.get("knockback_mult", 1.0)
	var duration_mult = gs.get("duration_mult", 1.0)
	var extra_projectiles = gs.get("extra_projectiles", 0)
	var extra_pierce = gs.get("extra_pierce", 0)
	var crit_chance = gs.get("crit_chance", 0.05)
	var crit_damage = gs.get("crit_damage", 2.0)
	
	# Calcular valores finales
	# FÓRMULA CORRECTA: (base + flat) * mult
	var damage_flat = gs.get("damage_flat", 0)
	var final_damage = (base_damage + damage_flat) * damage_mult
	var final_attack_speed = base_attack_speed * attack_speed_mult
	var final_cooldown = 1.0 / final_attack_speed if final_attack_speed > 0 else 1.0
	var final_projectile_speed = base_projectile_speed * projectile_speed_mult
	var final_projectile_count = base_projectile_count + extra_projectiles
	var final_pierce = base_pierce + extra_pierce
	var final_area = base_area * area_mult
	var final_range = base_range * range_mult
	var final_knockback = base_knockback * knockback_mult
	var final_duration = base_duration * duration_mult
	
	# Si tiene WeaponStats, usar esos valores más precisos
	if ws:
		# Verificar que WeaponStats tenga los stats base correctos
		# (puede estar desincronizado si se creó antes de inicializar el arma)
		var needs_recalc = false
		
		# Sincronizar daño
		var ws_base_damage = ws.base_stats.get("damage", 0)
		if ws_base_damage != base_damage and base_damage > 0:
			ws.base_stats["damage"] = base_damage
			needs_recalc = true
		
		# Sincronizar attack_speed
		var ws_base_as = ws.base_stats.get("attack_speed", 1.0)
		if abs(ws_base_as - base_attack_speed) > 0.01 and base_attack_speed > 0:
			ws.base_stats["attack_speed"] = base_attack_speed
			needs_recalc = true
		
		# Sincronizar otros stats importantes
		if ws.base_stats.get("projectile_count", 1) != base_projectile_count:
			ws.base_stats["projectile_count"] = base_projectile_count
			needs_recalc = true
		
		if ws.base_stats.get("pierce", 0) != base_pierce:
			ws.base_stats["pierce"] = base_pierce
			needs_recalc = true
		
		if needs_recalc:
			ws._recalculate_stats()
		
		final_damage = ws.get_final_stat("damage", gs)
		final_attack_speed = ws.get_final_attack_speed(gs)
		final_cooldown = ws.get_final_cooldown(gs)
		final_projectile_count = ws.get_final_projectile_count(gs)
		final_pierce = ws.get_final_pierce(gs)
	
	return {
		# Identificadores
		"weapon_id": weapon_id,
		"weapon_name": weapon.weapon_name if "weapon_name" in weapon else _get_weapon_name(weapon),
		"weapon_name_es": weapon.weapon_name_es if "weapon_name_es" in weapon else _get_weapon_name(weapon),
		"element": weapon.element if "element" in weapon else (weapon.element_type if "element_type" in weapon else "physical"),
		"icon": weapon.icon if "icon" in weapon else "🔮",
		"level": weapon.level if "level" in weapon else 1,
		"max_level": weapon.max_level if "max_level" in weapon else 8,
		
		# Daño
		"damage_base": base_damage,
		"damage_final": int(final_damage),
		"damage_mult": damage_mult,
		
		# Velocidad de ataque
		"attack_speed_base": base_attack_speed,
		"attack_speed_final": final_attack_speed,
		"attack_speed_mult": attack_speed_mult,
		"cooldown_base": base_cooldown,
		"cooldown_final": final_cooldown,
		
		# Proyectiles
		"projectile_count_base": base_projectile_count,
		"projectile_count_final": final_projectile_count,
		"extra_projectiles": extra_projectiles,
		
		# Velocidad de proyectil
		"projectile_speed_base": base_projectile_speed,
		"projectile_speed_final": final_projectile_speed,
		"projectile_speed_mult": projectile_speed_mult,
		
		# Penetración
		"pierce_base": base_pierce,
		"pierce_final": final_pierce,
		"extra_pierce": extra_pierce,
		
		# Área
		"area_base": base_area,
		"area_final": final_area,
		"area_mult": area_mult,
		
		# Alcance
		"range_base": base_range,
		"range_final": final_range,
		"range_mult": range_mult,
		
		# Empuje
		"knockback_base": base_knockback,
		"knockback_final": final_knockback,
		"knockback_mult": knockback_mult,
		
		# Duración
		"duration_base": base_duration,
		"duration_final": final_duration,
		"duration_mult": duration_mult,
		
		# Críticos (globales)
		"crit_chance": crit_chance,
		"crit_damage": crit_damage,
		
		# Mejoras aplicadas
		"has_weapon_stats": ws != null,
		"applied_upgrades": ws.get_upgrades() if ws else [],
		"global_upgrades": global_weapon_stats.applied_upgrades if global_weapon_stats else []
	}

func get_info() -> Dictionary:
	"""Obtener información del atacante para UI"""
	var weapon_infos = []
	var global_stats = _get_combined_global_stats()
	
	for weapon in weapons:
		var weapon_id = _get_weapon_id(weapon)
		var ws = weapon_stats_map.get(weapon_id, null)
		
		if weapon is BaseWeapon:
			# Calcular stats finales con mejoras globales
			var base_damage = weapon.damage
			var base_cooldown = weapon.cooldown
			var base_attack_speed = 1.0 / base_cooldown if base_cooldown > 0 else 1.0
			
			# Aplicar mejoras globales - FÓRMULA: (base + flat) * mult
			var damage_flat = global_stats.get("damage_flat", 0)
			var final_damage = (base_damage + damage_flat) * global_stats.get("damage_mult", 1.0)
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
				"has_specific_upgrades": ws != null and ws.get_upgrades().size() > 0,
				"specific_upgrades": ws.get_upgrades() if ws else []
			})
		else:
			pass  # Bloque else
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

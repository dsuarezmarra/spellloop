# BaseWeapon.gd
# Clase base para todas las armas del juego
# Maneja stats, niveles, cooldowns y efectos

class_name BaseWeapon
extends RefCounted

# ═══════════════════════════════════════════════════════════════════════════════
# SEÑALES
# ═══════════════════════════════════════════════════════════════════════════════

signal weapon_leveled_up(weapon_id: String, new_level: int)
signal weapon_fired(weapon_id: String, position: Vector2, target: Node2D)
signal effect_applied(target: Node2D, effect: String, value: float)

# ═══════════════════════════════════════════════════════════════════════════════
# PROPIEDADES
# ═══════════════════════════════════════════════════════════════════════════════

var id: String = ""
var weapon_name: String = ""
var weapon_name_es: String = ""
var description: String = ""
var icon: String = ""

# Sistema de niveles
var level: int = 1
var max_level: int = WeaponDatabase.MAX_WEAPON_LEVEL

# Estado de fusión
var is_fused: bool = false
var fusion_components: Array = []

# Stats base (los que vienen de WeaponDatabase)
var base_stats: Dictionary = {}

# Stats actuales (modificados por nivel y player)
var damage: float = 0.0
var cooldown: float = 1.0
var weapon_range: float = 300.0
var projectile_speed: float = 300.0
var projectile_count: int = 1
var pierce: int = 0
var area: float = 1.0
var duration: float = 0.0
var knockback: float = 0.0

# Elemento y tipo
var element: int = WeaponDatabase.Element.ARCANE
var target_type: int = WeaponDatabase.TargetType.NEAREST
var projectile_type: int = WeaponDatabase.ProjectileType.SINGLE
var color: Color = Color.WHITE

# Efectos especiales
var effect: String = "none"
var effect_value: float = 0.0
var effect_duration: float = 0.0

# Cooldown tracking
var current_cooldown: float = 0.0
var ready_to_fire: bool = true

# ═══════════════════════════════════════════════════════════════════════════════
# INICIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func _init(weapon_id: String = "", from_fusion: bool = false) -> void:
	if weapon_id.is_empty():
		return
	
	var data = WeaponDatabase.get_weapon_data(weapon_id)
	if data.is_empty():
		push_error("[BaseWeapon] No se encontraron datos para: %s" % weapon_id)
		return
	
	_initialize_from_data(data)
	is_fused = from_fusion
	
	if is_fused and data.has("components"):
		fusion_components = data.components.duplicate()

func _initialize_from_data(data: Dictionary) -> void:
	"""Inicializar el arma con datos del diccionario"""
	id = data.get("id", "")
	weapon_name = data.get("name", "Unknown")
	weapon_name_es = data.get("name_es", weapon_name)
	description = data.get("description", "")
	icon = data.get("icon", "🔮")
	
	# Guardar stats base
	base_stats = {
		"damage": data.get("damage", 10),
		"cooldown": data.get("cooldown", 1.0),
		"range": data.get("range", 300.0),
		"projectile_speed": data.get("projectile_speed", 300.0),
		"projectile_count": data.get("projectile_count", 1),
		"pierce": data.get("pierce", 0),
		"area": data.get("area", 1.0),
		"duration": data.get("duration", 0.0),
		"knockback": data.get("knockback", 50.0),
	}
	
	# Aplicar stats base
	_apply_base_stats()
	
	# Elemento y tipo
	element = data.get("element", WeaponDatabase.Element.ARCANE)
	target_type = data.get("target_type", WeaponDatabase.TargetType.NEAREST)
	projectile_type = data.get("projectile_type", WeaponDatabase.ProjectileType.SINGLE)
	color = data.get("color", Color.WHITE)
	
	# Efectos
	effect = data.get("effect", "none")
	effect_value = data.get("effect_value", 0.0)
	effect_duration = data.get("effect_duration", 0.0)

func _apply_base_stats() -> void:
	"""Aplicar stats base sin modificadores"""
	damage = base_stats.damage
	cooldown = base_stats.cooldown
	weapon_range = base_stats.range
	projectile_speed = base_stats.projectile_speed
	projectile_count = base_stats.projectile_count
	pierce = base_stats.pierce
	area = base_stats.area
	duration = base_stats.duration
	knockback = base_stats.knockback

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE NIVELES
# ═══════════════════════════════════════════════════════════════════════════════

func can_level_up() -> bool:
	"""Verificar si el arma puede subir de nivel"""
	return level < max_level

func level_up() -> bool:
	"""Subir de nivel el arma"""
	if not can_level_up():
		return false
	
	level += 1
	_recalculate_stats()
	weapon_leveled_up.emit(id, level)
	
	# print("[BaseWeapon] %s subió a nivel %d" % [weapon_name, level])
	return true

func _recalculate_stats() -> void:
	"""Recalcular todos los stats basados en el nivel actual"""
	# Empezar desde base
	_apply_base_stats()
	
	# Aplicar mejoras de nivel acumulativas
	for lvl in range(2, level + 1):
		var upgrade = WeaponDatabase.get_level_upgrade(lvl)
		if upgrade.is_empty():
			continue
		
		if upgrade.has("damage_mult"):
			damage *= upgrade.damage_mult
		
		if upgrade.has("cooldown_mult"):
			cooldown *= upgrade.cooldown_mult
		
		if upgrade.has("projectile_count_add"):
			projectile_count += upgrade.projectile_count_add
		
		if upgrade.has("pierce_add"):
			pierce += upgrade.pierce_add
		
		if upgrade.has("effect_mult"):
			effect_value *= upgrade.effect_mult
		
		if upgrade.has("all_mult"):
			damage *= upgrade.all_mult
			knockback *= upgrade.all_mult
			area *= upgrade.all_mult
			effect_value *= upgrade.all_mult

func get_level_progress() -> float:
	"""Obtener progreso hacia el siguiente nivel (0.0 - 1.0)"""
	return float(level) / float(max_level)

func get_next_upgrade_description() -> String:
	"""Obtener descripción de la siguiente mejora"""
	if not can_level_up():
		return "¡NIVEL MÁXIMO!"
	
	var upgrade = WeaponDatabase.get_level_upgrade(level + 1)
	return upgrade.get("description", "Mejora desconocida")

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE COOLDOWN
# ═══════════════════════════════════════════════════════════════════════════════

func tick_cooldown(delta: float) -> void:
	"""Actualizar cooldown cada frame"""
	if ready_to_fire:
		return
	
	current_cooldown -= delta
	if current_cooldown <= 0.0:
		current_cooldown = 0.0
		ready_to_fire = true

func is_ready_to_fire() -> bool:
	"""Verificar si el arma está lista para disparar"""
	return ready_to_fire

func start_cooldown() -> void:
	"""Iniciar el cooldown después de disparar"""
	current_cooldown = cooldown
	ready_to_fire = false

func get_cooldown_progress() -> float:
	"""Obtener progreso del cooldown (0.0 = recién disparó, 1.0 = listo)"""
	if ready_to_fire:
		return 1.0
	if cooldown <= 0:
		return 1.0
	return 1.0 - (current_cooldown / cooldown)

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE ATAQUE
# ═══════════════════════════════════════════════════════════════════════════════

func perform_attack(player: Node2D, player_stats: Dictionary = {}) -> void:
	"""
	Ejecutar ataque del arma
	Override en subclases para comportamiento específico
	"""
	if not is_ready_to_fire():
		return
	
	var targets = _find_targets(player)
	
	# Verificar si necesita targets
	# AOE y ORBIT no necesitan targets para disparar
	var needs_target = target_type != WeaponDatabase.TargetType.AREA \
		and target_type != WeaponDatabase.TargetType.ORBIT \
		and projectile_type != WeaponDatabase.ProjectileType.AOE \
		and projectile_type != WeaponDatabase.ProjectileType.ORBIT
	
	if targets.is_empty() and needs_target:
		return  # No hay objetivos y el arma necesita uno
	
	# Aplicar modificadores del jugador
	var modified_damage = damage
	var modified_crit = 0.0
	
	if not player_stats.is_empty():
		modified_damage *= player_stats.get("damage_mult", 1.0)
		modified_crit = player_stats.get("crit_chance", 0.0)
		
		# Agregar crit del efecto del arma
		if effect == "crit_chance":
			modified_crit += effect_value
	
	# Log de disparo
	# var target_info = "posición player" if targets.is_empty() else str(targets[0].global_position)
	# print("[%s] ⚡ Disparando (%s) → %s" % [weapon_name, WeaponDatabase.ProjectileType.keys()[projectile_type], target_info])
	
	# Crear proyectil(es) según el tipo
	_spawn_projectiles(player, targets, modified_damage, modified_crit)
	
	start_cooldown()
	weapon_fired.emit(id, player.global_position, targets[0] if not targets.is_empty() else null)

func _find_targets(player: Node2D) -> Array:
	"""
	Encontrar objetivos según el tipo de targeting
	Override si se necesita lógica especial
	"""
	var enemies = _get_enemies_in_range(player)
	
	match target_type:
		WeaponDatabase.TargetType.NEAREST:
			if enemies.is_empty():
				return []
			enemies.sort_custom(_sort_by_distance.bind(player))
			return [enemies[0]]
		
		WeaponDatabase.TargetType.RANDOM:
			if enemies.is_empty():
				return []
			enemies.shuffle()
			return [enemies[0]]
		
		WeaponDatabase.TargetType.AREA:
			return enemies  # Todos en área
		
		WeaponDatabase.TargetType.ORBIT:
			return []  # No necesita target
		
		WeaponDatabase.TargetType.DIRECTION:
			# Dirección del movimiento del player
			return enemies if not enemies.is_empty() else []
		
		WeaponDatabase.TargetType.HOMING:
			return enemies  # Todos como potenciales
		
		_:
			return enemies

func _get_enemies_in_range(player: Node2D) -> Array:
	"""Obtener enemigos dentro del rango del arma"""
	var enemies = []
	
	# Verificar que el árbol de escena existe
	if not player or not player.get_tree():
		return enemies
	
	# Obtener range_mult de GlobalWeaponStats (buscar por grupo)
	var range_mult = 1.0
	var gws_nodes = player.get_tree().get_nodes_in_group("global_weapon_stats")
	var gws = gws_nodes[0] if gws_nodes.size() > 0 else null
	if gws and gws.has_method("get_stat"):
		range_mult = gws.get_stat("range_mult")
	var effective_range = weapon_range * range_mult
	
	var enemy_group = player.get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemy_group:
		if not is_instance_valid(enemy):
			continue
		
		var dist = player.global_position.distance_to(enemy.global_position)
		if dist <= effective_range:
			enemies.append(enemy)
	
	return enemies

func _sort_by_distance(a: Node2D, b: Node2D, player: Node2D) -> bool:
	"""Comparador para ordenar por distancia"""
	var dist_a = player.global_position.distance_squared_to(a.global_position)
	var dist_b = player.global_position.distance_squared_to(b.global_position)
	return dist_a < dist_b

func _spawn_projectiles(player: Node2D, targets: Array, final_damage: float, crit_chance: float) -> void:
	"""
	Crear proyectiles del arma
	Override para comportamiento específico de cada tipo
	"""
	match projectile_type:
		WeaponDatabase.ProjectileType.SINGLE:
			_spawn_single_projectile(player, targets, final_damage, crit_chance)
		
		WeaponDatabase.ProjectileType.MULTI:
			_spawn_multi_projectiles(player, targets, final_damage, crit_chance)
		
		WeaponDatabase.ProjectileType.BEAM:
			_spawn_beam(player, targets, final_damage, crit_chance)
		
		WeaponDatabase.ProjectileType.AOE:
			_spawn_aoe(player, targets, final_damage, crit_chance)
		
		WeaponDatabase.ProjectileType.ORBIT:
			_spawn_orbit(player, final_damage, crit_chance)
		
		WeaponDatabase.ProjectileType.CHAIN:
			_spawn_chain(player, targets, final_damage, crit_chance)

func _spawn_single_projectile(player: Node2D, targets: Array, dmg: float, crit: float) -> void:
	"""Crear un solo proyectil"""
	if targets.is_empty():
		return
	
	var target = targets[0]
	var direction = (target.global_position - player.global_position).normalized()
	
	_create_projectile(player, direction, dmg, crit)

func _spawn_multi_projectiles(player: Node2D, targets: Array, dmg: float, crit: float) -> void:
	"""Crear múltiples proyectiles en abanico o hacia múltiples objetivos"""
	var count = projectile_count
	
	# Si hay menos objetivos que proyectiles, disparar en abanico
	if targets.size() < count:
		var base_direction: Vector2
		
		if targets.is_empty():
			# Usar dirección del movimiento del player
			base_direction = player.velocity.normalized() if player.velocity.length() > 0 else Vector2.RIGHT
		else:
			base_direction = (targets[0].global_position - player.global_position).normalized()
		
		var spread_angle = deg_to_rad(15.0)  # 15 grados entre cada proyectil
		var start_angle = -spread_angle * (count - 1) / 2.0
		
		for i in range(count):
			var angle = start_angle + spread_angle * i
			var direction = base_direction.rotated(angle)
			_create_projectile(player, direction, dmg, crit)
	else:
		# Disparar a múltiples objetivos
		for i in range(min(count, targets.size())):
			var direction = (targets[i].global_position - player.global_position).normalized()
			_create_projectile(player, direction, dmg, crit)

func _spawn_beam(player: Node2D, targets: Array, dmg: float, crit: float) -> void:
	"""Crear un rayo instantáneo"""
	if targets.is_empty():
		return
	
	var target = targets[0]
	var direction = (target.global_position - player.global_position).normalized()
	
	# El beam daña instantáneamente en una línea
	_create_beam(player, direction, dmg, crit)

func _spawn_aoe(player: Node2D, targets: Array, dmg: float, crit: float) -> void:
	"""Crear área de efecto"""
	var spawn_position = player.global_position
	
	# Si hay target, centrar AOE en el target (para Earth Spike, etc.)
	if not targets.is_empty() and target_type == WeaponDatabase.TargetType.RANDOM:
		spawn_position = targets[randi() % targets.size()].global_position
	
	_create_aoe(player, spawn_position, dmg, crit)

func _spawn_orbit(player: Node2D, dmg: float, crit: float) -> void:
	"""Crear proyectiles orbitantes"""
	# Los orbitales son persistentes, verificar si ya existen
	_create_orbitals(player, dmg, crit)

func _spawn_chain(player: Node2D, targets: Array, dmg: float, crit: float) -> void:
	"""Crear proyectil que encadena entre enemigos"""
	if targets.is_empty():
		return
	
	_create_chain_projectile(player, targets[0], dmg, crit)

# ═══════════════════════════════════════════════════════════════════════════════
# CREACIÓN DE PROYECTILES (para override en subclases o usar ProjectileFactory)
# ═══════════════════════════════════════════════════════════════════════════════

func _create_projectile(player: Node2D, direction: Vector2, dmg: float, crit: float) -> void:
	"""Crear proyectil básico - usar ProjectileFactory"""
	var projectile_data = _build_projectile_data(dmg, crit)
	projectile_data["direction"] = direction
	projectile_data["start_position"] = player.global_position
	
	# DEBUG: Verificar que los datos de efecto se pasan
	# if projectile_data.get("effect", "none") != "none":
	# 	print("[BaseWeapon] 📤 Creando proyectil para %s - effect: %s, val: %.2f, dur: %.2f" % [
	# 		id, projectile_data.effect, projectile_data.effect_value, projectile_data.effect_duration
	# 	])
	
	# Emitir para que el AttackManager maneje la creación
	ProjectileFactory.create_projectile(player, projectile_data)

func _create_beam(player: Node2D, direction: Vector2, dmg: float, crit: float) -> void:
	"""Crear rayo - usar ProjectileFactory"""
	var beam_data = _build_projectile_data(dmg, crit)
	beam_data["direction"] = direction
	beam_data["start_position"] = player.global_position
	beam_data["is_beam"] = true
	
	ProjectileFactory.create_beam(player, beam_data)

func _create_aoe(player: Node2D, position: Vector2, dmg: float, crit: float) -> void:
	"""Crear AOE - usar ProjectileFactory"""
	var aoe_data = _build_projectile_data(dmg, crit)
	aoe_data["position"] = position
	aoe_data["is_aoe"] = true
	
	ProjectileFactory.create_aoe(player, aoe_data)

func _create_orbitals(player: Node2D, dmg: float, crit: float) -> void:
	"""Crear orbitales - usar ProjectileFactory"""
	var orbital_data = _build_projectile_data(dmg, crit)
	orbital_data["orbital_count"] = projectile_count
	orbital_data["orbital_radius"] = weapon_range
	orbital_data["is_orbital"] = true
	
	ProjectileFactory.create_orbitals(player, orbital_data)

func _create_chain_projectile(player: Node2D, first_target: Node2D, dmg: float, crit: float) -> void:
	"""Crear proyectil encadenante - usar ProjectileFactory"""
	var chain_data = _build_projectile_data(dmg, crit)
	chain_data["first_target"] = first_target
	chain_data["chain_count"] = int(effect_value) if effect == "chain" else 2
	chain_data["is_chain"] = true
	
	ProjectileFactory.create_chain_projectile(player, chain_data)

func _build_projectile_data(dmg: float, crit: float) -> Dictionary:
	"""Construir datos base para proyectiles"""
	# Obtener crit_damage de GlobalWeaponStats (buscar por grupo)
	var crit_dmg = 2.0
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		var gws_nodes = tree.get_nodes_in_group("global_weapon_stats")
		var gws = gws_nodes[0] if gws_nodes.size() > 0 else null
		if gws and gws.has_method("get_crit_damage"):
			crit_dmg = gws.get_crit_damage()
	
	return {
		"weapon_id": id,
		"damage": dmg,
		"crit_chance": crit,
		"crit_damage": crit_dmg,  # Añadido multiplicador de crítico
		"speed": projectile_speed,
		"pierce": pierce,
		"range": weapon_range,
		"area": area,
		"duration": duration,
		"knockback": knockback,
		"element": element,
		"color": color,
		"effect": effect,
		"effect_value": effect_value,
		"effect_duration": effect_duration
	}

# ═══════════════════════════════════════════════════════════════════════════════
# APLICACIÓN DE EFECTOS
# ═══════════════════════════════════════════════════════════════════════════════

func apply_effect_to_target(target: Node2D) -> void:
	"""Aplicar efecto especial del arma al objetivo"""
	if effect == "none" or not is_instance_valid(target):
		return
	
	match effect:
		"slow":
			_apply_slow(target)
		"burn":
			_apply_burn(target)
		"freeze":
			_apply_freeze(target)
		"stun":
			_apply_stun(target)
		"pull":
			_apply_pull(target)
		"blind":
			_apply_blind(target)
		"steam":
			_apply_steam(target)
		"freeze_chain":
			_apply_freeze(target)
			# El chain se maneja en el proyectil
		"burn_chain":
			_apply_burn(target)
			# El chain se maneja en el proyectil
		"lifesteal":
			pass  # Se maneja al hacer daño
		"lifesteal_chain":
			pass  # Se maneja al hacer daño
		"execute":
			_apply_execute(target)
		"knockback_bonus":
			pass  # Se aplica automáticamente al knockback
		"crit_chance":
			pass  # Se aplica automáticamente al daño
		"chain":
			pass  # Se maneja en el proyectil
		"bleed":
			_apply_bleed(target)
		"shadow_mark":
			_apply_shadow_mark(target)
	
	effect_applied.emit(target, effect, effect_value)

func _apply_slow(target: Node2D) -> void:
	"""Aplicar slow al objetivo"""
	if target.has_method("apply_slow"):
		target.apply_slow(effect_value, effect_duration)

func _apply_burn(target: Node2D) -> void:
	"""Aplicar burn (DoT) al objetivo"""
	if target.has_method("apply_burn"):
		target.apply_burn(effect_value, effect_duration)

func _apply_freeze(target: Node2D) -> void:
	"""Aplicar freeze (slow extremo) al objetivo"""
	if target.has_method("apply_freeze"):
		target.apply_freeze(effect_value, effect_duration)
	elif target.has_method("apply_slow"):
		# Fallback a slow si no hay método freeze
		target.apply_slow(effect_value, effect_duration)

func _apply_stun(target: Node2D) -> void:
	"""Aplicar stun al objetivo"""
	if target.has_method("apply_stun"):
		target.apply_stun(effect_duration)

func _apply_pull(target: Node2D, pull_position: Vector2 = Vector2.ZERO) -> void:
	"""Atraer objetivo hacia una posición (por defecto el jugador)"""
	var target_pos = pull_position
	if target_pos == Vector2.ZERO:
		var player = _get_player()
		if player:
			target_pos = player.global_position
		else:
			return
	if target.has_method("apply_pull"):
		target.apply_pull(target_pos, effect_value, effect_duration)

func _apply_blind(target: Node2D) -> void:
	"""Aplicar ceguera al objetivo"""
	if target.has_method("apply_blind"):
		target.apply_blind(effect_duration)

func _apply_steam(target: Node2D) -> void:
	"""Aplicar efecto de vapor (slow + burn combinados)"""
	# Slow moderado
	if target.has_method("apply_slow"):
		target.apply_slow(0.3, effect_duration)  # 30% slow
	# Burn con el valor del efecto
	if target.has_method("apply_burn"):
		target.apply_burn(effect_value, effect_duration)

func _apply_execute(target: Node2D) -> void:
	"""Ejecutar al objetivo si tiene poca vida"""
	if not target.has_method("get_info"):
		return
	
	var info = target.get_info()
	var hp = info.get("hp", 100)
	var max_hp = info.get("max_hp", 100)
	var hp_percent = float(hp) / float(max_hp)
	
	# effect_value es el umbral (ej: 0.2 = 20% HP)
	if hp_percent <= effect_value:
		if target.has_method("take_damage"):
			target.take_damage(hp)  # Daño letal
			# print("[BaseWeapon] ⚔️ EXECUTE! Enemigo eliminado (%.0f%% HP)" % [hp_percent * 100])

func _apply_bleed(target: Node2D) -> void:
	"""Aplicar sangrado al objetivo (DoT)"""
	if target.has_method("apply_bleed"):
		target.apply_bleed(effect_value, effect_duration)

func _apply_shadow_mark(target: Node2D) -> void:
	"""Aplicar marca de sombra al objetivo (daño extra)"""
	if target.has_method("apply_shadow_mark"):
		target.apply_shadow_mark(effect_value, effect_duration)

func _get_player() -> Node:
	"""Obtener referencia al jugador"""
	var tree = Engine.get_main_loop()
	if tree and tree is SceneTree:
		var players = tree.get_nodes_in_group("player")
		if players.size() > 0:
			return players[0]
	return null

# ═══════════════════════════════════════════════════════════════════════════════
# SERIALIZACIÓN
# ═══════════════════════════════════════════════════════════════════════════════

func to_dict() -> Dictionary:
	"""Serializar arma para guardado"""
	return {
		"id": id,
		"level": level,
		"is_fused": is_fused,
		"fusion_components": fusion_components.duplicate()
	}

static func from_dict(data: Dictionary) -> BaseWeapon:
	"""Deserializar arma desde datos guardados"""
	var weapon = BaseWeapon.new(data.get("id", ""), data.get("is_fused", false))
	
	# Aplicar nivel
	var target_level = data.get("level", 1)
	for i in range(target_level - 1):
		weapon.level_up()
	
	return weapon

# ═══════════════════════════════════════════════════════════════════════════════
# DEBUG
# ═══════════════════════════════════════════════════════════════════════════════

func get_debug_info() -> String:
	"""Obtener información de debug del arma"""
	return """
[%s] %s (Lv.%d%s)
  DMG: %.1f | CD: %.2fs | Range: %.0f
  Proyectiles: %d | Pierce: %d | Area: %.1f
  Efecto: %s (%.2f por %.1fs)
""" % [
		id, weapon_name, level, " [FUSED]" if is_fused else "",
		damage, cooldown, weapon_range,
		projectile_count, pierce, area,
		effect, effect_value, effect_duration
	]

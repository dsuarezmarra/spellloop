extends Node
class_name WeaponManager

"""
⚔️ GESTOR DE ARMAS - SPELLLOOP STYLE
==================================

Gestiona todas las armas del player:
- Auto-ataque hacia enemigos
- Varita mágica inicial
- Sistema de cooldowns
- Targeting automático
"""

signal weapon_fired(weapon_type: String, target_position: Vector2)
signal weapons_updated(weapons_list: Array)

# Script del proyectil mágico - se carga dinámicamente
var MagicProjectileScript: Script = null

# Referencias
var player: CharacterBody2D
var enemy_manager
var auto_fire_timer: Timer = null

# Armas equipadas
var equipped_weapons: Array[WeaponData] = []
var max_weapons: int = 6

func increase_weapon_cap(amount: int = 1, cap_limit: int = 8) -> bool:
	"""Increase max weapon capacity up to cap_limit. Returns true if changed."""
	var new_cap = min(cap_limit, max_weapons + amount)
	if new_cap != max_weapons:
		max_weapons = new_cap
		# print("⚔️ Weapon capacity increased to: ", max_weapons)
		return true
	return false

# Configuración de targeting
var auto_target_range: float = 400.0

func _ready():
	# Asegurar que WeaponManager respete la pausa del juego
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	# print("⚔️ WeaponManager inicializado")
	# Cargar script del proyectil mágico
	if ResourceLoader.exists("res://scripts/magic/SpellloopMagicProjectile.gd"):
		MagicProjectileScript = load("res://scripts/magic/SpellloopMagicProjectile.gd")
	# Create auto-fire timer to handle cooldown ticks
	if not auto_fire_timer:
		auto_fire_timer = Timer.new()
		auto_fire_timer.name = "AutoFireTimer"
		auto_fire_timer.wait_time = 0.1
		auto_fire_timer.one_shot = false
		auto_fire_timer.autostart = true
		add_child(auto_fire_timer)
		auto_fire_timer.timeout.connect(_on_auto_fire_tick)

func initialize(player_ref: CharacterBody2D):
	"""Inicializar sistema de armas"""
	player = player_ref
	
	# Equipar arma inicial (varita mágica)
	equip_initial_weapon()
	
	# print("🪄 Sistema de armas inicializado")
	# Start the auto-fire timer if present
	if auto_fire_timer and not auto_fire_timer.is_stopped():
		auto_fire_timer.start()

func equip_initial_weapon():
	"""Equipar solo varita de hielo inicial"""
	# Solo Ice Wand - el resto está desactivado para evitar spam de proyectiles
	var ice_wand = WeaponData.new()
	ice_wand.id = "ice_wand"
	ice_wand.name = "Ice Wand"
	ice_wand.damage = 8
	ice_wand.cooldown = 1.1
	ice_wand.weapon_range = 340.0
	ice_wand.projectile_speed = 280.0
	ice_wand.weapon_type = WeaponData.WeaponType.PROJECTILE
	ice_wand.targeting = WeaponData.TargetingType.NEAREST_ENEMY
	ice_wand.tags = ["ice"]
	equipped_weapons.append(ice_wand)
	weapons_updated.emit(get_weapons_info())
	# Las otras armas están desactivadas temporalmente

func set_enemy_manager(enemy_manager_ref):
	"""Establecer referencia al gestor de enemigos"""
	enemy_manager = enemy_manager_ref

func _process(delta):
	"""Actualizar armas (cooldowns y auto-ataque)"""
	if not player or equipped_weapons.is_empty():
		return
	
	# Actualizar cooldowns y disparar armas listas
	for weapon in equipped_weapons:
		update_weapon(weapon, delta)

func update_weapon(weapon: WeaponData, delta: float):
	"""Actualizar una arma específica"""
	# Reducir cooldown
	if weapon.current_cooldown > 0:
		weapon.current_cooldown = max(0.0, weapon.current_cooldown - delta)
		return
	# If ready, will be fired in the auto-fire tick

func find_target(weapon: WeaponData) -> Vector2:
	"""Encontrar objetivo para un arma"""
	if not enemy_manager:
		return Vector2.ZERO
	
	match weapon.targeting:
		WeaponData.TargetingType.NEAREST_ENEMY:
			return find_nearest_enemy(weapon.weapon_range)
		WeaponData.TargetingType.AREA_AROUND_PLAYER:
			return player.global_position
		WeaponData.TargetingType.RANDOM_ENEMY:
			return find_random_enemy(weapon.weapon_range)
		_:
			return Vector2.ZERO

func find_nearest_enemy(_range: float) -> Vector2:
	"""Encontrar enemigo más cercano en rango"""
	if not enemy_manager:
		return Vector2.ZERO
	
	var enemies = enemy_manager.get_enemies_in_range(player.global_position, _range)
	if enemies.is_empty():
		return Vector2.ZERO
	
	# Encontrar el más cercano
	var nearest_enemy = null
	var nearest_distance = INF
	
	for enemy in enemies:
		var distance = player.global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_enemy = enemy
	
	return nearest_enemy.global_position if nearest_enemy else Vector2.ZERO

func find_random_enemy(_range: float) -> Vector2:
	"""Encontrar enemigo aleatorio en rango"""
	if not enemy_manager:
		return Vector2.ZERO
	
	var enemies = enemy_manager.get_enemies_in_range(player.global_position, _range)
	if enemies.is_empty():
		return Vector2.ZERO
	
	var random_enemy = enemies[randi() % enemies.size()]
	return random_enemy.global_position

func fire_weapon(weapon: WeaponData, target_position: Vector2):
	"""Disparar un arma hacia el objetivo"""
	if target_position == Vector2.ZERO:
		return
	
	match weapon.weapon_type:
		WeaponData.WeaponType.PROJECTILE:
			fire_projectile(weapon, target_position)
		WeaponData.WeaponType.AREA_SPELL:
			fire_area_spell(weapon, target_position)
		WeaponData.WeaponType.BEAM:
			fire_beam(weapon, target_position)
	
	# Resetear cooldown
	weapon.current_cooldown = weapon.cooldown
	
	# Emitir señal
	weapon_fired.emit(weapon.id, target_position)

func fire_projectile(weapon: WeaponData, target_position: Vector2):
	"""Disparar proyectil usando la fábrica centralizada"""
	# Construir diccionario de datos para la fábrica
	var direction = (target_position - player.global_position).normalized()
	
	var data = {
		"start_position": player.global_position,
		"direction": direction,
		"damage": weapon.damage,
		"speed": weapon.projectile_speed,
		"range": weapon.weapon_range,
		"knockback": weapon.knockback,
		"pierce": weapon.pierce,
		"element": weapon.element,
		"weapon_id": weapon.id
	}
	
	# Añadir efectos si existen
	if "effect" in weapon:
		data["effect"] = weapon.effect
	if "effect_value" in weapon:
		data["effect_value"] = weapon.effect_value
	if "effect_duration" in weapon:
		data["effect_duration"] = weapon.effect_duration
	if "crit_chance" in weapon:
		data["crit_chance"] = weapon.crit_chance
		
	# Pasar color si existe
	if "color" in weapon:
		data["color"] = weapon.color
	
	# Usar ProjectileFactory para crear el proyectil correcto
	ProjectileFactory.create_projectile(player, data)


func fire_area_spell(weapon: WeaponData, _target_position: Vector2):
	"""Lanzar hechizo de área"""
	# Por ahora, crear múltiples proyectiles en área
	var num_projectiles = 5
	var angle_step = PI * 2 / num_projectiles
	
	for i in range(num_projectiles):
		var angle = i * angle_step
		var direction = Vector2(cos(angle), sin(angle))
		var spell_target = player.global_position + direction * 100
		
		fire_projectile(weapon, spell_target)

func fire_beam(_weapon: WeaponData, _target_position: Vector2):
	# Implementación futura: rayo láser
	pass

func add_weapon_by_id(weapon_id: String) -> bool:
	"""Crear y añadir arma por su ID (o mejorar si ya existe)"""
	# 1. Verificar si ya tenemos el arma (para mejorarla en lugar de duplicarla)
	var existing_weapon = _get_weapon_by_id(weapon_id)
	if existing_weapon:
		# Ya la tenemos, aplicamos mejora de nivel genérica
		print("⚔️ [WeaponManager] Arma ya existe: %s. Aplicando mejora..." % weapon_id)
		# TODO: Obtener mejora real de base de datos. Por ahora, level up genérico.
		var level_up_data = {"damage_mult": 1.1, "cooldown_reduction": 0.05} 
		
		# Intentar buscar mejora real si existe lógica disponible
		if ClassDB.class_exists("WeaponDatabase"):
			# Lógica simplificada: simular upgrade
			pass
			
		update_weapon_stats(existing_weapon, level_up_data)
		existing_weapon.level += 1
		weapons_updated.emit(get_weapons_info())
		return true

	if not WeaponDatabase.WEAPONS.has(weapon_id):
		push_error("Weapon ID not found: " + weapon_id)
		return false
		
	var data = WeaponDatabase.WEAPONS[weapon_id]
	var new_weapon = WeaponData.new()
	
	new_weapon.id = data["id"]
	new_weapon.name = data["name"]
	new_weapon.damage = data["damage"]
	new_weapon.cooldown = data["cooldown"]
	new_weapon.weapon_range = data["range"]
	new_weapon.projectile_speed = data["projectile_speed"]
	# Enums conversion
	new_weapon.weapon_type = int(data.get("projectile_type", WeaponData.WeaponType.PROJECTILE))
	new_weapon.targeting = int(data.get("target_type", WeaponData.TargetingType.NEAREST_ENEMY))
	new_weapon.tags = data.get("tags", [])
	new_weapon.evolution = data.get("evolution", "")
	
	return add_weapon(new_weapon)

func _get_weapon_by_id(weapon_id: String) -> WeaponData:
	for w in equipped_weapons:
		if w.id == weapon_id:
			return w
	return null

func update_weapon_stats(weapon: WeaponData, modifications: Dictionary) -> void:
	weapon.apply_upgrade(modifications)

func add_weapon(weapon_data: WeaponData) -> bool:
	"""Añadir nueva arma"""
	if equipped_weapons.size() >= max_weapons:
		return false
	
	equipped_weapons.append(weapon_data)
	# print("⚔️ Nueva arma equipada: ", weapon_data.name)
	weapons_updated.emit(get_weapons_info())
	return true

func _on_auto_fire_tick() -> void:
	# Called by auto_fire_timer at a steady tick (0.1s). We accumulate a small delta (0.1)
	var tick_dt = 0.1
	if not player or equipped_weapons.is_empty():
		return
	for weapon in equipped_weapons:
		# Reduce cooldown and if ready, find a target and fire
		if weapon.current_cooldown > 0.0:
			weapon.current_cooldown = max(0.0, weapon.current_cooldown - tick_dt)
			continue
		var target = find_target(weapon)
		if target and target != Vector2.ZERO:
			fire_weapon(weapon, target)
			# weapon.current_cooldown reset inside fire_weapon

func upgrade_weapon(weapon_id: String, upgrade_data: Dictionary) -> bool:
	"""Mejorar arma existente"""
	for weapon in equipped_weapons:
		if weapon.id == weapon_id:
			weapon.apply_upgrade(upgrade_data)
			# print("⬆️ Arma mejorada: ", weapon.name)
			weapons_updated.emit(get_weapons_info())
			return true
	return false

func get_weapon_count() -> int:
	"""Obtener número de armas equipadas"""
	return equipped_weapons.size()

func get_weapons_info() -> Array:
	"""Obtener información de todas las armas"""
	var info = []
	for weapon in equipped_weapons:
		info.append(weapon.get_info())
	return info

# Clase para datos de arma
class WeaponData:
	enum WeaponType {
		PROJECTILE,
		AREA_SPELL,
		BEAM,
		MELEE
	}
	
	enum TargetingType {
		NEAREST_ENEMY,
		AREA_AROUND_PLAYER,
		RANDOM_ENEMY,
		PLAYER_DIRECTION
	}
	
	var id: String
	var name: String
	var damage: int
	var cooldown: float
	var current_cooldown: float = 0.0
	var weapon_range: float
	var projectile_speed: float
	var weapon_type: WeaponType
	var targeting: TargetingType
	var level: int = 1
	var max_level: int = 8
	var tags: Array = []
	# Para evoluciones/uniones
	var evolution: String = ""
	var passive_required: String = ""

	func apply_upgrade(upgrade_data: Dictionary):
		"""Aplicar mejora al arma"""
		if upgrade_data.has("damage"):
			damage += upgrade_data.damage
		if upgrade_data.has("cooldown_reduction"):
			cooldown = max(0.1, cooldown - upgrade_data.cooldown_reduction)
		if upgrade_data.has("range"):
			weapon_range += upgrade_data["range"]
		level = min(max_level, level + 1)

	func get_info() -> Dictionary:
		"""Obtener información del arma"""
		return {
			"id": id,
			"name": name,
			"damage": damage,
			"cooldown": cooldown,
			"range": weapon_range,
			"level": level,
			"tags": tags,
			"evolution": evolution
		}


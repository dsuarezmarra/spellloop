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
		print("⚔️ Weapon capacity increased to: ", max_weapons)
		return true
	return false

# Configuración de targeting
var auto_target_range: float = 400.0

func _ready():
	print("⚔️ WeaponManager inicializado")
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
	
	print("🪄 Sistema de armas inicializado")
	# Start the auto-fire timer if present
	if auto_fire_timer and not auto_fire_timer.is_stopped():
		auto_fire_timer.start()

func equip_initial_weapon():
	"""Equipar varita mágica inicial"""
	# Ejemplo: Ice Wand
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

	# Fire Wand
	var fire_wand = WeaponData.new()
	fire_wand.id = "fire_wand"
	fire_wand.name = "Fire Wand"
	fire_wand.damage = 12
	fire_wand.cooldown = 1.3
	fire_wand.weapon_range = 400.0
	fire_wand.projectile_speed = 320.0
	fire_wand.weapon_type = WeaponData.WeaponType.PROJECTILE
	fire_wand.targeting = WeaponData.TargetingType.NEAREST_ENEMY
	fire_wand.tags = ["fire"]
	equipped_weapons.append(fire_wand)

	# Arcane Nova
	var arcane_nova = WeaponData.new()
	arcane_nova.id = "arcane_nova"
	arcane_nova.name = "Arcane Nova"
	arcane_nova.damage = 7
	arcane_nova.cooldown = 2.5
	arcane_nova.weapon_range = 0.0
	arcane_nova.projectile_speed = 0.0
	arcane_nova.weapon_type = WeaponData.WeaponType.AREA_SPELL
	arcane_nova.targeting = WeaponData.TargetingType.AREA_AROUND_PLAYER
	arcane_nova.tags = ["arcane"]
	equipped_weapons.append(arcane_nova)

	# Chain Spark
	var chain_spark = WeaponData.new()
	chain_spark.id = "chain_spark"
	chain_spark.name = "Chain Spark"
	chain_spark.damage = 10
	chain_spark.cooldown = 1.7
	chain_spark.weapon_range = 420.0
	chain_spark.projectile_speed = 400.0
	chain_spark.weapon_type = WeaponData.WeaponType.PROJECTILE
	chain_spark.targeting = WeaponData.TargetingType.RANDOM_ENEMY
	chain_spark.tags = ["lightning"]
	equipped_weapons.append(chain_spark)

	# Orbit Blades
	var orbit_blades = WeaponData.new()
	orbit_blades.id = "orbit_blades"
	orbit_blades.name = "Orbit Blades"
	orbit_blades.damage = 6
	orbit_blades.cooldown = 0.0
	orbit_blades.weapon_range = 120.0
	orbit_blades.projectile_speed = 0.0
	orbit_blades.weapon_type = WeaponData.WeaponType.MELEE
	orbit_blades.targeting = WeaponData.TargetingType.AREA_AROUND_PLAYER
	orbit_blades.tags = ["physical", "orbit"]
	equipped_weapons.append(orbit_blades)

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
	# Disparar proyectil mágico (placeholder)
	# Prefer instancing a projectile scene named after the weapon id
	var scene_path = "res://scenes/projectiles/%s.tscn" % weapon.id
	if ResourceLoader.exists(scene_path):
		var pscene = ResourceLoader.load(scene_path)
		if pscene and pscene is PackedScene:
			var instance = pscene.instantiate()
			if instance and instance.has_method("initialize"):
				instance.initialize(player.global_position, target_position, weapon.damage, weapon.projectile_speed)
				get_tree().current_scene.add_child(instance)
				return
	# Fallback to SpellloopMagicProjectile
	var projectile = null
	if Engine.has_singleton("SpellloopMagicProjectile"):
		# unlikely but try class_name
		pass
	# Generic fallback
	projectile = SpellloopMagicProjectile.new()
	projectile.initialize(player.global_position, target_position, weapon.damage, weapon.projectile_speed)
	get_tree().current_scene.add_child(projectile)


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

func add_weapon(weapon_data: WeaponData) -> bool:
	"""Añadir nueva arma"""
	if equipped_weapons.size() >= max_weapons:
		return false
	
	equipped_weapons.append(weapon_data)
	print("⚔️ Nueva arma equipada: ", weapon_data.name)
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
			print("⬆️ Arma mejorada: ", weapon.name)
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


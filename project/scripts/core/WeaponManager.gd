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
var enemy_manager: EnemyManager

# Armas equipadas
var equipped_weapons: Array[WeaponData] = []
var max_weapons: int = 6

# Configuración de targeting
var auto_target_range: float = 400.0

func _ready():
	print("⚔️ WeaponManager inicializado")

func initialize(player_ref: CharacterBody2D):
	"""Inicializar sistema de armas"""
	player = player_ref
	
	# Equipar arma inicial (varita mágica)
	equip_initial_weapon()
	
	print("🪄 Sistema de armas inicializado")

func equip_initial_weapon():
	"""Equipar varita mágica inicial"""
	var magic_wand = WeaponData.new()
	magic_wand.id = "magic_wand"
	magic_wand.name = "Varita Mágica"
	magic_wand.damage = 10
	magic_wand.cooldown = 1.0
	magic_wand.range = 350.0
	magic_wand.projectile_speed = 300.0
	magic_wand.weapon_type = WeaponData.WeaponType.PROJECTILE
	magic_wand.targeting = WeaponData.TargetingType.NEAREST_ENEMY
	
	equipped_weapons.append(magic_wand)
	
	print("🪄 Varita Mágica equipada")

func set_enemy_manager(enemy_manager_ref: EnemyManager):
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
		weapon.current_cooldown -= delta
		return
	
	# Si el arma está lista, buscar objetivo y disparar
	var target = find_target(weapon)
	if target:
		fire_weapon(weapon, target)

func find_target(weapon: WeaponData) -> Vector2:
	"""Encontrar objetivo para un arma"""
	if not enemy_manager:
		return Vector2.ZERO
	
	match weapon.targeting:
		WeaponData.TargetingType.NEAREST_ENEMY:
			return find_nearest_enemy(weapon.range)
		WeaponData.TargetingType.AREA_AROUND_PLAYER:
			return player.global_position
		WeaponData.TargetingType.RANDOM_ENEMY:
			return find_random_enemy(weapon.range)
		_:
			return Vector2.ZERO

func find_nearest_enemy(range: float) -> Vector2:
	"""Encontrar enemigo más cercano en rango"""
	if not enemy_manager:
		return Vector2.ZERO
	
	var enemies = enemy_manager.get_enemies_in_range(player.global_position, range)
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

func find_random_enemy(range: float) -> Vector2:
	"""Encontrar enemigo aleatorio en rango"""
	if not enemy_manager:
		return Vector2.ZERO
	
	var enemies = enemy_manager.get_enemies_in_range(player.global_position, range)
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
	"""Disparar proyectil mágico"""
	var projectile = SpellloopMagicProjectile.new()
	projectile.initialize(
		player.global_position,
		target_position,
		weapon.damage,
		weapon.projectile_speed
	)
	
	# Añadir al árbol de escena
	get_tree().current_scene.add_child(projectile)
	
	print("🔮 Proyectil mágico disparado hacia: ", target_position)

func fire_area_spell(weapon: WeaponData, target_position: Vector2):
	"""Lanzar hechizo de área"""
	# Por ahora, crear múltiples proyectiles en área
	var num_projectiles = 5
	var angle_step = PI * 2 / num_projectiles
	
	for i in range(num_projectiles):
		var angle = i * angle_step
		var direction = Vector2(cos(angle), sin(angle))
		var spell_target = player.global_position + direction * 100
		
		fire_projectile(weapon, spell_target)

func fire_beam(weapon: WeaponData, target_position: Vector2):
	"""Disparar rayo láser"""
	# Implementación futura
	print("⚡ Rayo láser hacia: ", target_position)

func add_weapon(weapon_data: WeaponData) -> bool:
	"""Añadir nueva arma"""
	if equipped_weapons.size() >= max_weapons:
		return false
	
	equipped_weapons.append(weapon_data)
	print("⚔️ Nueva arma equipada: ", weapon_data.name)
	return true

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
	var range: float
	var projectile_speed: float
	var weapon_type: WeaponType
	var targeting: TargetingType
	var level: int = 1
	var max_level: int = 8
	
	func apply_upgrade(upgrade_data: Dictionary):
		"""Aplicar mejora al arma"""
		if upgrade_data.has("damage"):
			damage += upgrade_data.damage
		if upgrade_data.has("cooldown_reduction"):
			cooldown = max(0.1, cooldown - upgrade_data.cooldown_reduction)
		if upgrade_data.has("range"):
			range += upgrade_data.range
		
		level = min(max_level, level + 1)
	
	func get_info() -> Dictionary:
		"""Obtener información del arma"""
		return {
			"id": id,
			"name": name,
			"damage": damage,
			"cooldown": cooldown,
			"range": range,
			"level": level
		}

extends Node
class_name EnemyManager

signal boss_spawned(boss_node: Node2D)

var wave_manager: Node = null
var last_minute_checked: int = -1
var current_wave_pool: Dictionary = {}
signal enemy_spawned(enemy: Node2D)
signal enemy_died(enemy_position: Vector2, enemy_type: String, exp_value: int)


# Referencias
var player: CharacterBody2D
var world_manager: InfiniteWorldManager

# Configuración de spawn
var spawn_distance: float = 600.0  # Distancia del player para spawn
var max_enemies: int = 100
var spawn_rate: float = 2.0  # Enemigos por segundo
var spawn_timer: float = 0.0

# Enemigos activos
var active_enemies: Array[Node2D] = []

# Tipos de enemigos disponibles
var enemy_types: Array[EnemyType] = []

# Estado del sistema
var spawning_enabled: bool = true

func _ready():
	print("👹 EnemyManager inicializado")
	setup_enemy_types()

func initialize(player_ref: CharacterBody2D, world_ref: InfiniteWorldManager):
	"""Inicializar sistema de enemigos"""
	player = player_ref
	world_manager = world_ref
	
	spawning_enabled = true
	spawn_timer = 0.0
	
	print("👹 Sistema de enemigos inicializado")

func setup_enemy_types():
	"""Configurar tipos de enemigos disponibles"""
	
	# Esqueleto básico
	var skeleton = EnemyType.new()
	skeleton.id = "skeleton"
	skeleton.name = "Esqueleto"
	skeleton.health = 15
	skeleton.speed = 80.0
	skeleton.damage = 5
	skeleton.exp_value = 1
	skeleton.size = 32.0
	skeleton.color = Color.WHITE
	enemy_types.append(skeleton)
	
	# Goblin rápido
	var goblin = EnemyType.new()
	goblin.id = "goblin"
	goblin.name = "Goblin"
	goblin.health = 10
	goblin.speed = 120.0
	goblin.damage = 3
	goblin.exp_value = 1
	goblin.size = 28.0
	goblin.color = Color.GREEN
	enemy_types.append(goblin)
	
	# Slime resistente
	var slime = EnemyType.new()
	slime.id = "slime"
	slime.name = "Slime"
	slime.health = 25
	slime.speed = 60.0
	slime.damage = 8
	slime.exp_value = 2
	slime.size = 36.0
	slime.color = Color.BLUE
	enemy_types.append(slime)
	
	print("👹 ", enemy_types.size(), " tipos de enemigos configurados")

func _process(delta):
	"""Actualizar sistema de enemigos"""
	if not spawning_enabled or not player:
		return

	# Actualizar pool de oleada por minuto
	var minute = 0
	var second = 0
	var gm = null
	if get_tree() and get_tree().root and get_tree().root.has_node("GameManager"):
		gm = get_tree().root.get_node("GameManager")
	if gm and gm.has_method("get_elapsed_minutes"):
		minute = int(gm.get_elapsed_minutes())
		if gm.has_method("get_elapsed_seconds"):
			second = int(gm.get_elapsed_seconds()) % 60
	if minute != last_minute_checked and wave_manager:
		last_minute_checked = minute
		current_wave_pool = wave_manager.choose_two_enemies_per_tier(minute)
		# print("[EnemyManager] Wave pool for minute ", minute, ": ", current_wave_pool)

	# Picos de élites a 1:30, 3:00, 5:00 de cada tramo
	var t = (int(minute) % 5) * 60 + second
	if abs(t - 90) < 1.0:
		spawn_elite()
	if abs(t - 180) < 1.0:
		spawn_elite()
	if abs(t - 300) < 1.0:
		spawn_elite()

	# Población objetivo por minuto (puede escalar con el tiempo)
	max_enemies = 20 + int(minute * 2)
	spawn_rate = 1.5 + float(minute) * 0.1

	# Actualizar spawn timer
	update_spawn_timer(delta)
	# Limpiar enemigos muertos o lejanos
	cleanup_enemies()
	# Actualizar enemigos activos
	update_enemies(delta)

func spawn_elite():
	# Spawnea un enemigo de tier alto (tier_4 o boss)
	var elite_id = "titan_arcano"
	if current_wave_pool.has("tier_4") and current_wave_pool["tier_4"].size() > 0:
		elite_id = current_wave_pool["tier_4"][0]
	# Buscar EnemyType por id
	var enemy_type = null
	for et in enemy_types:
		if et.id == elite_id:
			enemy_type = et
			break
	if enemy_type:
		var spawn_position = get_spawn_position()
		var e = spawn_enemy(enemy_type, spawn_position)
		# spawn_elite is used for high-tier spawns; if spawn succeeded, emit boss_spawned
		if e:
			boss_spawned.emit(e)
			print("[EnemyManager] Elite/boss spawned: ", enemy_type.id if enemy_type and enemy_type.has_method("get") == false else str(enemy_type))

func update_spawn_timer(delta):
	"""Actualizar timer de spawn"""
	spawn_timer += delta
	
	var spawn_interval = 1.0 / spawn_rate
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		attempt_spawn_enemy()

func attempt_spawn_enemy():
	"""Intentar generar un enemigo"""
	if active_enemies.size() >= max_enemies:
		return
	
	# Elegir tipo de enemigo según el pool de oleada actual
	var all_wave_types = []
	for tier in current_wave_pool.keys():
		for etype in current_wave_pool[tier]:
			all_wave_types.append(etype)
	if all_wave_types.size() > 0:
		var chosen_id = all_wave_types[randi() % all_wave_types.size()]
		# Buscar EnemyType por id
		var enemy_type = null
		for et in enemy_types:
			if et.id == chosen_id:
				enemy_type = et
				break
		if enemy_type:
			var spawn_position = get_spawn_position()
			spawn_enemy(enemy_type, spawn_position)
	else:
		# Fallback: elegir aleatorio
		var enemy_type = enemy_types[randi() % enemy_types.size()]
		var spawn_position = get_spawn_position()
		spawn_enemy(enemy_type, spawn_position)

func get_spawn_position() -> Vector2:
	"""Obtener posición de spawn en el borde de la pantalla"""
	var _viewport_size = get_viewport().get_visible_rect().size
	var player_pos = player.global_position
	
	# Elegir lado aleatorio (arriba, abajo, izquierda, derecha)
	var side = randi() % 4
	var spawn_pos = Vector2()
	
	match side:
		0:  # Arriba
			spawn_pos = Vector2(
				randf_range(player_pos.x - spawn_distance, player_pos.x + spawn_distance),
				player_pos.y - spawn_distance
			)
		1:  # Derecha
			spawn_pos = Vector2(
				player_pos.x + spawn_distance,
				randf_range(player_pos.y - spawn_distance, player_pos.y + spawn_distance)
			)
		2:  # Abajo
			spawn_pos = Vector2(
				randf_range(player_pos.x - spawn_distance, player_pos.x + spawn_distance),
				player_pos.y + spawn_distance
			)
		3:  # Izquierda
			spawn_pos = Vector2(
				player_pos.x - spawn_distance,
				randf_range(player_pos.y - spawn_distance, player_pos.y + spawn_distance)
			)
	
	return spawn_pos

func spawn_enemy(enemy_type: EnemyType, position: Vector2):
	"""Crear un enemigo en la posición especificada"""
	var enemy = null
	var type_id = null
	if typeof(enemy_type) == TYPE_DICTIONARY and enemy_type.has("id"):
		type_id = enemy_type["id"]
	elif enemy_type and enemy_type.has_method("get"):
		var v = enemy_type.get("id")
		type_id = str(v) if v != null else str(enemy_type)
	else:
		type_id = str(enemy_type)

	var type_desc = type_id
	print("[EnemyManager] spawn_enemy called for type=", type_desc)

	# Try to load a specific scene for this enemy id
	var scene_path = "res://scenes/enemies/%s.tscn" % type_id
	if ResourceLoader.exists(scene_path):
		var packed = ResourceLoader.load(scene_path)
		if packed and packed is PackedScene:
			enemy = packed.instantiate()
			# set minimal fields and parent below

	# Fallback to SpellloopEnemy (script-based) if no scene
	if enemy == null:
		var se = load("res://scripts/enemies/SpellloopEnemy.gd")
		if se:
			enemy = se.new()

	if not enemy:
		push_error("Failed to create enemy for type: %s" % type_id)
		return

	# Initialize
	if enemy.has_method("initialize"):
		enemy.initialize(enemy_type, player)
	enemy.global_position = position

	# Ensure visual sprite is assigned: if enemy has AnimatedSprite2D or Sprite2D but no texture, try SpriteDB
	var root = get_tree().root if get_tree() else null
	if root and root.has_node("SpriteDB"):
		var sdb = root.get_node("SpriteDB")
		# Try assign based on type id under enemies/<id>. Use fallback by tier lists
		var assigned_sprite = ""
		if sdb and sdb.has_method("get_sprite"):
			# convention: enemies/<id>
			assigned_sprite = sdb.get_sprite("enemies/%s" % type_id)
			if assigned_sprite == "":
				# Try tier-based mapping if enemy_type contains tier info
				for tier_key in ["tier_1", "tier_2", "tier_3", "tier_4", "bosses"]:
					if sdb.has(tier_key):
						var list = sdb.get_enemy_list(tier_key)
						if list.size() > 0:
							assigned_sprite = list[randi() % list.size()]
							break
		# Apply assigned sprite to AnimatedSprite2D or Sprite2D if no texture present
		if assigned_sprite != "" and ResourceLoader.exists(assigned_sprite):
			var tex = ResourceLoader.load(assigned_sprite)
			# AnimatedSprite2D
			if enemy.has_node("AnimatedSprite2D"):
				var anim = enemy.get_node("AnimatedSprite2D")
				if anim and anim is AnimatedSprite2D:
					if anim.frames == null or anim.frames.get_frame_count(anim.animation) == 0:
						var frames = AnimatedSprite2D.new().frames
						# Simple single-frame assignment
						var sf = SpriteFrames.new()
						sf.add_animation("idle_down")
						sf.add_frame("idle_down", tex)
						anim.frames = sf
						anim.animation = "idle_down"
			# Sprite2D
			elif enemy.has_node("Sprite2D"):
				var spr = enemy.get_node("Sprite2D")
				if spr and spr is Sprite2D and spr.texture == null:
					spr.texture = tex
	
	# Conectar señales
	enemy.enemy_died.connect(_on_enemy_died)
	
	# Ensure collision layers/masks if methods available on enemy
	if enemy.has_method("set_collision_layer_value"):
		enemy.set_collision_layer_value(2, true) # Enemy layer
	if enemy.has_method("set_collision_mask_value"):
		enemy.set_collision_mask_value(1, true) # Collide with Player
		enemy.set_collision_mask_value(3, true) # Collide with PlayerProjectiles

	# Añadir al árbol
	var added = false
	var root_scene = get_tree().current_scene
	if root_scene and root_scene.has_node("WorldRoot/EnemiesRoot"):
		var enemies_root = root_scene.get_node("WorldRoot/EnemiesRoot")
		# Convertir a posición local en EnemiesRoot
		enemy.position = enemies_root.to_local(position)
		enemy.visible = true
		enemies_root.add_child(enemy)
		added = true
		# Usar type_desc calculado arriba para evitar llamadas .has() sobre instancias
		print("[EnemyManager][DEBUG] Spawn: ", type_desc, " @ ", enemy.global_position, " parent=", enemy.get_parent().name)
	if not added:
		# Fallback: añadir al manager
		add_child(enemy)
		enemy.global_position = position
	active_enemies.append(enemy)
	
	# Emitir señal
	enemy_spawned.emit(enemy)
	
	#print("👹 Enemigo spawneado: ", enemy_type.name, " en ", position)

	return enemy

func _on_enemy_died(enemy: Node2D, enemy_type_id: String, exp_value: int):
	"""Manejar muerte de enemigo"""
	var enemy_position = enemy.global_position
	
	# Remover de lista activos
	if enemy in active_enemies:
		active_enemies.erase(enemy)
	
	# Emitir señal para sistema de EXP
	enemy_died.emit(enemy_position, enemy_type_id, exp_value)
	
	print("💀 Enemigo eliminado: ", enemy_type_id, " EXP: ", exp_value)

func cleanup_enemies():
	"""Limpiar enemigos muertos o muy lejanos"""
	var enemies_to_remove = []
	
	for enemy in active_enemies:
		if not is_instance_valid(enemy):
			enemies_to_remove.append(enemy)
			continue
		
		# Remover enemigos muy lejanos del player
		var distance = enemy.global_position.distance_to(player.global_position)
		if distance > spawn_distance * 2:
			enemies_to_remove.append(enemy)
			enemy.queue_free()
	
	# Remover de la lista
	for enemy in enemies_to_remove:
		active_enemies.erase(enemy)

func update_enemies(_delta):
	"""Actualizar comportamiento de enemigos"""
	# Los enemigos se actualizan automáticamente con su AI

func get_enemy_count() -> int:
	"""Obtener número de enemigos activos"""
	return active_enemies.size()

func get_enemies_in_range(center: Vector2, r: float) -> Array:
	var found: Array = []
	for e in active_enemies:
		if is_instance_valid(e):
			if e.global_position.distance_to(center) <= r:
				found.append(e)
	return found

func set_spawn_rate(new_rate: float):
	"""Cambiar tasa de spawn"""
	spawn_rate = new_rate

func set_max_enemies(new_max: int):
	"""Cambiar máximo de enemigos"""
	max_enemies = new_max

func enable_spawning(enabled: bool):
	"""Habilitar/deshabilitar spawn de enemigos"""
	spawning_enabled = enabled

func clear_all_enemies():
	"""Eliminar todos los enemigos"""
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()

# Funciones para el minimapa
func get_active_enemies() -> Array[Vector2]:
	"""Obtener posiciones de enemigos activos para el minimapa"""
	var enemy_positions: Array[Vector2] = []
	
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy_positions.append(enemy.global_position)
	
	return enemy_positions

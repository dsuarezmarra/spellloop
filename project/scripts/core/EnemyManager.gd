extends Node
class_name EnemyManager

signal boss_spawned(boss_node: Node2D)
signal enemy_spawned(enemy: Node2D)
signal enemy_died(enemy_position: Vector2, enemy_type: String, exp_value: int)

# Script base de enemigos - todos los enemigos usan EnemyBase
var EnemyBaseScript: Script = null

# Test-friendly defaults: low max, high rate so we can observe spawns quickly during debugging.
@export var spawn_distance: float = 600.0
@export var max_enemies: int = 5
@export var spawn_rate: float = 5.0 # spawn attempts per second (useful for quick tests)
@export var debug_spawns: bool = true

var player: Node2D = null
var world_manager: Node = null
var wave_manager: Node = null
var spawn_timer: float = 0.0
var active_enemies: Array = []
var enemy_types: Array = []
var spawning_enabled: bool = true

func _ready() -> void:
	randomize()
	_load_enemy_scripts()
	if debug_spawns:
		print("👹 EnemyManager inicializado (debug_spawns=%s, spawn_rate=%s, max_enemies=%s)" % [debug_spawns, spawn_rate, max_enemies])
	_setup_enemy_types()

func _load_enemy_scripts() -> void:
	# Solo cargamos EnemyBase - es el script universal para todos los enemigos
	if ResourceLoader.exists("res://scripts/enemies/EnemyBase.gd"):
		EnemyBaseScript = load("res://scripts/enemies/EnemyBase.gd")

func _setup_enemy_types() -> void:
	# Velocidades base = 50% de lo que era antes
	# Skeleton: 40 (era 80), Goblin: 60 (era 120), Slime: 30 (era 60)
	enemy_types = [
		{"id":"skeleton","name":"Esqueleto","health":15,"speed":40.0,"exp_value":1,"tier":1},
		{"id":"goblin","name":"Goblin","health":10,"speed":60.0,"exp_value":1,"tier":1},
		{"id":"slime","name":"Slime","health":25,"speed":30.0,"exp_value":2,"tier":1}
	]
	if debug_spawns:
		print("[EnemyManager] enemy_types: %s" % enemy_types)

func initialize(player_ref: Node2D, world_ref: Node) -> void:
	player = player_ref
	world_manager = world_ref
	spawning_enabled = true
	spawn_timer = 0.0
	if debug_spawns:
		print("[EnemyManager] initialize called; player=%s world_manager=%s" % [player, world_manager])

func _process(delta: float) -> void:
	if not spawning_enabled or player == null:
		return
	_update_spawn_timer(delta)
	# NOTE: Enemy movement is now handled by each enemy's _physics_process() in EnemyBase
	# This avoids duplicate movement calculations

func _update_spawn_timer(delta: float) -> void:
	spawn_timer += delta
	var interval = max(0.01, 1.0 / spawn_rate)
	if spawn_timer >= interval:
		spawn_timer = 0.0
		_attempt_spawn()

func _attempt_spawn() -> void:
	if active_enemies.size() >= max_enemies:
		return
	if enemy_types.is_empty():
		return

	var choice = enemy_types[randi() % enemy_types.size()]
	var pos = _get_spawn_position()
	if debug_spawns:
		print("[EnemyManager] attempt spawn: type=%s pos=%s active=%d/%d" % [choice.get("id"), str(pos), active_enemies.size(), max_enemies])
	spawn_enemy(choice, pos)

func _get_spawn_position() -> Vector2:
	var ppos: Vector2 = Vector2.ZERO
	if player and player is Node2D:
		ppos = player.global_position

	var side = randi() % 4
	match side:
		0:
			return Vector2(randf_range(ppos.x - spawn_distance, ppos.x + spawn_distance), ppos.y - spawn_distance)
		1:
			return Vector2(ppos.x + spawn_distance, randf_range(ppos.y - spawn_distance, ppos.y + spawn_distance))
		2:
			return Vector2(randf_range(ppos.x - spawn_distance, ppos.x + spawn_distance), ppos.y + spawn_distance)
		3:
			return Vector2(ppos.x - spawn_distance, randf_range(ppos.y - spawn_distance, ppos.y + spawn_distance))
	return Vector2.ZERO

func _find_visual_node(root: Node) -> Node:
	if root == null:
		return null
	if root is Sprite2D or root is AnimatedSprite2D:
		return root
	for c in root.get_children():
		if c is Node:
			var f = _find_visual_node(c)
			if f:
				return f
	return null

func spawn_enemy(enemy_type: Dictionary, world_pos: Vector2) -> Node:
	var type_id: String = "enemy"
	if typeof(enemy_type) == TYPE_DICTIONARY:
		type_id = str(enemy_type.get("id", "enemy"))

	var enemy: Node = null
	
	# Todos los enemigos usan EnemyBase - la configuración viene del diccionario
	if EnemyBaseScript:
		enemy = CharacterBody2D.new()
		enemy.set_script(EnemyBaseScript)
		enemy.name = "Enemy_%s" % type_id
	else:
		push_warning("⚠️ [EnemyManager] EnemyBaseScript no cargado")
		return null

	if enemy and enemy.has_method("initialize"):
		enemy.initialize(enemy_type, player)

	# Los sprites ya están asignados en initialize() via AnimatedEnemySprite
	var visual = _find_visual_node(enemy)
	if visual and visual is Sprite2D:
		visual.centered = true
	
	# Asegurar visibilidad
	if enemy is Node2D:
		enemy.visible = true
		enemy.z_index = 0

	# Add to scene tree
	var root_scene = get_tree().current_scene if get_tree() else null
	if root_scene and root_scene.has_node("WorldRoot/EnemiesRoot"):
		var er = root_scene.get_node("WorldRoot/EnemiesRoot")
		er.add_child(enemy)
		if enemy is Node2D:
			enemy.position = er.to_local(world_pos)
	else:
		add_child(enemy)
		if enemy is Node2D:
			enemy.global_position = world_pos

	active_enemies.append(enemy)
	emit_signal("enemy_spawned", enemy)
	# If this enemy_type indicates a boss, emit boss_spawned for listeners
	var is_boss: bool = false
	if typeof(enemy_type) == TYPE_DICTIONARY:
		is_boss = bool(enemy_type.get("is_boss", false))
	# Heuristic: also treat types with 'boss' in their id as bosses
	if not is_boss and type_id.find("boss") != -1:
		is_boss = true
	if is_boss:
		emit_signal("boss_spawned", enemy)
	if debug_spawns:
		print("[EnemyManager] Spawned %s at %s (active=%d)" % [type_id, str(world_pos), active_enemies.size()])
	return enemy

func spawn_elite() -> Node:
	# Spawn a stronger random elite/boss near the player
	var elite_data = {"id":"slime_boss","name":"Slime Boss","health":150,"speed":60.0,"exp_value":20, "is_boss": true}
	var pos = _get_spawn_position()
	return spawn_enemy(elite_data, pos)


func _on_enemy_died(enemy: Node, type_id: String = "", exp_value: int = 0) -> void:
	if enemy in active_enemies:
		active_enemies.erase(enemy)
	var pos = Vector2.ZERO
	if enemy and enemy is Node2D:
		pos = enemy.global_position
	emit_signal("enemy_died", pos, type_id, exp_value)
	if debug_spawns:
		print("[EnemyManager] enemy died: %s at %s exp=%d" % [type_id, pos, exp_value])

func get_enemy_count() -> int:
	return active_enemies.size()

func cleanup_enemies() -> void:
	var enemies_to_remove: Array = []
	for enemy in active_enemies:
		if not is_instance_valid(enemy):
			enemies_to_remove.append(enemy)
			continue
		if enemy is Node2D and player and player is Node2D:
			var distance = enemy.global_position.distance_to(player.global_position)
			if distance > spawn_distance * 2:
				enemies_to_remove.append(enemy)
				enemy.queue_free()
	for e in enemies_to_remove:
		active_enemies.erase(e)

func get_enemies_in_range(center: Vector2, r: float) -> Array:
	var found: Array = []
	for e in active_enemies:
		if is_instance_valid(e) and e is Node2D:
			if e.global_position.distance_to(center) <= r:
				found.append(e)
	return found

func set_spawn_rate(new_rate: float) -> void:
	spawn_rate = max(0.01, new_rate)

func set_max_enemies(new_max: int) -> void:
	max_enemies = max(0, new_max)

func enable_spawning(enabled: bool) -> void:
	spawning_enabled = enabled

func clear_all_enemies() -> void:
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()

func get_active_enemy_positions() -> Array:
	var out: Array = []
	for enemy in active_enemies:
		if is_instance_valid(enemy) and enemy is Node2D:
			out.append(enemy.global_position)
	return out

func get_active_enemies() -> Array:
	"""Retornar posiciones de enemigos activos para el minimapa"""
	var out: Array = []
	for enemy in active_enemies:
		if is_instance_valid(enemy) and enemy is Node2D:
			out.append(enemy.global_position)
	return out

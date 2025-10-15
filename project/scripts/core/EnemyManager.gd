extends Node
class_name EnemyManager

"""
👹 GESTOR DE ENEMIGOS - SPELLLOOP STYLE
=====================================

Gestiona la aparición y comportamiento de enemigos:
- Spawn en bordes de pantalla
- Movimiento hacia el player
- Diferentes tipos de enemigos
- Sistema de oleadas
"""

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
	
	# Actualizar spawn timer
	update_spawn_timer(delta)
	
	# Limpiar enemigos muertos o lejanos
	cleanup_enemies()
	
	# Actualizar enemigos activos
	update_enemies(delta)

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
	
	# Elegir tipo de enemigo aleatorio
	var enemy_type = enemy_types[randi() % enemy_types.size()]
	
	# Elegir posición de spawn en el borde
	var spawn_position = get_spawn_position()
	
	# Crear enemigo
	spawn_enemy(enemy_type, spawn_position)

func get_spawn_position() -> Vector2:
	"""Obtener posición de spawn en el borde de la pantalla"""
	var viewport_size = get_viewport().get_visible_rect().size
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
	var enemy = SpellloopEnemy.new()
	enemy.initialize(enemy_type, player)
	enemy.global_position = position
	
	# Conectar señales
	enemy.enemy_died.connect(_on_enemy_died)
	
	# Añadir al árbol
	get_tree().current_scene.add_child(enemy)
	active_enemies.append(enemy)
	
	# Emitir señal
	enemy_spawned.emit(enemy)
	
	#print("👹 Enemigo spawneado: ", enemy_type.name, " en ", position)

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

func update_enemies(delta):
	"""Actualizar comportamiento de enemigos"""
	# Los enemigos se actualizan automáticamente con su AI
	pass

func get_enemies_in_range(position: Vector2, range: float) -> Array[Node2D]:
	"""Obtener enemigos en rango de una posición"""
	var enemies_in_range: Array[Node2D] = []
	
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			var distance = position.distance_to(enemy.global_position)
			if distance <= range:
				enemies_in_range.append(enemy)
	
	return enemies_in_range

func get_enemy_count() -> int:
	"""Obtener número de enemigos activos"""
	return active_enemies.size()

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
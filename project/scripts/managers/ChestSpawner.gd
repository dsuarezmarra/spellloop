# ChestSpawner.gd
# Manager para spawnear cofres tipo tienda aleatoriamente en el mapa
# Los cofres ofrecen items a cambio de monedas

extends Node
class_name ChestSpawner

signal chest_spawned(chest: Node2D, position: Vector2)
signal chest_opened(chest: Node2D, item_purchased: Dictionary)

# === CONFIGURACIÓN ===
@export_group("Spawn Timing")
@export var spawn_interval_base: float = 30.0  # Segundos entre spawns
@export var spawn_interval_variance: float = 5.0  # ± varianza
@export var first_spawn_delay: float = 15.0  # Delay antes del primer spawn

@export_group("Limits")
@export var max_simultaneous_chests: int = 3  # Máximo cofres en mapa
@export var min_distance_from_player: float = 300.0  # Distancia mínima al spawn
@export var max_distance_from_player: float = 800.0  # Distancia máxima al spawn
@export var min_distance_between_chests: float = 200.0  # Evitar clusters

# === ESTADO ===
var is_chest_open: bool = false # Si hay un popup de cofre abierto
var active_chests: Array[Node2D] = []
var spawn_timer: Timer
var player_ref: Node2D
var arena_manager: Node
var pickups_root: Node2D
var game_time: float = 0.0

# Referencia a la escena del cofre
var chest_scene: PackedScene

func _ready():
	# Cargar escena del cofre
	chest_scene = load("res://scenes/interactables/TreasureChest.tscn")
	if not chest_scene:
		push_error("[ChestSpawner] No se pudo cargar TreasureChest.tscn")
	
	# Crear timer de spawn
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	spawn_timer.process_mode = Node.PROCESS_MODE_PAUSABLE  # Respetar pausa del juego
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

func initialize(player: Node2D, arena: Node, pickups: Node2D) -> void:
	"""Inicializar el spawner con referencias necesarias"""
	player_ref = player
	arena_manager = arena
	pickups_root = pickups
	
	# Iniciar primer spawn después del delay
	_schedule_next_spawn(first_spawn_delay)
	
	print("[ChestSpawner] Inicializado - Primer cofre en %.1f segundos" % first_spawn_delay)

func update_game_time(time: float) -> void:
	"""Actualizar tiempo de juego para calcular tier de items"""
	game_time = time

func _schedule_next_spawn(delay: float = -1.0) -> void:
	"""Programar siguiente spawn de cofre"""
	if delay < 0:
		# Calcular delay con varianza
		delay = spawn_interval_base + randf_range(-spawn_interval_variance, spawn_interval_variance)
	
	spawn_timer.start(delay)

func _on_spawn_timer_timeout() -> void:
	"""Timer expiró - spawnear cofre"""
	# Limpiar cofres inválidos
	_cleanup_invalid_chests()
	
	# FIX: Ignorar límite global de cofres (max_simultaneous_chests)
	# Solo nos importa spawnear cerca del player periódicamente
	
	# Calcular posición en la zona del player
	var spawn_pos = _calculate_spawn_position_in_player_zone()
	if spawn_pos == Vector2.INF:
		# No se encontró posición válida, reintentar pronto
		_schedule_next_spawn(5.0)
		return
	
	# Spawnear cofre
	_spawn_shop_chest(spawn_pos)
	
	# Programar siguiente
	_schedule_next_spawn()

func _calculate_spawn_position_in_player_zone() -> Vector2:
	"""Calcular posición válida CERCA del player (Donut Spawn)"""
	if not is_instance_valid(player_ref):
		return Vector2.INF
	
	var player_pos = player_ref.global_position
	
	# Intentar encontrar posición válida sin stackear
	for _attempt in range(20):
		# Generar posición en donut alrededor del player
		var angle = randf() * TAU
		var distance = randf_range(min_distance_from_player, max_distance_from_player)
		var candidate_pos = player_pos + Vector2.from_angle(angle) * distance
		
		# Verificar distancia solo con cofres CERCANOS (ignorar los lejanos)
		var too_close = false
		for chest in active_chests:
			if is_instance_valid(chest):
				# Optimización: Distancia cuadrada
				if chest.global_position.distance_squared_to(candidate_pos) < min_distance_between_chests * min_distance_between_chests:
					too_close = true
					break
		
		if not too_close:
			return candidate_pos
	
	# Fallback: Si está muy lleno, spawnear igual (Prioridad al User Request: "Que aparezca")
	var fallback_angle = randf() * TAU
	return player_pos + Vector2.from_angle(fallback_angle) * min_distance_from_player

func _spawn_shop_chest(pos: Vector2) -> void:
	"""Crear cofre tipo tienda en la posición"""
	if not chest_scene:
		return
	
	var chest = chest_scene.instantiate()
	
	# Añadir al árbol
	if pickups_root:
		pickups_root.add_child(chest)
	else:
		get_tree().current_scene.add_child(chest)
	
	# Determinar tier basado en zona y tiempo
	var zone_tier = _get_zone_tier_at_position(pos)
	var time_bonus = int(game_time / 300.0)  # +1 tier cada 5 minutos
	var effective_tier = clampi(zone_tier + time_bonus, 1, 5)
	
	# Inicializar como cofre SHOP
	if chest.has_method("initialize_as_shop"):
		chest.initialize_as_shop(pos, player_ref, effective_tier, game_time)
	else:
		# Fallback si no tiene el método (usamos initialize normal)
		chest.initialize(pos, TreasureChest.ChestType.NORMAL, player_ref)
	
	# Conectar señales
	if chest.has_signal("chest_opened"):
		chest.chest_opened.connect(_on_chest_opened.bind(chest))
	if chest.has_signal("tree_exiting"):
		chest.tree_exiting.connect(_on_chest_removed.bind(chest))
	
	# Detectar cuando se abre la UI de este cofre
	if chest.has_signal("ui_opened"):
		chest.ui_opened.connect(func(): is_chest_open = true)
	if chest.has_signal("ui_closed"):
		chest.ui_closed.connect(func(): is_chest_open = false)
	
	active_chests.append(chest)
	chest_spawned.emit(chest, pos)
	
	# Debug desactivado: print("[ChestSpawner] Cofre SHOP spawneado en %s (Tier efectivo: %d)" % [pos, effective_tier])

func _get_zone_tier_at_position(pos: Vector2) -> int:
	"""Obtener tier de zona en una posición"""
	if not arena_manager:
		return 1
	
	# Intentar obtener zona del ArenaManager
	if arena_manager.has_method("get_zone_at_position"):
		var zone = arena_manager.get_zone_at_position(pos)
		match zone:
			0: return 1  # SAFE
			1: return 2  # MEDIUM
			2: return 3  # DANGER
			3: return 4  # DEATH
	
	# Fallback: calcular por distancia al centro
	var distance = pos.length()
	if arena_manager.has("arena_radius"):
		var ratio = distance / arena_manager.arena_radius
		if ratio < 0.25: return 1
		elif ratio < 0.55: return 2
		elif ratio < 0.85: return 3
		else: return 4
	
	return 1

func _on_chest_opened(chest: Node2D, items: Array) -> void:
	"""Cofre fue abierto"""
	chest_opened.emit(chest, items[0] if items.size() > 0 else {})

func _on_chest_removed(chest: Node2D) -> void:
	"""Cofre fue removido del árbol"""
	active_chests.erase(chest)

func _cleanup_invalid_chests() -> void:
	"""Limpiar referencias a cofres inválidos"""
	active_chests = active_chests.filter(func(c): return is_instance_valid(c))

func get_active_chest_count() -> int:
	"""Obtener cantidad de cofres activos"""
	_cleanup_invalid_chests()
	return active_chests.size()

extends Node2D

# ItemSpawner.gd
# Sistema que genera objetos coleccionables aleatoriamente en el mapa

class_name ItemSpawner

# Configuración de spawning
@export var spawn_interval: float = 10.0  # Segundos entre spawns
@export var max_items_on_map: int = 5     # Máximo de objetos en el mapa
@export var spawn_radius: float = 300.0   # Radio alrededor del jugador
@export var min_distance_from_player: float = 100.0  # Distancia mínima del jugador

# Referencias
var player: Node2D
var current_items: Array[IsaacItem] = []
var spawn_timer: float = 0.0

# Área de spawn válida
var map_bounds: Rect2 = Rect2(-500, -500, 1000, 1000)  # Área por defecto

func _ready():
	print("[ItemSpawner] Item spawner initialized")
	find_player()
	# Spawn inicial
	spawn_timer = 2.0  # Primer objeto aparece en 2 segundos

func _process(delta):
	# Actualizar timer de spawn
	spawn_timer -= delta
	
	# Limpiar objetos que ya no existen
	clean_up_items()
	
	# Verificar si necesitamos generar más objetos
	if spawn_timer <= 0 and current_items.size() < max_items_on_map:
		attempt_spawn_item()
		spawn_timer = spawn_interval

func find_player():
	"""Encontrar al jugador en la escena"""
	# Buscar el jugador en varios lugares posibles
	player = get_tree().get_first_node_in_group("players")
	
	if not player:
		# Buscar por nombre
		player = get_tree().get_nodes_in_group("player").front() if get_tree().get_nodes_in_group("player").size() > 0 else null
	
	if not player:
		# Buscar cualquier SimplePlayer
		var all_nodes = get_tree().get_nodes_in_group("entities")
		for node in all_nodes:
			if node.get_script() and node.get_script().get_path().ends_with("SimplePlayer.gd"):
				player = node
				break
	
	if not player:
		print("[ItemSpawner] Warning: Player not found! Items will spawn randomly.")
	else:
		print("[ItemSpawner] Player found: ", player.name)

func clean_up_items():
	"""Eliminar referencias a objetos que ya no existen"""
	var valid_items: Array[IsaacItem] = []
	for item in current_items:
		if is_instance_valid(item):
			valid_items.append(item)
	current_items = valid_items

func attempt_spawn_item():
	"""Intentar generar un nuevo objeto"""
	var spawn_position = get_valid_spawn_position()
	if spawn_position != Vector2.ZERO:
		spawn_item(spawn_position)

func get_valid_spawn_position() -> Vector2:
	"""Encontrar una posición válida para generar un objeto"""
	var attempts = 10  # Máximo de intentos
	
	while attempts > 0:
		var position: Vector2
		
		if player and is_instance_valid(player):
			# Generar alrededor del jugador
			var angle = randf() * 2 * PI
			var distance = min_distance_from_player + randf() * (spawn_radius - min_distance_from_player)
			position = player.global_position + Vector2(cos(angle), sin(angle)) * distance
		else:
			# Generar posición aleatoria en el mapa
			position = Vector2(
				map_bounds.position.x + randf() * map_bounds.size.x,
				map_bounds.position.y + randf() * map_bounds.size.y
			)
		
		# Verificar que la posición esté dentro de los límites del mapa
		if map_bounds.has_point(position):
			# Verificar que no esté demasiado cerca de otros objetos
			var too_close = false
			for existing_item in current_items:
				if is_instance_valid(existing_item):
					if position.distance_to(existing_item.global_position) < 50:
						too_close = true
						break
			
			if not too_close:
				return position
		
		attempts -= 1
	
	print("[ItemSpawner] Could not find valid spawn position")
	return Vector2.ZERO

func spawn_item(position: Vector2):
	"""Generar un objeto en la posición especificada"""
	# Crear objeto aleatorio
	var item = IsaacItem.create_random_item()
	item.global_position = position
	
	# Añadir a la escena
	get_parent().add_child(item)
	current_items.append(item)
	
	print("[ItemSpawner] Spawned ", item.get_item_name(), " at ", position)

func spawn_specific_item(item_type: IsaacItem.ItemType, position: Vector2):
	"""Generar un objeto específico en una posición específica"""
	var item = IsaacItem.new()
	item.item_type = item_type
	item.global_position = position
	
	get_parent().add_child(item)
	current_items.append(item)
	
	print("[ItemSpawner] Spawned specific item: ", item.get_item_name(), " at ", position)

func set_map_bounds(bounds: Rect2):
	"""Establecer los límites del mapa para el spawning"""
	map_bounds = bounds
	print("[ItemSpawner] Map bounds set to: ", bounds)

func force_spawn_near_player():
	"""Forzar la generación de un objeto cerca del jugador (para testing)"""
	if player and is_instance_valid(player):
		var position = player.global_position + Vector2(100, 0)  # 100 píxeles a la derecha
		spawn_item(position)
	else:
		print("[ItemSpawner] Cannot spawn near player - player not found")

# Función para testing: spawn todos los tipos de objetos
func spawn_all_item_types():
	"""Generar uno de cada tipo de objeto (para testing)"""
	if not player or not is_instance_valid(player):
		print("[ItemSpawner] Cannot spawn test items - player not found")
		return
	
	var base_position = player.global_position
	var offset = 0
	
	for item_type in IsaacItem.ItemType.values():
		var position = base_position + Vector2(offset, -100)
		spawn_specific_item(item_type, position)
		offset += 40  # Espaciar los objetos

func get_items_count() -> int:
	"""Obtener el número actual de objetos en el mapa"""
	clean_up_items()
	return current_items.size()

# Señales públicas para otros sistemas
signal item_spawned(item: IsaacItem)
signal max_items_reached()
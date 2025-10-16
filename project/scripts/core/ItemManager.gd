extends Node
class_name ItemManager

"""
📦 GESTOR DE ITEMS - VAMPIRE SURVIVORS STYLE
==========================================

Gestiona cofres, items y mejoras:
- Cofres aleatorios en el mundo
- Items de mejora
- Drops especiales de bosses
- Sistema de recolección
"""

signal chest_spawned(chest: Node2D)
signal item_collected(item_type: String, item_data: Dictionary)

# Referencias
var player: CharacterBody2D
var world_manager: InfiniteWorldManager
var static_objects_container: Node2D  # Contenedor para objetos del mundo (se mueve CON el mundo)

# Cofres activos
var active_chests: Array[Node2D] = []
var fixed_chests: Array[Node2D] = []  # Cofres fijos iniciales cerca del player
var chest_spawn_chance: float = 0.15  # Reducida para evitar spam (15%)

# Sistema de spawn dinámico
var last_player_position: Vector2
var distance_for_new_chest: float = 500.0  # Distancia que debe recorrer el player para spawns
var max_active_chests: int = 8  # Máximo de cofres activos en el mundo
var min_chest_distance: float = 300.0  # Distancia mínima entre cofres

# Configuración de items
var item_types: Dictionary = {}

func _ready():
	print("📦 ItemManager inicializado")
	setup_item_types()

func initialize(player_ref: CharacterBody2D, world_ref: InfiniteWorldManager):
	"""Inicializar sistema de items"""
	print("📦 Inicializando ItemManager...")
	player = player_ref
	world_manager = world_ref
	last_player_position = player.global_position
	
	# Crear contenedor para objetos del mundo (cofres, items)
	create_static_container()
	
	# Conectar señales del mundo
	if world_manager.has_signal("chunk_generated"):
		world_manager.chunk_generated.connect(_on_chunk_generated)
		print("📦 Señal chunk_generated conectada")
	else:
		print("❌ Error: chunk_generated signal no encontrada")
	
	# Crear cofres fijos iniciales y sistema dinámico
	create_initial_setup()
	
	print("📦 Sistema de items inicializado")

func setup_item_types():
	"""Configurar tipos de items disponibles"""
	
	# Items de mejora de armas
	item_types["weapon_damage"] = {
		"name": "Cristal de Poder",
		"description": "Aumenta el daño de todas las armas",
		"rarity": "common",
		"color": Color.RED,
		"icon": "⚡"
	}
	
	item_types["weapon_speed"] = {
		"name": "Cristal de Velocidad",
		"description": "Aumenta la velocidad de ataque",
		"rarity": "common", 
		"color": Color.YELLOW,
		"icon": "⚡"
	}
	
	# Items de mejora del player
	item_types["health_boost"] = {
		"name": "Poción de Vida",
		"description": "Aumenta la vida máxima permanentemente",
		"rarity": "common",
		"color": Color.GREEN,
		"icon": "❤️"
	}
	
	item_types["speed_boost"] = {
		"name": "Botas Élficas",
		"description": "Aumenta la velocidad de movimiento",
		"rarity": "uncommon",
		"color": Color.CYAN,
		"icon": "👢"
	}
	
	# Items especiales
	item_types["new_weapon"] = {
		"name": "Arma Nueva",
		"description": "Desbloquea una nueva arma",
		"rarity": "rare",
		"color": Color.PURPLE,
		"icon": "⚔️"
	}
	
	item_types["heal_full"] = {
		"name": "Elixir de Curación",
		"description": "Restaura toda la vida",
		"rarity": "uncommon",
		"color": Color.PINK,
		"icon": "🧪"
	}
	
	print("📦 ", item_types.size(), " tipos de items configurados")

func _process(_delta):
	"""Actualizar sistema dinámico de cofres"""
	if not player:
		return
	
	# Verificar si el player se ha movido lo suficiente para spawnar un nuevo cofre
	var current_pos = player.global_position
	var distance_moved = current_pos.distance_to(last_player_position)
	
	if distance_moved >= distance_for_new_chest:
		consider_spawning_dynamic_chest()
		last_player_position = current_pos
	
	# Limpiar cofres muy lejanos para optimizar
	cleanup_distant_chests()

func create_static_container():
	"""Crear contenedor para objetos del mundo que se mueven CON el mundo"""
	static_objects_container = Node2D.new()
	static_objects_container.name = "WorldObjectsContainer"
	
	# CLAVE: Añadir al world_manager para que se mueva CON el mundo
	if world_manager:
		world_manager.add_child(static_objects_container)
		print("📦 Contenedor de objetos del mundo creado - se mueve CON el mundo")
	else:
		print("❌ Error: world_manager no disponible")
		return

func _on_chunk_generated(chunk_pos: Vector2i):
	"""Manejar generación de nuevo chunk - Sistema dinámico mejorado"""
	print("📦 Chunk generado: ", chunk_pos, " - Evaluando spawn de cofre...")
	
	# Verificar que no esté muy cerca del player (evitar spawn inmediato)
	var player_chunk = Vector2i(
		int(player.global_position.x / world_manager.CHUNK_SIZE),
		int(player.global_position.y / world_manager.CHUNK_SIZE)
	)
	
	var distance_to_player_chunk = chunk_pos.distance_to(player_chunk)
	if distance_to_player_chunk < 2.0:  # Al menos 2 chunks de distancia
		print("📦 Chunk muy cerca del player, no generando cofre")
		return
	
	# Verificar límite de cofres activos
	if active_chests.size() >= max_active_chests:
		print("📦 Máximo de cofres activos alcanzado (", max_active_chests, ")")
		return
	
	# Probabilidad muy baja para evitar spam
	if randf() < chest_spawn_chance:
		print("📦 ¡Generando cofre dinámico en chunk ", chunk_pos, "!")
		spawn_chest_in_chunk(chunk_pos)
	else:
		print("📦 No se genera cofre en chunk ", chunk_pos)

func spawn_chest_in_chunk(chunk_pos: Vector2i):
	"""Generar cofre en un chunk específico"""
	if not world_manager:
		return
	
	# Calcular posición aleatoria dentro del chunk
	var chunk_world_pos = world_manager.chunk_to_world(chunk_pos)
	var chunk_size = world_manager.CHUNK_SIZE
	
	var chest_pos = Vector2(
		chunk_world_pos.x + randf_range(100, chunk_size - 100),
		chunk_world_pos.y + randf_range(100, chunk_size - 100)
	)
	
	spawn_chest(chest_pos)

func spawn_chest(position: Vector2, chest_type: String = "normal"):
	"""Crear cofre en posición específica del mundo"""
	# Verificar que no esté muy cerca de otros cofres
	for existing_chest in active_chests:
		if is_instance_valid(existing_chest):
			if existing_chest.global_position.distance_to(position) < min_chest_distance:
				print("📦 Posición muy cerca de otro cofre, cancelando spawn")
				return
	
	var chest = TreasureChest.new()
	
	# Determinar rareza del cofre usando nivel del jugador
	var player_level = 1  # Nivel base por defecto
	if player and player.has_method("get_level"):
		player_level = player.get_level()
	var item = ItemsDefinitions.get_weighted_random_item(player_level)
	
	chest.initialize(position, chest_type, player, 0)  # Usar rareza básica por ahora
	chest.chest_opened.connect(_on_chest_opened)
	
	# CLAVE: Añadir al contenedor del mundo - se mueve CON el mundo
	if static_objects_container:
		static_objects_container.add_child(chest)
		chest.global_position = position  # Posición en el mundo
		print("📦 Cofre generado en el MUNDO en posición: ", position)
	else:
		print("❌ Error: Contenedor del mundo no disponible")
		return
	
	active_chests.append(chest)
	
	# Emitir señal
	chest_spawned.emit(chest)
	
	print("📦 Cofre generado ESTÁTICO AUTOCOMPENSADO en posición: ", position)

func _on_chest_opened(chest: Node2D, items: Array):
	"""Manejar apertura de cofre"""
	# Remover de lista activos
	if chest in active_chests:
		active_chests.erase(chest)
	
	# Procesar items obtenidos
	for item_data in items:
		process_item_collected(item_data)
	
	print("📦 Cofre abierto - Items obtenidos: ", items.size())

func process_item_collected(item_data: Dictionary):
	"""Procesar item recolectado"""
	var item_type = item_data.get("type", "unknown")
	
	# Aplicar efecto del item
	apply_item_effect(item_type, item_data)
	
	# Emitir señal
	item_collected.emit(item_type, item_data)

func apply_item_effect(item_type: String, item_data: Dictionary):
	"""Aplicar efecto de un item"""
	match item_type:
		"weapon_damage":
			# Aumentar daño de armas (se conectará con WeaponManager)
			print("⚡ Daño de armas aumentado")
		
		"weapon_speed":
			# Aumentar velocidad de ataque
			print("⚡ Velocidad de ataque aumentada")
		
		"health_boost":
			# Aumentar vida máxima
			if player.has_method("increase_max_health"):
				player.increase_max_health(20)
			print("❤️ Vida máxima aumentada")
		
		"speed_boost":
			# Aumentar velocidad de movimiento
			print("👢 Velocidad de movimiento aumentada")
		
		"heal_full":
			# Curar completamente
			if player.has_method("heal"):
				player.heal(999)
			print("🧪 Vida completamente restaurada")
		
		"new_weapon":
			# Desbloquear nueva arma (se conectará con WeaponManager)
			print("⚔️ Nueva arma desbloqueada")

func create_boss_drop(position: Vector2, boss_type: String):
	"""Crear drop especial de boss"""
	var item_types_boss = ["new_weapon", "weapon_damage", "health_boost"]
	var selected_type = item_types_boss[randi() % item_types_boss.size()]
	
	# Boss drops tienen mejor rareza
	var rarity = ItemsDefinitions.ItemRarity.BLUE  # Común para bosses
	
	var item_drop = ItemDrop.new()
	item_drop.initialize(position, selected_type, player, rarity)
	item_drop.item_collected.connect(_on_item_drop_collected)
	
	# Añadir al mundo fijo, no al current_scene que podría moverse
	if world_manager:
		world_manager.add_child(item_drop)
	else:
		get_tree().current_scene.add_child(item_drop)
	
	print("👑 Drop de boss creado: ", selected_type)

func _on_item_drop_collected(item_drop: Node2D, item_type: String):
	"""Manejar recolección de item drop"""
	var item_data = {
		"type": item_type,
		"source": "boss_drop"
	}
	
	process_item_collected(item_data)

func get_random_item_type(rarity_bias: String = "common") -> String:
	"""Obtener tipo de item aleatorio con sesgo de rareza"""
	var filtered_items = []
	
	for item_id in item_types.keys():
		var item = item_types[item_id]
		if item.rarity == rarity_bias or rarity_bias == "any":
			filtered_items.append(item_id)
	
	if filtered_items.is_empty():
		return item_types.keys()[0]  # Fallback al primer item
	
	return filtered_items[randi() % filtered_items.size()]

func get_chest_count() -> int:
	"""Obtener número de cofres activos"""
	return active_chests.size()

# Funciones para el minimapa
func get_active_chests() -> Array[Dictionary]:
	"""Obtener cofres activos con información de rareza para el minimapa"""
	var chest_data: Array[Dictionary] = []
	
	for child in get_children():
		if child is TreasureChest and not child.is_opened:
			chest_data.append({
				"position": child.global_position,
				"rarity": child.chest_rarity
			})
	
	return chest_data

func get_active_items() -> Array[Dictionary]:
	"""Obtener items activos con información de rareza para el minimapa"""
	var item_data: Array[Dictionary] = []
	
	for child in get_children():
		if child is ItemDrop:
			item_data.append({
				"position": child.global_position,
				"rarity": child.item_rarity
			})
	
	return item_data

func create_test_items():
	"""Crear items y cofres de prueba para testing - REEMPLAZADO por create_initial_setup"""
	print("📦 create_test_items() ha sido reemplazado por create_initial_setup()")

func create_initial_setup():
	"""Crear configuración inicial: 3 cofres fijos cerca del player + items de prueba"""
	print("📦 Iniciando configuración inicial del sistema...")
	
	if not player:
		print("❌ Error: Player no disponible para crear configuración inicial")
		return
	
	var player_pos = player.global_position
	print("📦 Posición del player: ", player_pos)
	
	# CREAR 3 COFRES FIJOS ALCANZABLES CERCA DEL PLAYER
	print("📦 Creando 3 cofres fijos cerca del player...")
	
	# Cofres fijos en posiciones calculadas alrededor del player (alcanzables)
	var fixed_positions = [
		player_pos + Vector2(200, 150),   # Cofre 1: derecha-abajo del player
		player_pos + Vector2(-180, 120),  # Cofre 2: izquierda-abajo del player  
		player_pos + Vector2(50, -200)    # Cofre 3: arriba del player
	]
	
	for i in range(fixed_positions.size()):
		var chest_pos = fixed_positions[i]
		spawn_fixed_chest(chest_pos, "fixed")
		print("📦 Cofre fijo ", i + 1, " creado en: ", chest_pos)
	
	# CREAR ALGUNOS COFRES LEJANOS PARA EXPLORACIÓN
	print("📦 Creando cofres de exploración...")
	var exploration_positions = [
		Vector2(1400, 300),   # Cofre de exploración lejano
		Vector2(600, 800),    # Cofre de exploración lejano
	]
	
	for pos in exploration_positions:
		spawn_chest(pos, "exploration")
	
	# Crear algunos items de prueba
	print("📦 Creando items de prueba...")
	create_test_item_drop(player_pos + Vector2(100, 80), "weapon_damage", ItemsDefinitions.ItemRarity.WHITE)
	create_test_item_drop(player_pos + Vector2(-120, 90), "health_boost", ItemsDefinitions.ItemRarity.BLUE)
	create_test_item_drop(player_pos + Vector2(150, -100), "speed_boost", ItemsDefinitions.ItemRarity.YELLOW)
	
	print("📦 Configuración inicial completada: 3 cofres fijos + 2 exploración + 3 items")

func spawn_fixed_chest(position: Vector2, chest_type: String = "fixed"):
	"""Crear cofre fijo inicial (no se cuenta para límites dinámicos)"""
	var chest = TreasureChest.new()
	
	chest.initialize(position, chest_type, player, 0)
	chest.chest_opened.connect(_on_chest_opened)
	
	# CLAVE: Añadir al contenedor del mundo - se mueve CON el mundo
	if static_objects_container:
		static_objects_container.add_child(chest)
		chest.global_position = position  # Posición en el mundo
	else:
		print("❌ Error: Contenedor del mundo no disponible")
		return
	
	fixed_chests.append(chest)
	
	print("📦 Cofre FIJO del mundo generado en posición: ", position)

func consider_spawning_dynamic_chest():
	"""Considerar spawnar un cofre dinámico basado en el movimiento del player"""
	# Verificar límites
	if active_chests.size() >= max_active_chests:
		return
	
	# Probabilidad de spawn dinámico (cuando el player se mueve)
	if randf() < 0.4:  # 40% chance cuando se cumple la distancia
		spawn_dynamic_chest()

func spawn_dynamic_chest():
	"""Spawnar cofre dinámico en posición aleatoria alrededor del player"""
	if not player:
		return
	
	var player_pos = player.global_position
	
	# Generar posición aleatoria en un rango moderado del player
	var angle = randf() * 2 * PI
	var distance = randf_range(400.0, 800.0)  # Entre 400 y 800 pixels del player
	
	var spawn_pos = player_pos + Vector2(
		cos(angle) * distance,
		sin(angle) * distance
	)
	
	# Verificar que no esté muy cerca de otros cofres
	var too_close = false
	for existing_chest in active_chests + fixed_chests:
		if is_instance_valid(existing_chest):
			# Comparación directa ya que el contenedor compensa automáticamente
			if existing_chest.global_position.distance_to(spawn_pos) < min_chest_distance:
				too_close = true
				break
	
	if not too_close:
		spawn_chest(spawn_pos, "dynamic")
		print("📦 Cofre dinámico spawneado en: ", spawn_pos)

func cleanup_distant_chests():
	"""Limpiar cofres dinámicos muy lejanos para optimizar"""
	if not player:
		return
	
	var player_pos = player.global_position
	var max_distance = 1500.0  # Distancia máxima para mantener cofres
	
	for i in range(active_chests.size() - 1, -1, -1):
		var chest = active_chests[i]
		if is_instance_valid(chest):
			# Comparación directa ya que el contenedor compensa automáticamente
			if chest.global_position.distance_to(player_pos) > max_distance:
				print("📦 Removiendo cofre dinámico lejano en: ", chest.global_position)
				active_chests.remove_at(i)
				chest.queue_free()
		else:
			# Remover referencias inválidas
			active_chests.remove_at(i)

func create_test_item_drop(position: Vector2, type: String, rarity: int):
	"""Crear un item drop de prueba"""
	print("⭐ Creando item de prueba: ", type, " en ", position)
	
	var item_drop = ItemDrop.new()
	item_drop.initialize(position, type, player, rarity)
	item_drop.item_collected.connect(_on_item_drop_collected)
	
	# CLAVE: Añadir al contenedor del mundo - se mueve CON el mundo
	if static_objects_container:
		static_objects_container.add_child(item_drop)
		item_drop.global_position = position  # Posición en el mundo
	else:
		print("❌ Error: Contenedor del mundo no disponible")
		return
	
	print("⭐ Item de prueba creado en el mundo: ", position)

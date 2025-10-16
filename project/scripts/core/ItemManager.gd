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

# Cofres activos
var active_chests: Array[Node2D] = []
var chest_spawn_chance: float = 0.3  # Aumentado temporalmente para testing (30%)

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
	
	# Conectar señales del mundo
	if world_manager.has_signal("chunk_generated"):
		world_manager.chunk_generated.connect(_on_chunk_generated)
		print("📦 Señal chunk_generated conectada")
	else:
		print("❌ Error: chunk_generated signal no encontrada")
	
	# Crear algunos items de prueba cerca del player para testing
	create_test_items()
	
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

func _on_chunk_generated(chunk_pos: Vector2i):
	"""Manejar generación de nuevo chunk"""
	print("📦 Chunk generado: ", chunk_pos, " - Evaluando spawn de cofre...")
	
	# Verificar que no esté muy cerca del player (evitar spawn inmediato)
	var player_chunk = Vector2i(
		int(player.global_position.x / world_manager.CHUNK_SIZE),
		int(player.global_position.y / world_manager.CHUNK_SIZE)
	)
	
	var distance_to_player_chunk = chunk_pos.distance_to(player_chunk)
	if distance_to_player_chunk < 1.5:  # Al menos 1.5 chunks de distancia
		print("📦 Chunk muy cerca del player, no generando cofre")
		return
	
	# Probabilidad ajustada según distancia
	var distance_factor = min(distance_to_player_chunk / 3.0, 1.0)  # Máximo factor a distancia 3
	var adjusted_chance = chest_spawn_chance * distance_factor
	
	# Posibilidad de generar cofre en el chunk
	if randf() < adjusted_chance:
		print("📦 ¡Generando cofre en chunk ", chunk_pos, "! (probabilidad: ", adjusted_chance, ")")
		spawn_chest_in_chunk(chunk_pos)
	else:
		print("📦 No se genera cofre en chunk ", chunk_pos, " (probabilidad: ", adjusted_chance, ")")

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
	"""Crear cofre en posición específica"""
	var chest = TreasureChest.new()
	
	# Determinar rareza del cofre usando nivel del jugador
	var player_level = 1  # Nivel base por defecto
	if player and player.has_method("get_level"):
		player_level = player.get_level()
	var item = ItemsDefinitions.get_weighted_random_item(player_level)
	
	chest.initialize(position, chest_type, player, 0)  # Usar rareza básica por ahora
	chest.chest_opened.connect(_on_chest_opened)
	
	# Añadir al mundo fijo, no al current_scene que podría moverse
	if world_manager:
		world_manager.add_child(chest)
	else:
		get_tree().current_scene.add_child(chest)
	active_chests.append(chest)
	
	# Emitir señal
	chest_spawned.emit(chest)
	
	print("📦 Cofre generado en: ", position)

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

func cleanup_distant_chests():
	"""Limpiar cofres muy lejanos del player"""
	var max_distance = 1000.0
	var chests_to_remove = []
	
	for chest in active_chests:
		if not is_instance_valid(chest):
			chests_to_remove.append(chest)
			continue
		
		var distance = chest.global_position.distance_to(player.global_position)
		if distance > max_distance:
			chests_to_remove.append(chest)
			chest.queue_free()
	
	for chest in chests_to_remove:
		active_chests.erase(chest)

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
	"""Crear items y cofres de prueba para testing"""
	print("📦 Iniciando creación de items de prueba...")
	
	if not player:
		print("❌ Error: Player no disponible para crear items de prueba")
		return
	
	var player_pos = player.global_position
	print("📦 Posición del player: ", player_pos)
	
	# Crear algunos cofres de prueba con diferentes rarezas
	print("📦 Creando cofres de prueba...")
	spawn_chest(player_pos + Vector2(200, 100), "normal")  # Cofre normal
	spawn_chest(player_pos + Vector2(-200, 150), "normal")  # Cofre común  
	spawn_chest(player_pos + Vector2(150, -200), "normal")  # Cofre raro
	
	# Crear algunos items de prueba
	print("📦 Creando items de prueba...")
	create_test_item_drop(player_pos + Vector2(100, 50), "weapon_damage", ItemsDefinitions.ItemRarity.WHITE)
	create_test_item_drop(player_pos + Vector2(-100, 75), "health_boost", ItemsDefinitions.ItemRarity.BLUE)
	create_test_item_drop(player_pos + Vector2(75, -100), "speed_boost", ItemsDefinitions.ItemRarity.YELLOW)
	create_test_item_drop(player_pos + Vector2(-75, -125), "new_weapon", ItemsDefinitions.ItemRarity.ORANGE)
	
	print("📦 Items y cofres de prueba creados cerca del player")

func create_test_item_drop(position: Vector2, type: String, rarity: int):
	"""Crear un item drop de prueba"""
	print("⭐ Creando item de prueba: ", type, " en ", position)
	
	var item_drop = ItemDrop.new()
	item_drop.initialize(position, type, player, rarity)
	item_drop.item_collected.connect(_on_item_drop_collected)
	
	# Añadir al mundo fijo, no al current_scene que podría moverse
	if world_manager:
		world_manager.add_child(item_drop)
	else:
		get_tree().current_scene.add_child(item_drop)
	
	print("⭐ Item de prueba creado exitosamente")

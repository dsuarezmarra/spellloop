extends Node
class_name ItemManager

"""
📦 GESTOR DE ITEMS - VAMPIRE SURVIVORS STYLE
==========================================

Gestiona cofres, items y mejoras:
- Cofres generados en chunks (pegados al suelo)
- Items de mejora
- Drops especiales de bosses
- Sistema de recolección
"""

signal chest_spawned(chest: Node2D)
signal item_collected(item_type: String, item_data: Dictionary)

# Referencias
var player: CharacterBody2D
var world_manager: InfiniteWorldManager

# Configuración de spawn en chunks
var chest_spawn_chance: float = 0.3  # Probabilidad de que un chunk tenga cofre (30%)

# Tracking de cofres por chunk
var chests_by_chunk: Dictionary = {}  # Vector2i (chunk_pos) -> Array[Node2D] (cofres en ese chunk)
var all_chests: Array[Node2D] = []  # Todos los cofres generados

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
	
	# Conectar a la señal de generación de chunks
	if world_manager.has_signal("chunk_generated"):
		world_manager.chunk_generated.connect(_on_chunk_generated)
		print("📦 Conectado a señal chunk_generated")
	else:
		print("❌ Error: chunk_generated signal no encontrada")
	
	# Crear cofres iniciales de prueba en el chunk inicial (0, 0)
	create_initial_test_chests()
	
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
	"""Actualizar sistema de cofres"""
	if not player:
		return
	
	# Limpiar cofres muy lejanos para optimizar
	cleanup_distant_chests()

func create_initial_test_chests():
	"""Crear cofres de prueba en el chunk inicial (0, 0)"""
	print("📦 Creando cofres de prueba en chunk (0, 0)...")
	
	# Crear 3 cofres de prueba en posiciones específicas dentro del chunk inicial
	var chunk_pos = Vector2i(0, 0)
	var chunk_world_pos = world_manager.chunk_to_world(chunk_pos)
	var _chunk_size = world_manager.CHUNK_SIZE
	
	# Posiciones relativas dentro del chunk
	var test_positions = [
		chunk_world_pos + Vector2(200, 200),
		chunk_world_pos + Vector2(500, 300),
		chunk_world_pos + Vector2(300, 600)
	]
	
	for pos in test_positions:
		spawn_chest_in_chunk_at_position(chunk_pos, pos)
	
	print("📦 Cofres de prueba creados: ", test_positions.size())

func _on_chunk_generated(chunk_pos: Vector2i):
	"""Manejar generación de nuevo chunk - Generar cofre si toca"""
	# Probabilidad de generar un cofre en este chunk
	if randf() < chest_spawn_chance:
		print("📦 ¡Generando cofre aleatorio en chunk ", chunk_pos, "!")
		spawn_random_chest_in_chunk(chunk_pos)
	else:
		print("📦 Sin cofre en chunk ", chunk_pos)

func spawn_random_chest_in_chunk(chunk_pos: Vector2i):
	"""Generar un cofre aleatorio en una posición aleatoria del chunk"""
	if not world_manager or not world_manager.loaded_chunks.has(chunk_pos):
		print("❌ Chunk no cargado: ", chunk_pos)
		return
	
	# Obtener el nodo del chunk
	var chunk_data = world_manager.loaded_chunks[chunk_pos]
	var chunk_node = chunk_data.node
	if not chunk_node:
		print("❌ Chunk node no disponible")
		return
	
	# Posición aleatoria dentro del chunk
	var chunk_size = world_manager.CHUNK_SIZE
	var local_pos = Vector2(
		randf_range(100, chunk_size - 100),
		randf_range(100, chunk_size - 100)
	)
	
	spawn_chest_in_chunk_at_position(chunk_pos, chunk_node.global_position + local_pos)

func spawn_chest_in_chunk_at_position(chunk_pos: Vector2i, world_position: Vector2):
	"""Generar un cofre en una posición específica dentro de un chunk"""
	if not world_manager or not world_manager.loaded_chunks.has(chunk_pos):
		print("❌ Chunk no disponible")
		return
	
	# Obtener el nodo del chunk
	var chunk_data = world_manager.loaded_chunks[chunk_pos]
	var chunk_node = chunk_data.node
	if not chunk_node:
		print("❌ Chunk node no disponible")
		return
	
	# Crear el cofre
	var chest = TreasureChest.new()
	chest.initialize(world_position, "normal", player, 0)
	chest.chest_opened.connect(_on_chest_opened)
	
	# CLAVE: Añadir el cofre como HIJO del chunk
	# Así se mueve automáticamente cuando el chunk se mueve
	chunk_node.add_child(chest)
	chest.global_position = world_position
	
	# Registrar en tracking
	if not chests_by_chunk.has(chunk_pos):
		chests_by_chunk[chunk_pos] = []
	chests_by_chunk[chunk_pos].append(chest)
	all_chests.append(chest)
	
	# Emitir señal
	chest_spawned.emit(chest)
	
	print("📦 Cofre generado en chunk ", chunk_pos, " en posición: ", world_position)

func _on_chest_opened(chest: Node2D, items: Array):
	"""Manejar apertura de cofre"""
	# Remover de tracking
	for chunk_pos in chests_by_chunk.keys():
		if chest in chests_by_chunk[chunk_pos]:
			chests_by_chunk[chunk_pos].erase(chest)
	
	if chest in all_chests:
		all_chests.erase(chest)
	
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

func apply_item_effect(item_type: String, _item_data: Dictionary):
	"""Aplicar efecto de un item"""
	match item_type:
		"weapon_damage":
			print("⚡ Daño de armas aumentado")
			var _cs = get_tree() and get_tree().current_scene
			if _cs and _cs.has_node("WeaponManager"):
				var wm = _cs.get_node("WeaponManager")
				wm.upgrade_weapon("magic_wand", {"damage": 5})
		"weapon_speed":
			print("⚡ Velocidad de ataque aumentada")
			var _cs = get_tree() and get_tree().current_scene
			if _cs and _cs.has_node("WeaponManager"):
				var wm = _cs.get_node("WeaponManager")
				wm.upgrade_weapon("magic_wand", {"cooldown_reduction": 0.2})
		"health_boost":
			if player.has_method("increase_max_health"):
				player.increase_max_health(20)
			print("❤️ Vida máxima aumentada")
		"speed_boost":
			print("👢 Velocidad de movimiento aumentada")
		"heal_full":
			if player.has_method("heal"):
				player.heal(999)
			print("🧪 Vida completamente restaurada")
		"new_weapon":
			print("⚔️ Nueva arma desbloqueada")
			var _cs = get_tree() and get_tree().current_scene
			if _cs and _cs.has_node("WeaponManager"):
				var wm = _cs.get_node("WeaponManager")
				var new_w = WeaponManager.WeaponData.new()
				new_w.id = "fire_staff"
				new_w.name = "Bastón de Fuego"
				new_w.damage = 15
				new_w.cooldown = 1.2
				new_w.weapon_range = 400.0
				new_w.projectile_speed = 350.0
				new_w.weapon_type = WeaponManager.WeaponData.WeaponType.PROJECTILE
				new_w.targeting = WeaponManager.WeaponData.TargetingType.NEAREST_ENEMY
				wm.add_weapon(new_w)

func create_boss_drop(position: Vector2, _boss_type: String):
	"""Crear drop especial de boss"""
	var item_types_boss = ["new_weapon", "weapon_damage", "health_boost"]
	var selected_type = item_types_boss[randi() % item_types_boss.size()]
	
	# Boss drops tienen mejor rareza
	# Use numeric fallback for rarity enum to avoid parse-time ItemsDefinitions dependency
	var rarity = 1  # ItemsDefinitions.ItemRarity.BLUE
	
	var item_drop = ItemDrop.new()
	item_drop.initialize(position, selected_type, player, rarity)
	item_drop.item_collected.connect(_on_item_drop_collected)
	
	# Añadir al mundo fijo, no al current_scene que podría moverse
	if world_manager:
		world_manager.add_child(item_drop)
	else:
		get_tree().current_scene.add_child(item_drop)
	
	print("👑 Drop de boss creado: ", selected_type)

func _on_item_drop_collected(_item_drop: Node2D, item_type: String):
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
		var _item = item_types[item_id]
		if _item.rarity == rarity_bias or rarity_bias == "any":
			filtered_items.append(item_id)
	
	if filtered_items.is_empty():
		return item_types.keys()[0]  # Fallback al primer item
	
	return filtered_items[randi() % filtered_items.size()]
func get_chest_count() -> int:
	"""Obtener número de cofres activos"""
	return all_chests.size()

# Funciones para el minimapa
func get_active_chests() -> Array[Dictionary]:
	"""Obtener cofres activos con información de rareza para el minimapa"""
	var chest_data: Array[Dictionary] = []
	
	for chest in all_chests:
		if is_instance_valid(chest):
			# Obtener la rareza real del cofre si existe, sino usar 0 (WHITE)
			var chest_rarity = 0
			if chest.has_meta("chest_rarity"):
				chest_rarity = chest.get_meta("chest_rarity")
			elif "chest_rarity" in chest:
				chest_rarity = chest.chest_rarity
			
			chest_data.append({
				"position": chest.global_position,
				"rarity": chest_rarity
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
	"""Obsoleto - Reemplazado por create_initial_test_chests()"""
	pass

# Funciones de cleanup y management

func cleanup_distant_chests():
	"""Limpiar cofres que están muy lejos del player"""
	var chests_to_remove = []
	var max_distance = 2000.0  # Distancia máxima antes de remover
	
	for chest in all_chests:
		if not is_instance_valid(chest):
			chests_to_remove.append(chest)
			continue
		
		var distance = chest.global_position.distance_to(player.global_position)
		if distance > max_distance:
			# Marcar para remover (el cofre ya está en un chunk que se descargará)
			chests_to_remove.append(chest)
	
	for chest in chests_to_remove:
		if chest in all_chests:
			all_chests.erase(chest)

func create_test_item_drop(_position: Vector2, _type: String, _rarity: int):
	"""Crear un item drop de prueba (obsoleto - items ahora se crean al abrir cofres)"""
	print("⭐ Item drop - Los items ahora se generan al abrir cofres")

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
	var chunk_world_pos = Vector2(chunk_pos.x * world_manager.chunk_width, chunk_pos.y * world_manager.chunk_height)
	
	# Posiciones relativas dentro del chunk
	var test_positions = [
		chunk_world_pos + Vector2(200, 200),
		chunk_world_pos + Vector2(500, 300),
		chunk_world_pos + Vector2(300, 600)
	]
	
	for pos in test_positions:
		spawn_chest_at_position(chunk_pos, pos)
	
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
	# Obtener el nodo del chunk desde el world_manager
	var chunk_node = world_manager.get_chunk_at_pos(Vector2(chunk_pos.x * world_manager.chunk_width, chunk_pos.y * world_manager.chunk_height))
	if not chunk_node:
		print("❌ Chunk no disponible: ", chunk_pos)
		return
	
	# Posición aleatoria dentro del chunk
	var local_pos = Vector2(
		randf_range(100, world_manager.chunk_width - 100),
		randf_range(100, world_manager.chunk_height - 100)
	)
	
	var world_pos = chunk_node.global_position + local_pos
	spawn_chest_at_position(chunk_pos, world_pos)

func spawn_chest_at_position(chunk_pos: Vector2i, world_position: Vector2):
	"""Generar un cofre en una posición específica dentro de un chunk"""
	# Obtener el nodo del chunk desde el world_manager
	var chunk_node = world_manager.get_chunk_at_pos(world_position)
	if not chunk_node:
		print("❌ Chunk no disponible para posición: ", world_position)
		return
	
	# Crear el cofre
	var rarity = compute_normal_chest_rarity()
	var chest = TreasureChest.new()
	chest.initialize(world_position, "normal", player, rarity)
	chest.chest_opened.connect(_on_chest_opened)
	
	# Añadir el cofre como hijo del chunk
	# Así se mueve automáticamente cuando el chunk se carga/descarga
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
			var _cs = null
			var _gt = get_tree()
			if _gt:
				_cs = _gt.current_scene
			if _cs and _cs.has_node("WeaponManager"):
				var wm = _cs.get_node("WeaponManager")
				if wm and wm.has_method("upgrade_weapon"):
					wm.upgrade_weapon("magic_wand", {"damage": 5})
		"weapon_speed":
			print("⚡ Velocidad de ataque aumentada")
			var _cs = null
			var _gt = get_tree()
			if _gt:
				_cs = _gt.current_scene
			if _cs and _cs.has_node("WeaponManager"):
				var wm = _cs.get_node("WeaponManager")
				if wm and wm.has_method("upgrade_weapon"):
					wm.upgrade_weapon("magic_wand", {"cooldown_reduction": 0.2})
		"health_boost":
			if player and player.has_method("increase_max_health"):
				player.increase_max_health(20)
			print("❤️ Vida máxima aumentada")
		"speed_boost":
			print("👢 Velocidad de movimiento aumentada")
		"heal_full":
			if player and player.has_method("heal"):
				player.heal(999)
			print("🧪 Vida completamente restaurada")
		"new_weapon":
			print("⚔️ Nueva arma desbloqueada")
			var _cs = null
			var _gt = get_tree()
			if _gt:
				_cs = _gt.current_scene
			if _cs and _cs.has_node("WeaponManager"):
				var wm = _cs.get_node("WeaponManager")
				# Prefer calling add_weapon with a WeaponData instance if available
				if wm and wm.has_method("add_weapon"):
					var created = false
					# Try to construct WeaponManager.WeaponData if symbol is available
					if typeof(WeaponManager) != TYPE_NIL:
						var wd = WeaponManager.WeaponData.new()
						wd.id = "fire_staff"
						wd.name = "Bastón de Fuego"
						wd.damage = 15
						wd.cooldown = 1.2
						wd.weapon_range = 400.0
						wd.projectile_speed = 350.0
						wd.weapon_type = WeaponManager.WeaponData.WeaponType.PROJECTILE
						wd.targeting = WeaponManager.WeaponData.TargetingType.NEAREST_ENEMY
						wm.add_weapon(wd)
						created = true
					# Fallback: pass a simple dictionary if object construction failed
					if not created:
						var new_w = {
							"id": "fire_staff",
							"name": "Bastón de Fuego",
							"damage": 15,
							"cooldown": 1.2,
							"weapon_range": 400.0,
							"projectile_speed": 350.0,
							"weapon_type": "projectile",
							"targeting": "nearest"
						}
						wm.add_weapon(new_w)



func create_boss_drop(position: Vector2, _boss_type: String):
	"""Crear drop especial de boss"""
	# Determine chest rarity influenced by meta luck
	var chest_rarity = compute_boss_chest_rarity()
	var chest = TreasureChest.new()
	# Use type 'big' so UI/popup can adapt (TreasureChest handles visuals itself)
	chest.initialize(position, "big", player, chest_rarity)
	chest.chest_opened.connect(_on_chest_opened)

	# Añadir al mundo (ponerlo en world_manager para que se mueva con chunks si es posible)
	if world_manager and world_manager.has_method("add_child"):
		world_manager.add_child(chest)
		# Ajustar posición global en caso de parent cambiado
		chest.global_position = position
	else:
		var _gt = get_tree()
		if _gt and _gt.current_scene:
			_gt.current_scene.add_child(chest)
			chest.global_position = position
		else:
			add_child(chest)
			chest.global_position = position

	# Registrar en tracking global de cofres para minimizar/cleanup
	all_chests.append(chest)

	# Emitir señal para que otros sistemas (minimap/UI) sepan del cofre
	chest_spawned.emit(chest)

	print("👑 Cofre de boss creado en: ", position, " rarity:", chest_rarity)


func compute_boss_chest_rarity() -> int:
	"""Compute boss chest rarity influenced by SaveManager luck points.
	Return value is an int where higher means rarer (0..4)
	"""
	var luck = 0
	var _gt = get_tree()
	var sm = _gt.root.get_node_or_null("SaveManager") if _gt and _gt.root else null
	if sm and sm.has_method("get_meta_data"):
		var meta = sm.get_meta_data()
		luck = int(meta.get("luck_points", 0))

	# Simple probabilistic boost: luck increases chance of higher rarity
	var roll = randi() % 100
	var threshold_common = max(50 - luck, 10)
	var threshold_uncommon = max(75 - int(luck * 0.8), 30)
	var threshold_rare = max(90 - int(luck * 0.6), 50)
	var threshold_epic = max(97 - int(luck * 0.4), 80)

	if roll < threshold_common:
		return 0
	elif roll < threshold_uncommon:
		return 1
	elif roll < threshold_rare:
		return 2
	elif roll < threshold_epic:
		return 3
	else:
		return 4


func compute_normal_chest_rarity() -> int:
	"""Compute rarity for normal chests, influenced by luck but with lower ceilings than boss chests."""
	var luck = 0
	var _gt = get_tree()
	var sm = _gt.root.get_node_or_null("SaveManager") if _gt and _gt.root else null
	if sm and sm.has_method("get_meta_data"):
		var meta = sm.get_meta_data()
		luck = int(meta.get("luck_points", 0))

	# Simpler roll: normal chests are mostly common/uncommon
	var roll = randi() % 100
	var threshold_common = max(60 - luck, 30)
	var threshold_uncommon = max(85 - int(luck * 0.5), 50)
	var threshold_rare = max(95 - int(luck * 0.3), 70)

	if roll < threshold_common:
		return 0
	elif roll < threshold_uncommon:
		return 1
	elif roll < threshold_rare:
		return 2
	else:
		return 3


func cleanup_distant_chests() -> void:
	"""Limpiar cofres que están muy lejos del player"""
	var chests_to_remove = []
	var max_distance = 2000.0  # Distancia máxima antes de remover

	for chest in all_chests:
		if not is_instance_valid(chest):
			chests_to_remove.append(chest)
			continue
		var distance = chest.global_position.distance_to(player.global_position)
		if distance > max_distance:
			chests_to_remove.append(chest)

	for chest in chests_to_remove:
		if chest in all_chests:
			all_chests.erase(chest)
			if is_instance_valid(chest):
				chest.queue_free()

func get_active_chests() -> Array:
	"""Retornar posiciones y rareza de cofres activos para el minimapa"""
	var out: Array = []
	for chest in all_chests:
		if is_instance_valid(chest):
			var rarity = 0
			if chest.has_meta("rarity"):
				rarity = chest.get_meta("rarity")
			out.append({
				"position": chest.global_position,
				"rarity": rarity
			})
	return out

func get_active_items() -> Array:
	"""Retornar posiciones y rareza de items activos para el minimapa"""
	# Por ahora, retornar lista vacía (items no persistentes en el mundo)
	# Se pueden agregar aquí items dropsados que no son recolectados aún
	return []

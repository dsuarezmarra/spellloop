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
var chest_spawn_chance: float = 0.02  # 2% por chunk

# Configuración de items
var item_types: Dictionary = {}

func _ready():
	print("📦 ItemManager inicializado")
	setup_item_types()

func initialize(player_ref: CharacterBody2D, world_ref: InfiniteWorldManager):
	"""Inicializar sistema de items"""
	player = player_ref
	world_manager = world_ref
	
	# Conectar señales del mundo
	if world_manager.has_signal("chunk_generated"):
		world_manager.chunk_generated.connect(_on_chunk_generated)
	
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
	# Posibilidad de generar cofre en el chunk
	if randf() < chest_spawn_chance:
		spawn_chest_in_chunk(chunk_pos)

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
	chest.initialize(position, chest_type, player)
	chest.chest_opened.connect(_on_chest_opened)
	
	# Añadir al árbol
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
	
	var item_drop = ItemDrop.new()
	item_drop.initialize(position, selected_type, player)
	item_drop.item_collected.connect(_on_item_drop_collected)
	
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

# Clase para cofres del tesoro
class TreasureChest extends Node2D:
	
	signal chest_opened(chest: Node2D, items: Array)
	
	var chest_type: String = "normal"
	var is_opened: bool = false
	var interaction_range: float = 60.0
	
	var sprite: Sprite2D
	var player_ref: CharacterBody2D
	var items_inside: Array = []
	
	func initialize(position: Vector2, type: String, player: CharacterBody2D):
		global_position = position
		chest_type = type
		player_ref = player
		z_index = 35
		
		setup_visual()
		generate_contents()
	
	func setup_visual():
		"""Configurar apariencia del cofre"""
		sprite = Sprite2D.new()
		add_child(sprite)
		
		create_chest_texture()
		
		var scale_factor = 1.0
		if ScaleManager:
			scale_factor = ScaleManager.get_scale()
		sprite.scale = Vector2(scale_factor, scale_factor)
	
	func create_chest_texture():
		"""Crear textura del cofre"""
		var size = 32
		var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
		
		# Cofre marrón simple
		var chest_color = Color(0.6, 0.3, 0.1, 1.0)  # Marrón
		var lock_color = Color.YELLOW
		
		# Cuerpo del cofre
		for x in range(4, size - 4):
			for y in range(8, size - 4):
				image.set_pixel(x, y, chest_color)
		
		# Detalle dorado (cerradura)
		for x in range(size/2 - 2, size/2 + 2):
			for y in range(size/2 - 1, size/2 + 1):
				image.set_pixel(x, y, lock_color)
		
		var texture = ImageTexture.new()
		texture.set_image(image)
		sprite.texture = texture
	
	func generate_contents():
		"""Generar contenido del cofre"""
		var item_count = randi_range(1, 3)  # 1-3 items por cofre
		
		for i in range(item_count):
			var item_type = get_random_chest_item()
			items_inside.append({
				"type": item_type,
				"source": "chest"
			})
	
	func get_random_chest_item() -> String:
		"""Obtener item aleatorio para cofre"""
		var common_items = ["weapon_damage", "weapon_speed", "health_boost", "heal_full"]
		var uncommon_items = ["speed_boost", "new_weapon"]
		
		# 70% común, 30% poco común
		if randf() < 0.7:
			return common_items[randi() % common_items.size()]
		else:
			return uncommon_items[randi() % uncommon_items.size()]
	
	func _process(delta):
		if is_opened or not player_ref:
			return
		
		# Verificar si el player está cerca para abrir
		var distance = global_position.distance_to(player_ref.global_position)
		if distance <= interaction_range:
			open_chest()
	
	func open_chest():
		"""Abrir cofre"""
		if is_opened:
			return
		
		is_opened = true
		
		# Efecto visual de apertura
		create_opening_effect()
		
		# Emitir señal con items
		chest_opened.emit(self, items_inside)
		
		# Remover después de un delay
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = 1.0
		timer.one_shot = true
		timer.timeout.connect(func(): queue_free())
		timer.start()
	
	func create_opening_effect():
		"""Efecto visual de apertura"""
		if sprite:
			var tween = Tween.new()
			add_child(tween)
			
			# Efecto de brillo y escala
			tween.parallel().tween_property(sprite, "modulate", Color(2, 2, 2, 1), 0.3)
			tween.parallel().tween_property(sprite, "scale", sprite.scale * 1.2, 0.3)
			tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0.5), 0.7)

# Clase para drops de items individuales
class ItemDrop extends Node2D:
	
	signal item_collected(item_drop: Node2D, item_type: String)
	
	var item_type: String
	var collection_range: float = 40.0
	var lifetime: float = 60.0
	var life_timer: float = 0.0
	
	var sprite: Sprite2D
	var player_ref: CharacterBody2D
	
	func initialize(position: Vector2, type: String, player: CharacterBody2D):
		global_position = position
		item_type = type
		player_ref = player
		z_index = 45
		
		setup_visual()
	
	func setup_visual():
		"""Configurar apariencia del item"""
		sprite = Sprite2D.new()
		add_child(sprite)
		
		create_item_texture()
		
		var scale_factor = 0.8
		if ScaleManager:
			scale_factor *= ScaleManager.get_scale()
		sprite.scale = Vector2(scale_factor, scale_factor)
		
		# Efecto de flotación
		start_floating_effect()
	
	func create_item_texture():
		"""Crear textura del item"""
		var size = 16
		var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
		
		# Color basado en el tipo de item
		var item_color = Color.WHITE
		match item_type:
			"weapon_damage":
				item_color = Color.RED
			"health_boost":
				item_color = Color.GREEN
			"speed_boost":
				item_color = Color.CYAN
			"new_weapon":
				item_color = Color.PURPLE
		
		# Crear forma de gema
		var center = Vector2(size / 2, size / 2)
		var radius = size / 2 - 2
		
		for x in range(size):
			for y in range(size):
				var pos = Vector2(x, y)
				var distance = pos.distance_to(center)
				
				if distance <= radius:
					var intensity = 1.0 - (distance / radius) * 0.5
					var color = item_color * intensity
					color.a = 0.9
					image.set_pixel(x, y, color)
		
		var texture = ImageTexture.new()
		texture.set_image(image)
		sprite.texture = texture
	
	func start_floating_effect():
		"""Efecto de flotación"""
		var tween = Tween.new()
		add_child(tween)
		
		tween.tween_property(sprite, "position", Vector2(0, -8), 1.5)
		tween.tween_property(sprite, "position", Vector2(0, 8), 1.5)
		tween.set_loops()
	
	func _process(delta):
		life_timer += delta
		
		# Verificar recolección
		if player_ref:
			var distance = global_position.distance_to(player_ref.global_position)
			if distance <= collection_range:
				collect_item()
		
		# Desaparecer después del tiempo de vida
		if life_timer >= lifetime:
			queue_free()
	
	func collect_item():
		"""Recolectar item"""
		item_collected.emit(self, item_type)
		queue_free()
extends Node2D
class_name TreasureChest

signal chest_opened(chest: Node2D, items: Array)

var chest_type: String = "normal"
var chest_rarity: ItemRarity.Type = ItemRarity.Type.NORMAL
var is_opened: bool = false
var interaction_range: float = 60.0

var sprite: Sprite2D
var player_ref: CharacterBody2D
var items_inside: Array = []

func initialize(position: Vector2, type: String, player: CharacterBody2D, rarity: ItemRarity.Type = ItemRarity.Type.NORMAL):
	global_position = position
	chest_type = type
	chest_rarity = rarity
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
	"""Crear textura del cofre con color de rareza"""
	var size = 32
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Color base del cofre según rareza
	var chest_color = Color(0.6, 0.3, 0.1, 1.0)  # Marrón base
	var rarity_color = ItemRarity.get_color(chest_rarity)
	var lock_color = rarity_color
	
	# Cuerpo del cofre
	for x in range(4, size - 4):
		for y in range(8, size - 4):
			image.set_pixel(x, y, chest_color)
	
	# Borde de rareza
	for x in range(3, size - 3):
		for y in range(7, 9):  # Borde superior
			image.set_pixel(x, y, rarity_color)
		for y in range(size - 5, size - 3):  # Borde inferior
			image.set_pixel(x, y, rarity_color)
	
	# Bordes laterales
	for y in range(7, size - 3):
		image.set_pixel(3, y, rarity_color)  # Izquierda
		image.set_pixel(size - 4, y, rarity_color)  # Derecha
	
	# Detalle central (cerradura) con color de rareza
	for x in range(size/2 - 2, size/2 + 2):
		for y in range(size/2 - 1, size/2 + 1):
			image.set_pixel(x, y, lock_color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture

func generate_contents():
	"""Generar contenido del cofre basado en rareza"""
	# Más items en cofres de mayor rareza
	var item_count = 1
	match chest_rarity:
		ItemRarity.Type.NORMAL:
			item_count = randi_range(1, 2)
		ItemRarity.Type.COMMON:
			item_count = randi_range(2, 3)
		ItemRarity.Type.RARE:
			item_count = randi_range(3, 4)
		ItemRarity.Type.LEGENDARY:
			item_count = randi_range(4, 5)
	
	for i in range(item_count):
		var item_type = get_random_chest_item()
		var item_rarity = get_item_rarity_for_chest()
		items_inside.append({
			"type": item_type,
			"rarity": item_rarity,
			"source": "chest"
		})

func get_item_rarity_for_chest() -> ItemRarity.Type:
	"""Obtener rareza de item basada en rareza del cofre"""
	match chest_rarity:
		ItemRarity.Type.NORMAL:
			return ItemRarity.Type.NORMAL if randf() < 0.8 else ItemRarity.Type.COMMON
		ItemRarity.Type.COMMON:
			return ItemRarity.Type.COMMON if randf() < 0.7 else ItemRarity.Type.RARE
		ItemRarity.Type.RARE:
			return ItemRarity.Type.RARE if randf() < 0.6 else ItemRarity.Type.LEGENDARY
		ItemRarity.Type.LEGENDARY:
			return ItemRarity.Type.LEGENDARY  # Siempre legendario
	
	return ItemRarity.Type.NORMAL

func get_random_chest_item() -> String:
	"""Obtener item aleatorio para cofre"""
	var item_types = [
		"weapon_damage", "weapon_speed", "health_boost", 
		"speed_boost", "new_weapon", "heal_full",
		"shield_boost", "crit_chance", "mana_boost"
	]
	return item_types[randi() % item_types.size()]

func _process(delta):
	if is_opened or not player_ref:
		return
	
	# Verificar si el player está cerca para activar el popup
	var distance = global_position.distance_to(player_ref.global_position)
	if distance <= interaction_range:
		trigger_chest_interaction()

func trigger_chest_interaction():
	"""Activar interacción con cofre - mostrar popup"""
	if is_opened:
		return
	
	# Pausar el juego
	get_tree().paused = true
	
	# Crear popup de selección
	create_chest_popup()

func create_chest_popup():
	"""Crear popup de selección de mejoras"""
	var popup = preload("res://scenes/ui/ChestPopup.tscn")
	if not popup:
		# Si no existe la escena, crear popup dinámicamente
		create_dynamic_popup()
		return
	
	var popup_instance = popup.instantiate()
	get_tree().current_scene.add_child(popup_instance)
	popup_instance.setup_items(items_inside)
	popup_instance.item_selected.connect(_on_popup_item_selected)

func create_dynamic_popup():
	"""Crear popup dinámicamente si no existe la escena"""
	var popup = ChestSelectionPopup.new()
	get_tree().current_scene.add_child(popup)
	popup.setup_chest(self, items_inside)
	popup.item_selected.connect(_on_popup_item_selected)

func _on_popup_item_selected(selected_item: Dictionary):
	"""Manejar selección de item del popup"""
	is_opened = true
	
	# Reanudar el juego
	get_tree().paused = false
	
	# Efecto visual de apertura
	create_opening_effect()
	
	# Emitir señal solo con el item seleccionado
	chest_opened.emit(self, [selected_item])
	
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
		var tween = create_tween()
		
		# Efecto de brillo y escala
		tween.parallel().tween_property(sprite, "modulate", Color(2, 2, 2, 1), 0.3)
		tween.parallel().tween_property(sprite, "scale", sprite.scale * 1.2, 0.3)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0.5), 0.7)
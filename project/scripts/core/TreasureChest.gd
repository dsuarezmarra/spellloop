extends Node2D
class_name TreasureChest

signal chest_opened(chest: Node2D, items: Array)

var chest_type: String = "normal"
var chest_rarity: int = 0  # ItemsDefinitions.ItemRarity.WHITE
var is_opened: bool = false
var interaction_range: float = 60.0
var popup_shown: bool = false  # Control para evitar múltiples popups

var sprite: Sprite2D
var player_ref: CharacterBody2D
var items_inside: Array = []

func initialize(chest_position: Vector2, type: String, player: CharacterBody2D, rarity: int = 0):
	global_position = chest_position
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
	var rarity_color = ItemsDefinitions.get_rarity_color(chest_rarity)
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
	for x in range(int(size/2.0) - 2, int(size/2.0) + 2):
		for y in range(int(size/2.0) - 1, int(size/2.0) + 1):
			image.set_pixel(x, y, lock_color)
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture

func generate_contents():
	"""Generar contenido del cofre basado en rareza"""
	# Más items en cofres de mayor rareza
	var item_count = 1
	match chest_rarity:
		ItemsDefinitions.ItemRarity.WHITE:
			item_count = randi_range(1, 2)
		ItemsDefinitions.ItemRarity.BLUE:
			item_count = randi_range(2, 3)
		ItemsDefinitions.ItemRarity.YELLOW:
			item_count = randi_range(3, 4)
		ItemsDefinitions.ItemRarity.ORANGE:
			item_count = randi_range(4, 5)
	
	for i in range(item_count):
		var item_type = get_random_chest_item()
		var item_rarity = get_item_rarity_for_chest()
		items_inside.append({
			"type": item_type,
			"rarity": item_rarity,
			"source": "chest"
		})

func get_item_rarity_for_chest() -> int:
	"""Obtener rareza de item basada en rareza del cofre"""
	match chest_rarity:
		ItemsDefinitions.ItemRarity.WHITE:
			return ItemsDefinitions.ItemRarity.WHITE if randf() < 0.8 else ItemsDefinitions.ItemRarity.BLUE
		ItemsDefinitions.ItemRarity.BLUE:
			return ItemsDefinitions.ItemRarity.BLUE if randf() < 0.7 else ItemsDefinitions.ItemRarity.YELLOW
		ItemsDefinitions.ItemRarity.YELLOW:
			return ItemsDefinitions.ItemRarity.YELLOW if randf() < 0.6 else ItemsDefinitions.ItemRarity.ORANGE
		ItemsDefinitions.ItemRarity.ORANGE:
			return ItemsDefinitions.ItemRarity.ORANGE  # Siempre legendario
	
	return ItemsDefinitions.ItemRarity.WHITE

func get_random_chest_item() -> String:
	"""Obtener item aleatorio para cofre"""
	var item_types = [
		"weapon_damage", "weapon_speed", "health_boost", 
		"speed_boost", "new_weapon", "heal_full",
		"shield_boost", "crit_chance", "mana_boost"
	]
	return item_types[randi() % item_types.size()]

func _process(_delta):
	if is_opened or not player_ref or popup_shown:
		return
	
	# Verificar si el player está cerca para activar el popup
	var distance = global_position.distance_to(player_ref.global_position)
	if distance <= interaction_range:
		print("[TreasureChest] ¡COFRE TOCADO! Distancia: ", distance)
		popup_shown = true  # Marcar que ya se mostró el popup
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
	print("[TreasureChest] Intentando crear popup...")
	
	# Usar popup simple directo en lugar de escena
	var popup_instance = SimpleChestPopup.new()
	print("[TreasureChest] SimpleChestPopup instanciado")
	
	get_tree().current_scene.add_child(popup_instance)
	print("[TreasureChest] Popup añadido a escena")
	
	# Preparar items con información completa
	var items_with_names = []
	for item in items_inside:
		var item_display = item.duplicate()
		if not item_display.has("name"):
			item_display["name"] = item.get("type", "Unknown Item")
		items_with_names.append(item_display)
	
	popup_instance.setup_items(items_with_names)
	print("[TreasureChest] Items configurados en popup")
	popup_instance.item_selected.connect(_on_popup_item_selected)
	print("[TreasureChest] Señal conectada a _on_popup_item_selected")

func _on_popup_item_selected(selected_item: Dictionary):
	"""Manejar selección de item del popup"""
	print("[TreasureChest] ¡¡¡ CALLBACK RECIBIDO !!! Item: ", selected_item)
	is_opened = true
	
	# Efecto visual de apertura
	create_opening_effect()
	
	# Emitir señal solo con el item seleccionado
	chest_opened.emit(self, [selected_item])
	print("[TreasureChest] Señal chest_opened emitida")
	
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

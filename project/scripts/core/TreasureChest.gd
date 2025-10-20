extends Node2D
class_name TreasureChest

signal chest_opened(chest: Node2D, items: Array)

var chest_type: String = "normal"
var chest_rarity: int = 0  # ItemsDefinitions.ItemRarity.WHITE (numeric fallback)
var is_opened: bool = false
var interaction_range: float = 60.0
var popup_shown: bool = false  # Control para evitar múltiples popups

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_area: Area2D = $InteractionArea
var player_ref: CharacterBody2D
var items_inside: Array = []
var aura: Node2D

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
	var scale_manager = null
	if get_tree() and get_tree().root and get_tree().root.get_node_or_null("ScaleManager"):
		scale_manager = get_tree().root.get_node("ScaleManager")
	if scale_manager and scale_manager.has_method("get_scale"):
		scale_factor = scale_manager.get_scale()
	sprite.scale = Vector2(scale_factor, scale_factor)
	
	# ✨ Agregar aura dorada al cofre (protegido en caso de recursos faltantes)
	var AuraClass = load("res://scripts/effects/AuraEffect.gd")
	if AuraClass:
		aura = AuraClass.new()
		if aura:
			add_child(aura)
			if aura.has_method("initialize"):
				aura.initialize(sprite, chest_rarity, true)  # true = usar color dorado

			# Aplicar configuración protegida
			var AuraConfig = load("res://scripts/effects/AuraConfiguration.gd")
			if AuraConfig and AuraConfig.has("CHEST_AURA_RADIUS") == false:
				pass
			if AuraConfig and aura:
				if AuraConfig.has("CHEST_AURA_RADIUS"):
					aura.set_aura_radius(AuraConfig.CHEST_AURA_RADIUS)
				if AuraConfig.has("CHEST_PULSE_INTENSITY"):
					aura.set_pulse_intensity(AuraConfig.CHEST_PULSE_INTENSITY)

func create_chest_texture():
	"""Crear textura del cofre con color de rareza"""
	var size = 32
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Color base del cofre según rareza
	var chest_color = Color(0.6, 0.3, 0.1, 1.0)  # Marrón base
	var rarity_color = Color(1,1,1)
	var items_defs = null
	if get_tree() and get_tree().root and get_tree().root.get_node_or_null("ItemsDefinitions"):
		items_defs = get_tree().root.get_node("ItemsDefinitions")
	if items_defs and items_defs.has_method("get_rarity_color"):
		rarity_color = items_defs.get_rarity_color(chest_rarity)
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
	"""Generar contenido del cofre basado en rareza - SOLO 3 ITEMS PARA POPUP"""
	# SIEMPRE generar exactamente 3 items para el popup
	var item_count = 3
	# Intentar usar ItemsDefinitions con modificador de suerte si está disponible
	var items_defs = null
	if get_tree() and get_tree().root and get_tree().root.get_node_or_null("ItemsDefinitions"):
		items_defs = get_tree().root.get_node("ItemsDefinitions")

	# Obtener modificador de suerte desde SaveManager (user://meta.json) - asunción: cada punto de luck = +2% prob
	var luck_modifier = 1.0
	if get_tree() and get_tree().root and get_tree().root.get_node_or_null("SaveManager"):
		var sm = get_tree().root.get_node("SaveManager")
		var meta = sm.get_meta_data() if sm.has_method("get_meta_data") else {}
		var luck_points = 0
		if meta and meta.has("luck_points"):
			luck_points = int(meta["luck_points"])
		luck_modifier = 1.0 + (luck_points * 0.02)

	for i in range(item_count):
		var chosen_item = null
		# Intentar usar la función de ItemsDefinitions que respeta luck_modifier
		if items_defs and items_defs.has_method("get_weighted_random_item"):
			var player_level = 1
			# Intentar leer nivel del player vía ExperienceManager autoload si existe
			if get_tree() and get_tree().root and get_tree().root.get_node_or_null("ExperienceManager"):
				var em = get_tree().root.get_node("ExperienceManager")
				if em and em.has("current_level"):
					player_level = int(em.current_level)
			chosen_item = items_defs.get_weighted_random_item(player_level, luck_modifier)
			if chosen_item and typeof(chosen_item) == TYPE_DICTIONARY and chosen_item.has("id"):
				var item_id = chosen_item.id
				var item_rarity_local = int(chosen_item.rarity) if chosen_item.has("rarity") else get_item_rarity_for_chest()
				items_inside.append({"type": item_id, "rarity": item_rarity_local, "source": "chest"})
				continue

		# Fallback al método anterior simple
		var item_type = get_random_chest_item()
		var item_rarity = get_item_rarity_for_chest()
		items_inside.append({
			"type": item_type,
			"rarity": item_rarity,
			"source": "chest"
		})
	
	print("[TreasureChest] Contenido del cofre generado: ", items_inside.size(), " items")

func get_item_rarity_for_chest() -> int:
	"""Obtener rareza de item con progresión temporal (cada 5 minutos)"""
	# Obtener minutos transcurridos desde GameManager
	var minutes_elapsed = 0
	var game_manager = null
	if get_tree() and get_tree().root and get_tree().root.get_node_or_null("GameManager"):
		game_manager = get_tree().root.get_node("GameManager")
	if game_manager and game_manager.has_method("get_elapsed_minutes"):
		minutes_elapsed = game_manager.get_elapsed_minutes()
	
	# Calcular "ronda" de dificultad (cada 5 minutos = 1 ronda)
	var difficulty_round = minutes_elapsed / 5.0
	
	print("[TreasureChest] Rareza calculada - Minutos: ", minutes_elapsed, " Ronda: ", difficulty_round)
	
	# TABLA DE PROGRESIÓN DE RAREZA POR RONDA (cada 5 minutos)
	#
	# Ronda 0 (0-4 min):   80% Blanco,      20% Azul
	# Ronda 1 (5-9 min):   60% Blanco,      30% Azul,       10% Amarillo
	# Ronda 2 (10-14 min): 40% Blanco,      40% Azul,       20% Amarillo
	# Ronda 3 (15-19 min): 20% Blanco,      50% Azul,       25% Amarillo, 5% Naranja
	# Ronda 4+ (20+ min):  10% Blanco,      40% Azul,       40% Amarillo, 10% Naranja
	
	var rand_value = randf()
	var rarity = 0
	var items_defs2 = null
	if get_tree() and get_tree().root and get_tree().root.get_node_or_null("ItemsDefinitions"):
		items_defs2 = get_tree().root.get_node("ItemsDefinitions")
	if items_defs2 and items_defs2.has("ItemRarity"):
		rarity = items_defs2.ItemRarity.WHITE
	
	# Use numeric enum values to avoid compile-time autoload dependency
	# ItemRarity: 0=WHITE, 1=BLUE, 2=YELLOW, 3=ORANGE, 4=PURPLE
	match difficulty_round:
		0:  # 0-4 minutos
			if rand_value < 0.80:
				rarity = 0
			else:
				rarity = 1
		
		1:  # 5-9 minutos
			if rand_value < 0.60:
				rarity = 0
			elif rand_value < 0.90:
				rarity = 1
			else:
				rarity = 2
		
		2:  # 10-14 minutos
			if rand_value < 0.40:
				rarity = 0
			elif rand_value < 0.80:
				rarity = 1
			else:
				rarity = 2
		
		3:  # 15-19 minutos
			if rand_value < 0.20:
				rarity = 0
			elif rand_value < 0.70:
				rarity = 1
			elif rand_value < 0.95:
				rarity = 2
			else:
				rarity = 3
		
		_:  # 20+ minutos
			if rand_value < 0.10:
				rarity = 0
			elif rand_value < 0.50:
				rarity = 1
			elif rand_value < 0.90:
				rarity = 2
			else:
				rarity = 3
	
	print("[TreasureChest] Rareza seleccionada: ", rarity, " (Ronda: ", difficulty_round, ")")
	return rarity

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
	if not is_instance_valid(player_ref):
		return
	var distance = global_position.distance_to(player_ref.global_position)
	if distance <= interaction_range:
		print("[TreasureChest] ¡COFRE TOCADO! Distancia: ", distance)
		popup_shown = true  # Marcar que ya se mostró el popup
		trigger_chest_interaction()

func _ready():
	# Conectar área de interacción
	if is_instance_valid(interaction_area) and interaction_area.has_signal("body_entered"):
		interaction_area.body_entered.connect(func(body):
			if body and body.has_method("get_hp"):
				player_ref = body
				trigger_chest_interaction()
		)

func trigger_chest_interaction():
	"""Activar interacción con cofre - mostrar popup"""
	if is_opened:
		return
	
	# Pausar el juego
	get_tree().paused = true
	
	# Crear popup de selección
	create_chest_popup()

func create_chest_popup():
	"""Crear popup de selección de mejoras - CON 3 ITEMS ALEATORIOS"""
	print("[TreasureChest] Intentando crear popup...")
	
	# Usar popup simple directo en lugar de escena
	var popup_instance = SimpleChestPopup.new()
	print("[TreasureChest] SimpleChestPopup instanciado")
	
	get_tree().current_scene.add_child(popup_instance)
	print("[TreasureChest] Popup añadido a escena - layer 100")
	
	# Preparar items con información completa (los 3 items del cofre)
	var items_with_names = []
	for i in range(items_inside.size()):
		var item = items_inside[i]
		var item_display = item.duplicate()
		
		# Obtener nombre legible del item
		var item_type = item.get("type", "Unknown")
		var item_name = get_item_display_name(item_type)
		var rarity_name = get_rarity_name(item.get("rarity", 0))
		
		item_display["name"] = "%s (%s)" % [item_name, rarity_name]
		items_with_names.append(item_display)
		
		print("[TreasureChest] Item %d - Type: %s, Name: %s, Rarity: %s" % [i + 1, item_type, item_name, rarity_name])
	
	popup_instance.setup_items(items_with_names)
	print("[TreasureChest] Items configurados en popup (%d items)" % items_with_names.size())
	popup_instance.item_selected.connect(_on_popup_item_selected)
	print("[TreasureChest] Señal conectada a _on_popup_item_selected")

func get_item_display_name(item_type: String) -> String:
	"""Obtener nombre legible del item"""
	match item_type:
		"weapon_damage": return "⚡ Poder de Arma"
		"weapon_speed": return "💫 Velocidad de Ataque"
		"health_boost": return "❤️ Poción de Vida"
		"speed_boost": return "🏃 Rapidez"
		"new_weapon": return "🗡️ Nueva Arma"
		"heal_full": return "💚 Curación Total"
		"shield_boost": return "🛡️ Escudo"
		"crit_chance": return "💥 Golpe Crítico"
		"mana_boost": return "🔮 Maná"
		_: return "🎁 %s" % item_type

func get_rarity_name(rarity: int) -> String:
	"""Obtener nombre legible de la rareza"""
	# Rarity mapping: 0=WHITE, 1=BLUE, 2=YELLOW, 3=ORANGE, 4=PURPLE
	match rarity:
		0: return "Normal"
		1: return "Raro"
		2: return "Épico"
		3: return "Legendario"
		4: return "Único"
		_: return "?"

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


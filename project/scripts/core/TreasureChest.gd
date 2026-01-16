extends Node2D
class_name TreasureChest

signal chest_opened(chest: Node2D, items: Array)

enum ChestType {
	NORMAL,
	ELITE,
	BOSS,
	WEAPON
}

var chest_type: int = ChestType.NORMAL
var chest_rarity: int = 0  # ItemsDefinitions.ItemRarity.WHITE (numeric fallback)
var is_opened: bool = false
var interaction_range: float = 60.0
var popup_shown: bool = false  # Control para evitar múltiples popups

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_area: Area2D = $InteractionArea
var player_ref: CharacterBody2D
var items_inside: Array = []
var aura: Node2D

func initialize(chest_position: Vector2, type: int, player: CharacterBody2D, rarity: int = -1):
	global_position = chest_position
	chest_type = type
	player_ref = player
	z_index = 35
	
	# Determinar rareza si no se especifica (-1)
	if rarity == -1:
		match chest_type:
			ChestType.BOSS:
				chest_rarity = 3 # Legendario
			ChestType.ELITE:
				chest_rarity = 1 # Raro mínimo
			_:
				# Probabilidad base para cofres normales
				var roll = randf()
				if roll < 0.6:
					chest_rarity = 0 # Common
				elif roll < 0.9:
					chest_rarity = 1 # Uncommon
				else:
					chest_rarity = 2 # Rare
	else:
		chest_rarity = rarity
	
	setup_visual()
	generate_contents()

func setup_visual():
	"""Configurar apariencia del cofre"""
	sprite = Sprite2D.new()
	add_child(sprite)
	
	create_chest_texture()
	
	var scale_factor = 1.0
	# Escala según tipo
	match chest_type:
		ChestType.BOSS: scale_factor = 1.3
		ChestType.ELITE: scale_factor = 1.15
	
	var scale_manager = null
	if get_tree() and get_tree().root and get_tree().root.get_node_or_null("ScaleManager"):
		scale_manager = get_tree().root.get_node("ScaleManager")
	if scale_manager and scale_manager.has_method("get_scale"):
		scale_factor *= scale_manager.get_scale()
	sprite.scale = Vector2(scale_factor, scale_factor)
	
	# ✨ Agregar aura dorada al cofre
	var AuraClass = load("res://scripts/effects/AuraEffect.gd")
	if AuraClass:
		aura = AuraClass.new()
		if aura:
			add_child(aura)
			var use_gold = chest_type == ChestType.BOSS or chest_rarity >= 3
			if aura.has_method("initialize"):
				aura.initialize(sprite, chest_rarity, use_gold)

			# Aplicar configuración protegida
			var AuraConfig = load("res://scripts/effects/AuraConfiguration.gd")
			if AuraConfig and aura:
				var radius = AuraConfig.gate("CHEST_AURA_RADIUS") if AuraConfig.has_method("gate") else 64.0
				if AuraConfig.has("CHEST_AURA_RADIUS"): radius = AuraConfig.CHEST_AURA_RADIUS
				
				# Boss chest aura mas grande
				if chest_type == ChestType.BOSS:
					radius *= 1.5
				
				if aura.has_method("set_aura_radius"):
					aura.set_aura_radius(radius)

func create_chest_texture():
	"""Crear textura del cofre con color de rareza"""
	var size = 32
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	# Color base del cofre según tipo
	var chest_color = Color(0.6, 0.3, 0.1, 1.0)  # Marrón base
	match chest_type:
		ChestType.ELITE: chest_color = Color(0.7, 0.6, 0.2) # Dorado osc
		ChestType.BOSS: chest_color = Color(0.4, 0.1, 0.6) # Purpura oscuro
		ChestType.WEAPON: chest_color = Color(0.5, 0.1, 0.1) # Rojo oscuro
	
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
	"""Generar contenido del cofre usando LootManager"""
	
	# Usar LootManager si está disponible
	if ClassDB.class_exists("LootManager") or ResourceLoader.exists("res://scripts/managers/LootManager.gd"):
		var loot_class = load("res://scripts/managers/LootManager.gd")
		if loot_class:
			# Calcular modificador de suerte
			var luck_modifier = 1.0
			var sm = get_tree().root.get_node_or_null("SaveManager") if get_tree() and get_tree().root else null
			if sm and sm.has_method("get_meta_data"):
				var meta = sm.get_meta_data()
				var luck_points = int(meta.get("luck_points", 0))
				luck_modifier = 1.0 + (luck_points * 0.02)
			
			# Contexto para fusiones (AttackManager)
			var context = null
			if player_ref:
				if "attack_manager" in player_ref:
					context = player_ref.attack_manager
				elif player_ref.has_node("AttackManager"):
					context = player_ref.get_node("AttackManager")
				
			items_inside = loot_class.get_chest_loot(chest_type, luck_modifier, context)
			
			# Fallback si LootManager devuelve vacío
			if items_inside.size() == 0:
				items_inside.append(loot_class._generate_gold_loot(chest_type, 1.0))
			return

	# Fallback legacy si no existe LootManager (para evitar crash)
	items_inside.append({
		"type": "gold",
		"id": "gold_bag_legacy",
		"name": "Bolsa de Oro",
		"amount": 100,
		"rarity": 1,
		"icon": "💰"
	})

func get_random_chest_item() -> String:
	var item_types = [
		"weapon_damage", "weapon_speed", "health_boost", 
		"speed_boost", "new_weapon", "heal_full",
		"shield_boost", "crit_chance", "mana_boost"
	]
	return item_types[randi() % item_types.size()]

func _process(_delta):
	if is_opened or not player_ref or popup_shown:
		return
	
	if not is_instance_valid(player_ref):
		return
	var distance = global_position.distance_to(player_ref.global_position)
	if distance <= interaction_range:
		popup_shown = true
		trigger_chest_interaction()

func _ready():
	if is_instance_valid(interaction_area) and interaction_area.has_signal("body_entered"):
		interaction_area.body_entered.connect(func(body):
			if body and body.has_method("get_hp"):
				player_ref = body
				trigger_chest_interaction()
		)

func trigger_chest_interaction():
	if is_opened: return
	get_tree().paused = true
	create_chest_popup()

func create_chest_popup():
	var popup_instance = SimpleChestPopup.new()
	get_tree().current_scene.add_child(popup_instance)
	
	var items_with_names = []
	for i in range(items_inside.size()):
		var item = items_inside[i]
		var item_display = item.duplicate()
		var item_type = item.get("type", "Unknown")
		var item_name = item.get("name", "")
		# Fallback name logic if internal name is not display-friendly
		if item_name == "":
			item_name = get_item_display_name(item_type)
			
		var rarity_name = get_rarity_name(item.get("rarity", 0))
		item_display["name"] = "%s (%s)" % [item_name, rarity_name]
		items_with_names.append(item_display)
	
	# Determinar modo Jackpot vs Selección
	if items_with_names.size() > 1:
		# Modo Jackpot / Fusión: Mostrar todos y reclamar todos
		popup_instance.show_as_jackpot(items_with_names)
		popup_instance.all_items_claimed.connect(_on_jackpot_claimed)
	else:
		# Modo normal: Selección (o solo 1 item)
		popup_instance.setup_items(items_with_names)
		popup_instance.item_selected.connect(_on_popup_item_selected)

func get_item_display_name(item_type: String) -> String:
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
	match rarity:
		0: return "Normal"
		1: return "Raro"
		2: return "Épico"
		3: return "Legendario"
		4: return "Único"
		_: return "?"

func _on_popup_item_selected(selected_item: Dictionary):
	# Reconstruir el item original (quitando el nombre visual si es necesario) o pasarlo tal cual
	# AttackManager/Game espera el formato de LootManager.
	# SimpleChestPopup devuelve el item con 'name' modificado, pero la data importante (id, type) persiste.
	
	_finalize_opening([selected_item])

func _on_jackpot_claimed(items: Array):
	# Reclamar todos los items
	_finalize_opening(items)

func _finalize_opening(items: Array):
	is_opened = true
	create_opening_effect()
	
	# Emitir señal con los items originales (hacemos match por índice si es necesario, 
	# pero como items_inside no cambia, podemos confiar en el orden o usar items)
	# Nota: items viene del popup, que tiene nombres modificados. 
	# Mejor usar items_inside si es reclamar todo, o buscar el seleccionado.
	# Para simplificar, pasamos los items del popup que tienen la data base.
	
	chest_opened.emit(self, items)
	
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(func(): queue_free())
	timer.start()

func create_opening_effect():
	if sprite:
		var tween = create_tween()
		tween.parallel().tween_property(sprite, "modulate", Color(2, 2, 2, 1), 0.3)
		tween.parallel().tween_property(sprite, "scale", sprite.scale * 1.2, 0.3)
		tween.tween_property(sprite, "modulate", Color(1, 1, 1, 0.5), 0.7)

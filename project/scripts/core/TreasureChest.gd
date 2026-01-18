extends Node2D
class_name TreasureChest

signal chest_opened(chest: Node2D, items: Array)

enum ChestType {
	NORMAL,
	ELITE,
	BOSS,
	WEAPON,
	SHOP  # Cofres tipo tienda que aparecen en el mapa
}

const TIER_COLORS = {
	0: Color(0.7, 0.7, 0.7),      # Gris (Común)
	1: Color(0.3, 0.7, 0.3),      # Verde (Poco común)
	2: Color(0.3, 0.5, 0.9),      # Azul (Raro)
	3: Color(0.7, 0.3, 0.9),      # Púrpura (Épico)
	4: Color(1.0, 0.7, 0.2)       # Dorado (Legendario)
}

var chest_type: int = ChestType.NORMAL
var chest_rarity: int = 0  # ItemsDefinitions.ItemRarity.WHITE (numeric fallback)
var is_opened: bool = false
var interaction_range: float = 60.0
var popup_shown: bool = false  # Control para evitar múltiples popups

# Variables específicas para SHOP chests
var is_shop_chest: bool = false
var shop_tier: int = 1
var shop_game_time: float = 0.0

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

func initialize_as_shop(chest_position: Vector2, player: CharacterBody2D, tier: int, game_time: float):
	"""Inicializar como cofre tipo tienda"""
	global_position = chest_position
	chest_type = ChestType.SHOP
	player_ref = player
	is_shop_chest = true
	shop_tier = tier
	shop_game_time = game_time
	z_index = 35
	chest_rarity = tier  # Rareza visual = tier
	
	setup_visual()
	# No llamar generate_contents - se genera al abrir con ShopChestPopup

func setup_visual():
	"""Configurar apariencia del cofre usando spritesheets"""
	sprite = Sprite2D.new()
	add_child(sprite)
	
	# Determinar textura según rareza
	var tex_name = "chest_common"
	match chest_rarity:
		0: tex_name = "chest_common"
		1: tex_name = "chest_rare"
		2: tex_name = "chest_epic"
		3: tex_name = "chest_legendary"
		4: tex_name = "chest_unique"
	
	# Mapeos especiales
	if chest_type == ChestType.BOSS: tex_name = "chest_legendary"
	if chest_type == ChestType.WEAPON: tex_name = "chest_rare"
	
	var path = "res://assets/treasure_chests/%s.png" % tex_name
	
	# Cargar textura o fallback
	if ResourceLoader.exists(path):
		var tex = load(path)
		sprite.texture = tex
		sprite.hframes = 4 # Spritesheet de 4 frames (Bouncing)
		sprite.offset = Vector2(0, -16) # Ajuste de pivote
	else:
		create_chest_texture()
	
	# Ajuste de tamaño (Request de usuario: reducir a la mitad porque se ven enormes)
	var scale_factor = 0.5
	
	# Escala según tipo
	match chest_type:
		ChestType.BOSS: scale_factor *= 1.3
		ChestType.ELITE: scale_factor *= 1.15
	
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
	# Eliminado ItemsDefinitions (Dead Code)
	if TIER_COLORS.has(chest_rarity):
		rarity_color = TIER_COLORS[chest_rarity]
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

# Variables de animación
var _anim_timer: float = 0.0
const ANIM_FRAME_TIME: float = 0.15

func _process(delta):
	# Animación Bouncing (solo si está cerrado y no pausado)
	if not is_opened and sprite and sprite.hframes > 1 and not get_tree().paused:
		_anim_timer += delta
		if _anim_timer >= ANIM_FRAME_TIME:
			_anim_timer = 0.0
			sprite.frame = (sprite.frame + 1) % sprite.hframes

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
	# Si es cofre tipo SHOP, usar ShopChestPopup
	if is_shop_chest:
		_create_shop_popup()
		return
	
	# Popup normal para otros tipos
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
		if popup_instance.has_signal("skipped"):
			popup_instance.skipped.connect(_on_chest_skipped)

func _on_chest_skipped():
	"""Callback cuando se salta el cofre"""
	is_opened = true
	create_opening_effect()
	
	# No aplicamos items
	print("[TreasureChest] Cofre saltado (Skip usado)")
	chest_opened.emit(self, []) # Lista vacía indica skip
	
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0
	timer.one_shot = true
	timer.timeout.connect(func(): queue_free())
	timer.start()

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
	
	# APLICAR ITEMS AL JUGADOR (CRÍTICO: Esto faltaba para cofres normales)
	for item in items:
		_apply_item(item)
	
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

# ═══════════════════════════════════════════════════════════════════════════════
# SHOP CHEST POPUP
# ═══════════════════════════════════════════════════════════════════════════════

func _create_shop_popup():
	"""Crear popup de tienda para cofre SHOP"""
	# Obtener monedas del jugador
	var player_coins = 0
	var exp_mgr = get_tree().current_scene.get_node_or_null("ExperienceManager")
	if exp_mgr and "total_coins" in exp_mgr:
		player_coins = exp_mgr.total_coins
	elif player_ref and "coins" in player_ref:
		player_coins = player_ref.coins
	
	# Generar items con precios
	var luck = 1.0
	if player_ref and player_ref.has_method("get_luck"):
		luck = player_ref.get_luck()
	
	# Restaurar declaración de game_time_minutes
	var game_time_minutes = shop_game_time / 60.0
	
	# Mapear shop_tier a ChestType de LootManager
	var loot_chest_type = LootManager.ChestType.NORMAL
	if shop_tier >= 3:
		loot_chest_type = LootManager.ChestType.BOSS
	elif shop_tier == 2:
		loot_chest_type = LootManager.ChestType.ELITE
		
	# Calcular cantidad de items (1-3 + bonus por tiempo)
	var count = clampi(2 + int(game_time_minutes / 5.0), 2, 5)
	
	items_inside = LootManager.get_random_shop_loot(loot_chest_type, count, luck)
	
	if items_inside.is_empty():
		# Fallback: generar al menos un item
		items_inside.append({
			"type": "gold",
			"id": "gold_bag",
			"name": "Bolsa de Oro",
			"description": "+50 monedas",
			"icon": "💰",
			"tier": 1,
			"price": 25,
			"original_price": 25,
			"discount_percent": 0
		})
	
	# Crear popup
	var popup = ShopChestPopup.new()
	get_tree().current_scene.add_child(popup)
	popup.setup_shop(items_inside, player_coins)
	
	# Conectar señales
	popup.item_purchased.connect(_on_shop_item_purchased)
	popup.popup_closed.connect(_on_shop_popup_closed)

func _on_shop_item_purchased(item: Dictionary, price: int):
	"""Callback cuando se compra un item de la tienda"""
	# Descontar monedas
	var exp_mgr = get_tree().current_scene.get_node_or_null("ExperienceManager")
	if exp_mgr and exp_mgr.has_method("spend_coins"):
		exp_mgr.spend_coins(price)
	elif exp_mgr and "total_coins" in exp_mgr:
		exp_mgr.total_coins -= price
	
	# Aplicar item al jugador
	_apply_item(item)
	
	# Finalizar apertura
	is_opened = true
	create_opening_effect()
	chest_opened.emit(self, [item])
	
	# Destruir cofre después de un delay
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _on_shop_popup_closed(purchased: bool):
	"""Callback cuando se cierra el popup de tienda"""
	is_opened = true
	
	if not purchased:
		# No compró nada, igual destruir
		create_opening_effect()
	
	# Destruir cofre
	await get_tree().create_timer(0.5).timeout
	queue_free()

	# Destruir cofre
	await get_tree().create_timer(0.5).timeout
	queue_free()

func _apply_item(item: Dictionary):
	"""Aplicar item al jugador (usado tanto para compras como para loot normal)"""
	var item_type = item.get("type", "")
	var item_id = item.get("id", "")
	
	match item_type:
		"weapon":
			# Añadir arma usando AttackManager (el sistema correcto de armas)
			# AttackManager.add_weapon_by_id crea un BaseWeapon con comportamiento completo
			print("[TreasureChest] Intentando añadir arma: %s" % item_id)
			var result = false
			
			# Buscar AttackManager por grupo (más robusto que player_ref.attack_manager)
			var attack_mgr = get_tree().get_first_node_in_group("attack_manager")
			print("[TreasureChest] DEBUG: attack_mgr = %s" % attack_mgr)
			
			if attack_mgr and attack_mgr.has_method("add_weapon_by_id"):
				result = attack_mgr.add_weapon_by_id(item_id)
				print("[TreasureChest] ✅ Arma añadida via AttackManager: %s" % result)
			else:
				push_error("[TreasureChest] No se pudo añadir arma: attack_manager=%s" % attack_mgr)
			
			if not result:
				print("[TreasureChest] ❌ Falló añadir arma: %s" % item_id)
		
		"upgrade":
			# Aplicar upgrade al PlayerStats
			# IMPORTANTE: LootManager devuelve un wrapper con la data real en "data"
			# Debemos pasar la data real (que contiene "effects") al PlayerStats
			var upgrade_data = item.get("data", item)
			print("[TreasureChest] Aplicando upgrade: %s (Raw: %s)" % [upgrade_data, item])
			
			# Buscar PlayerStats por grupo (NO por ruta directa)
			var player_stats_nodes = get_tree().get_nodes_in_group("player_stats")
			var player_stats = player_stats_nodes[0] if player_stats_nodes.size() > 0 else null
			
			if player_stats and player_stats.has_method("apply_upgrade"):
				var result = player_stats.apply_upgrade(upgrade_data)
				print("[TreasureChest] Upgrade applied: %s" % result)
			elif player_ref and player_ref.has_method("apply_upgrade"):
				player_ref.apply_upgrade(upgrade_data)
			else:
				push_error("[TreasureChest] No se encontró PlayerStats para aplicar upgrade")
		
		"healing":
			var amount = item.get("amount", 20)
			# Curar usando player_ref o búsqueda segura
			if player_ref and player_ref.has_method("heal"):
				player_ref.heal(amount)
				print("[TreasureChest] ❤️ Curado %d HP via player_ref" % amount)
			else:
				var p = get_tree().get_first_node_in_group("player")
				if p and p.has_method("heal"):
					p.heal(amount)
					print("[TreasureChest] ❤️ Curado %d HP via group" % amount)
		
		"gold":
			# Añadir oro
			var amount = item.get("amount", 50)
			var exp_mgr = get_tree().current_scene.get_node_or_null("ExperienceManager")
			
			if not exp_mgr:
				# Intentar buscar por grupo
				var groups = get_tree().get_nodes_in_group("experience_manager")
				if not groups.is_empty():
					exp_mgr = groups[0]
			
			if exp_mgr and exp_mgr.has_method("add_coins"):
				exp_mgr.add_coins(amount)
				print("[TreasureChest] 💰 Añadido %d ORO" % amount)
			elif player_ref and "coins" in player_ref:
				player_ref.coins += amount
				print("[TreasureChest] 💰 Añadido %d ORO a player.coins" % amount)
				
		"fusion":
			# Aplicar fusión
			var fusion_data = item.get("fusion_data", {})
			if player_ref and "attack_manager" in player_ref:
				if player_ref.attack_manager.has_method("apply_fusion_result"):
					player_ref.attack_manager.apply_fusion_result(fusion_data)
				elif player_ref.attack_manager.has_method("perform_fusion"):
					player_ref.attack_manager.perform_fusion(fusion_data)
		
		"healing", "health_boost":
			# Curación instantánea
			var amount = item.get("amount", 0)
			# Si es health_boost, puede ser max_hp o curación, depende de la implementación.
			# Asumimos que healing es curar.
			if player_ref and player_ref.has_method("heal"):
				player_ref.heal(amount)
			elif player_ref and "health_component" in player_ref:
				if player_ref.health_component.has_method("heal"):
					player_ref.health_component.heal(amount)
					
		"consumable", "elixir", "potion":
			# Manejar consumibles (curación, buffs temporales o permanentes)
			var handled = false
			
			# 1. Curación directa
			# Soportar tanto "heal_amount" como "amount" si el efecto es curar
			var is_heal = item.get("effect") == "heal" or "potion" in item_id or "elixir" in item_id
			var heal_val = item.get("heal_amount", item.get("amount", 0))
			
			if is_heal and heal_val > 0:
				if player_ref and player_ref.has_method("heal"):
					player_ref.heal(heal_val)
					handled = true
					print("[TreasureChest] 🧪 Consumible curó: %s HP" % heal_val)
				elif player_ref and "health_component" in player_ref and player_ref.health_component:
					player_ref.health_component.heal(heal_val)
					handled = true
					print("[TreasureChest] 🧪 Consumible curó (direct HC): %s HP" % heal_val)
			
			# 2. Efectos de stats
			var effects = item.get("effects", [])
			if not effects.is_empty():
				var player_stats_nodes = get_tree().get_nodes_in_group("player_stats")
				var player_stats = player_stats_nodes[0] if player_stats_nodes.size() > 0 else null
				
				if player_stats:
					# Verificar si tiene duración (buff temporal)
					var duration = item.get("duration", 0.0)
					if duration > 0 and player_stats.has_method("add_temporary_modifier"):
						for eff in effects:
							player_stats.add_temporary_modifier(eff.get("stat"), eff.get("value"), duration)
						handled = true
						print("[TreasureChest] 🧪 Consumible aplicó buffs temporales (%.1fs)" % duration)
					else:
						player_stats.apply_upgrade(item)
						handled = true
						print("[TreasureChest] 🧪 Consumible aplicado como upgrade permanente")
			
			if not handled:
				print("[TreasureChest] ⚠️ Consumible sin efectos reconocidos: %s" % item)

		_:
			# Otros tipos (stats directos como speed_boost, etc. deberían ser upgrades)
			# Si son temporales, se aplican aquí. Si son stats permanentes, mejor usar "upgrade".
			# Por ahora, loguear para debug.
			print("[TreasureChest] Aplicando item genérico o desconocido: %s" % item_type)

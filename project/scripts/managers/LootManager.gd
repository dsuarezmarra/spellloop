# LootManager.gd
# Sistema centralizado para generar loot de cofres
# Conecta TreasureChest con PlayerUpgradeDatabase y WeaponDatabase

extends Node
class_name LootManager

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTES DE TIPO DE COFRE
# ═══════════════════════════════════════════════════════════════════════════════

enum ChestType {
	NORMAL = 0,
	ELITE = 1,
	BOSS = 2,
	WEAPON = 3
}

# Probabilidades base por tipo de cofre
const CHEST_WIEGHTS = {
	ChestType.NORMAL: {
		"gold": 0.4,
		"healing": 0.3,
		"upgrade": 0.2,
		"weapon": 0.1
	},
	ChestType.ELITE: {
		"gold": 0.2,
		"healing": 0.2,
		"upgrade": 0.4,
		"weapon": 0.2
	},
	ChestType.BOSS: {
		"gold": 0.0,
		"healing": 0.1,
		"upgrade": 0.4,
		"weapon": 0.5  # Alta probabilidad de arma/evolución
	},
	ChestType.WEAPON: {
		"gold": 0.0,
		"healing": 0.0,
		"upgrade": 0.0,
		"weapon": 1.0
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# GENERACIÓN DE LOOT
# ═══════════════════════════════════════════════════════════════════════════════

static func get_chest_loot(chest_type: int, luck_modifier: float = 1.0, context: Object = null) -> Array:
	"""
	Generar contenido para un cofre.
	Retorna array de diccionarios: [{id, type, rarity, amount, ...}]
	Context: Objeto opcional (usualmente AttackManager) para lógica de fusiones
	"""
	var items = []
	
	# Lógica especial para BOSS (Cofre Legendario)
	if chest_type == ChestType.BOSS:
		return _generate_boss_loot(luck_modifier, context)
	
	# Lógica estándar para otros cofres
	var weights = CHEST_WIEGHTS.get(chest_type, CHEST_WIEGHTS[ChestType.NORMAL])
	var category = _roll_category(weights, luck_modifier)
	
	var item = null
	match category:
		"gold":
			item = _generate_gold_loot(chest_type, luck_modifier)
		"healing":
			item = _generate_healing_loot(chest_type)
		"upgrade":
			# Elite asegura mejores mejoras (min tier 2)
			var min_tier = 2 if chest_type == ChestType.ELITE else 1
			item = _generate_upgrade_loot(chest_type, luck_modifier, min_tier)
		"weapon":
			item = _generate_weapon_loot(chest_type, luck_modifier)
			
	if item:
		items.append(item)
		
	return items

static func _generate_boss_loot(luck: float, context: Object) -> Array:
	"""
	Generar loot de JEFE (Legendario)
	Prioridad 1: Fusión si está disponible
	Prioridad 2: Jackpot (3-5 items)
	"""
	var items = []
	
	# 1. Intentar FUSIÓN (Garantizada si está disponible)
	# context debe ser el AttackManager
	if context and context.has_method("get_available_fusions"):
		var fusions = context.get_available_fusions()
		if not fusions.is_empty():
			# ¡Fusión disponible! Devolver el resultado de la primera fusión
			var fusing = fusions[0]
			var result = fusing.result
			
			items.append({
				"id": result.id,
				"type": "fusion", # Tipo especial para UI
				"name": result.name,
				"description": result.description,
				"rarity": 4, # Legendario/Evolución
				"icon": result.get("icon", "🌟"),
				"fusion_data": fusing # Datos necesarios para realizar la fusión
			})
			
			# Bonus de oro siempre
			items.append(_generate_gold_loot(ChestType.BOSS, luck))
			return items

	# 2. JACKPOT (Si no hay fusión)
	# 3 items garantizados: 1 Upgrade Raro, 1 Arma/Upgrade, 1 Upgrade
	
	# Item 1: Upgrade de Tier Alto (Min Tier 2)
	items.append(_generate_upgrade_loot(ChestType.BOSS, luck, 2))
	
	# Item 2: Arma o Upgrade
	if randf() < 0.5:
		items.append(_generate_weapon_loot(ChestType.BOSS, luck))
	else:
		items.append(_generate_upgrade_loot(ChestType.BOSS, luck, 2))
		
	# Item 3: Otro Upgrade
	items.append(_generate_upgrade_loot(ChestType.BOSS, luck, 1))
	
	# Plus de oro grande
	items.append(_generate_gold_loot(ChestType.BOSS, luck))
	
	return items

# ═══════════════════════════════════════════════════════════════════════════════
# GENERADORES ESPECÍFICOS
# ═══════════════════════════════════════════════════════════════════════════════

static func _generate_gold_loot(chest_type: int, luck: float) -> Dictionary:
	var base_amount = 50
	match chest_type:
		ChestType.ELITE: base_amount = 150
		ChestType.BOSS: base_amount = 500
		
	# Variación y suerte
	var amount = int(base_amount * randf_range(0.8, 1.2) * luck)
	
	return {
		"id": "gold_bag",
		"type": "gold",
		"name": "Bolsa de Oro",
		"amount": amount,
		"rarity": 1,
		"icon": "💰"
	}

static func _generate_healing_loot(chest_type: int) -> Dictionary:
	var heal_type = "potion"
	var name = "Poción de Vida"
	var amount = 30 # % de cura
	var icon = "❤️"
	
	if chest_type >= ChestType.ELITE:
		heal_type = "full_potion"
		name = "Elixir Completo"
		amount = 100
		icon = "💚"
		
	return {
		"id": heal_type,
		"type": "consumable",
		"effect": "heal",
		"name": name,
		"amount": amount,
		"rarity": 1,
		"icon": icon
	}

static func _generate_upgrade_loot(chest_type: int, luck: float, min_tier_override: int = 1) -> Dictionary:
	"""
	Generar una mejora aleatoria desde la base de datos de mejoras.
	min_tier_override: Fuerza un tier mínimo (para Elites/Jefes)
	"""
	# Obtener referencia a la base de datos de mejoras
	var all_upgrades = []
	
	# Cargar script dinámicamente
	if not ClassDB.class_exists("UpgradeDatabase") and not ResourceLoader.exists("res://scripts/data/UpgradeDatabase.gd"):
		printerr("❌ LootManager: UpgradeDatabase no encontrado.")
		return loot
		
	var UpgradeDB = load("res://scripts/data/UpgradeDatabase.gd")
	if UpgradeDB:
		_append_dict_values(all_upgrades, UpgradeDB.DEFENSIVE_UPGRADES)
		_append_dict_values(all_upgrades, UpgradeDB.UTILITY_UPGRADES)
		_append_dict_values(all_upgrades, UpgradeDB.OFFENSIVE_UPGRADES)
		
		# Determinar tier mínimo
		var min_tier = min_tier_override
		if chest_type == ChestType.ELITE and min_tier < 2: min_tier = 2
		if chest_type == ChestType.BOSS and min_tier < 3: min_tier = 3
		
		var valid_upgrades = []
		for up in all_upgrades:
			if up.get("tier", 1) >= min_tier:
				# Aplicar suerte
				var tier = up.get("tier", 1)
				var weight = 1.0
				
				# Preferir altos tiers para cofres buenos
				if tier > min_tier:
					weight = 1.0 + (luck - 1.0) * 0.5
				
				valid_upgrades.append({"data": up, "weight": weight})
		
		if valid_upgrades.size() > 0:
			var picked = _weighted_random(valid_upgrades)
			return {
				"id": picked.id,
				"type": "upgrade",
				"name": picked.name,
				"description": picked.description,
				"rarity": picked.get("tier", 1) - 1,
				"icon": picked.icon,
				"data": picked
			}
			
	return _generate_gold_loot(chest_type, luck)

static func _append_dict_values(target_array: Array, source_dict: Dictionary) -> void:
	for key in source_dict:
		target_array.append(source_dict[key])

static func _weighted_random(items: Array) -> Dictionary:
	var total_weight = 0.0
	for item in items:
		total_weight += item.weight
	
	var roll = randf() * total_weight
	var current = 0.0
	for item in items:
		current += item.weight
		if roll <= current:
			return item.data
	return items[0].data

static func _generate_weapon_loot(chest_type: int, luck: float) -> Dictionary:
	# Seleccionar arma aleatoria
	var possible_weapons = []
	
	# Obtener armas reales de la base de datos
	if ClassDB.class_exists("WeaponDatabase") or ResourceLoader.exists("res://scripts/data/WeaponDatabase.gd"):
		var WeaponDB = load("res://scripts/data/WeaponDatabase.gd")
		if WeaponDB:
			possible_weapons = WeaponDB.get_all_base_weapons()
	
	# Fallback
	if possible_weapons.is_empty():
		possible_weapons = ["ice_wand", "fire_wand", "lightning_wand"]

	var selected_id = possible_weapons[randi() % possible_weapons.size()]
	
	return {
		"id": selected_id,
		"type": "weapon",
		"name": selected_id.capitalize().replace("_", " "),
		"rarity": 3 if chest_type == ChestType.BOSS else 2,
		"icon": "⚔️"
	}
	
# ═══════════════════════════════════════════════════════════════════════════════
# UTILS
# ═══════════════════════════════════════════════════════════════════════════════

static func _roll_category(weights: Dictionary, luck: float) -> String:
	var total_weight = 0.0
	var modified_weights = weights.duplicate()
	
	# La suerte aumenta probabilidad de cosas buenas (weapon/upgrade)
	if luck > 1.0:
		if modified_weights.has("weapon"): modified_weights["weapon"] *= luck
		if modified_weights.has("upgrade"): modified_weights["upgrade"] *= luck
		
	for w in modified_weights.values():
		total_weight += w
		
	var roll = randf() * total_weight
	var current = 0.0
	
	for category in modified_weights:
		current += modified_weights[category]
		if roll <= current:
			return category
			
	return "gold"

# ═══════════════════════════════════════════════════════════════════════════════
# SHOP CHEST LOOT (Cofres tienda con precios)
# ═══════════════════════════════════════════════════════════════════════════════

const PRICE_BY_TIER = {
	1: {"base": 50, "variance": 25},
	2: {"base": 100, "variance": 50},
	3: {"base": 200, "variance": 100},
	4: {"base": 350, "variance": 175},
	5: {"base": 500, "variance": 250}
}

const DISCOUNT_CHANCE: float = 0.20  # 20% probabilidad de descuento
const DISCOUNT_MIN: int = 10
const DISCOUNT_MAX: int = 90

static func get_random_shop_loot(chest_type: int, count: int, luck: float = 1.0) -> Array:
	"""
	Generar items para cofre tipo tienda.
	Retorna array de items con precios y descuentos.
	"""
	var items = []
	
	# Tier base según tipo de cofre
	var base_tier = 1
	var min_rarity = 0
	
	match chest_type:
		ChestType.NORMAL:
			base_tier = 1 # Común/Uncommon
		ChestType.ELITE:
			base_tier = 2 # Rare+
			min_rarity = 1
		ChestType.BOSS:
			base_tier = 3 # Epic/Legendary
			min_rarity = 3
			
	# Generar items
	for i in range(count):
		var item = _generate_shop_item(chest_type, base_tier, luck)
		if item:
			items.append(item)
	
	return items

static func _generate_shop_item(chest_type: int, base_tier: int, luck: float) -> Dictionary:
	"""Generar un item para tienda con precio"""
	
	var item = {}
	
	# Lógica especial para BOSS
	if chest_type == ChestType.BOSS:
		# 50% Boss Item, 30% Weapon, 20% High Tier Upgrade
		var roll = randf()
		if roll < 0.5:
			# Intentar sacar item de BossDatabase (si implementado) o fallback a upgrade alto
			item = _generate_shop_boss_item(luck)
		elif roll < 0.8:
			item = _generate_shop_weapon(base_tier, luck)
		else:
			item = _generate_shop_upgrade(base_tier, 0, luck)
	else:
		# Lógica estándar
		var is_weapon = randf() < 0.2  # 20% armas
		if is_weapon:
			item = _generate_shop_weapon(base_tier, luck)
		else:
			item = _generate_shop_upgrade(base_tier, 0, luck)
	
	if item.is_empty():
		return {}
	
	# Calcular tier efectivo (clamping)
	var tier = item.get("tier", base_tier)
	tier = clampi(tier, 1, 5)
	
	# Calcular precio
	var price_data = PRICE_BY_TIER.get(tier, PRICE_BY_TIER[1])
	var base_price = price_data.base
	var variance = price_data.variance
	var price = base_price + randi_range(-variance, variance)
	price = maxi(price, 10)
	
	var original_price = price
	var discount = 0
	
	# Aplicar descuento aleatorio
	if randf() < DISCOUNT_CHANCE:
		discount = randi_range(DISCOUNT_MIN, DISCOUNT_MAX)
		price = int(price * (100 - discount) / 100.0)
		price = maxi(price, 5)
	
	item["price"] = price
	item["original_price"] = original_price
	item["discount_percent"] = discount
	
	return item

static func _generate_shop_weapon(base_tier: int, luck: float) -> Dictionary:
	"""Generar arma para tienda"""
	# Obtener todas las armas base del diccionario
	var all_weapon_ids = WeaponDatabase.WEAPONS.keys()
	
	if all_weapon_ids.is_empty():
		return {}
	
	# Seleccionar arma aleatoria
	var weapon_id = all_weapon_ids[randi() % all_weapon_ids.size()]
	var weapon_data = WeaponDatabase.get_weapon_data(weapon_id)
	
	if weapon_data.is_empty():
		return {}
	
	return {
		"type": "weapon",
		"id": weapon_id,
		"name": weapon_data.get("name_es", weapon_data.get("name", "Arma")),
		"description": weapon_data.get("description", "Nueva arma"),
		"icon": weapon_data.get("icon", "⚔️"),
		"tier": base_tier,
		"rarity": base_tier
	}

static func _generate_shop_upgrade(base_tier: int, time_bonus: int, luck: float) -> Dictionary:
	"""Generar upgrade para tienda"""
	var UpgradeDB = load("res://scripts/data/UpgradeDatabase.gd")
	if not UpgradeDB:
		return {}
	
	var all_upgrades = []
	
	# Recolectar de todas las categorías
	if UpgradeDB.get("DEFENSIVE_UPGRADES"):
		_append_dict_values(all_upgrades, UpgradeDB.DEFENSIVE_UPGRADES)
	if UpgradeDB.get("UTILITY_UPGRADES"):
		_append_dict_values(all_upgrades, UpgradeDB.UTILITY_UPGRADES)
	if UpgradeDB.get("OFFENSIVE_UPGRADES"):
		_append_dict_values(all_upgrades, UpgradeDB.OFFENSIVE_UPGRADES)
	
	if all_upgrades.is_empty():
		return {}
	
	# Filtrar por tier (con bonus de tiempo y suerte)
	var target_tier = base_tier
	if randf() < luck * 0.2:  # Suerte puede subir tier
		target_tier = mini(target_tier + 1, 5)
	if time_bonus > 0 and randf() < 0.3:
		target_tier = mini(target_tier + 1, 5)
	
	var eligible = all_upgrades.filter(func(u): 
		var t = u.get("tier", 1)
		return t >= base_tier and t <= target_tier + 1
	)
	
	if eligible.is_empty():
		eligible = all_upgrades
	
	var upgrade = eligible[randi() % eligible.size()]
	
	return {
		"type": "upgrade",
		"id": upgrade.get("id", "unknown"),
		"name": upgrade.get("name", "Mejora"),
		"description": upgrade.get("description", "Mejora desconocida"),
		"icon": upgrade.get("icon", "⬆️"),
		"tier": upgrade.get("tier", 1),
		"rarity": upgrade.get("tier", 1),
		"effects": upgrade.get("effects", [])
	}
 
 s t a t i c   f u n c   _ g e n e r a t e _ s h o p _ b o s s _ i t e m ( l u c k :   f l o a t )   - >   D i c t i o n a r y :  
 	 " " " G e n e r a r   i t e m   d e   j e f e   ( L e g e n d a r i o / � an i c o ) " " "  
 	 i f   n o t   C l a s s D B . c l a s s _ e x i s t s ( " B o s s D a t a b a s e " )   a n d   n o t   R e s o u r c e L o a d e r . e x i s t s ( " r e s : / / s c r i p t s / d a t a / B o s s D a t a b a s e . g d " ) :  
 	 	 r e t u r n   _ g e n e r a t e _ s h o p _ u p g r a d e ( 4 ,   0 ,   l u c k )  
 	 	  
 	 v a r   B o s s D B   =   l o a d ( " r e s : / / s c r i p t s / d a t a / B o s s D a t a b a s e . g d " )  
 	 i f   n o t   B o s s D B :   r e t u r n   _ g e n e r a t e _ s h o p _ u p g r a d e ( 4 ,   0 ,   l u c k )  
 	  
 	 v a r   l o o t _ t a b l e   =   B o s s D B . g e t _ b o s s _ l o o t ( " d e f a u l t " )  
 	 v a r   p o o l   =   l o o t _ t a b l e . g e t ( " p o o l " ,   [ ] )  
 	  
 	 i f   p o o l . i s _ e m p t y ( ) :  
 	 	 r e t u r n   _ g e n e r a t e _ s h o p _ u p g r a d e ( 4 ,   0 ,   l u c k )  
 	 	  
 	 v a r   p i c k   =   p o o l [ r a n d i ( )   %   p o o l . s i z e ( ) ]  
 	  
 	 m a t c h   p i c k :  
 	 	 " w e a p o n _ u p g r a d e " :  
 	 	 	 r e t u r n   _ g e n e r a t e _ s h o p _ w e a p o n ( 4 ,   l u c k )   #   T i e r   4   w e a p o n  
 	 	 " s t a t _ u p g r a d e _ t i e r _ 3 " :  
 	 	 	 r e t u r n   _ g e n e r a t e _ s h o p _ u p g r a d e ( 3 ,   0 ,   l u c k )  
 	 	 " s t a t _ u p g r a d e _ t i e r _ 4 " :  
 	 	 	 r e t u r n   _ g e n e r a t e _ s h o p _ u p g r a d e ( 4 ,   0 ,   l u c k )  
 	 	 " u n i q u e _ u p g r a d e " :  
 	 	 	 r e t u r n   _ g e n e r a t e _ s h o p _ u p g r a d e ( 5 ,   0 ,   l u c k   *   1 . 5 )   #   T r y   f o r   u n i q u e  
 	 	 	  
 	 r e t u r n   _ g e n e r a t e _ s h o p _ u p g r a d e ( 3 ,   0 ,   l u c k )  
 
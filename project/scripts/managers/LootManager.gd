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
	if not ClassDB.class_exists("PlayerUpgradeDatabase") and not ResourceLoader.exists("res://scripts/data/PlayerUpgradeDatabase.gd"):
		return {
			"id": "gold_bag_fallback", 
			"type": "gold", 
			"amount": 100,
			"name": "Tesoro",
			"rarity": 1,
			"icon": "💰"
		}
		
	var UpgradeDB = load("res://scripts/data/PlayerUpgradeDatabase.gd")
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

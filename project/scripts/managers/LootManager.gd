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

static func get_chest_loot(chest_type: int, luck_modifier: float = 1.0) -> Array:
	"""
	Generar contenido para un cofre.
	Retorna array de diccionarios: [{id, type, rarity, amount, ...}]
	"""
	var items = []
	var weights = CHEST_WIEGHTS.get(chest_type, CHEST_WIEGHTS[ChestType.NORMAL])
	
	# Determinar categoría principal del premio
	var category = _roll_category(weights, luck_modifier)
	
	# Generar item específico según categoría
	var item = null
	
	match category:
		"gold":
			item = _generate_gold_loot(chest_type, luck_modifier)
		"healing":
			item = _generate_healing_loot(chest_type)
		"upgrade":
			item = _generate_upgrade_loot(chest_type, luck_modifier)
		"weapon":
			item = _generate_weapon_loot(chest_type, luck_modifier)
			
	if item:
		items.append(item)
		
	# Boss chests pueden dar premios extra
	if chest_type == ChestType.BOSS:
		# Siempre añadir oro extra
		items.append(_generate_gold_loot(chest_type, luck_modifier))
		
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

static func _generate_upgrade_loot(chest_type: int, luck: float) -> Dictionary:
	"""
	Generar una mejora aleatoria desde la base de datos de mejoras.
	"""
	# Obtener referencia a la base de datos de mejoras
	# Como PlayerUpgradeDatabase tiene constantes estáticas, podemos acceder a ellas directamente
	# o vía una instancia dummy si es necesario. En Godot 4, acceso estático a const dictionary funciona.
	
	var all_upgrades = []
	
	# Recopilar todas las mejoras posibles
	# Nota: Asumimos que PlayerUpgradeDatabase es accesible globalmente o preload
	if not ClassDB.class_exists("PlayerUpgradeDatabase") and not ResourceLoader.exists("res://scripts/data/PlayerUpgradeDatabase.gd"):
		# Fallback de emergencia
		return {
			"id": "gold_bag_fallback", 
			"type": "gold", 
			"amount": 100,
			"name": "Tesoro",
			"rarity": 1,
			"icon": "💰"
		}
		
	# Cargar script dinámicamente para acceder constantes
	var UpgradeDB = load("res://scripts/data/PlayerUpgradeDatabase.gd")
	
	if UpgradeDB:
		_append_dict_values(all_upgrades, UpgradeDB.DEFENSIVE_UPGRADES)
		_append_dict_values(all_upgrades, UpgradeDB.UTILITY_UPGRADES)
		_append_dict_values(all_upgrades, UpgradeDB.OFFENSIVE_UPGRADES) # Asumiendo que existe
		
		# Filtrar por rareza mínima según tipo de cofre
		var min_tier = 1
		if chest_type == ChestType.ELITE: min_tier = 2
		if chest_type == ChestType.BOSS: min_tier = 3
		
		var valid_upgrades = []
		for up in all_upgrades:
			if up.get("tier", 1) >= min_tier:
				# Aplicar suerte: si luck es alto, preferir tiers altos
				var tier = up.get("tier", 1)
				var weight = 1.0
				if tier > min_tier:
					weight = 1.0 + (luck - 1.0) * 0.5 # Bonus leve de peso a tiers superiores
				
				valid_upgrades.append({"data": up, "weight": weight})
		
		if valid_upgrades.size() > 0:
			var picked = _weighted_random(valid_upgrades)
			return {
				"id": picked.id,
				"type": "upgrade",
				"name": picked.name,
				"description": picked.description,
				"rarity": picked.get("tier", 1) - 1, # Ajuste visual 0-indexed si es necesario
				"icon": picked.icon,
				"data": picked # Guardar ref completa
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
	# En una implementación completa verificaríamos armas desbloqueadas
	
	var possible_weapons = ["magic_wand", "axe", "cross", "fireball"]
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

# LootManager.gd
# Sistema centralizado para generar loot de cofres
# Conecta TreasureChest con UpgradeDatabase y WeaponDatabase

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

# ═══════════════════════════════════════════════════════════════════════════════
# BALANCE PASS 2: CONFIGURACIÓN DE FUSIÓN EN CHESTS
# ═══════════════════════════════════════════════════════════════════════════════
# Las fusiones ahora SOLO aparecen en chests, NO en LevelUpPanel.
# - ELITE: Baja probabilidad (8%)
# - BOSS: Garantizada (100% si hay fusión disponible)
# Condición: 2+ armas al nivel máximo (lvl 8) - verificada por get_available_fusions()
const ELITE_FUSION_CHANCE: float = 0.08   # 8% chance de fusión en elite chest
const BOSS_FUSION_GUARANTEED: bool = true  # Boss siempre da fusión si disponible

# Probabilidades base por tipo de cofre
const CHEST_WEIGHTS = {
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
	
	BALANCE PASS 2: Fusiones solo en chests (no LevelUp)
	- BOSS: Garantizada si disponible
	- ELITE: 8% chance si disponible
	"""
	var items = []
	
	# Lógica especial para BOSS (Cofre Legendario)
	if chest_type == ChestType.BOSS:
		return _generate_boss_loot(luck_modifier, context)
	
	# BALANCE PASS 2: Check fusión en ELITE chests
	if chest_type == ChestType.ELITE:
		var fusion_item = _try_generate_fusion_loot(context, ELITE_FUSION_CHANCE)
		if fusion_item:
			items.append(fusion_item)
			# Si hay fusión, añadir bonus de oro y retornar
			items.append(_generate_gold_loot(ChestType.ELITE, luck_modifier))
			return items
	
	# Lógica estándar para otros cofres
	var weights = CHEST_WEIGHTS.get(chest_type, CHEST_WEIGHTS[ChestType.NORMAL])
	var category = _roll_category(weights, luck_modifier, context)
	
	var item = null
	match category:
		"gold":
			item = _generate_gold_loot(chest_type, luck_modifier)
		"healing":
			item = _generate_healing_loot(chest_type)
		"upgrade":
			# Elite asegura mejores mejoras (min tier 2)
			var min_tier = 2 if chest_type == ChestType.ELITE else 1
			item = _generate_upgrade_loot(chest_type, luck_modifier, min_tier, context)
		"weapon":
			item = _generate_weapon_loot(chest_type, luck_modifier, context)
			
	if item:
		items.append(item)
		
	return items

static func _try_generate_fusion_loot(context: Object, chance: float) -> Dictionary:
	"""
	BALANCE PASS 2: Intentar generar loot de fusión.
	Retorna diccionario con datos de fusión, o {} si no aplica.
	Condición: 2+ armas lvl 8 Y roll de probabilidad
	"""
	if not context or not context.has_method("get_available_fusions"):
		return {}
	
	# Verificar si hay fusiones disponibles (ya verifica 2+ armas lvl 8)
	var fusions = context.get_available_fusions()
	if fusions.is_empty():
		return {}
	
	# Roll de probabilidad
	if randf() > chance:
		return {}
	
	# ¡Fusión disponible! Devolver la primera
	var fusing = fusions[0]
	var result = fusing.result
	
	return {
		"id": result.id,
		"type": "fusion",
		"name": result.name,
		"description": result.description,
		"rarity": 4,  # Legendario/Evolución
		"icon": result.get("icon", "🌟"),
		"fusion_data": fusing
	}

static func _get_player_stats(context: Object, tree: SceneTree = null) -> Node:
	"""Helper para obtener PlayerStats desde contexto o grupo global"""
	# 1. Intentar desde contexto (AttackManager)
	if context and context.has_method("get_player_stats"):
		# Si AttackManager tiene getter
		var result = context.get_player_stats()
		if result is Node:
			return result
	if context and "player_stats" in context:
		var stats = context.player_stats
		# Only return if it's a Node (not a Dictionary)
		if stats is Node:
			return stats
		
	# 2. Intentar buscar globalmente (si tenemos tree)
	if tree:
		var nodes = tree.get_nodes_in_group("player_stats")
		if not nodes.is_empty():
			return nodes[0]
			
	return null

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

	# 2. BOSS DATABASE LOOT
	# Usar tabla de loot definida en BossDatabase
	var BossDB = load("res://scripts/data/BossDatabase.gd")
	var loot_config = BossDB.get_boss_loot("default") # Por defecto o pasar ID si estuviera disponible
	
	# Recompensas garantizadas
	for guaranteed_item in loot_config.get("guaranteed", []):
		var item = _resolve_loot_string(guaranteed_item, luck, context)
		if item: items.append(item)
		
	# Chance de extra
	if randf() < loot_config.get("chance_for_extra", 0.0):
		var pool = loot_config.get("pool", [])
		if not pool.is_empty():
			var pick = pool[randi() % pool.size()]
			var item = _resolve_loot_string(pick, luck, context)
			if item: items.append(item)
			
	# Garantizar al menos un item de pool si solo hay oro garantizado?
	# La config actual da "gold_large" y "stat_upgrade_tier_3" garantizados en default.
	# Si la lista de items sigue vacía (por error), fallback
	if items.is_empty():
		items.append(_generate_upgrade_loot(ChestType.BOSS, luck, 3, context))
	
	return items

static func _resolve_loot_string(key: String, luck: float, context: Object) -> Dictionary:
	match key:
		"gold_large":
			return _generate_gold_loot(ChestType.BOSS, luck)
		"weapon_upgrade":
			return _generate_weapon_loot(ChestType.BOSS, luck, context)
		"stat_upgrade_tier_3":
			return _generate_upgrade_loot(ChestType.BOSS, luck, 3, context)
		"stat_upgrade_tier_4":
			return _generate_upgrade_loot(ChestType.BOSS, luck, 4, context)
		"unique_upgrade":
			# Intentar tier 5 (Legendario/Unico)
			return _generate_upgrade_loot(ChestType.BOSS, luck, 5, context)
		_:
			printerr("LootManager: Clave desconocida de BossDatabase: ", key)
			return {}

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
		"description": "+%d Monedas" % amount,
		"amount": amount,
		"rarity": 1,
		"icon": "💰"
	}

static func _generate_healing_loot(chest_type: int) -> Dictionary:
	var heal_type = "potion"
	var item_name = Localization.L("items.potions.health_potion.name")
	var amount = 30 # % de cura
	var icon = "❤️"
	var desc = Localization.L("items.potions.health_potion.description")
	
	if chest_type >= ChestType.ELITE:
		heal_type = "full_potion"
		item_name = Localization.L("items.potions.full_elixir.name")
		amount = 100
		icon = "💚"
		desc = Localization.L("items.potions.full_elixir.description")
		
	return {
		"id": heal_type,
		"type": "consumable",
		"effect": "heal",
		"name": item_name,
		"description": desc,
		"amount": amount,
		"rarity": 1,
		"icon": icon
	}

static func _generate_upgrade_loot(chest_type: int, luck: float, min_tier_override: int = 1, context: Object = null) -> Dictionary:
	"""
	Generar una mejora aleatoria desde la base de datos de mejoras.
	min_tier_override: Fuerza un tier mínimo (para Elites/Jefes)
	"""
	# Obtener referencia a la base de datos de mejoras
	var all_upgrades = []
	
	# Cargar script dinámicamente
	if not ClassDB.class_exists("UpgradeDatabase") and not ResourceLoader.exists("res://scripts/data/UpgradeDatabase.gd"):
		printerr("❌ LootManager: UpgradeDatabase no encontrado.")
		return {}
		
	var UpgradeDB = load("res://scripts/data/UpgradeDatabase.gd")
	if UpgradeDB:
		_append_dict_values(all_upgrades, UpgradeDB.DEFENSIVE_UPGRADES)
		_append_dict_values(all_upgrades, UpgradeDB.UTILITY_UPGRADES)
		_append_dict_values(all_upgrades, UpgradeDB.OFFENSIVE_UPGRADES)
		
		# Incluir CURSED con 15% de probabilidad (trade-offs interesantes)
		if randf() < 0.15:
			_append_dict_values(all_upgrades, UpgradeDB.CURSED_UPGRADES)
		
		# Incluir UNIQUE solo para cofres BOSS (objetos especiales)
		if chest_type == ChestType.BOSS:
			_append_dict_values(all_upgrades, UpgradeDB.UNIQUE_UPGRADES)
		
		# Determinar tier mínimo
		var min_tier = min_tier_override
		if chest_type == ChestType.ELITE and min_tier < 2: min_tier = 2
		if chest_type == ChestType.BOSS and min_tier < 3: min_tier = 3
		
		# Obtener PlayerStats para filtrado inteligente
		var player_stats = _get_player_stats(context, Engine.get_main_loop().current_scene.get_tree() if Engine.get_main_loop() else null)

		var valid_upgrades = []
		for up in all_upgrades:
			# Validar si cumple requisitos base
			if up.get("tier", 1) < min_tier:
				continue
				
			# -----------------------------------------------------------
			# FILTRO INTELIGENTE (Fix Upgrade Duplicates)
			# -----------------------------------------------------------
			if player_stats:
				var up_id = up.get("id", "")
				
				# 1. Filtrar únicos ya obtenidos
				if up.get("is_unique", false) and player_stats.has_method("has_unique_upgrade"):
					if player_stats.has_unique_upgrade(up_id):
						continue
						
				# 2. Filtrar mejoras maxeadas por stacks
				var max_stacks = up.get("max_stacks", 0)
				if max_stacks > 0 and player_stats.has_method("get_upgrade_stacks"):
					if player_stats.get_upgrade_stacks(up_id) >= max_stacks:
						continue
						
				# 3. Filtrar mejoras inútiles (stats capeados)
				if player_stats.has_method("would_upgrade_be_useful"):
					if not player_stats.would_upgrade_be_useful(up):
						continue
			# -----------------------------------------------------------

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

static func _generate_weapon_loot(chest_type: int, luck: float, context: Object = null) -> Dictionary:
	# VERIFICACIÓN: No ofrecer armas si no hay slots disponibles
	if context:
		# Verificar si hay slot disponible usando la propiedad directamente
		var has_slot = true
		
		# Método 1: Propiedad directa has_available_slot
		if "has_available_slot" in context:
			has_slot = context.has_available_slot
		# Método 2: Calcular manualmente desde weapons y max_slots
		elif context.has_method("get_weapons"):
			var equipped = context.get_weapons()
			var max_slots = context.max_weapon_slots if "max_weapon_slots" in context else 6
			has_slot = equipped.size() < max_slots
		
		if not has_slot:
			# No hay espacio para más armas - dar upgrade o monedas en su lugar
			print("[LootManager] No hay slots de arma disponibles - dando upgrade en lugar de arma")
			return _generate_upgrade_loot(chest_type, luck, 1, context)
	
	# Seleccionar arma aleatoria
	var possible_weapons = []
	
	# Obtener armas reales de la base de datos
	var WeaponDB = null
	if ClassDB.class_exists("WeaponDatabase") or ResourceLoader.exists("res://scripts/data/WeaponDatabase.gd"):
		WeaponDB = load("res://scripts/data/WeaponDatabase.gd")
		if WeaponDB:
			possible_weapons = WeaponDB.get_all_base_weapons()
	
	# Fallback
	if possible_weapons.is_empty():
		possible_weapons = ["ice_wand", "fire_wand", "lightning_wand"]

	# Filtrar armas que ya están al nivel máximo (8)
	if context and context.has_method("get_weapons"):
		var equipped_weapons = context.get_weapons()
		var maxed_weapons = []
		
		for w in equipped_weapons:
			if w.level >= 8: # MAX LEVEL CONSTANT
				maxed_weapons.append(w.id)
		
		# Remover armas maxeadas de la lista posible
		var filtered = []
		for w_id in possible_weapons:
			if not w_id in maxed_weapons:
				filtered.append(w_id)
		possible_weapons = filtered
	
	# Si no quedan armas disponibles (todas maxeadas o error), dar Oro o Curación
	if possible_weapons.is_empty():
		return _generate_gold_loot(chest_type, luck)

	var selected_id = possible_weapons[randi() % possible_weapons.size()]
	
	# Obtener nombre bonito y descripción si es posible
	var w_name = selected_id.capitalize().replace("_", " ")
	var w_desc = Localization.L("items.weapons.new_weapon_fallback")
	
	if WeaponDB and WeaponDB.WEAPONS.has(selected_id):
		w_name = WeaponDB.WEAPONS[selected_id].get("name", w_name)
		w_desc = WeaponDB.WEAPONS[selected_id].get("description", w_desc)

	return {
		"id": selected_id,
		"type": "weapon",
		"name": w_name,
		"description": w_desc,
		"rarity": 3 if chest_type == ChestType.BOSS else 2,
		"icon": "⚔️"
	}
	
# ═══════════════════════════════════════════════════════════════════════════════
# UTILS
# ═══════════════════════════════════════════════════════════════════════════════

static func _roll_category(weights: Dictionary, luck: float, context: Object = null) -> String:
	var total_weight = 0.0
	var modified_weights = weights.duplicate()
	
	# FILTRAR ARMAS SI NO HAY ESPACIO DISPONIBLE
	if context and modified_weights.has("weapon") and modified_weights["weapon"] > 0:
		var has_slot = true
		
		# Verificar slots disponibles
		if "has_available_slot" in context:
			has_slot = context.has_available_slot
		elif context.has_method("get_weapons"):
			var equipped = context.get_weapons()
			var max_slots = context.max_weapon_slots if "max_weapon_slots" in context else 6
			has_slot = equipped.size() < max_slots
		
		if not has_slot:
			# Redistribuir el peso de armas a upgrades
			var weapon_weight = modified_weights["weapon"]
			modified_weights["weapon"] = 0.0
			if modified_weights.has("upgrade"):
				modified_weights["upgrade"] += weapon_weight
			else:
				modified_weights["gold"] = modified_weights.get("gold", 0.0) + weapon_weight
			print("[LootManager] Sin slots de arma - redistribuyendo peso a upgrades")
	
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

static func get_random_shop_loot(chest_type: int, count: int, luck: float = 1.0, context: Object = null) -> Array:
	"""
	Generar items para cofre tipo tienda.
	Retorna array de items con precios y descuentos.
	"""
	var items = []
	
	# Tier base según tipo de cofre
	var base_tier = 1
	var _min_rarity = 0  # Reserved for future filtering
	
	match chest_type:
		ChestType.NORMAL:
			base_tier = 1 # Común/Uncommon
		ChestType.ELITE:
			base_tier = 2 # Rare+
			_min_rarity = 1
		ChestType.BOSS:
			base_tier = 3 # Epic/Legendary
			_min_rarity = 3
			
	# Generar items
	for i in range(count):
		var item = _generate_shop_item(chest_type, base_tier, luck, context)
		if item:
			items.append(item)
	
	return items

static func _generate_shop_item(chest_type: int, base_tier: int, luck: float, context: Object = null) -> Dictionary:
	"""Generar un item para tienda con precio"""
	
	var item = {}
	
	# Verificar si hay slots disponibles para armas
	var can_add_weapons = true
	if context:
		# Verificar propiedad has_available_slot directamente
		if "has_available_slot" in context:
			can_add_weapons = context.has_available_slot
		elif context.has_method("get_weapons"):
			var max_slots = 6
			if "max_weapon_slots" in context:
				max_slots = context.max_weapon_slots
			can_add_weapons = context.get_weapons().size() < max_slots
	
	# Lógica especial para BOSS
	if chest_type == ChestType.BOSS:
		# 50% Boss Item, 30% Weapon, 20% High Tier Upgrade
		var roll = randf()
		if roll < 0.5:
			# Intentar sacar item de BossDatabase (si implementado) o fallback a upgrade alto
			item = _generate_shop_boss_item(luck, context)
		elif roll < 0.8 and can_add_weapons:
			item = _generate_shop_weapon(base_tier, luck)
		else:
			item = _generate_shop_upgrade(base_tier, 0, luck, context)
	else:
		# Lógica estándar
		var is_weapon = randf() < 0.2 and can_add_weapons  # 20% armas solo si hay slots
		if is_weapon:
			item = _generate_shop_weapon(base_tier, luck)
		else:
			item = _generate_shop_upgrade(base_tier, 0, luck, context)
	
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

static func _generate_shop_weapon(base_tier: int, _luck: float) -> Dictionary:
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

static func _generate_shop_upgrade(base_tier: int, time_bonus: int, luck: float, context: Object = null) -> Dictionary:
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
	
	# FILTRO DE UPGRADES SHOP (Nuevo)
	var player_stats = _get_player_stats(context, Engine.get_main_loop().current_scene.get_tree() if Engine.get_main_loop() else null)
	if player_stats:
		var filtered = []
		for up in eligible:
			var up_id = up.get("id", "")
			# 1. Filtrar únicos
			if up.get("is_unique", false) and player_stats.has_unique_upgrade(up_id):
				continue
			# 2. Filtrar max stacks
			var max_stacks = up.get("max_stacks", 0)
			if max_stacks > 0 and player_stats.get_upgrade_stacks(up_id) >= max_stacks:
				continue
			# 3. Filtrar capped
			if not player_stats.would_upgrade_be_useful(up):
				continue
			filtered.append(up)
		eligible = filtered
	
	if eligible.is_empty():
		# Si filtramos todo (muy avanzado el juego), dar oro o cura
		return {
			"type": "gold",
			"id": "gold_bag_shop",
			"name": "Reembolso",
			"amount": 100,
			"rarity": 1,
			"icon": "💰",
			"tier": 1
		}
	
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

static func _generate_shop_boss_item(luck: float, context: Object = null) -> Dictionary:
	"""Generar item de jefe (Legendario/Único)"""
	if not ClassDB.class_exists("BossDatabase") and not ResourceLoader.exists("res://scripts/data/BossDatabase.gd"):
		return _generate_shop_upgrade(4, 0, luck, context)
		
	var BossDB = load("res://scripts/data/BossDatabase.gd")
	if not BossDB: return _generate_shop_upgrade(4, 0, luck, context)
	
	var loot_table = BossDB.get_boss_loot("default")
	var pool = loot_table.get("pool", [])
	
	if pool.is_empty():
		return _generate_shop_upgrade(4, 0, luck, context)
	
	# Verificar si hay slots disponibles para armas
	var can_add_weapons = true
	if context:
		if "has_available_slot" in context:
			can_add_weapons = context.has_available_slot
		elif context.has_method("get_weapons"):
			var max_slots = context.max_weapon_slots if "max_weapon_slots" in context else 6
			can_add_weapons = context.get_weapons().size() < max_slots
		
	var pick = pool[randi() % pool.size()]
	
	match pick:
		"weapon_upgrade":
			# Solo dar arma si hay slots disponibles
			if can_add_weapons:
				return _generate_shop_weapon(4, luck)
			else:
				return _generate_shop_upgrade(4, 0, luck, context)
		"stat_upgrade_tier_3":
			return _generate_shop_upgrade(3, 0, luck, context)
		"stat_upgrade_tier_4":
			return _generate_shop_upgrade(4, 0, luck, context)
		"unique_upgrade":
			return _generate_shop_upgrade(5, 0, luck * 1.5, context)
			
	return _generate_shop_upgrade(3, 0, luck, context)

extends Node
# Sistema de Items y Raridades - Spellloop
# 50 items: 15 blancos, 12 azules, 10 amarillas, 8 naranjas, 5 moradas

enum ItemType {
	WEAPON_SPELL,    # Armas/Hechizos activos
	PASSIVE,         # Pasivos/Modificadores
	ACCESSORY        # Accesorios con efectos únicos
}

enum ItemRarity {
	WHITE,    # Blanca (normal)
	BLUE,     # Azul (común)
	YELLOW,   # Amarilla (rara)
	ORANGE,   # Naranja (legendaria)
	PURPLE    # Morada (única)
}

var rarity_colors = {
	ItemRarity.WHITE: "#FFFFFF",
	ItemRarity.BLUE: "#3B82F6",
	ItemRarity.YELLOW: "#FACC15",
	ItemRarity.ORANGE: "#F97316",
	ItemRarity.PURPLE: "#8B5CF6"
}

var rarity_names = {
	ItemRarity.WHITE: "Común",
	ItemRarity.BLUE: "Poco Común",
	ItemRarity.YELLOW: "Rara",
	ItemRarity.ORANGE: "Legendaria",
	ItemRarity.PURPLE: "Única"
}

# Definiciones completas de items
var items_database = {
	# ITEMS BLANCOS (15) - Básicos y comunes
	"basic_wand": {
		"id": "basic_wand",
		"name": "Varita Básica",
		"type": ItemType.WEAPON_SPELL,
		"rarity": ItemRarity.WHITE,
		"description": "Varita simple que aumenta ligeramente el daño mágico",
		"stat_modifiers": {"magic_damage": 1.1, "cast_speed": 1.05},
		"stackable": true,
		"max_stacks": 3,
		"drop_weight": 20
	},
	"minor_health": {
		"id": "minor_health",
		"name": "Poción de Vida Menor",
		"type": ItemType.PASSIVE,
		"rarity": ItemRarity.WHITE,
		"description": "Aumenta la vida máxima en pequeña cantidad",
		"stat_modifiers": {"max_health": 25},
		"stackable": true,
		"max_stacks": 5,
		"drop_weight": 25
	},
	"speed_boots": {
		"id": "speed_boots",
		"name": "Botas de Velocidad",
		"type": ItemType.PASSIVE,
		"rarity": ItemRarity.WHITE,
		"description": "Incrementa ligeramente la velocidad de movimiento",
		"stat_modifiers": {"move_speed": 1.08},
		"stackable": true,
		"max_stacks": 4,
		"drop_weight": 18
	},
	"mana_crystal": {
		"id": "mana_crystal",
		"name": "Cristal de Maná",
		"type": ItemType.PASSIVE,
		"rarity": ItemRarity.WHITE,
		"description": "Aumenta el maná máximo",
		"stat_modifiers": {"max_mana": 30},
		"stackable": true,
		"max_stacks": 6,
		"drop_weight": 22
	},
	"iron_ring": {
		"id": "iron_ring",
		"name": "Anillo de Hierro",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.WHITE,
		"description": "Proporciona resistencia básica",
		"stat_modifiers": {"damage_resistance": 0.05},
		"stackable": false,
		"special_effect": "basic_protection",
		"drop_weight": 15
	},
	"apprentice_robe": {
		"id": "apprentice_robe",
		"name": "Túnica de Aprendiz",
		"type": ItemType.PASSIVE,
		"rarity": ItemRarity.WHITE,
		"description": "Túnica que aumenta la regeneración de maná",
		"stat_modifiers": {"mana_regen": 1.15},
		"stackable": true,
		"max_stacks": 3,
		"drop_weight": 16
	},

	"lucky_coin": {
		"id": "lucky_coin",
		"name": "Moneda de la Suerte",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.WHITE,
		"description": "Aumenta ligeramente la suerte para drops",
		"stat_modifiers": {"luck": 1.1},
		"stackable": true,
		"max_stacks": 3,
		"drop_weight": 14
	},
	"wooden_staff": {
		"id": "wooden_staff",
		"name": "Bastón de Madera",
		"type": ItemType.WEAPON_SPELL,
		"rarity": ItemRarity.WHITE,
		"description": "Bastón básico que añade proyectil adicional",
		"stat_modifiers": {"projectile_count": 1},
		"stackable": true,
		"max_stacks": 2,
		"drop_weight": 19
	},
	"stamina_potion": {
		"id": "stamina_potion",
		"name": "Poción de Resistencia",
		"type": ItemType.PASSIVE,
		"rarity": ItemRarity.WHITE,
		"description": "Aumenta la resistencia general",
		"stat_modifiers": {"stamina": 1.12},
		"stackable": true,
		"max_stacks": 4,
		"drop_weight": 21
	},
	"leather_gloves": {
		"id": "leather_gloves",
		"name": "Guantes de Cuero",
		"type": ItemType.PASSIVE,
		"rarity": ItemRarity.WHITE,
		"description": "Mejora la precisión de los hechizos",
		"stat_modifiers": {"accuracy": 1.06},
		"stackable": true,
		"max_stacks": 3,
		"drop_weight": 18
	},
	"herb_pouch": {
		"id": "herb_pouch",
		"name": "Bolsa de Hierbas",
		"type": ItemType.PASSIVE,
		"rarity": ItemRarity.WHITE,
		"description": "Aumenta lentamente la regeneración de vida",
		"stat_modifiers": {"health_regen": 1.1},
		"stackable": true,
		"max_stacks": 5,
		"drop_weight": 16
	},
	"candle_light": {
		"id": "candle_light",
		"name": "Vela Mágica",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.WHITE,
		"description": "Aumenta el rango de visión",
		"stat_modifiers": {"vision_range": 1.15},
		"stackable": false,
		"special_effect": "light_aura",
		"drop_weight": 13
	},
	"simple_scroll": {
		"id": "simple_scroll",
		"name": "Pergamino Simple",
		"type": ItemType.WEAPON_SPELL,
		"rarity": ItemRarity.WHITE,
		"description": "Pergamino que mejora las combinaciones mágicas",
		"stat_modifiers": {"combination_bonus": 1.05},
		"stackable": true,
		"max_stacks": 3,
		"drop_weight": 15
	},
	"training_manual": {
		"id": "training_manual",
		"name": "Manual de Entrenamiento",
		"type": ItemType.PASSIVE,
		"rarity": ItemRarity.WHITE,
		"description": "Aumenta la experiencia ganada",
		"stat_modifiers": {"xp_multiplier": 1.08},
		"stackable": true,
		"max_stacks": 2,
		"drop_weight": 12
	},

	# ITEMS AZULES (12) - Poco comunes con efectos notables
	"flame_staff": {
		"id": "flame_staff",
		"name": "Bastón Llameante",
		"type": ItemType.WEAPON_SPELL,
		"rarity": ItemRarity.BLUE,
		"description": "Bastón que añade efecto de quemadura a los hechizos de fuego",
		"stat_modifiers": {"fire_damage": 1.25, "burn_duration": 1.5},
		"stackable": false,
		"special_effect": "fire_enchant",
		"drop_weight": 12
	},
	"frost_orb": {
		"id": "frost_orb",
		"name": "Orbe Gélido",
		"type": ItemType.WEAPON_SPELL,
		"rarity": ItemRarity.BLUE,
		"description": "Orbe que convierte 30% del daño en hielo",
		"stat_modifiers": {"ice_conversion": 0.3, "slow_chance": 0.2},
		"stackable": false,
		"special_effect": "frost_conversion",
		"drop_weight": 11
	},
	"lightning_rod": {
		"id": "lightning_rod",
		"name": "Vara de Rayos",
		"type": ItemType.WEAPON_SPELL,
		"rarity": ItemRarity.BLUE,
		"description": "Vara que hace que los rayos salten a enemigos adicionales",
		"stat_modifiers": {"chain_count": 2, "lightning_damage": 1.2},
		"stackable": false,
		"special_effect": "chain_lightning",
		"drop_weight": 10
	},
	"shadow_cloak": {
		"id": "shadow_cloak",
		"name": "Capa de Sombras",
		"type": ItemType.PASSIVE,
		"rarity": ItemRarity.BLUE,
		"description": "Capa que otorga 15% de probabilidad de evadir ataques",
		"stat_modifiers": {"dodge_chance": 0.15, "shadow_resistance": 0.3},
		"stackable": false,
		"special_effect": "shadow_dodge",
		"drop_weight": 9
	},
	"vitality_amulet": {
		"id": "vitality_amulet",
		"name": "Amuleto de Vitalidad",
		"type": ItemType.PASSIVE,
		"rarity": ItemRarity.BLUE,
		"description": "Amuleto que aumenta significativamente la vida máxima",
		"stat_modifiers": {"max_health": 75, "health_regen": 1.3},
		"stackable": false,
		"special_effect": "vitality_boost",
		"drop_weight": 13
	},
	"mage_boots": {
		"id": "mage_boots",
		"name": "Botas del Mago",
		"type": ItemType.PASSIVE,
		"rarity": ItemRarity.BLUE,
		"description": "Botas que reducen costos de maná al moverse",
		"stat_modifiers": {"move_speed": 1.2, "mana_efficiency": 1.15},
		"stackable": false,
		"special_effect": "mana_step",
		"drop_weight": 8
	},
	"crystal_focus": {
		"id": "crystal_focus",
		"name": "Foco de Cristal",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.BLUE,
		"description": "Cristal que amplifica el poder de las combinaciones mágicas",
		"stat_modifiers": {"combination_damage": 1.4, "mana_cost_reduction": 0.1},
		"stackable": false,
		"special_effect": "magic_amplifier",
		"drop_weight": 10
	},
	"berserker_ring": {
		"id": "berserker_ring",
		"name": "Anillo Berserker",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.BLUE,
		"description": "Anillo que aumenta daño cuando la vida está baja",
		"stat_modifiers": {"low_health_damage": 1.5},
		"stackable": false,
		"special_effect": "berserker_rage",
		"drop_weight": 7
	},
	"elemental_core": {
		"id": "elemental_core",
		"name": "Núcleo Elemental",
		"type": ItemType.PASSIVE,
		"rarity": ItemRarity.BLUE,
		"description": "Núcleo que potencia todos los elementos por igual",
		"stat_modifiers": {"elemental_damage": 1.2, "elemental_resistance": 0.15},
		"stackable": false,
		"special_effect": "elemental_harmony",
		"drop_weight": 11
	},
	"scholars_tome": {
		"id": "scholars_tome",
		"name": "Tomo del Erudito",
		"type": ItemType.PASSIVE,
		"rarity": ItemRarity.BLUE,
		"description": "Libro ancestral que aumenta la experiencia obtenida",
		"stat_modifiers": {"xp_multiplier": 1.35},
		"stackable": false,
		"special_effect": "knowledge_boost",
		"drop_weight": 9
	},
	"wind_walker": {
		"id": "wind_walker",
		"name": "Caminante del Viento",
		"type": ItemType.PASSIVE,
		"rarity": ItemRarity.BLUE,
		"description": "Permite atravesar enemigos y proyectiles ocasionalmente",
		"stat_modifiers": {"move_speed": 1.3, "phase_chance": 0.1},
		"stackable": false,
		"special_effect": "wind_walk",
		"drop_weight": 6
	},
	"mystic_pendant": {
		"id": "mystic_pendant",
		"name": "Colgante Místico",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.BLUE,
		"description": "Colgante que regenera maná al causar daño",
		"stat_modifiers": {"mana_on_damage": 5, "magic_damage": 1.15},
		"stackable": false,
		"special_effect": "mana_leech",
		"drop_weight": 8
	},

	# ITEMS AMARILLOS (10) - Raros con efectos únicos
	"arcane_mastery": {
		"id": "arcane_mastery",
		"name": "Maestría Arcana",
		"type": ItemType.WEAPON_SPELL,
		"rarity": ItemRarity.YELLOW,
		"description": "Permite lanzar dos hechizos simultáneamente",
		"stat_modifiers": {"dual_cast": true, "mana_cost": 1.3},
		"stackable": false,
		"special_effect": "dual_casting",
		"drop_weight": 5
	},
	"phoenix_feather": {
		"id": "phoenix_feather",
		"name": "Pluma de Fénix",
		"type": ItemType.PASSIVE,
		"rarity": ItemRarity.YELLOW,
		"description": "Renace una vez por nivel al morir",
		"stat_modifiers": {"resurrection": true, "fire_immunity": 0.5},
		"stackable": false,
		"special_effect": "phoenix_rebirth",
		"drop_weight": 3
	},
	"time_crystal": {
		"id": "time_crystal",
		"name": "Cristal Temporal",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.YELLOW,
		"description": "Ralentiza el tiempo durante 3 segundos cada 30 segundos",
		"stat_modifiers": {"time_slow_duration": 3, "time_slow_cooldown": 30},
		"stackable": false,
		"special_effect": "time_manipulation",
		"drop_weight": 4
	},
	"void_shard": {
		"id": "void_shard",
		"name": "Fragmento del Vacío",
		"type": ItemType.WEAPON_SPELL,
		"rarity": ItemRarity.YELLOW,
		"description": "Los hechizos tienen 20% de probabilidad de atravesar completamente",
		"stat_modifiers": {"void_pierce_chance": 0.2, "damage": 1.3},
		"stackable": false,
		"special_effect": "void_piercing",
		"drop_weight": 4
	},
	"life_steal_crown": {
		"id": "life_steal_crown",
		"name": "Corona Vampírica",
		"type": ItemType.PASSIVE,
		"rarity": ItemRarity.YELLOW,
		"description": "Roba vida con cada enemigo eliminado",
		"stat_modifiers": {"life_steal": 0.15, "max_health": 50},
		"stackable": false,
		"special_effect": "vampiric_crown",
		"drop_weight": 5
	},
	"mirror_shield": {
		"id": "mirror_shield",
		"name": "Escudo Espejo",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.YELLOW,
		"description": "30% de probabilidad de duplicar proyectiles propios",
		"stat_modifiers": {"mirror_chance": 0.3, "damage_resistance": 0.2},
		"stackable": false,
		"special_effect": "projectile_mirror",
		"drop_weight": 4
	},
	"chaos_orb": {
		"id": "chaos_orb",
		"name": "Orbe del Caos",
		"type": ItemType.WEAPON_SPELL,
		"rarity": ItemRarity.YELLOW,
		"description": "Cada hechizo tiene efecto aleatorio adicional",
		"stat_modifiers": {"chaos_effect": true, "damage_variance": 0.5},
		"stackable": false,
		"special_effect": "chaotic_spells",
		"drop_weight": 3
	},
	"nature_heart": {
		"id": "nature_heart",
		"name": "Corazón de la Naturaleza",
		"type": ItemType.PASSIVE,
		"rarity": ItemRarity.YELLOW,
		"description": "Regenera vida constantemente y purifica efectos negativos",
		"stat_modifiers": {"health_regen": 2.0, "debuff_immunity": 0.8},
		"stackable": false,
		"special_effect": "nature_blessing",
		"drop_weight": 5
	},
	"mana_overflow": {
		"id": "mana_overflow",
		"name": "Desbordamiento Mágico",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.YELLOW,
		"description": "Cuando el maná está lleno, los hechizos no consumen maná",
		"stat_modifiers": {"max_mana": 100, "overflow_effect": true},
		"stackable": false,
		"special_effect": "mana_overflow",
		"drop_weight": 4
	},
	"elemental_fusion": {
		"id": "elemental_fusion",
		"name": "Fusión Elemental",
		"type": ItemType.WEAPON_SPELL,
		"rarity": ItemRarity.YELLOW,
		"description": "Combina automáticamente elementos adyacentes",
		"stat_modifiers": {"auto_combination": true, "combination_bonus": 1.5},
		"stackable": false,
		"special_effect": "auto_fusion",
		"drop_weight": 3
	},

	# ITEMS NARANJAS (8) - Legendarios con efectos poderosos
	"reality_ripper": {
		"id": "reality_ripper",
		"name": "Desgarrador de Realidad",
		"type": ItemType.WEAPON_SPELL,
		"rarity": ItemRarity.ORANGE,
		"description": "Crea grietas dimensionales que persisten y causan daño continuo",
		"stat_modifiers": {"dimensional_rift": true, "damage": 2.0},
		"stackable": false,
		"special_effect": "reality_rift",
		"drop_weight": 2
	},
	"immortal_essence": {
		"id": "immortal_essence",
		"name": "Esencia Inmortal",
		"type": ItemType.PASSIVE,
		"rarity": ItemRarity.ORANGE,
		"description": "Inmunidad a la muerte por 5 segundos tras recibir daño fatal",
		"stat_modifiers": {"death_immunity_duration": 5, "max_health": 200},
		"stackable": false,
		"special_effect": "immortality_trigger",
		"drop_weight": 1
	},
	"omnimage_staff": {
		"id": "omnimage_staff",
		"name": "Bastón del Omnimago",
		"type": ItemType.WEAPON_SPELL,
		"rarity": ItemRarity.ORANGE,
		"description": "Domina todos los elementos y permite combinaciones imposibles",
		"stat_modifiers": {"all_elements": true, "impossible_combinations": true},
		"stackable": false,
		"special_effect": "omni_mastery",
		"drop_weight": 2
	},
	"world_ender": {
		"id": "world_ender",
		"name": "Fin del Mundo",
		"type": ItemType.WEAPON_SPELL,
		"rarity": ItemRarity.ORANGE,
		"description": "Cada kill aumenta permanentemente el daño de todos los hechizos",
		"stat_modifiers": {"permanent_damage_stack": 0.02, "base_damage": 1.5},
		"stackable": false,
		"special_effect": "escalating_power",
		"drop_weight": 1
	},
	"god_slayer_armor": {
		"id": "god_slayer_armor",
		"name": "Armadura Matadios",
		"type": ItemType.PASSIVE,
		"rarity": ItemRarity.ORANGE,
		"description": "Inmunidad a efectos de estado y refleja el 50% del daño recibido",
		"stat_modifiers": {"status_immunity": true, "damage_reflection": 0.5},
		"stackable": false,
		"special_effect": "divine_protection",
		"drop_weight": 2
	},
	"infinite_mana": {
		"id": "infinite_mana",
		"name": "Maná Infinito",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.ORANGE,
		"description": "Los hechizos nunca consumen maná, pero tienen 3x cooldown",
		"stat_modifiers": {"infinite_mana": true, "cooldown_multiplier": 3.0},
		"stackable": false,
		"special_effect": "limitless_power",
		"drop_weight": 1
	},
	"timeline_controller": {
		"id": "timeline_controller",
		"name": "Controlador Temporal",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.ORANGE,
		"description": "Puede revertir el tiempo 10 segundos una vez por nivel",
		"stat_modifiers": {"time_revert": 10, "temporal_resistance": 1.0},
		"stackable": false,
		"special_effect": "time_control",
		"drop_weight": 1
	},
	"cosmic_crown": {
		"id": "cosmic_crown",
		"name": "Corona Cósmica",
		"type": ItemType.PASSIVE,
		"rarity": ItemRarity.ORANGE,
		"description": "Otorga una habilidad aleatoria legendaria cada 60 segundos",
		"stat_modifiers": {"cosmic_ability_timer": 60, "all_stats": 1.3},
		"stackable": false,
		"special_effect": "cosmic_power",
		"drop_weight": 2
	},

	# ITEMS MORADOS (5) - Únicos y ultra raros
	"creators_will": {
		"id": "creators_will",
		"name": "Voluntad del Creador",
		"type": ItemType.WEAPON_SPELL,
		"rarity": ItemRarity.PURPLE,
		"description": "Permite crear nuevas magias combinando cualquier número de elementos",
		"stat_modifiers": {"unlimited_combination": true, "creation_power": true},
		"stackable": false,
		"special_effect": "divine_creation",
		"drop_weight": 1
	},
	"existence_anchor": {
		"id": "existence_anchor",
		"name": "Ancla de Existencia",
		"type": ItemType.PASSIVE,
		"rarity": ItemRarity.PURPLE,
		"description": "Inmunidad total a efectos de aniquilación y borrado de existencia",
		"stat_modifiers": {"existence_immunity": true, "reality_anchor": true},
		"stackable": false,
		"special_effect": "existential_protection",
		"drop_weight": 1
	},
	"multiverse_key": {
		"id": "multiverse_key",
		"name": "Llave del Multiverso",
		"type": ItemType.ACCESSORY,
		"rarity": ItemRarity.PURPLE,
		"description": "Accede a habilidades de versiones alternativas del jugador",
		"stat_modifiers": {"alternate_abilities": true, "multiverse_access": true},
		"stackable": false,
		"special_effect": "dimensional_abilities",
		"drop_weight": 1
	},
	"concept_destroyer": {
		"id": "concept_destroyer",
		"name": "Destructor de Conceptos",
		"type": ItemType.WEAPON_SPELL,
		"rarity": ItemRarity.PURPLE,
		"description": "Destruye conceptos abstractos como la resistencia, inmunidad o regeneración",
		"stat_modifiers": {"concept_destruction": true, "absolute_damage": true},
		"stackable": false,
		"special_effect": "conceptual_annihilation",
		"drop_weight": 1
	},
	"unity_of_all": {
		"id": "unity_of_all",
		"name": "Unidad de Todo",
		"type": ItemType.PASSIVE,
		"rarity": ItemRarity.PURPLE,
		"description": "Fusiona al jugador con el universo del juego, otorgando control total",
		"stat_modifiers": {"universal_unity": true, "omnipotence": true},
		"stackable": false,
		"special_effect": "cosmic_unity",
		"drop_weight": 1
	}
}

# Funciones de utilidad
func get_item(item_id: String):
	return items_database.get(item_id, null)

func get_items_by_rarity(rarity: int) -> Array:
	var filtered_items = []
	for item_id in items_database.keys():
		var item = items_database[item_id]
		if item.rarity == rarity:
			filtered_items.append(item)
	return filtered_items

func get_items_by_type(type: int) -> Array:
	var filtered_items = []
	for item_id in items_database.keys():
		var item = items_database[item_id]
		if item.type == type:
			filtered_items.append(item)
	return filtered_items

func get_weighted_random_item(player_level: int, luck_modifier: float = 1.0):
	var total_weight = 0.0
	var available_items = []
	
	# Ajustar probabilidades según nivel del jugador
	var rarity_multipliers = {
		ItemRarity.WHITE: max(0.1, 1.0 - (player_level * 0.05)),
		ItemRarity.BLUE: min(2.0, 0.5 + (player_level * 0.03)),
		ItemRarity.YELLOW: min(1.5, 0.1 + (player_level * 0.02)),
		ItemRarity.ORANGE: min(1.0, 0.01 + (player_level * 0.01)),
		ItemRarity.PURPLE: min(0.5, 0.001 + (player_level * 0.001))
	}
	
	for item_id in items_database.keys():
		var item = items_database[item_id]
		var adjusted_weight = item.drop_weight * rarity_multipliers[item.rarity] * luck_modifier
		total_weight += adjusted_weight
		available_items.append({
			"item": item,
			"weight": adjusted_weight
		})
	
	var random_value = randf() * total_weight
	var current_weight = 0.0
	
	for item_data in available_items:
		current_weight += item_data.weight
		if random_value <= current_weight:
			return item_data.item
	
	# Fallback al último item
	return available_items[-1].item if available_items.size() > 0 else null

func apply_item_effects(player_node: Node, item_id: String):
	var item = get_item(item_id)
	if not item:
		return false
	
	# Aplicar modificadores de stats
	if "stat_modifiers" in item:
		for stat in item.stat_modifiers.keys():
			var value = item.stat_modifiers[stat]
			if player_node.has_method("modify_stat"):
				player_node.modify_stat(stat, value)
	
	# Aplicar efectos especiales
	if "special_effect" in item:
		if player_node.has_method("apply_special_effect"):
			player_node.apply_special_effect(item.special_effect, item)
	
	return true

# Generar template de resource para Godot
func generate_item_resource_template(item_id: String) -> String:
	var item = get_item(item_id)
	if not item:
		return ""
	
	var template = """
extends Resource
class_name ItemResource

export var id: String = \"%s\"
export var name: String = \"%s\"
export var item_type: int = %d
export var rarity: int = %d
export var description: String = \"%s\"
export var stackable: bool = %s
export var stat_modifiers: Dictionary = %s
export var special_effect: String = \"%s\"
""" % [
		item.id,
		item.name,
		item.type,
		item.rarity,
		item.description,
		str(item.get("stackable", false)),
		str(item.get("stat_modifiers", {})),
		item.get("special_effect", "")
	]
	
	return template

# Funciones de utilidad para rareza
func get_rarity_color(rarity: int) -> Color:
	"""Obtener color de rareza como Color"""
	var hex_color = rarity_colors.get(rarity, "#FFFFFF")
	return Color(hex_color)

func get_rarity_name(rarity: int) -> String:
	"""Obtener nombre de rareza"""
	return rarity_names.get(rarity, "Común")

func get_rarity_hex_color(rarity: int) -> String:
	"""Obtener color de rareza como string hexadecimal"""
	return rarity_colors.get(rarity, "#FFFFFF")


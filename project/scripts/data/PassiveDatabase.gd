# PassiveDatabase.gd
# Base de datos de mejoras pasivas para el jugador
# Estas mejoras se pueden seleccionar al subir de nivel o comprar en tienda
#
# CATEGORÍAS:
# - combat: Mejoras de combate (daño, crítico, velocidad de ataque)
# - defense: Mejoras defensivas (vida, armadura, regeneración)
# - utility: Utilidades (pickup_range, movimiento, xp_mult)
# - special: Habilidades especiales y sinergias

extends Node
class_name PassiveDatabase

# ═══════════════════════════════════════════════════════════════════════════════
# MEJORAS PASIVAS
# ═══════════════════════════════════════════════════════════════════════════════

const PASSIVES: Dictionary = {
	# ───────────────────────────────────────────────────────────────────────────
	# UTILITY - Mejoras de utilidad
	# ───────────────────────────────────────────────────────────────────────────

	"magnet_1": {
		"id": "magnet_1",
		"name": "Imán Menor",
		"description": "Aumenta el rango de recolección en 25%",
		"icon": "res://assets/sprites/ui/passives/magnet.png",
		"category": "utility",
		"rarity": "common",
		"max_stacks": 4,
		"effect": {
			"type": "multiply_stat",
			"stat": "pickup_range",
			"value": 1.25
		}
	},

	"magnet_2": {
		"id": "magnet_2",
		"name": "Imán Mayor",
		"description": "Aumenta el rango de recolección en 50%",
		"icon": "res://assets/sprites/ui/passives/magnet_2.png",
		"category": "utility",
		"rarity": "uncommon",
		"max_stacks": 2,
		"effect": {
			"type": "multiply_stat",
			"stat": "pickup_range",
			"value": 1.5
		}
	},

	"vacuum": {
		"id": "vacuum",
		"name": "Vacío Magnético",
		"description": "Las monedas son atraídas desde mucho más lejos (+100 píxeles)",
		"icon": "res://assets/sprites/ui/passives/vacuum.png",
		"category": "utility",
		"rarity": "rare",
		"max_stacks": 1,
		"effect": {
			"type": "add_stat",
			"stat": "pickup_range_flat",
			"value": 100.0
		}
	},

	"xp_boost_1": {
		"id": "xp_boost_1",
		"name": "Sabiduría",
		"description": "Aumenta la experiencia ganada en 15%",
		"icon": "res://assets/sprites/ui/passives/xp_boost.png",
		"category": "utility",
		"rarity": "common",
		"max_stacks": 5,
		"effect": {
			"type": "multiply_stat",
			"stat": "xp_mult",
			"value": 1.15
		}
	},

	"speed_boost_1": {
		"id": "speed_boost_1",
		"name": "Botas Ligeras",
		"description": "Aumenta la velocidad de movimiento en 10%",
		"icon": "res://assets/sprites/ui/passives/speed.png",
		"category": "utility",
		"rarity": "common",
		"max_stacks": 5,
		"effect": {
			"type": "multiply_stat",
			"stat": "move_speed",
			"value": 1.1
		}
	},

	"luck_1": {
		"id": "luck_1",
		"name": "Trébol de 4 Hojas",
		"description": "Aumenta la suerte en 10% (mejores drops y opciones)",
		"icon": "res://assets/sprites/ui/passives/luck.png",
		"category": "utility",
		"rarity": "uncommon",
		"max_stacks": 5,
		"effect": {
			"type": "add_stat",
			"stat": "luck",
			"value": 0.1
		}
	},

	# ───────────────────────────────────────────────────────────────────────────
	# COMBAT - Mejoras de combate
	# ───────────────────────────────────────────────────────────────────────────

	"damage_1": {
		"id": "damage_1",
		"name": "Fuerza Interior",
		"description": "Aumenta el daño en 10%",
		"icon": "res://assets/sprites/ui/passives/damage.png",
		"category": "combat",
		"rarity": "common",
		"max_stacks": 10,
		"effect": {
			"type": "multiply_stat",
			"stat": "damage_mult",
			"value": 1.1
		}
	},

	"crit_chance_1": {
		"id": "crit_chance_1",
		"name": "Ojo Certero",
		"description": "Aumenta la probabilidad de crítico en 5%",
		"icon": "res://assets/sprites/ui/passives/crit_chance.png",
		"category": "combat",
		"rarity": "common",
		"max_stacks": 10,
		"effect": {
			"type": "add_stat",
			"stat": "crit_chance",
			"value": 0.05
		}
	},

	"crit_damage_1": {
		"id": "crit_damage_1",
		"name": "Golpe Devastador",
		"description": "Aumenta el daño crítico en 25%",
		"icon": "res://assets/sprites/ui/passives/crit_damage.png",
		"category": "combat",
		"rarity": "uncommon",
		"max_stacks": 5,
		"effect": {
			"type": "add_stat",
			"stat": "crit_damage",
			"value": 0.25
		}
	},

	"attack_speed_1": {
		"id": "attack_speed_1",
		"name": "Velocidad Arcana",
		"description": "Reduce el cooldown de ataques en 8%",
		"icon": "res://assets/sprites/ui/passives/attack_speed.png",
		"category": "combat",
		"rarity": "common",
		"max_stacks": 8,
		"effect": {
			"type": "multiply_stat",
			"stat": "cooldown_mult",
			"value": 0.92
		}
	},

	"area_1": {
		"id": "area_1",
		"name": "Expansión Mágica",
		"description": "Aumenta el área de efecto en 10%",
		"icon": "res://assets/sprites/ui/passives/area.png",
		"category": "combat",
		"rarity": "common",
		"max_stacks": 8,
		"effect": {
			"type": "multiply_stat",
			"stat": "area_mult",
			"value": 1.1
		}
	},

	# ───────────────────────────────────────────────────────────────────────────
	# DEFENSE - Mejoras defensivas
	# ───────────────────────────────────────────────────────────────────────────

	"max_health_1": {
		"id": "max_health_1",
		"name": "Vitalidad",
		"description": "Aumenta la vida máxima en 15",
		"icon": "res://assets/sprites/ui/passives/health.png",
		"category": "defense",
		"rarity": "common",
		"max_stacks": 10,
		"effect": {
			"type": "add_stat",
			"stat": "max_health",
			"value": 15.0
		}
	},

	"armor_1": {
		"id": "armor_1",
		"name": "Piel de Hierro",
		"description": "Reduce el daño recibido en 2 puntos",
		"icon": "res://assets/sprites/ui/passives/armor.png",
		"category": "defense",
		"rarity": "common",
		"max_stacks": 10,
		"effect": {
			"type": "add_stat",
			"stat": "armor",
			"value": 2.0
		}
	},

	"health_regen_1": {
		"id": "health_regen_1",
		"name": "Regeneración",
		"description": "Regenera 0.5 vida por segundo",
		"icon": "res://assets/sprites/ui/passives/regen.png",
		"category": "defense",
		"rarity": "uncommon",
		"max_stacks": 5,
		"effect": {
			"type": "add_stat",
			"stat": "health_regen",
			"value": 0.5
		}
	},

	# ───────────────────────────────────────────────────────────────────────────
	# SPECIAL - Mejoras especiales y sinergias
	# ───────────────────────────────────────────────────────────────────────────

	"coin_value_1": {
		"id": "coin_value_1",
		"name": "Avaricia",
		"description": "Las monedas valen 20% más",
		"icon": "res://assets/sprites/ui/passives/greed.png",
		"category": "special",
		"rarity": "uncommon",
		"max_stacks": 3,
		"effect": {
			"type": "multiply_stat",
			"stat": "coin_value_mult",
			"value": 1.2
		}
	},

	"coin_magnet_combo": {
		"id": "coin_magnet_combo",
		"name": "Rey Midas",
		"description": "Rango de recolección +100%, monedas +50% valor",
		"icon": "res://assets/sprites/ui/passives/midas.png",
		"category": "special",
		"rarity": "legendary",
		"max_stacks": 1,
		"effect": {
			"type": "multi",
			"effects": [
				{"type": "multiply_stat", "stat": "pickup_range", "value": 2.0},
				{"type": "multiply_stat", "stat": "coin_value_mult", "value": 1.5}
			]
		}
	},

	"streak_master": {
		"id": "streak_master",
		"name": "Maestro de Racha",
		"description": "El bonus de racha de monedas es el doble",
		"icon": "res://assets/sprites/ui/passives/streak.png",
		"category": "special",
		"rarity": "rare",
		"max_stacks": 1,
		"effect": {
			"type": "set_flag",
			"flag": "double_coin_streak",
			"value": true
		}
	},

	# ───────────────────────────────────────────────────────────────────────────
	# NUEVOS STATS - Defensivos avanzados
	# ───────────────────────────────────────────────────────────────────────────

	"dodge_1": {
		"id": "dodge_1",
		"name": "Reflejos",
		"description": "5% de probabilidad de esquivar ataques",
		"icon": "res://assets/sprites/ui/passives/dodge.png",
		"category": "defense",
		"rarity": "uncommon",
		"max_stacks": 6,  # Max 30%
		"effect": {
			"type": "add_stat",
			"stat": "dodge_chance",
			"value": 0.05
		}
	},

	"dodge_2": {
		"id": "dodge_2",
		"name": "Evasión Total",
		"description": "10% de probabilidad de esquivar ataques",
		"icon": "res://assets/sprites/ui/passives/dodge_2.png",
		"category": "defense",
		"rarity": "rare",
		"max_stacks": 3,  # Max 30%
		"effect": {
			"type": "add_stat",
			"stat": "dodge_chance",
			"value": 0.10
		}
	},

	"life_steal_1": {
		"id": "life_steal_1",
		"name": "Vampirismo",
		"description": "Recupera 3% del daño infligido como vida",
		"icon": "res://assets/sprites/ui/passives/lifesteal.png",
		"category": "defense",
		"rarity": "uncommon",
		"max_stacks": 5,  # Max 15%
		"effect": {
			"type": "add_stat",
			"stat": "life_steal",
			"value": 0.03
		}
	},

	"life_steal_2": {
		"id": "life_steal_2",
		"name": "Sed de Sangre",
		"description": "Recupera 8% del daño infligido como vida",
		"icon": "res://assets/sprites/ui/passives/lifesteal_2.png",
		"category": "defense",
		"rarity": "rare",
		"max_stacks": 2,  # Max 16%
		"effect": {
			"type": "add_stat",
			"stat": "life_steal",
			"value": 0.08
		}
	},

	# ───────────────────────────────────────────────────────────────────────────
	# NUEVOS STATS - Ofensivos avanzados
	# ───────────────────────────────────────────────────────────────────────────

	"projectile_speed_1": {
		"id": "projectile_speed_1",
		"name": "Proyectiles Rápidos",
		"description": "Aumenta la velocidad de proyectiles en 15%",
		"icon": "res://assets/sprites/ui/passives/proj_speed.png",
		"category": "combat",
		"rarity": "common",
		"max_stacks": 5,
		"effect": {
			"type": "multiply_stat",
			"stat": "projectile_speed_mult",
			"value": 1.15
		}
	},

	"duration_1": {
		"id": "duration_1",
		"name": "Persistencia",
		"description": "Aumenta la duración de efectos en 15%",
		"icon": "res://assets/sprites/ui/passives/duration.png",
		"category": "combat",
		"rarity": "common",
		"max_stacks": 5,
		"effect": {
			"type": "multiply_stat",
			"stat": "duration_mult",
			"value": 1.15
		}
	},

	"extra_projectiles_1": {
		"id": "extra_projectiles_1",
		"name": "Multidisparo",
		"description": "Dispara 1 proyectil adicional",
		"icon": "res://assets/sprites/ui/passives/multi.png",
		"category": "combat",
		"rarity": "rare",
		"max_stacks": 3,
		"effect": {
			"type": "add_stat",
			"stat": "extra_projectiles",
			"value": 1
		}
	},

	"knockback_1": {
		"id": "knockback_1",
		"name": "Impacto Fuerte",
		"description": "Aumenta el empuje a enemigos en 25%",
		"icon": "res://assets/sprites/ui/passives/knockback.png",
		"category": "combat",
		"rarity": "common",
		"max_stacks": 4,
		"effect": {
			"type": "multiply_stat",
			"stat": "knockback_mult",
			"value": 1.25
		}
	},

	# ───────────────────────────────────────────────────────────────────────────
	# COMBOS LEGENDARIOS
	# ───────────────────────────────────────────────────────────────────────────

	"glass_cannon": {
		"id": "glass_cannon",
		"name": "Cañón de Cristal",
		"description": "+50% Daño, +25% Crítico, -30% Vida máxima",
		"icon": "res://assets/sprites/ui/passives/glass_cannon.png",
		"category": "special",
		"rarity": "legendary",
		"max_stacks": 1,
		"effect": {
			"type": "multi",
			"effects": [
				{"type": "multiply_stat", "stat": "damage_mult", "value": 1.5},
				{"type": "add_stat", "stat": "crit_chance", "value": 0.25},
				{"type": "multiply_stat", "stat": "max_health", "value": 0.7}
			]
		}
	},

	"tank": {
		"id": "tank",
		"name": "Fortaleza",
		"description": "+50 Vida, +5 Armadura, 15% Esquivar, -20% Velocidad",
		"icon": "res://assets/sprites/ui/passives/tank.png",
		"category": "special",
		"rarity": "legendary",
		"max_stacks": 1,
		"effect": {
			"type": "multi",
			"effects": [
				{"type": "add_stat", "stat": "max_health", "value": 50},
				{"type": "add_stat", "stat": "armor", "value": 5},
				{"type": "add_stat", "stat": "dodge_chance", "value": 0.15},
				{"type": "multiply_stat", "stat": "move_speed", "value": 0.8}
			]
		}
	},

	"berserker": {
		"id": "berserker",
		"name": "Berserker",
		"description": "+30% Daño, +10% Robo de Vida, +20% Velocidad Ataque",
		"icon": "res://assets/sprites/ui/passives/berserker.png",
		"category": "special",
		"rarity": "legendary",
		"max_stacks": 1,
		"effect": {
			"type": "multi",
			"effects": [
				{"type": "multiply_stat", "stat": "damage_mult", "value": 1.3},
				{"type": "add_stat", "stat": "life_steal", "value": 0.10},
				{"type": "multiply_stat", "stat": "cooldown_mult", "value": 0.8}
			]
		}
	},

	"sniper": {
		"id": "sniper",
		"name": "Francotirador",
		"description": "+50% Crítico, +100% Daño Crítico, +30% Vel. Proyectil",
		"icon": "res://assets/sprites/ui/passives/sniper.png",
		"category": "special",
		"rarity": "legendary",
		"max_stacks": 1,
		"effect": {
			"type": "multi",
			"effects": [
				{"type": "add_stat", "stat": "crit_chance", "value": 0.50},
				{"type": "add_stat", "stat": "crit_damage", "value": 1.0},
				{"type": "multiply_stat", "stat": "projectile_speed_mult", "value": 1.3}
			]
		}
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# RARIDADES Y PESOS
# ═══════════════════════════════════════════════════════════════════════════════

const RARITY_WEIGHTS: Dictionary = {
	"common": 60,
	"uncommon": 25,
	"rare": 12,
	"legendary": 3
}

const RARITY_COLORS: Dictionary = {
	"common": Color(0.7, 0.7, 0.7),      # Gris
	"uncommon": Color(0.3, 0.8, 0.3),    # Verde
	"rare": Color(0.3, 0.5, 1.0),        # Azul
	"legendary": Color(1.0, 0.6, 0.0)    # Naranja
}

# ═══════════════════════════════════════════════════════════════════════════════
# API
# ═══════════════════════════════════════════════════════════════════════════════

static func get_passive(id: String) -> Dictionary:
	"""Obtener datos de un pasivo por ID"""
	return PASSIVES.get(id, {})

static func get_all_passives() -> Dictionary:
	"""Obtener todos los pasivos"""
	return PASSIVES

static func get_passives_by_category(category: String) -> Array:
	"""Obtener pasivos filtrados por categoría"""
	var result = []
	for id in PASSIVES:
		if PASSIVES[id].category == category:
			result.append(PASSIVES[id])
	return result

static func get_passives_by_rarity(rarity: String) -> Array:
	"""Obtener pasivos filtrados por rareza"""
	var result = []
	for id in PASSIVES:
		if PASSIVES[id].rarity == rarity:
			result.append(PASSIVES[id])
	return result

static func get_random_passives(count: int, exclude_ids: Array = [], luck_bonus: float = 0.0) -> Array:
	"""Obtener pasivos aleatorios respetando pesos de rareza"""
	var available = []

	# Recopilar pasivos disponibles
	for id in PASSIVES:
		if id not in exclude_ids:
			available.append(PASSIVES[id])

	if available.is_empty():
		return []

	# Calcular pesos totales con bonus de suerte
	var weighted_pool = []
	for passive in available:
		var weight = RARITY_WEIGHTS.get(passive.rarity, 10)

		# La suerte aumenta las probabilidades de rarezas altas
		if passive.rarity == "rare":
			weight *= (1.0 + luck_bonus * 0.5)
		elif passive.rarity == "legendary":
			weight *= (1.0 + luck_bonus)

		weighted_pool.append({"passive": passive, "weight": weight})

	# Seleccionar pasivos
	var selected = []
	for i in range(min(count, weighted_pool.size())):
		var total_weight = 0.0
		for item in weighted_pool:
			total_weight += item.weight

		var roll = randf() * total_weight
		var cumulative = 0.0

		for j in range(weighted_pool.size()):
			cumulative += weighted_pool[j].weight
			if roll <= cumulative:
				selected.append(weighted_pool[j].passive)
				weighted_pool.remove_at(j)
				break

	return selected

static func get_rarity_color(rarity: String) -> Color:
	"""Obtener color de rareza"""
	return RARITY_COLORS.get(rarity, Color.WHITE)

static func get_magnet_passives() -> Array:
	"""Obtener específicamente los pasivos de imán/pickup"""
	var result = []
	for id in PASSIVES:
		var passive = PASSIVES[id]
		if passive.effect.has("stat"):
			if "pickup" in passive.effect.stat or passive.effect.stat == "magnet":
				result.append(passive)
		elif passive.effect.type == "multi":
			for effect in passive.effect.effects:
				if effect.has("stat") and ("pickup" in effect.stat or effect.stat == "magnet"):
					result.append(passive)
					break
	return result

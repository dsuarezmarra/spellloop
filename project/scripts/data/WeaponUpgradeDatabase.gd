# WeaponUpgradeDatabase.gd
# Base de datos de mejoras para armas - VERSIÓN 2.0 EXPANDIDA
#
# SISTEMA DE MEJORAS:
# ═══════════════════════════════════════════════════════════════════════════════
# TIPOS:
# - GLOBAL: Afecta TODAS las armas (GlobalWeaponStats)
# - SPECIFIC: Se asigna a UN arma específica
# - WEAPON_ONLY: Solo funciona con un arma concreta
# - UNIQUE: Solo puedes tener 1 de esta mejora por run
# - CURSED: Tiene beneficio y penalización
# - CONDITIONAL: Efecto depende de una condición
# - CONSUMABLE: Se usa una vez y desaparece
#
# TIERS (colores en UI):
# - Tier 1: Blanco - Común (aparece minuto 0+)
# - Tier 2: Verde - Poco común (aparece minuto 3+)
# - Tier 3: Azul - Raro (aparece minuto 8+)
# - Tier 4: Amarillo - Épico (aparece minuto 15+)
# - Tier 5: Naranja - Legendario (muy raro, minuto 20+)
# - Único: Rojo - Solo 1 por run
# - Cursed: Púrpura - Trade-off
# ═══════════════════════════════════════════════════════════════════════════════

extends Node
class_name WeaponUpgradeDatabase

# ═══════════════════════════════════════════════════════════════════════════════
# ENUMS Y CONSTANTES
# ═══════════════════════════════════════════════════════════════════════════════

enum UpgradeType {
	GLOBAL,       # Afecta a todas las armas
	SPECIFIC,     # Se asigna a un arma
	WEAPON_ONLY,  # Solo para un arma concreta
	UNIQUE,       # Solo 1 por run
	CURSED,       # Trade-off
	CONDITIONAL,  # Efecto condicional
	CONSUMABLE    # Se consume al usarse
}

enum UpgradeRarity {
	COMMON = 1,
	UNCOMMON = 2,
	RARE = 3,
	EPIC = 4,
	LEGENDARY = 5
}

# Colores por tier (nuevos)
const TIER_COLORS: Dictionary = {
	1: Color(0.9, 0.9, 0.9),      # Blanco
	2: Color(0.3, 0.9, 0.3),      # Verde
	3: Color(0.4, 0.6, 1.0),      # Azul
	4: Color(1.0, 0.85, 0.2),     # Amarillo
	5: Color(1.0, 0.5, 0.1),      # Naranja
}

const UNIQUE_COLOR = Color(1.0, 0.3, 0.3)   # Rojo
const CURSED_COLOR = Color(0.7, 0.2, 0.8)   # Púrpura

# Colores legacy por rarity (compatibilidad)
const RARITY_COLORS: Dictionary = {
	"common": Color(0.9, 0.9, 0.9),
	"uncommon": Color(0.3, 0.9, 0.3),
	"rare": Color(0.4, 0.6, 1.0),
	"epic": Color(1.0, 0.85, 0.2),
	"legendary": Color(1.0, 0.5, 0.1)
}

const RARITY_NAMES: Dictionary = {
	"common": "Común",
	"uncommon": "Poco común",
	"rare": "Raro",
	"epic": "Épico",
	"legendary": "Legendario"
}

# ═══════════════════════════════════════════════════════════════════════════════
# MEJORAS GLOBALES (LevelUpPanel)
# Estas mejoras afectan a TODAS las armas automáticamente
# ═══════════════════════════════════════════════════════════════════════════════

const GLOBAL_UPGRADES: Dictionary = {
	# ─────────────────────────────────────────────────────────────────────────────
	# DAÑO
	# ─────────────────────────────────────────────────────────────────────────────
	"global_damage_1": {
		"id": "global_damage_1",
		"name": "Poder Menor",
		"description": "Todas las armas hacen +10% de daño.",
		"icon": "⚔️",
		"type": UpgradeType.GLOBAL,
		"rarity": "common",
		"tier": 1,
		"max_stacks": 5,
		"effects": [
			{"stat": "damage_mult", "value": 1.10, "operation": "multiply"}
		]
	},
	"global_damage_2": {
		"id": "global_damage_2",
		"name": "Poder",
		"description": "Todas las armas hacen +20% de daño.",
		"icon": "⚔️",
		"type": UpgradeType.GLOBAL,
		"rarity": "uncommon",
		"tier": 2,
		"max_stacks": 3,
		"effects": [
			{"stat": "damage_mult", "value": 1.20, "operation": "multiply"}
		]
	},
	"global_damage_3": {
		"id": "global_damage_3",
		"name": "Poder Mayor",
		"description": "Todas las armas hacen +35% de daño.",
		"icon": "⚔️",
		"type": UpgradeType.GLOBAL,
		"rarity": "rare",
		"tier": 3,
		"max_stacks": 2,
		"effects": [
			{"stat": "damage_mult", "value": 1.35, "operation": "multiply"}
		]
	},
	"global_damage_flat_1": {
		"id": "global_damage_flat_1",
		"name": "Filo Afilado",
		"description": "Todas las armas hacen +3 de daño.",
		"icon": "➕",
		"type": UpgradeType.GLOBAL,
		"rarity": "common",
		"tier": 1,
		"max_stacks": 5,
		"effects": [
			{"stat": "damage_flat", "value": 3, "operation": "add"}
		]
	},
	"global_damage_flat_2": {
		"id": "global_damage_flat_2",
		"name": "Filo Mortal",
		"description": "Todas las armas hacen +8 de daño.",
		"icon": "➕",
		"type": UpgradeType.GLOBAL,
		"rarity": "rare",
		"tier": 3,
		"max_stacks": 3,
		"effects": [
			{"stat": "damage_flat", "value": 8, "operation": "add"}
		]
	},

	# ─────────────────────────────────────────────────────────────────────────────
	# VELOCIDAD DE ATAQUE
	# ─────────────────────────────────────────────────────────────────────────────
	"global_attack_speed_1": {
		"id": "global_attack_speed_1",
		"name": "Reflejos",
		"description": "Todas las armas atacan +15% más rápido.",
		"icon": "⚡",
		"type": UpgradeType.GLOBAL,
		"rarity": "common",
		"tier": 1,
		"max_stacks": 5,
		"effects": [
			{"stat": "attack_speed_mult", "value": 1.15, "operation": "multiply"}
		]
	},
	"global_attack_speed_2": {
		"id": "global_attack_speed_2",
		"name": "Celeridad",
		"description": "Todas las armas atacan +25% más rápido.",
		"icon": "⚡",
		"type": UpgradeType.GLOBAL,
		"rarity": "uncommon",
		"tier": 2,
		"max_stacks": 3,
		"effects": [
			{"stat": "attack_speed_mult", "value": 1.25, "operation": "multiply"}
		]
	},
	"global_attack_speed_3": {
		"id": "global_attack_speed_3",
		"name": "Velocidad de la Luz",
		"description": "Todas las armas atacan +40% más rápido.",
		"icon": "⚡",
		"type": UpgradeType.GLOBAL,
		"rarity": "epic",
		"tier": 4,
		"max_stacks": 2,
		"effects": [
			{"stat": "attack_speed_mult", "value": 1.40, "operation": "multiply"}
		]
	},

	# ─────────────────────────────────────────────────────────────────────────────
	# ÁREA DE EFECTO
	# ─────────────────────────────────────────────────────────────────────────────
	"global_area_1": {
		"id": "global_area_1",
		"name": "Explosión Menor",
		"description": "Todas las áreas de efecto +15% más grandes.",
		"icon": "🌀",
		"type": UpgradeType.GLOBAL,
		"rarity": "common",
		"tier": 1,
		"max_stacks": 5,
		"effects": [
			{"stat": "area_mult", "value": 1.15, "operation": "multiply"}
		]
	},
	"global_area_2": {
		"id": "global_area_2",
		"name": "Explosión",
		"description": "Todas las áreas de efecto +30% más grandes.",
		"icon": "🌀",
		"type": UpgradeType.GLOBAL,
		"rarity": "rare",
		"tier": 3,
		"max_stacks": 3,
		"effects": [
			{"stat": "area_mult", "value": 1.30, "operation": "multiply"}
		]
	},

	# ─────────────────────────────────────────────────────────────────────────────
	# PROYECTILES
	# ─────────────────────────────────────────────────────────────────────────────
	"global_projectile_1": {
		"id": "global_projectile_1",
		"name": "Proyectil Extra",
		"description": "Todas las armas disparan +1 proyectil.",
		"icon": "🎯",
		"type": UpgradeType.GLOBAL,
		"rarity": "rare",
		"tier": 3,
		"max_stacks": 3,
		"effects": [
			{"stat": "extra_projectiles", "value": 1, "operation": "add"}
		]
	},
	"global_projectile_2": {
		"id": "global_projectile_2",
		"name": "Lluvia de Proyectiles",
		"description": "Todas las armas disparan +2 proyectiles.",
		"icon": "🎯",
		"type": UpgradeType.GLOBAL,
		"rarity": "legendary",
		"tier": 5,
		"max_stacks": 1,
		"effects": [
			{"stat": "extra_projectiles", "value": 2, "operation": "add"}
		]
	},
	"global_projectile_speed_1": {
		"id": "global_projectile_speed_1",
		"name": "Velocidad Proyectil",
		"description": "Todos los proyectiles +20% más rápidos.",
		"icon": "➡️",
		"type": UpgradeType.GLOBAL,
		"rarity": "common",
		"tier": 1,
		"max_stacks": 4,
		"effects": [
			{"stat": "projectile_speed_mult", "value": 1.20, "operation": "multiply"}
		]
	},

	# ─────────────────────────────────────────────────────────────────────────────
	# PENETRACIÓN
	# ─────────────────────────────────────────────────────────────────────────────
	"global_pierce_1": {
		"id": "global_pierce_1",
		"name": "Penetración",
		"description": "Todos los proyectiles atraviesan +1 enemigo.",
		"icon": "🔱",
		"type": UpgradeType.GLOBAL,
		"rarity": "uncommon",
		"tier": 2,
		"max_stacks": 3,
		"effects": [
			{"stat": "extra_pierce", "value": 1, "operation": "add"}
		]
	},
	"global_pierce_2": {
		"id": "global_pierce_2",
		"name": "Perforación Total",
		"description": "Todos los proyectiles atraviesan +3 enemigos.",
		"icon": "🔱",
		"type": UpgradeType.GLOBAL,
		"rarity": "epic",
		"tier": 4,
		"max_stacks": 2,
		"effects": [
			{"stat": "extra_pierce", "value": 3, "operation": "add"}
		]
	},

	# ─────────────────────────────────────────────────────────────────────────────
	# CRÍTICOS
	# ─────────────────────────────────────────────────────────────────────────────
	"global_crit_chance_1": {
		"id": "global_crit_chance_1",
		"name": "Ojo Crítico",
		"description": "+5% probabilidad de crítico.",
		"icon": "🎯",
		"type": UpgradeType.GLOBAL,
		"rarity": "common",
		"tier": 1,
		"max_stacks": 6,
		"effects": [
			{"stat": "crit_chance", "value": 0.05, "operation": "add"}
		]
	},
	"global_crit_chance_2": {
		"id": "global_crit_chance_2",
		"name": "Precisión Mortal",
		"description": "+12% probabilidad de crítico.",
		"icon": "🎯",
		"type": UpgradeType.GLOBAL,
		"rarity": "rare",
		"tier": 3,
		"max_stacks": 3,
		"effects": [
			{"stat": "crit_chance", "value": 0.12, "operation": "add"}
		]
	},
	"global_crit_damage_1": {
		"id": "global_crit_damage_1",
		"name": "Golpe Devastador",
		"description": "+25% daño crítico.",
		"icon": "💢",
		"type": UpgradeType.GLOBAL,
		"rarity": "uncommon",
		"tier": 2,
		"max_stacks": 4,
		"effects": [
			{"stat": "crit_damage", "value": 0.25, "operation": "add"}
		]
	},
	"global_crit_damage_2": {
		"id": "global_crit_damage_2",
		"name": "Ejecución",
		"description": "+50% daño crítico.",
		"icon": "💢",
		"type": UpgradeType.GLOBAL,
		"rarity": "epic",
		"tier": 4,
		"max_stacks": 2,
		"effects": [
			{"stat": "crit_damage", "value": 0.50, "operation": "add"}
		]
	},

	# ─────────────────────────────────────────────────────────────────────────────
	# DURACIÓN Y EMPUJE
	# ─────────────────────────────────────────────────────────────────────────────
	"global_duration_1": {
		"id": "global_duration_1",
		"name": "Persistencia",
		"description": "Efectos de armas duran +20% más.",
		"icon": "⌛",
		"type": UpgradeType.GLOBAL,
		"rarity": "uncommon",
		"tier": 2,
		"max_stacks": 4,
		"effects": [
			{"stat": "duration_mult", "value": 1.20, "operation": "multiply"}
		]
	},
	"global_knockback_1": {
		"id": "global_knockback_1",
		"name": "Impacto",
		"description": "Todas las armas empujan +30% más fuerte.",
		"icon": "💥",
		"type": UpgradeType.GLOBAL,
		"rarity": "common",
		"tier": 1,
		"max_stacks": 4,
		"effects": [
			{"stat": "knockback_mult", "value": 1.30, "operation": "multiply"}
		]
	},
	"global_range_1": {
		"id": "global_range_1",
		"name": "Alcance Extendido",
		"description": "Todas las armas +15% de alcance.",
		"icon": "🎯",
		"type": UpgradeType.GLOBAL,
		"rarity": "common",
		"tier": 1,
		"max_stacks": 4,
		"effects": [
			{"stat": "range_mult", "value": 1.15, "operation": "multiply"}
		]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# TIER 1 - MEJORAS COMUNES ADICIONALES
	# ─────────────────────────────────────────────────────────────────────────────
	"global_damage_4": {
		"id": "global_damage_4",
		"name": "Poder Superior",
		"description": "Todas las armas hacen +50% de daño.",
		"icon": "⚔️",
		"type": UpgradeType.GLOBAL,
		"rarity": "epic",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "damage_mult", "value": 1.50, "operation": "multiply"}]
	},
	"global_damage_5": {
		"id": "global_damage_5",
		"name": "Poder Absoluto",
		"description": "Todas las armas hacen +75% de daño.",
		"icon": "⚔️",
		"type": UpgradeType.GLOBAL,
		"rarity": "legendary",
		"tier": 5,
		"max_stacks": 1,
		"effects": [{"stat": "damage_mult", "value": 1.75, "operation": "multiply"}]
	},
	"global_damage_flat_3": {
		"id": "global_damage_flat_3",
		"name": "Filo Letal",
		"description": "Todas las armas hacen +15 de daño.",
		"icon": "➕",
		"type": UpgradeType.GLOBAL,
		"rarity": "epic",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "damage_flat", "value": 15, "operation": "add"}]
	},
	"global_damage_flat_4": {
		"id": "global_damage_flat_4",
		"name": "Filo Legendario",
		"description": "Todas las armas hacen +25 de daño.",
		"icon": "➕",
		"type": UpgradeType.GLOBAL,
		"rarity": "legendary",
		"tier": 5,
		"max_stacks": 1,
		"effects": [{"stat": "damage_flat", "value": 25, "operation": "add"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ÁREA - TIERS ADICIONALES
	# ─────────────────────────────────────────────────────────────────────────────
	"global_area_3": {
		"id": "global_area_3",
		"name": "Detonación",
		"description": "Todas las áreas de efecto +50% más grandes.",
		"icon": "🌀",
		"type": UpgradeType.GLOBAL,
		"rarity": "epic",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "area_mult", "value": 1.50, "operation": "multiply"}]
	},
	"global_area_4": {
		"id": "global_area_4",
		"name": "Cataclismo",
		"description": "Todas las áreas de efecto +75% más grandes.",
		"icon": "🌀",
		"type": UpgradeType.GLOBAL,
		"rarity": "legendary",
		"tier": 5,
		"max_stacks": 1,
		"effects": [{"stat": "area_mult", "value": 1.75, "operation": "multiply"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# VELOCIDAD DE ATAQUE - TIERS ADICIONALES
	# ─────────────────────────────────────────────────────────────────────────────
	"global_attack_speed_4": {
		"id": "global_attack_speed_4",
		"name": "Frenesí",
		"description": "Todas las armas atacan +60% más rápido.",
		"icon": "⚡",
		"type": UpgradeType.GLOBAL,
		"rarity": "legendary",
		"tier": 5,
		"max_stacks": 1,
		"effects": [{"stat": "attack_speed_mult", "value": 1.60, "operation": "multiply"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# COOLDOWN
	# ─────────────────────────────────────────────────────────────────────────────
	"global_cooldown_1": {
		"id": "global_cooldown_1",
		"name": "Fluidez",
		"description": "-10% tiempo de recarga.",
		"icon": "⏱️",
		"type": UpgradeType.GLOBAL,
		"rarity": "common",
		"tier": 1,
		"max_stacks": 5,
		"effects": [{"stat": "cooldown_mult", "value": 0.90, "operation": "multiply"}]
	},
	"global_cooldown_2": {
		"id": "global_cooldown_2",
		"name": "Eficiencia",
		"description": "-20% tiempo de recarga.",
		"icon": "⏱️",
		"type": UpgradeType.GLOBAL,
		"rarity": "uncommon",
		"tier": 2,
		"max_stacks": 3,
		"effects": [{"stat": "cooldown_mult", "value": 0.80, "operation": "multiply"}]
	},
	"global_cooldown_3": {
		"id": "global_cooldown_3",
		"name": "Maestría",
		"description": "-30% tiempo de recarga.",
		"icon": "⏱️",
		"type": UpgradeType.GLOBAL,
		"rarity": "rare",
		"tier": 3,
		"max_stacks": 2,
		"effects": [{"stat": "cooldown_mult", "value": 0.70, "operation": "multiply"}]
	},
	"global_cooldown_4": {
		"id": "global_cooldown_4",
		"name": "Perfección",
		"description": "-40% tiempo de recarga.",
		"icon": "⏱️",
		"type": UpgradeType.GLOBAL,
		"rarity": "epic",
		"tier": 4,
		"max_stacks": 1,
		"effects": [{"stat": "cooldown_mult", "value": 0.60, "operation": "multiply"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# CRÍTICOS - TIERS ADICIONALES
	# ─────────────────────────────────────────────────────────────────────────────
	"global_crit_chance_3": {
		"id": "global_crit_chance_3",
		"name": "Ojo del Francotirador",
		"description": "+20% probabilidad de crítico.",
		"icon": "🎯",
		"type": UpgradeType.GLOBAL,
		"rarity": "epic",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "crit_chance", "value": 0.20, "operation": "add"}]
	},
	"global_crit_damage_3": {
		"id": "global_crit_damage_3",
		"name": "Aniquilación",
		"description": "+100% daño crítico.",
		"icon": "💢",
		"type": UpgradeType.GLOBAL,
		"rarity": "legendary",
		"tier": 5,
		"max_stacks": 1,
		"effects": [{"stat": "crit_damage", "value": 1.0, "operation": "add"}]
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# MEJORAS ESPECÍFICAS (Cofres, Bosses, Élites)
# Estas mejoras se asignan a UN arma específica elegida por el jugador
# ═══════════════════════════════════════════════════════════════════════════════

const SPECIFIC_UPGRADES: Dictionary = {
	# ─────────────────────────────────────────────────────────────────────────────
	# DAÑO ESPECÍFICO
	# ─────────────────────────────────────────────────────────────────────────────
	"specific_damage_1": {
		"id": "specific_damage_1",
		"name": "Potenciador Menor",
		"description": "Un arma hace +20% de daño.",
		"icon": "⚔️",
		"type": UpgradeType.SPECIFIC,
		"rarity": "uncommon",
		"tier": 2,
		"effects": [
			{"stat": "damage_mult", "value": 1.20, "operation": "multiply"}
		]
	},
	"specific_damage_2": {
		"id": "specific_damage_2",
		"name": "Potenciador",
		"description": "Un arma hace +40% de daño.",
		"icon": "⚔️",
		"type": UpgradeType.SPECIFIC,
		"rarity": "rare",
		"tier": 3,
		"effects": [
			{"stat": "damage_mult", "value": 1.40, "operation": "multiply"}
		]
	},
	"specific_damage_3": {
		"id": "specific_damage_3",
		"name": "Potenciador Supremo",
		"description": "Un arma hace +75% de daño.",
		"icon": "⚔️",
		"type": UpgradeType.SPECIFIC,
		"rarity": "legendary",
		"tier": 5,
		"effects": [
			{"stat": "damage_mult", "value": 1.75, "operation": "multiply"}
		]
	},

	# ─────────────────────────────────────────────────────────────────────────────
	# VELOCIDAD DE ATAQUE ESPECÍFICA
	# ─────────────────────────────────────────────────────────────────────────────
	"specific_attack_speed_1": {
		"id": "specific_attack_speed_1",
		"name": "Acelerador",
		"description": "Un arma ataca +35% más rápido.",
		"icon": "⚡",
		"type": UpgradeType.SPECIFIC,
		"rarity": "rare",
		"tier": 3,
		"effects": [
			{"stat": "attack_speed_mult", "value": 1.35, "operation": "multiply"}
		]
	},
	"specific_attack_speed_2": {
		"id": "specific_attack_speed_2",
		"name": "Frenesí",
		"description": "Un arma ataca +60% más rápido.",
		"icon": "⚡",
		"type": UpgradeType.SPECIFIC,
		"rarity": "legendary",
		"tier": 5,
		"effects": [
			{"stat": "attack_speed_mult", "value": 1.60, "operation": "multiply"}
		]
	},

	# ─────────────────────────────────────────────────────────────────────────────
	# PROYECTILES ESPECÍFICOS
	# ─────────────────────────────────────────────────────────────────────────────
	"specific_projectile_1": {
		"id": "specific_projectile_1",
		"name": "Disparo Doble",
		"description": "Un arma dispara +1 proyectil.",
		"icon": "🎯",
		"type": UpgradeType.SPECIFIC,
		"rarity": "rare",
		"tier": 3,
		"effects": [
			{"stat": "extra_projectiles", "value": 1, "operation": "add"}
		]
	},
	"specific_projectile_2": {
		"id": "specific_projectile_2",
		"name": "Disparo Triple",
		"description": "Un arma dispara +2 proyectiles.",
		"icon": "🎯",
		"type": UpgradeType.SPECIFIC,
		"rarity": "epic",
		"tier": 4,
		"effects": [
			{"stat": "extra_projectiles", "value": 2, "operation": "add"}
		]
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# MEJORAS EXCLUSIVAS POR ARMA (Cofres, Bosses)
# Estas mejoras solo funcionan con un arma específica
# ═══════════════════════════════════════════════════════════════════════════════

const WEAPON_SPECIFIC_UPGRADES: Dictionary = {
	# ─────────────────────────────────────────────────────────────────────────────
	# ICE WAND
	# ─────────────────────────────────────────────────────────────────────────────
	"ice_wand_frost_nova": {
		"id": "ice_wand_frost_nova",
		"name": "Nova de Escarcha",
		"description": "Ice Wand dispara +2 proyectiles en todas direcciones.",
		"icon": "❄️",
		"type": UpgradeType.WEAPON_ONLY,
		"weapon_id": "ice_wand",
		"rarity": "epic",
		"tier": 4,
		"effects": [
			{"stat": "extra_projectiles", "value": 2, "operation": "add"},
			{"stat": "area_mult", "value": 1.30, "operation": "multiply"}
		]
	},
	"ice_wand_deep_freeze": {
		"id": "ice_wand_deep_freeze",
		"name": "Congelación Profunda",
		"description": "Ice Wand ralentiza un 20% más y dura más.",
		"icon": "❄️",
		"type": UpgradeType.WEAPON_ONLY,
		"weapon_id": "ice_wand",
		"rarity": "rare",
		"tier": 3,
		"effects": [
			{"stat": "effect_value", "value": 0.20, "operation": "add"},
			{"stat": "effect_duration", "value": 1.0, "operation": "add"}
		]
	},

	# ─────────────────────────────────────────────────────────────────────────────
	# FIRE WAND
	# ─────────────────────────────────────────────────────────────────────────────
	"fire_wand_inferno": {
		"id": "fire_wand_inferno",
		"name": "Infierno",
		"description": "Fire Wand hace +50% daño y quemaduras más fuertes.",
		"icon": "🔥",
		"type": UpgradeType.WEAPON_ONLY,
		"weapon_id": "fire_wand",
		"rarity": "epic",
		"tier": 4,
		"effects": [
			{"stat": "damage_mult", "value": 1.50, "operation": "multiply"},
			{"stat": "effect_value", "value": 2.0, "operation": "add"}
		]
	},
	"fire_wand_spread": {
		"id": "fire_wand_spread",
		"name": "Propagación",
		"description": "Fire Wand dispara +1 proyectil.",
		"icon": "🔥",
		"type": UpgradeType.WEAPON_ONLY,
		"weapon_id": "fire_wand",
		"rarity": "rare",
		"tier": 3,
		"effects": [
			{"stat": "extra_projectiles", "value": 1, "operation": "add"}
		]
	},

	# ─────────────────────────────────────────────────────────────────────────────
	# LIGHTNING WAND
	# ─────────────────────────────────────────────────────────────────────────────
	"lightning_wand_chain_master": {
		"id": "lightning_wand_chain_master",
		"name": "Maestro del Rayo",
		"description": "Lightning Wand salta a +2 enemigos adicionales.",
		"icon": "⚡",
		"type": UpgradeType.WEAPON_ONLY,
		"weapon_id": "lightning_wand",
		"rarity": "epic",
		"tier": 4,
		"effects": [
			{"stat": "effect_value", "value": 2, "operation": "add"}
		]
	},
	"lightning_wand_overcharge": {
		"id": "lightning_wand_overcharge",
		"name": "Sobrecarga",
		"description": "Lightning Wand +40% daño y +30% velocidad.",
		"icon": "⚡",
		"type": UpgradeType.WEAPON_ONLY,
		"weapon_id": "lightning_wand",
		"rarity": "rare",
		"tier": 3,
		"effects": [
			{"stat": "damage_mult", "value": 1.40, "operation": "multiply"},
			{"stat": "attack_speed_mult", "value": 1.30, "operation": "multiply"}
		]
	},

	# ─────────────────────────────────────────────────────────────────────────────
	# SHADOW DAGGER
	# ─────────────────────────────────────────────────────────────────────────────
	"shadow_dagger_assassin": {
		"id": "shadow_dagger_assassin",
		"name": "Arte del Asesino",
		"description": "Shadow Dagger +50% daño crítico y +10% prob. crítico.",
		"icon": "🗡️",
		"type": UpgradeType.WEAPON_ONLY,
		"weapon_id": "shadow_dagger",
		"rarity": "epic",
		"tier": 4,
		"effects": [
			{"stat": "crit_damage", "value": 0.50, "operation": "add"},
			{"stat": "crit_chance", "value": 0.10, "operation": "add"}
		]
	},
	"shadow_dagger_multi": {
		"id": "shadow_dagger_multi",
		"name": "Dagas Múltiples",
		"description": "Shadow Dagger dispara +2 dagas.",
		"icon": "🗡️",
		"type": UpgradeType.WEAPON_ONLY,
		"weapon_id": "shadow_dagger",
		"rarity": "rare",
		"tier": 3,
		"effects": [
			{"stat": "extra_projectiles", "value": 2, "operation": "add"}
		]
	},

	# ─────────────────────────────────────────────────────────────────────────────
	# NATURE STAFF
	# ─────────────────────────────────────────────────────────────────────────────
	"nature_staff_overgrowth": {
		"id": "nature_staff_overgrowth",
		"name": "Sobrecrecimiento",
		"description": "Nature Staff +2 proyectiles y +30% área.",
		"icon": "🌿",
		"type": UpgradeType.WEAPON_ONLY,
		"weapon_id": "nature_staff",
		"rarity": "epic",
		"tier": 4,
		"effects": [
			{"stat": "extra_projectiles", "value": 2, "operation": "add"},
			{"stat": "area_mult", "value": 1.30, "operation": "multiply"}
		]
	},

	# ─────────────────────────────────────────────────────────────────────────────
	# ARCANE ORB
	# ─────────────────────────────────────────────────────────────────────────────
	"arcane_orb_expansion": {
		"id": "arcane_orb_expansion",
		"name": "Expansión Arcana",
		"description": "Arcane Orb +2 orbes y órbita más amplia.",
		"icon": "💜",
		"type": UpgradeType.WEAPON_ONLY,
		"weapon_id": "arcane_orb",
		"rarity": "epic",
		"tier": 4,
		"effects": [
			{"stat": "extra_projectiles", "value": 2, "operation": "add"},
			{"stat": "range_mult", "value": 1.40, "operation": "multiply"}
		]
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# FUNCIONES DE ACCESO
# ═══════════════════════════════════════════════════════════════════════════════

static func get_global_upgrade(upgrade_id: String) -> Dictionary:
	"""Obtener mejora global por ID"""
	return GLOBAL_UPGRADES.get(upgrade_id, {})

static func get_specific_upgrade(upgrade_id: String) -> Dictionary:
	"""Obtener mejora específica por ID"""
	return SPECIFIC_UPGRADES.get(upgrade_id, {})

static func get_weapon_upgrade(upgrade_id: String) -> Dictionary:
	"""Obtener mejora de arma específica por ID"""
	return WEAPON_SPECIFIC_UPGRADES.get(upgrade_id, {})

static func get_upgrade(upgrade_id: String) -> Dictionary:
	"""Buscar mejora en todas las categorías"""
	if GLOBAL_UPGRADES.has(upgrade_id):
		return GLOBAL_UPGRADES[upgrade_id]
	if SPECIFIC_UPGRADES.has(upgrade_id):
		return SPECIFIC_UPGRADES[upgrade_id]
	if WEAPON_SPECIFIC_UPGRADES.has(upgrade_id):
		return WEAPON_SPECIFIC_UPGRADES[upgrade_id]
	return {}

static func get_all_global_upgrades() -> Array:
	"""Obtener todas las mejoras globales"""
	return GLOBAL_UPGRADES.values()

static func get_all_specific_upgrades() -> Array:
	"""Obtener todas las mejoras específicas"""
	return SPECIFIC_UPGRADES.values()

static func get_upgrades_for_weapon(weapon_id: String) -> Array:
	"""Obtener mejoras exclusivas para un arma"""
	var result = []
	for upgrade in WEAPON_SPECIFIC_UPGRADES.values():
		if upgrade.get("weapon_id") == weapon_id:
			result.append(upgrade)
	return result

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE SELECCIÓN CON SUERTE Y TIEMPO
# ═══════════════════════════════════════════════════════════════════════════════

static func get_random_global_upgrades(count: int, excluded_ids: Array, luck: float, game_time_minutes: float) -> Array:
	"""
	Obtener mejoras globales aleatorias con sistema de tiers basado en suerte y tiempo.
	
	luck: 0.0 = normal, valores positivos aumentan probabilidad de mejores tiers
	game_time_minutes: tiempo de juego en minutos
	
	Sistema de tiers por tiempo:
	- Min 0-3: Tier 1 dominante (80%), Tier 2 (18%), Tier 3 (2%)
	- Min 3-8: Tier 1 (50%), Tier 2 (35%), Tier 3 (13%), Tier 4 (2%)
	- Min 8-15: Tier 1 (25%), Tier 2 (35%), Tier 3 (30%), Tier 4 (9%), Tier 5 (1%)
	- Min 15-25: Tier 1 (10%), Tier 2 (25%), Tier 3 (35%), Tier 4 (25%), Tier 5 (5%)
	- Min 25+: Tier 1 (5%), Tier 2 (15%), Tier 3 (30%), Tier 4 (35%), Tier 5 (15%)
	"""
	var tier_weights = _calculate_tier_weights(game_time_minutes, luck)
	var available = []
	
	for upgrade in GLOBAL_UPGRADES.values():
		if upgrade.id in excluded_ids:
			continue
		available.append(upgrade)
	
	if available.is_empty():
		return []
	
	# Seleccionar upgrades basados en tier weights
	var selected = []
	var attempts = 0
	var max_attempts = count * 10
	
	while selected.size() < count and attempts < max_attempts:
		attempts += 1
		
		# Seleccionar tier basado en pesos
		var selected_tier = _weighted_random_tier(tier_weights)
		
		# Filtrar upgrades del tier seleccionado
		var tier_upgrades = available.filter(func(u): return u.get("tier", 1) == selected_tier)
		
		if tier_upgrades.is_empty():
			continue
		
		var upgrade = tier_upgrades[randi() % tier_upgrades.size()]
		
		# Evitar duplicados
		var already_selected = false
		for s in selected:
			if s.id == upgrade.id:
				already_selected = true
				break
		
		if not already_selected:
			selected.append(upgrade)
	
	return selected

static func _calculate_tier_weights(game_time_minutes: float, luck: float) -> Dictionary:
	"""Calcular pesos de cada tier basado en tiempo y suerte"""
	var weights = {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0}
	
	# Pesos base por tiempo
	if game_time_minutes < 3.0:
		weights = {1: 0.80, 2: 0.18, 3: 0.02, 4: 0.0, 5: 0.0}
	elif game_time_minutes < 8.0:
		weights = {1: 0.50, 2: 0.35, 3: 0.13, 4: 0.02, 5: 0.0}
	elif game_time_minutes < 15.0:
		weights = {1: 0.25, 2: 0.35, 3: 0.30, 4: 0.09, 5: 0.01}
	elif game_time_minutes < 25.0:
		weights = {1: 0.10, 2: 0.25, 3: 0.35, 4: 0.25, 5: 0.05}
	else:
		weights = {1: 0.05, 2: 0.15, 3: 0.30, 4: 0.35, 5: 0.15}
	
	# Aplicar bonus de suerte (mover peso de tiers bajos a altos)
	if luck > 0:
		var luck_factor = clampf(luck * 0.1, 0.0, 0.3)  # Máximo 30% de shift
		
		# Reducir tier 1 y 2, aumentar tier 3, 4, 5
		var shift_from_low = (weights[1] + weights[2]) * luck_factor
		weights[1] *= (1.0 - luck_factor)
		weights[2] *= (1.0 - luck_factor * 0.5)
		weights[3] += shift_from_low * 0.4
		weights[4] += shift_from_low * 0.4
		weights[5] += shift_from_low * 0.2
	
	return weights

static func _weighted_random_tier(weights: Dictionary) -> int:
	"""Seleccionar tier basado en pesos"""
	var total = 0.0
	for w in weights.values():
		total += w
	
	var roll = randf() * total
	var cumulative = 0.0
	
	for tier in weights:
		cumulative += weights[tier]
		if roll <= cumulative:
			return tier
	
	return 1  # Fallback a tier 1

static func get_rarity_color(rarity: String) -> Color:
	"""Obtener color de rareza"""
	return RARITY_COLORS.get(rarity, Color.WHITE)

static func get_rarity_name(rarity: String) -> String:
	"""Obtener nombre de rareza en español"""
	return RARITY_NAMES.get(rarity, "Desconocido")

# PlayerUpgradeDatabase.gd
# Base de datos de mejoras PARA EL JUGADOR (no armas)
# 
# Incluye:
# - Mejoras defensivas (HP, armor, dodge, etc.)
# - Mejoras de utilidad (velocidad, XP, suerte, etc.)
# - Mejoras CURSED (trade-off: beneficio + penalización)
# - Mejoras ÚNICAS (solo 1 por run)
# - Mejoras CONDICIONALES (efecto basado en condición)
#
# SISTEMA DE TIERS (colores):
# - Tier 1: Blanco - Común
# - Tier 2: Verde - Poco común  
# - Tier 3: Azul - Raro
# - Tier 4: Amarillo - Épico
# - Tier 5: Naranja - Legendario
# - Único: Rojo
# - Cursed: Púrpura

extends Node
class_name PlayerUpgradeDatabase

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTES
# ═══════════════════════════════════════════════════════════════════════════════

enum UpgradeCategory {
	DEFENSIVE,
	UTILITY,
	CURSED,
	UNIQUE,
	CONDITIONAL
}

# ═══════════════════════════════════════════════════════════════════════════════
# MEJORAS DEFENSIVAS
# ═══════════════════════════════════════════════════════════════════════════════

const DEFENSIVE_UPGRADES: Dictionary = {
	# ─────────────────────────────────────────────────────────────────────────────
	# VIDA MÁXIMA
	# ─────────────────────────────────────────────────────────────────────────────
	"health_1": {
		"id": "health_1",
		"name": "Vitalidad Menor",
		"description": "+10 Vida máxima.",
		"icon": "❤️",
		"category": "defensive",
		"tier": 1,
		"max_stacks": 10,
		"effects": [{"stat": "max_health", "value": 10, "operation": "add"}]
	},
	"health_2": {
		"id": "health_2",
		"name": "Vitalidad",
		"description": "+25 Vida máxima.",
		"icon": "❤️",
		"category": "defensive",
		"tier": 2,
		"max_stacks": 5,
		"effects": [{"stat": "max_health", "value": 25, "operation": "add"}]
	},
	"health_3": {
		"id": "health_3",
		"name": "Vitalidad Mayor",
		"description": "+50 Vida máxima.",
		"icon": "❤️",
		"category": "defensive",
		"tier": 3,
		"max_stacks": 3,
		"effects": [{"stat": "max_health", "value": 50, "operation": "add"}]
	},
	"health_4": {
		"id": "health_4",
		"name": "Corazón de Titan",
		"description": "+100 Vida máxima.",
		"icon": "❤️",
		"category": "defensive",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "max_health", "value": 100, "operation": "add"}]
	},
	"health_percent_1": {
		"id": "health_percent_1",
		"name": "Constitución",
		"description": "+15% Vida máxima.",
		"icon": "💪",
		"category": "defensive",
		"tier": 2,
		"max_stacks": 4,
		"effects": [{"stat": "max_health", "value": 1.15, "operation": "multiply"}]
	},
	"health_percent_2": {
		"id": "health_percent_2",
		"name": "Fortaleza",
		"description": "+30% Vida máxima.",
		"icon": "💪",
		"category": "defensive",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "max_health", "value": 1.30, "operation": "multiply"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# REGENERACIÓN
	# ─────────────────────────────────────────────────────────────────────────────
	"regen_1": {
		"id": "regen_1",
		"name": "Regeneración Menor",
		"description": "+1.0 HP/segundo.",
		"icon": "💚",
		"category": "defensive",
		"tier": 1,
		"max_stacks": 6,
		"effects": [{"stat": "health_regen", "value": 1.0, "operation": "add"}]
	},
	"regen_2": {
		"id": "regen_2",
		"name": "Regeneración",
		"description": "+2.5 HP/segundo.",
		"icon": "💚",
		"category": "defensive",
		"tier": 2,
		"max_stacks": 4,
		"effects": [{"stat": "health_regen", "value": 2.5, "operation": "add"}]
	},
	"regen_3": {
		"id": "regen_3",
		"name": "Regeneración Mayor",
		"description": "+3 HP/segundo.",
		"icon": "💚",
		"category": "defensive",
		"tier": 3,
		"max_stacks": 3,
		"effects": [{"stat": "health_regen", "value": 3.0, "operation": "add"}]
	},
	"regen_4": {
		"id": "regen_4",
		"name": "Curación Divina",
		"description": "+5 HP/segundo.",
		"icon": "💚",
		"category": "defensive",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "health_regen", "value": 5.0, "operation": "add"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ARMADURA
	# ─────────────────────────────────────────────────────────────────────────────
	"armor_1": {
		"id": "armor_1",
		"name": "Piel Dura",
		"description": "+3 Armadura (reduce daño recibido).",
		"icon": "🛡️",
		"category": "defensive",
		"tier": 1,
		"max_stacks": 8,
		"effects": [{"stat": "armor", "value": 3, "operation": "add"}]
	},
	"armor_2": {
		"id": "armor_2",
		"name": "Coraza",
		"description": "+5 Armadura.",
		"icon": "🛡️",
		"category": "defensive",
		"tier": 2,
		"max_stacks": 5,
		"effects": [{"stat": "armor", "value": 5, "operation": "add"}]
	},
	"armor_3": {
		"id": "armor_3",
		"name": "Blindaje",
		"description": "+10 Armadura.",
		"icon": "🛡️",
		"category": "defensive",
		"tier": 3,
		"max_stacks": 3,
		"effects": [{"stat": "armor", "value": 10, "operation": "add"}]
	},
	"armor_4": {
		"id": "armor_4",
		"name": "Fortaleza de Hierro",
		"description": "+20 Armadura.",
		"icon": "🛡️",
		"category": "defensive",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "armor", "value": 20, "operation": "add"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ESQUIVA
	# ─────────────────────────────────────────────────────────────────────────────
	"dodge_1": {
		"id": "dodge_1",
		"name": "Agilidad",
		"description": "+3% probabilidad de esquivar.",
		"icon": "💨",
		"category": "defensive",
		"tier": 1,
		"max_stacks": 4,
		"effects": [{"stat": "dodge_chance", "value": 0.03, "operation": "add"}]
	},
	"dodge_2": {
		"id": "dodge_2",
		"name": "Reflejos Rápidos",
		"description": "+6% probabilidad de esquivar.",
		"icon": "💨",
		"category": "defensive",
		"tier": 2,
		"max_stacks": 3,
		"effects": [{"stat": "dodge_chance", "value": 0.06, "operation": "add"}]
	},
	"dodge_3": {
		"id": "dodge_3",
		"name": "Evasión",
		"description": "+10% probabilidad de esquivar.",
		"icon": "💨",
		"category": "defensive",
		"tier": 3,
		"max_stacks": 2,
		"effects": [{"stat": "dodge_chance", "value": 0.10, "operation": "add"}]
	},
	"dodge_4": {
		"id": "dodge_4",
		"name": "Sombra Elusiva",
		"description": "+15% probabilidad de esquivar.",
		"icon": "💨",
		"category": "defensive",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "dodge_chance", "value": 0.15, "operation": "add"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ROBO DE VIDA
	# ─────────────────────────────────────────────────────────────────────────────
	"lifesteal_1": {
		"id": "lifesteal_1",
		"name": "Vampirismo Menor",
		"description": "+5% robo de vida.",
		"icon": "🩸",
		"category": "defensive",
		"tier": 2,
		"max_stacks": 4,
		"effects": [{"stat": "life_steal", "value": 0.05, "operation": "add"}]
	},
	"lifesteal_2": {
		"id": "lifesteal_2",
		"name": "Vampirismo",
		"description": "+7% robo de vida.",
		"icon": "🩸",
		"category": "defensive",
		"tier": 3,
		"max_stacks": 3,
		"effects": [{"stat": "life_steal", "value": 0.07, "operation": "add"}]
	},
	"lifesteal_3": {
		"id": "lifesteal_3",
		"name": "Sed de Sangre",
		"description": "+12% robo de vida.",
		"icon": "🩸",
		"category": "defensive",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "life_steal", "value": 0.12, "operation": "add"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# REDUCCIÓN DE DAÑO
	# ─────────────────────────────────────────────────────────────────────────────
	"damage_reduction_1": {
		"id": "damage_reduction_1",
		"name": "Resistencia",
		"description": "-5% daño recibido.",
		"icon": "🔰",
		"category": "defensive",
		"tier": 2,
		"max_stacks": 5,
		"effects": [{"stat": "damage_taken_mult", "value": 0.95, "operation": "multiply"}]
	},
	"damage_reduction_2": {
		"id": "damage_reduction_2",
		"name": "Dureza",
		"description": "-10% daño recibido.",
		"icon": "🔰",
		"category": "defensive",
		"tier": 3,
		"max_stacks": 3,
		"effects": [{"stat": "damage_taken_mult", "value": 0.90, "operation": "multiply"}]
	},
	"damage_reduction_3": {
		"id": "damage_reduction_3",
		"name": "Invulnerabilidad",
		"description": "-20% daño recibido.",
		"icon": "🔰",
		"category": "defensive",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "damage_taken_mult", "value": 0.80, "operation": "multiply"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ESPINAS (THORNS)
	# ─────────────────────────────────────────────────────────────────────────────
	"thorns_1": {
		"id": "thorns_1",
		"name": "Espinas Menores",
		"description": "Refleja 5% del daño recibido a atacantes.",
		"icon": "🌵",
		"category": "defensive",
		"tier": 1,
		"max_stacks": 5,
		"effects": [{"stat": "thorns_percent", "value": 0.05, "operation": "add"}]
	},
	"thorns_2": {
		"id": "thorns_2",
		"name": "Espinas",
		"description": "Refleja 12% del daño recibido.",
		"icon": "🌵",
		"category": "defensive",
		"tier": 2,
		"max_stacks": 4,
		"effects": [{"stat": "thorns_percent", "value": 0.12, "operation": "add"}]
	},
	"thorns_3": {
		"id": "thorns_3",
		"name": "Espinas Venenosas",
		"description": "Refleja 20% del daño recibido.",
		"icon": "🌵",
		"category": "defensive",
		"tier": 3,
		"max_stacks": 3,
		"effects": [{"stat": "thorns_percent", "value": 0.20, "operation": "add"}]
	},
	"thorns_percent_1": {
		"id": "thorns_percent_1",
		"name": "Retribución",
		"description": "Refleja 30% del daño recibido. Los ataques reflejados ralentizan.",
		"icon": "⚡",
		"category": "defensive",
		"tier": 4,
		"max_stacks": 2,
		"effects": [
			{"stat": "thorns_percent", "value": 0.30, "operation": "add"},
			{"stat": "thorns_slow", "value": 0.25, "operation": "add"}
		]
	},
	"thorns_percent_2": {
		"id": "thorns_percent_2",
		"name": "Venganza Divina",
		"description": "Refleja 50% del daño recibido. Los ataques reflejados aturden 0.3s.",
		"icon": "⚡",
		"category": "defensive",
		"tier": 5,
		"max_stacks": 1,
		"effects": [
			{"stat": "thorns_percent", "value": 0.50, "operation": "add"},
			{"stat": "thorns_stun", "value": 0.3, "operation": "add"}
		]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# CURACIÓN AL MATAR
	# ─────────────────────────────────────────────────────────────────────────────
	"kill_heal_1": {
		"id": "kill_heal_1",
		"name": "Absorción",
		"description": "+2 HP por enemigo eliminado.",
		"icon": "💀",
		"category": "defensive",
		"tier": 2,
		"max_stacks": 4,
		"effects": [{"stat": "kill_heal", "value": 2, "operation": "add"}]
	},
	"kill_heal_2": {
		"id": "kill_heal_2",
		"name": "Devorador",
		"description": "+4 HP por enemigo eliminado.",
		"icon": "💀",
		"category": "defensive",
		"tier": 3,
		"max_stacks": 3,
		"effects": [{"stat": "kill_heal", "value": 4, "operation": "add"}]
	},
	"kill_heal_3": {
		"id": "kill_heal_3",
		"name": "Cosechador de Almas",
		"description": "+5 HP por enemigo eliminado.",
		"icon": "💀",
		"category": "defensive",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "kill_heal", "value": 5, "operation": "add"}]
	},
	# ─────────────────────────────────────────────────────────────────────────────
	# ESCUDO DE ENERGÍA (Sistema estilo Path of Exile 2)
	# El escudo absorbe daño antes que la vida y se regenera después de no recibir daño
	# ─────────────────────────────────────────────────────────────────────────────
	"shield_1": {
		"id": "shield_1",
		"name": "Escudo Arcano Menor",
		"description": "+20 Escudo máximo, +2 regen/s. Regenera tras 3s sin daño.",
		"icon": "🛡️",
		"category": "defensive",
		"tier": 2,
		"max_stacks": 5,
		"effects": [
			{"stat": "max_shield", "value": 20, "operation": "add"},
			{"stat": "shield_amount", "value": 20, "operation": "add"},
			{"stat": "shield_regen", "value": 2.0, "operation": "add"}
		]
	},
	"shield_2": {
		"id": "shield_2",
		"name": "Escudo Arcano",
		"description": "+40 Escudo máximo, +4 regen/s. Regenera tras 3s sin daño.",
		"icon": "🛡️",
		"category": "defensive",
		"tier": 3,
		"max_stacks": 3,
		"effects": [
			{"stat": "max_shield", "value": 40, "operation": "add"},
			{"stat": "shield_amount", "value": 40, "operation": "add"},
			{"stat": "shield_regen", "value": 4.0, "operation": "add"}
		]
	},
	"shield_3": {
		"id": "shield_3",
		"name": "Barrera Mágica",
		"description": "+70 Escudo máximo, +7 regen/s. Regenera tras 3s sin daño.",
		"icon": "🔮",
		"category": "defensive",
		"tier": 4,
		"max_stacks": 2,
		"effects": [
			{"stat": "max_shield", "value": 70, "operation": "add"},
			{"stat": "shield_amount", "value": 70, "operation": "add"},
			{"stat": "shield_regen", "value": 7.0, "operation": "add"}
		]
	},
	"shield_4": {
		"id": "shield_4",
		"name": "Égida del Archimago",
		"description": "+100 Escudo máximo, +10 regen/s. Regenera tras 3s sin daño.",
		"icon": "✨",
		"category": "defensive",
		"tier": 5,
		"max_stacks": 1,
		"effects": [
			{"stat": "max_shield", "value": 100, "operation": "add"},
			{"stat": "shield_amount", "value": 100, "operation": "add"},
			{"stat": "shield_regen", "value": 10.0, "operation": "add"}
		]
	},
	"shield_regen_delay_1": {
		"id": "shield_regen_delay_1",
		"name": "Recuperación Rápida",
		"description": "-0.5s de delay para regenerar escudo.",
		"icon": "⚡",
		"category": "defensive",
		"tier": 3,
		"max_stacks": 3,
		"effects": [{"stat": "shield_regen_delay", "value": -0.5, "operation": "add"}]
	},
	"shield_regen_delay_2": {
		"id": "shield_regen_delay_2",
		"name": "Regeneración Instantánea",
		"description": "-1s de delay para regenerar escudo.",
		"icon": "⚡",
		"category": "defensive",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "shield_regen_delay", "value": -1.0, "operation": "add"}]
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# MEJORAS DE UTILIDAD
# ═══════════════════════════════════════════════════════════════════════════════

const UTILITY_UPGRADES: Dictionary = {
	# ─────────────────────────────────────────────────────────────────────────────
	# VELOCIDAD DE MOVIMIENTO
	# ─────────────────────────────────────────────────────────────────────────────
	"speed_1": {
		"id": "speed_1",
		"name": "Pies Ligeros",
		"description": "+8% velocidad de movimiento.",
		"icon": "🏃",
		"category": "utility",
		"tier": 1,
		"max_stacks": 6,
		"effects": [{"stat": "move_speed", "value": 1.08, "operation": "multiply"}]
	},
	"speed_2": {
		"id": "speed_2",
		"name": "Velocidad",
		"description": "+15% velocidad de movimiento.",
		"icon": "🏃",
		"category": "utility",
		"tier": 2,
		"max_stacks": 4,
		"effects": [{"stat": "move_speed", "value": 1.15, "operation": "multiply"}]
	},
	"speed_3": {
		"id": "speed_3",
		"name": "Celeridad",
		"description": "+25% velocidad de movimiento.",
		"icon": "🏃",
		"category": "utility",
		"tier": 3,
		"max_stacks": 2,
		"effects": [{"stat": "move_speed", "value": 1.25, "operation": "multiply"}]
	},
	"speed_4": {
		"id": "speed_4",
		"name": "Velocidad del Viento",
		"description": "+40% velocidad de movimiento.",
		"icon": "🏃",
		"category": "utility",
		"tier": 4,
		"max_stacks": 1,
		"effects": [{"stat": "move_speed", "value": 1.40, "operation": "multiply"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# EXPERIENCIA
	# ─────────────────────────────────────────────────────────────────────────────
	"xp_1": {
		"id": "xp_1",
		"name": "Aprendizaje",
		"description": "+10% experiencia ganada.",
		"icon": "📚",
		"category": "utility",
		"tier": 1,
		"max_stacks": 6,
		"effects": [{"stat": "xp_mult", "value": 1.10, "operation": "multiply"}]
	},
	"xp_2": {
		"id": "xp_2",
		"name": "Sabiduría",
		"description": "+20% experiencia ganada.",
		"icon": "📚",
		"category": "utility",
		"tier": 2,
		"max_stacks": 4,
		"effects": [{"stat": "xp_mult", "value": 1.20, "operation": "multiply"}]
	},
	"xp_3": {
		"id": "xp_3",
		"name": "Erudición",
		"description": "+35% experiencia ganada.",
		"icon": "📚",
		"category": "utility",
		"tier": 3,
		"max_stacks": 2,
		"effects": [{"stat": "xp_mult", "value": 1.35, "operation": "multiply"}]
	},
	"xp_4": {
		"id": "xp_4",
		"name": "Iluminación",
		"description": "+50% experiencia ganada.",
		"icon": "📚",
		"category": "utility",
		"tier": 4,
		"max_stacks": 1,
		"effects": [{"stat": "xp_mult", "value": 1.50, "operation": "multiply"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# RANGO DE RECOGIDA
	# ─────────────────────────────────────────────────────────────────────────────
	"pickup_1": {
		"id": "pickup_1",
		"name": "Imán Menor",
		"description": "+20% rango de recogida.",
		"icon": "🧲",
		"category": "utility",
		"tier": 1,
		"max_stacks": 5,
		"effects": [{"stat": "pickup_range", "value": 1.20, "operation": "multiply"}]
	},
	"pickup_2": {
		"id": "pickup_2",
		"name": "Imán",
		"description": "+40% rango de recogida.",
		"icon": "🧲",
		"category": "utility",
		"tier": 2,
		"max_stacks": 3,
		"effects": [{"stat": "pickup_range", "value": 1.40, "operation": "multiply"}]
	},
	"pickup_3": {
		"id": "pickup_3",
		"name": "Vacío Magnético",
		"description": "+75% rango de recogida.",
		"icon": "🧲",
		"category": "utility",
		"tier": 3,
		"max_stacks": 2,
		"effects": [{"stat": "pickup_range", "value": 1.75, "operation": "multiply"}]
	},
}

# ═══════════════════════════════════════════════════════════════════════════════
# MEJORAS OFENSIVAS
# ═══════════════════════════════════════════════════════════════════════════════

const OFFENSIVE_UPGRADES: Dictionary = {
	# ─────────────────────────────────────────────────────────────────────────────
	# DAÑO GLOBAL (Mejoras ofensivas directas - MUY IMPORTANTES)
	# ─────────────────────────────────────────────────────────────────────────────
	"damage_1": {
		"id": "damage_1",
		"name": "Poder Menor",
		"description": "+10% daño de todas las armas.",
		"icon": "⚔️",
		"category": "offensive",
		"tier": 1,
		"max_stacks": 6,
		"effects": [{"stat": "damage_mult", "value": 1.10, "operation": "multiply"}]
	},
	"damage_2": {
		"id": "damage_2",
		"name": "Poder",
		"description": "+18% daño de todas las armas.",
		"icon": "⚔️",
		"category": "offensive",
		"tier": 2,
		"max_stacks": 4,
		"effects": [{"stat": "damage_mult", "value": 1.18, "operation": "multiply"}]
	},
	"damage_3": {
		"id": "damage_3",
		"name": "Fuerza Brutal",
		"description": "+30% daño de todas las armas.",
		"icon": "⚔️",
		"category": "offensive",
		"tier": 3,
		"max_stacks": 3,
		"effects": [{"stat": "damage_mult", "value": 1.30, "operation": "multiply"}]
	},
	"damage_4": {
		"id": "damage_4",
		"name": "Devastación",
		"description": "+50% daño de todas las armas.",
		"icon": "⚔️",
		"category": "offensive",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "damage_mult", "value": 1.50, "operation": "multiply"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# VELOCIDAD DE ATAQUE
	# ─────────────────────────────────────────────────────────────────────────────
	"attack_speed_1": {
		"id": "attack_speed_1",
		"name": "Agilidad de Combate",
		"description": "+10% velocidad de ataque.",
		"icon": "⚡",
		"category": "offensive",
		"tier": 1,
		"max_stacks": 5,
		"effects": [{"stat": "attack_speed_mult", "value": 1.10, "operation": "multiply"}]
	},
	"attack_speed_2": {
		"id": "attack_speed_2",
		"name": "Rapidez",
		"description": "+20% velocidad de ataque.",
		"icon": "⚡",
		"category": "offensive",
		"tier": 2,
		"max_stacks": 4,
		"effects": [{"stat": "attack_speed_mult", "value": 1.20, "operation": "multiply"}]
	},
	"attack_speed_3": {
		"id": "attack_speed_3",
		"name": "Frenesí",
		"description": "+35% velocidad de ataque.",
		"icon": "⚡",
		"category": "offensive",
		"tier": 3,
		"max_stacks": 2,
		"effects": [{"stat": "attack_speed_mult", "value": 1.35, "operation": "multiply"}]
	},
	"attack_speed_4": {
		"id": "attack_speed_4",
		"name": "Tormenta de Acero",
		"description": "+50% velocidad de ataque.",
		"icon": "⚡",
		"category": "offensive",
		"tier": 4,
		"max_stacks": 1,
		"effects": [{"stat": "attack_speed_mult", "value": 1.50, "operation": "multiply"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# CRÍTICOS
	# ─────────────────────────────────────────────────────────────────────────────
	"crit_chance_1": {
		"id": "crit_chance_1",
		"name": "Ojo Entrenado",
		"description": "+5% probabilidad de crítico.",
		"icon": "🎯",
		"category": "offensive",
		"tier": 1,
		"max_stacks": 5,
		"effects": [{"stat": "crit_chance", "value": 0.05, "operation": "add"}]
	},
	"crit_chance_2": {
		"id": "crit_chance_2",
		"name": "Precisión",
		"description": "+10% probabilidad de crítico.",
		"icon": "🎯",
		"category": "offensive",
		"tier": 2,
		"max_stacks": 3,
		"effects": [{"stat": "crit_chance", "value": 0.10, "operation": "add"}]
	},
	"crit_chance_3": {
		"id": "crit_chance_3",
		"name": "Maestría del Golpe",
		"description": "+15% probabilidad de crítico.",
		"icon": "🎯",
		"category": "offensive",
		"tier": 3,
		"max_stacks": 2,
		"effects": [{"stat": "crit_chance", "value": 0.15, "operation": "add"}]
	},
	"crit_damage_1": {
		"id": "crit_damage_1",
		"name": "Golpe Certero",
		"description": "+25% daño crítico.",
		"icon": "💥",
		"category": "offensive",
		"tier": 2,
		"max_stacks": 4,
		"effects": [{"stat": "crit_damage", "value": 0.25, "operation": "add"}]
	},
	"crit_damage_2": {
		"id": "crit_damage_2",
		"name": "Golpe Demoledor",
		"description": "+50% daño crítico.",
		"icon": "💥",
		"category": "offensive",
		"tier": 3,
		"max_stacks": 3,
		"effects": [{"stat": "crit_damage", "value": 0.50, "operation": "add"}]
	},
	"crit_damage_3": {
		"id": "crit_damage_3",
		"name": "Aniquilación",
		"description": "+75% daño crítico.",
		"icon": "💥",
		"category": "offensive",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "crit_damage", "value": 0.75, "operation": "add"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ÁREA DE EFECTO
	# ─────────────────────────────────────────────────────────────────────────────
	"area_1": {
		"id": "area_1",
		"name": "Alcance Expandido",
		"description": "+15% área de efecto.",
		"icon": "🔵",
		"category": "offensive",
		"tier": 1,
		"max_stacks": 5,
		"effects": [{"stat": "area_mult", "value": 1.15, "operation": "multiply"}]
	},
	"area_2": {
		"id": "area_2",
		"name": "Onda Expansiva",
		"description": "+25% área de efecto.",
		"icon": "🔵",
		"category": "offensive",
		"tier": 2,
		"max_stacks": 3,
		"effects": [{"stat": "area_mult", "value": 1.25, "operation": "multiply"}]
	},
	"area_3": {
		"id": "area_3",
		"name": "Devastación en Área",
		"description": "+40% área de efecto.",
		"icon": "🔵",
		"category": "offensive",
		"tier": 3,
		"max_stacks": 2,
		"effects": [{"stat": "area_mult", "value": 1.40, "operation": "multiply"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# PROYECTILES Y PENETRACIÓN
	# ─────────────────────────────────────────────────────────────────────────────
	"projectile_1": {
		"id": "projectile_1",
		"name": "Disparo Doble",
		"description": "+1 proyectil adicional.",
		"icon": "🔮",
		"category": "offensive",
		"tier": 3,
		"max_stacks": 3,
		"effects": [{"stat": "extra_projectiles", "value": 1, "operation": "add"}]
	},
	"projectile_2": {
		"id": "projectile_2",
		"name": "Ráfaga",
		"description": "+2 proyectiles adicionales.",
		"icon": "🔮",
		"category": "offensive",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "extra_projectiles", "value": 2, "operation": "add"}]
	},
	"pierce_1": {
		"id": "pierce_1",
		"name": "Penetración",
		"description": "+1 penetración (atraviesa +1 enemigo).",
		"icon": "➡️",
		"category": "offensive",
		"tier": 2,
		"max_stacks": 4,
		"excluded_tags": ["no_pierce"],
		"effects": [{"stat": "extra_pierce", "value": 1, "operation": "add"}]
	},
	"pierce_2": {
		"id": "pierce_2",
		"name": "Empalamiento",
		"description": "+2 penetración (atraviesa +2 enemigos).",
		"icon": "➡️",
		"category": "offensive",
		"tier": 3,
		"max_stacks": 3,
		"excluded_tags": ["no_pierce"],
		"effects": [{"stat": "extra_pierce", "value": 2, "operation": "add"}]
	},
	"pierce_3": {
		"id": "pierce_3",
		"name": "Perforación Total",
		"description": "+3 penetración (atraviesa +3 enemigos).",
		"icon": "➡️",
		"category": "offensive",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "extra_pierce", "value": 3, "operation": "add"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# CADENAS (CHAIN)
	# ─────────────────────────────────────────────────────────────────────────────
	"chain_1": {
		"id": "chain_1",
		"name": "Rebote",
		"description": "Los ataques saltan a +1 enemigo cercano.",
		"icon": "⚡",
		"category": "offensive",
		"tier": 3,
		"max_stacks": 3,
		"required_tags": ["chain"],
		"effects": [{"stat": "chain_count", "value": 1, "operation": "add"}]
	},
	"chain_2": {
		"id": "chain_2",
		"name": "Cadena de Rayos",
		"description": "Los ataques saltan a +2 enemigos cercanos.",
		"icon": "⚡",
		"category": "offensive",
		"tier": 4,
		"max_stacks": 2,
		"required_tags": ["chain"],
		"effects": [{"stat": "chain_count", "value": 2, "operation": "add"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# VELOCIDAD DE PROYECTIL
	# ─────────────────────────────────────────────────────────────────────────────
	"projectile_speed_1": {
		"id": "projectile_speed_1",
		"name": "Proyectiles Rápidos",
		"description": "+20% velocidad de proyectiles.",
		"icon": "💨",
		"category": "offensive",
		"tier": 1,
		"max_stacks": 4,
		"effects": [{"stat": "projectile_speed_mult", "value": 1.20, "operation": "multiply"}]
	},
	"projectile_speed_2": {
		"id": "projectile_speed_2",
		"name": "Proyectiles Supersónicos",
		"description": "+40% velocidad de proyectiles.",
		"icon": "💨",
		"category": "offensive",
		"tier": 2,
		"max_stacks": 3,
		"effects": [{"stat": "projectile_speed_mult", "value": 1.40, "operation": "multiply"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# DURACIÓN DE HABILIDADES
	# ─────────────────────────────────────────────────────────────────────────────
	"duration_1": {
		"id": "duration_1",
		"name": "Persistencia",
		"description": "+20% duración de proyectiles y efectos.",
		"icon": "⏳",
		"category": "offensive",
		"tier": 2,
		"max_stacks": 4,
		"effects": [{"stat": "duration_mult", "value": 1.20, "operation": "multiply"}]
	},
	"duration_2": {
		"id": "duration_2",
		"name": "Permanencia",
		"description": "+40% duración de proyectiles y efectos.",
		"icon": "⏳",
		"category": "offensive",
		"tier": 3,
		"max_stacks": 2,
		"effects": [{"stat": "duration_mult", "value": 1.40, "operation": "multiply"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# REDUCCIÓN DE COOLDOWN
	# ─────────────────────────────────────────────────────────────────────────────
	"cooldown_1": {
		"id": "cooldown_1",
		"name": "Recuperación",
		"description": "-10% tiempo de recarga.",
		"icon": "🔄",
		"category": "offensive",
		"tier": 2,
		"max_stacks": 4,
		"effects": [{"stat": "cooldown_mult", "value": 0.90, "operation": "multiply"}]
	},
	"cooldown_2": {
		"id": "cooldown_2",
		"name": "Celeridad",
		"description": "-20% tiempo de recarga.",
		"icon": "🔄",
		"category": "offensive",
		"tier": 3,
		"max_stacks": 3,
		"effects": [{"stat": "cooldown_mult", "value": 0.80, "operation": "multiply"}]
	},
	"cooldown_3": {
		"id": "cooldown_3",
		"name": "Flujo Arcano",
		"description": "-30% tiempo de recarga.",
		"icon": "🔄",
		"category": "offensive",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "cooldown_mult", "value": 0.70, "operation": "multiply"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# KNOCKBACK
	# ─────────────────────────────────────────────────────────────────────────────
	"knockback_1": {
		"id": "knockback_1",
		"name": "Impacto",
		"description": "+30% retroceso a enemigos.",
		"icon": "💪",
		"category": "offensive",
		"tier": 1,
		"max_stacks": 4,
		"effects": [{"stat": "knockback_mult", "value": 1.30, "operation": "multiply"}]
	},
	"knockback_2": {
		"id": "knockback_2",
		"name": "Fuerza Bruta",
		"description": "+60% retroceso a enemigos.",
		"icon": "💪",
		"category": "offensive",
		"tier": 2,
		"max_stacks": 3,
		"effects": [{"stat": "knockback_mult", "value": 1.60, "operation": "multiply"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# DAÑO CONTRA ELITES/JEFES
	# ─────────────────────────────────────────────────────────────────────────────
	"elite_damage_1": {
		"id": "elite_damage_1",
		"name": "Cazador de Elites",
		"description": "+25% daño contra elites y jefes.",
		"icon": "👑",
		"category": "offensive",
		"tier": 2,
		"max_stacks": 4,
		"effects": [{"stat": "elite_damage_mult", "value": 0.25, "operation": "add"}]
	},
	"elite_damage_2": {
		"id": "elite_damage_2",
		"name": "Matador de Gigantes",
		"description": "+50% daño contra elites y jefes.",
		"icon": "👑",
		"category": "offensive",
		"tier": 3,
		"max_stacks": 2,
		"effects": [{"stat": "elite_damage_mult", "value": 0.50, "operation": "add"}]
	},
	"elite_damage_3": {
		"id": "elite_damage_3",
		"name": "Verdugo de Titanes",
		"description": "+100% daño contra elites y jefes.",
		"icon": "👑",
		"category": "offensive",
		"tier": 4,
		"max_stacks": 1,
		"effects": [{"stat": "elite_damage_mult", "value": 1.0, "operation": "add"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# EFECTOS DE ESTADO OFENSIVOS
	# ─────────────────────────────────────────────────────────────────────────────
	"burn_chance_1": {
		"id": "burn_chance_1",
		"name": "Toque Ardiente",
		"description": "+10% prob. de quemar enemigos (3 daño/s por 3s).",
		"icon": "🔥",
		"category": "offensive",
		"tier": 2,
		"max_stacks": 4,
		"effects": [{"stat": "burn_chance", "value": 0.10, "operation": "add"}]
	},
	"burn_chance_2": {
		"id": "burn_chance_2",
		"name": "Inmolación",
		"description": "+20% prob. de quemar enemigos.",
		"icon": "🔥",
		"category": "offensive",
		"tier": 3,
		"max_stacks": 2,
		"effects": [{"stat": "burn_chance", "value": 0.20, "operation": "add"}]
	},
	"freeze_chance_1": {
		"id": "freeze_chance_1",
		"name": "Toque Gélido",
		"description": "+10% prob. de congelar enemigos (1s).",
		"icon": "❄️",
		"category": "offensive",
		"tier": 2,
		"max_stacks": 4,
		"effects": [{"stat": "freeze_chance", "value": 0.10, "operation": "add"}]
	},
	"freeze_chance_2": {
		"id": "freeze_chance_2",
		"name": "Corazón de Hielo",
		"description": "+20% prob. de congelar enemigos.",
		"icon": "❄️",
		"category": "offensive",
		"tier": 3,
		"max_stacks": 2,
		"effects": [{"stat": "freeze_chance", "value": 0.20, "operation": "add"}]
	},
	"bleed_chance_1": {
		"id": "bleed_chance_1",
		"name": "Corte Profundo",
		"description": "+10% prob. de causar sangrado (2 daño/s por 4s).",
		"icon": "🩸",
		"category": "offensive",
		"tier": 2,
		"max_stacks": 4,
		"effects": [{"stat": "bleed_chance", "value": 0.10, "operation": "add"}]
	},
	"bleed_chance_2": {
		"id": "bleed_chance_2",
		"name": "Hemorragia",
		"description": "+20% prob. de causar sangrado.",
		"icon": "🩸",
		"category": "offensive",
		"tier": 3,
		"max_stacks": 2,
		"effects": [{"stat": "bleed_chance", "value": 0.20, "operation": "add"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# RANGO DE ATAQUE
	# ─────────────────────────────────────────────────────────────────────────────
	"range_1": {
		"id": "range_1",
		"name": "Alcance",
		"description": "+15% rango de ataque.",
		"icon": "🏹",
		"category": "offensive",
		"tier": 1,
		"max_stacks": 4,
		"effects": [{"stat": "range_mult", "value": 1.15, "operation": "multiply"}]
	},
	"range_2": {
		"id": "range_2",
		"name": "Largo Alcance",
		"description": "+30% rango de ataque.",
		"icon": "🏹",
		"category": "offensive",
		"tier": 2,
		"max_stacks": 3,
		"effects": [{"stat": "range_mult", "value": 1.30, "operation": "multiply"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# SUERTE
	# ─────────────────────────────────────────────────────────────────────────────
	"luck_1": {
		"id": "luck_1",
		"name": "Fortuna Menor",
		"description": "+8% suerte (mejores drops).",
		"icon": "🍀",
		"category": "utility",
		"tier": 1,
		"max_stacks": 6,
		"effects": [{"stat": "luck", "value": 0.08, "operation": "add"}]
	},
	"luck_2": {
		"id": "luck_2",
		"name": "Fortuna",
		"description": "+15% suerte.",
		"icon": "🍀",
		"category": "utility",
		"tier": 2,
		"max_stacks": 4,
		"effects": [{"stat": "luck", "value": 0.15, "operation": "add"}]
	},
	"luck_3": {
		"id": "luck_3",
		"name": "Buena Estrella",
		"description": "+20% suerte.",
		"icon": "🍀",
		"category": "utility",
		"tier": 3,
		"max_stacks": 3,
		"effects": [{"stat": "luck", "value": 0.20, "operation": "add"}]
	},
	"luck_4": {
		"id": "luck_4",
		"name": "Bendición de la Fortuna",
		"description": "+35% suerte.",
		"icon": "🍀",
		"category": "utility",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "luck", "value": 0.35, "operation": "add"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ORO
	# ─────────────────────────────────────────────────────────────────────────────
	"gold_1": {
		"id": "gold_1",
		"name": "Avaricia",
		"description": "+15% oro obtenido.",
		"icon": "🪙",
		"category": "utility",
		"tier": 1,
		"max_stacks": 5,
		"effects": [{"stat": "gold_mult", "value": 1.15, "operation": "multiply"}]
	},
	"gold_2": {
		"id": "gold_2",
		"name": "Codicia",
		"description": "+30% oro obtenido.",
		"icon": "🪙",
		"category": "utility",
		"tier": 2,
		"max_stacks": 3,
		"effects": [{"stat": "gold_mult", "value": 1.30, "operation": "multiply"}]
	},
	"gold_3": {
		"id": "gold_3",
		"name": "Rey Midas",
		"description": "+50% oro obtenido.",
		"icon": "🪙",
		"category": "utility",
		"tier": 3,
		"max_stacks": 2,
		"effects": [{"stat": "gold_mult", "value": 1.50, "operation": "multiply"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# REROLLS Y BANISH
	# ─────────────────────────────────────────────────────────────────────────────
	"reroll_1": {
		"id": "reroll_1",
		"name": "Segunda Oportunidad",
		"description": "+1 Reroll en level up.",
		"icon": "🔄",
		"category": "utility",
		"tier": 2,
		"max_stacks": 3,
		"effects": [{"stat": "reroll_count", "value": 1, "operation": "add"}]
	},
	"banish_1": {
		"id": "banish_1",
		"name": "Rechazo",
		"description": "+1 Banish en level up.",
		"icon": "❌",
		"category": "utility",
		"tier": 2,
		"max_stacks": 3,
		"effects": [{"stat": "banish_count", "value": 1, "operation": "add"}]
	},
	"levelup_options_1": {
		"id": "levelup_options_1",
		"name": "Más Opciones",
		"description": "+1 opción al subir de nivel.",
		"icon": "📋",
		"category": "utility",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "levelup_options", "value": 1, "operation": "add"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# CRECIMIENTO
	# ─────────────────────────────────────────────────────────────────────────────
	"growth_1": {
		"id": "growth_1",
		"name": "Crecimiento",
		"description": "+1% a TODOS los stats por minuto sobrevivido.",
		"icon": "📈",
		"category": "utility",
		"tier": 3,
		"max_stacks": 3,
		"effects": [{"stat": "growth", "value": 0.01, "operation": "add"}]
	},
	"growth_2": {
		"id": "growth_2",
		"name": "Evolución",
		"description": "+2% a TODOS los stats por minuto sobrevivido.",
		"icon": "📈",
		"category": "utility",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "growth", "value": 0.02, "operation": "add"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# SINERGIAS - Daño condicional
	# ─────────────────────────────────────────────────────────────────────────────
	"slow_synergy_1": {
		"id": "slow_synergy_1",
		"name": "Cazador Paciente",
		"description": "+25% daño a enemigos ralentizados.",
		"icon": "🐌",
		"category": "offensive",
		"tier": 2,
		"max_stacks": 3,
		"effects": [{"stat": "damage_vs_slowed", "value": 0.25, "operation": "add"}]
	},
	"slow_synergy_2": {
		"id": "slow_synergy_2",
		"name": "Depredador",
		"description": "+50% daño a enemigos ralentizados.",
		"icon": "🐌",
		"category": "offensive",
		"tier": 3,
		"max_stacks": 2,
		"effects": [{"stat": "damage_vs_slowed", "value": 0.50, "operation": "add"}]
	},
	"burn_synergy_1": {
		"id": "burn_synergy_1",
		"name": "Pirómano",
		"description": "+25% daño a enemigos en llamas.",
		"icon": "🔥",
		"category": "offensive",
		"tier": 2,
		"max_stacks": 3,
		"effects": [{"stat": "damage_vs_burning", "value": 0.25, "operation": "add"}]
	},
	"burn_synergy_2": {
		"id": "burn_synergy_2",
		"name": "Señor del Fuego",
		"description": "+50% daño a enemigos en llamas.",
		"icon": "🔥",
		"category": "offensive",
		"tier": 3,
		"max_stacks": 2,
		"effects": [{"stat": "damage_vs_burning", "value": 0.50, "operation": "add"}]
	},
	"freeze_synergy_1": {
		"id": "freeze_synergy_1",
		"name": "Ejecutor del Hielo",
		"description": "+40% daño a enemigos congelados.",
		"icon": "❄️",
		"category": "offensive",
		"tier": 2,
		"max_stacks": 3,
		"effects": [{"stat": "damage_vs_frozen", "value": 0.40, "operation": "add"}]
	},
	"freeze_synergy_2": {
		"id": "freeze_synergy_2",
		"name": "Rompe Hielos",
		"description": "+80% daño a enemigos congelados.",
		"icon": "❄️",
		"category": "offensive",
		"tier": 3,
		"max_stacks": 2,
		"effects": [{"stat": "damage_vs_frozen", "value": 0.80, "operation": "add"}]
	},
	"low_hp_damage_1": {
		"id": "low_hp_damage_1",
		"name": "Riesgo Calculado",
		"description": "+2% daño por cada 10% de HP perdido.",
		"icon": "💔",
		"category": "offensive",
		"tier": 3,
		"max_stacks": 3,
		"effects": [{"stat": "low_hp_damage_bonus", "value": 0.02, "operation": "add"}]
	},
	"low_hp_damage_2": {
		"id": "low_hp_damage_2",
		"name": "Al Borde de la Muerte",
		"description": "+4% daño por cada 10% de HP perdido.",
		"icon": "💔",
		"category": "offensive",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "low_hp_damage_bonus", "value": 0.04, "operation": "add"}]
	},
	"full_hp_damage_1": {
		"id": "full_hp_damage_1",
		"name": "Confianza Plena",
		"description": "+20% daño mientras tengas HP máximo.",
		"icon": "💚",
		"category": "offensive",
		"tier": 2,
		"max_stacks": 3,
		"effects": [{"stat": "full_hp_damage_bonus", "value": 0.20, "operation": "add"}]
	},
	"full_hp_damage_2": {
		"id": "full_hp_damage_2",
		"name": "Perfeccionista",
		"description": "+40% daño mientras tengas HP máximo.",
		"icon": "💚",
		"category": "offensive",
		"tier": 3,
		"max_stacks": 2,
		"effects": [{"stat": "full_hp_damage_bonus", "value": 0.40, "operation": "add"}]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# OVERKILL (Daño excedente transferido)
	# ─────────────────────────────────────────────────────────────────────────────
	"overkill_1": {
		"id": "overkill_1",
		"name": "Explosión de Daño",
		"description": "25% del daño excedente se transfiere a enemigos cercanos.",
		"icon": "💥",
		"category": "utility",
		"tier": 2,
		"max_stacks": 4,
		"effects": [{"stat": "overkill_damage", "value": 0.25, "operation": "add"}]
	},
	"overkill_2": {
		"id": "overkill_2",
		"name": "Reacción en Cadena",
		"description": "50% del daño excedente se transfiere a enemigos cercanos.",
		"icon": "💥",
		"category": "utility",
		"tier": 3,
		"max_stacks": 2,
		"effects": [{"stat": "overkill_damage", "value": 0.50, "operation": "add"}]
	},
	"overkill_3": {
		"id": "overkill_3",
		"name": "Devastación",
		"description": "100% del daño excedente se transfiere a enemigos cercanos.",
		"icon": "💥",
		"category": "utility",
		"tier": 4,
		"max_stacks": 1,
		"effects": [{"stat": "overkill_damage", "value": 1.0, "operation": "add"}]
	},
	# ─────────────────────────────────────────────────────────────────────────────
	# DURACIÓN DE EFECTOS DE ESTADO (quemadura, ralentización, congelación, etc.)
	# Afecta a: slow, burn, freeze, stun, blind, bleed, poison
	# ─────────────────────────────────────────────────────────────────────────────
	"status_duration_1": {
		"id": "status_duration_1",
		"name": "Aflicción Persistente",
		"description": "+15% duración de efectos de estado en enemigos.",
		"icon": "⌛",
		"category": "utility",
		"tier": 2,
		"max_stacks": 5,
		"effects": [{"stat": "status_duration_mult", "value": 0.15, "operation": "add"}]
	},
	"status_duration_2": {
		"id": "status_duration_2",
		"name": "Tormento Prolongado",
		"description": "+30% duración de efectos de estado en enemigos.",
		"icon": "⌛",
		"category": "utility",
		"tier": 3,
		"max_stacks": 3,
		"effects": [{"stat": "status_duration_mult", "value": 0.30, "operation": "add"}]
	},
	"status_duration_3": {
		"id": "status_duration_3",
		"name": "Agonía Eterna",
		"description": "+50% duración de efectos de estado en enemigos.",
		"icon": "💀",
		"category": "utility",
		"tier": 4,
		"max_stacks": 2,
		"effects": [{"stat": "status_duration_mult", "value": 0.50, "operation": "add"}]
	},
	"status_duration_4": {
		"id": "status_duration_4",
		"name": "Maldición del Tiempo",
		"description": "+75% duración de efectos de estado en enemigos.",
		"icon": "🕐",
		"category": "utility",
		"tier": 5,
		"max_stacks": 1,
		"effects": [{"stat": "status_duration_mult", "value": 0.75, "operation": "add"}]
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# MEJORAS CURSED (Trade-off: beneficio + penalización)
# ═══════════════════════════════════════════════════════════════════════════════

const CURSED_UPGRADES: Dictionary = {
	# ─────────────────────────────────────────────────────────────────────────────
	# DAÑO vs DEFENSA
	# ─────────────────────────────────────────────────────────────────────────────
	"cursed_glass_cannon_1": {
		"id": "cursed_glass_cannon_1",
		"name": "Cañón de Cristal",
		"description": "+25% daño, pero +15% daño recibido.",
		"icon": "💎",
		"category": "cursed",
		"tier": 2,
		"is_cursed": true,
		"max_stacks": 3,
		"effects": [
			{"stat": "damage_mult", "value": 1.25, "operation": "multiply"},
			{"stat": "damage_taken_mult", "value": 1.15, "operation": "multiply"}
		]
	},
	"cursed_glass_cannon_2": {
		"id": "cursed_glass_cannon_2",
		"name": "Cañón Frágil",
		"description": "+50% daño, pero +30% daño recibido.",
		"icon": "💎",
		"category": "cursed",
		"tier": 3,
		"is_cursed": true,
		"max_stacks": 2,
		"effects": [
			{"stat": "damage_mult", "value": 1.50, "operation": "multiply"},
			{"stat": "damage_taken_mult", "value": 1.30, "operation": "multiply"}
		]
	},
	"cursed_glass_cannon_3": {
		"id": "cursed_glass_cannon_3",
		"name": "Devastación Mortal",
		"description": "+100% daño, pero +50% daño recibido.",
		"icon": "💎",
		"category": "cursed",
		"tier": 4,
		"is_cursed": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "damage_mult", "value": 2.0, "operation": "multiply"},
			{"stat": "damage_taken_mult", "value": 1.50, "operation": "multiply"}
		]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# VELOCIDAD vs DAÑO
	# ─────────────────────────────────────────────────────────────────────────────
	"cursed_berserker_1": {
		"id": "cursed_berserker_1",
		"name": "Furia Berserker",
		"description": "+30% velocidad de ataque, pero -10% velocidad movimiento.",
		"icon": "😤",
		"category": "cursed",
		"tier": 2,
		"is_cursed": true,
		"max_stacks": 3,
		"effects": [
			{"stat": "attack_speed_mult", "value": 1.30, "operation": "multiply"},
			{"stat": "move_speed", "value": 0.90, "operation": "multiply"}
		]
	},
	"cursed_berserker_2": {
		"id": "cursed_berserker_2",
		"name": "Rabia Imparable",
		"description": "+50% velocidad de ataque, pero -20% velocidad movimiento.",
		"icon": "😤",
		"category": "cursed",
		"tier": 3,
		"is_cursed": true,
		"max_stacks": 2,
		"effects": [
			{"stat": "attack_speed_mult", "value": 1.50, "operation": "multiply"},
			{"stat": "move_speed", "value": 0.80, "operation": "multiply"}
		]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# CRÍTICOS vs DAÑO BASE
	# ─────────────────────────────────────────────────────────────────────────────
	"cursed_gambler_1": {
		"id": "cursed_gambler_1",
		"name": "Apuesta del Jugador",
		"description": "+20% prob. crítico, +50% daño crítico, pero -15% daño base.",
		"icon": "🎰",
		"category": "cursed",
		"tier": 3,
		"is_cursed": true,
		"max_stacks": 2,
		"effects": [
			{"stat": "crit_chance", "value": 0.20, "operation": "add"},
			{"stat": "crit_damage", "value": 0.50, "operation": "add"},
			{"stat": "damage_mult", "value": 0.85, "operation": "multiply"}
		]
	},
	"cursed_gambler_2": {
		"id": "cursed_gambler_2",
		"name": "Todo o Nada",
		"description": "+35% prob. crítico, +100% daño crítico, pero -25% daño base.",
		"icon": "🎰",
		"category": "cursed",
		"tier": 4,
		"is_cursed": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "crit_chance", "value": 0.35, "operation": "add"},
			{"stat": "crit_damage", "value": 1.0, "operation": "add"},
			{"stat": "damage_mult", "value": 0.75, "operation": "multiply"}
		]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ÁREA vs VELOCIDAD
	# ─────────────────────────────────────────────────────────────────────────────
	"cursed_heavy_weapons_1": {
		"id": "cursed_heavy_weapons_1",
		"name": "Armas Pesadas",
		"description": "+40% área de efecto, pero -15% velocidad de ataque.",
		"icon": "🔨",
		"category": "cursed",
		"tier": 2,
		"is_cursed": true,
		"max_stacks": 3,
		"effects": [
			{"stat": "area_mult", "value": 1.40, "operation": "multiply"},
			{"stat": "attack_speed_mult", "value": 0.85, "operation": "multiply"}
		]
	},
	"cursed_heavy_weapons_2": {
		"id": "cursed_heavy_weapons_2",
		"name": "Artillería",
		"description": "+75% área de efecto, pero -25% velocidad de ataque.",
		"icon": "🔨",
		"category": "cursed",
		"tier": 3,
		"is_cursed": true,
		"max_stacks": 2,
		"effects": [
			{"stat": "area_mult", "value": 1.75, "operation": "multiply"},
			{"stat": "attack_speed_mult", "value": 0.75, "operation": "multiply"}
		]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# VIDA vs VELOCIDAD
	# ─────────────────────────────────────────────────────────────────────────────
	"cursed_tank_1": {
		"id": "cursed_tank_1",
		"name": "Tanque Lento",
		"description": "+50 vida máxima, +5 armadura, pero -15% velocidad movimiento.",
		"icon": "🐢",
		"category": "cursed",
		"tier": 2,
		"is_cursed": true,
		"max_stacks": 3,
		"effects": [
			{"stat": "max_health", "value": 50, "operation": "add"},
			{"stat": "armor", "value": 5, "operation": "add"},
			{"stat": "move_speed", "value": 0.85, "operation": "multiply"}
		]
	},
	"cursed_tank_2": {
		"id": "cursed_tank_2",
		"name": "Fortaleza Móvil",
		"description": "+100 vida, +10 armadura, pero -25% velocidad movimiento.",
		"icon": "🐢",
		"category": "cursed",
		"tier": 3,
		"is_cursed": true,
		"max_stacks": 2,
		"effects": [
			{"stat": "max_health", "value": 100, "operation": "add"},
			{"stat": "armor", "value": 10, "operation": "add"},
			{"stat": "move_speed", "value": 0.75, "operation": "multiply"}
		]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# RECOMPENSAS vs DIFICULTAD
	# ─────────────────────────────────────────────────────────────────────────────
	"cursed_greed_1": {
		"id": "cursed_greed_1",
		"name": "Pacto de Avaricia",
		"description": "+30% oro y XP, pero +10% daño recibido.",
		"icon": "💰",
		"category": "cursed",
		"tier": 2,
		"is_cursed": true,
		"max_stacks": 3,
		"effects": [
			{"stat": "gold_mult", "value": 1.30, "operation": "multiply"},
			{"stat": "xp_mult", "value": 1.30, "operation": "multiply"},
			{"stat": "damage_taken_mult", "value": 1.10, "operation": "multiply"}
		]
	},
	"cursed_greed_2": {
		"id": "cursed_greed_2",
		"name": "Codicia Infinita",
		"description": "+60% oro y XP, pero +25% daño recibido.",
		"icon": "💰",
		"category": "cursed",
		"tier": 3,
		"is_cursed": true,
		"max_stacks": 2,
		"effects": [
			{"stat": "gold_mult", "value": 1.60, "operation": "multiply"},
			{"stat": "xp_mult", "value": 1.60, "operation": "multiply"},
			{"stat": "damage_taken_mult", "value": 1.25, "operation": "multiply"}
		]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# PROYECTILES vs DAÑO
	# ─────────────────────────────────────────────────────────────────────────────
	"cursed_scatter_1": {
		"id": "cursed_scatter_1",
		"name": "Disparo Disperso",
		"description": "+1 proyectil, pero -10% daño por proyectil.",
		"icon": "🎯",
		"category": "cursed",
		"tier": 3,
		"is_cursed": true,
		"max_stacks": 2,
		"effects": [
			{"stat": "extra_projectiles", "value": 1, "operation": "add"},
			{"stat": "damage_mult", "value": 0.90, "operation": "multiply"}
		]
	},
	"cursed_scatter_2": {
		"id": "cursed_scatter_2",
		"name": "Metralla",
		"description": "+2 proyectiles, pero -20% daño por proyectil.",
		"icon": "🎯",
		"category": "cursed",
		"tier": 4,
		"is_cursed": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "extra_projectiles", "value": 2, "operation": "add"},
			{"stat": "damage_mult", "value": 0.80, "operation": "multiply"}
		]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ROBO DE VIDA vs VIDA MÁXIMA
	# ─────────────────────────────────────────────────────────────────────────────
	"cursed_vampire_1": {
		"id": "cursed_vampire_1",
		"name": "Pacto Vampírico",
		"description": "+10% robo de vida, pero -25 vida máxima.",
		"icon": "🧛",
		"category": "cursed",
		"tier": 2,
		"is_cursed": true,
		"max_stacks": 3,
		"effects": [
			{"stat": "life_steal", "value": 0.10, "operation": "add"},
			{"stat": "max_health", "value": -25, "operation": "add"}
		]
	},
	"cursed_vampire_2": {
		"id": "cursed_vampire_2",
		"name": "Señor de la Noche",
		"description": "+20% robo de vida, pero -50 vida máxima.",
		"icon": "🧛",
		"category": "cursed",
		"tier": 3,
		"is_cursed": true,
		"max_stacks": 2,
		"effects": [
			{"stat": "life_steal", "value": 0.20, "operation": "add"},
			{"stat": "max_health", "value": -50, "operation": "add"}
		]
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ESQUIVA vs ARMADURA
	# ─────────────────────────────────────────────────────────────────────────────
	"cursed_nimble_1": {
		"id": "cursed_nimble_1",
		"name": "Danzarín de Sombras",
		"description": "+15% esquiva, pero -5 armadura.",
		"icon": "🌙",
		"category": "cursed",
		"tier": 2,
		"is_cursed": true,
		"max_stacks": 3,
		"effects": [
			{"stat": "dodge_chance", "value": 0.15, "operation": "add"},
			{"stat": "armor", "value": -5, "operation": "add"}
		]
	},
	"cursed_nimble_2": {
		"id": "cursed_nimble_2",
		"name": "Fantasma",
		"description": "+25% esquiva, pero -10 armadura.",
		"icon": "🌙",
		"category": "cursed",
		"tier": 3,
		"is_cursed": true,
		"max_stacks": 2,
		"effects": [
			{"stat": "dodge_chance", "value": 0.25, "operation": "add"},
			{"stat": "armor", "value": -10, "operation": "add"}
		]
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# MEJORAS ÚNICAS (Solo 1 por run - Efectos especiales)
# ═══════════════════════════════════════════════════════════════════════════════

const UNIQUE_UPGRADES: Dictionary = {
	"unique_phoenix_heart": {
		"id": "unique_phoenix_heart",
		"name": "Corazón de Fénix",
		"description": "Al morir, revives con 50% HP. (Se consume al usarse)",
		"icon": "🔥",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"is_consumable": true,
		"max_stacks": 1,
		"effects": [{"stat": "revives", "value": 1, "operation": "add"}]
	},
	"unique_second_chance": {
		"id": "unique_second_chance",
		"name": "Segunda Vida",
		"description": "Revives una vez con 50% HP + 3s invulnerabilidad. (Se consume)",
		"icon": "💫",
		"category": "unique",
		"tier": 4,
		"is_unique": true,
		"is_consumable": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "revives", "value": 1, "operation": "add"},
			{"stat": "revive_invuln", "value": 3.0, "operation": "add"}
		]
	},
	"unique_critical_mastery": {
		"id": "unique_critical_mastery",
		"name": "Maestría Crítica",
		"description": "Los golpes críticos siempre hacen daño máximo (+35% prob, +75% daño crit).",
		"icon": "⚡",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "crit_chance", "value": 0.35, "operation": "add"},
			{"stat": "crit_damage", "value": 0.75, "operation": "add"}
		]
	},
	"unique_executioner": {
		"id": "unique_executioner",
		"name": "Verdugo",
		"description": "Enemigos bajo 10% HP mueren instantáneamente.",
		"icon": "⚰️",
		"category": "unique",
		"tier": 4,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [{"stat": "execute_threshold", "value": 0.10, "operation": "add"}]
	},
	"unique_chain_lightning": {
		"id": "unique_chain_lightning",
		"name": "Rayo en Cadena",
		"description": "Todos los ataques saltan a 2 enemigos adicionales.",
		"icon": "⚡",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [{"stat": "chain_count", "value": 2, "operation": "add"}]
	},
	"unique_explosion_master": {
		"id": "unique_explosion_master",
		"name": "Maestro de Explosiones",
		"description": "25% prob. de explotar al matar (50 daño en área).",
		"icon": "💣",
		"category": "unique",
		"tier": 4,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "explosion_chance", "value": 0.25, "operation": "add"},
			{"stat": "explosion_damage", "value": 50, "operation": "add"}
		]
	},
	"unique_immortal": {
		"id": "unique_immortal",
		"name": "Inmortal",
		"description": "-20% daño recibido, +40% vida máxima.",
		"icon": "👑",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "damage_taken_mult", "value": 0.80, "operation": "multiply"},
			{"stat": "max_health", "value": 1.40, "operation": "multiply"}
		]
	},
	"unique_speed_demon": {
		"id": "unique_speed_demon",
		"name": "Demonio de la Velocidad",
		"description": "+50% velocidad movimiento, +30% velocidad de ataque.",
		"icon": "👹",
		"category": "unique",
		"tier": 4,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "move_speed", "value": 1.50, "operation": "multiply"},
			{"stat": "attack_speed_mult", "value": 1.30, "operation": "multiply"}
		]
	},
	"unique_treasure_hunter": {
		"id": "unique_treasure_hunter",
		"name": "Cazador de Tesoros",
		"description": "+100% oro, +50% suerte, +25% XP.",
		"icon": "💎",
		"category": "unique",
		"tier": 4,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "gold_mult", "value": 2.0, "operation": "multiply"},
			{"stat": "luck", "value": 0.50, "operation": "add"},
			{"stat": "xp_mult", "value": 1.25, "operation": "multiply"}
		]
	},
	"unique_bullet_hell": {
		"id": "unique_bullet_hell",
		"name": "Infierno de Balas",
		"description": "+3 proyectiles, pero -10% daño por proyectil.",
		"icon": "🔫",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "extra_projectiles", "value": 3, "operation": "add"},
			{"stat": "damage_mult", "value": 0.90, "operation": "multiply"}
		]
	},
	# ─────────────────────────────────────────────────────────────────────────────
	# NUEVAS MEJORAS ÚNICAS (v2.0)
	# ─────────────────────────────────────────────────────────────────────────────
	"unique_arcane_barrier": {
		"id": "unique_arcane_barrier",
		"name": "Barrera Arcana",
		"description": "Ganas un escudo de 50 HP que se regenera 5/s tras 3s sin daño.",
		"icon": "🔮",
		"category": "unique",
		"tier": 4,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "max_shield", "value": 50, "operation": "add"},
			{"stat": "shield_amount", "value": 50, "operation": "add"},
			{"stat": "shield_regen", "value": 5.0, "operation": "add"}
		]
	},
	"unique_combo_master": {
		"id": "unique_combo_master",
		"name": "Combo Master",
		"description": "+50% daño crítico, +10% prob. crítico, +20% velocidad ataque.",
		"icon": "🎯",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "crit_damage", "value": 0.50, "operation": "add"},
			{"stat": "crit_chance", "value": 0.10, "operation": "add"},
			{"stat": "attack_speed_mult", "value": 1.20, "operation": "multiply"}
		]
	},
	"unique_glass_sword": {
		"id": "unique_glass_sword",
		"name": "Espada de Cristal",
		"description": "+150% daño, pero -75% vida máxima.",
		"icon": "🗡️",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"is_cursed": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "damage_mult", "value": 2.50, "operation": "multiply"},
			{"stat": "max_health", "value": 0.25, "operation": "multiply"}
		]
	},
	"unique_slow_power": {
		"id": "unique_slow_power",
		"name": "Poder Concentrado",
		"description": "+80% daño y área, pero -40% velocidad ataque.",
		"icon": "💪",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"is_cursed": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "damage_mult", "value": 1.80, "operation": "multiply"},
			{"stat": "area_mult", "value": 1.80, "operation": "multiply"},
			{"stat": "attack_speed_mult", "value": 0.60, "operation": "multiply"}
		]
	},
	"unique_magnet_lord": {
		"id": "unique_magnet_lord",
		"name": "Señor del Magnetismo",
		"description": "+200% rango recogida, +50% XP, +30% velocidad.",
		"icon": "🧲",
		"category": "unique",
		"tier": 4,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "pickup_range", "value": 3.0, "operation": "multiply"},
			{"stat": "xp_mult", "value": 1.50, "operation": "multiply"},
			{"stat": "move_speed", "value": 1.30, "operation": "multiply"}
		]
	},
	"unique_berserker_rage": {
		"id": "unique_berserker_rage",
		"name": "Furia del Berserker",
		"description": "+50% daño, +25% velocidad ataque, pero -15% vida máxima.",
		"icon": "😡",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"is_cursed": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "damage_mult", "value": 1.50, "operation": "multiply"},
			{"stat": "attack_speed_mult", "value": 1.25, "operation": "multiply"},
			{"stat": "max_health", "value": 0.85, "operation": "multiply"}
		]
	},
	# ─────────────────────────────────────────────────────────────────────────────
	# NUEVAS MEJORAS ÚNICAS (v3.0) - Sistema de Escudo y Efectos de Estado
	# ─────────────────────────────────────────────────────────────────────────────
	"unique_energy_vampire": {
		"id": "unique_energy_vampire",
		"name": "Vampiro Energético",
		"description": "+75 Escudo, +5% life steal, -1s delay regeneración escudo.",
		"icon": "🧛",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "max_shield", "value": 75, "operation": "add"},
			{"stat": "shield_amount", "value": 75, "operation": "add"},
			{"stat": "shield_regen", "value": 8.0, "operation": "add"},
			{"stat": "life_steal", "value": 0.05, "operation": "add"},
			{"stat": "shield_regen_delay", "value": -1.0, "operation": "add"}
		]
	},
	"unique_affliction_master": {
		"id": "unique_affliction_master",
		"name": "Maestro de Aflicciones",
		"description": "+100% duración de efectos, +15% prob. congelar, +15% prob. sangrado.",
		"icon": "☠️",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "status_duration_mult", "value": 1.0, "operation": "add"},
			{"stat": "freeze_chance", "value": 0.15, "operation": "add"},
			{"stat": "bleed_chance", "value": 0.15, "operation": "add"}
		]
	},
	"unique_temporal_mage": {
		"id": "unique_temporal_mage",
		"name": "Mago Temporal",
		"description": "+50% duración de efectos, -20% cooldowns, +20% duración habilidades.",
		"icon": "🕐",
		"category": "unique",
		"tier": 4,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "status_duration_mult", "value": 0.50, "operation": "add"},
			{"stat": "cooldown_mult", "value": 0.80, "operation": "multiply"},
			{"stat": "duration_mult", "value": 1.20, "operation": "multiply"}
		]
	},
	"unique_guardian_angel": {
		"id": "unique_guardian_angel",
		"name": "Ángel Guardián",
		"description": "+100 Escudo, +50 HP, +1 revive, regenera escudo 2s más rápido.",
		"icon": "👼",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "max_shield", "value": 100, "operation": "add"},
			{"stat": "shield_amount", "value": 100, "operation": "add"},
			{"stat": "shield_regen", "value": 12.0, "operation": "add"},
			{"stat": "max_health", "value": 50, "operation": "add"},
			{"stat": "revives", "value": 1, "operation": "add"},
			{"stat": "shield_regen_delay", "value": -2.0, "operation": "add"}
		]
	},
	"unique_frost_nova": {
		"id": "unique_frost_nova",
		"name": "Nova de Escarcha",
		"description": "+30% prob. congelar, +75% duración congelación, +25% área.",
		"icon": "❄️",
		"category": "unique",
		"tier": 4,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "freeze_chance", "value": 0.30, "operation": "add"},
			{"stat": "status_duration_mult", "value": 0.75, "operation": "add"},
			{"stat": "area_mult", "value": 1.25, "operation": "multiply"}
		]
	},
	# ─────────────────────────────────────────────────────────────────────────────
	# NUEVAS MEJORAS ÚNICAS (v4.0) - Build-Defining
	# ─────────────────────────────────────────────────────────────────────────────
	"unique_orbital_mastery": {
		"id": "unique_orbital_mastery",
		"name": "Maestro Orbital",
		"description": "+50% daño orbital, +2 orbes adicionales, +30% velocidad orbital.",
		"icon": "🔮",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "orbital_damage_mult", "value": 0.50, "operation": "add"},
			{"stat": "orbital_count_bonus", "value": 2, "operation": "add"},
			{"stat": "orbital_speed_mult", "value": 1.30, "operation": "multiply"}
		]
	},
	"unique_projectile_specialist": {
		"id": "unique_projectile_specialist",
		"name": "Especialista en Proyectiles",
		"description": "+2 proyectiles, +30% velocidad proyectil, +25% penetración.",
		"icon": "🎯",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "extra_projectiles", "value": 2, "operation": "add"},
			{"stat": "projectile_speed_mult", "value": 1.30, "operation": "multiply"},
			{"stat": "extra_pierce", "value": 3, "operation": "add"}
		]
	},
	"unique_aoe_devastator": {
		"id": "unique_aoe_devastator",
		"name": "Devastador de Área",
		"description": "+60% área, +40% daño en área, -20% daño single target.",
		"icon": "💥",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "area_mult", "value": 1.60, "operation": "multiply"},
			{"stat": "aoe_damage_mult", "value": 0.40, "operation": "add"},
			{"stat": "single_target_mult", "value": 0.80, "operation": "multiply"}
		]
	},
	"unique_glass_mage": {
		"id": "unique_glass_mage",
		"name": "Mago de Cristal",
		"description": "+100% daño, +100% velocidad ataque, pero armadura = 0.",
		"icon": "💠",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"is_cursed": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "damage_mult", "value": 2.0, "operation": "multiply"},
			{"stat": "attack_speed_mult", "value": 2.0, "operation": "multiply"},
			{"stat": "armor", "value": -999, "operation": "add"}
		]
	},
	"unique_juggernaut": {
		"id": "unique_juggernaut",
		"name": "Juggernaut",
		"description": "+200 HP, +30 armadura, +15% daño, pero -30% velocidad.",
		"icon": "🦾",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"is_cursed": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "max_health", "value": 200, "operation": "add"},
			{"stat": "armor", "value": 30, "operation": "add"},
			{"stat": "damage_mult", "value": 1.15, "operation": "multiply"},
			{"stat": "move_speed", "value": 0.70, "operation": "multiply"}
		]
	},
	"unique_elemental_fusion": {
		"id": "unique_elemental_fusion",
		"name": "Fusión Elemental",
		"description": "+15% prob. quemar, congelar y sangrar. +50% daño a afectados.",
		"icon": "🌈",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "burn_chance", "value": 0.15, "operation": "add"},
			{"stat": "freeze_chance", "value": 0.15, "operation": "add"},
			{"stat": "bleed_chance", "value": 0.15, "operation": "add"},
			{"stat": "damage_vs_burning", "value": 0.50, "operation": "add"},
			{"stat": "damage_vs_frozen", "value": 0.50, "operation": "add"}
		]
	},
	"unique_soul_collector": {
		"id": "unique_soul_collector",
		"name": "Colector de Almas",
		"description": "+5 HP por kill, +3% daño permanente por cada 100 kills (max 30%).",
		"icon": "👻",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "kill_heal", "value": 5, "operation": "add"},
			{"stat": "kill_damage_scaling", "value": 0.03, "operation": "add"}
		]
	},
	"unique_lucky_star": {
		"id": "unique_lucky_star",
		"name": "Estrella de la Suerte",
		"description": "+75% suerte, +25% probabilidad crítico, +50% oro.",
		"icon": "⭐",
		"category": "unique",
		"tier": 4,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "luck", "value": 0.75, "operation": "add"},
			{"stat": "crit_chance", "value": 0.25, "operation": "add"},
			{"stat": "gold_mult", "value": 1.50, "operation": "multiply"}
		]
	},
	"unique_mirror_shield": {
		"id": "unique_mirror_shield",
		"name": "Escudo Espejo",
		"description": "Refleja 100% del daño recibido. +20% esquiva. -20% HP máx.",
		"icon": "🪞",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"is_cursed": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "thorns_percent", "value": 1.0, "operation": "add"},
			{"stat": "dodge_chance", "value": 0.20, "operation": "add"},
			{"stat": "max_health", "value": 0.80, "operation": "multiply"}
		]
	},
	"unique_time_dilation": {
		"id": "unique_time_dilation",
		"name": "Dilatación Temporal",
		"description": "Enemigos se mueven 25% más lento. -40% cooldowns. +25% velocidad.",
		"icon": "⏰",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "enemy_slow_aura", "value": 0.25, "operation": "add"},
			{"stat": "cooldown_mult", "value": 0.60, "operation": "multiply"},
			{"stat": "move_speed", "value": 1.25, "operation": "multiply"}
		]
	},
	"unique_blood_mage": {
		"id": "unique_blood_mage",
		"name": "Mago de Sangre",
		"description": "Las habilidades cuestan 5 HP pero hacen +50% daño. +20% life steal.",
		"icon": "🩸",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"is_cursed": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "hp_cost_per_attack", "value": 5, "operation": "add"},
			{"stat": "damage_mult", "value": 1.50, "operation": "multiply"},
			{"stat": "life_steal", "value": 0.20, "operation": "add"}
		]
	},
	"unique_gravity_well": {
		"id": "unique_gravity_well",
		"name": "Pozo de Gravedad",
		"description": "Atrae TODAS las monedas y gemas del mapa instantáneamente. +50% oro.",
		"icon": "🌀",
		"category": "unique",
		"tier": 5,
		"is_unique": true,
		"max_stacks": 1,
		"effects": [
			{"stat": "infinite_pickup_range", "value": 1, "operation": "add"},
			{"stat": "gold_mult", "value": 1.50, "operation": "multiply"}
		]
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# FUNCIONES DE ACCESO
# ═══════════════════════════════════════════════════════════════════════════════

static func get_all_player_upgrades() -> Array:
	"""Obtiene todas las mejoras de jugador combinadas"""
	var all_upgrades = []
	all_upgrades.append_array(DEFENSIVE_UPGRADES.values())
	all_upgrades.append_array(UTILITY_UPGRADES.values())
	all_upgrades.append_array(CURSED_UPGRADES.values())
	all_upgrades.append_array(UNIQUE_UPGRADES.values())
	return all_upgrades

static func get_defensive_upgrades() -> Array:
	return DEFENSIVE_UPGRADES.values()

static func get_utility_upgrades() -> Array:
	return UTILITY_UPGRADES.values()

static func get_cursed_upgrades() -> Array:
	return CURSED_UPGRADES.values()

static func get_unique_upgrades() -> Array:
	return UNIQUE_UPGRADES.values()

static func get_upgrade_by_id(upgrade_id: String) -> Dictionary:
	"""Busca una mejora por ID en todas las categorías"""
	if DEFENSIVE_UPGRADES.has(upgrade_id):
		return DEFENSIVE_UPGRADES[upgrade_id]
	if UTILITY_UPGRADES.has(upgrade_id):
		return UTILITY_UPGRADES[upgrade_id]
	if CURSED_UPGRADES.has(upgrade_id):
		return CURSED_UPGRADES[upgrade_id]
	if UNIQUE_UPGRADES.has(upgrade_id):
		return UNIQUE_UPGRADES[upgrade_id]
	return {}

static func get_random_player_upgrades(count: int, excluded_ids: Array, luck: float, game_time_minutes: float, owned_unique_ids: Array = [], common_tags: Array = [], all_tags: Array = []) -> Array:
	"""
	Obtiene mejoras aleatorias de jugador basadas en tier y tiempo.
	
	owned_unique_ids: IDs de mejoras únicas que el jugador ya posee
	common_tags: Tags presentes en TODAS las armas equipadas (para exclusión)
	all_tags: Tags presentes en AL MENOS UNA arma equipada (para requisitos)
	"""
	var all_available = []
	
	# Función auxiliar para filtrar
	var check_tags = func(upgrade):
		# Chequear exclusión (si TODAS las armas tienen el tag prohibido)
		if upgrade.has("excluded_tags"):
			for tag in upgrade.excluded_tags:
				if tag in common_tags:
					return false
		
		# Chequear requisitos (si NINGUNA arma tiene el tag requerido)
		if upgrade.has("required_tags"):
			for tag in upgrade.required_tags:
				if tag not in all_tags:
					# Excepción: si el upgrade OTORGA el tag (ej: weapon evolution), permitirlo
					# pero aquí son stats pasivos.
					return false
		return true
	
	# Añadir mejoras normales
	for upgrade in DEFENSIVE_UPGRADES.values():
		if upgrade.id not in excluded_ids:
			if check_tags.call(upgrade):
				all_available.append(upgrade)
	
	for upgrade in UTILITY_UPGRADES.values():
		if upgrade.id not in excluded_ids:
			if check_tags.call(upgrade):
				all_available.append(upgrade)
	
	# Añadir cursed (menos frecuentes - 30% chance de incluirlas)
	if randf() < 0.3:
		for upgrade in CURSED_UPGRADES.values():
			if upgrade.id not in excluded_ids:
				if check_tags.call(upgrade):
					all_available.append(upgrade)
	
	# Añadir únicas (si no las tiene ya)
	for upgrade in UNIQUE_UPGRADES.values():
		if upgrade.id not in excluded_ids and upgrade.id not in owned_unique_ids:
			if check_tags.call(upgrade):
				all_available.append(upgrade)
	
	if all_available.is_empty():
		return []
	
	# Calcular pesos por tier basados en tiempo
	var tier_weights = _calculate_tier_weights(game_time_minutes, luck)
	
	var selected = []
	var attempts = 0
	var max_attempts = count * 15
	
	while selected.size() < count and attempts < max_attempts:
		attempts += 1
		
		var target_tier = _weighted_random_tier(tier_weights)
		var tier_upgrades = all_available.filter(func(u): return u.get("tier", 1) == target_tier)
		
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
	"""Calcula pesos de tier basados en tiempo y suerte"""
	var weights = {1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0}
	
	if game_time_minutes < 3.0:
		weights = {1: 0.75, 2: 0.22, 3: 0.03, 4: 0.0, 5: 0.0}
	elif game_time_minutes < 8.0:
		weights = {1: 0.45, 2: 0.35, 3: 0.17, 4: 0.03, 5: 0.0}
	elif game_time_minutes < 15.0:
		weights = {1: 0.20, 2: 0.35, 3: 0.30, 4: 0.13, 5: 0.02}
	elif game_time_minutes < 25.0:
		weights = {1: 0.08, 2: 0.22, 3: 0.35, 4: 0.27, 5: 0.08}
	else:
		weights = {1: 0.03, 2: 0.12, 3: 0.30, 4: 0.35, 5: 0.20}
	
	# Bonus de suerte
	if luck > 0:
		var luck_factor = clampf(luck * 0.15, 0.0, 0.4)
		var shift = (weights[1] + weights[2]) * luck_factor
		weights[1] *= (1.0 - luck_factor)
		weights[2] *= (1.0 - luck_factor * 0.5)
		weights[3] += shift * 0.35
		weights[4] += shift * 0.40
		weights[5] += shift * 0.25
	
	return weights

static func _weighted_random_tier(weights: Dictionary) -> int:
	"""Selecciona tier aleatorio basado en pesos"""
	var total = 0.0
	for w in weights.values():
		total += w
	
	var roll = randf() * total
	var cumulative = 0.0
	
	for tier in weights:
		cumulative += weights[tier]
		if roll <= cumulative:
			return tier
	
	return 1

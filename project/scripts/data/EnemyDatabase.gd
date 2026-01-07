# EnemyDatabase.gd
# Base de datos centralizada de todos los enemigos del juego
# Similar a WeaponDatabase pero para enemigos
#
# ARQUETIPOS DE COMPORTAMIENTO:
# - melee: Persigue y ataca cuerpo a cuerpo
# - agile: Rápido, movimiento en zigzag, hit & run
# - tank: Lento pero muy resistente
# - flying: Movimiento errático, puede esquivar
# - debuffer: Aplica efectos negativos (slow, poison)
# - blocker: Puede bloquear/reducir daño ocasionalmente
# - pack: Bonus cuando hay aliados del mismo tipo cerca
# - ranged: Ataca a distancia con proyectiles
# - phase: Puede volverse intangible brevemente
# - charger: Hace dash/carga hacia el jugador
# - trail: Deja rastro dañino al moverse
# - teleporter: Se teletransporta ocasionalmente
# - support: Buff a aliados cercanos
# - aoe: Ataques de área
# - breath: Ataque en cono
# - multi: Múltiples tipos de ataque
# - boss: Comportamiento de boss con fases

extends Node
class_name EnemyDatabase

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTES DE ESCALADO
# ═══════════════════════════════════════════════════════════════════════════════

# Escalado base por tier (multiplicadores respecto a tier 1)
const TIER_SCALING = {
	1: {"hp": 1.0, "damage": 1.0, "speed": 1.0, "xp": 1.0},
	2: {"hp": 2.5, "damage": 1.8, "speed": 1.1, "xp": 3.0},
	3: {"hp": 5.0, "damage": 3.0, "speed": 1.2, "xp": 7.0},
	4: {"hp": 10.0, "damage": 5.0, "speed": 1.3, "xp": 15.0},
	5: {"hp": 1.0, "damage": 1.0, "speed": 1.0, "xp": 50.0}  # Bosses - NO multiplicar HP/daño (ya tienen base_hp alto)
}

# Escalado exponencial post-minuto 20 (cada 5 minutos)
const EXPONENTIAL_SCALING_BASE = 1.5  # 50% más fuerte cada 5 min después de min 20

# Configuración de élites/legendarios - EXTREMADAMENTE BUFFADOS
const ELITE_CONFIG = {
	"hp_multiplier": 10.0,          # 10x HP base - son mini-bosses
	"damage_multiplier": 3.5,       # 3.5x daño - duelen mucho
	"size_multiplier": 1.8,         # 80% más grandes - imponentes
	"xp_multiplier": 20.0,          # 20x XP - gran recompensa
	"speed_multiplier": 1.35,       # 35% más rápidos - agresivos
	"attack_speed_multiplier": 0.55,# Atacan 45% más rápido
	"spawn_chance_per_minute": 0.025, # 2.5% por minuto
	"max_per_run": 10,
	"min_spawn_minute": 2,
	"aura_color": Color(1.0, 0.85, 0.1, 0.95),  # Dorado brillante
	"aura_pulse_speed": 4.0,        # Aura pulsante más rápida
	# Habilidades especiales para élites - MUCHAS MÁS
	"extra_abilities": ["elite_slam", "elite_rage", "elite_shield", "elite_dash", "elite_nova", "elite_summon"],
	# Elite Slam - Golpe de área devastador
	"slam_cooldown": 4.0,           # Más frecuente
	"slam_radius": 100.0,           # Radio más grande
	"slam_damage_mult": 2.0,        # El doble de daño
	# Elite Rage - Furia al estar bajo de vida
	"rage_hp_threshold": 0.5,       # Se enfurece al 50% HP (antes)
	"rage_damage_bonus": 0.75,      # +75% daño en rage
	"rage_speed_bonus": 0.5,        # +50% velocidad en rage
	# Elite Shield - Escudo protector
	"shield_charges": 5,            # 5 hits absorbidos
	"shield_cooldown": 12.0,        # Cooldown más corto
	# Elite Dash - Embestida hacia el jugador
	"dash_cooldown": 3.0,
	"dash_speed": 600.0,
	"dash_damage_mult": 1.8,
	# Elite Nova - Explosión de proyectiles en círculo
	"nova_cooldown": 6.0,
	"nova_projectile_count": 12,
	"nova_damage_mult": 0.8,
	# Elite Summon - Invoca minions temporales
	"summon_cooldown": 10.0,
	"summon_count": 3,
	"ability_use_chance": 0.50      # 50% de usar habilidad por ataque
}

# Tiempo de aparición de tiers
const TIER_SPAWN_TIMES = {
	1: 0,    # Desde el inicio
	2: 5,    # Minuto 5+
	3: 10,   # Minuto 10+
	4: 15,   # Minuto 15+
}

# Tiempo de bosses (cada 5 minutos)
const BOSS_SPAWN_INTERVAL = 5.0  # minutos

# ═══════════════════════════════════════════════════════════════════════════════
# BASE DE DATOS DE ENEMIGOS - TIER 1
# ═══════════════════════════════════════════════════════════════════════════════

const TIER_1_ENEMIES = {
	"esqueleto_aprendiz": {
		"id": "tier_1_esqueleto_aprendiz",
		"name": "Esqueleto Aprendiz",
		"tier": 1,
		"archetype": "melee",
		"base_hp": 20,
		"base_damage": 6,
		"base_speed": 45.0,
		"base_xp": 1,
		"attack_range": 32.0,
		"attack_cooldown": 1.2,
		"collision_radius": 14.0,
		"description": "Un esqueleto reanimado con conocimientos básicos de combate.",
		"special_abilities": [],
		"modifiers": {}  # Sin modificadores especiales
	},
	"duende_sombrio": {
		"id": "tier_1_duende_sombrio",
		"name": "Duende Sombrío",
		"tier": 1,
		"archetype": "agile",
		"base_hp": 12,
		"base_damage": 5,
		"base_speed": 70.0,
		"base_xp": 1,
		"attack_range": 28.0,
		"attack_cooldown": 0.8,
		"collision_radius": 12.0,
		"description": "Pequeño y escurridizo, ataca rápido y huye.",
		"special_abilities": ["zigzag_movement", "hit_and_run"],
		"modifiers": {
			"hp": 0.6,      # 40% menos HP
			"speed": 1.4,   # 40% más rápido
			"damage": 0.8   # 20% menos daño
		}
	},
	"slime_arcano": {
		"id": "tier_1_slime_arcano",
		"name": "Slime Arcano",
		"tier": 1,
		"archetype": "tank",
		"base_hp": 35,
		"base_damage": 5,
		"base_speed": 25.0,
		"base_xp": 2,
		"attack_range": 24.0,
		"attack_cooldown": 1.3,
		"collision_radius": 18.0,
		"description": "Masa gelatinosa imbuida de magia. Lenta pero resistente.",
		"special_abilities": ["split_on_death"],
		"modifiers": {
			"hp": 1.75,     # 75% más HP
			"speed": 0.6,   # 40% más lento
			"damage": 0.7   # 30% menos daño
		}
	},
	"murcielago_etereo": {
		"id": "tier_1_murcielago_etereo",
		"name": "Murciélago Etéreo",
		"tier": 1,
		"archetype": "flying",
		"base_hp": 10,
		"base_damage": 4,
		"base_speed": 55.0,
		"base_xp": 1,
		"attack_range": 20.0,
		"attack_cooldown": 0.7,
		"collision_radius": 10.0,
		"description": "Criatura voladora con movimiento impredecible.",
		"special_abilities": ["erratic_movement", "evasion"],
		"modifiers": {
			"hp": 0.5,      # 50% menos HP
			"speed": 1.3,   # 30% más rápido
			"evasion": 0.15 # 15% evasión
		}
	},
	"arana_venenosa": {
		"id": "tier_1_arana_venenosa",
		"name": "Araña Venenosa",
		"tier": 1,
		"archetype": "debuffer",
		"base_hp": 18,
		"base_damage": 5,
		"base_speed": 40.0,
		"base_xp": 2,
		"attack_range": 30.0,
		"attack_cooldown": 1.3,
		"collision_radius": 14.0,
		"description": "Sus ataques envenenan y ralentizan a la presa.",
		"special_abilities": ["poison_attack", "slow_attack"],
		"modifiers": {
			"poison_damage": 2,      # DPS de veneno
			"poison_duration": 3.0,  # Segundos
			"slow_amount": 0.2,      # 20% slow
			"slow_duration": 2.0
		}
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# BASE DE DATOS DE ENEMIGOS - TIER 2
# ═══════════════════════════════════════════════════════════════════════════════

const TIER_2_ENEMIES = {
	"guerrero_espectral": {
		"id": "tier_2_guerrero_espectral",
		"name": "Guerrero Espectral",
		"tier": 2,
		"archetype": "blocker",
		"base_hp": 50,
		"base_damage": 12,
		"base_speed": 38.0,
		"base_xp": 4,
		"attack_range": 36.0,
		"attack_cooldown": 1.4,
		"collision_radius": 16.0,
		"description": "Espíritu de un guerrero caído. Puede bloquear ataques.",
		"special_abilities": ["block_chance", "counter_attack"],
		"modifiers": {
			"block_chance": 0.25,    # 25% de bloquear
			"block_reduction": 0.7,  # Reduce 70% del daño bloqueado
			"counter_damage": 1.5    # 150% daño en contraataque
		}
	},
	"lobo_de_cristal": {
		"id": "tier_2_lobo_de_cristal",
		"name": "Lobo de Cristal",
		"tier": 2,
		"archetype": "pack",
		"base_hp": 35,
		"base_damage": 10,
		"base_speed": 55.0,
		"base_xp": 3,
		"attack_range": 32.0,
		"attack_cooldown": 1.0,
		"collision_radius": 15.0,
		"description": "Caza en manada. Más peligroso junto a sus compañeros.",
		"special_abilities": ["pack_bonus"],
		"modifiers": {
			"pack_radius": 200.0,      # Radio para detectar aliados
			"pack_damage_bonus": 0.15, # +15% daño por cada aliado cercano
			"pack_speed_bonus": 0.05,  # +5% velocidad por aliado
			"max_pack_bonus": 3        # Máximo 3 aliados cuentan
		}
	},
	"golem_runico": {
		"id": "tier_2_golem_runico",
		"name": "Gólem Rúnico",
		"tier": 2,
		"archetype": "tank",
		"base_hp": 90,
		"base_damage": 18,
		"base_speed": 22.0,
		"base_xp": 5,
		"attack_range": 40.0,
		"attack_cooldown": 2.0,
		"collision_radius": 22.0,
		"description": "Construcción mágica masiva. Extremadamente resistente.",
		"special_abilities": ["stomp_attack", "damage_reduction"],
		"modifiers": {
			"hp": 2.0,              # Doble HP base
			"speed": 0.5,           # Mitad de velocidad
			"damage_reduction": 0.2, # Reduce 20% todo el daño recibido
			"stomp_radius": 60.0,
			"stomp_cooldown": 5.0
		}
	},
	"hechicero_desgastado": {
		"id": "tier_2_hechicero_desgastado",
		"name": "Hechicero Desgastado",
		"tier": 2,
		"archetype": "ranged",
		"base_hp": 30,
		"base_damage": 14,
		"base_speed": 30.0,
		"base_xp": 4,
		"attack_range": 250.0,
		"attack_cooldown": 2.0,
		"collision_radius": 14.0,
		"description": "Mago corrupto que ataca desde la distancia.",
		"special_abilities": ["ranged_attack", "keep_distance"],
		"modifiers": {
			"preferred_distance": 180.0,  # Intenta mantener esta distancia
			"projectile_speed": 200.0,
			"projectile_damage": 14
		}
	},
	"sombra_flotante": {
		"id": "tier_2_sombra_flotante",
		"name": "Sombra Flotante",
		"tier": 2,
		"archetype": "phase",
		"base_hp": 28,
		"base_damage": 11,
		"base_speed": 45.0,
		"base_xp": 4,
		"attack_range": 28.0,
		"attack_cooldown": 1.2,
		"collision_radius": 13.0,
		"description": "Entidad etérea que puede volverse intangible.",
		"special_abilities": ["phase_shift"],
		"modifiers": {
			"phase_duration": 1.5,      # Segundos intangible
			"phase_cooldown": 6.0,      # Cooldown de la habilidad
			"phase_speed_bonus": 1.5    # 50% más rápido mientras está en fase
		}
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# BASE DE DATOS DE ENEMIGOS - TIER 3
# ═══════════════════════════════════════════════════════════════════════════════

const TIER_3_ENEMIES = {
	"caballero_del_vacio": {
		"id": "tier_3_caballero_del_vacio",
		"name": "Caballero del Vacío",
		"tier": 3,
		"archetype": "charger",
		"base_hp": 85,
		"base_damage": 22,
		"base_speed": 42.0,
		"base_xp": 8,
		"attack_range": 38.0,
		"attack_cooldown": 1.5,
		"collision_radius": 18.0,
		"description": "Guerrero corrompido por el vacío. Carga hacia sus enemigos.",
		"special_abilities": ["charge_attack"],
		"modifiers": {
			"charge_speed": 300.0,       # Velocidad durante carga
			"charge_damage_mult": 2.0,   # x2 daño en carga
			"charge_cooldown": 4.0,
			"charge_distance": 200.0,    # Distancia máxima de carga
			"charge_windup": 0.5         # Tiempo de preparación
		}
	},
	"serpiente_de_fuego": {
		"id": "tier_3_serpiente_de_fuego",
		"name": "Serpiente de Fuego",
		"tier": 3,
		"archetype": "trail",
		"base_hp": 60,
		"base_damage": 18,
		"base_speed": 55.0,
		"base_xp": 7,
		"attack_range": 30.0,
		"attack_cooldown": 1.0,
		"collision_radius": 14.0,
		"description": "Deja un rastro de fuego ardiente a su paso.",
		"special_abilities": ["fire_trail"],
		"modifiers": {
			"trail_damage": 8,           # Daño por segundo del rastro
			"trail_duration": 3.0,       # Segundos que dura el rastro
			"trail_interval": 0.2,       # Cada cuánto deja fuego
			"trail_radius": 20.0
		}
	},
	"elemental_de_hielo": {
		"id": "tier_3_elemental_de_hielo",
		"name": "Elemental de Hielo",
		"tier": 3,
		"archetype": "ranged",
		"base_hp": 70,
		"base_damage": 20,
		"base_speed": 35.0,
		"base_xp": 8,
		"attack_range": 280.0,
		"attack_cooldown": 1.5,
		"collision_radius": 16.0,
		"description": "Ser de hielo puro. Sus proyectiles congelan.",
		"special_abilities": ["ranged_attack", "freeze_projectile"],
		"modifiers": {
			"projectile_speed": 180.0,
			"slow_amount": 0.4,          # 40% slow
			"slow_duration": 2.5,
			"freeze_chance": 0.1,        # 10% chance de congelar 1s
			"preferred_distance": 200.0
		}
	},
	"mago_abismal": {
		"id": "tier_3_mago_abismal",
		"name": "Mago Abismal",
		"tier": 3,
		"archetype": "teleporter",
		"base_hp": 55,
		"base_damage": 28,
		"base_speed": 32.0,
		"base_xp": 9,
		"attack_range": 300.0,
		"attack_cooldown": 2.2,
		"collision_radius": 14.0,
		"description": "Domina la magia del vacío. Se teletransporta para evadir.",
		"special_abilities": ["ranged_attack", "teleport"],
		"modifiers": {
			"teleport_cooldown": 5.0,
			"teleport_range": 150.0,     # Distancia máxima de teleport
			"teleport_health_threshold": 0.4, # Teleporta si HP < 40%
			"projectile_speed": 160.0
		}
	},
	"corruptor_alado": {
		"id": "tier_3_corruptor_alado",
		"name": "Corruptor Alado",
		"tier": 3,
		"archetype": "support",
		"base_hp": 65,
		"base_damage": 15,
		"base_speed": 48.0,
		"base_xp": 10,
		"attack_range": 34.0,
		"attack_cooldown": 1.3,
		"collision_radius": 16.0,
		"description": "Criatura alada que potencia a sus aliados.",
		"special_abilities": ["flying", "buff_allies"],
		"modifiers": {
			"buff_radius": 150.0,
			"buff_damage_bonus": 0.25,   # +25% daño a aliados
			"buff_speed_bonus": 0.15,    # +15% velocidad a aliados
			"buff_duration": 5.0,
			"buff_cooldown": 8.0
		}
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# BASE DE DATOS DE ENEMIGOS - TIER 4
# ═══════════════════════════════════════════════════════════════════════════════

const TIER_4_ENEMIES = {
	"titan_arcano": {
		"id": "tier_4_titan_arcano",
		"name": "Titán Arcano",
		"tier": 4,
		"archetype": "tank",
		"base_hp": 200,
		"base_damage": 45,
		"base_speed": 25.0,
		"base_xp": 18,
		"attack_range": 50.0,
		"attack_cooldown": 2.2,
		"collision_radius": 28.0,
		"description": "Gigante imbuido de magia ancestral. Devastador en combate.",
		"special_abilities": ["stomp_attack", "aoe_slam", "damage_reduction"],
		"modifiers": {
			"hp": 2.5,
			"damage_reduction": 0.3,
			"stomp_radius": 100.0,
			"stomp_damage": 40,
			"stomp_cooldown": 4.0,
			"slam_radius": 80.0,
			"slam_cooldown": 6.0
		}
	},
	"senor_de_las_llamas": {
		"id": "tier_4_senor_de_las_llamas",
		"name": "Señor de las Llamas",
		"tier": 4,
		"archetype": "aoe",
		"base_hp": 140,
		"base_damage": 38,
		"base_speed": 35.0,
		"base_xp": 16,
		"attack_range": 200.0,
		"attack_cooldown": 1.7,
		"collision_radius": 20.0,
		"description": "Maestro del fuego. Crea zonas ardientes letales.",
		"special_abilities": ["ranged_attack", "fire_zone", "burn_aura"],
		"modifiers": {
			"fire_zone_radius": 80.0,
			"fire_zone_damage": 15,      # DPS
			"fire_zone_duration": 5.0,
			"fire_zone_cooldown": 7.0,
			"burn_aura_radius": 50.0,
			"burn_aura_damage": 5        # DPS cercano
		}
	},
	"reina_del_hielo": {
		"id": "tier_4_reina_del_hielo",
		"name": "Reina del Hielo",
		"tier": 4,
		"archetype": "aoe",
		"base_hp": 130,
		"base_damage": 18,
		"base_speed": 32.0,
		"base_xp": 16,
		"attack_range": 220.0,
		"attack_cooldown": 1.8,
		"collision_radius": 18.0,
		"description": "Soberana del frío eterno. Congela todo a su alrededor.",
		"special_abilities": ["ranged_attack", "freeze_zone", "ice_armor"],
		"modifiers": {
			"freeze_zone_radius": 120.0,
			"freeze_zone_slow": 0.5,     # 50% slow
			"freeze_zone_duration": 4.0,
			"freeze_zone_cooldown": 8.0,
			"ice_armor_reduction": 0.25, # 25% menos daño
			"shatter_damage": 50         # Daño al romper congelación
		}
	},
	"archimago_perdido": {
		"id": "tier_4_archimago_perdido",
		"name": "Archimago Perdido",
		"tier": 4,
		"archetype": "multi",
		"base_hp": 110,
		"base_damage": 38,
		"base_speed": 30.0,
		"base_xp": 20,
		"attack_range": 280.0,
		"attack_cooldown": 1.8,
		"collision_radius": 16.0,
		"description": "Mago de inmenso poder que domina múltiples elementos.",
		"special_abilities": ["ranged_attack", "teleport", "multi_element"],
		"modifiers": {
			"teleport_cooldown": 6.0,
			"element_cycle": ["fire", "ice", "void"],  # Cicla entre elementos
			"fire_projectile_burn": 3.0,   # Segundos de burn
			"ice_projectile_slow": 0.35,
			"void_projectile_pull": 50.0   # Fuerza de pull
		}
	},
	"dragon_etereo": {
		"id": "tier_4_dragon_etereo",
		"name": "Dragón Etéreo",
		"tier": 4,
		"archetype": "breath",
		"base_hp": 180,
		"base_damage": 32,
		"base_speed": 40.0,
		"base_xp": 22,
		"attack_range": 180.0,
		"attack_cooldown": 2.5,
		"collision_radius": 24.0,
		"description": "Dragón espectral. Su aliento arrasa con todo.",
		"special_abilities": ["flying", "breath_attack", "dive_attack"],
		"modifiers": {
			"breath_angle": 45.0,        # Grados del cono
			"breath_range": 200.0,
			"breath_damage": 20,         # Por tick
			"breath_duration": 2.0,
			"breath_cooldown": 6.0,
			"dive_damage_mult": 2.5,
			"dive_cooldown": 8.0
		}
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# BASE DE DATOS DE BOSSES - STATS BASE SIMILARES, DIFICULTAD ESCALA POR MINUTO
# Todos los bosses tienen stats base equilibrados.
# La dificultad real depende del minuto en que aparecen (5, 10, 15, 20+)
# ═══════════════════════════════════════════════════════════════════════════════

const BOSSES = {
	"el_conjurador_primigenio": {
		"id": "boss_el_conjurador",
		"name": "El Conjurador Primigenio",
		"tier": 5,
		"archetype": "boss",
		"base_hp": 1200,         # Más HP
		"base_damage": 22,       # Más daño
		"base_speed": 50.0,      # Más rápido (era 30)
		"base_xp": 150,
		"attack_range": 700.0,   # Rango enorme - ataca desde lejos
		"attack_cooldown": 0.9,  # Cooldown muy bajo
		"collision_radius": 32.0,
		"description": "El primer mago. Domina la invocación y la magia arcana.",
		"phases": 3,
		"special_abilities": [
			"arcane_barrage",
			"summon_minions",
			"teleport_strike",
			"arcane_nova",
			"curse_aura"
		],
		"ability_cooldowns": {
			"arcane_barrage": 2.0,    # Reducido
			"summon_minions": 8.0,    # Reducido
			"teleport_strike": 5.0,   # Reducido
			"arcane_nova": 6.0,       # Reducido
			"curse_aura": 10.0        # Reducido
		},
		"modifiers": {
			"barrage_count": 8,       # Más proyectiles
			"barrage_damage": 18,     # Más daño
			"barrage_spread": 45.0,   # Mayor dispersión
			"summon_count": 3,        # Más invocaciones
			"summon_tier": 2,         # Invocaciones más fuertes
			"teleport_range": 300.0,  # Mayor rango de teleport
			"teleport_damage_mult": 2.0,
			"nova_radius": 180.0,     # Mayor radio
			"nova_damage": 45,        # Más daño
			"curse_radius": 200.0,    # Mayor radio de maldición
			"curse_reduction": 0.6,   # Mayor reducción
			"curse_duration": 10.0,
			"phase_2_hp": 0.65,
			"phase_3_hp": 0.3,
			"phase_2_summon_count": 5,
			"phase_2_barrage_count": 12,
			"phase_3_summon_tier": 3,
			"phase_3_nova_damage": 70
		}
	},
	"el_corazon_del_vacio": {
		"id": "boss_el_corazon",
		"name": "El Corazón del Vacío",
		"tier": 5,
		"archetype": "boss",
		"base_hp": 1200,          # Más HP
		"base_damage": 25,        # Más daño
		"base_speed": 55.0,       # MUCHO más rápido (era 18)
		"base_xp": 150,
		"attack_range": 800.0,    # Rango enorme - ataca desde lejos
		"attack_cooldown": 0.8,   # Cooldown muy bajo
		"collision_radius": 45.0,
		"description": "Núcleo de energía del vacío. Distorsiona la realidad a su alrededor.",
		"phases": 3,
		"special_abilities": [
			"void_pull",
			"void_explosion",
			"void_orbs",
			"reality_tear",
			"damage_aura",
			"void_beam"
		],
		"ability_cooldowns": {
			"void_pull": 4.0,          # Reducido
			"void_explosion": 6.0,     # Reducido
			"void_orbs": 3.0,          # Reducido
			"reality_tear": 8.0,       # Reducido
			"damage_aura": 0.0,
			"void_beam": 10.0          # Reducido
		},
		"modifiers": {
			"pull_radius": 450.0,      # Mayor radio
			"pull_force": 200.0,       # Mayor fuerza
			"pull_duration": 3.0,
			"explosion_radius": 220.0, # Mayor radio
			"explosion_damage": 70,    # Más daño
			"orb_count": 5,            # Más orbes
			"orb_damage": 30,          # Más daño
			"orb_speed": 180.0,        # Más rápidos
			"orb_duration": 6.0,
			"tear_radius": 100.0,
			"tear_damage": 18,
			"tear_duration": 7.0,
			"aura_radius": 130.0,
			"aura_damage": 10,
			"beam_damage": 35,
			"beam_duration": 3.5,
			"beam_width": 50.0,
			"phase_2_hp": 0.6,         # Fase 2 antes
			"phase_3_hp": 0.3,
			"phase_2_pull_force": 280.0,
			"phase_2_orb_count": 7,
			"phase_3_aura_radius": 180.0,
			"phase_3_explosion_damage": 100
		}
	},
	"el_guardian_de_runas": {
		"id": "boss_el_guardian",
		"name": "El Guardián de Runas",
		"tier": 5,
		"archetype": "boss",
		"base_hp": 1200,
		"base_damage": 20,
		"base_speed": 50.0,       # Más rápido (era 25)
		"base_xp": 150,
		"attack_range": 600.0,    # Mayor rango
		"attack_cooldown": 1.0,   # Más rápido
		"collision_radius": 42.0,
		"description": "Protector ancestral cubierto de runas de poder. Casi indestructible.",
		"phases": 3,
		"special_abilities": [
			"rune_shield",
			"rune_blast",
			"rune_prison",
			"counter_stance",
			"rune_barrage",
			"ground_slam"
		],
		"ability_cooldowns": {
			"rune_shield": 18.0,
			"rune_blast": 5.0,
			"rune_prison": 12.0,
			"counter_stance": 10.0,
			"rune_barrage": 7.0,
			"ground_slam": 8.0
		},
		"modifiers": {
			"shield_charges": 4,
			"shield_duration": 10.0,
			"blast_radius": 120.0,
			"blast_damage": 35,
			"prison_duration": 1.5,
			"prison_damage": 15,
			"counter_window": 2.0,
			"counter_damage_mult": 2.5,
			"barrage_count": 6,
			"barrage_damage": 15,
			"slam_radius": 150.0,
			"slam_damage": 35,
			"slam_stun": 0.5,
			"phase_2_hp": 0.6,
			"phase_3_hp": 0.25,
			"phase_2_shield_charges": 6,
			"phase_2_blast_damage": 50,
			"phase_3_counter_damage_mult": 3.5,
			"phase_3_slam_damage": 55
		}
	},
	"minotauro_de_fuego": {
		"id": "boss_minotauro",
		"name": "Minotauro de Fuego",
		"tier": 5,
		"archetype": "boss",
		"base_hp": 1400,          # Más HP (tanque)
		"base_damage": 28,        # Más daño
		"base_speed": 55.0,       # Más rápido (era 35)
		"base_xp": 150,
		"attack_range": 500.0,    # Mayor rango
		"attack_cooldown": 0.8,   # Cooldown muy bajo
		"collision_radius": 36.0,
		"description": "La bestia definitiva. Furia y fuego encarnados.",
		"phases": 3,
		"special_abilities": [
			"charge_attack",
			"fire_stomp",
			"flame_breath",
			"meteor_call",
			"enrage",
			"fire_trail"
		],
		"ability_cooldowns": {
			"charge_attack": 3.0,     # Reducido
			"fire_stomp": 4.0,        # Reducido
			"flame_breath": 5.0,      # Reducido
			"meteor_call": 8.0,       # Reducido
			"enrage": 0.0,
			"fire_trail": 0.0
		},
		"modifiers": {
			"charge_speed": 550.0,    # Más rápido
			"charge_damage_mult": 3.0,
			"charge_stun": 1.0,
			"stomp_radius": 200.0,    # Mayor radio
			"stomp_damage": 60,       # Más daño
			"stomp_burn": 15.0,
			"stomp_burn_duration": 5.0,
			"breath_angle": 65.0,     # Más ancho
			"breath_range": 250.0,    # Más alcance
			"breath_damage": 30,      # Más daño
			"breath_duration": 3.0,
			"meteor_count": 8,        # Más meteoros
			"meteor_damage": 55,      # Más daño
			"meteor_radius": 80.0,    # Mayor radio
			"meteor_delay": 1.2,      # Más rápido
			"enrage_threshold": 0.35, # Enrage antes
			"enrage_damage_bonus": 0.7,
			"enrage_speed_bonus": 0.4,
			"trail_damage": 12,
			"trail_duration": 4.0,
			"phase_2_hp": 0.6,
			"phase_3_hp": 0.25,
			"phase_2_charge_damage_mult": 4.0,
			"phase_2_stomp_radius": 250.0,
			"phase_3_meteor_count": 12,
			"phase_3_breath_damage": 50
		}
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# FUNCIONES DE ACCESO
# ═══════════════════════════════════════════════════════════════════════════════

static func get_all_tier_1() -> Dictionary:
	return TIER_1_ENEMIES.duplicate(true)

static func get_all_tier_2() -> Dictionary:
	return TIER_2_ENEMIES.duplicate(true)

static func get_all_tier_3() -> Dictionary:
	return TIER_3_ENEMIES.duplicate(true)

static func get_all_tier_4() -> Dictionary:
	return TIER_4_ENEMIES.duplicate(true)

static func get_all_bosses() -> Dictionary:
	return BOSSES.duplicate(true)

static func get_enemy_by_id(enemy_id: String) -> Dictionary:
	"""Obtener datos de un enemigo por su ID"""
	# Buscar en todos los tiers
	for dict in [TIER_1_ENEMIES, TIER_2_ENEMIES, TIER_3_ENEMIES, TIER_4_ENEMIES, BOSSES]:
		for key in dict:
			if dict[key].id == enemy_id or key == enemy_id:
				return dict[key].duplicate(true)
	return {}

static func get_enemies_for_tier(tier: int) -> Array:
	"""Obtener array de enemigos disponibles para un tier"""
	var enemies = []
	var source = {}
	
	match tier:
		1: source = TIER_1_ENEMIES
		2: source = TIER_2_ENEMIES
		3: source = TIER_3_ENEMIES
		4: source = TIER_4_ENEMIES
		5: source = BOSSES
	
	for key in source:
		enemies.append(source[key].duplicate(true))
	
	return enemies

static func get_random_enemy_for_tier(tier: int) -> Dictionary:
	"""Obtener un enemigo aleatorio del tier especificado"""
	var enemies = get_enemies_for_tier(tier)
	if enemies.is_empty():
		return {}
	return enemies[randi() % enemies.size()]

static func get_available_tiers_for_minute(minute: float) -> Array:
	"""Obtener los tiers disponibles según el minuto de juego"""
	var available = []
	for tier in TIER_SPAWN_TIMES:
		if minute >= TIER_SPAWN_TIMES[tier]:
			available.append(tier)
	return available

static func get_boss_for_minute(minute: int) -> Dictionary:
	"""Obtener un boss aleatorio con escalado según el minuto"""
	if minute % int(BOSS_SPAWN_INTERVAL) != 0 or minute == 0:
		return {}
	
	# Obtener boss aleatorio desde SpawnConfig
	var boss_id = SpawnConfig.get_boss_for_minute(minute)
	if boss_id.is_empty() or not BOSSES.has(boss_id):
		return {}
	
	var boss = BOSSES[boss_id].duplicate(true)
	
	# Aplicar escalado según el minuto de aparición
	var minute_scaling = SpawnConfig.get_boss_scaling_for_minute(minute)
	
	boss.base_hp = int(boss.base_hp * minute_scaling.hp_mult)
	boss.base_damage = int(boss.base_damage * minute_scaling.damage_mult)
	boss.base_xp = int(boss.base_xp * (1.0 + (minute - 5) * 0.25))  # XP escala también
	
	# Aplicar escalado a cooldowns (más rápido en minutos altos)
	if boss.has("ability_cooldowns"):
		var scaled_cooldowns = {}
		for ability in boss.ability_cooldowns:
			scaled_cooldowns[ability] = boss.ability_cooldowns[ability] * minute_scaling.cooldown_mult
		boss.ability_cooldowns = scaled_cooldowns
	
	# También escalar algunos modifiers de daño
	if boss.has("modifiers"):
		var mods = boss.modifiers
		for key in mods:
			if "damage" in key and typeof(mods[key]) in [TYPE_INT, TYPE_FLOAT]:
				mods[key] = mods[key] * minute_scaling.damage_mult
	
	# Marcar con info de escalado para debug
	boss["spawn_minute"] = minute
	boss["scaling_applied"] = minute_scaling
	
	print("[EnemyDatabase] 👹 Boss seleccionado: %s para minuto %d (HP: %d, DMG: %d)" % [
		boss.name, minute, boss.base_hp, boss.base_damage
	])
	
	return boss

static func get_exponential_scale(minute: float) -> float:
	"""Calcular el factor de escalado exponencial después del minuto 20"""
	if minute <= 20:
		return 1.0
	
	var periods_past_20 = (minute - 20.0) / 5.0
	return pow(EXPONENTIAL_SCALING_BASE, periods_past_20)

static func apply_difficulty_scaling(enemy_data: Dictionary, minute: float, difficulty_mult: float = 1.0) -> Dictionary:
	"""Aplicar escalado de dificultad a los stats del enemigo"""
	var scaled = enemy_data.duplicate(true)
	var tier = scaled.get("tier", 1)
	
	# Aplicar escalado base de tier
	var tier_scale = TIER_SCALING.get(tier, TIER_SCALING[1])
	
	# Aplicar escalado exponencial si pasó el minuto 20
	var exp_scale = get_exponential_scale(minute)
	
	# Calcular stats finales
	var hp_modifier = scaled.get("modifiers", {}).get("hp", 1.0)
	var damage_modifier = scaled.get("modifiers", {}).get("damage", 1.0)
	var speed_modifier = scaled.get("modifiers", {}).get("speed", 1.0)
	
	scaled["final_hp"] = int(scaled.base_hp * tier_scale.hp * hp_modifier * exp_scale * difficulty_mult)
	scaled["final_damage"] = int(scaled.base_damage * tier_scale.damage * damage_modifier * exp_scale * difficulty_mult)
	scaled["final_speed"] = scaled.base_speed * tier_scale.speed * speed_modifier
	scaled["final_xp"] = int(scaled.base_xp * tier_scale.xp * exp_scale)
	
	return scaled

static func create_elite_version(enemy_data: Dictionary) -> Dictionary:
	"""Crear versión élite/legendaria de un enemigo - MUY MEJORADA"""
	var elite = enemy_data.duplicate(true)
	
	elite["is_elite"] = true
	elite["name"] = "👑 " + elite.get("name", "Enemigo") + " Legendario"
	elite["base_hp"] = int(elite.base_hp * ELITE_CONFIG.hp_multiplier)
	elite["base_damage"] = int(elite.base_damage * ELITE_CONFIG.damage_multiplier)
	elite["base_speed"] = elite.base_speed * ELITE_CONFIG.speed_multiplier
	elite["base_xp"] = int(elite.base_xp * ELITE_CONFIG.xp_multiplier)
	elite["size_scale"] = ELITE_CONFIG.size_multiplier
	elite["aura_color"] = ELITE_CONFIG.aura_color
	elite["aura_pulse_speed"] = ELITE_CONFIG.get("aura_pulse_speed", 3.0)
	
	# Reducir cooldown de ataque (atacan más rápido)
	var attack_cd = elite.get("attack_cooldown", 1.5)
	elite["attack_cooldown"] = attack_cd * ELITE_CONFIG.get("attack_speed_multiplier", 0.7)
	
	# AÑADIR HABILIDADES ESPECIALES DE ÉLITE - SISTEMA MEJORADO
	var existing_abilities = elite.get("special_abilities", []).duplicate()
	var tier = elite.get("tier", 1)
	
	# Todos los élites tienen slam de área y dash
	if not "elite_slam" in existing_abilities:
		existing_abilities.append("elite_slam")
	if not "elite_dash" in existing_abilities:
		existing_abilities.append("elite_dash")
	
	# Élites de tier 2+ tienen rage y nova
	if tier >= 2:
		if not "elite_rage" in existing_abilities:
			existing_abilities.append("elite_rage")
		if not "elite_nova" in existing_abilities:
			existing_abilities.append("elite_nova")
	
	# Élites de tier 3+ tienen escudo y summon
	if tier >= 3:
		if not "elite_shield" in existing_abilities:
			existing_abilities.append("elite_shield")
		if not "elite_summon" in existing_abilities:
			existing_abilities.append("elite_summon")
	
	# Tier 4 tiene TODAS las habilidades + stats mejorados
	if tier >= 4:
		for ability in ELITE_CONFIG.extra_abilities:
			if not ability in existing_abilities:
				existing_abilities.append(ability)
	
	elite["special_abilities"] = existing_abilities
	
	# Añadir modifiers para TODAS las habilidades élite (escaladas por tier)
	var mods = elite.get("modifiers", {}).duplicate()
	var tier_bonus = 1.0 + (tier - 1) * 0.2  # +20% por tier
	
	# Slam - escala con tier
	mods["elite_slam_cooldown"] = ELITE_CONFIG.get("slam_cooldown", 4.0) / tier_bonus
	mods["elite_slam_radius"] = ELITE_CONFIG.get("slam_radius", 100.0) * tier_bonus
	mods["elite_slam_damage_mult"] = ELITE_CONFIG.get("slam_damage_mult", 2.0) * tier_bonus
	
	# Rage - umbrales y bonuses escalados
	mods["elite_rage_threshold"] = min(0.7, ELITE_CONFIG.get("rage_hp_threshold", 0.5) + (tier - 1) * 0.05)
	mods["elite_rage_damage_bonus"] = ELITE_CONFIG.get("rage_damage_bonus", 0.75) * tier_bonus
	mods["elite_rage_speed_bonus"] = ELITE_CONFIG.get("rage_speed_bonus", 0.5) * tier_bonus
	
	# Shield - más cargas por tier
	mods["elite_shield_charges"] = ELITE_CONFIG.get("shield_charges", 5) + (tier - 1) * 2
	mods["elite_shield_cooldown"] = ELITE_CONFIG.get("shield_cooldown", 12.0) / tier_bonus
	
	# Dash - nuevo
	mods["elite_dash_cooldown"] = ELITE_CONFIG.get("dash_cooldown", 3.0) / tier_bonus
	mods["elite_dash_speed"] = ELITE_CONFIG.get("dash_speed", 600.0) * tier_bonus
	mods["elite_dash_damage_mult"] = ELITE_CONFIG.get("dash_damage_mult", 1.8) * tier_bonus
	
	# Nova - nuevo
	mods["elite_nova_cooldown"] = ELITE_CONFIG.get("nova_cooldown", 6.0) / tier_bonus
	mods["elite_nova_projectile_count"] = ELITE_CONFIG.get("nova_projectile_count", 12) + (tier - 1) * 4
	mods["elite_nova_damage_mult"] = ELITE_CONFIG.get("nova_damage_mult", 0.8) * tier_bonus
	
	# Summon - nuevo
	mods["elite_summon_cooldown"] = ELITE_CONFIG.get("summon_cooldown", 10.0) / tier_bonus
	mods["elite_summon_count"] = ELITE_CONFIG.get("summon_count", 3) + (tier - 1)
	
	# Chance de usar habilidades
	mods["elite_ability_chance"] = ELITE_CONFIG.get("ability_use_chance", 0.50)
	
	elite["modifiers"] = mods
	
	return elite

static func should_spawn_elite(minute: float, elites_spawned: int) -> bool:
	"""Determinar si debería aparecer un élite"""
	if minute < ELITE_CONFIG.min_spawn_minute:
		return false
	if elites_spawned >= ELITE_CONFIG.max_per_run:
		return false
	
	# Chance aumenta con el tiempo
	var chance = ELITE_CONFIG.spawn_chance_per_minute * minute
	return randf() < chance

static func get_enemies_by_tier(tier: int) -> Array:
	"""Obtener array con los IDs de enemigos de un tier específico"""
	var ids = []
	var source = {}
	
	match tier:
		1: source = TIER_1_ENEMIES
		2: source = TIER_2_ENEMIES
		3: source = TIER_3_ENEMIES
		4: source = TIER_4_ENEMIES
		5: source = BOSSES
	
	for key in source:
		ids.append(key)
	
	return ids

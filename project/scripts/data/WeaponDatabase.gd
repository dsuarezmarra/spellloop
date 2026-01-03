# WeaponDatabase.gd
# Base de datos centralizada de todas las armas del juego
# Incluye: 10 armas base + matriz de fusiones + mejoras por nivel

extends Node
class_name WeaponDatabase

# ═══════════════════════════════════════════════════════════════════════════════
# CONSTANTES
# ═══════════════════════════════════════════════════════════════════════════════

const MAX_WEAPON_LEVEL: int = 8
const MAX_WEAPON_SLOTS: int = 6

# Elementos disponibles
enum Element {
	ICE,
	FIRE,
	LIGHTNING,
	ARCANE,
	SHADOW,
	NATURE,
	WIND,
	EARTH,
	LIGHT,
	VOID
}

# Tipos de targeting
enum TargetType {
	NEAREST,      # Enemigo más cercano
	RANDOM,       # Enemigo aleatorio en rango
	AREA,         # Área alrededor del player
	ORBIT,        # Orbita al player
	DIRECTION,    # Dirección del movimiento
	HOMING        # Persigue enemigos
}

# Tipos de proyectil
enum ProjectileType {
	SINGLE,       # Un proyectil
	MULTI,        # Múltiples proyectiles
	BEAM,         # Rayo instantáneo
	AOE,          # Área de efecto
	ORBIT,        # Orbitante
	CHAIN         # Encadena entre enemigos
}

# ═══════════════════════════════════════════════════════════════════════════════
# ARMAS BASE (10 armas)
# ═══════════════════════════════════════════════════════════════════════════════

const WEAPONS: Dictionary = {
	# ─────────────────────────────────────────────────────────────────────────────
	# ICE WAND - Ralentiza enemigos
	# ─────────────────────────────────────────────────────────────────────────────
	"ice_wand": {
		"id": "ice_wand",
		"name": "Ice Wand",
		"name_es": "Varita de Hielo",
		"description": "Dispara fragmentos de hielo que ralentizan enemigos",
		"element": Element.ICE,
		"rarity": "common",
		
		# Stats base
		"damage": 10,
		"cooldown": 1.4,
		"range": 350.0,
		"projectile_speed": 320.0,
		"projectile_count": 1,
		"pierce": 0,
		"area": 1.0,
		"duration": 0.0,
		"knockback": 80.0,
		
		# Comportamiento
		"target_type": TargetType.NEAREST,
		"projectile_type": ProjectileType.SINGLE,
		
		# Efecto especial
		"effect": "slow",
		"effect_value": 0.30,  # 30% slow
		"effect_duration": 2.0,
		
		# Visual
		"color": Color(0.4, 0.8, 1.0),
		"icon": "❄️"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# FIRE WAND - Quema enemigos (DoT)
	# ─────────────────────────────────────────────────────────────────────────────
	"fire_wand": {
		"id": "fire_wand",
		"name": "Fire Wand",
		"name_es": "Varita de Fuego",
		"description": "Lanza bolas de fuego que queman a los enemigos",
		"element": Element.FIRE,
		"rarity": "common",
		
		"damage": 12,
		"cooldown": 1.6,
		"range": 300.0,
		"projectile_speed": 280.0,
		"projectile_count": 1,
		"pierce": 0,
		"area": 1.2,
		"duration": 0.0,
		"knockback": 60.0,
		
		"target_type": TargetType.RANDOM,
		"projectile_type": ProjectileType.SINGLE,
		
		"effect": "burn",
		"effect_value": 3.0,  # 3 daño por tick
		"effect_duration": 4.0,
		
		"color": Color(1.0, 0.4, 0.1),
		"icon": "🔥"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# LIGHTNING WAND - Encadena rayos entre enemigos
	# ─────────────────────────────────────────────────────────────────────────────
	"lightning_wand": {
		"id": "lightning_wand",
		"name": "Lightning Wand",
		"name_es": "Varita de Rayo",
		"description": "Dispara rayos que saltan entre enemigos cercanos",
		"element": Element.LIGHTNING,
		"rarity": "uncommon",
		
		"damage": 15,
		"cooldown": 1.8,
		"range": 400.0,
		"projectile_speed": 600.0,  # Muy rápido (casi instantáneo)
		"projectile_count": 1,
		"pierce": 0,
		"area": 1.0,
		"duration": 0.0,
		"knockback": 40.0,
		
		"target_type": TargetType.NEAREST,
		"projectile_type": ProjectileType.CHAIN,
		
		"effect": "chain",
		"effect_value": 2,  # Salta a 2 enemigos adicionales
		"effect_duration": 0.0,
		
		"color": Color(1.0, 1.0, 0.3),
		"icon": "⚡"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ARCANE ORB - Orbes que orbitan al jugador
	# ─────────────────────────────────────────────────────────────────────────────
	"arcane_orb": {
		"id": "arcane_orb",
		"name": "Arcane Orb",
		"name_es": "Orbe Arcano",
		"description": "Invoca orbes mágicos que orbitan a tu alrededor",
		"element": Element.ARCANE,
		"rarity": "uncommon",
		
		"damage": 8,
		"cooldown": 0.0,  # Daño continuo
		"range": 120.0,   # Radio de órbita
		"projectile_speed": 200.0,  # Velocidad de rotación
		"projectile_count": 3,
		"pierce": 999,  # Infinito
		"area": 1.0,
		"duration": 999.0,  # Permanente
		"knockback": 20.0,
		
		"target_type": TargetType.ORBIT,
		"projectile_type": ProjectileType.ORBIT,
		
		"effect": "none",
		"effect_value": 0,
		"effect_duration": 0.0,
		
		"color": Color(0.7, 0.3, 1.0),
		"icon": "💜"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# SHADOW DAGGER - Dagas rápidas con pierce
	# ─────────────────────────────────────────────────────────────────────────────
	"shadow_dagger": {
		"id": "shadow_dagger",
		"name": "Shadow Dagger",
		"name_es": "Daga Sombría",
		"description": "Lanza dagas oscuras que atraviesan múltiples enemigos",
		"element": Element.SHADOW,
		"rarity": "common",
		
		"damage": 7,
		"cooldown": 0.9,  # Rápido pero balanceado
		"range": 450.0,
		"projectile_speed": 500.0,
		"projectile_count": 1,
		"pierce": 3,
		"area": 0.8,
		"duration": 0.0,
		"knockback": 30.0,
		
		"target_type": TargetType.DIRECTION,
		"projectile_type": ProjectileType.SINGLE,
		
		"effect": "none",
		"effect_value": 0,
		"effect_duration": 0.0,
		
		"color": Color(0.3, 0.1, 0.4),
		"icon": "🗡️"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# NATURE STAFF - Proyectiles homing que curan
	# ─────────────────────────────────────────────────────────────────────────────
	"nature_staff": {
		"id": "nature_staff",
		"name": "Nature Staff",
		"name_es": "Bastón Natural",
		"description": "Dispara hojas mágicas que persiguen enemigos y te curan al matar",
		"element": Element.NATURE,
		"rarity": "uncommon",
		
		"damage": 9,
		"cooldown": 1.0,
		"range": 500.0,
		"projectile_speed": 250.0,
		"projectile_count": 2,
		"pierce": 0,
		"area": 1.0,
		"duration": 3.0,  # Tiempo de vida del proyectil homing
		"knockback": 50.0,
		
		"target_type": TargetType.HOMING,
		"projectile_type": ProjectileType.MULTI,
		
		"effect": "lifesteal",
		"effect_value": 1,  # 1 HP por kill
		"effect_duration": 0.0,
		
		"color": Color(0.3, 0.8, 0.2),
		"icon": "🌿"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# WIND BLADE - Cortes de viento en abanico
	# ─────────────────────────────────────────────────────────────────────────────
	"wind_blade": {
		"id": "wind_blade",
		"name": "Wind Blade",
		"name_es": "Hoja de Viento",
		"description": "Lanza cuchillas de viento en abanico",
		"element": Element.WIND,
		"rarity": "common",
		
		"damage": 6,
		"cooldown": 1.2,
		"range": 380.0,
		"projectile_speed": 450.0,
		"projectile_count": 3,  # 3 cuchillas en abanico
		"pierce": 1,
		"area": 1.0,
		"duration": 0.0,
		"knockback": 100.0,  # Alto knockback
		
		"target_type": TargetType.DIRECTION,
		"projectile_type": ProjectileType.MULTI,
		
		"effect": "knockback_bonus",
		"effect_value": 1.5,  # 50% más knockback
		"effect_duration": 0.0,
		
		"color": Color(0.8, 0.95, 0.9),
		"icon": "🌪️"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# EARTH SPIKE - Área de efecto en el suelo
	# ─────────────────────────────────────────────────────────────────────────────
	"earth_spike": {
		"id": "earth_spike",
		"name": "Earth Spike",
		"name_es": "Pico de Tierra",
		"description": "Invoca picos de tierra que emergen bajo los enemigos",
		"element": Element.EARTH,
		"rarity": "uncommon",
		
		"damage": 20,
		"cooldown": 1.8,
		"range": 250.0,
		"projectile_speed": 0.0,  # Instantáneo en posición
		"projectile_count": 1,
		"pierce": 999,  # Daña a todos en área
		"area": 1.5,
		"duration": 0.5,
		"knockback": 150.0,
		
		"target_type": TargetType.RANDOM,
		"projectile_type": ProjectileType.AOE,
		
		"effect": "stun",
		"effect_value": 0.5,  # 0.5 segundos de stun
		"effect_duration": 0.5,
		
		"color": Color(0.6, 0.4, 0.2),
		"icon": "🪨"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# LIGHT BEAM - Rayo de luz instantáneo
	# ─────────────────────────────────────────────────────────────────────────────
	"light_beam": {
		"id": "light_beam",
		"name": "Light Beam",
		"name_es": "Rayo de Luz",
		"description": "Dispara un rayo de luz pura que atraviesa todo",
		"element": Element.LIGHT,
		"rarity": "rare",
		
		"damage": 25,
		"cooldown": 2.0,
		"range": 600.0,
		"projectile_speed": 999.0,  # Instantáneo
		"projectile_count": 1,
		"pierce": 999,
		"area": 0.5,  # Delgado
		"duration": 0.3,
		"knockback": 0.0,
		
		"target_type": TargetType.NEAREST,
		"projectile_type": ProjectileType.BEAM,
		
		"effect": "crit_chance",
		"effect_value": 0.2,  # 20% probabilidad de crítico
		"effect_duration": 0.0,
		
		"color": Color(1.0, 1.0, 0.9),
		"icon": "✨"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# VOID PULSE - Explosión de vacío que atrae enemigos
	# ─────────────────────────────────────────────────────────────────────────────
	"void_pulse": {
		"id": "void_pulse",
		"name": "Void Pulse",
		"name_es": "Pulso del Vacío",
		"description": "Crea un pulso de vacío que atrae y daña enemigos cercanos",
		"element": Element.VOID,
		"rarity": "rare",
		
		"damage": 18,
		"cooldown": 2.5,
		"range": 200.0,
		"projectile_speed": 0.0,
		"projectile_count": 1,
		"pierce": 999,
		"area": 2.0,
		"duration": 1.0,
		"knockback": -200.0,  # Negativo = atrae
		
		"target_type": TargetType.AREA,
		"projectile_type": ProjectileType.AOE,
		
		"effect": "pull",
		"effect_value": 150.0,  # Fuerza de atracción
		"effect_duration": 1.0,
		
		"color": Color(0.2, 0.0, 0.3),
		"icon": "🕳️"
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# MEJORAS POR NIVEL (aplicables a todas las armas)
# ═══════════════════════════════════════════════════════════════════════════════

const LEVEL_UPGRADES: Dictionary = {
	2: {"damage_mult": 1.2, "description": "+20% Daño"},
	3: {"cooldown_mult": 0.85, "description": "-15% Cooldown"},
	4: {"projectile_count_add": 1, "description": "+1 Proyectil"},
	5: {"effect_mult": 1.5, "description": "+50% Efecto especial"},
	6: {"damage_mult": 1.25, "description": "+25% Daño"},
	7: {"pierce_add": 2, "description": "+2 Pierce"},
	8: {"all_mult": 1.3, "description": "¡MÁXIMO! +30% a todo"}
}

# ═══════════════════════════════════════════════════════════════════════════════
# MATRIZ DE FUSIONES
# Cada fusión combina 2 armas en 1 más poderosa
# El jugador PIERDE 1 slot permanentemente al fusionar
# ═══════════════════════════════════════════════════════════════════════════════

const FUSIONS: Dictionary = {
	# ─────────────────────────────────────────────────────────────────────────────
	# STEAM CANNON (Ice + Fire) - Vapor explosivo
	# ─────────────────────────────────────────────────────────────────────────────
	"ice_wand+fire_wand": {
		"id": "steam_cannon",
		"name": "Steam Cannon",
		"name_es": "Cañón de Vapor",
		"description": "La fusión de hielo y fuego crea explosiones de vapor devastadoras",
		"components": ["ice_wand", "fire_wand"],
		
		# Stats combinados y mejorados
		"damage": 25,  # Mayor que ambos
		"cooldown": 0.8,
		"range": 350.0,
		"projectile_speed": 300.0,
		"projectile_count": 1,
		"pierce": 0,
		"area": 2.0,  # Explosión grande
		"duration": 0.0,
		"knockback": 120.0,
		
		"target_type": TargetType.NEAREST,
		"projectile_type": ProjectileType.AOE,
		
		# Combina efectos: slow + burn
		"effect": "steam",  # Slow + DoT
		"effect_value": 5.0,
		"effect_duration": 3.0,
		
		"color": Color(0.8, 0.8, 0.9),
		"icon": "💨"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# STORM CALLER (Lightning + Wind) - Tormenta eléctrica
	# ─────────────────────────────────────────────────────────────────────────────
	"lightning_wand+wind_blade": {
		"id": "storm_caller",
		"name": "Storm Caller",
		"name_es": "Invocador de Tormentas",
		"description": "Invoca una tormenta que lanza rayos en todas direcciones",
		"components": ["lightning_wand", "wind_blade"],
		
		"damage": 18,
		"cooldown": 1.0,
		"range": 400.0,
		"projectile_speed": 600.0,
		"projectile_count": 5,  # Múltiples rayos
		"pierce": 0,
		"area": 1.2,
		"duration": 0.0,
		"knockback": 80.0,
		
		"target_type": TargetType.AREA,
		"projectile_type": ProjectileType.CHAIN,
		
		"effect": "chain",
		"effect_value": 2,  # 2 saltos (nerfed from 3)
		"effect_duration": 0.0,
		
		"color": Color(0.9, 1.0, 0.5),
		"icon": "⛈️"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# SOUL REAPER (Shadow + Nature) - Drena vida masivamente
	# ─────────────────────────────────────────────────────────────────────────────
	"shadow_dagger+nature_staff": {
		"id": "soul_reaper",
		"name": "Soul Reaper",
		"name_es": "Segador de Almas",
		"description": "Dagas espectrales que drenan la esencia vital de los enemigos",
		"components": ["shadow_dagger", "nature_staff"],
		
		"damage": 12,
		"cooldown": 0.5,
		"range": 450.0,
		"projectile_speed": 400.0,
		"projectile_count": 3,
		"pierce": 5,
		"area": 1.0,
		"duration": 2.5,
		"knockback": 40.0,
		
		"target_type": TargetType.HOMING,
		"projectile_type": ProjectileType.MULTI,
		
		"effect": "lifesteal",
		"effect_value": 2,  # 2 HP por kill (nerfed from 3)
		"effect_duration": 0.0,
		
		"color": Color(0.4, 0.2, 0.5),
		"icon": "💀"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# COSMIC BARRIER (Arcane + Light) - Escudo orbital brillante
	# ─────────────────────────────────────────────────────────────────────────────
	"arcane_orb+light_beam": {
		"id": "cosmic_barrier",
		"name": "Cosmic Barrier",
		"name_es": "Barrera Cósmica",
		"description": "Orbes de luz pura que protegen y dañan",
		"components": ["arcane_orb", "light_beam"],
		
		"damage": 20,
		"cooldown": 0.0,
		"range": 150.0,
		"projectile_speed": 250.0,
		"projectile_count": 5,
		"pierce": 999,
		"area": 1.5,
		"duration": 999.0,
		"knockback": 60.0,
		
		"target_type": TargetType.ORBIT,
		"projectile_type": ProjectileType.ORBIT,
		
		"effect": "crit_chance",
		"effect_value": 0.25,
		"effect_duration": 0.0,
		
		"color": Color(0.9, 0.8, 1.0),
		"icon": "🌟"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# RIFT QUAKE (Earth + Void) - Grietas sísmicas del vacío
	# ─────────────────────────────────────────────────────────────────────────────
	"earth_spike+void_pulse": {
		"id": "rift_quake",
		"name": "Rift Quake",
		"name_es": "Grieta Sísmica",
		"description": "Abre grietas en la tierra que absorben enemigos al vacío",
		"components": ["earth_spike", "void_pulse"],
		
		"damage": 40,
		"cooldown": 2.5,  # Buffed from 3.0
		"range": 300.0,
		"projectile_speed": 0.0,
		"projectile_count": 1,
		"pierce": 999,
		"area": 3.0,
		"duration": 1.5,
		"knockback": 200.0,
		
		"target_type": TargetType.AREA,
		"projectile_type": ProjectileType.AOE,
		
		"effect": "stun",
		"effect_value": 1.0,
		"effect_duration": 1.0,
		
		"color": Color(0.4, 0.2, 0.1),
		"icon": "🌋"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# FROSTVINE (Ice + Nature) - Enredaderas de hielo viviente
	# ─────────────────────────────────────────────────────────────────────────────
	"ice_wand+nature_staff": {
		"id": "frostvine",
		"name": "Frostvine",
		"name_es": "Enredadera de Hielo",
		"description": "Proyectiles de hielo vivo que congelan y persiguen como enredaderas",
		"components": ["ice_wand", "nature_staff"],
		
		"damage": 14,
		"cooldown": 0.8,
		"range": 450.0,
		"projectile_speed": 280.0,
		"projectile_count": 3,
		"pierce": 1,
		"area": 1.2,
		"duration": 3.0,
		"knockback": 70.0,
		
		"target_type": TargetType.HOMING,
		"projectile_type": ProjectileType.MULTI,
		
		"effect": "freeze",  # Congelación temporal
		"effect_value": 0.8,  # 80% slow (casi congelado)
		"effect_duration": 2.5,
		
		"color": Color(0.5, 0.9, 0.7),
		"icon": "🥶"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# HELLFIRE (Fire + Shadow) - Fuego oscuro devastador
	# ─────────────────────────────────────────────────────────────────────────────
	"fire_wand+shadow_dagger": {
		"id": "hellfire",
		"name": "Hellfire",
		"name_es": "Fuego Infernal",
		"description": "Llamas oscuras que queman el alma de los enemigos",
		"components": ["fire_wand", "shadow_dagger"],
		
		"damage": 15,
		"cooldown": 0.6,
		"range": 400.0,
		"projectile_speed": 420.0,
		"projectile_count": 2,
		"pierce": 4,
		"area": 1.0,
		"duration": 0.0,
		"knockback": 50.0,
		
		"target_type": TargetType.DIRECTION,
		"projectile_type": ProjectileType.MULTI,
		
		"effect": "burn",
		"effect_value": 6.0,  # Burn más potente
		"effect_duration": 5.0,
		
		"color": Color(0.8, 0.2, 0.3),
		"icon": "👹"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# THUNDER SPEAR (Lightning + Light) - Lanza divina
	# ─────────────────────────────────────────────────────────────────────────────
	"lightning_wand+light_beam": {
		"id": "thunder_spear",
		"name": "Thunder Spear",
		"name_es": "Lanza del Trueno",
		"description": "Un rayo divino que aniquila todo en su camino",
		"components": ["lightning_wand", "light_beam"],
		
		"damage": 45,
		"cooldown": 2.2,
		"range": 700.0,
		"projectile_speed": 999.0,
		"projectile_count": 1,
		"pierce": 999,
		"area": 0.8,
		"duration": 0.4,
		"knockback": 100.0,
		
		"target_type": TargetType.NEAREST,
		"projectile_type": ProjectileType.BEAM,
		
		"effect": "crit_chance",
		"effect_value": 0.35,  # 35% crit
		"effect_duration": 0.0,
		
		"color": Color(1.0, 0.95, 0.6),
		"icon": "🔱"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# VOID STORM (Void + Wind) - Tornado de vacío
	# ─────────────────────────────────────────────────────────────────────────────
	"void_pulse+wind_blade": {
		"id": "void_storm",
		"name": "Void Storm",
		"name_es": "Tormenta del Vacío",
		"description": "Un tornado de vacío que succiona y destruye enemigos",
		"components": ["void_pulse", "wind_blade"],
		
		"damage": 22,
		"cooldown": 1.8,
		"range": 280.0,
		"projectile_speed": 150.0,
		"projectile_count": 1,
		"pierce": 999,
		"area": 2.5,
		"duration": 2.0,
		"knockback": -250.0,  # Atrae fuertemente
		
		"target_type": TargetType.AREA,
		"projectile_type": ProjectileType.AOE,
		
		"effect": "pull",
		"effect_value": 200.0,
		"effect_duration": 2.0,
		
		"color": Color(0.3, 0.1, 0.4),
		"icon": "🌀"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# CRYSTAL GUARDIAN (Earth + Arcane) - Cristales orbitantes
	# ─────────────────────────────────────────────────────────────────────────────
	"earth_spike+arcane_orb": {
		"id": "crystal_guardian",
		"name": "Crystal Guardian",
		"name_es": "Guardián de Cristal",
		"description": "Cristales mágicos que orbitan y explotan al contacto",
		"components": ["earth_spike", "arcane_orb"],
		
		"damage": 16,
		"cooldown": 0.0,
		"range": 140.0,
		"projectile_speed": 180.0,
		"projectile_count": 4,
		"pierce": 3,
		"area": 1.3,
		"duration": 999.0,
		"knockback": 90.0,
		
		"target_type": TargetType.ORBIT,
		"projectile_type": ProjectileType.ORBIT,
		
		"effect": "stun",
		"effect_value": 0.3,
		"effect_duration": 0.3,
		
		"color": Color(0.6, 0.5, 0.8),
		"icon": "💎"
	},
	
	# ═══════════════════════════════════════════════════════════════════════════
	# FUSIONES ADICIONALES (35 combinaciones más para completar 45 total)
	# ═══════════════════════════════════════════════════════════════════════════
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ICE + LIGHTNING: FROZEN THUNDER - Hielo electrificado
	# ─────────────────────────────────────────────────────────────────────────────
	"ice_wand+lightning_wand": {
		"id": "frozen_thunder",
		"name": "Frozen Thunder",
		"name_es": "Trueno Congelado",
		"description": "Rayos que congelan al impactar y saltan entre enemigos",
		"components": ["ice_wand", "lightning_wand"],
		"damage": 18,
		"cooldown": 1.0,
		"range": 400.0,
		"projectile_speed": 550.0,
		"projectile_count": 1,
		"pierce": 0,
		"area": 1.1,
		"duration": 0.0,
		"knockback": 60.0,
		"target_type": TargetType.NEAREST,
		"projectile_type": ProjectileType.CHAIN,
		"effect": "freeze_chain",
		"effect_value": 0.5,
		"effect_duration": 1.5,
		"color": Color(0.6, 0.9, 1.0),
		"icon": "🧊⚡"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ICE + ARCANE: FROST ORB - Orbes de hielo orbitantes
	# ─────────────────────────────────────────────────────────────────────────────
	"ice_wand+arcane_orb": {
		"id": "frost_orb",
		"name": "Frost Orb",
		"name_es": "Orbe de Escarcha",
		"description": "Orbes de hielo que orbitan y ralentizan enemigos cercanos",
		"components": ["ice_wand", "arcane_orb"],
		"damage": 10,
		"cooldown": 0.0,
		"range": 130.0,
		"projectile_speed": 190.0,
		"projectile_count": 4,
		"pierce": 999,
		"area": 1.2,
		"duration": 999.0,
		"knockback": 30.0,
		"target_type": TargetType.ORBIT,
		"projectile_type": ProjectileType.ORBIT,
		"effect": "slow",
		"effect_value": 0.4,
		"effect_duration": 2.0,
		"color": Color(0.5, 0.8, 1.0),
		"icon": "🔮❄️"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ICE + SHADOW: FROSTBITE - Dagas de hielo oscuro
	# ─────────────────────────────────────────────────────────────────────────────
	"ice_wand+shadow_dagger": {
		"id": "frostbite",
		"name": "Frostbite",
		"name_es": "Mordedura Gélida",
		"description": "Dagas de hielo negro que congelan y atraviesan enemigos",
		"components": ["ice_wand", "shadow_dagger"],
		"damage": 11,
		"cooldown": 0.5,
		"range": 420.0,
		"projectile_speed": 480.0,
		"projectile_count": 2,
		"pierce": 4,
		"area": 0.9,
		"duration": 0.0,
		"knockback": 50.0,
		"target_type": TargetType.DIRECTION,
		"projectile_type": ProjectileType.MULTI,
		"effect": "slow",
		"effect_value": 0.45,
		"effect_duration": 2.5,
		"color": Color(0.2, 0.4, 0.6),
		"icon": "🗡️❄️"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ICE + WIND: BLIZZARD - Tormenta de nieve
	# ─────────────────────────────────────────────────────────────────────────────
	"ice_wand+wind_blade": {
		"id": "blizzard",
		"name": "Blizzard",
		"name_es": "Ventisca",
		"description": "Una tormenta de nieve que ralentiza y daña en área",
		"components": ["ice_wand", "wind_blade"],
		"damage": 8,
		"cooldown": 0.6,
		"range": 350.0,
		"projectile_speed": 400.0,
		"projectile_count": 5,
		"pierce": 2,
		"area": 1.5,
		"duration": 0.0,
		"knockback": 90.0,
		"target_type": TargetType.DIRECTION,
		"projectile_type": ProjectileType.MULTI,
		"effect": "slow",
		"effect_value": 0.35,
		"effect_duration": 2.0,
		"color": Color(0.8, 0.9, 1.0),
		"icon": "🌨️"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ICE + EARTH: GLACIER - Picos de hielo
	# ─────────────────────────────────────────────────────────────────────────────
	"ice_wand+earth_spike": {
		"id": "glacier",
		"name": "Glacier",
		"name_es": "Glaciar",
		"description": "Invoca picos de hielo que congelan y dañan en área",
		"components": ["ice_wand", "earth_spike"],
		"damage": 22,
		"cooldown": 1.6,
		"range": 250.0,
		"projectile_speed": 0.0,
		"projectile_count": 1,
		"pierce": 999,
		"area": 1.8,
		"duration": 0.6,
		"knockback": 130.0,
		"target_type": TargetType.RANDOM,
		"projectile_type": ProjectileType.AOE,
		"effect": "freeze",
		"effect_value": 0.7,
		"effect_duration": 1.5,
		"color": Color(0.6, 0.85, 0.95),
		"icon": "🏔️"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ICE + LIGHT: AURORA - Rayo de luz helada
	# ─────────────────────────────────────────────────────────────────────────────
	"ice_wand+light_beam": {
		"id": "aurora",
		"name": "Aurora",
		"name_es": "Aurora Boreal",
		"description": "Un rayo de luz fría que congela todo en su camino",
		"components": ["ice_wand", "light_beam"],
		"damage": 28,
		"cooldown": 1.8,
		"range": 550.0,
		"projectile_speed": 999.0,
		"projectile_count": 1,
		"pierce": 999,
		"area": 0.7,
		"duration": 0.35,
		"knockback": 40.0,
		"target_type": TargetType.NEAREST,
		"projectile_type": ProjectileType.BEAM,
		"effect": "freeze",
		"effect_value": 0.6,
		"effect_duration": 2.0,
		"color": Color(0.7, 0.95, 0.9),
		"icon": "🌌"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ICE + VOID: ABSOLUTE ZERO - Vacío congelante
	# ─────────────────────────────────────────────────────────────────────────────
	"ice_wand+void_pulse": {
		"id": "absolute_zero",
		"name": "Absolute Zero",
		"name_es": "Cero Absoluto",
		"description": "Un pulso de frío absoluto que congela el espacio-tiempo",
		"components": ["ice_wand", "void_pulse"],
		"damage": 20,
		"cooldown": 2.2,
		"range": 220.0,
		"projectile_speed": 0.0,
		"projectile_count": 1,
		"pierce": 999,
		"area": 2.2,
		"duration": 1.2,
		"knockback": -150.0,
		"target_type": TargetType.AREA,
		"projectile_type": ProjectileType.AOE,
		"effect": "freeze",
		"effect_value": 0.9,
		"effect_duration": 3.0,
		"color": Color(0.3, 0.5, 0.7),
		"icon": "🕳️❄️"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# FIRE + LIGHTNING: PLASMA - Bola de plasma
	# ─────────────────────────────────────────────────────────────────────────────
	"fire_wand+lightning_wand": {
		"id": "plasma",
		"name": "Plasma Bolt",
		"name_es": "Rayo de Plasma",
		"description": "Proyectiles de plasma súper caliente que explotan y encadenan",
		"components": ["fire_wand", "lightning_wand"],
		"damage": 22,
		"cooldown": 1.2,
		"range": 380.0,
		"projectile_speed": 450.0,
		"projectile_count": 1,
		"pierce": 0,
		"area": 1.4,
		"duration": 0.0,
		"knockback": 70.0,
		"target_type": TargetType.NEAREST,
		"projectile_type": ProjectileType.CHAIN,
		"effect": "burn_chain",
		"effect_value": 4.0,
		"effect_duration": 3.0,
		"color": Color(1.0, 0.6, 0.8),
		"icon": "⚡🔥"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# FIRE + ARCANE: INFERNO ORB - Orbes de fuego mágico
	# ─────────────────────────────────────────────────────────────────────────────
	"fire_wand+arcane_orb": {
		"id": "inferno_orb",
		"name": "Inferno Orb",
		"name_es": "Orbe Infernal",
		"description": "Orbes de fuego mágico que orbitan dejando rastros de llamas",
		"components": ["fire_wand", "arcane_orb"],
		"damage": 12,
		"cooldown": 0.0,
		"range": 125.0,
		"projectile_speed": 210.0,
		"projectile_count": 4,
		"pierce": 999,
		"area": 1.3,
		"duration": 999.0,
		"knockback": 25.0,
		"target_type": TargetType.ORBIT,
		"projectile_type": ProjectileType.ORBIT,
		"effect": "burn",
		"effect_value": 4.0,
		"effect_duration": 3.0,
		"color": Color(1.0, 0.5, 0.2),
		"icon": "🔮🔥"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# FIRE + NATURE: WILDFIRE - Fuego natural propagante
	# ─────────────────────────────────────────────────────────────────────────────
	"fire_wand+nature_staff": {
		"id": "wildfire",
		"name": "Wildfire",
		"name_es": "Fuego Salvaje",
		"description": "Llamas vivientes que persiguen y se propagan entre enemigos",
		"components": ["fire_wand", "nature_staff"],
		"damage": 13,
		"cooldown": 0.9,
		"range": 480.0,
		"projectile_speed": 260.0,
		"projectile_count": 3,
		"pierce": 1,
		"area": 1.1,
		"duration": 2.8,
		"knockback": 55.0,
		"target_type": TargetType.HOMING,
		"projectile_type": ProjectileType.MULTI,
		"effect": "burn",
		"effect_value": 5.0,
		"effect_duration": 4.5,
		"color": Color(0.9, 0.6, 0.2),
		"icon": "🌿🔥"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# FIRE + WIND: FIRESTORM - Tornado de fuego
	# ─────────────────────────────────────────────────────────────────────────────
	"fire_wand+wind_blade": {
		"id": "firestorm",
		"name": "Firestorm",
		"name_es": "Tormenta de Fuego",
		"description": "Un tornado de llamas que arrasa con todo",
		"components": ["fire_wand", "wind_blade"],
		"damage": 10,
		"cooldown": 0.65,
		"range": 360.0,
		"projectile_speed": 420.0,
		"projectile_count": 4,
		"pierce": 2,
		"area": 1.3,
		"duration": 0.0,
		"knockback": 110.0,
		"target_type": TargetType.DIRECTION,
		"projectile_type": ProjectileType.MULTI,
		"effect": "burn",
		"effect_value": 3.5,
		"effect_duration": 3.0,
		"color": Color(1.0, 0.4, 0.0),
		"icon": "🌪️🔥"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# FIRE + EARTH: VOLCANO - Erupción volcánica
	# ─────────────────────────────────────────────────────────────────────────────
	"fire_wand+earth_spike": {
		"id": "volcano",
		"name": "Volcano",
		"name_es": "Volcán",
		"description": "Invoca una erupción volcánica bajo los enemigos",
		"components": ["fire_wand", "earth_spike"],
		"damage": 30,
		"cooldown": 2.0,
		"range": 260.0,
		"projectile_speed": 0.0,
		"projectile_count": 1,
		"pierce": 999,
		"area": 2.0,
		"duration": 0.8,
		"knockback": 180.0,
		"target_type": TargetType.RANDOM,
		"projectile_type": ProjectileType.AOE,
		"effect": "burn",
		"effect_value": 6.0,
		"effect_duration": 4.0,
		"color": Color(0.9, 0.3, 0.1),
		"icon": "🌋"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# FIRE + LIGHT: SOLAR FLARE - Llamarada solar
	# ─────────────────────────────────────────────────────────────────────────────
	"fire_wand+light_beam": {
		"id": "solar_flare",
		"name": "Solar Flare",
		"name_es": "Llamarada Solar",
		"description": "Un rayo de fuego solar que incinera todo",
		"components": ["fire_wand", "light_beam"],
		"damage": 35,
		"cooldown": 1.9,
		"range": 580.0,
		"projectile_speed": 999.0,
		"projectile_count": 1,
		"pierce": 999,
		"area": 0.8,
		"duration": 0.4,
		"knockback": 50.0,
		"target_type": TargetType.NEAREST,
		"projectile_type": ProjectileType.BEAM,
		"effect": "burn",
		"effect_value": 8.0,
		"effect_duration": 3.0,
		"color": Color(1.0, 0.9, 0.4),
		"icon": "☀️"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# FIRE + VOID: DARK FLAME - Llama del vacío
	# ─────────────────────────────────────────────────────────────────────────────
	"fire_wand+void_pulse": {
		"id": "dark_flame",
		"name": "Dark Flame",
		"name_es": "Llama Oscura",
		"description": "Fuego del vacío que atrae y consume enemigos",
		"components": ["fire_wand", "void_pulse"],
		"damage": 24,
		"cooldown": 2.3,
		"range": 210.0,
		"projectile_speed": 0.0,
		"projectile_count": 1,
		"pierce": 999,
		"area": 2.3,
		"duration": 1.3,
		"knockback": -180.0,
		"target_type": TargetType.AREA,
		"projectile_type": ProjectileType.AOE,
		"effect": "burn",
		"effect_value": 7.0,
		"effect_duration": 5.0,
		"color": Color(0.4, 0.1, 0.2),
		"icon": "🕳️🔥"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# LIGHTNING + ARCANE: ARCANE STORM - Tormenta arcana
	# ─────────────────────────────────────────────────────────────────────────────
	"lightning_wand+arcane_orb": {
		"id": "arcane_storm",
		"name": "Arcane Storm",
		"name_es": "Tormenta Arcana",
		"description": "Orbes que disparan rayos a enemigos cercanos",
		"components": ["lightning_wand", "arcane_orb"],
		"damage": 14,
		"cooldown": 0.0,
		"range": 160.0,
		"projectile_speed": 200.0,
		"projectile_count": 4,
		"pierce": 0,
		"area": 1.0,
		"duration": 999.0,
		"knockback": 35.0,
		"target_type": TargetType.ORBIT,
		"projectile_type": ProjectileType.ORBIT,
		"effect": "chain",
		"effect_value": 1,
		"effect_duration": 0.0,
		"color": Color(0.8, 0.5, 1.0),
		"icon": "🔮⚡"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# LIGHTNING + SHADOW: DARK LIGHTNING - Rayo oscuro
	# ─────────────────────────────────────────────────────────────────────────────
	"lightning_wand+shadow_dagger": {
		"id": "dark_lightning",
		"name": "Dark Lightning",
		"name_es": "Rayo Oscuro",
		"description": "Dagas eléctricas que encadenan y atraviesan enemigos",
		"components": ["lightning_wand", "shadow_dagger"],
		"damage": 14,
		"cooldown": 0.5,
		"range": 430.0,
		"projectile_speed": 550.0,
		"projectile_count": 2,
		"pierce": 3,
		"area": 0.9,
		"duration": 0.0,
		"knockback": 45.0,
		"target_type": TargetType.DIRECTION,
		"projectile_type": ProjectileType.MULTI,
		"effect": "chain",
		"effect_value": 2,
		"effect_duration": 0.0,
		"color": Color(0.4, 0.2, 0.6),
		"icon": "🗡️⚡"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# LIGHTNING + NATURE: THUNDER BLOOM - Rayo natural
	# ─────────────────────────────────────────────────────────────────────────────
	"lightning_wand+nature_staff": {
		"id": "thunder_bloom",
		"name": "Thunder Bloom",
		"name_es": "Flor del Trueno",
		"description": "Rayos vivientes que persiguen y curan al matar",
		"components": ["lightning_wand", "nature_staff"],
		"damage": 16,
		"cooldown": 1.1,
		"range": 480.0,
		"projectile_speed": 300.0,
		"projectile_count": 2,
		"pierce": 0,
		"area": 1.0,
		"duration": 2.5,
		"knockback": 50.0,
		"target_type": TargetType.HOMING,
		"projectile_type": ProjectileType.MULTI,
		"effect": "lifesteal_chain",
		"effect_value": 2,
		"effect_duration": 0.0,
		"color": Color(0.6, 1.0, 0.4),
		"icon": "🌿⚡"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# LIGHTNING + EARTH: SEISMIC BOLT - Rayo sísmico
	# ─────────────────────────────────────────────────────────────────────────────
	"lightning_wand+earth_spike": {
		"id": "seismic_bolt",
		"name": "Seismic Bolt",
		"name_es": "Rayo Sísmico",
		"description": "Rayos que crean ondas sísmicas al impactar",
		"components": ["lightning_wand", "earth_spike"],
		"damage": 28,
		"cooldown": 1.7,
		"range": 350.0,
		"projectile_speed": 600.0,
		"projectile_count": 1,
		"pierce": 0,
		"area": 1.8,
		"duration": 0.5,
		"knockback": 160.0,
		"target_type": TargetType.NEAREST,
		"projectile_type": ProjectileType.AOE,
		"effect": "stun",
		"effect_value": 0.6,
		"effect_duration": 0.6,
		"color": Color(0.7, 0.6, 0.3),
		"icon": "🪨⚡"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# LIGHTNING + VOID: VOID BOLT - Rayo del vacío
	# ─────────────────────────────────────────────────────────────────────────────
	"lightning_wand+void_pulse": {
		"id": "void_bolt",
		"name": "Void Bolt",
		"name_es": "Rayo del Vacío",
		"description": "Rayos que abren portales que atraen enemigos",
		"components": ["lightning_wand", "void_pulse"],
		"damage": 26,
		"cooldown": 2.0,
		"range": 380.0,
		"projectile_speed": 650.0,
		"projectile_count": 1,
		"pierce": 999,
		"area": 1.5,
		"duration": 0.0,
		"knockback": -120.0,
		"target_type": TargetType.NEAREST,
		"projectile_type": ProjectileType.CHAIN,
		"effect": "pull",
		"effect_value": 100.0,
		"effect_duration": 0.8,
		"color": Color(0.3, 0.1, 0.5),
		"icon": "🕳️⚡"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ARCANE + SHADOW: SHADOW ORBS - Orbes de sombra
	# ─────────────────────────────────────────────────────────────────────────────
	"arcane_orb+shadow_dagger": {
		"id": "shadow_orbs",
		"name": "Shadow Orbs",
		"name_es": "Orbes de Sombra",
		"description": "Orbes oscuros que disparan dagas fantasmales",
		"components": ["arcane_orb", "shadow_dagger"],
		"damage": 10,
		"cooldown": 0.0,
		"range": 135.0,
		"projectile_speed": 220.0,
		"projectile_count": 5,
		"pierce": 2,
		"area": 1.0,
		"duration": 999.0,
		"knockback": 35.0,
		"target_type": TargetType.ORBIT,
		"projectile_type": ProjectileType.ORBIT,
		"effect": "shadow_mark",  # Marked enemies take 25% extra damage
		"effect_value": 0.25,
		"effect_duration": 3.0,
		"color": Color(0.4, 0.2, 0.5),
		"icon": "🔮🗡️"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ARCANE + NATURE: LIFE ORBS - Orbes de vida
	# ─────────────────────────────────────────────────────────────────────────────
	"arcane_orb+nature_staff": {
		"id": "life_orbs",
		"name": "Life Orbs",
		"name_es": "Orbes de Vida",
		"description": "Orbes vivientes que curan mientras dañan",
		"components": ["arcane_orb", "nature_staff"],
		"damage": 9,
		"cooldown": 0.0,
		"range": 140.0,
		"projectile_speed": 200.0,
		"projectile_count": 4,
		"pierce": 999,
		"area": 1.1,
		"duration": 999.0,
		"knockback": 30.0,
		"target_type": TargetType.ORBIT,
		"projectile_type": ProjectileType.ORBIT,
		"effect": "lifesteal",
		"effect_value": 3,  # Buffed from 2
		"effect_duration": 0.0,
		"color": Color(0.5, 0.9, 0.6),
		"icon": "🔮🌿"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ARCANE + WIND: WIND ORBS - Orbes de viento
	# ─────────────────────────────────────────────────────────────────────────────
	"arcane_orb+wind_blade": {
		"id": "wind_orbs",
		"name": "Wind Orbs",
		"name_es": "Orbes de Viento",
		"description": "Orbes rápidos que empujan enemigos hacia afuera",
		"components": ["arcane_orb", "wind_blade"],
		"damage": 8,
		"cooldown": 0.0,
		"range": 150.0,
		"projectile_speed": 280.0,
		"projectile_count": 5,
		"pierce": 999,
		"area": 1.0,
		"duration": 999.0,
		"knockback": 120.0,
		"target_type": TargetType.ORBIT,
		"projectile_type": ProjectileType.ORBIT,
		"effect": "knockback_bonus",
		"effect_value": 1.8,
		"effect_duration": 0.0,
		"color": Color(0.7, 0.8, 1.0),
		"icon": "🔮🌪️"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# ARCANE + VOID: COSMIC VOID - Orbes del cosmos
	# ─────────────────────────────────────────────────────────────────────────────
	"arcane_orb+void_pulse": {
		"id": "cosmic_void",
		"name": "Cosmic Void",
		"name_es": "Vacío Cósmico",
		"description": "Orbes del vacío que marcan enemigos para daño extra",
		"components": ["arcane_orb", "void_pulse"],
		"damage": 16,
		"cooldown": 0.0,
		"range": 180.0,
		"projectile_speed": 160.0,
		"projectile_count": 4,
		"pierce": 999,
		"area": 1.8,
		"duration": 999.0,
		"knockback": 0.0,
		"target_type": TargetType.ORBIT,
		"projectile_type": ProjectileType.ORBIT,
		"effect": "shadow_mark",
		"effect_value": 1.5,
		"effect_duration": 3.0,
		"color": Color(0.3, 0.1, 0.4),
		"icon": "🔮🕳️"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# SHADOW + WIND: PHANTOM BLADE - Cuchillas fantasma
	# ─────────────────────────────────────────────────────────────────────────────
	"shadow_dagger+wind_blade": {
		"id": "phantom_blade",
		"name": "Phantom Blade",
		"name_es": "Hoja Fantasma",
		"description": "Cuchillas espectrales rápidas que atraviesan todo",
		"components": ["shadow_dagger", "wind_blade"],
		"damage": 9,
		"cooldown": 0.35,
		"range": 400.0,
		"projectile_speed": 580.0,
		"projectile_count": 4,
		"pierce": 5,
		"area": 0.9,
		"duration": 0.0,
		"knockback": 70.0,
		"target_type": TargetType.DIRECTION,
		"projectile_type": ProjectileType.MULTI,
		"effect": "bleed",  # DoT damage over time
		"effect_value": 3,  # 3 damage per tick
		"effect_duration": 2.0,  # 2 seconds
		"color": Color(0.4, 0.3, 0.5),
		"icon": "👻🗡️"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# SHADOW + EARTH: STONE FANG - Dagas de piedra
	# ─────────────────────────────────────────────────────────────────────────────
	"shadow_dagger+earth_spike": {
		"id": "stone_fang",
		"name": "Stone Fang",
		"name_es": "Colmillo de Piedra",
		"description": "Dagas de obsidiana que aturden y atraviesan",
		"components": ["shadow_dagger", "earth_spike"],
		"damage": 14,
		"cooldown": 0.55,
		"range": 400.0,
		"projectile_speed": 450.0,
		"projectile_count": 2,
		"pierce": 4,
		"area": 1.0,
		"duration": 0.0,
		"knockback": 80.0,
		"target_type": TargetType.DIRECTION,
		"projectile_type": ProjectileType.MULTI,
		"effect": "stun",
		"effect_value": 0.3,
		"effect_duration": 0.3,
		"color": Color(0.3, 0.2, 0.3),
		"icon": "🗡️🪨"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# SHADOW + LIGHT: TWILIGHT - Crepúsculo
	# ─────────────────────────────────────────────────────────────────────────────
	"shadow_dagger+light_beam": {
		"id": "twilight",
		"name": "Twilight",
		"name_es": "Crepúsculo",
		"description": "Dagas de luz y sombra que critican frecuentemente",
		"components": ["shadow_dagger", "light_beam"],
		"damage": 16,
		"cooldown": 0.45,
		"range": 450.0,
		"projectile_speed": 520.0,
		"projectile_count": 2,
		"pierce": 4,
		"area": 0.9,
		"duration": 0.0,
		"knockback": 40.0,
		"target_type": TargetType.DIRECTION,
		"projectile_type": ProjectileType.MULTI,
		"effect": "crit_chance",
		"effect_value": 0.3,
		"effect_duration": 0.0,
		"color": Color(0.6, 0.5, 0.7),
		"icon": "🌅"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# SHADOW + VOID: ABYSS - El abismo
	# ─────────────────────────────────────────────────────────────────────────────
	"shadow_dagger+void_pulse": {
		"id": "abyss",
		"name": "Abyss",
		"name_es": "Abismo",
		"description": "Dagas del abismo que ciegan y devoran la luz",
		"components": ["shadow_dagger", "void_pulse"],
		"damage": 18,
		"cooldown": 0.6,
		"range": 380.0,
		"projectile_speed": 400.0,
		"projectile_count": 3,
		"pierce": 5,
		"area": 1.2,
		"duration": 0.0,
		"knockback": -60.0,
		"target_type": TargetType.DIRECTION,
		"projectile_type": ProjectileType.MULTI,
		"effect": "blind",
		"effect_value": 0.0,
		"effect_duration": 2.0,
		"color": Color(0.1, 0.0, 0.2),
		"icon": "🕳️🗡️"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# NATURE + WIND: POLLEN STORM - Tormenta de polen
	# ─────────────────────────────────────────────────────────────────────────────
	"nature_staff+wind_blade": {
		"id": "pollen_storm",
		"name": "Pollen Storm",
		"name_es": "Tormenta de Polen",
		"description": "Esporas venenosas que el viento esparce por todos lados",
		"components": ["nature_staff", "wind_blade"],
		"damage": 7,
		"cooldown": 0.65,
		"range": 400.0,
		"projectile_speed": 350.0,
		"projectile_count": 5,
		"pierce": 2,
		"area": 1.3,
		"duration": 2.0,
		"knockback": 80.0,
		"target_type": TargetType.HOMING,
		"projectile_type": ProjectileType.MULTI,
		"effect": "lifesteal",
		"effect_value": 1,
		"effect_duration": 0.0,
		"color": Color(0.7, 0.9, 0.4),
		"icon": "🌿🌪️"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# NATURE + EARTH: GAIA - Poder de la tierra
	# ─────────────────────────────────────────────────────────────────────────────
	"nature_staff+earth_spike": {
		"id": "gaia",
		"name": "Gaia",
		"name_es": "Gaia",
		"description": "El poder de la naturaleza emerge de la tierra",
		"components": ["nature_staff", "earth_spike"],
		"damage": 22,
		"cooldown": 1.5,
		"range": 280.0,
		"projectile_speed": 0.0,
		"projectile_count": 2,
		"pierce": 999,
		"area": 1.8,
		"duration": 0.7,
		"knockback": 140.0,
		"target_type": TargetType.RANDOM,
		"projectile_type": ProjectileType.AOE,
		"effect": "lifesteal",
		"effect_value": 2,
		"effect_duration": 0.0,
		"color": Color(0.4, 0.6, 0.3),
		"icon": "🌍"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# NATURE + LIGHT: SOLAR BLOOM - Flor solar
	# ─────────────────────────────────────────────────────────────────────────────
	"nature_staff+light_beam": {
		"id": "solar_bloom",
		"name": "Solar Bloom",
		"name_es": "Flor Solar",
		"description": "Un rayo de energía vital que cura mientras destruye",
		"components": ["nature_staff", "light_beam"],
		"damage": 30,
		"cooldown": 1.8,
		"range": 550.0,
		"projectile_speed": 999.0,
		"projectile_count": 1,
		"pierce": 999,
		"area": 0.7,
		"duration": 0.35,
		"knockback": 30.0,
		"target_type": TargetType.NEAREST,
		"projectile_type": ProjectileType.BEAM,
		"effect": "lifesteal",
		"effect_value": 5,
		"effect_duration": 0.0,
		"color": Color(0.9, 1.0, 0.5),
		"icon": "🌻"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# NATURE + VOID: DECAY - Descomposición
	# ─────────────────────────────────────────────────────────────────────────────
	"nature_staff+void_pulse": {
		"id": "decay",
		"name": "Decay",
		"name_es": "Descomposición",
		"description": "El poder de la naturaleza y el vacío consume todo",
		"components": ["nature_staff", "void_pulse"],
		"damage": 20,
		"cooldown": 2.0,
		"range": 240.0,
		"projectile_speed": 0.0,
		"projectile_count": 1,
		"pierce": 999,
		"area": 2.4,
		"duration": 1.5,
		"knockback": -130.0,
		"target_type": TargetType.AREA,
		"projectile_type": ProjectileType.AOE,
		"effect": "lifesteal",
		"effect_value": 4,
		"effect_duration": 0.0,
		"color": Color(0.3, 0.4, 0.2),
		"icon": "🍂"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# WIND + EARTH: SANDSTORM - Tormenta de arena
	# ─────────────────────────────────────────────────────────────────────────────
	"wind_blade+earth_spike": {
		"id": "sandstorm",
		"name": "Sandstorm",
		"name_es": "Tormenta de Arena",
		"description": "Un tornado de arena que ciega y daña",
		"components": ["wind_blade", "earth_spike"],
		"damage": 12,
		"cooldown": 0.8,
		"range": 320.0,
		"projectile_speed": 380.0,
		"projectile_count": 6,
		"pierce": 3,
		"area": 1.6,
		"duration": 0.0,
		"knockback": 150.0,
		"target_type": TargetType.DIRECTION,
		"projectile_type": ProjectileType.MULTI,
		"effect": "blind",
		"effect_value": 0.4,  # Nerfed from 0.5 (50% to 40%)
		"effect_duration": 2.0,
		"color": Color(0.8, 0.7, 0.5),
		"icon": "🏜️"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# WIND + LIGHT: PRISM WIND - Viento prismático
	# ─────────────────────────────────────────────────────────────────────────────
	"wind_blade+light_beam": {
		"id": "prism_wind",
		"name": "Prism Wind",
		"name_es": "Viento Prismático",
		"description": "Cuchillas de luz refractada que critican a menudo",
		"components": ["wind_blade", "light_beam"],
		"damage": 18,
		"cooldown": 0.6,
		"range": 420.0,
		"projectile_speed": 500.0,
		"projectile_count": 3,  # Nerfed from 4
		"pierce": 2,
		"area": 1.0,
		"duration": 0.0,
		"knockback": 90.0,
		"target_type": TargetType.DIRECTION,
		"projectile_type": ProjectileType.MULTI,
		"effect": "crit_chance",
		"effect_value": 0.25,
		"effect_duration": 0.0,
		"color": Color(0.9, 0.95, 1.0),
		"icon": "🌈"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# EARTH + LIGHT: RADIANT STONE - Piedra radiante
	# ─────────────────────────────────────────────────────────────────────────────
	"earth_spike+light_beam": {
		"id": "radiant_stone",
		"name": "Radiant Stone",
		"name_es": "Piedra Radiante",
		"description": "Pilares de luz cristalizada que ciegan y aturden",
		"components": ["earth_spike", "light_beam"],
		"damage": 32,
		"cooldown": 1.9,
		"range": 280.0,
		"projectile_speed": 0.0,
		"projectile_count": 1,
		"pierce": 999,
		"area": 2.0,
		"duration": 0.6,
		"knockback": 170.0,
		"target_type": TargetType.RANDOM,
		"projectile_type": ProjectileType.AOE,
		"effect": "stun",
		"effect_value": 0.8,
		"effect_duration": 0.8,
		"color": Color(0.9, 0.85, 0.7),
		"icon": "💎✨"
	},
	
	# ─────────────────────────────────────────────────────────────────────────────
	# LIGHT + VOID: ECLIPSE - El eclipse
	# ─────────────────────────────────────────────────────────────────────────────
	"light_beam+void_pulse": {
		"id": "eclipse",
		"name": "Eclipse",
		"name_es": "Eclipse",
		"description": "El equilibrio entre luz y oscuridad, destrucción pura",
		"components": ["light_beam", "void_pulse"],
		"damage": 50,
		"cooldown": 2.5,  # Buffed from 3.0
		"range": 500.0,
		"projectile_speed": 999.0,
		"projectile_count": 1,
		"pierce": 999,
		"area": 2.5,
		"duration": 0.5,
		"knockback": 0.0,
		"target_type": TargetType.AREA,
		"projectile_type": ProjectileType.BEAM,
		"effect": "execute",
		"effect_value": 0.25,  # Buffed from 0.2 (20% to 25%)
		"effect_duration": 0.0,
		"color": Color(0.5, 0.4, 0.6),
		"icon": "🌑"
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# MÉTODOS DE UTILIDAD
# ═══════════════════════════════════════════════════════════════════════════════

static func get_weapon_data(weapon_id: String) -> Dictionary:
	"""Obtener datos de un arma por ID"""
	if WEAPONS.has(weapon_id):
		return WEAPONS[weapon_id].duplicate(true)
	
	# Buscar en fusiones
	for fusion_key in FUSIONS:
		if FUSIONS[fusion_key].id == weapon_id:
			return FUSIONS[fusion_key].duplicate(true)
	
	push_error("[WeaponDatabase] Arma no encontrada: %s" % weapon_id)
	return {}

static func get_fusion_result(weapon_a: String, weapon_b: String) -> Dictionary:
	"""Obtener resultado de fusionar dos armas"""
	var key1 = "%s+%s" % [weapon_a, weapon_b]
	var key2 = "%s+%s" % [weapon_b, weapon_a]
	
	if FUSIONS.has(key1):
		return FUSIONS[key1].duplicate(true)
	elif FUSIONS.has(key2):
		return FUSIONS[key2].duplicate(true)
	
	return {}  # No hay fusión disponible

static func can_fuse(weapon_a: String, weapon_b: String) -> bool:
	"""Verificar si dos armas pueden fusionarse"""
	var result = get_fusion_result(weapon_a, weapon_b)
	return not result.is_empty()

static func get_all_base_weapons() -> Array:
	"""Obtener lista de todas las armas base"""
	return WEAPONS.keys()

static func get_all_fusions() -> Array:
	"""Obtener lista de todas las fusiones posibles"""
	return FUSIONS.keys()

static func get_level_upgrade(level: int) -> Dictionary:
	"""Obtener mejora para un nivel específico"""
	if LEVEL_UPGRADES.has(level):
		return LEVEL_UPGRADES[level].duplicate()
	return {}

static func get_weapons_by_rarity(rarity: String) -> Array:
	"""Obtener armas por rareza"""
	var result = []
	for weapon_id in WEAPONS:
		if WEAPONS[weapon_id].rarity == rarity:
			result.append(weapon_id)
	return result

static func get_random_weapon(exclude: Array = []) -> String:
	"""Obtener un arma aleatoria, excluyendo las especificadas"""
	var available = []
	for weapon_id in WEAPONS:
		if weapon_id not in exclude:
			available.append(weapon_id)
	
	if available.is_empty():
		return ""
	
	return available[randi() % available.size()]

static func get_possible_fusions_for_weapon(weapon_id: String) -> Array:
	"""Obtener todas las fusiones posibles que involucran un arma específica"""
	var result = []
	for fusion_key in FUSIONS:
		if weapon_id in FUSIONS[fusion_key].components:
			result.append(FUSIONS[fusion_key])
	return result

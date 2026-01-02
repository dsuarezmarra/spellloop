# ProjectileVisualManager.gd
# Gestor central de efectos visuales para proyectiles
# Cada arma/fusión tiene su configuración visual ÚNICA

class_name ProjectileVisualManager
extends Node

# ═══════════════════════════════════════════════════════════════════════════════
# SINGLETON
# ═══════════════════════════════════════════════════════════════════════════════

static var instance: ProjectileVisualManager

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

# ═══════════════════════════════════════════════════════════════════════════════
# CACHE DE DATOS VISUALES
# ═══════════════════════════════════════════════════════════════════════════════

var _visual_data_cache: Dictionary = {}

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIONES VISUALES ÚNICAS POR ARMA
# Cada arma tiene su propia identidad visual
# ═══════════════════════════════════════════════════════════════════════════════

# Formato: weapon_id -> { colors, style, shape, effects }
const WEAPON_VISUALS: Dictionary = {
	# ══════════════════════════════════════════════════════════════════════════
	# ARMAS BASE (10)
	# ══════════════════════════════════════════════════════════════════════════

	"ice_wand": {
		"shape": "shard",           # Forma de cristal puntiagudo
		"primary": Color(0.4, 0.85, 1.0),
		"secondary": Color(0.2, 0.6, 0.95),
		"accent": Color(1.0, 1.0, 1.0),
		"outline": Color(0.1, 0.3, 0.5),
		"glow": Color(0.5, 0.9, 1.0, 0.5),
		"trail_color": Color(0.6, 0.9, 1.0, 0.4),
		"particles": "snowflakes",
		"rotation_speed": 0.0,       # No rota
		"squash_amount": 0.1
	},

	"fire_wand": {
		"shape": "fireball",         # Bola de fuego con llamas
		"primary": Color(1.0, 0.5, 0.1),
		"secondary": Color(1.0, 0.2, 0.0),
		"accent": Color(1.0, 0.95, 0.4),
		"outline": Color(0.5, 0.15, 0.0),
		"glow": Color(1.0, 0.4, 0.1, 0.6),
		"trail_color": Color(1.0, 0.3, 0.0, 0.5),
		"particles": "embers",
		"rotation_speed": 0.0,
		"squash_amount": 0.15
	},

	"lightning_wand": {
		"shape": "bolt",             # Rayo zigzag
		"primary": Color(0.4, 0.8, 1.0),
		"secondary": Color(0.7, 0.95, 1.0),
		"accent": Color(1.0, 1.0, 1.0),
		"outline": Color(0.15, 0.4, 0.6),
		"glow": Color(0.5, 0.85, 1.0, 0.6),
		"trail_color": Color(0.6, 0.9, 1.0, 0.3),
		"particles": "sparks",
		"rotation_speed": 0.0,
		"squash_amount": 0.2
	},

	"arcane_orb": {
		"shape": "orb",              # Orbe mágico con runas
		"primary": Color(0.6, 0.3, 0.9),
		"secondary": Color(0.8, 0.5, 1.0),
		"accent": Color(1.0, 0.85, 1.0),
		"outline": Color(0.25, 0.1, 0.45),
		"glow": Color(0.7, 0.4, 1.0, 0.5),
		"trail_color": Color(0.7, 0.5, 1.0, 0.4),
		"particles": "magic_sparkles",
		"rotation_speed": 2.0,       # Rota sobre sí mismo
		"squash_amount": 0.1
	},

	"shadow_dagger": {
		"shape": "dagger",           # Daga oscura
		"primary": Color(0.25, 0.1, 0.35),
		"secondary": Color(0.15, 0.05, 0.2),
		"accent": Color(0.5, 0.3, 0.7),
		"outline": Color(0.1, 0.05, 0.15),
		"glow": Color(0.4, 0.2, 0.6, 0.4),
		"trail_color": Color(0.3, 0.15, 0.5, 0.5),
		"particles": "shadow_wisps",
		"rotation_speed": 8.0,       # Gira rápido como cuchillo lanzado
		"squash_amount": 0.05
	},

	"nature_staff": {
		"shape": "leaf",             # Hoja/espina vegetal
		"primary": Color(0.35, 0.8, 0.3),
		"secondary": Color(0.5, 0.9, 0.4),
		"accent": Color(0.85, 1.0, 0.7),
		"outline": Color(0.15, 0.35, 0.1),
		"glow": Color(0.45, 0.85, 0.4, 0.45),
		"trail_color": Color(0.5, 0.9, 0.4, 0.4),
		"particles": "leaves",
		"rotation_speed": 1.0,
		"squash_amount": 0.12
	},

	"wind_blade": {
		"shape": "crescent",         # Media luna de viento
		"primary": Color(0.75, 0.92, 0.85),
		"secondary": Color(0.55, 0.85, 0.75),
		"accent": Color(1.0, 1.0, 1.0),
		"outline": Color(0.35, 0.5, 0.45),
		"glow": Color(0.65, 0.92, 0.85, 0.35),
		"trail_color": Color(0.7, 0.95, 0.9, 0.3),
		"particles": "wind_lines",
		"rotation_speed": 12.0,      # Gira muy rápido
		"squash_amount": 0.08
	},

	"earth_spike": {
		"shape": "spike",            # Pico de roca
		"primary": Color(0.6, 0.45, 0.25),
		"secondary": Color(0.8, 0.65, 0.45),
		"accent": Color(0.95, 0.85, 0.7),
		"outline": Color(0.35, 0.25, 0.12),
		"glow": Color(0.7, 0.55, 0.35, 0.35),
		"trail_color": Color(0.6, 0.5, 0.3, 0.4),
		"particles": "dust",
		"rotation_speed": 0.0,
		"squash_amount": 0.05
	},

	"light_beam": {
		"shape": "star",             # Estrella brillante
		"primary": Color(1.0, 0.98, 0.85),
		"secondary": Color(1.0, 0.92, 0.65),
		"accent": Color(1.0, 1.0, 1.0),
		"outline": Color(0.85, 0.75, 0.55),
		"glow": Color(1.0, 0.98, 0.85, 0.6),
		"trail_color": Color(1.0, 0.95, 0.8, 0.5),
		"particles": "light_rays",
		"rotation_speed": 3.0,
		"squash_amount": 0.1
	},

	"void_pulse": {
		"shape": "void_sphere",      # Esfera de vacío distorsionada
		"primary": Color(0.12, 0.05, 0.2),
		"secondary": Color(0.2, 0.1, 0.35),
		"accent": Color(0.5, 0.25, 0.75),
		"outline": Color(0.08, 0.03, 0.12),
		"glow": Color(0.35, 0.15, 0.55, 0.5),
		"trail_color": Color(0.25, 0.1, 0.45, 0.5),
		"particles": "void_particles",
		"rotation_speed": -1.5,      # Rota al revés
		"squash_amount": 0.2
	},

	# ══════════════════════════════════════════════════════════════════════════
	# FUSIONES ICE (9)
	# ══════════════════════════════════════════════════════════════════════════

	"steam_cannon": {  # Ice + Fire
		"shape": "steam_cloud",
		"primary": Color(0.9, 0.9, 0.95),
		"secondary": Color(0.7, 0.75, 0.85),
		"accent": Color(1.0, 0.6, 0.4),
		"outline": Color(0.5, 0.5, 0.55),
		"glow": Color(0.85, 0.85, 0.9, 0.5),
		"trail_color": Color(0.8, 0.8, 0.9, 0.4),
		"particles": "steam",
		"rotation_speed": 0.5,
		"squash_amount": 0.18
	},

	"frozen_thunder": {  # Ice + Lightning
		"shape": "ice_bolt",
		"primary": Color(0.5, 0.85, 1.0),
		"secondary": Color(0.7, 0.95, 1.0),
		"accent": Color(1.0, 1.0, 1.0),
		"outline": Color(0.2, 0.4, 0.6),
		"glow": Color(0.6, 0.9, 1.0, 0.55),
		"trail_color": Color(0.5, 0.9, 1.0, 0.4),
		"particles": "ice_sparks",
		"rotation_speed": 0.0,
		"squash_amount": 0.15
	},

	"frost_orb": {  # Ice + Arcane
		"shape": "frost_crystal",
		"primary": Color(0.5, 0.7, 0.95),
		"secondary": Color(0.65, 0.5, 0.9),
		"accent": Color(0.9, 0.95, 1.0),
		"outline": Color(0.2, 0.25, 0.45),
		"glow": Color(0.55, 0.7, 0.95, 0.5),
		"trail_color": Color(0.6, 0.7, 1.0, 0.4),
		"particles": "arcane_frost",
		"rotation_speed": 1.5,
		"squash_amount": 0.1
	},

	"frostbite": {  # Ice + Shadow
		"shape": "dark_shard",
		"primary": Color(0.3, 0.5, 0.7),
		"secondary": Color(0.15, 0.2, 0.4),
		"accent": Color(0.6, 0.8, 0.95),
		"outline": Color(0.1, 0.15, 0.25),
		"glow": Color(0.35, 0.5, 0.7, 0.45),
		"trail_color": Color(0.3, 0.45, 0.65, 0.5),
		"particles": "dark_frost",
		"rotation_speed": 0.0,
		"squash_amount": 0.08
	},

	"blizzard": {  # Ice + Nature
		"shape": "snowstorm",
		"primary": Color(0.5, 0.85, 0.75),
		"secondary": Color(0.4, 0.75, 0.9),
		"accent": Color(0.9, 1.0, 0.95),
		"outline": Color(0.2, 0.4, 0.35),
		"glow": Color(0.5, 0.85, 0.8, 0.45),
		"trail_color": Color(0.55, 0.9, 0.8, 0.4),
		"particles": "ice_leaves",
		"rotation_speed": 0.8,
		"squash_amount": 0.15
	},

	"glacier": {  # Ice + Wind
		"shape": "ice_blade",
		"primary": Color(0.55, 0.9, 0.95),
		"secondary": Color(0.7, 0.95, 1.0),
		"accent": Color(1.0, 1.0, 1.0),
		"outline": Color(0.25, 0.45, 0.5),
		"glow": Color(0.6, 0.9, 0.95, 0.4),
		"trail_color": Color(0.65, 0.95, 1.0, 0.35),
		"particles": "frost_wind",
		"rotation_speed": 10.0,
		"squash_amount": 0.1
	},

	"aurora": {  # Ice + Earth
		"shape": "aurora_crystal",
		"primary": Color(0.5, 0.8, 0.85),
		"secondary": Color(0.7, 0.6, 0.5),
		"accent": Color(0.85, 0.95, 0.9),
		"outline": Color(0.3, 0.35, 0.35),
		"glow": Color(0.55, 0.75, 0.8, 0.45),
		"trail_color": Color(0.6, 0.8, 0.85, 0.4),
		"particles": "crystal_dust",
		"rotation_speed": 0.0,
		"squash_amount": 0.08
	},

	"absolute_zero": {  # Ice + Light
		"shape": "pure_ice",
		"primary": Color(0.7, 0.95, 1.0),
		"secondary": Color(0.9, 0.98, 1.0),
		"accent": Color(1.0, 1.0, 1.0),
		"outline": Color(0.4, 0.6, 0.7),
		"glow": Color(0.75, 0.95, 1.0, 0.6),
		"trail_color": Color(0.8, 0.98, 1.0, 0.5),
		"particles": "light_frost",
		"rotation_speed": 2.0,
		"squash_amount": 0.12
	},

	"frostvine": {  # Ice + Nature - Enredadera de Hielo
		"shape": "organic_crystal",
		"primary": Color(0.4, 1.0, 0.8),      # Mint green (#66FFCC)
		"secondary": Color(0.6, 1.0, 1.0),    # Cyan (#99FFFF)
		"accent": Color(0.8, 1.0, 0.93),      # Pale mint (#CCFFEE)
		"outline": Color(0.2, 0.4, 0.33),     # Deep teal (#336655)
		"glow": Color(0.4, 1.0, 0.8, 0.5),
		"trail_color": Color(0.5, 1.0, 0.9, 0.45),
		"particles": "frost_vines",
		"rotation_speed": 0.0,
		"squash_amount": 0.1
	},

	# ══════════════════════════════════════════════════════════════════════════
	# FUSIONES FIRE (8)
	# ══════════════════════════════════════════════════════════════════════════

	"plasma": {  # Fire + Lightning
		"shape": "plasma_ball",
		"primary": Color(1.0, 0.7, 0.9),
		"secondary": Color(0.9, 0.4, 0.7),
		"accent": Color(1.0, 0.95, 1.0),
		"outline": Color(0.5, 0.2, 0.4),
		"glow": Color(1.0, 0.6, 0.85, 0.6),
		"trail_color": Color(0.95, 0.5, 0.8, 0.5),
		"particles": "plasma_sparks",
		"rotation_speed": 0.0,
		"squash_amount": 0.2
	},

	"inferno_orb": {  # Fire + Arcane
		"shape": "arcane_flame",
		"primary": Color(1.0, 0.4, 0.3),
		"secondary": Color(0.8, 0.3, 0.6),
		"accent": Color(1.0, 0.85, 0.5),
		"outline": Color(0.4, 0.15, 0.25),
		"glow": Color(1.0, 0.45, 0.4, 0.55),
		"trail_color": Color(0.95, 0.4, 0.5, 0.5),
		"particles": "magic_flames",
		"rotation_speed": 1.5,
		"squash_amount": 0.15
	},

	"wildfire": {  # Fire + Nature - Fuego Salvaje
		"shape": "organic_flame",
		"primary": Color(1.0, 0.4, 0.07),     # Bright orange (#FF6611)
		"secondary": Color(0.8, 1.0, 0.2),    # Yellow-green (#CCFF33)
		"accent": Color(1.0, 0.8, 0.0),       # Yellow (#FFCC00)
		"outline": Color(0.6, 0.2, 0.0),      # Burnt orange (#993300)
		"glow": Color(1.0, 0.6, 0.15, 0.5),
		"trail_color": Color(1.0, 0.5, 0.1, 0.5),
		"particles": "burning_seeds",
		"rotation_speed": 0.0,
		"squash_amount": 0.15
	},

	"firestorm": {  # Fire + Wind - Tornado de fuego giratorio
		"shape": "fire_tornado",
		"primary": Color(1.0, 0.4, 0.0),       # Orange #FF6600
		"secondary": Color(1.0, 0.27, 0.0),    # Red-orange #FF4400
		"accent": Color(1.0, 0.93, 0.4),       # Yellow-white core #FFEE66
		"outline": Color(0.4, 0.13, 0.0),      # Deep red-brown #662200
		"glow": Color(1.0, 0.5, 0.1, 0.55),
		"trail_color": Color(1.0, 0.8, 0.6, 0.5),  # Wind-fire trail
		"particles": "fire_embers",
		"rotation_speed": 8.0,  # Fast spin for tornado effect
		"squash_amount": 0.08
	},

	"volcano": {  # Fire + Earth
		"shape": "lava_rock",
		"primary": Color(1.0, 0.45, 0.1),
		"secondary": Color(0.6, 0.3, 0.2),
		"accent": Color(1.0, 0.8, 0.3),
		"outline": Color(0.35, 0.15, 0.1),
		"glow": Color(1.0, 0.5, 0.15, 0.55),
		"trail_color": Color(0.9, 0.4, 0.1, 0.5),
		"particles": "ash_embers",
		"rotation_speed": 3.0,
		"squash_amount": 0.1
	},

	"solar_flare": {  # Fire + Earth
		"shape": "solar_disc",
		"primary": Color(1.0, 0.7, 0.3),
		"secondary": Color(0.85, 0.55, 0.25),
		"accent": Color(1.0, 0.95, 0.6),
		"outline": Color(0.5, 0.35, 0.15),
		"glow": Color(1.0, 0.75, 0.35, 0.55),
		"trail_color": Color(1.0, 0.7, 0.3, 0.45),
		"particles": "solar_dust",
		"rotation_speed": 2.0,
		"squash_amount": 0.1
	},

	"dark_flame": {  # Fire + Light
		"shape": "holy_fire",
		"primary": Color(1.0, 0.85, 0.5),
		"secondary": Color(1.0, 0.5, 0.2),
		"accent": Color(1.0, 1.0, 0.9),
		"outline": Color(0.6, 0.45, 0.2),
		"glow": Color(1.0, 0.8, 0.45, 0.55),
		"trail_color": Color(1.0, 0.85, 0.5, 0.5),
		"particles": "holy_embers",
		"rotation_speed": 1.0,
		"squash_amount": 0.15
	},

	"hellfire": {  # Fire + Shadow - Fuego demoníaco corrupto
		"shape": "demonic_flame",
		"primary": Color(0.6, 0.0, 0.2),       # Deep crimson #990033
		"secondary": Color(0.4, 0.0, 0.13),    # Dark red #660022
		"accent": Color(1.0, 0.27, 0.13),      # Orange-red #FF4422
		"outline": Color(0.2, 0.0, 0.07),      # Very dark #330011
		"glow": Color(0.8, 0.13, 0.27, 0.55),  # Sinister magenta-red
		"trail_color": Color(0.1, 0.04, 0.04, 0.6),  # Shadow trail
		"particles": "dark_embers",
		"rotation_speed": 0.0,
		"squash_amount": 0.15
	},

	# ══════════════════════════════════════════════════════════════════════════
	# FUSIONES LIGHTNING (7)
	# ══════════════════════════════════════════════════════════════════════════

	"storm_caller": {  # Lightning + Arcane
		"shape": "storm_orb",
		"primary": Color(0.5, 0.6, 0.95),
		"secondary": Color(0.7, 0.5, 0.9),
		"accent": Color(0.9, 0.95, 1.0),
		"outline": Color(0.25, 0.25, 0.5),
		"glow": Color(0.55, 0.6, 0.95, 0.55),
		"trail_color": Color(0.6, 0.65, 1.0, 0.45),
		"particles": "arcane_lightning",
		"rotation_speed": 2.5,
		"squash_amount": 0.15
	},

	"arcane_storm": {  # Lightning + Shadow
		"shape": "dark_bolt",
		"primary": Color(0.35, 0.4, 0.7),
		"secondary": Color(0.15, 0.15, 0.35),
		"accent": Color(0.7, 0.8, 1.0),
		"outline": Color(0.1, 0.1, 0.25),
		"glow": Color(0.4, 0.45, 0.7, 0.5),
		"trail_color": Color(0.35, 0.4, 0.65, 0.45),
		"particles": "shadow_sparks",
		"rotation_speed": 0.0,
		"squash_amount": 0.18
	},

	"dark_lightning": {  # Lightning + Shadow - Rayo Oscuro
		"shape": "dark_dagger",
		"primary": Color(0.4, 0.2, 0.67),       # Deep purple #6633AA
		"secondary": Color(0.27, 0.13, 0.67),   # Dark violet #4422AA
		"accent": Color(0.87, 0.8, 1.0),        # Pale lavender #DDCCFF
		"outline": Color(0.13, 0.0, 0.2),       # Very dark purple #220033
		"glow": Color(0.6, 0.4, 1.0, 0.55),     # Electric violet glow
		"trail_color": Color(0.4, 0.2, 0.67, 0.5),
		"particles": "shadow_sparks",
		"rotation_speed": 0.0,
		"squash_amount": 0.1
	},

	"thunder_bloom": {  # Lightning + Nature - Flor del Trueno
		"shape": "thunder_leaf",
		"primary": Color(0.45, 0.85, 0.35),       # Verde eléctrico brillante
		"secondary": Color(0.6, 1.0, 0.4),        # Verde-amarillo (del weapon color)
		"accent": Color(1.0, 1.0, 0.7),           # Destello amarillo-blanco (electricidad)
		"outline": Color(0.2, 0.45, 0.15),        # Verde oscuro
		"glow": Color(0.5, 0.95, 0.4, 0.55),      # Resplandor verde brillante
		"trail_color": Color(0.55, 0.9, 0.45, 0.45),
		"particles": "electric_pollen",
		"rotation_speed": 3.0,
		"squash_amount": 0.12
	},

	"seismic_bolt": {  # Lightning + Earth
		"shape": "geo_bolt",
		"primary": Color(0.65, 0.55, 0.4),
		"secondary": Color(0.5, 0.7, 0.85),
		"accent": Color(0.9, 0.85, 0.7),
		"outline": Color(0.3, 0.25, 0.2),
		"glow": Color(0.6, 0.55, 0.45, 0.45),
		"trail_color": Color(0.6, 0.6, 0.5, 0.4),
		"particles": "charged_rocks",
		"rotation_speed": 0.0,
		"squash_amount": 0.08
	},

	"thunder_spear": {  # Lightning + Light
		"shape": "light_bolt",
		"primary": Color(0.85, 0.95, 1.0),
		"secondary": Color(1.0, 1.0, 0.9),
		"accent": Color(1.0, 1.0, 1.0),
		"outline": Color(0.5, 0.6, 0.7),
		"glow": Color(0.9, 0.95, 1.0, 0.6),
		"trail_color": Color(0.9, 0.98, 1.0, 0.5),
		"particles": "divine_sparks",
		"rotation_speed": 0.0,
		"squash_amount": 0.15
	},

	"void_bolt": {  # Lightning + Void - Dark ethereal chain lightning
		"shape": "void_bolt",
		"primary": Color(0.3, 0.1, 0.4),        # Dark purple #4D1A66
		"secondary": Color(0.1, 0.04, 0.15),    # Near-black #1A0A26
		"accent": Color(0.8, 0.8, 1.0),         # Ghostly pale #CCCCFF
		"outline": Color(0.1, 0.04, 0.15),      # Very dark purple-black
		"glow": Color(0.3, 0.1, 0.4, 0.4),      # Dark purple glow
		"trail_color": Color(0.4, 0.2, 0.5, 0.35),
		"particles": "shadow_sparks",
		"rotation_speed": 0.0,
		"squash_amount": 0.1
	},

	# ══════════════════════════════════════════════════════════════════════════
	# FUSIONES ARCANE (5)
	# ══════════════════════════════════════════════════════════════════════════

	"shadow_orbs": {  # Arcane + Shadow
		"shape": "shadow_orb",
		"primary": Color(0.4, 0.2, 0.55),
		"secondary": Color(0.2, 0.1, 0.3),
		"accent": Color(0.7, 0.5, 0.85),
		"outline": Color(0.15, 0.08, 0.22),
		"glow": Color(0.45, 0.25, 0.55, 0.5),
		"trail_color": Color(0.4, 0.2, 0.5, 0.45),
		"particles": "shadow_magic",
		"rotation_speed": 1.5,
		"squash_amount": 0.12
	},

	"life_orbs": {  # Arcane + Nature
		"shape": "nature_orb",
		"primary": Color(0.5, 0.7, 0.5),
		"secondary": Color(0.65, 0.55, 0.85),
		"accent": Color(0.85, 1.0, 0.85),
		"outline": Color(0.25, 0.35, 0.3),
		"glow": Color(0.55, 0.7, 0.55, 0.45),
		"trail_color": Color(0.55, 0.75, 0.55, 0.4),
		"particles": "life_sparkles",
		"rotation_speed": 1.0,
		"squash_amount": 0.1
	},

	"wind_orbs": {  # Arcane + Wind
		"shape": "wind_orb",
		"primary": Color(0.65, 0.75, 0.9),
		"secondary": Color(0.7, 0.55, 0.85),
		"accent": Color(0.95, 0.98, 1.0),
		"outline": Color(0.35, 0.4, 0.5),
		"glow": Color(0.65, 0.75, 0.9, 0.45),
		"trail_color": Color(0.7, 0.8, 0.95, 0.4),
		"particles": "magic_wind",
		"rotation_speed": 4.0,
		"squash_amount": 0.15
	},

	"cosmic_barrier": {  # Arcane + Earth
		"shape": "crystal_orb",
		"primary": Color(0.6, 0.45, 0.7),
		"secondary": Color(0.7, 0.55, 0.5),
		"accent": Color(0.85, 0.8, 0.9),
		"outline": Color(0.3, 0.25, 0.35),
		"glow": Color(0.6, 0.5, 0.7, 0.45),
		"trail_color": Color(0.65, 0.5, 0.7, 0.4),
		"particles": "crystal_magic",
		"rotation_speed": 0.8,
		"squash_amount": 0.08
	},

	"cosmic_void": {  # Arcane + Light
		"shape": "radiant_orb",
		"primary": Color(0.85, 0.75, 0.95),
		"secondary": Color(0.95, 0.9, 0.8),
		"accent": Color(1.0, 1.0, 1.0),
		"outline": Color(0.5, 0.45, 0.55),
		"glow": Color(0.85, 0.8, 0.95, 0.55),
		"trail_color": Color(0.9, 0.85, 0.98, 0.5),
		"particles": "holy_magic",
		"rotation_speed": 1.5,
		"squash_amount": 0.1
	},

	# ══════════════════════════════════════════════════════════════════════════
	# FUSIONES SHADOW (5)
	# ══════════════════════════════════════════════════════════════════════════

	"soul_reaper": {  # Shadow + Nature
		"shape": "death_scythe",
		"primary": Color(0.25, 0.3, 0.2),
		"secondary": Color(0.15, 0.1, 0.15),
		"accent": Color(0.5, 0.6, 0.4),
		"outline": Color(0.1, 0.12, 0.08),
		"glow": Color(0.3, 0.35, 0.25, 0.45),
		"trail_color": Color(0.25, 0.3, 0.2, 0.45),
		"particles": "death_leaves",
		"rotation_speed": 6.0,
		"squash_amount": 0.08
	},

	"phantom_blade": {  # Shadow + Wind
		"shape": "ghost_blade",
		"primary": Color(0.4, 0.45, 0.5),
		"secondary": Color(0.2, 0.15, 0.25),
		"accent": Color(0.7, 0.75, 0.8),
		"outline": Color(0.15, 0.12, 0.18),
		"glow": Color(0.45, 0.5, 0.55, 0.4),
		"trail_color": Color(0.4, 0.45, 0.5, 0.4),
		"particles": "phantom_wisps",
		"rotation_speed": 10.0,
		"squash_amount": 0.1
	},

	"stone_fang": {  # Shadow + Earth
		"shape": "obsidian_fang",
		"primary": Color(0.25, 0.2, 0.25),
		"secondary": Color(0.4, 0.35, 0.3),
		"accent": Color(0.5, 0.45, 0.5),
		"outline": Color(0.12, 0.1, 0.12),
		"glow": Color(0.3, 0.25, 0.3, 0.4),
		"trail_color": Color(0.28, 0.22, 0.28, 0.4),
		"particles": "obsidian_dust",
		"rotation_speed": 0.0,
		"squash_amount": 0.05
	},

	"twilight": {  # Shadow + Light
		"shape": "twilight_orb",
		"primary": Color(0.5, 0.4, 0.6),
		"secondary": Color(0.8, 0.75, 0.65),
		"accent": Color(0.9, 0.85, 0.95),
		"outline": Color(0.3, 0.25, 0.35),
		"glow": Color(0.55, 0.45, 0.6, 0.5),
		"trail_color": Color(0.55, 0.5, 0.6, 0.45),
		"particles": "twilight_sparkles",
		"rotation_speed": 1.0,
		"squash_amount": 0.12
	},

	"abyss": {  # Shadow + Void
		"shape": "abyss_maw",
		"primary": Color(0.1, 0.05, 0.15),
		"secondary": Color(0.15, 0.08, 0.2),
		"accent": Color(0.35, 0.2, 0.45),
		"outline": Color(0.05, 0.02, 0.08),
		"glow": Color(0.15, 0.08, 0.2, 0.5),
		"trail_color": Color(0.12, 0.06, 0.18, 0.5),
		"particles": "abyss_particles",
		"rotation_speed": -1.0,
		"squash_amount": 0.25
	},

	# ══════════════════════════════════════════════════════════════════════════
	# FUSIONES NATURE (4)
	# ══════════════════════════════════════════════════════════════════════════

	"pollen_storm": {  # Nature + Wind
		"shape": "pollen_cloud",
		"primary": Color(0.7, 0.85, 0.4),
		"secondary": Color(0.6, 0.8, 0.7),
		"accent": Color(0.95, 1.0, 0.8),
		"outline": Color(0.35, 0.45, 0.25),
		"glow": Color(0.7, 0.85, 0.5, 0.4),
		"trail_color": Color(0.75, 0.9, 0.5, 0.35),
		"particles": "pollen",
		"rotation_speed": 3.0,
		"squash_amount": 0.18
	},

	"gaia": {  # Nature + Earth
		"shape": "earth_seed",
		"primary": Color(0.45, 0.6, 0.35),
		"secondary": Color(0.55, 0.45, 0.3),
		"accent": Color(0.75, 0.85, 0.6),
		"outline": Color(0.25, 0.3, 0.18),
		"glow": Color(0.5, 0.6, 0.4, 0.4),
		"trail_color": Color(0.5, 0.65, 0.4, 0.4),
		"particles": "earth_leaves",
		"rotation_speed": 0.5,
		"squash_amount": 0.1
	},

	"solar_bloom": {  # Nature + Light
		"shape": "sun_flower",
		"primary": Color(0.55, 0.8, 0.45),
		"secondary": Color(1.0, 0.9, 0.5),
		"accent": Color(1.0, 1.0, 0.85),
		"outline": Color(0.3, 0.45, 0.25),
		"glow": Color(0.65, 0.85, 0.55, 0.5),
		"trail_color": Color(0.7, 0.9, 0.55, 0.45),
		"particles": "sun_petals",
		"rotation_speed": 2.0,
		"squash_amount": 0.12
	},

	"decay": {  # Nature + Void
		"shape": "rot_spore",
		"primary": Color(0.35, 0.4, 0.25),
		"secondary": Color(0.2, 0.15, 0.25),
		"accent": Color(0.55, 0.6, 0.4),
		"outline": Color(0.15, 0.18, 0.12),
		"glow": Color(0.4, 0.45, 0.3, 0.45),
		"trail_color": Color(0.38, 0.42, 0.28, 0.45),
		"particles": "decay_spores",
		"rotation_speed": 0.3,
		"squash_amount": 0.15
	},

	# ══════════════════════════════════════════════════════════════════════════
	# FUSIONES WIND (3)
	# ══════════════════════════════════════════════════════════════════════════

	"sandstorm": {  # Wind + Earth
		"shape": "sand_vortex",
		"primary": Color(0.8, 0.7, 0.5),
		"secondary": Color(0.65, 0.55, 0.4),
		"accent": Color(0.95, 0.9, 0.75),
		"outline": Color(0.45, 0.38, 0.28),
		"glow": Color(0.8, 0.72, 0.55, 0.4),
		"trail_color": Color(0.78, 0.68, 0.5, 0.4),
		"particles": "sand",
		"rotation_speed": 8.0,
		"squash_amount": 0.15
	},

	"prism_wind": {  # Wind + Light
		"shape": "light_gust",
		"primary": Color(0.85, 0.95, 0.95),
		"secondary": Color(0.95, 0.95, 0.85),
		"accent": Color(1.0, 1.0, 1.0),
		"outline": Color(0.5, 0.55, 0.55),
		"glow": Color(0.88, 0.95, 0.95, 0.45),
		"trail_color": Color(0.9, 0.98, 0.98, 0.4),
		"particles": "prism_sparkles",
		"rotation_speed": 5.0,
		"squash_amount": 0.1
	},

	# ══════════════════════════════════════════════════════════════════════════
	# FUSIONES EARTH (3)
	# ══════════════════════════════════════════════════════════════════════════

	"rift_quake": {  # Earth + Void
		"shape": "light_crystal",
		"primary": Color(0.75, 0.65, 0.5),
		"secondary": Color(0.95, 0.9, 0.75),
		"accent": Color(1.0, 0.98, 0.9),
		"outline": Color(0.45, 0.38, 0.3),
		"glow": Color(0.8, 0.72, 0.58, 0.5),
		"trail_color": Color(0.82, 0.75, 0.6, 0.45),
		"particles": "light_dust",
		"rotation_speed": 0.0,
		"squash_amount": 0.08
	},

	"crystal_guardian": {  # Earth + Void
		"shape": "void_crystal",
		"primary": Color(0.45, 0.35, 0.45),
		"secondary": Color(0.2, 0.15, 0.25),
		"accent": Color(0.65, 0.55, 0.7),
		"outline": Color(0.22, 0.18, 0.25),
		"glow": Color(0.48, 0.38, 0.5, 0.45),
		"trail_color": Color(0.45, 0.35, 0.48, 0.45),
		"particles": "void_crystals",
		"rotation_speed": -0.5,
		"squash_amount": 0.1
	},

	"radiant_stone": {  # Earth + Light
		"shape": "radiant_gem",
		"primary": Color(0.8, 0.7, 0.55),
		"secondary": Color(1.0, 0.95, 0.8),
		"accent": Color(1.0, 1.0, 0.95),
		"outline": Color(0.48, 0.42, 0.32),
		"glow": Color(0.85, 0.78, 0.6, 0.5),
		"trail_color": Color(0.88, 0.8, 0.65, 0.45),
		"particles": "gem_sparkles",
		"rotation_speed": 1.0,
		"squash_amount": 0.08
	},

	# ══════════════════════════════════════════════════════════════════════════
	# FUSIONES LIGHT/VOID (2)
	# ══════════════════════════════════════════════════════════════════════════

	"void_storm": {  # Light + Void
		"shape": "duality_orb",
		"primary": Color(0.7, 0.65, 0.8),
		"secondary": Color(0.15, 0.1, 0.25),
		"accent": Color(0.95, 0.92, 1.0),
		"outline": Color(0.35, 0.3, 0.42),
		"glow": Color(0.68, 0.62, 0.78, 0.5),
		"trail_color": Color(0.65, 0.6, 0.75, 0.45),
		"particles": "duality_sparks",
		"rotation_speed": 0.0,
		"squash_amount": 0.18
	},

	"eclipse": {  # Void + Light
		"shape": "eclipse_ring",
		"primary": Color(0.2, 0.15, 0.3),
		"secondary": Color(0.9, 0.85, 0.75),
		"accent": Color(0.5, 0.4, 0.6),
		"outline": Color(0.1, 0.08, 0.15),
		"glow": Color(0.25, 0.2, 0.35, 0.5),
		"trail_color": Color(0.22, 0.18, 0.32, 0.5),
		"particles": "eclipse_particles",
		"rotation_speed": 2.0,
		"squash_amount": 0.15
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# TIPO DE PROYECTIL POR INT (del WeaponDatabase)
# ═══════════════════════════════════════════════════════════════════════════════

const PROJECTILE_TYPE_MAP: Dictionary = {
	0: ProjectileVisualData.ProjectileStyle.SINGLE,  # SINGLE
	1: ProjectileVisualData.ProjectileStyle.MULTI,   # MULTI
	2: ProjectileVisualData.ProjectileStyle.BEAM,    # BEAM
	3: ProjectileVisualData.ProjectileStyle.AOE,     # AOE
	4: ProjectileVisualData.ProjectileStyle.ORBIT,   # ORBIT
	5: ProjectileVisualData.ProjectileStyle.CHAIN    # CHAIN
}

# Path base para sprites de proyectiles personalizados
const PROJECTILE_SPRITES_PATH = "res://assets/sprites/projectiles/"
const WEAPONS_SPRITES_PATH = "res://assets/sprites/projectiles/weapons/"
const FUSION_SPRITES_PATH = "res://assets/sprites/projectiles/fusion/"

# Lista de armas base (van en carpeta weapons/)
const BASE_WEAPONS: Array = ["ice_wand", "fire_wand", "nature_staff", "wind_blade", "lightning_wand", "arcane_orb", "shadow_dagger", "earth_spike", "light_beam", "void_pulse"]

# Configuración de sprites por arma (frame counts y fps)
# Nomenclatura de archivos: flight_spritesheet_[weapon].png, impact_spritesheet_[weapon].png
const WEAPON_SPRITE_CONFIG: Dictionary = {
	"ice_wand": {
		"flight_frames": 6,
		"flight_fps": 12.0,
		"impact_frames": 6,
		"impact_fps": 15.0,
		"sprite_scale": 1.0,
		"rotation_offset": 30.0  # Corregir eje desviado del sprite (grados)
	},
	"lightning_wand": {
		"flight_frames": 4,
		"flight_fps": 20.0,  # Fast for electric crackling effect
		"impact_frames": 4,
		"impact_fps": 24.0,  # Very fast for instant zap feel
		"sprite_scale": 1.0,
		"is_chain": true,    # Usar sistema de sprites chain
		"chain_bolt_frames": 4,
		"chain_zap_frames": 4
	},
	"frozen_thunder": {  # Ice + Lightning fusion - Chain weapon
		"flight_frames": 4,
		"flight_fps": 18.0,  # Slightly slower - ice crystals forming
		"impact_frames": 4,
		"impact_fps": 20.0,  # Ice shattering effect
		"sprite_scale": 1.0,
		"is_chain": true,
		"chain_bolt_frames": 4,
		"chain_zap_frames": 4
	},
	"plasma": {  # Fire + Lightning fusion - Chain weapon
		"flight_frames": 4,
		"flight_fps": 22.0,  # Fast - hot plasma energy
		"impact_frames": 4,
		"impact_fps": 24.0,  # Quick plasma burst
		"sprite_scale": 1.0,
		"is_chain": true,
		"chain_bolt_frames": 4,
		"chain_zap_frames": 4
	},
	"storm_caller": {  # Lightning + Wind fusion - Chain weapon
		"flight_frames": 4,
		"flight_fps": 20.0,  # Medium - powerful storm
		"impact_frames": 4,
		"impact_fps": 22.0,  # Storm impact
		"sprite_scale": 1.0,
		"is_chain": true,
		"chain_bolt_frames": 4,
		"chain_zap_frames": 4
	},
	"void_bolt": {  # Lightning + Void fusion - Chain weapon
		"flight_frames": 4,
		"flight_fps": 18.0,  # Slower - ethereal shadow
		"impact_frames": 4,
		"impact_fps": 20.0,  # Ghostly impact
		"sprite_scale": 1.0,
		"is_chain": true,
		"chain_bolt_frames": 4,
		"chain_zap_frames": 4
	},
	"fire_wand": {
		"flight_frames": 6,
		"flight_fps": 12.0,
		"impact_frames": 6,
		"impact_fps": 15.0,
		"sprite_scale": 1.0
	},
	"nature_staff": {
		"flight_frames": 6,
		"flight_fps": 12.0,
		"impact_frames": 6,
		"impact_fps": 15.0,
		"sprite_scale": 1.0
	},
	"wind_blade": {
		"flight_frames": 6,
		"flight_fps": 12.0,
		"impact_frames": 6,
		"impact_fps": 15.0,
		"sprite_scale": 1.0
	},
	"shadow_dagger": {
		"flight_frames": 6,
		"flight_fps": 12.0,
		"impact_frames": 6,
		"impact_fps": 15.0,
		"sprite_scale": 1.0
	},
	# === FUSION WEAPONS ===
	"frostbite": {
		"flight_frames": 6,
		"flight_fps": 12.0,
		"impact_frames": 6,
		"impact_fps": 15.0,
		"sprite_scale": 1.0
	},
	"blizzard": {
		"flight_frames": 6,
		"flight_fps": 12.0,
		"impact_frames": 6,
		"impact_fps": 15.0,
		"sprite_scale": 1.0
	},
	"frostvine": {
		"flight_frames": 6,
		"flight_fps": 10.0,
		"impact_frames": 6,
		"impact_fps": 12.0,
		"sprite_scale": 1.0
	},
	"wildfire": {
		"flight_frames": 6,
		"flight_fps": 12.0,
		"impact_frames": 6,
		"impact_fps": 14.0,
		"sprite_scale": 1.0
	},
	"firestorm": {
		"flight_frames": 6,
		"flight_fps": 14.0,  # Fast spin
		"impact_frames": 6,
		"impact_fps": 16.0,
		"sprite_scale": 1.0,
		"lock_rotation": true  # Tornado no rota con la dirección (siempre se ve igual)
	},
	"hellfire": {
		"flight_frames": 6,
		"flight_fps": 12.0,
		"impact_frames": 6,
		"impact_fps": 14.0,
		"sprite_scale": 1.0
	},
	"dark_lightning": {
		"flight_frames": 6,
		"flight_fps": 14.0,  # Fast for electric feel
		"impact_frames": 6,
		"impact_fps": 16.0,
		"sprite_scale": 1.0,
		"rotation_offset": 30.0  # Inclinación visual de la daga eléctrica
	},
	"thunder_bloom": {
		"flight_frames": 6,
		"flight_fps": 12.0,
		"impact_frames": 6,
		"impact_fps": 14.0,
		"sprite_scale": 1.0,
		"lock_rotation": true  # Flor no rota con la dirección (siempre se ve igual)
	},
	"soul_reaper": {
		"flight_frames": 6,
		"flight_fps": 10.0,  # Slower, more menacing
		"impact_frames": 6,
		"impact_fps": 12.0,
		"sprite_scale": 1.0
	},
	"phantom_blade": {
		"flight_frames": 6,
		"flight_fps": 16.0,  # Very fast, ghostly blur
		"impact_frames": 6,
		"impact_fps": 18.0,
		"sprite_scale": 1.0
	},
	"stone_fang": {
		"flight_frames": 6,
		"flight_fps": 10.0,  # Slow, heavy obsidian projectile
		"impact_frames": 6,
		"impact_fps": 14.0,
		"sprite_scale": 1.0
	},
	"twilight": {
		"flight_frames": 6,
		"flight_fps": 10.0,  # Serene, balanced rotation
		"impact_frames": 6,
		"impact_fps": 12.0,
		"sprite_scale": 1.0
	},
	"abyss": {
		"flight_frames": 6,
		"flight_fps": 8.0,  # Very slow, ominous void maw
		"impact_frames": 6,
		"impact_fps": 10.0,
		"sprite_scale": 1.0
	},
	"pollen_storm": {
		"flight_frames": 6,
		"flight_fps": 12.0,
		"impact_frames": 6,
		"impact_fps": 14.0,
		"sprite_scale": 1.0
	},
	"sandstorm": {
		"flight_frames": 6,
		"flight_fps": 16.0,  # Fast spinning vortex
		"impact_frames": 6,
		"impact_fps": 16.0,
		"sprite_scale": 1.0,
		"lock_rotation": true  # Tornado/vortex siempre vertical
	},
	"prism_wind": {
		"flight_frames": 6,
		"flight_fps": 14.0,  # Fast, ethereal wind blade
		"impact_frames": 6,
		"impact_fps": 16.0,
		"sprite_scale": 1.0
	},
	# === ORBITAL WEAPONS ===
	"arcane_orb": {
		"orbit_frames": 8,
		"orbit_fps": 10.0,  # Smooth magical rotation
		"sprite_scale": 1.0,
		"is_orbital": true
	},
	"cosmic_barrier": {
		"orbit_frames": 8,
		"orbit_fps": 12.0,  # Divine light pulsing
		"sprite_scale": 1.0,
		"is_orbital": true
	},
	"crystal_guardian": {
		"orbit_frames": 8,
		"orbit_fps": 8.0,  # Slow, heavy crystal rotation
		"sprite_scale": 1.0,
		"is_orbital": true
	},
	"frost_orb": {
		"orbit_frames": 8,
		"orbit_fps": 10.0,  # Cold, elegant rotation
		"sprite_scale": 1.0,
		"is_orbital": true
	},
	"inferno_orb": {
		"orbit_frames": 8,
		"orbit_fps": 14.0,  # Fast, chaotic flames
		"sprite_scale": 1.0,
		"is_orbital": true
	},
	"arcane_storm": {
		"orbit_frames": 8,
		"orbit_fps": 16.0,  # Fast electric crackling
		"sprite_scale": 1.0,
		"is_orbital": true
	},
	"shadow_orbs": {
		"orbit_frames": 8,
		"orbit_fps": 8.0,  # Slow, ghostly movement
		"sprite_scale": 1.0,
		"is_orbital": true
	},
	"life_orbs": {
		"orbit_frames": 8,
		"orbit_fps": 10.0,  # Gentle breathing rhythm
		"sprite_scale": 1.0,
		"is_orbital": true
	},
	"wind_orbs": {
		"orbit_frames": 8,
		"orbit_fps": 14.0,  # Fast, airy movement
		"sprite_scale": 1.0,
		"is_orbital": true
	},
	"cosmic_void": {
		"orbit_frames": 8,
		"orbit_fps": 8.0,  # Slow, ominous pull
		"sprite_scale": 1.0,
		"is_orbital": true
	},
	# === AOE WEAPONS (Area of Effect) ===
	# Sprites: aoe_appear_[weapon].png, aoe_active_[weapon].png, aoe_fade_[weapon].png
	"earth_spike": {
		"aoe_appear_frames": 4,
		"aoe_active_frames": 6,
		"aoe_fade_frames": 4,
		"aoe_fps": 12.0,
		"sprite_scale": 1.0,
		"is_aoe": true
	},
	"void_pulse": {
		"aoe_appear_frames": 4,
		"aoe_active_frames": 6,
		"aoe_fade_frames": 4,
		"aoe_fps": 10.0,  # Slower, ominous void
		"sprite_scale": 1.0,
		"is_aoe": true
	},
	"steam_cannon": {
		"aoe_appear_frames": 4,
		"aoe_active_frames": 6,
		"aoe_fade_frames": 4,
		"aoe_fps": 14.0,  # Fast steam dispersal
		"sprite_scale": 1.0,
		"is_aoe": true
	},
	"rift_quake": {
		"aoe_appear_frames": 4,
		"aoe_active_frames": 6,
		"aoe_fade_frames": 4,
		"aoe_fps": 12.0,  # Powerful seismic
		"sprite_scale": 1.0,
		"is_aoe": true
	},
	"void_storm": {
		"aoe_appear_frames": 4,
		"aoe_active_frames": 6,
		"aoe_fade_frames": 4,
		"aoe_fps": 14.0,  # Fast vortex spin
		"sprite_scale": 1.0,
		"is_aoe": true
	},
	"glacier": {
		"aoe_appear_frames": 4,
		"aoe_active_frames": 6,
		"aoe_fade_frames": 4,
		"aoe_fps": 10.0,  # Slow, cold ice formation
		"sprite_scale": 1.0,
		"is_aoe": true
	},
	"absolute_zero": {
		"aoe_appear_frames": 4,
		"aoe_active_frames": 6,
		"aoe_fade_frames": 4,
		"aoe_fps": 8.0,  # Very slow, time-frozen
		"sprite_scale": 1.0,
		"is_aoe": true
	},
	"volcano": {
		"aoe_appear_frames": 4,
		"aoe_active_frames": 6,
		"aoe_fade_frames": 4,
		"aoe_fps": 14.0,  # Fast, violent eruption
		"sprite_scale": 1.0,
		"is_aoe": true
	},
	"dark_flame": {
		"aoe_appear_frames": 4,
		"aoe_active_frames": 6,
		"aoe_fade_frames": 4,
		"aoe_fps": 12.0,  # Sinister dark fire
		"sprite_scale": 1.0,
		"is_aoe": true
	},
	"seismic_bolt": {
		"aoe_appear_frames": 4,
		"aoe_active_frames": 6,
		"aoe_fade_frames": 4,
		"aoe_fps": 16.0,  # Fast electric shockwave
		"sprite_scale": 1.0,
		"is_aoe": true
	},
	"gaia": {
		"aoe_appear_frames": 4,
		"aoe_active_frames": 6,
		"aoe_fade_frames": 4,
		"aoe_fps": 10.0,  # Slow, organic growth
		"sprite_scale": 1.0,
		"is_aoe": true
	},
	"decay": {
		"aoe_appear_frames": 4,
		"aoe_active_frames": 6,
		"aoe_fade_frames": 4,
		"aoe_fps": 8.0,  # Slow, creeping corruption
		"sprite_scale": 1.0,
		"is_aoe": true
	},
	"radiant_stone": {
		"aoe_appear_frames": 4,
		"aoe_active_frames": 6,
		"aoe_fade_frames": 4,
		"aoe_fps": 12.0,  # Divine crystal light
		"sprite_scale": 1.0,
		"is_aoe": true
	}
}

# ═══════════════════════════════════════════════════════════════════════════════
# CARGA DE SPRITES PERSONALIZADOS
# ═══════════════════════════════════════════════════════════════════════════════

func _try_load_custom_sprites(data: ProjectileVisualData, weapon_id: String) -> void:
	"""Intentar cargar sprites personalizados para un arma si existen"""
	# Determinar la ruta base según si es arma base o fusión
	var base_path: String
	if weapon_id in BASE_WEAPONS:
		base_path = WEAPONS_SPRITES_PATH + weapon_id + "/"
	else:
		base_path = FUSION_SPRITES_PATH + weapon_id + "/"

	# Obtener configuración de frames para este arma
	var config = WEAPON_SPRITE_CONFIG.get(weapon_id, {})
	
	# ═══════════════════════════════════════════════════════════════════════════
	# SPRITES ORBITALES (para armas tipo ORBIT)
	# ═══════════════════════════════════════════════════════════════════════════
	if config.get("is_orbital", false):
		var orbit_path = base_path + "orbit_spritesheet_" + weapon_id + ".png"
		if ResourceLoader.exists(orbit_path):
			var orbit_tex = load(orbit_path) as Texture2D
			if orbit_tex:
				data.orbit_idle_spritesheet = orbit_tex
				data.orbit_idle_frames = config.get("orbit_frames", 8)
				data.orbit_fps = config.get("orbit_fps", 10.0)
				
				# Aplicar escala personalizada si está definida
				if config.has("sprite_scale"):
					data.base_scale = config.get("sprite_scale", 1.0)
				
				print("[ProjectileVisualManager] Sprites orbitales cargados para: " + weapon_id)
				return
			else:
				push_warning("[ProjectileVisualManager] No se pudo cargar orbit_spritesheet_" + weapon_id + ".png")
		# Si no hay sprites orbitales, usar procedural
		return
	
	# ═══════════════════════════════════════════════════════════════════════════
	# SPRITES AOE (para armas tipo AOE: appear + active + fade)
	# ═══════════════════════════════════════════════════════════════════════════
	if config.get("is_aoe", false):
		var appear_path = base_path + "aoe_appear_" + weapon_id + ".png"
		var active_path = base_path + "aoe_active_" + weapon_id + ".png"
		var fade_path = base_path + "aoe_fade_" + weapon_id + ".png"
		
		var appear_tex = load(appear_path) as Texture2D if ResourceLoader.exists(appear_path) else null
		var active_tex = load(active_path) as Texture2D if ResourceLoader.exists(active_path) else null
		var fade_tex = load(fade_path) as Texture2D if ResourceLoader.exists(fade_path) else null
		
		if appear_tex or active_tex or fade_tex:
			# Al menos uno de los sprites AOE existe
			if appear_tex:
				data.aoe_appear_spritesheet = appear_tex
				data.aoe_appear_frames = config.get("aoe_appear_frames", 4)
			if active_tex:
				data.aoe_active_spritesheet = active_tex
				data.aoe_active_frames = config.get("aoe_active_frames", 6)
			if fade_tex:
				data.aoe_fade_spritesheet = fade_tex
				data.aoe_fade_frames = config.get("aoe_fade_frames", 4)
			
			data.aoe_fps = config.get("aoe_fps", 12.0)
			
			# Aplicar escala personalizada si está definida
			if config.has("sprite_scale"):
				data.base_scale = config.get("sprite_scale", 1.0)
			
			print("[ProjectileVisualManager] Sprites AOE cargados para: " + weapon_id)
			return
		# Si no hay sprites AOE, usar procedural
		return

	# ═══════════════════════════════════════════════════════════════════════════
	# SPRITES DE PROYECTIL NORMAL (flight + impact)
	# ═══════════════════════════════════════════════════════════════════════════
	var flight_path = base_path + "flight_spritesheet_" + weapon_id + ".png"
	if not ResourceLoader.exists(flight_path):
		return  # No hay sprites personalizados, usar procedural

	# Cargar sprites (solo flight e impact son requeridos)
	var flight_tex = load(flight_path) as Texture2D
	var impact_tex = load(base_path + "impact_spritesheet_" + weapon_id + ".png") as Texture2D

	if flight_tex == null:
		push_warning("[ProjectileVisualManager] No se pudo cargar flight_spritesheet_" + weapon_id + ".png")
		return

	# NOTA: launch.png ya no se usa - los proyectiles empiezan directamente en flight

	# Configurar sprites de vuelo
	data.flight_spritesheet = flight_tex
	data.flight_frames = config.get("flight_frames", 6)
	data.flight_fps = config.get("flight_fps", 12.0)
	data.flight_loop = true

	# Configurar sprites de impacto
	if impact_tex:
		data.impact_spritesheet = impact_tex
		data.impact_frames = config.get("impact_frames", 6)
		data.impact_fps = config.get("impact_fps", 15.0)
		data.impact_loop = false

	# Aplicar escala personalizada si está definida
	if config.has("sprite_scale"):
		data.base_scale = config.get("sprite_scale", 1.0)

	# Aplicar tamaño de frame personalizado si está definido
	if config.has("frame_size"):
		var fs = config.get("frame_size", 64)
		data.frame_size = Vector2i(fs, fs)

	print("[ProjectileVisualManager] Sprites personalizados cargados para: " + weapon_id)

# ═══════════════════════════════════════════════════════════════════════════════
# OBTENER DATOS VISUALES
# ═══════════════════════════════════════════════════════════════════════════════

func get_visual_data(weapon_id: String, weapon_data: Dictionary = {}) -> ProjectileVisualData:
	"""Obtener o crear datos visuales para un arma específica"""
	if _visual_data_cache.has(weapon_id):
		return _visual_data_cache[weapon_id]

	# Crear datos visuales únicos para esta arma
	var data = _create_weapon_visual_data(weapon_id, weapon_data)
	_visual_data_cache[weapon_id] = data
	return data

func _create_weapon_visual_data(weapon_id: String, weapon_data: Dictionary) -> ProjectileVisualData:
	"""Crear datos visuales ÚNICOS para cada arma"""
	var data = ProjectileVisualData.new()

	# ═══════════════════════════════════════════════════════════════════════════
	# PASO 1: Valores por defecto (se pueden sobrescribir después)
	# ═══════════════════════════════════════════════════════════════════════════
	data.base_scale = 1.0
	data.frame_size = Vector2i(64, 64)

	# ═══════════════════════════════════════════════════════════════════════════
	# PASO 2: Configuración específica del arma
	# ═══════════════════════════════════════════════════════════════════════════
	if WEAPON_VISUALS.has(weapon_id):
		var config = WEAPON_VISUALS[weapon_id]
		data.id = weapon_id
		data.primary_color = config.get("primary", Color.WHITE)
		data.secondary_color = config.get("secondary", Color.GRAY)
		data.accent_color = config.get("accent", Color.WHITE)
		data.outline_color = config.get("outline", Color.BLACK)
		data.glow_color = config.get("glow", Color(1, 1, 1, 0.5))
		data.trail_enabled = true
		data.trail_length = 0.35
		data.trail_color = config.get("trail_color", data.glow_color)
		data.glow_enabled = true
		data.glow_intensity = 0.5

		# Guardar shape y efectos especiales en metadata
		data.set_meta("shape", config.get("shape", "orb"))
		data.set_meta("particles", config.get("particles", "default"))
		data.set_meta("rotation_speed", config.get("rotation_speed", 0.0))
		data.set_meta("squash_amount", config.get("squash_amount", 0.1))
	else:
		# Fallback: generar desde el weapon_data
		data.id = weapon_id
		data.primary_color = Color(0.6, 0.6, 0.8)
		data.secondary_color = Color(0.4, 0.4, 0.6)
		data.accent_color = Color.WHITE
		data.outline_color = Color(0.2, 0.2, 0.3)
		data.glow_color = Color(0.5, 0.5, 0.7, 0.5)
		data.trail_enabled = true
		data.glow_enabled = true
		data.set_meta("shape", "orb")
		data.set_meta("rotation_speed", 0.0)
		data.set_meta("squash_amount", 0.1)

	# ═══════════════════════════════════════════════════════════════════════════
	# PASO 3: Determinar estilo según tipo de proyectil
	# ═══════════════════════════════════════════════════════════════════════════
	var proj_type_int = weapon_data.get("projectile_type", 0)
	if proj_type_int is int:
		data.style = PROJECTILE_TYPE_MAP.get(proj_type_int, ProjectileVisualData.ProjectileStyle.SINGLE)
	else:
		data.style = ProjectileVisualData.ProjectileStyle.SINGLE

	# ═══════════════════════════════════════════════════════════════════════════
	# PASO 4: Cargar sprites personalizados (ÚLTIMO - puede sobrescribir escala)
	# ═══════════════════════════════════════════════════════════════════════════
	_try_load_custom_sprites(data, weapon_id)

	return data

# ═══════════════════════════════════════════════════════════════════════════════
# CREAR EFECTOS VISUALES
# ═══════════════════════════════════════════════════════════════════════════════

func create_projectile_visual(weapon_id: String, weapon_data: Dictionary = {}) -> AnimatedProjectileSprite:
	"""Crear sprite animado para proyectil normal"""
	var visual_data = get_visual_data(weapon_id, weapon_data)
	var sprite = AnimatedProjectileSprite.new()
	sprite.setup(visual_data)

	# Aplicar configuraciones especiales si están definidas para este arma
	if WEAPON_SPRITE_CONFIG.has(weapon_id):
		var config = WEAPON_SPRITE_CONFIG[weapon_id]
		if config.has("rotation_offset"):
			sprite.set_rotation_offset(config["rotation_offset"])
		if config.get("lock_rotation", false):
			sprite.set_lock_rotation(true)

	return sprite

func create_aoe_visual(weapon_id: String, radius: float, duration: float = 0.5,
		weapon_data: Dictionary = {}) -> AOEVisualEffect:
	"""Crear efecto visual AOE"""
	var visual_data = get_visual_data(weapon_id, weapon_data)
	var effect = AOEVisualEffect.new()
	effect.setup(visual_data, radius, duration)
	return effect

func create_beam_visual(weapon_id: String, length: float, direction: Vector2,
		width: float = 12.0, weapon_data: Dictionary = {}) -> BeamVisualEffect:
	"""Crear efecto visual de rayo"""
	var visual_data = get_visual_data(weapon_id, weapon_data)
	var effect = BeamVisualEffect.new()
	effect.setup(visual_data, length, direction, width)
	return effect

func create_chain_visual(weapon_id: String, chain_count: int = 2, weapon_data: Dictionary = {}) -> Node2D:
	"""Crear efecto visual de cadena de rayos - cada arma tiene su propia clase"""
	var visual_data = get_visual_data(weapon_id, weapon_data)

	match weapon_id:
		"frozen_thunder":
			var effect = FrozenThunderVisual.new()
			effect.setup(visual_data, chain_count)
			return effect
		"plasma":
			var effect = PlasmaVisual.new()
			effect.setup(visual_data, chain_count)
			return effect
		"storm_caller":
			var effect = StormCallerVisual.new()
			effect.setup(visual_data, chain_count)
			return effect
		"void_bolt":
			var effect = VoidBoltVisual.new()
			effect.setup(visual_data, chain_count)
			return effect
		_:  # Default: lightning_wand y otros
			var effect = ChainLightningVisual.new()
			effect.setup(visual_data, weapon_id, chain_count)
			return effect

func create_orbit_visual(weapon_id: String, orbital_count: int, orbit_radius: float,
		weapon_data: Dictionary = {}) -> OrbitalsVisualContainer:
	"""Crear contenedor con múltiples orbes visuales"""
	var visual_data = get_visual_data(weapon_id, weapon_data)
	var container = OrbitalsVisualContainer.new()
	container.setup(visual_data, orbital_count, orbit_radius, 24.0)
	return container

# ═══════════════════════════════════════════════════════════════════════════════
# UTILIDADES
# ═══════════════════════════════════════════════════════════════════════════════

func clear_cache() -> void:
	"""Limpiar cache de datos visuales"""
	_visual_data_cache.clear()

func get_weapon_shape(weapon_id: String) -> String:
	"""Obtener la forma del proyectil para un arma"""
	if WEAPON_VISUALS.has(weapon_id):
		return WEAPON_VISUALS[weapon_id].get("shape", "orb")
	return "orb"

func get_weapon_particles(weapon_id: String) -> String:
	"""Obtener el tipo de partículas para un arma"""
	if WEAPON_VISUALS.has(weapon_id):
		return WEAPON_VISUALS[weapon_id].get("particles", "default")
	return "default"

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
	
	"frostfire": {  # Ice + Void
		"shape": "entropy_shard",
		"primary": Color(0.4, 0.6, 0.85),
		"secondary": Color(0.2, 0.15, 0.4),
		"accent": Color(0.7, 0.85, 1.0),
		"outline": Color(0.15, 0.1, 0.3),
		"glow": Color(0.45, 0.55, 0.8, 0.5),
		"trail_color": Color(0.4, 0.5, 0.8, 0.45),
		"particles": "void_frost",
		"rotation_speed": -0.8,
		"squash_amount": 0.15
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
	
	"wildfire": {  # Fire + Shadow
		"shape": "dark_flame",
		"primary": Color(0.8, 0.3, 0.1),
		"secondary": Color(0.3, 0.1, 0.15),
		"accent": Color(1.0, 0.6, 0.2),
		"outline": Color(0.2, 0.05, 0.05),
		"glow": Color(0.7, 0.25, 0.1, 0.5),
		"trail_color": Color(0.6, 0.2, 0.1, 0.5),
		"particles": "shadow_flames",
		"rotation_speed": 0.0,
		"squash_amount": 0.18
	},
	
	"firestorm": {  # Fire + Nature
		"shape": "burning_seed",
		"primary": Color(1.0, 0.6, 0.2),
		"secondary": Color(0.5, 0.7, 0.2),
		"accent": Color(1.0, 0.9, 0.4),
		"outline": Color(0.4, 0.3, 0.1),
		"glow": Color(0.9, 0.6, 0.25, 0.5),
		"trail_color": Color(0.85, 0.55, 0.2, 0.45),
		"particles": "burning_leaves",
		"rotation_speed": 0.5,
		"squash_amount": 0.12
	},
	
	"volcano": {  # Fire + Wind
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
	
	"hellfire": {  # Fire + Void
		"shape": "chaos_flame",
		"primary": Color(0.7, 0.2, 0.4),
		"secondary": Color(0.2, 0.05, 0.15),
		"accent": Color(1.0, 0.5, 0.3),
		"outline": Color(0.15, 0.05, 0.1),
		"glow": Color(0.65, 0.2, 0.35, 0.55),
		"trail_color": Color(0.6, 0.15, 0.3, 0.5),
		"particles": "void_flames",
		"rotation_speed": -0.5,
		"squash_amount": 0.2
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
	
	"dark_lightning": {  # Lightning + Nature
		"shape": "thunder_leaf",
		"primary": Color(0.45, 0.75, 0.6),
		"secondary": Color(0.6, 0.9, 0.7),
		"accent": Color(0.9, 1.0, 0.95),
		"outline": Color(0.2, 0.4, 0.3),
		"glow": Color(0.5, 0.8, 0.65, 0.45),
		"trail_color": Color(0.55, 0.85, 0.7, 0.4),
		"particles": "electric_pollen",
		"rotation_speed": 0.0,
		"squash_amount": 0.12
	},
	
	"thunder_bloom": {  # Lightning + Wind
		"shape": "wind_bolt",
		"primary": Color(0.6, 0.9, 0.95),
		"secondary": Color(0.75, 0.95, 1.0),
		"accent": Color(1.0, 1.0, 1.0),
		"outline": Color(0.3, 0.5, 0.55),
		"glow": Color(0.65, 0.9, 0.95, 0.5),
		"trail_color": Color(0.7, 0.95, 1.0, 0.4),
		"particles": "wind_sparks",
		"rotation_speed": 6.0,
		"squash_amount": 0.1
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
	
	"void_bolt": {  # Lightning + Void
		"shape": "entropy_bolt",
		"primary": Color(0.35, 0.25, 0.6),
		"secondary": Color(0.15, 0.1, 0.3),
		"accent": Color(0.6, 0.7, 0.95),
		"outline": Color(0.1, 0.08, 0.2),
		"glow": Color(0.4, 0.3, 0.6, 0.5),
		"trail_color": Color(0.35, 0.25, 0.55, 0.45),
		"particles": "void_sparks",
		"rotation_speed": -2.0,
		"squash_amount": 0.2
	},
	
	# ══════════════════════════════════════════════════════════════════════════
	# FUSIONES ARCANE (5)
	# ══════════════════════════════════════════════════════════════════════════
	
	"void_orbs": {  # Arcane + Shadow
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
	
	"earthquake": {  # Earth + Light
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
# NOTA: Solo se requieren flight.png e impact.png. launch.png es opcional y no se usa.
const WEAPON_SPRITE_CONFIG: Dictionary = {
	"ice_wand": {
		"flight_frames": 6,
		"flight_fps": 12.0,
		"impact_frames": 6,
		"impact_fps": 15.0,
		"sprite_scale": 0.5,
		"rotation_offset": 30.0  # Corregir eje desviado del sprite (grados)
	},
	"fire_wand": {
		"flight_frames": 6,
		"flight_fps": 12.0,
		"impact_frames": 6,
		"impact_fps": 15.0,
		"sprite_scale": 0.5
	},
	"nature_staff": {
		"flight_frames": 6,
		"flight_fps": 12.0,
		"impact_frames": 6,
		"impact_fps": 15.0,
		"sprite_scale": 0.5
	},
	"wind_blade": {
		"flight_frames": 6,
		"flight_fps": 12.0,
		"impact_frames": 6,
		"impact_fps": 15.0,
		"sprite_scale": 0.5
	},
	# === FUSION WEAPONS ===
	"frostbite": {
		"flight_frames": 6,
		"flight_fps": 12.0,
		"impact_frames": 6,
		"impact_fps": 15.0,
		"sprite_scale": 0.5
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
	
	# Verificar si existe el archivo de vuelo (mínimo requerido)
	var flight_path = base_path + "flight.png"
	if not ResourceLoader.exists(flight_path):
		return  # No hay sprites personalizados, usar procedural
	
	# Cargar sprites (solo flight e impact son requeridos, launch es opcional)
	var flight_tex = load(flight_path) as Texture2D
	var impact_tex = load(base_path + "impact.png") as Texture2D
	
	if flight_tex == null:
		push_warning("[ProjectileVisualManager] No se pudo cargar flight.png para " + weapon_id)
		return
	
	# Obtener configuración de frames para este arma
	var config = WEAPON_SPRITE_CONFIG.get(weapon_id, {})
	
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
	
	# Aplicar rotation_offset si está configurado para este arma
	if WEAPON_SPRITE_CONFIG.has(weapon_id):
		var config = WEAPON_SPRITE_CONFIG[weapon_id]
		if config.has("rotation_offset"):
			sprite.set_rotation_offset(config["rotation_offset"])
	
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

func create_chain_visual(weapon_id: String, chain_count: int = 2, weapon_data: Dictionary = {}) -> ChainLightningVisual:
	"""Crear efecto visual de cadena de rayos"""
	var visual_data = get_visual_data(weapon_id, weapon_data)
	var effect = ChainLightningVisual.new()
	effect.setup(visual_data)
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

# CharacterDatabase.gd
# Database of all playable characters
# Each character has unique stats and a different starting weapon

extends Node
class_name CharacterDatabase

# =============================================================================
# CONSTANTS
# =============================================================================

# Unlock states
enum UnlockStatus {
	LOCKED,           # Blocked, not available
	UNLOCKED,         # Unlocked and playable
	STARTER           # Available from the start
}

# Elements (matches WeaponDatabase.Element)
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

# =============================================================================
# CHARACTER DATABASE (10 characters)
# =============================================================================

const CHARACTERS: Dictionary = {
	# -------------------------------------------------------------------------
	# FROST MAGE - Ice Mage (STARTER)
	# Control and enemy slowdown
	# -------------------------------------------------------------------------
	"frost_mage": {
		"id": "frost_mage",
		"name": "Frost Mage",
		"name_es": "Mago de Hielo",
		"title": "The Frozen One",
		"title_es": "El Congelado",
		"description": "A wise wizard who harnesses the power of ice to slow and freeze enemies.",
		"description_es": "Un sabio mago que controla el poder del hielo para ralentizar y congelar enemigos.",

		# Element and starting weapon
		"element": Element.ICE,
		"starting_weapon": "ice_wand",

		# Base stats (balanced)
		"stats": {
			"max_health": 100,
			"health_regen": 0.0,
			"move_speed": 120.0,
			"armor": 0,
			"damage_mult": 1.0,
			"cooldown_mult": 1.0,
			"area_mult": 1.0,
			"pickup_range": 50.0,
			"luck": 0.0,
			"xp_mult": 1.0
		},

		# Unique passive
		"passive": {
			"id": "frozen_aura",
			"name": "Frozen Aura",
			"name_es": "Aura Gelida",
			"description": "Enemies near you are slowed by 10%",
			"description_es": "Los enemigos cercanos son ralentizados un 10%"
		},

		# Unlock
		"unlock_status": UnlockStatus.STARTER,
		"unlock_requirement": null,

		# Visual
		"color_primary": Color(0.4, 0.8, 1.0),      # Ice blue
		"color_secondary": Color(0.3, 0.6, 0.9),    # Deep blue
		"icon": "??",
		"sprite_folder": "wizard",  # Uses current wizard sprites
		"portrait": "res://assets/sprites/players/portraits/frost_mage.png"
	},

	# -------------------------------------------------------------------------
	# PYROMANCER - Fire Mage (STARTER)
	# High damage, burns enemies
	# -------------------------------------------------------------------------
	"pyromancer": {
		"id": "pyromancer",
		"name": "Pyromancer",
		"name_es": "Piromante",
		"title": "The Flame Bringer",
		"title_es": "El Portador de Llamas",
		"description": "A fierce mage who wields devastating fire magic, burning all in his path.",
		"description_es": "Un mago feroz que usa magia de fuego devastadora, quemando todo a su paso.",

		"element": Element.FIRE,
		"starting_weapon": "fire_wand",

		# Stats (high damage, less health)
		"stats": {
			"max_health": 90,
			"health_regen": 0.0,
			"move_speed": 125.0,
			"armor": 0,
			"damage_mult": 1.15,  # +15% damage
			"cooldown_mult": 1.0,
			"area_mult": 1.1,   # +10% area (explosions)
			"pickup_range": 50.0,
			"luck": 0.0,
			"xp_mult": 1.0
		},

		"passive": {
			"id": "burning_soul",
			"name": "Burning Soul",
			"name_es": "Alma Ardiente",
			"description": "Fire damage burns 20% longer",
			"description_es": "El dano de fuego quema un 20% mas de tiempo"
		},

		"unlock_status": UnlockStatus.STARTER,
		"unlock_requirement": null,

		"color_primary": Color(1.0, 0.4, 0.1),      # Fire orange
		"color_secondary": Color(1.0, 0.2, 0.0),    # Intense red
		"icon": "??",
		"sprite_folder": "pyromancer",
		"portrait": "res://assets/sprites/players/portraits/pyromancer.png"
	},

	# -------------------------------------------------------------------------
	# STORM CALLER - Lightning Mage (STARTER)
	# Fast, chain damage
	# -------------------------------------------------------------------------
	"storm_caller": {
		"id": "storm_caller",
		"name": "Storm Caller",
		"name_es": "Invocador de Tormentas",
		"title": "The Thunder Born",
		"title_es": "El Nacido del Trueno",
		"description": "A swift mage who commands lightning, striking multiple foes at once.",
		"description_es": "Un mago veloz que controla el rayo, golpeando multiples enemigos a la vez.",

		"element": Element.LIGHTNING,
		"starting_weapon": "lightning_wand",

		# Stats (fast, less health)
		"stats": {
			"max_health": 85,
			"health_regen": 0.0,
			"move_speed": 135.0,  # Fast
			"armor": 0,
			"damage_mult": 1.0,
			"cooldown_mult": 0.95,  # -5% cooldown
			"area_mult": 1.0,
			"pickup_range": 55.0,
			"luck": 0.05,  # +5% luck (crits)
			"xp_mult": 1.0
		},

		"passive": {
			"id": "static_charge",
			"name": "Static Charge",
			"name_es": "Carga Estatica",
			"description": "Lightning chains to 1 additional enemy",
			"description_es": "Los rayos saltan a 1 enemigo adicional"
		},

		"unlock_status": UnlockStatus.STARTER,
		"unlock_requirement": null,

		"color_primary": Color(1.0, 1.0, 0.3),      # Electric yellow
		"color_secondary": Color(0.6, 0.4, 1.0),    # Storm purple
		"icon": "?",
		"sprite_folder": "storm_caller",
		"portrait": "res://assets/sprites/players/portraits/storm_caller.png"
	},

	# -------------------------------------------------------------------------
	# ARCANIST - Arcane Mage (UNLOCKABLE)
	# Defensive, orbitals
	# -------------------------------------------------------------------------
	"arcanist": {
		"id": "arcanist",
		"name": "Arcanist",
		"name_es": "Arcanista",
		"title": "The Mystic Scholar",
		"title_es": "El Erudito Mistico",
		"description": "A defensive mage surrounded by arcane orbs that protect and damage.",
		"description_es": "Un mago defensivo rodeado de orbes arcanos que protegen y danan.",

		"element": Element.ARCANE,
		"starting_weapon": "arcane_orb",

		# Stats (defensive, slow)
		"stats": {
			"max_health": 110,
			"health_regen": 0.5,  # Light regen
			"move_speed": 105.0,
			"armor": 5,  # Some armor
			"damage_mult": 0.95,
			"cooldown_mult": 1.0,
			"area_mult": 1.15,  # +15% orbital area
			"pickup_range": 60.0,
			"luck": 0.0,
			"xp_mult": 1.0
		},

		"passive": {
			"id": "arcane_shield",
			"name": "Arcane Shield",
			"name_es": "Escudo Arcano",
			"description": "Start with +1 orbital projectile",
			"description_es": "Comienza con +1 proyectil orbital"
		},

		"unlock_status": UnlockStatus.LOCKED,
		"unlock_requirement": {
			"type": "total_runs",
			"value": 10,
			"description": "Complete 10 runs",
			"description_es": "Completa 10 partidas"
		},

		"color_primary": Color(0.7, 0.3, 1.0),      # Arcane purple
		"color_secondary": Color(0.5, 0.2, 0.8),    # Dark purple
		"icon": "??",
		"sprite_folder": "arcanist",
		"portrait": "res://assets/sprites/players/portraits/arcanist.png"
	},

	# -------------------------------------------------------------------------
	# SHADOW BLADE - Shadow Assassin (UNLOCKABLE)
	# Very fast, very fragile
	# -------------------------------------------------------------------------
	"shadow_blade": {
		"id": "shadow_blade",
		"name": "Shadow Blade",
		"name_es": "Hoja Sombria",
		"title": "The Phantom",
		"title_es": "El Fantasma",
		"description": "A deadly assassin who strikes from the shadows with piercing daggers.",
		"description_es": "Un asesino letal que golpea desde las sombras con dagas perforantes.",

		"element": Element.SHADOW,
		"starting_weapon": "shadow_dagger",

		# Stats (extreme glass cannon)
		"stats": {
			"max_health": 70,  # Very fragile
			"health_regen": 0.0,
			"move_speed": 145.0,  # Very fast
			"armor": 0,
			"damage_mult": 1.2,  # +20% damage
			"cooldown_mult": 0.9,  # -10% cooldown
			"area_mult": 0.9,
			"pickup_range": 45.0,
			"luck": 0.1,  # +10% luck (crits)
			"xp_mult": 1.0
		},

		"passive": {
			"id": "shadow_step",
			"name": "Shadow Step",
			"name_es": "Paso Umbrio",
			"description": "+1 pierce on all projectiles",
			"description_es": "+1 penetracion en todos los proyectiles"
		},

		"unlock_status": UnlockStatus.LOCKED,
		"unlock_requirement": {
			"type": "kills_total",
			"value": 5000,
			"description": "Defeat 5000 enemies total",
			"description_es": "Derrota 5000 enemigos en total"
		},

		"color_primary": Color(0.3, 0.1, 0.4),      # Dark purple
		"color_secondary": Color(0.1, 0.05, 0.15),  # Black
		"icon": "???",
		"sprite_folder": "shadow_blade",
		"portrait": "res://assets/sprites/players/portraits/shadow_blade.png"
	},

	# -------------------------------------------------------------------------
	# DRUID - Nature Druid (UNLOCKABLE)
	# Regeneration, balanced
	# -------------------------------------------------------------------------
	"druid": {
		"id": "druid",
		"name": "Druid",
		"name_es": "Druida",
		"title": "The Nature Guardian",
		"title_es": "El Guardian de la Naturaleza",
		"description": "A peaceful guardian who heals through nature and uses homing magic.",
		"description_es": "Un guardian pacifico que sana mediante la naturaleza y usa magia rastreadora.",

		"element": Element.NATURE,
		"starting_weapon": "nature_staff",

		# Stats (regen and balance)
		"stats": {
			"max_health": 100,
			"health_regen": 1.5,  # High regen
			"move_speed": 110.0,
			"armor": 0,
			"damage_mult": 0.95,
			"cooldown_mult": 1.0,
			"area_mult": 1.0,
			"pickup_range": 70.0,  # Higher pickup range
			"luck": 0.0,
			"xp_mult": 1.1  # +10% XP
		},

		"passive": {
			"id": "natures_blessing",
			"name": "Nature's Blessing",
			"name_es": "Bendicion Natural",
			"description": "Heal 1 HP when collecting experience",
			"description_es": "Cura 1 PV al recoger experiencia"
		},

		"unlock_status": UnlockStatus.LOCKED,
		"unlock_requirement": {
			"type": "survive_time",
			"value": 900,  # 15 minutes
			"description": "Survive for 15 minutes in a single run",
			"description_es": "Sobrevive 15 minutos en una sola partida"
		},

		"color_primary": Color(0.3, 0.8, 0.2),      # Nature green
		"color_secondary": Color(0.2, 0.5, 0.1),    # Dark green
		"icon": "??",
		"sprite_folder": "druid",
		"portrait": "res://assets/sprites/players/portraits/druid.png"
	},

	# -------------------------------------------------------------------------
	# WIND RUNNER - Wind Runner (UNLOCKABLE)
	# Extremely fast
	# -------------------------------------------------------------------------
	"wind_runner": {
		"id": "wind_runner",
		"name": "Wind Runner",
		"name_es": "Corredor del Viento",
		"title": "The Swift",
		"title_es": "El Veloz",
		"description": "The fastest mage, using wind magic to outrun any danger.",
		"description_es": "El mago mas rapido, usando magia de viento para escapar de cualquier peligro.",

		"element": Element.WIND,
		"starting_weapon": "wind_blade",

		# Stats (extreme speed)
		"stats": {
			"max_health": 80,
			"health_regen": 0.0,
			"move_speed": 150.0,  # The fastest
			"armor": 0,
			"damage_mult": 0.9,   # Less damage
			"cooldown_mult": 0.95,
			"area_mult": 1.0,
			"pickup_range": 80.0,  # Big range
			"luck": 0.0,
			"xp_mult": 1.0
		},

		"passive": {
			"id": "tailwind",
			"name": "Tailwind",
			"name_es": "Viento de Cola",
			"description": "Move 15% faster when below 50% HP",
			"description_es": "Muevete 15% mas rapido bajo 50% de vida"
		},

		"unlock_status": UnlockStatus.LOCKED,
		"unlock_requirement": {
			"type": "level_reached",
			"value": 30,
			"description": "Reach level 30 in a single run",
			"description_es": "Alcanza nivel 30 en una sola partida"
		},

		"color_primary": Color(0.8, 0.95, 0.9),     # White greenish
		"color_secondary": Color(0.6, 0.9, 0.85),   # Light cyan
		"icon": "??",
		"sprite_folder": "wind_runner",
		"portrait": "res://assets/sprites/players/portraits/wind_runner.png"
	},

	# -------------------------------------------------------------------------
	# GEOMANCER - Earth Geomancer (UNLOCKABLE)
	# Slow tank
	# -------------------------------------------------------------------------
	"geomancer": {
		"id": "geomancer",
		"name": "Geomancer",
		"name_es": "Geomante",
		"title": "The Mountain",
		"title_es": "La Montana",
		"description": "An immovable tank who crushes enemies with devastating earth magic.",
		"description_es": "Un tanque inamovible que aplasta enemigos con magia de tierra devastadora.",

		"element": Element.EARTH,
		"starting_weapon": "earth_spike",

		# Stats (extreme tank)
		"stats": {
			"max_health": 150,  # Lots of health
			"health_regen": 0.5,
			"move_speed": 90.0,  # Very slow
			"armor": 15,  # Lots of armor
			"damage_mult": 1.1,
			"cooldown_mult": 1.1,  # Slower attacks
			"area_mult": 1.2,
			"pickup_range": 40.0,  # Low range
			"luck": 0.0,
			"xp_mult": 0.9  # -10% XP
		},

		"passive": {
			"id": "stone_skin",
			"name": "Stone Skin",
			"name_es": "Piel de Piedra",
			"description": "Take 20% less damage when standing still",
			"description_es": "Recibe 20% menos dano al estar quieto"
		},

		"unlock_status": UnlockStatus.LOCKED,
		"unlock_requirement": {
			"type": "damage_taken",
			"value": 10000,
			"description": "Take 10000 total damage across all runs",
			"description_es": "Recibe 10000 de dano total entre todas las partidas"
		},

		"color_primary": Color(0.6, 0.4, 0.2),      # Earth brown
		"color_secondary": Color(0.4, 0.3, 0.15),   # Dark brown
		"icon": "??",
		"sprite_folder": "geomancer",
		"portrait": "res://assets/sprites/players/portraits/geomancer.png"
	},

	# -------------------------------------------------------------------------
	# PALADIN - Light Paladin (UNLOCKABLE)
	# Balanced tank with crits
	# -------------------------------------------------------------------------
	"paladin": {
		"id": "paladin",
		"name": "Paladin",
		"name_es": "Paladin",
		"title": "The Light Bringer",
		"title_es": "El Portador de Luz",
		"description": "A holy warrior who smites enemies with pure light and critical strikes.",
		"description_es": "Un guerrero sagrado que castiga enemigos con luz pura y golpes criticos.",

		"element": Element.LIGHT,
		"starting_weapon": "light_beam",

		# Stats (tank with crits)
		"stats": {
			"max_health": 120,
			"health_regen": 0.3,
			"move_speed": 105.0,
			"armor": 5,
			"damage_mult": 1.0,
			"cooldown_mult": 1.05,
			"area_mult": 0.9,
			"pickup_range": 50.0,
			"luck": 0.15,  # +15% luck (crits)
			"xp_mult": 1.0
		},

		"passive": {
			"id": "divine_judgment",
			"name": "Divine Judgment",
			"name_es": "Juicio Divino",
			"description": "Critical hits deal 50% more damage",
			"description_es": "Los criticos hacen 50% mas de dano"
		},

		"unlock_status": UnlockStatus.LOCKED,
		"unlock_requirement": {
			"type": "bosses_defeated",
			"value": 10,
			"description": "Defeat 10 bosses",
			"description_es": "Derrota 10 jefes"
		},

		"color_primary": Color(1.0, 1.0, 0.9),      # White gold
		"color_secondary": Color(1.0, 0.9, 0.5),    # Gold
		"icon": "?",
		"sprite_folder": "paladin",
		"portrait": "res://assets/sprites/players/portraits/paladin.png"
	},

	# -------------------------------------------------------------------------
	# VOID WALKER - Void Walker (UNLOCKABLE)
	# High risk/reward
	# -------------------------------------------------------------------------
	"void_walker": {
		"id": "void_walker",
		"name": "Void Walker",
		"name_es": "Caminante del Vacio",
		"title": "The Abyss Touched",
		"title_es": "El Tocado por el Abismo",
		"description": "A mysterious mage who traded his health for immense void power.",
		"description_es": "Un mago misterioso que cambio su salud por inmenso poder del vacio.",

		"element": Element.VOID,
		"starting_weapon": "void_pulse",

		# Stats (glass cannon with special mechanics)
		"stats": {
			"max_health": 60,  # Very fragile
			"health_regen": -0.5,  # LOSES health constantly
			"move_speed": 120.0,
			"armor": 0,
			"damage_mult": 1.3,  # +30% damage
			"cooldown_mult": 0.85,  # -15% cooldown
			"area_mult": 1.25,
			"pickup_range": 100.0,  # Attracts pickups
			"luck": 0.0,
			"xp_mult": 1.2  # +20% XP
		},

		"passive": {
			"id": "void_hunger",
			"name": "Void Hunger",
			"name_es": "Hambre del Vacio",
			"description": "Killing enemies heals 2 HP, but lose 0.5 HP/sec",
			"description_es": "Matar enemigos cura 2 PV, pero pierdes 0.5 PV/seg"
		},

		"unlock_status": UnlockStatus.LOCKED,
		"unlock_requirement": {
			"type": "all_weapons_collected",
			"value": 1,  # Boolean-like
			"description": "Collect all 10 base weapons in a single run",
			"description_es": "Recoge las 10 armas base en una sola partida"
		},

		"color_primary": Color(0.2, 0.0, 0.3),      # Void purple
		"color_secondary": Color(0.1, 0.0, 0.2),    # Purple black
		"icon": "??",
		"sprite_folder": "void_walker",
		"portrait": "res://assets/sprites/players/portraits/void_walker.png"
	}
}

# =============================================================================
# ACCESS FUNCTIONS
# =============================================================================

static func get_character(character_id: String) -> Dictionary:
	"""Get character data by ID"""
	if CHARACTERS.has(character_id):
		return CHARACTERS[character_id].duplicate(true)
	push_error("[CharacterDatabase] Character not found: " + character_id)
	return {}

static func get_all_characters() -> Array:
	"""Get array with all characters"""
	var result = []
	for char_id in CHARACTERS:
		result.append(CHARACTERS[char_id].duplicate(true))
	return result

static func get_starter_characters() -> Array:
	"""Get characters available from the start"""
	var result = []
	for char_id in CHARACTERS:
		if CHARACTERS[char_id].unlock_status == UnlockStatus.STARTER:
			result.append(CHARACTERS[char_id].duplicate(true))
	return result

static func get_unlocked_characters(save_data: Dictionary = {}) -> Array:
	"""Get unlocked characters (starter + unlocked)"""
	var result = []
	var unlocked_ids = save_data.get("unlocked_characters", [])

	for char_id in CHARACTERS:
		var char_data = CHARACTERS[char_id]
		if char_data.unlock_status == UnlockStatus.STARTER:
			result.append(char_data.duplicate(true))
		elif char_data.unlock_status == UnlockStatus.UNLOCKED:
			result.append(char_data.duplicate(true))
		elif char_id in unlocked_ids:
			var data = char_data.duplicate(true)
			data.unlock_status = UnlockStatus.UNLOCKED
			result.append(data)

	return result

static func get_character_ids() -> Array:
	"""Get array with all character IDs"""
	return CHARACTERS.keys()

static func get_starting_weapon(character_id: String) -> String:
	"""Get the starting weapon for a character"""
	if CHARACTERS.has(character_id):
		return CHARACTERS[character_id].starting_weapon
	return "ice_wand"  # Default

static func get_character_stats(character_id: String) -> Dictionary:
	"""Get base stats for a character"""
	if CHARACTERS.has(character_id):
		return CHARACTERS[character_id].stats.duplicate(true)
	# Default stats
	return {
		"max_health": 100,
		"health_regen": 0.0,
		"move_speed": 200.0,
		"armor": 0,
		"damage_mult": 1.0,
		"cooldown_mult": 1.0,
		"area_mult": 1.0,
		"pickup_range": 50.0,
		"luck": 0.0,
		"xp_mult": 1.0
	}

static func check_unlock_requirement(character_id: String, player_stats: Dictionary) -> bool:
	"""Check if a character meets unlock requirements"""
	if not CHARACTERS.has(character_id):
		return false

	var char_data = CHARACTERS[character_id]

	# Starters always available
	if char_data.unlock_status == UnlockStatus.STARTER:
		return true

	var req = char_data.get("unlock_requirement")
	if not req:
		return false

	var req_type = req.get("type", "")
	var req_value = req.get("value", 0)

	match req_type:
		"total_runs":
			return player_stats.get("total_runs", 0) >= req_value
		"kills_total":
			return player_stats.get("enemies_defeated", 0) >= req_value
		"survive_time":
			return player_stats.get("best_time", 0) >= req_value
		"level_reached":
			return player_stats.get("best_level", 0) >= req_value
		"damage_taken":
			return player_stats.get("total_damage_taken", 0) >= req_value
		"bosses_defeated":
			return player_stats.get("bosses_defeated", 0) >= req_value
		"all_weapons_collected":
			return player_stats.get("max_weapons_in_run", 0) >= 10
		_:
			return false

# =============================================================================
# DEBUG
# =============================================================================

static func print_all_characters() -> void:
	"""Print all characters (debug)"""
	print("=".repeat(60))
	print("CHARACTER DATABASE - %d characters" % CHARACTERS.size())
	print("=".repeat(60))
	for char_id in CHARACTERS:
		var c = CHARACTERS[char_id]
		var status = "STARTER" if c.unlock_status == UnlockStatus.STARTER else "LOCKED"
		print("%s %s (%s) - %s - Weapon: %s" % [c.icon, c.name, status, c.element, c.starting_weapon])
	print("=".repeat(60))

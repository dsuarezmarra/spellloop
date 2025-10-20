extends Node
# Sistema de Magias y Combinaciones - Spellloop
# Paleta global de colores: Primary [#8B5CF6, #3B82F6, #EF4444] - Opposite [#FACC15, #F97316, #10B981]

# Tipos base de magia
enum MagicType {
	FUEGO,
	HIELO,
	RAYO,
	OSCURIDAD,
	LUZ,
	VIENTO,
	TIERRA,
	NATURALEZA,
	CAOS,
	TIEMPO
}

# Definiciones de magias base
var base_magic_definitions = {
	MagicType.FUEGO: {
		"name": "Fuego",
		"slug": "fire",
		"damage_formula": "base_damage * (1 + 0.15 * spell_level)",
		"projectile_type": "FireBall",
		"cooldown": 1.2,
		"special_effects": ["DOT", "burn"],
		"scaling_attribute": "intelligence",
		"mana_cost": 10,
		"color": "#EF4444",
		"description": "Proyectil ardiente que causa daño continuo"
	},
	MagicType.HIELO: {
		"name": "Hielo",
		"slug": "ice",
		"damage_formula": "base_damage * (1 + 0.12 * spell_level)",
		"projectile_type": "IceShard",
		"cooldown": 1.5,
		"special_effects": ["slow", "freeze"],
		"scaling_attribute": "intelligence",
		"mana_cost": 12,
		"color": "#3B82F6",
		"description": "Fragmento helado que ralentiza enemigos"
	},
	MagicType.RAYO: {
		"name": "Rayo",
		"slug": "lightning",
		"damage_formula": "base_damage * (1 + 0.18 * spell_level)",
		"projectile_type": "LightningBolt",
		"cooldown": 0.8,
		"special_effects": ["chain", "stun"],
		"scaling_attribute": "intelligence",
		"mana_cost": 15,
		"color": "#FACC15",
		"description": "Descarga eléctrica que salta entre enemigos"
	},
	MagicType.OSCURIDAD: {
		"name": "Oscuridad",
		"slug": "darkness",
		"damage_formula": "base_damage * (1 + 0.14 * spell_level)",
		"projectile_type": "ShadowOrb",
		"cooldown": 1.3,
		"special_effects": ["lifesteal", "blind"],
		"scaling_attribute": "intelligence",
		"mana_cost": 13,
		"color": "#7C3AED",
		"description": "Orbe sombrio que absorbe vida"
	},
	MagicType.LUZ: {
		"name": "Luz",
		"slug": "light",
		"damage_formula": "base_damage * (1 + 0.16 * spell_level)",
		"projectile_type": "LightBeam",
		"cooldown": 1.0,
		"special_effects": ["pierce", "heal_nearby"],
		"scaling_attribute": "intelligence",
		"mana_cost": 14,
		"color": "#F59E0B",
		"description": "Rayo luminoso que atraviesa enemigos"
	},
	MagicType.VIENTO: {
		"name": "Viento",
		"slug": "wind",
		"damage_formula": "base_damage * (1 + 0.13 * spell_level)",
		"projectile_type": "WindBlade",
		"cooldown": 0.9,
		"special_effects": ["knockback", "AoE"],
		"scaling_attribute": "agility",
		"mana_cost": 11,
		"color": "#10B981",
		"description": "Ráfaga cortante que empuja enemigos"
	},
	MagicType.TIERRA: {
		"name": "Tierra",
		"slug": "earth",
		"damage_formula": "base_damage * (1 + 0.20 * spell_level)",
		"projectile_type": "RockSpike",
		"cooldown": 2.0,
		"special_effects": ["armor_break", "root"],
		"scaling_attribute": "strength",
		"mana_cost": 16,
		"color": "#A16207",
		"description": "Pico rocoso que reduce armadura"
	},
	MagicType.NATURALEZA: {
		"name": "Naturaleza",
		"slug": "nature",
		"damage_formula": "base_damage * (1 + 0.11 * spell_level)",
		"projectile_type": "VineWhip",
		"cooldown": 1.1,
		"special_effects": ["poison", "regen"],
		"scaling_attribute": "wisdom",
		"mana_cost": 9,
		"color": "#16A34A",
		"description": "Látigo venenoso que regenera al caster"
	},
	MagicType.CAOS: {
		"name": "Caos",
		"slug": "chaos",
		"damage_formula": "base_damage * (0.8 + rand_range(0.4, 1.8) * spell_level)",
		"projectile_type": "ChaosOrb",
		"cooldown": 1.4,
		"special_effects": ["random_effect", "unstable"],
		"scaling_attribute": "luck",
		"mana_cost": 18,
		"color": "#DC2626",
		"description": "Orbe impredecible con efectos aleatorios"
	},
	MagicType.TIEMPO: {
		"name": "Tiempo",
		"slug": "time",
		"damage_formula": "base_damage * (1 + 0.10 * spell_level)",
		"projectile_type": "TimeRift",
		"cooldown": 2.5,
		"special_effects": ["time_slow", "delay_damage"],
		"scaling_attribute": "intelligence",
		"mana_cost": 20,
		"color": "#8B5CF6",
		"description": "Grieta temporal que ralentiza el tiempo"
	}
}

# Sistema de combinaciones de magias (25 combinaciones)
var magic_combinations = {
	# Combinaciones de 2 elementos
	"fire_ice": {
		"name": "Vapor Ardiente",
		"slug": "steam_blast",
		"components": [MagicType.FUEGO, MagicType.HIELO],
		"damage_multiplier": 1.3,
		"special_effects": ["steam_cloud", "AoE", "confusion"],
		"cooldown": 1.8,
		"mana_cost": 25,
		"description": "Explosión de vapor que confunde enemigos"
	},
	"fire_lightning": {
		"name": "Tormenta Ígnea",
		"slug": "fire_storm",
		"components": [MagicType.FUEGO, MagicType.RAYO],
		"damage_multiplier": 1.5,
		"special_effects": ["chain_burn", "electric_fire"],
		"cooldown": 1.6,
		"mana_cost": 28,
		"description": "Rayos ardientes que saltan entre enemigos"
	},
	"fire_wind": {
		"name": "Tornado de Brasas",
		"slug": "ember_tornado",
		"components": [MagicType.FUEGO, MagicType.VIENTO],
		"damage_multiplier": 1.4,
		"special_effects": ["piercing", "AoE", "DOT"],
		"cooldown": 2.0,
		"mana_cost": 24,
		"description": "Tornado ardiente que atraviesa múltiples enemigos"
	},
	"ice_lightning": {
		"name": "Cadena Criogénica",
		"slug": "cryo_chain",
		"components": [MagicType.HIELO, MagicType.RAYO],
		"damage_multiplier": 1.3,
		"special_effects": ["slow", "chain", "freeze_chance"],
		"cooldown": 1.4,
		"mana_cost": 30,
		"description": "Rayo helado que congela y salta entre objetivos"
	},
	"ice_earth": {
		"name": "Glacial Field",
		"slug": "glacial_field",
		"components": [MagicType.HIELO, MagicType.TIERRA],
		"damage_multiplier": 1.4,
		"special_effects": ["freeze", "slow"],
		"cooldown": 2.5,
		"mana_cost": 30,
		"description": "Campo glaciar que ralentiza y congela enemigos"
	},
	"lightning_wind": {
		"name": "Ciclón Eléctrico",
		"slug": "electric_cyclone",
		"components": [MagicType.RAYO, MagicType.VIENTO],
		"damage_multiplier": 1.4,
		"special_effects": ["pull", "chain", "knockback"],
		"cooldown": 1.9,
		"mana_cost": 32,
		"description": "Ciclón que atrae y electrocuta enemigos"
	},
	"darkness_light": {
		"name": "Eclipse Devastador",
		"slug": "devastating_eclipse",
		"components": [MagicType.OSCURIDAD, MagicType.LUZ],
		"damage_multiplier": 2.0,
		"special_effects": ["massive_AoE", "blind", "lifesteal"],
		"cooldown": 4.0,
		"mana_cost": 45,
		"description": "Explosión de luz y sombra con área masiva"
	},
	"nature_earth": {
		"name": "Jardín Espinoso",
		"slug": "thorn_garden",
		"components": [MagicType.NATURALEZA, MagicType.TIERRA],
		"damage_multiplier": 1.2,
		"special_effects": ["poison", "root", "area_control"],
		"cooldown": 2.5,
		"mana_cost": 28,
		"description": "Campo de espinas venenosas que inmovilizan"
	},
	"chaos_time": {
		"name": "Paradoja Temporal",
		"slug": "time_paradox",
		"components": [MagicType.CAOS, MagicType.TIEMPO],
		"damage_multiplier": 1.8,
		"special_effects": ["time_loop", "random_teleport", "duplicate"],
		"cooldown": 3.5,
		"mana_cost": 50,
		"description": "Distorsión que duplica efectos aleatoriamente"
	},
	"fire_nature": {
		"name": "Llama Viviente",
		"slug": "living_flame",
		"components": [MagicType.FUEGO, MagicType.NATURALEZA],
		"damage_multiplier": 1.3,
		"special_effects": ["seek", "regen_on_kill", "spread"],
		"cooldown": 1.7,
		"mana_cost": 22,
		"description": "Fuego que busca enemigos y se propaga"
	},
	"ice_darkness": {
		"name": "Escarcha Sombría",
		"slug": "shadow_frost",
		"components": [MagicType.HIELO, MagicType.OSCURIDAD],
		"damage_multiplier": 1.4,
		"special_effects": ["lifesteal", "slow", "blind"],
		"cooldown": 1.8,
		"mana_cost": 27,
		"description": "Hielo negro que absorbe vida y ciega"
	},
	"wind_light": {
		"name": "Destello Cortante",
		"slug": "cutting_flash",
		"components": [MagicType.VIENTO, MagicType.LUZ],
		"damage_multiplier": 1.5,
		"special_effects": ["pierce", "heal_nearby", "speed_boost"],
		"cooldown": 1.3,
		"mana_cost": 26,
		"description": "Luz cortante que cura aliados cercanos"
	},
	"earth_chaos": {
		"name": "Terremoto Caótico",
		"slug": "chaotic_quake",
		"components": [MagicType.TIERRA, MagicType.CAOS],
		"damage_multiplier": 1.7,
		"special_effects": ["random_spikes", "terrain_change", "knockdown"],
		"cooldown": 3.2,
		"mana_cost": 38,
		"description": "Sismos impredecibles que cambian el terreno"
	},
	"lightning_nature": {
		"name": "Rayo Verde",
		"slug": "green_lightning",
		"components": [MagicType.RAYO, MagicType.NATURALEZA],
		"damage_multiplier": 1.3,
		"special_effects": ["poison", "chain", "heal_caster"],
		"cooldown": 1.5,
		"mana_cost": 25,
		"description": "Electricidad natural que envenena y cura"
	},
	"darkness_earth": {
		"name": "Abismo Rocoso",
		"slug": "stone_abyss",
		"components": [MagicType.OSCURIDAD, MagicType.TIERRA],
		"damage_multiplier": 1.6,
		"special_effects": ["pit_trap", "lifesteal", "armor_break"],
		"cooldown": 2.8,
		"mana_cost": 33,
		"description": "Foso de piedra que drena vida"
	},
	"time_light": {
		"name": "Pulso Cronos",
		"slug": "chronos_pulse",
		"components": [MagicType.TIEMPO, MagicType.LUZ],
		"damage_multiplier": 1.4,
		"special_effects": ["time_slow", "pierce", "future_damage"],
		"cooldown": 2.3,
		"mana_cost": 36,
		"description": "Pulso luminoso que ralentiza el tiempo"
	},
	# Combinaciones raras de 3 elementos
	"fire_ice_lightning": {
		"name": "Trifuerza Elemental",
		"slug": "elemental_triforce",
		"components": [MagicType.FUEGO, MagicType.HIELO, MagicType.RAYO],
		"damage_multiplier": 2.2,
		"special_effects": ["tri_effect", "AoE", "elemental_weakness"],
		"cooldown": 5.0,
		"mana_cost": 60,
		"description": "Fusión de tres elementos primarios"
	},
	"darkness_light_chaos": {
		"name": "Singularidad",
		"slug": "singularity",
		"components": [MagicType.OSCURIDAD, MagicType.LUZ, MagicType.CAOS],
		"damage_multiplier": 2.5,
		"special_effects": ["gravity_well", "reality_warp", "massive_damage"],
		"cooldown": 6.0,
		"mana_cost": 75,
		"description": "Punto de singularidad que distorsiona la realidad"
	},
	"earth_wind_nature": {
		"name": "Furia de Gaia",
		"slug": "gaia_fury",
		"components": [MagicType.TIERRA, MagicType.VIENTO, MagicType.NATURALEZA],
		"damage_multiplier": 2.0,
		"special_effects": ["earth_storm", "nature_heal", "terrain_control"],
		"cooldown": 4.5,
		"mana_cost": 55,
		"description": "Ira de la naturaleza desatada"
	},
	"time_chaos_lightning": {
		"name": "Tormenta Temporal",
		"slug": "temporal_storm",
		"components": [MagicType.TIEMPO, MagicType.CAOS, MagicType.RAYO],
		"damage_multiplier": 2.3,
		"special_effects": ["time_fracture", "random_chains", "paradox_damage"],
		"cooldown": 5.5,
		"mana_cost": 70,
		"description": "Tormenta que fractura el tiempo"
	},
	# Combinaciones especiales únicas
	"void_magic": {
		"name": "Magia del Vacío",
		"slug": "void_magic",
		"components": [MagicType.OSCURIDAD, MagicType.TIEMPO, MagicType.CAOS],
		"damage_multiplier": 3.0,
		"special_effects": ["void_damage", "existence_erase", "mana_drain"],
		"cooldown": 8.0,
		"mana_cost": 100,
		"description": "Magia prohibida que borra la existencia"
	},
	"genesis_wave": {
		"name": "Onda Génesis",
		"slug": "genesis_wave",
		"components": [MagicType.LUZ, MagicType.NATURALEZA, MagicType.TIEMPO],
		"damage_multiplier": 2.8,
		"special_effects": ["creation_force", "heal_massive", "life_restore"],
		"cooldown": 7.0,
		"mana_cost": 85,
		"description": "Poder creativo que restaura la vida"
	},
	"eternal_flame": {
		"name": "Llama Eterna",
		"slug": "eternal_flame",
		"components": [MagicType.FUEGO, MagicType.LUZ, MagicType.TIEMPO],
		"damage_multiplier": 2.4,
		"special_effects": ["never_extinguish", "continuous_burn", "light_heal"],
		"cooldown": 6.5,
		"mana_cost": 80,
		"description": "Fuego que nunca se extingue"
	},
	"absolute_zero": {
		"name": "Cero Absoluto",
		"slug": "absolute_zero",
		"components": [MagicType.HIELO, MagicType.TIEMPO, MagicType.OSCURIDAD],
		"damage_multiplier": 2.6,
		"special_effects": ["time_freeze", "instant_death", "area_freeze"],
		"cooldown": 7.5,
		"mana_cost": 90,
		"description": "Frío que detiene el tiempo mismo"
	},
	"world_breaker": {
		"name": "Rompe Mundos",
		"slug": "world_breaker",
		"components": [MagicType.TIERRA, MagicType.CAOS, MagicType.OSCURIDAD],
		"damage_multiplier": 3.2,
		"special_effects": ["world_crack", "reality_damage", "terrain_destroy"],
		"cooldown": 10.0,
		"mana_cost": 120,
		"description": "Poder que puede quebrar la realidad misma"
	}
}

# Funciones para obtener definiciones
func get_base_magic(type: int):
	return base_magic_definitions[type]

func get_combination(slug: String):
	return magic_combinations[slug]

func can_combine(types: Array) -> String:
	for combination_key in magic_combinations.keys():
		var combination = magic_combinations[combination_key]
		if combination.components.size() == types.size():
			var matches = 0
			for type in types:
				if type in combination.components:
					matches += 1
			if matches == types.size():
				return combination_key
	return ""

# Calcular daño final con escalado
func calculate_damage(base_damage: int, spell_level: int, magic_type: int) -> int:
	var _definition = base_magic_definitions[magic_type]
	# Simplificación de la fórmula para Godot
	return int(base_damage * (1 + 0.15 * spell_level))

func calculate_combination_damage(base_damage: int, spell_level: int, combination_slug: String) -> int:
	var combination = magic_combinations[combination_slug]
	var multiplier = combination.damage_multiplier
	return int(base_damage * multiplier * (1 + 0.12 * spell_level))


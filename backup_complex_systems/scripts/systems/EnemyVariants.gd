# EnemyVariants.gd
# Extended enemy system with unique variants for each biome
# Provides diverse enemy types with special abilities and behaviors
#
# Public API:
# - get_biome_enemies(biome: String) -> Array[Dictionary]
# - create_special_enemy(variant_id: String, position: Vector2) -> Enemy
# - get_boss_data(biome: String) -> Dictionary
#
# Signals:
# - special_enemy_spawned(enemy: Enemy, variant_id: String)
# - boss_ability_used(boss: Enemy, ability: String)

extends Node

signal special_enemy_spawned(enemy: Enemy, variant_id: String)
signal boss_ability_used(boss: Enemy, ability: String)

# Enemy variant data by biome
var enemy_variants: Dictionary = {}
var boss_variants: Dictionary = {}

func _ready() -> void:
	print("[EnemyVariants] Initializing Enemy Variants System...")
	
	# Load variant data
	_initialize_enemy_variants()
	_initialize_boss_variants()
	
	print("[EnemyVariants] System initialized with ", enemy_variants.size(), " biomes")

func _initialize_enemy_variants() -> void:
	"""Initialize all enemy variants by biome"""
	enemy_variants = {
		"dungeon": {
			"slime_basic": {
				"id": "slime_basic",
				"name": {"en": "Dungeon Slime", "es": "Slime de Mazmorra"},
				"health": 30,
				"damage": 8,
				"speed": 80,
				"color": Color.GREEN,
				"abilities": ["basic_attack"],
				"loot_chance": 0.15,
				"experience": 10
			},
			"skeleton_archer": {
				"id": "skeleton_archer",
				"name": {"en": "Skeleton Archer", "es": "Arquero Esqueleto"},
				"health": 40,
				"damage": 12,
				"speed": 60,
				"color": Color.GRAY,
				"abilities": ["ranged_attack", "backstep"],
				"loot_chance": 0.20,
				"experience": 15,
				"attack_range": 200
			},
			"stone_golem": {
				"id": "stone_golem",
				"name": {"en": "Stone Golem", "es": "Gólem de Piedra"},
				"health": 80,
				"damage": 20,
				"speed": 40,
				"color": Color.BROWN,
				"abilities": ["charge_attack", "stone_throw"],
				"loot_chance": 0.30,
				"experience": 25,
				"armor": 5
			}
		},
		
		"forest": {
			"thorn_sprite": {
				"id": "thorn_sprite",
				"name": {"en": "Thorn Sprite", "es": "Duende Espinoso"},
				"health": 25,
				"damage": 10,
				"speed": 120,
				"color": Color.DARK_GREEN,
				"abilities": ["thorn_burst", "teleport"],
				"loot_chance": 0.18,
				"experience": 12
			},
			"bark_beast": {
				"id": "bark_beast",
				"name": {"en": "Bark Beast", "es": "Bestia de Corteza"},
				"health": 60,
				"damage": 15,
				"speed": 70,
				"color": Color.SADDLE_BROWN,
				"abilities": ["root_grasp", "bark_shield"],
				"loot_chance": 0.25,
				"experience": 20,
				"regeneration": 2
			},
			"wind_wisp": {
				"id": "wind_wisp",
				"name": {"en": "Wind Wisp", "es": "Brisa Espiritual"},
				"health": 35,
				"damage": 8,
				"speed": 150,
				"color": Color.LIGHT_CYAN,
				"abilities": ["wind_dash", "air_bolt"],
				"loot_chance": 0.15,
				"experience": 14,
				"phase_chance": 0.3
			}
		},
		
		"volcanic": {
			"magma_imp": {
				"id": "magma_imp",
				"name": {"en": "Magma Imp", "es": "Diablillo de Magma"},
				"health": 45,
				"damage": 18,
				"speed": 100,
				"color": Color.ORANGE_RED,
				"abilities": ["fire_blast", "flame_trail"],
				"loot_chance": 0.22,
				"experience": 18,
				"fire_immunity": true
			},
			"lava_golem": {
				"id": "lava_golem",
				"name": {"en": "Lava Golem", "es": "Gólem de Lava"},
				"health": 100,
				"damage": 25,
				"speed": 50,
				"color": Color.DARK_RED,
				"abilities": ["lava_slam", "molten_armor"],
				"loot_chance": 0.35,
				"experience": 30,
				"armor": 8,
				"fire_aura": true
			},
			"fire_salamander": {
				"id": "fire_salamander",
				"name": {"en": "Fire Salamander", "es": "Salamandra de Fuego"},
				"health": 55,
				"damage": 16,
				"speed": 90,
				"color": Color.YELLOW,
				"abilities": ["flame_spit", "heat_wave"],
				"loot_chance": 0.28,
				"experience": 22
			}
		},
		
		"ice": {
			"frost_spider": {
				"id": "frost_spider",
				"name": {"en": "Frost Spider", "es": "Araña de Escarcha"},
				"health": 40,
				"damage": 14,
				"speed": 85,
				"color": Color.LIGHT_BLUE,
				"abilities": ["ice_web", "freeze_bite"],
				"loot_chance": 0.20,
				"experience": 16,
				"slow_on_hit": true
			},
			"ice_wraith": {
				"id": "ice_wraith",
				"name": {"en": "Ice Wraith", "es": "Espectro de Hielo"},
				"health": 50,
				"damage": 12,
				"speed": 110,
				"color": Color.CYAN,
				"abilities": ["frost_nova", "phase_walk"],
				"loot_chance": 0.25,
				"experience": 20,
				"phase_chance": 0.4
			},
			"glacier_giant": {
				"id": "glacier_giant",
				"name": {"en": "Glacier Giant", "es": "Gigante Glacial"},
				"health": 120,
				"damage": 30,
				"speed": 35,
				"color": Color.ALICE_BLUE,
				"abilities": ["ice_stomp", "blizzard"],
				"loot_chance": 0.40,
				"experience": 35,
				"armor": 10,
				"ice_immunity": true
			}
		},
		
		"corruption": {
			"shadow_spawn": {
				"id": "shadow_spawn",
				"name": {"en": "Shadow Spawn", "es": "Engendro Sombra"},
				"health": 30,
				"damage": 20,
				"speed": 130,
				"color": Color.PURPLE,
				"abilities": ["shadow_strike", "darkness"],
				"loot_chance": 0.18,
				"experience": 20,
				"stealth_chance": 0.3
			},
			"void_stalker": {
				"id": "void_stalker",
				"name": {"en": "Void Stalker", "es": "Acechador del Vacío"},
				"health": 70,
				"damage": 25,
				"speed": 95,
				"color": Color.DARK_VIOLET,
				"abilities": ["void_bolt", "phase_hunt"],
				"loot_chance": 0.30,
				"experience": 28,
				"teleport_range": 150
			},
			"corruption_beast": {
				"id": "corruption_beast",
				"name": {"en": "Corruption Beast", "es": "Bestia Corrupta"},
				"health": 90,
				"damage": 22,
				"speed": 75,
				"color": Color.DARK_MAGENTA,
				"abilities": ["corrupt_aura", "life_drain"],
				"loot_chance": 0.35,
				"experience": 32,
				"corruption_damage": 5
			}
		},
		
		"celestial": {
			"light_seraph": {
				"id": "light_seraph",
				"name": {"en": "Light Seraph", "es": "Serafín de Luz"},
				"health": 60,
				"damage": 18,
				"speed": 100,
				"color": Color.GOLD,
				"abilities": ["holy_bolt", "light_shield"],
				"loot_chance": 0.25,
				"experience": 25,
				"light_immunity": true
			},
			"crystal_guardian": {
				"id": "crystal_guardian",
				"name": {"en": "Crystal Guardian", "es": "Guardián de Cristal"},
				"health": 80,
				"damage": 24,
				"speed": 60,
				"color": Color.WHITE,
				"abilities": ["crystal_lance", "prism_barrier"],
				"loot_chance": 0.30,
				"experience": 30,
				"reflect_chance": 0.2
			},
			"star_elemental": {
				"id": "star_elemental",
				"name": {"en": "Star Elemental", "es": "Elemental Estelar"},
				"health": 100,
				"damage": 28,
				"speed": 85,
				"color": Color.LIGHT_YELLOW,
				"abilities": ["star_fall", "cosmic_burst"],
				"loot_chance": 0.40,
				"experience": 40,
				"energy_shield": 20
			}
		}
	}

func _initialize_boss_variants() -> void:
	"""Initialize boss variants for each biome"""
	boss_variants = {
		"dungeon": {
			"id": "dungeon_lord",
			"name": {"en": "Dungeon Lord", "es": "Señor de la Mazmorra"},
			"health": 300,
			"damage": 40,
			"speed": 70,
			"color": Color.DARK_GRAY,
			"phases": [
				{
					"name": "Summon Phase",
					"health_threshold": 0.75,
					"abilities": ["summon_minions", "ground_slam"]
				},
				{
					"name": "Rage Phase",
					"health_threshold": 0.5,
					"abilities": ["charge_combo", "stone_prison"]
				},
				{
					"name": "Desperate Phase",
					"health_threshold": 0.25,
					"abilities": ["earth_quake", "rock_storm"]
				}
			],
			"loot": ["rare_crystal", "boss_essence", "meta_currency"],
			"experience": 150
		},
		
		"forest": {
			"id": "forest_ancient",
			"name": {"en": "Forest Ancient", "es": "Ancestro del Bosque"},
			"health": 350,
			"damage": 35,
			"speed": 50,
			"color": Color.DARK_GREEN,
			"phases": [
				{
					"name": "Growth Phase",
					"health_threshold": 0.8,
					"abilities": ["root_network", "thorn_volley"]
				},
				{
					"name": "Fury Phase",
					"health_threshold": 0.5,
					"abilities": ["wind_storm", "nature_wrath"]
				},
				{
					"name": "Final Phase",
					"health_threshold": 0.2,
					"abilities": ["forest_rage", "life_drain_aura"]
				}
			],
			"loot": ["nature_essence", "wind_rune", "meta_currency"],
			"experience": 200
		},
		
		"volcanic": {
			"id": "volcano_king",
			"name": {"en": "Volcano King", "es": "Rey del Volcán"},
			"health": 400,
			"damage": 45,
			"speed": 60,
			"color": Color.RED,
			"phases": [
				{
					"name": "Eruption Phase",
					"health_threshold": 0.75,
					"abilities": ["lava_burst", "fire_rain"]
				},
				{
					"name": "Molten Phase",
					"health_threshold": 0.5,
					"abilities": ["lava_tsunami", "flame_tornado"]
				},
				{
					"name": "Inferno Phase",
					"health_threshold": 0.25,
					"abilities": ["volcanic_apocalypse", "phoenix_form"]
				}
			],
			"loot": ["fire_core", "molten_crystal", "meta_currency"],
			"experience": 250
		},
		
		"ice": {
			"id": "ice_empress",
			"name": {"en": "Ice Empress", "es": "Emperatriz de Hielo"},
			"health": 450,
			"damage": 38,
			"speed": 55,
			"color": Color.CYAN,
			"phases": [
				{
					"name": "Freeze Phase",
					"health_threshold": 0.8,
					"abilities": ["ice_prison", "frost_shards"]
				},
				{
					"name": "Blizzard Phase",
					"health_threshold": 0.5,
					"abilities": ["eternal_winter", "ice_meteor"]
				},
				{
					"name": "Absolute Zero",
					"health_threshold": 0.2,
					"abilities": ["time_freeze", "crystal_cascade"]
				}
			],
			"loot": ["ice_heart", "eternal_frost", "meta_currency"],
			"experience": 300
		},
		
		"corruption": {
			"id": "void_emperor",
			"name": {"en": "Void Emperor", "es": "Emperador del Vacío"},
			"health": 500,
			"damage": 50,
			"speed": 80,
			"color": Color.BLACK,
			"phases": [
				{
					"name": "Corruption Phase",
					"health_threshold": 0.75,
					"abilities": ["void_rifts", "shadow_army"]
				},
				{
					"name": "Nightmare Phase",
					"health_threshold": 0.5,
					"abilities": ["reality_tear", "darkness_embrace"]
				},
				{
					"name": "Apocalypse Phase",
					"health_threshold": 0.25,
					"abilities": ["void_storm", "existence_erasure"]
				}
			],
			"loot": ["void_essence", "shadow_crown", "meta_currency"],
			"experience": 400
		},
		
		"celestial": {
			"id": "star_god",
			"name": {"en": "Star God", "es": "Dios Estelar"},
			"health": 600,
			"damage": 55,
			"speed": 90,
			"color": Color.GOLD,
			"phases": [
				{
					"name": "Divine Phase",
					"health_threshold": 0.8,
					"abilities": ["stellar_judgment", "light_prison"]
				},
				{
					"name": "Cosmic Phase",
					"health_threshold": 0.5,
					"abilities": ["galaxy_spin", "supernova"]
				},
				{
					"name": "Transcendent Phase",
					"health_threshold": 0.2,
					"abilities": ["big_bang", "universal_reset"]
				}
			],
			"loot": ["star_fragment", "divine_essence", "meta_currency"],
			"experience": 500,
			"is_final_boss": true
		}
	}

func get_biome_enemies(biome: String) -> Array[Dictionary]:
	"""Get all enemy variants for a specific biome"""
	var enemies = []
	
	if enemy_variants.has(biome):
		for enemy_id in enemy_variants[biome]:
			var enemy_data = enemy_variants[biome][enemy_id].duplicate()
			enemy_data["biome"] = biome
			enemies.append(enemy_data)
	
	return enemies

func get_random_biome_enemy(biome: String) -> Dictionary:
	"""Get a random enemy variant from a biome"""
	var enemies = get_biome_enemies(biome)
	if enemies.size() > 0:
		return enemies[randi() % enemies.size()]
	
	return {}

func get_boss_data(biome: String) -> Dictionary:
	"""Get boss data for a specific biome"""
	return boss_variants.get(biome, {})

func create_special_enemy(variant_id: String, position: Vector2, parent: Node) -> Enemy:
	"""Create a special enemy variant at a position"""
	# Find the variant data
	var variant_data = {}
	var found_biome = ""
	
	for biome in enemy_variants:
		if enemy_variants[biome].has(variant_id):
			variant_data = enemy_variants[biome][variant_id]
			found_biome = biome
			break
	
	if variant_data.is_empty():
		print("[EnemyVariants] Unknown variant: ", variant_id)
		return null
	
	# Create enemy using EnemyFactory
	var enemy_type = _get_factory_type_for_variant(variant_id)
	var enemy = EnemyFactory.create_enemy(enemy_type, position, parent)
	
	if enemy:
		# Apply variant data
		_apply_variant_data(enemy, variant_data)
		special_enemy_spawned.emit(enemy, variant_id)
	
	return enemy

func _get_factory_type_for_variant(variant_id: String) -> EnemyFactory.EnemyType:
	"""Map variant ID to EnemyFactory type"""
	# Map to basic types for now
	match variant_id:
		"slime_basic", "thorn_sprite", "magma_imp", "frost_spider", "shadow_spawn", "light_seraph":
			return EnemyFactory.EnemyType.BASIC_SLIME
		"skeleton_archer", "wind_wisp", "fire_salamander", "ice_wraith", "void_stalker", "crystal_guardian":
			return EnemyFactory.EnemyType.SENTINEL_ORB
		_:
			return EnemyFactory.EnemyType.PATROL_GUARD

func _apply_variant_data(enemy: Enemy, variant_data: Dictionary) -> void:
	"""Apply variant data to an enemy"""
	# Apply basic stats
	if variant_data.has("health"):
		enemy.max_health = variant_data["health"]
		enemy.current_health = variant_data["health"]
	
	if variant_data.has("damage"):
		enemy.attack_damage = variant_data["damage"]
	
	if variant_data.has("speed"):
		enemy.movement_speed = variant_data["speed"]
	
	if variant_data.has("color"):
		enemy.modulate = variant_data["color"]
	
	# Apply special properties
	if variant_data.has("armor"):
		enemy.set_meta("armor", variant_data["armor"])
	
	if variant_data.has("regeneration"):
		enemy.set_meta("regeneration", variant_data["regeneration"])
	
	if variant_data.has("fire_immunity"):
		enemy.set_meta("fire_immunity", true)
	
	if variant_data.has("ice_immunity"):
		enemy.set_meta("ice_immunity", true)
	
	# Store abilities
	if variant_data.has("abilities"):
		enemy.set_meta("abilities", variant_data["abilities"])

func get_enemy_ability_data(ability_id: String) -> Dictionary:
	"""Get data for enemy abilities"""
	var abilities = {
		"basic_attack": {
			"name": "Basic Attack",
			"cooldown": 1.0,
			"range": 50,
			"damage_multiplier": 1.0
		},
		"ranged_attack": {
			"name": "Ranged Attack",
			"cooldown": 2.0,
			"range": 200,
			"projectile_speed": 300
		},
		"charge_attack": {
			"name": "Charge Attack",
			"cooldown": 3.0,
			"range": 150,
			"damage_multiplier": 2.0,
			"stun_duration": 0.5
		},
		"thorn_burst": {
			"name": "Thorn Burst",
			"cooldown": 2.5,
			"range": 100,
			"projectile_count": 8
		},
		"teleport": {
			"name": "Teleport",
			"cooldown": 4.0,
			"range": 200
		},
		"fire_blast": {
			"name": "Fire Blast",
			"cooldown": 2.0,
			"range": 120,
			"burn_duration": 3.0
		},
		"shadow_strike": {
			"name": "Shadow Strike",
			"cooldown": 1.5,
			"range": 80,
			"stealth_duration": 1.0
		}
	}
	
	return abilities.get(ability_id, {})

func get_localized_enemy_name(variant_id: String) -> String:
	"""Get localized name for an enemy variant"""
	for biome in enemy_variants:
		if enemy_variants[biome].has(variant_id):
			var variant = enemy_variants[biome][variant_id]
			if variant.has("name"):
				var names = variant["name"]
				var current_lang = Localization.get_current_language()
				return names.get(current_lang, names.get("en", variant_id))
	
	return variant_id

func get_all_variants() -> Dictionary:
	"""Get all enemy variants data"""
	return enemy_variants

func get_variant_count() -> int:
	"""Get total number of enemy variants"""
	var total = 0
	for biome in enemy_variants:
		total += enemy_variants[biome].size()
	return total
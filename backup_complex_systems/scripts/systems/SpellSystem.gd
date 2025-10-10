# SpellSystem.gd
# Central spell management system that handles spell casting, data, and projectile creation
# Loads spell data from JSON and manages spell behaviors
#
# Public API:
# - cast_spell(spell_id: String, caster: Entity, direction: Vector2, position: Vector2) -> void
# - get_spell_data(spell_id: String) -> Dictionary
# - is_spell_unlocked(spell_id: String) -> bool
# - get_spell_cooldown(spell_id: String) -> float
#
# Signals:
# - spell_cast(spell_id: String, caster: Entity, projectile: Projectile)
# - projectile_created(projectile: Projectile)

extends Node

signal spell_cast(spell_id: String, caster: Entity, projectile: Projectile)
signal projectile_created(projectile: Projectile)

# Spell data storage
var spell_data: Dictionary = {}
var projectile_scene: PackedScene

# Spell elements for combination system
enum SpellElement {
	FIRE,
	ICE,
	LIGHTNING,
	SHADOW,
	EARTH,
	WIND,
	LIGHT,
	VOID
}

func _ready() -> void:
	print("[SpellSystem] Initializing SpellSystem...")
	
	# Load projectile scene
	projectile_scene = preload("res://scenes/characters/Projectile.tscn")
	
	# Load spell data
	_load_spell_data()
	
	print("[SpellSystem] SpellSystem initialized with ", spell_data.size(), " spells")

func _load_spell_data() -> void:
	"""Load spell data from JSON file"""
	var data_path = "res://assets/data/spells.json"
	
	if not FileAccess.file_exists(data_path):
		print("[SpellSystem] Spell data file not found, creating default")
		_create_default_spell_data()
		return
	
	var file = FileAccess.open(data_path, FileAccess.READ)
	if file == null:
		print("[SpellSystem] Error: Could not open spell data file")
		_create_default_spell_data()
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("[SpellSystem] Error: Could not parse spell data JSON")
		_create_default_spell_data()
		return
	
	spell_data = json.data
	print("[SpellSystem] Loaded spell data successfully")

func _create_default_spell_data() -> void:
	"""Create default spell data"""
	spell_data = {
		"fireball": {
			"id": "fireball",
			"elements": ["fire"],
			"name": {"en": "Fireball", "es": "Bola de Fuego"},
			"damage": 15,
			"speed": 350,
			"range": 400,
			"cooldown": 0.8,
			"cost": 10,
			"projectile_type": "fireball",
			"effects": ["explosion"]
		},
		"ice_shard": {
			"id": "ice_shard",
			"elements": ["ice"],
			"name": {"en": "Ice Shard", "es": "Fragmento de Hielo"},
			"damage": 12,
			"speed": 450,
			"range": 350,
			"cooldown": 0.6,
			"cost": 8,
			"projectile_type": "ice_shard",
			"effects": ["pierce"]
		},
		"lightning_bolt": {
			"id": "lightning_bolt",
			"elements": ["lightning"],
			"name": {"en": "Lightning Bolt", "es": "Rayo"},
			"damage": 20,
			"speed": 600,
			"range": 300,
			"cooldown": 1.0,
			"cost": 15,
			"projectile_type": "lightning_bolt",
			"effects": ["instant"]
		},
		"shadow_blast": {
			"id": "shadow_blast",
			"elements": ["shadow"],
			"name": {"en": "Shadow Blast", "es": "Explosión Sombría"},
			"damage": 18,
			"speed": 300,
			"range": 250,
			"cooldown": 1.2,
			"cost": 12,
			"projectile_type": "shadow_blast",
			"effects": ["void"]
		},
		"healing_light": {
			"id": "healing_light",
			"elements": ["light"],
			"name": {"en": "Healing Light", "es": "Luz Curativa"},
			"damage": -25,  # Negative damage = healing
			"speed": 200,
			"range": 150,
			"cooldown": 2.0,
			"cost": 20,
			"projectile_type": "healing_light",
			"effects": ["heal"]
		}
	}
	
	# Save default data to file
	_save_spell_data()

func _save_spell_data() -> void:
	"""Save spell data to JSON file"""
	var data_path = "res://assets/data/spells.json"
	var file = FileAccess.open(data_path, FileAccess.WRITE)
	
	if file:
		file.store_string(JSON.stringify(spell_data, "\t"))
		file.close()
		print("[SpellSystem] Saved spell data to file")

func cast_spell(spell_id: String, caster: Entity, direction: Vector2, position: Vector2) -> void:
	"""Cast a spell from a caster in a direction"""
	if not spell_data.has(spell_id):
		print("[SpellSystem] Error: Unknown spell: ", spell_id)
		return
	
	var spell = spell_data[spell_id]
	
	# Check if it's a healing spell
	if spell.get("damage", 0) < 0:
		_cast_healing_spell(spell, caster)
		return
	
	# Play spell cast effects
	if EffectsManager:
		EffectsManager.play_spell_effect(spell_id, position)
	
	if AudioManager:
		AudioManager.play_spell_cast_sfx(spell_id)
	
	# Create projectile
	var projectile = _create_projectile(spell, caster, direction, position)
	if projectile:
		# Add to current scene
		get_tree().current_scene.add_child(projectile)
		
		# Emit signals
		spell_cast.emit(spell_id, caster, projectile)
		projectile_created.emit(projectile)
		
		print("[SpellSystem] Cast spell: ", spell_id, " from ", caster.name)

func _create_projectile(spell: Dictionary, caster: Entity, direction: Vector2, position: Vector2) -> Projectile:
	"""Create a projectile for the spell"""
	if not projectile_scene:
		print("[SpellSystem] Error: Projectile scene not loaded")
		return null
	
	var projectile = projectile_scene.instantiate() as Projectile
	if not projectile:
		print("[SpellSystem] Error: Could not create projectile instance")
		return null
	
	# Set position
	projectile.global_position = position
	
	# Set owner
	projectile.set_owner_entity(caster)
	
	# Initialize projectile with spell data
	var damage = spell.get("damage", 10)
	var speed = spell.get("speed", 300)
	var range = spell.get("range", 400)
	
	projectile.initialize(direction, speed, damage, range)
	
	# Configure projectile type
	var projectile_type = spell.get("projectile_type", "basic")
	_configure_projectile_type(projectile, projectile_type)
	
	return projectile

func _configure_projectile_type(projectile: Projectile, projectile_type: String) -> void:
	"""Configure projectile based on its type"""
	match projectile_type:
		"fireball":
			projectile.configure_fireball()
		"ice_shard":
			projectile.configure_ice_shard()
		"lightning_bolt":
			projectile.configure_lightning_bolt()
		"shadow_blast":
			projectile.configure_shadow_blast()
		_:
			print("[SpellSystem] Unknown projectile type: ", projectile_type)

func _cast_healing_spell(spell: Dictionary, caster: Entity) -> void:
	"""Cast a healing spell on the caster"""
	var heal_amount = abs(spell.get("damage", 25))
	caster.heal(heal_amount)
	
	print("[SpellSystem] Cast healing spell on ", caster.name, " for ", heal_amount, " health")
	
	# Visual and audio effects for healing
	EffectsManager.play_spell_effect("healing", caster.global_position)
	AudioManager.play_sfx("spell_heal")
	
	# Show healing indicator
	EffectsManager.play_damage_effect(heal_amount, caster.global_position, Color.GREEN)
	
	# Emit spell cast signal (no projectile for healing)
	spell_cast.emit(spell["id"], caster, null)

func get_spell_data(spell_id: String) -> Dictionary:
	"""Get spell data dictionary"""
	return spell_data.get(spell_id, {})

func is_spell_unlocked(spell_id: String) -> bool:
	"""Check if spell is unlocked for the player"""
	if SaveManager and SaveManager.is_data_loaded:
		var player_data = SaveManager.get_player_progression()
		return spell_id in player_data.get("unlocked_spells", [])
	
	# Default unlocked spells
	return spell_id in ["fireball", "ice_shard"]

func get_spell_cooldown(spell_id: String) -> float:
	"""Get spell cooldown duration"""
	var spell = get_spell_data(spell_id)
	return spell.get("cooldown", 1.0)

func get_spell_name(spell_id: String) -> String:
	"""Get localized spell name"""
	var spell = get_spell_data(spell_id)
	if spell.has("name"):
		var names = spell["name"]
		var current_lang = Localization.get_current_language()
		return names.get(current_lang, names.get("en", spell_id))
	
	return spell_id

func get_available_spells() -> Array[String]:
	"""Get list of all available spell IDs"""
	return spell_data.keys()

func get_unlocked_spells() -> Array[String]:
	"""Get list of unlocked spell IDs for the player"""
	var unlocked = []
	for spell_id in spell_data.keys():
		if is_spell_unlocked(spell_id):
			unlocked.append(spell_id)
	
	return unlocked

# Spell combination system (for future DLC expansion)
func combine_spells(element1: SpellElement, element2: SpellElement) -> String:
	"""Combine two spell elements to create a new spell"""
	# TODO: Implement spell combination logic
	# This is a placeholder for the spell combination system
	
	var combination_key = str(element1) + "_" + str(element2)
	
	match combination_key:
		"0_1":  # Fire + Ice
			return "steam_blast"
		"0_2":  # Fire + Lightning
			return "plasma_bolt"
		"1_2":  # Ice + Lightning
			return "frozen_lightning"
		_:
			print("[SpellSystem] No combination found for elements: ", element1, " + ", element2)
			return ""

func get_spell_elements(spell_id: String) -> Array:
	"""Get the elements that make up a spell"""
	var spell = get_spell_data(spell_id)
	return spell.get("elements", [])

# Debug and testing functions
func list_all_spells() -> void:
	"""Print all available spells for debugging"""
	print("[SpellSystem] Available spells:")
	for spell_id in spell_data:
		var spell = spell_data[spell_id]
		print("  - ", spell_id, ": ", spell.get("name", {}).get("en", spell_id))
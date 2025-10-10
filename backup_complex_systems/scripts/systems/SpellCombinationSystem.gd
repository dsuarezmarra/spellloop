# SpellCombinationSystem.gd
# Advanced spell combination system that creates new spells by combining elements
# Handles combination discovery, unlocking, and casting mechanics
#
# Public API:
# - try_combine_spells(primary_spell: String, secondary_spell: String) -> String
# - is_combination_unlocked(combination_id: String) -> bool
# - discover_combination(combination_id: String) -> void
# - get_available_combinations() -> Array[Dictionary]
#
# Signals:
# - combination_discovered(combination_id: String, recipe: Dictionary)
# - combination_cast(combination_id: String, caster: Entity)

extends Node

signal combination_discovered(combination_id: String, recipe: Dictionary)
signal combination_cast(combination_id: String, caster: Entity)

# Combination recipes data
var combination_recipes: Dictionary = {}
var discovered_combinations: Array[String] = []

# Combination discovery system
var attempted_combinations: Array[String] = []
var combination_attempts: Dictionary = {}

func _ready() -> void:
	print("[SpellCombinationSystem] Initializing Spell Combination System...")
	
	# Load combination data
	_load_combination_data()
	
	# Connect to spell system
	if SpellSystem:
		SpellSystem.spell_cast.connect(_on_spell_cast)
	
	print("[SpellCombinationSystem] System initialized with ", combination_recipes.size(), " combinations")

func _load_combination_data() -> void:
	"""Load spell combination recipes from data"""
	combination_recipes = {
		# Basic Element Combinations
		"frost_nova": {
			"id": "frost_nova",
			"name": {"en": "Frost Nova", "es": "Nova de Escarcha"},
			"description": {"en": "Ice + Wind creates an area freeze effect", "es": "Hielo + Viento crea congelación en área"},
			"required_spells": ["ice_shard", "wind_slash"],
			"elements": ["ice", "wind"],
			"damage": 16,
			"speed": 0,
			"range": 200,
			"cooldown": 2.5,
			"cost": 25,
			"effects": ["area", "freeze", "slow"],
			"discovery_hint": "Try combining ice and wind magic...",
			"unlock_cost": 150,
			"visual_effect": "frost_explosion"
		},
		
		"flame_wave": {
			"id": "flame_wave",
			"name": {"en": "Flame Wave", "es": "Onda de Llamas"},
			"description": {"en": "Fire + Earth creates spreading flames", "es": "Fuego + Tierra crea llamas que se extienden"},
			"required_spells": ["fireball", "earth_spike"],
			"elements": ["fire", "earth"],
			"damage": 20,
			"speed": 250,
			"range": 350,
			"cooldown": 2.0,
			"cost": 22,
			"effects": ["area", "burn", "spread"],
			"discovery_hint": "Fire can be amplified by earth...",
			"unlock_cost": 175,
			"visual_effect": "spreading_fire"
		},
		
		"thunder_storm": {
			"id": "thunder_storm",
			"name": {"en": "Thunder Storm", "es": "Tormenta de Truenos"},
			"description": {"en": "Lightning + Wind creates multiple strikes", "es": "Rayo + Viento crea múltiples rayos"},
			"required_spells": ["lightning_bolt", "wind_slash"],
			"elements": ["lightning", "wind"],
			"damage": 25,
			"speed": 400,
			"range": 300,
			"cooldown": 3.0,
			"cost": 30,
			"effects": ["multiple", "stun", "chain"],
			"discovery_hint": "Wind can carry lightning...",
			"unlock_cost": 200,
			"visual_effect": "lightning_storm"
		},
		
		# Advanced Combinations
		"shadow_fire": {
			"id": "shadow_fire",
			"name": {"en": "Shadow Fire", "es": "Fuego Sombra"},
			"description": {"en": "Fire + Shadow creates dark flames that phase through walls", "es": "Fuego + Sombra crea llamas oscuras que atraviesan paredes"},
			"required_spells": ["fireball", "shadow_blast"],
			"elements": ["fire", "shadow"],
			"damage": 22,
			"speed": 320,
			"range": 450,
			"cooldown": 1.8,
			"cost": 28,
			"effects": ["phase", "burn", "fear"],
			"discovery_hint": "Dark magic can corrupt fire...",
			"unlock_cost": 250,
			"visual_effect": "dark_fire"
		},
		
		"crystal_lance": {
			"id": "crystal_lance",
			"name": {"en": "Crystal Lance", "es": "Lanza de Cristal"},
			"description": {"en": "Ice + Lightning creates a piercing crystal spear", "es": "Hielo + Rayo crea una lanza de cristal perforante"},
			"required_spells": ["ice_shard", "lightning_bolt"],
			"elements": ["ice", "lightning"],
			"damage": 30,
			"speed": 500,
			"range": 400,
			"cooldown": 2.2,
			"cost": 26,
			"effects": ["pierce", "shatter", "stun"],
			"discovery_hint": "Lightning can crystallize ice...",
			"unlock_cost": 225,
			"visual_effect": "crystal_explosion"
		},
		
		# Master Level Combinations
		"void_storm": {
			"id": "void_storm",
			"name": {"en": "Void Storm", "es": "Tormenta del Vacío"},
			"description": {"en": "Shadow + Lightning + Wind creates a devastating vortex", "es": "Sombra + Rayo + Viento crea un vórtice devastador"},
			"required_spells": ["shadow_blast", "lightning_bolt", "wind_slash"],
			"elements": ["shadow", "lightning", "wind"],
			"damage": 40,
			"speed": 200,
			"range": 250,
			"cooldown": 5.0,
			"cost": 50,
			"effects": ["area", "pull", "void", "multiple"],
			"discovery_hint": "Three elements can create ultimate destruction...",
			"unlock_cost": 500,
			"visual_effect": "void_vortex",
			"is_master_combination": true
		},
		
		"phoenix_resurrection": {
			"id": "phoenix_resurrection",
			"name": {"en": "Phoenix Resurrection", "es": "Resurrección del Fénix"},
			"description": {"en": "Fire + Light + Healing creates rebirth magic", "es": "Fuego + Luz + Curación crea magia de renacimiento"},
			"required_spells": ["fireball", "healing_light", "healing_light"],
			"elements": ["fire", "light", "light"],
			"damage": -100,  # Massive healing
			"speed": 0,
			"range": 0,
			"cooldown": 15.0,
			"cost": 80,
			"effects": ["resurrect", "heal", "buff"],
			"discovery_hint": "Life can triumph over death...",
			"unlock_cost": 750,
			"visual_effect": "phoenix_rebirth",
			"is_master_combination": true,
			"special_effect": "revive_on_death"
		}
	}

func try_combine_spells(primary_spell: String, secondary_spell: String, tertiary_spell: String = "") -> String:
	"""Try to combine spells and return combination ID if successful"""
	var spell_list = [primary_spell, secondary_spell]
	if tertiary_spell != "":
		spell_list.append(tertiary_spell)
	
	# Sort spells for consistent matching
	spell_list.sort()
	
	# Check each combination recipe
	for combination_id in combination_recipes:
		var recipe = combination_recipes[combination_id]
		var required_spells = recipe["required_spells"].duplicate()
		required_spells.sort()
		
		# Check if spell lists match
		if _arrays_match(spell_list, required_spells):
			# Check if combination is unlocked
			if is_combination_unlocked(combination_id):
				return combination_id
			else:
				# Attempt discovery
				_attempt_combination_discovery(combination_id, spell_list)
				return ""
	
	return ""

func _arrays_match(array1: Array, array2: Array) -> bool:
	"""Check if two arrays contain the same elements"""
	if array1.size() != array2.size():
		return false
	
	for i in range(array1.size()):
		if array1[i] != array2[i]:
			return false
	
	return true

func _attempt_combination_discovery(combination_id: String, spell_list: Array) -> void:
	"""Handle combination discovery attempt"""
	var combination_key = "_".join(spell_list)
	
	# Track attempts
	if not combination_attempts.has(combination_key):
		combination_attempts[combination_key] = 0
	
	combination_attempts[combination_key] += 1
	
	# Check discovery conditions
	var recipe = combination_recipes[combination_id]
	var required_attempts = recipe.get("required_attempts", 3)
	
	if combination_attempts[combination_key] >= required_attempts:
		discover_combination(combination_id)

func discover_combination(combination_id: String) -> void:
	"""Discover a new spell combination"""
	if combination_id in discovered_combinations:
		return
	
	discovered_combinations.append(combination_id)
	var recipe = combination_recipes[combination_id]
	
	# Add to spell system
	if SpellSystem:
		var spell_data = {
			"id": combination_id,
			"elements": recipe["elements"],
			"name": recipe["name"],
			"description": recipe["description"],
			"damage": recipe["damage"],
			"speed": recipe["speed"],
			"range": recipe["range"],
			"cooldown": recipe["cooldown"],
			"cost": recipe["cost"],
			"projectile_type": combination_id,
			"effects": recipe["effects"],
			"unlock_cost": recipe["unlock_cost"],
			"is_combination": true
		}
		
		SpellSystem.spell_data[combination_id] = spell_data
	
	# Emit discovery signal
	combination_discovered.emit(combination_id, recipe)
	
	print("[SpellCombinationSystem] COMBINATION DISCOVERED: ", recipe["name"]["en"])

func is_combination_unlocked(combination_id: String) -> bool:
	"""Check if a combination is unlocked"""
	return combination_id in discovered_combinations

func get_available_combinations() -> Array[Dictionary]:
	"""Get all available combinations with their data"""
	var available = []
	
	for combination_id in discovered_combinations:
		if combination_recipes.has(combination_id):
			var recipe = combination_recipes[combination_id].duplicate()
			recipe["is_unlocked"] = true
			available.append(recipe)
	
	return available

func get_discovery_hints() -> Array[Dictionary]:
	"""Get hints for undiscovered combinations"""
	var hints = []
	
	for combination_id in combination_recipes:
		if combination_id not in discovered_combinations:
			var recipe = combination_recipes[combination_id]
			if recipe.has("discovery_hint"):
				hints.append({
					"hint": recipe["discovery_hint"],
					"elements": recipe["elements"],
					"difficulty": recipe.get("unlock_cost", 100)
				})
	
	return hints

func cast_combination_spell(combination_id: String, caster: Entity, direction: Vector2, position: Vector2) -> void:
	"""Cast a combination spell"""
	if not is_combination_unlocked(combination_id):
		print("[SpellCombinationSystem] Combination not unlocked: ", combination_id)
		return
	
	# Use SpellSystem to cast the combination
	if SpellSystem:
		SpellSystem.cast_spell(combination_id, caster, direction, position)
		combination_cast.emit(combination_id, caster)

func _on_spell_cast(spell_id: String, caster: Entity, projectile: Projectile) -> void:
	"""Handle spell cast for combination tracking"""
	# Track recent spell casts for auto-combination detection
	# This could be expanded for auto-combination features
	pass

func get_combination_recipe(combination_id: String) -> Dictionary:
	"""Get the recipe for a specific combination"""
	return combination_recipes.get(combination_id, {})

func get_localized_combination_name(combination_id: String) -> String:
	"""Get localized name for a combination"""
	var recipe = get_combination_recipe(combination_id)
	if recipe.has("name"):
		var names = recipe["name"]
		var current_lang = Localization.get_current_language()
		return names.get(current_lang, names.get("en", combination_id))
	
	return combination_id

# Save/Load functionality for discovered combinations
func save_combination_data() -> Dictionary:
	"""Save combination discovery data"""
	return {
		"discovered_combinations": discovered_combinations,
		"combination_attempts": combination_attempts
	}

func load_combination_data(data: Dictionary) -> void:
	"""Load combination discovery data"""
	discovered_combinations = data.get("discovered_combinations", [])
	combination_attempts = data.get("combination_attempts", {})
	
	# Re-add discovered combinations to spell system
	for combination_id in discovered_combinations:
		if combination_recipes.has(combination_id):
			discover_combination(combination_id)
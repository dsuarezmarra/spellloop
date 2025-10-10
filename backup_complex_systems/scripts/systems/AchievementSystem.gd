# AchievementSystem.gd
# Comprehensive achievement system with progress tracking and rewards
# Handles achievement unlocking, progress tracking, and Steam integration preparation
#
# Public API:
# - unlock_achievement(achievement_id: String) -> void
# - update_progress(achievement_id: String, progress: int) -> void
# - is_achievement_unlocked(achievement_id: String) -> bool
# - get_achievement_progress(achievement_id: String) -> float
# - get_unlocked_achievements() -> Array[String]
#
# Signals:
# - achievement_unlocked(achievement_id: String, achievement_data: Dictionary)
# - achievement_progress_updated(achievement_id: String, progress: int, total: int)

extends Node

signal achievement_unlocked(achievement_id: String, achievement_data: Dictionary)
signal achievement_progress_updated(achievement_id: String, progress: int, total: int)

# Achievement data
var achievements: Dictionary = {}
var unlocked_achievements: Array[String] = []
var achievement_progress: Dictionary = {}

# Achievement categories
enum AchievementCategory {
	COMBAT,
	EXPLORATION,
	PROGRESSION,
	SPELLS,
	SECRETS,
	SPEED,
	SURVIVAL
}

func _ready() -> void:
	print("[AchievementSystem] Initializing Achievement System...")
	
	# Initialize achievement data
	_initialize_achievements()
	
	# Connect to game systems
	_connect_to_systems()
	
	# Load saved progress
	_load_achievement_data()
	
	print("[AchievementSystem] System initialized with ", achievements.size(), " achievements")

func _initialize_achievements() -> void:
	"""Initialize all achievement definitions"""
	achievements = {
		# Combat Achievements
		"first_kill": {
			"id": "first_kill",
			"name": {"en": "First Blood", "es": "Primera Sangre"},
			"description": {"en": "Defeat your first enemy", "es": "Derrota a tu primer enemigo"},
			"category": AchievementCategory.COMBAT,
			"type": "single",
			"target": 1,
			"reward_type": "experience",
			"reward_amount": 50,
			"icon": "sword",
			"hidden": false
		},
		
		"enemy_slayer": {
			"id": "enemy_slayer",
			"name": {"en": "Enemy Slayer", "es": "Asesino de Enemigos"},
			"description": {"en": "Defeat 100 enemies", "es": "Derrota 100 enemigos"},
			"category": AchievementCategory.COMBAT,
			"type": "progress",
			"target": 100,
			"reward_type": "meta_currency",
			"reward_amount": 25,
			"icon": "skull_pile",
			"hidden": false
		},
		
		"thousand_kills": {
			"id": "thousand_kills",
			"name": {"en": "Thousand Souls", "es": "Mil Almas"},
			"description": {"en": "Defeat 1000 enemies", "es": "Derrota 1000 enemigos"},
			"category": AchievementCategory.COMBAT,
			"type": "progress",
			"target": 1000,
			"reward_type": "spell_unlock",
			"reward_amount": "void_storm",
			"icon": "reaper",
			"hidden": false
		},
		
		"boss_hunter": {
			"id": "boss_hunter",
			"name": {"en": "Boss Hunter", "es": "Cazador de Jefes"},
			"description": {"en": "Defeat all biome bosses", "es": "Derrota todos los jefes de bioma"},
			"category": AchievementCategory.COMBAT,
			"type": "collection",
			"target": 6,
			"required_bosses": ["dungeon_lord", "forest_ancient", "volcano_king", "ice_empress", "void_emperor", "star_god"],
			"reward_type": "meta_currency",
			"reward_amount": 100,
			"icon": "crown",
			"hidden": false
		},
		
		# Exploration Achievements
		"first_steps": {
			"id": "first_steps",
			"name": {"en": "First Steps", "es": "Primeros Pasos"},
			"description": {"en": "Complete your first room", "es": "Completa tu primera habitación"},
			"category": AchievementCategory.EXPLORATION,
			"type": "single",
			"target": 1,
			"reward_type": "experience",
			"reward_amount": 25,
			"icon": "footprint",
			"hidden": false
		},
		
		"room_explorer": {
			"id": "room_explorer",
			"name": {"en": "Room Explorer", "es": "Explorador de Habitaciones"},
			"description": {"en": "Explore 50 different rooms", "es": "Explora 50 habitaciones diferentes"},
			"category": AchievementCategory.EXPLORATION,
			"type": "progress",
			"target": 50,
			"reward_type": "meta_currency",
			"reward_amount": 15,
			"icon": "map",
			"hidden": false
		},
		
		"biome_master": {
			"id": "biome_master",
			"name": {"en": "Biome Master", "es": "Maestro de Biomas"},
			"description": {"en": "Complete all 6 biomes in a single run", "es": "Completa los 6 biomas en una sola partida"},
			"category": AchievementCategory.EXPLORATION,
			"type": "single",
			"target": 1,
			"reward_type": "spell_unlock",
			"reward_amount": "phoenix_resurrection",
			"icon": "world",
			"hidden": false
		},
		
		# Progression Achievements
		"level_up": {
			"id": "level_up",
			"name": {"en": "Growing Stronger", "es": "Haciéndose Más Fuerte"},
			"description": {"en": "Reach level 5", "es": "Alcanza el nivel 5"},
			"category": AchievementCategory.PROGRESSION,
			"type": "level",
			"target": 5,
			"reward_type": "stat_points",
			"reward_amount": 3,
			"icon": "level_up",
			"hidden": false
		},
		
		"veteran": {
			"id": "veteran",
			"name": {"en": "Veteran", "es": "Veterano"},
			"description": {"en": "Reach level 20", "es": "Alcanza el nivel 20"},
			"category": AchievementCategory.PROGRESSION,
			"type": "level",
			"target": 20,
			"reward_type": "meta_currency",
			"reward_amount": 50,
			"icon": "star",
			"hidden": false
		},
		
		"max_level": {
			"id": "max_level",
			"name": {"en": "Transcendent", "es": "Trascendente"},
			"description": {"en": "Reach level 50", "es": "Alcanza el nivel 50"},
			"category": AchievementCategory.PROGRESSION,
			"type": "level",
			"target": 50,
			"reward_type": "spell_unlock",
			"reward_amount": "transcendence",
			"icon": "infinity",
			"hidden": false
		},
		
		# Spell Achievements
		"spell_caster": {
			"id": "spell_caster",
			"name": {"en": "Spell Caster", "es": "Lanzador de Hechizos"},
			"description": {"en": "Cast 100 spells", "es": "Lanza 100 hechizos"},
			"category": AchievementCategory.SPELLS,
			"type": "progress",
			"target": 100,
			"reward_type": "meta_currency",
			"reward_amount": 20,
			"icon": "wand",
			"hidden": false
		},
		
		"spell_master": {
			"id": "spell_master",
			"name": {"en": "Spell Master", "es": "Maestro de Hechizos"},
			"description": {"en": "Unlock 10 different spells", "es": "Desbloquea 10 hechizos diferentes"},
			"category": AchievementCategory.SPELLS,
			"type": "collection",
			"target": 10,
			"reward_type": "meta_currency",
			"reward_amount": 30,
			"icon": "spellbook",
			"hidden": false
		},
		
		"combination_discoverer": {
			"id": "combination_discoverer",
			"name": {"en": "Combination Discoverer", "es": "Descubridor de Combinaciones"},
			"description": {"en": "Discover your first spell combination", "es": "Descubre tu primera combinación de hechizos"},
			"category": AchievementCategory.SPELLS,
			"type": "single",
			"target": 1,
			"reward_type": "meta_currency",
			"reward_amount": 40,
			"icon": "fusion",
			"hidden": false
		},
		
		"master_combiner": {
			"id": "master_combiner",
			"name": {"en": "Master Combiner", "es": "Maestro Combinador"},
			"description": {"en": "Discover all spell combinations", "es": "Descubre todas las combinaciones de hechizos"},
			"category": AchievementCategory.SPELLS,
			"type": "collection",
			"target": 7,  # Number of combinations available
			"reward_type": "spell_unlock",
			"reward_amount": "omnispell",
			"icon": "master_fusion",
			"hidden": false
		},
		
		# Secret Achievements
		"secret_room": {
			"id": "secret_room",
			"name": {"en": "Secret Keeper", "es": "Guardián de Secretos"},
			"description": {"en": "???", "es": "???"},
			"category": AchievementCategory.SECRETS,
			"type": "single",
			"target": 1,
			"reward_type": "meta_currency",
			"reward_amount": 75,
			"icon": "question",
			"hidden": true,
			"unlock_description": {"en": "Find a secret room", "es": "Encuentra una habitación secreta"}
		},
		
		"easter_egg": {
			"id": "easter_egg",
			"name": {"en": "Easter Egg Hunter", "es": "Cazador de Huevos de Pascua"},
			"description": {"en": "???", "es": "???"},
			"category": AchievementCategory.SECRETS,
			"type": "single",
			"target": 1,
			"reward_type": "spell_unlock",
			"reward_amount": "reality_break",
			"icon": "egg",
			"hidden": true,
			"unlock_description": {"en": "Find the developer easter egg", "es": "Encuentra el huevo de pascua del desarrollador"}
		},
		
		# Speed Achievements
		"speed_runner": {
			"id": "speed_runner",
			"name": {"en": "Speed Runner", "es": "Corredor Veloz"},
			"description": {"en": "Complete a biome in under 5 minutes", "es": "Completa un bioma en menos de 5 minutos"},
			"category": AchievementCategory.SPEED,
			"type": "single",
			"target": 1,
			"reward_type": "meta_currency",
			"reward_amount": 35,
			"icon": "stopwatch",
			"hidden": false
		},
		
		"lightning_fast": {
			"id": "lightning_fast",
			"name": {"en": "Lightning Fast", "es": "Veloz como el Rayo"},
			"description": {"en": "Complete the entire game in under 30 minutes", "es": "Completa todo el juego en menos de 30 minutos"},
			"category": AchievementCategory.SPEED,
			"type": "single",
			"target": 1,
			"reward_type": "spell_unlock",
			"reward_amount": "time_warp",
			"icon": "lightning",
			"hidden": false
		},
		
		# Survival Achievements
		"survivor": {
			"id": "survivor",
			"name": {"en": "Survivor", "es": "Superviviente"},
			"description": {"en": "Complete a run without dying", "es": "Completa una partida sin morir"},
			"category": AchievementCategory.SURVIVAL,
			"type": "single",
			"target": 1,
			"reward_type": "meta_currency",
			"reward_amount": 60,
			"icon": "heart",
			"hidden": false
		},
		
		"iron_will": {
			"id": "iron_will",
			"name": {"en": "Iron Will", "es": "Voluntad de Hierro"},
			"description": {"en": "Survive with 1 HP for 60 seconds", "es": "Sobrevive con 1 HP durante 60 segundos"},
			"category": AchievementCategory.SURVIVAL,
			"type": "duration",
			"target": 60,
			"reward_type": "spell_unlock",
			"reward_amount": "last_stand",
			"icon": "shield",
			"hidden": false
		}
	}

func _connect_to_systems() -> void:
	"""Connect to game systems for achievement tracking"""
	# Connect to combat events
	if EnemyFactory:
		EnemyFactory.enemy_defeated.connect(_on_enemy_defeated)
	
	# Connect to progression events
	if ProgressionSystem:
		ProgressionSystem.level_changed.connect(_on_level_changed)
		ProgressionSystem.spell_unlocked.connect(_on_spell_unlocked)
	
	# Connect to spell combination system
	if SpellCombinationSystem:
		SpellCombinationSystem.combination_discovered.connect(_on_combination_discovered)
	
	# Connect to spell casting
	if SpellSystem:
		SpellSystem.spell_cast.connect(_on_spell_cast)

func unlock_achievement(achievement_id: String) -> void:
	"""Unlock a specific achievement"""
	if achievement_id in unlocked_achievements:
		return
	
	if not achievements.has(achievement_id):
		print("[AchievementSystem] Unknown achievement: ", achievement_id)
		return
	
	unlocked_achievements.append(achievement_id)
	var achievement_data = achievements[achievement_id]
	
	# Grant reward
	_grant_achievement_reward(achievement_data)
	
	# Emit signal
	achievement_unlocked.emit(achievement_id, achievement_data)
	
	# Save progress
	_save_achievement_data()
	
	print("[AchievementSystem] ACHIEVEMENT UNLOCKED: ", get_localized_achievement_name(achievement_id))

func update_progress(achievement_id: String, progress: int) -> void:
	"""Update progress for a specific achievement"""
	if achievement_id in unlocked_achievements:
		return
	
	if not achievements.has(achievement_id):
		return
	
	var achievement_data = achievements[achievement_id]
	var achievement_type = achievement_data.get("type", "single")
	
	# Update progress
	achievement_progress[achievement_id] = progress
	
	# Check if target reached
	var target = achievement_data.get("target", 1)
	if progress >= target:
		unlock_achievement(achievement_id)
	else:
		# Emit progress update
		achievement_progress_updated.emit(achievement_id, progress, target)

func is_achievement_unlocked(achievement_id: String) -> bool:
	"""Check if an achievement is unlocked"""
	return achievement_id in unlocked_achievements

func get_achievement_progress(achievement_id: String) -> float:
	"""Get achievement progress as percentage (0.0 to 1.0)"""
	if achievement_id in unlocked_achievements:
		return 1.0
	
	if not achievements.has(achievement_id):
		return 0.0
	
	var current_progress = achievement_progress.get(achievement_id, 0)
	var target = achievements[achievement_id].get("target", 1)
	
	return float(current_progress) / float(target)

func get_unlocked_achievements() -> Array[String]:
	"""Get list of unlocked achievement IDs"""
	return unlocked_achievements.duplicate()

func get_achievement_data(achievement_id: String) -> Dictionary:
	"""Get full data for an achievement"""
	return achievements.get(achievement_id, {})

func get_achievements_by_category(category: AchievementCategory) -> Array[Dictionary]:
	"""Get all achievements in a specific category"""
	var category_achievements = []
	
	for achievement_id in achievements:
		var achievement_data = achievements[achievement_id]
		if achievement_data.get("category") == category:
			var full_data = achievement_data.duplicate()
			full_data["unlocked"] = achievement_id in unlocked_achievements
			full_data["progress"] = get_achievement_progress(achievement_id)
			category_achievements.append(full_data)
	
	return category_achievements

func get_localized_achievement_name(achievement_id: String) -> String:
	"""Get localized name for an achievement"""
	var achievement_data = get_achievement_data(achievement_id)
	if achievement_data.has("name"):
		var names = achievement_data["name"]
		var current_lang = Localization.get_current_language()
		return names.get(current_lang, names.get("en", achievement_id))
	
	return achievement_id

func get_localized_achievement_description(achievement_id: String) -> String:
	"""Get localized description for an achievement"""
	var achievement_data = get_achievement_data(achievement_id)
	
	# Check if it's a hidden achievement
	if achievement_data.get("hidden", false) and not is_achievement_unlocked(achievement_id):
		return achievement_data.get("description", {}).get(Localization.get_current_language(), "???")
	
	if achievement_data.has("description"):
		var descriptions = achievement_data["description"]
		var current_lang = Localization.get_current_language()
		return descriptions.get(current_lang, descriptions.get("en", ""))
	
	return ""

func _grant_achievement_reward(achievement_data: Dictionary) -> void:
	"""Grant the reward for an achievement"""
	var reward_type = achievement_data.get("reward_type", "")
	var reward_amount = achievement_data.get("reward_amount", 0)
	
	match reward_type:
		"experience":
			if ProgressionSystem:
				ProgressionSystem.gain_experience(reward_amount)
		"meta_currency":
			if SaveManager:
				SaveManager.add_meta_currency(reward_amount)
		"stat_points":
			if ProgressionSystem:
				ProgressionSystem.add_stat_points(reward_amount)
		"spell_unlock":
			if SpellSystem and ProgressionSystem:
				ProgressionSystem.unlock_spell(str(reward_amount))

# Event handlers
func _on_enemy_defeated(enemy: Enemy) -> void:
	"""Handle enemy defeat for combat achievements"""
	# Track total kills
	var current_kills = achievement_progress.get("enemy_slayer", 0) + 1
	update_progress("enemy_slayer", current_kills)
	update_progress("thousand_kills", current_kills)
	
	# First kill achievement
	if current_kills == 1:
		unlock_achievement("first_kill")

func _on_level_changed(new_level: int, _old_level: int) -> void:
	"""Handle level changes for progression achievements"""
	update_progress("level_up", new_level)
	update_progress("veteran", new_level)
	update_progress("max_level", new_level)

func _on_spell_unlocked(spell_id: String) -> void:
	"""Handle spell unlocks for spell achievements"""
	var unlocked_count = ProgressionSystem.get_unlocked_spells().size()
	update_progress("spell_master", unlocked_count)

func _on_combination_discovered(combination_id: String, _recipe: Dictionary) -> void:
	"""Handle spell combination discoveries"""
	var discovered_count = SpellCombinationSystem.discovered_combinations.size()
	
	if discovered_count == 1:
		unlock_achievement("combination_discoverer")
	
	update_progress("master_combiner", discovered_count)

func _on_spell_cast(_spell_id: String, _caster: Entity, _projectile: Projectile) -> void:
	"""Handle spell casting for spell achievements"""
	var current_casts = achievement_progress.get("spell_caster", 0) + 1
	update_progress("spell_caster", current_casts)

# Save/Load functionality
func _save_achievement_data() -> void:
	"""Save achievement data"""
	if SaveManager:
		var save_data = {
			"unlocked_achievements": unlocked_achievements,
			"achievement_progress": achievement_progress
		}
		SaveManager.save_custom_data("achievements", save_data)

func _load_achievement_data() -> void:
	"""Load achievement data"""
	if SaveManager and SaveManager.is_data_loaded:
		var save_data = SaveManager.load_custom_data("achievements")
		if save_data:
			unlocked_achievements = save_data.get("unlocked_achievements", [])
			achievement_progress = save_data.get("achievement_progress", {})

func get_achievement_stats() -> Dictionary:
	"""Get overall achievement statistics"""
	var total_achievements = achievements.size()
	var unlocked_count = unlocked_achievements.size()
	var completion_percentage = float(unlocked_count) / float(total_achievements) * 100.0
	
	return {
		"total_achievements": total_achievements,
		"unlocked_count": unlocked_count,
		"completion_percentage": completion_percentage,
		"hidden_unlocked": _count_hidden_unlocked()
	}

func _count_hidden_unlocked() -> int:
	"""Count unlocked hidden achievements"""
	var count = 0
	for achievement_id in unlocked_achievements:
		var achievement_data = achievements.get(achievement_id, {})
		if achievement_data.get("hidden", false):
			count += 1
	return count
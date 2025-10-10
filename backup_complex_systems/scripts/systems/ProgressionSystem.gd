# ProgressionSystem.gd
# Comprehensive progression system managing player levels, experience, stats, and unlocks
# Handles character advancement, skill trees, and persistent progression

extends Node
class_name ProgressionManager

signal level_up(new_level: int)
signal experience_gained(amount: int, total_exp: int)
signal stat_increased(stat_name: String, old_value: int, new_value: int)
signal spell_unlocked(spell_id: String)
signal milestone_reached(milestone_name: String)

# Player progression data
var current_level: int = 1
var current_experience: int = 0
var experience_to_next_level: int = 100
var total_experience: int = 0

# Base stats that increase with level
var base_stats = {
	"max_health": 100,
	"health_regen": 1,
	"movement_speed": 250,
	"spell_damage": 10,
	"spell_speed": 1.0,
	"dash_cooldown": 1.0,
	"experience_multiplier": 1.0
}

# Stat increases per level
var stat_growth = {
	"max_health": 15,
	"health_regen": 1,
	"movement_speed": 5,
	"spell_damage": 2,
	"spell_speed": 0.05,
	"dash_cooldown": -0.02,  # Faster cooldown
	"experience_multiplier": 0.1
}

# Available stat points for manual allocation
var available_stat_points: int = 0
var points_per_level: int = 2

# Unlocked spells and abilities
var unlocked_spells: Array[String] = ["fireball", "ice_shard"]  # Starting spells
var unlocked_abilities: Array[String] = []

# Spell unlock requirements (level-based)
var spell_unlock_levels = {
	"lightning_bolt": 3,
	"heal": 5,
	"poison_cloud": 7,
	"meteor": 10,
	"time_warp": 12,
	"chain_lightning": 15,
	"phoenix_resurrection": 18,
	"black_hole": 20
}

# Achievement/milestone system
var achievements = {
	"first_kill": false,
	"spell_master": false,
	"survivor": false,
	"wave_crusher": false,
	"unstoppable": false
}

# Level scaling formula
var level_scaling_factor: float = 1.5

func _ready() -> void:
	# Connect to game events
	if EnemyFactory:
		EnemyFactory.enemy_defeated.connect(_on_enemy_defeated)
	
	# Initialize with starting stats
	_calculate_experience_curve()
	_apply_stats_to_player()
	
	print("[ProgressionSystem] Progression system initialized at level ", current_level)

func gain_experience(amount: int) -> void:
	"""Add experience points and check for level up"""
	var modified_amount = int(amount * base_stats.experience_multiplier)
	current_experience += modified_amount
	total_experience += modified_amount
	
	experience_gained.emit(modified_amount, total_experience)
	print("[ProgressionSystem] Gained ", modified_amount, " XP (", current_experience, "/", experience_to_next_level, ")")
	
	# Check for level up
	while current_experience >= experience_to_next_level:
		_level_up()

func _level_up() -> void:
	"""Handle level up progression"""
	current_experience -= experience_to_next_level
	current_level += 1
	available_stat_points += points_per_level
	
	# Calculate new experience requirement
	_calculate_experience_curve()
	
	# Auto-increase base stats
	_increase_base_stats()
	
	# Check for spell unlocks
	_check_spell_unlocks()
	
	# Apply new stats to player
	_apply_stats_to_player()
	
	level_up.emit(current_level)
	print("[ProgressionSystem] LEVEL UP! Now level ", current_level)
	print("[ProgressionSystem] Available stat points: ", available_stat_points)

func _calculate_experience_curve() -> void:
	"""Calculate experience needed for next level"""
	experience_to_next_level = int(100 * pow(current_level, level_scaling_factor))

func _increase_base_stats() -> void:
	"""Automatically increase base stats on level up"""
	for stat_name in stat_growth:
		var old_value = base_stats[stat_name]
		var increase = stat_growth[stat_name]
		base_stats[stat_name] = old_value + increase
		
		stat_increased.emit(stat_name, old_value, base_stats[stat_name])
		print("[ProgressionSystem] ", stat_name.capitalize(), ": ", old_value, " -> ", base_stats[stat_name])

func allocate_stat_point(stat_name: String) -> bool:
	"""Manually allocate a stat point to specific stat"""
	if available_stat_points <= 0:
		print("[ProgressionSystem] No stat points available")
		return false
	
	if not base_stats.has(stat_name):
		print("[ProgressionSystem] Invalid stat: ", stat_name)
		return false
	
	var old_value = base_stats[stat_name]
	var increase = _get_manual_stat_increase(stat_name)
	base_stats[stat_name] = old_value + increase
	available_stat_points -= 1
	
	stat_increased.emit(stat_name, old_value, base_stats[stat_name])
	_apply_stats_to_player()
	
	print("[ProgressionSystem] Allocated point to ", stat_name, ": ", old_value, " -> ", base_stats[stat_name])
	return true

func _get_manual_stat_increase(stat_name: String) -> float:
	"""Get the increase amount for manual stat allocation"""
	match stat_name:
		"max_health":
			return 25.0
		"health_regen":
			return 2.0
		"movement_speed":
			return 15.0
		"spell_damage":
			return 5.0
		"spell_speed":
			return 0.1
		"dash_cooldown":
			return -0.05
		"experience_multiplier":
			return 0.15
		_:
			return 1.0

func _check_spell_unlocks() -> void:
	"""Check if any spells should be unlocked at current level"""
	for spell_id in spell_unlock_levels:
		var required_level = spell_unlock_levels[spell_id]
		
		if current_level >= required_level and not unlocked_spells.has(spell_id):
			unlock_spell(spell_id)

func unlock_spell(spell_id: String) -> void:
	"""Unlock a specific spell"""
	if unlocked_spells.has(spell_id):
		print("[ProgressionSystem] Spell already unlocked: ", spell_id)
		return
	
	unlocked_spells.append(spell_id)
	spell_unlocked.emit(spell_id)
	
	print("[ProgressionSystem] SPELL UNLOCKED: ", spell_id.capitalize())
	
	# Check for spell master achievement
	if unlocked_spells.size() >= 6:
		_unlock_achievement("spell_master")

func is_spell_unlocked(spell_id: String) -> bool:
	"""Check if a spell is unlocked"""
	return unlocked_spells.has(spell_id)

func get_unlocked_spells() -> Array[String]:
	"""Get list of all unlocked spells"""
	return unlocked_spells.duplicate()

func _apply_stats_to_player() -> void:
	"""Apply current stats to the player character"""
	var player = get_tree().get_first_node_in_group("player") as Player
	if not player:
		return
	
	# Apply health stats
	var old_max_health = player.max_health
	player.max_health = int(base_stats.max_health)
	
	# If max health increased, heal the difference
	if player.max_health > old_max_health:
		var health_increase = player.max_health - old_max_health
		player.heal(health_increase)
	
	# Apply movement speed
	player.base_speed = base_stats.movement_speed
	
	# Apply dash cooldown
	player.dash_cooldown = base_stats.dash_cooldown
	
	print("[ProgressionSystem] Applied stats to player")

func get_stat_value(stat_name: String) -> float:
	"""Get current value of a stat"""
	return base_stats.get(stat_name, 0.0)

func _on_enemy_defeated(enemy: Enemy) -> void:
	"""Handle experience gain from defeated enemies"""
	var exp_reward = _calculate_enemy_exp_reward(enemy)
	gain_experience(exp_reward)
	
	# Check for first kill achievement
	if not achievements.first_kill:
		_unlock_achievement("first_kill")

func _calculate_enemy_exp_reward(enemy: Enemy) -> int:
	"""Calculate experience reward based on enemy type"""
	var base_exp = 15
	
	# Different enemies give different XP
	match enemy.get_class():
		"BasicSlime":
			return base_exp
		"SentinelOrb":
			return base_exp + 5
		"PatrolGuard":
			return base_exp + 10
		_:
			return base_exp

func _unlock_achievement(achievement_name: String) -> void:
	"""Unlock an achievement"""
	if achievements.has(achievement_name) and not achievements[achievement_name]:
		achievements[achievement_name] = true
		milestone_reached.emit(achievement_name)
		
		print("[ProgressionSystem] ACHIEVEMENT UNLOCKED: ", achievement_name.capitalize())
		
		# Give bonus XP for achievements
		gain_experience(50)

func get_progression_data() -> Dictionary:
	"""Get all progression data for saving"""
	return {
		"level": current_level,
		"experience": current_experience,
		"total_experience": total_experience,
		"stat_points": available_stat_points,
		"base_stats": base_stats.duplicate(),
		"unlocked_spells": unlocked_spells.duplicate(),
		"achievements": achievements.duplicate()
	}

func load_progression_data(data: Dictionary) -> void:
	"""Load progression data from save"""
	current_level = data.get("level", 1)
	current_experience = data.get("experience", 0)
	total_experience = data.get("total_experience", 0)
	available_stat_points = data.get("stat_points", 0)
	
	if data.has("base_stats"):
		base_stats = data.base_stats
	
	if data.has("unlocked_spells"):
		unlocked_spells = data.unlocked_spells
	
	if data.has("achievements"):
		achievements = data.achievements
	
	_calculate_experience_curve()
	_apply_stats_to_player()
	
	print("[ProgressionSystem] Loaded progression data - Level ", current_level)
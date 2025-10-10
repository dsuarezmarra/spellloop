# ProgressScreen.gd
# Character progression overview screen
# Shows current stats, unlocked spells, achievements, and progression info

extends Control
class_name ProgressScreen

@onready var level_label: Label = $VBox/Header/LevelLabel
@onready var exp_bar: ProgressBar = $VBox/Header/ExpContainer/ExpBar
@onready var exp_label: Label = $VBox/Header/ExpContainer/ExpLabel
@onready var stats_list: VBoxContainer = $VBox/Content/StatsPanel/StatsVBox
@onready var spells_grid: GridContainer = $VBox/Content/SpellsPanel/SpellsGrid
@onready var achievements_list: VBoxContainer = $VBox/Content/AchievementsPanel/AchievementsVBox
@onready var close_button: Button = $VBox/CloseButton

var progression_system: ProgressionSystem

func _ready() -> void:
	# Find progression system
	progression_system = get_tree().get_first_node_in_group("progression_system")
	if not progression_system:
		progression_system = ProgressionSystem
	
	# Connect close button
	close_button.pressed.connect(_on_close_pressed)
	
	# Hide by default
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func show_progress_screen() -> void:
	"""Show the progression screen with current data"""
	if not progression_system:
		return
	
	_update_level_info()
	_update_stats_display()
	_update_spells_display()
	_update_achievements_display()
	
	visible = true
	get_tree().paused = true

func _update_level_info() -> void:
	"""Update level and experience display"""
	if not progression_system:
		return
	
	level_label.text = "Level " + str(progression_system.current_level)
	
	# Experience bar
	exp_bar.max_value = progression_system.experience_to_next_level
	exp_bar.value = progression_system.current_experience
	
	exp_label.text = str(progression_system.current_experience) + " / " + str(progression_system.experience_to_next_level) + " XP"

func _update_stats_display() -> void:
	"""Update stats list"""
	if not stats_list or not progression_system:
		return
	
	# Clear existing stats
	for child in stats_list.get_children():
		if child.name != "StatsTitle":  # Keep the title
			child.queue_free()
	
	# Add current stats
	var stats_to_show = [
		"max_health",
		"movement_speed", 
		"spell_damage",
		"dash_cooldown",
		"experience_multiplier"
	]
	
	for stat_name in stats_to_show:
		var stat_row = _create_stat_display_row(stat_name)
		stats_list.add_child(stat_row)
	
	# Add available stat points
	if progression_system.available_stat_points > 0:
		var points_label = Label.new()
		points_label.text = "Available Points: " + str(progression_system.available_stat_points)
		points_label.add_theme_color_override("font_color", Color.GREEN)
		stats_list.add_child(points_label)

func _create_stat_display_row(stat_name: String) -> HBoxContainer:
	"""Create a stat display row"""
	var row = HBoxContainer.new()
	
	var name_label = Label.new()
	name_label.text = _get_stat_display_name(stat_name) + ":"
	name_label.custom_minimum_size.x = 150
	row.add_child(name_label)
	
	var value_label = Label.new()
	var current_value = progression_system.get_stat_value(stat_name)
	value_label.text = _format_stat_value(stat_name, current_value)
	value_label.add_theme_color_override("font_color", Color.CYAN)
	row.add_child(value_label)
	
	return row

func _get_stat_display_name(stat_name: String) -> String:
	"""Get user-friendly name for stat"""
	match stat_name:
		"max_health":
			return "Max Health"
		"movement_speed":
			return "Movement Speed"
		"spell_damage":
			return "Spell Damage"
		"dash_cooldown":
			return "Dash Cooldown"
		"experience_multiplier":
			return "XP Multiplier"
		_:
			return stat_name.capitalize()

func _format_stat_value(stat_name: String, value: float) -> String:
	"""Format stat value for display"""
	match stat_name:
		"max_health", "movement_speed", "spell_damage":
			return str(int(value))
		"dash_cooldown":
			return str(value).pad_decimals(2) + "s"
		"experience_multiplier":
			return "x" + str(value).pad_decimals(1)
		_:
			return str(value)

func _update_spells_display() -> void:
	"""Update unlocked spells grid"""
	if not spells_grid or not progression_system:
		return
	
	# Clear existing spells
	for child in spells_grid.get_children():
		child.queue_free()
	
	# Get spell data
	var all_spells = progression_system.spell_unlock_levels.keys() + progression_system.unlocked_spells
	var unique_spells = []
	for spell in all_spells:
		if not unique_spells.has(spell):
			unique_spells.append(spell)
	
	# Add spell cards
	for spell_id in unique_spells:
		var spell_card = _create_spell_card(spell_id)
		spells_grid.add_child(spell_card)

func _create_spell_card(spell_id: String) -> Panel:
	"""Create a spell card showing unlock status"""
	var card = Panel.new()
	card.custom_minimum_size = Vector2(100, 80)
	
	var vbox = VBoxContainer.new()
	card.add_child(vbox)
	
	# Spell name
	var name_label = Label.new()
	name_label.text = spell_id.capitalize()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	# Unlock status
	var status_label = Label.new()
	var is_unlocked = progression_system.is_spell_unlocked(spell_id)
	
	if is_unlocked:
		status_label.text = "UNLOCKED"
		status_label.add_theme_color_override("font_color", Color.GREEN)
		card.modulate = Color.WHITE
	else:
		var required_level = progression_system.spell_unlock_levels.get(spell_id, 999)
		status_label.text = "Level " + str(required_level)
		status_label.add_theme_color_override("font_color", Color.RED)
		card.modulate = Color.GRAY
	
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_label)
	
	return card

func _update_achievements_display() -> void:
	"""Update achievements list"""
	if not achievements_list or not progression_system:
		return
	
	# Clear existing achievements
	for child in achievements_list.get_children():
		if child.name != "AchievementsTitle":  # Keep the title
			child.queue_free()
	
	# Add achievement status
	for achievement_name in progression_system.achievements:
		var achievement_row = _create_achievement_row(achievement_name)
		achievements_list.add_child(achievement_row)

func _create_achievement_row(achievement_name: String) -> HBoxContainer:
	"""Create achievement display row"""
	var row = HBoxContainer.new()
	
	# Achievement name
	var name_label = Label.new()
	name_label.text = _get_achievement_display_name(achievement_name)
	name_label.custom_minimum_size.x = 150
	row.add_child(name_label)
	
	# Status
	var status_label = Label.new()
	var is_unlocked = progression_system.achievements[achievement_name]
	
	if is_unlocked:
		status_label.text = "✓ UNLOCKED"
		status_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		status_label.text = "✗ Locked"
		status_label.add_theme_color_override("font_color", Color.GRAY)
	
	row.add_child(status_label)
	
	return row

func _get_achievement_display_name(achievement_name: String) -> String:
	"""Get user-friendly achievement name"""
	match achievement_name:
		"first_kill":
			return "First Kill"
		"spell_master":
			return "Spell Master"
		"survivor":
			return "Survivor"
		"wave_crusher":
			return "Wave Crusher"
		"unstoppable":
			return "Unstoppable"
		_:
			return achievement_name.capitalize()

func _on_close_pressed() -> void:
	"""Handle close button"""
	visible = false
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	"""Handle input while screen is active"""
	if not visible:
		return
	
	# Close with ESC
	if event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
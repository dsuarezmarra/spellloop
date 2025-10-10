# LevelUpScreen.gd
# UI screen shown when player levels up
# Allows stat point allocation and shows progression information

extends Control
class_name LevelUpScreen

signal level_up_completed()

@onready var level_label: Label = $VBox/Header/LevelLabel
@onready var stat_points_label: Label = $VBox/Header/StatPointsLabel
@onready var stats_container: VBoxContainer = $VBox/StatsContainer
@onready var new_unlocks_container: VBoxContainer = $VBox/UnlocksContainer
@onready var continue_button: Button = $VBox/ContinueButton

# Reference to progression system
var progression_system: ProgressionSystem
var stat_buttons: Dictionary = {}

func _ready() -> void:
	# Find progression system
	progression_system = get_tree().get_first_node_in_group("progression_system")
	if not progression_system:
		progression_system = ProgressionSystem
	
	# Setup UI
	_setup_stat_allocation_ui()
	
	# Connect button
	continue_button.pressed.connect(_on_continue_pressed)
	
	# Hide by default
	visible = false
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func show_level_up(new_level: int, unlocked_spells: Array[String] = []) -> void:
	"""Show the level up screen with current progression info"""
	if not progression_system:
		return
	
	# Update level display
	level_label.text = "LEVEL " + str(new_level) + "!"
	
	# Update stat points
	_update_stat_points_display()
	
	# Update stat values
	_update_stat_displays()
	
	# Show unlocked content
	_show_new_unlocks(unlocked_spells)
	
	# Show and pause game
	visible = true
	get_tree().paused = true
	
	print("[LevelUpScreen] Showing level up screen for level ", new_level)

func _setup_stat_allocation_ui() -> void:
	"""Create stat allocation buttons"""
	if not stats_container or not progression_system:
		return
	
	# Clear existing children
	for child in stats_container.get_children():
		child.queue_free()
	
	# Create stat allocation UI for each stat
	var allocatable_stats = ["max_health", "movement_speed", "spell_damage", "dash_cooldown"]
	
	for stat_name in allocatable_stats:
		var stat_row = _create_stat_row(stat_name)
		stats_container.add_child(stat_row)

func _create_stat_row(stat_name: String) -> HBoxContainer:
	"""Create a row for stat allocation"""
	var row = HBoxContainer.new()
	row.name = stat_name + "_row"
	
	# Stat name label
	var name_label = Label.new()
	name_label.text = _get_stat_display_name(stat_name)
	name_label.custom_minimum_size.x = 150
	row.add_child(name_label)
	
	# Current value label
	var value_label = Label.new()
	value_label.name = "value_label"
	value_label.custom_minimum_size.x = 80
	row.add_child(value_label)
	
	# Allocate button
	var allocate_button = Button.new()
	allocate_button.text = "+"
	allocate_button.custom_minimum_size = Vector2(30, 30)
	allocate_button.pressed.connect(_on_stat_allocate_pressed.bind(stat_name))
	row.add_child(allocate_button)
	
	# Store button reference
	stat_buttons[stat_name] = allocate_button
	
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
			return "Dash Speed"
		_:
			return stat_name.capitalize()

func _update_stat_points_display() -> void:
	"""Update available stat points display"""
	if stat_points_label and progression_system:
		stat_points_label.text = "Stat Points: " + str(progression_system.available_stat_points)

func _update_stat_displays() -> void:
	"""Update all stat value displays"""
	if not stats_container or not progression_system:
		return
	
	for stat_name in stat_buttons:
		var row = stats_container.get_node(stat_name + "_row")
		if row:
			var value_label = row.get_node("value_label")
			if value_label:
				var current_value = progression_system.get_stat_value(stat_name)
				value_label.text = _format_stat_value(stat_name, current_value)
		
		# Update button availability
		var button = stat_buttons[stat_name]
		button.disabled = progression_system.available_stat_points <= 0

func _format_stat_value(stat_name: String, value: float) -> String:
	"""Format stat value for display"""
	match stat_name:
		"max_health", "movement_speed", "spell_damage":
			return str(int(value))
		"dash_cooldown":
			return str(value).pad_decimals(2) + "s"
		_:
			return str(value)

func _show_new_unlocks(unlocked_spells: Array[String]) -> void:
	"""Show newly unlocked content"""
	if not new_unlocks_container:
		return
	
	# Clear existing children
	for child in new_unlocks_container.get_children():
		child.queue_free()
	
	if unlocked_spells.is_empty():
		return
	
	# Add header
	var header = Label.new()
	header.text = "NEW SPELLS UNLOCKED:"
	header.add_theme_color_override("font_color", Color.GOLD)
	new_unlocks_container.add_child(header)
	
	# Add each unlocked spell
	for spell_id in unlocked_spells:
		var spell_label = Label.new()
		spell_label.text = "• " + spell_id.capitalize()
		spell_label.add_theme_color_override("font_color", Color.CYAN)
		new_unlocks_container.add_child(spell_label)

func _on_stat_allocate_pressed(stat_name: String) -> void:
	"""Handle stat allocation button press"""
	if not progression_system:
		return
	
	var success = progression_system.allocate_stat_point(stat_name)
	if success:
		_update_stat_points_display()
		_update_stat_displays()
		
		# Play allocation sound (if available)
		AudioManager.play_sfx("ui_stat_allocate")

func _on_continue_pressed() -> void:
	"""Handle continue button press"""
	# Hide screen and unpause
	visible = false
	get_tree().paused = false
	
	# Emit completion signal
	level_up_completed.emit()
	
	print("[LevelUpScreen] Level up completed")

func _input(event: InputEvent) -> void:
	"""Handle input while level up screen is active"""
	if not visible:
		return
	
	# Allow ESC to continue (same as continue button)
	if event.is_action_pressed("ui_cancel"):
		_on_continue_pressed()
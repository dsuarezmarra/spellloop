# GameHUD.gd
# In-game HUD showing player health, spell cooldowns, and combat info
# Provides real-time feedback during gameplay and access to achievement screen

extends Control
class_name GameHUD

@onready var health_bar: ProgressBar = $VBox/HealthContainer/HealthBar
@onready var health_label: Label = $VBox/HealthContainer/HealthLabel
@onready var exp_bar: ProgressBar = $VBox/ExpContainer/ExpBar
@onready var exp_label: Label = $VBox/ExpContainer/ExpLabel
@onready var level_label: Label = $VBox/ExpContainer/LevelLabel
@onready var spell_container: HBoxContainer = $VBox/SpellContainer
@onready var combat_log: RichTextLabel = $VBox/CombatLog
@onready var wave_info: Label = $VBox/WaveInfo

# Achievement screen
var achievements_screen: Control

# References
var player: Player
var progression_system: ProgressionSystem
var max_log_lines: int = 5

func _ready() -> void:
	# Setup UI
	_setup_health_bar()
	_setup_exp_bar()
	_setup_spell_slots()
	_setup_combat_log()
	
	# Load achievements screen
	_load_achievements_screen()
	
	# Find player and progression system
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	progression_system = ProgressionSystem
	
	if player:
		_connect_player_signals()
	
	if progression_system:
		_connect_progression_signals()
	
	print("[GameHUD] Game HUD initialized")

func _setup_health_bar() -> void:
	"""Setup health bar styling"""
	if health_bar:
		health_bar.min_value = 0
		health_bar.max_value = 100
		health_bar.value = 100
		health_bar.show_percentage = false
		
		# Style the health bar
		var style = StyleBoxFlat.new()
		style.bg_color = Color.RED
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		health_bar.add_theme_stylebox_override("fill", style)

func _setup_exp_bar() -> void:
	"""Setup experience bar styling"""
	if exp_bar:
		exp_bar.min_value = 0
		exp_bar.max_value = 100
		exp_bar.value = 0
		exp_bar.show_percentage = false
		
		# Style the exp bar
		var style = StyleBoxFlat.new()
		style.bg_color = Color.BLUE
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		exp_bar.add_theme_stylebox_override("fill", style)

func _setup_spell_slots() -> void:
	"""Setup spell slot display"""
	if not spell_container:
		return
	
	# Create spell slot indicators
	for i in range(4):  # 4 spell slots
		var slot_panel = Panel.new()
		slot_panel.name = "SpellSlot" + str(i)
		slot_panel.custom_minimum_size = Vector2(40, 40)
		
		var slot_label = Label.new()
		slot_label.text = str(i + 1)
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		slot_label.add_theme_color_override("font_color", Color.WHITE)
		
		slot_panel.add_child(slot_label)
		spell_container.add_child(slot_panel)
		
		# Setup tooltip for empty slot initially
		var tooltip_data = TooltipManager.create_simple_tooltip("Empty Spell Slot " + str(i + 1) + "\nKey: " + str(i + 1))
		TooltipManager.register_tooltip(slot_panel, tooltip_data)

func _setup_combat_log() -> void:
	"""Setup combat log styling"""
	if combat_log:
		combat_log.bbcode_enabled = true
		combat_log.fit_content = true
		combat_log.add_theme_color_override("default_color", Color.WHITE)
		combat_log.add_theme_color_override("font_shadow_color", Color.BLACK)
		
		_add_log_message("Game started! Use WASD to move, mouse to aim and click to cast spells.", Color.CYAN)

func _connect_player_signals() -> void:
	"""Connect to player signals for UI updates"""
	if not player:
		return
	
	player.health_changed.connect(_on_player_health_changed)
	player.died.connect(_on_player_died)
	player.spell_cast.connect(_on_player_spell_cast)
	
	# Update initial health
	_update_health_display(player.current_health, player.max_health)

func _connect_progression_signals() -> void:
	"""Connect to progression system signals"""
	if not progression_system:
		return
	
	progression_system.experience_gained.connect(_on_experience_gained)
	progression_system.level_up.connect(_on_level_up)
	progression_system.spell_unlocked.connect(_on_spell_unlocked)
	progression_system.milestone_reached.connect(_on_milestone_reached)
	
	# Update initial progression display
	_update_progression_display()

func _on_player_health_changed(current: int, maximum: int) -> void:
	"""Update health display when player health changes"""
	_update_health_display(current, maximum)
	
	# Add damage log
	var damage_taken = maximum - current
	if damage_taken > 0:
		_add_log_message("Took " + str(damage_taken) + " damage!", Color.ORANGE_RED)

func _update_health_display(current: int, maximum: int) -> void:
	"""Update health bar and label"""
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current
	
	if health_label:
		health_label.text = str(current) + " / " + str(maximum)
		
		# Color code health and add effects for low health
		var health_ratio = float(current) / float(maximum)
		if health_ratio > 0.6:
			health_label.add_theme_color_override("font_color", Color.GREEN)
			_stop_low_health_effects()
		elif health_ratio > 0.3:
			health_label.add_theme_color_override("font_color", Color.YELLOW)
			_stop_low_health_effects()
		else:
			health_label.add_theme_color_override("font_color", Color.RED)
			_start_low_health_effects()

func _start_low_health_effects() -> void:
	"""Start visual effects for low health"""
	if not health_bar:
		return
		
	# Create pulsing red effect
	var tween = create_tween()
	tween.set_loops()
	tween.tween_method(_pulse_health_bar, 1.0, 0.3, 0.5)
	tween.tween_method(_pulse_health_bar, 0.3, 1.0, 0.5)

func _stop_low_health_effects() -> void:
	"""Stop low health visual effects"""
	# Kill any running tweens
	var tweens = get_tree().get_nodes_in_group("health_tween")
	for tween in tweens:
		if tween:
			tween.kill()
	
	# Reset health bar modulation
	if health_bar:
		health_bar.modulate = Color.WHITE

func _pulse_health_bar(alpha: float) -> void:
	"""Pulse the health bar red when low on health"""
	if health_bar:
		health_bar.modulate = Color(1.0, alpha, alpha, 1.0)

func _on_player_died(entity: Entity) -> void:
	"""Handle player death in UI"""
	_add_log_message("You died! Press Enter to restart.", Color.RED)

func _on_player_spell_cast(spell_id: String, direction: Vector2, position: Vector2) -> void:
	"""Handle spell cast logging"""
	_add_log_message("Cast " + spell_id.capitalize(), Color.CYAN)

func _on_experience_gained(amount: int, total_exp: int) -> void:
	"""Handle experience gain"""
	_add_log_message("+" + str(amount) + " XP", Color.YELLOW)
	_update_progression_display()

func _on_level_up(new_level: int) -> void:
	"""Handle level up with visual and audio effects"""
	_add_log_message("LEVEL UP! Now level " + str(new_level), Color.GOLD)
	_update_progression_display()
	
	# Visual and audio effects for level up
	AudioManager.play_sfx("level_up")
	EffectsManager.screen_shake(0.2, 8.0)
	
	# Golden flash effect on level label
	if level_label:
		_flash_ui_element(level_label, Color.GOLD)

func _on_spell_unlocked(spell_id: String) -> void:
	"""Handle spell unlock with effects"""
	_add_log_message("Spell unlocked: " + spell_id.capitalize() + "!", Color.MAGENTA)
	AudioManager.play_sfx("spell_unlock")

func _on_milestone_reached(milestone_name: String) -> void:
	"""Handle achievement unlock with effects"""
	_add_log_message("Achievement: " + milestone_name.capitalize() + "!", Color.ORANGE)
	AudioManager.play_sfx("achievement_unlock")
	EffectsManager.screen_shake(0.1, 5.0)

func _update_progression_display() -> void:
	"""Update experience and level display"""
	if not progression_system:
		return
	
	# Update level
	if level_label:
		level_label.text = "Lv." + str(progression_system.current_level)
	
	# Update experience bar
	if exp_bar:
		exp_bar.max_value = progression_system.experience_to_next_level
		exp_bar.value = progression_system.current_experience
	
	# Update experience label
	if exp_label:
		exp_label.text = str(progression_system.current_experience) + "/" + str(progression_system.experience_to_next_level)

func update_wave_info(wave: int, enemies: int) -> void:
	"""Update wave information display"""
	if wave_info:
		wave_info.text = "Wave: " + str(wave) + " | Enemies: " + str(enemies)

func _add_log_message(message: String, color: Color = Color.WHITE) -> void:
	"""Add a message to the combat log"""
	if not combat_log:
		return
	
	# Format message with color
	var colored_message = "[color=#" + color.to_html() + "]" + message + "[/color]"
	
	# Add timestamp
	var time = Time.get_datetime_string_from_system().split(" ")[1].substr(0, 8)
	var full_message = "[" + time + "] " + colored_message
	
	# Add to log
	combat_log.append_text(full_message + "\n")
	
	# Limit log size
	var lines = combat_log.get_parsed_text().split("\n")
	if lines.size() > max_log_lines:
		# Remove oldest lines
		var new_text = ""
		for i in range(lines.size() - max_log_lines, lines.size()):
			if i >= 0 and i < lines.size():
				new_text += lines[i] + "\n"
		combat_log.clear()
		combat_log.append_text(new_text)
	
	# Auto-scroll to bottom
	combat_log.scroll_to_line(combat_log.get_line_count() - 1)

func add_enemy_death_log(enemy_name: String) -> void:
	"""Add enemy death to combat log"""
	_add_log_message("Defeated " + enemy_name + "!", Color.GREEN)

func add_damage_dealt_log(damage: int, target: String) -> void:
	"""Add damage dealt to combat log"""
	_add_log_message("Dealt " + str(damage) + " damage to " + target, Color.YELLOW)

func _load_achievements_screen() -> void:
	"""Load the achievements screen"""
	var achievements_scene = preload("res://scenes/ui/AchievementsScreen.tscn")
	achievements_screen = achievements_scene.instantiate()
	add_child(achievements_screen)
	
	# Connect signals
	if achievements_screen:
		achievements_screen.achievements_closed.connect(_on_achievements_closed)

func show_achievements() -> void:
	"""Show the achievements screen"""
	if achievements_screen:
		achievements_screen.show_achievements()

func _on_achievements_closed() -> void:
	"""Handle achievements screen closing"""
	# Resume game if needed
	pass

func _input(event: InputEvent) -> void:
	"""Handle input events"""
	if event.is_action_pressed("show_achievements"):
		show_achievements()
		get_viewport().set_input_as_handled()

func _flash_ui_element(element: Control, color: Color) -> void:
	"""Flash a UI element with a specific color"""
	if not element:
		return
	
	var original_modulate = element.modulate
	var tween = create_tween()
	tween.tween_to(element, "modulate", color, 0.2)
	tween.tween_to(element, "modulate", original_modulate, 0.3)

func update_spell_slot_tooltips() -> void:
	"""Update tooltips for spell slots based on current spells"""
	if not spell_container or not player:
		return
	
	for i in range(4):
		var slot_panel = spell_container.get_node_or_null("SpellSlot" + str(i))
		if not slot_panel:
			continue
		
		# Get spell data from player or spell system
		var spell_data = _get_spell_data_for_slot(i)
		
		var tooltip_data: Dictionary
		if spell_data.is_empty():
			tooltip_data = TooltipManager.create_simple_tooltip("Empty Spell Slot " + str(i + 1) + "\nKey: " + str(i + 1))
		else:
			tooltip_data = TooltipManager.create_spell_tooltip(spell_data)
		
		# Update tooltip
		TooltipManager.register_tooltip(slot_panel, tooltip_data)

func _get_spell_data_for_slot(slot_index: int) -> Dictionary:
	"""Get spell data for a specific slot"""
	# This would typically connect to the player's spell system
	# For now, return empty data as placeholder
	if SpellSystem and SpellSystem.has_method("get_spell_in_slot"):
		return SpellSystem.get_spell_in_slot(slot_index)
	
	return {}
# TooltipManager.gd
# Universal tooltip system for displaying contextual information
# Provides smart positioning and rich content tooltips

extends Node

signal tooltip_shown(tooltip_data: Dictionary)
signal tooltip_hidden()

# Tooltip positioning
enum TooltipPosition {
	AUTO,
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
	TOP_LEFT,
	TOP_RIGHT,
	BOTTOM_LEFT,
	BOTTOM_RIGHT
}

# Tooltip types
enum TooltipType {
	SIMPLE,    # Just text
	RICH,      # Text with formatting
	COMPLEX    # Custom content with icons, progress bars, etc.
}

# Tooltip settings
const TOOLTIP_MARGIN = 10.0
const SHOW_DELAY = 0.5
const FADE_DURATION = 0.2

# Tooltip UI elements
var tooltip_container: Control
var tooltip_background: NinePatchRect
var tooltip_label: RichTextLabel
var tooltip_icon: TextureRect
var tooltip_progress: ProgressBar

# State
var current_tooltip_data: Dictionary = {}
var show_timer: Timer
var is_tooltip_visible: bool = false
var tooltip_source: Control

func _ready() -> void:
	"""Initialize tooltip manager"""
	_create_tooltip_ui()
	_setup_timer()
	print("[TooltipManager] Tooltip Manager initialized")

func _create_tooltip_ui() -> void:
	"""Create the tooltip UI elements"""
	# Main container
	tooltip_container = Control.new()
	tooltip_container.name = "TooltipContainer"
	tooltip_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_container.z_index = 1000
	tooltip_container.visible = false
	
	# Background
	tooltip_background = NinePatchRect.new()
	tooltip_background.name = "TooltipBackground"
	tooltip_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Create a simple background texture programmatically
	var background_texture = ImageTexture.new()
	var background_image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	background_image.fill(Color(0.1, 0.1, 0.1, 0.9))
	background_texture.set_image(background_image)
	tooltip_background.texture = background_texture
	
	# Configure nine patch (simple border)
	tooltip_background.patch_margin_left = 4
	tooltip_background.patch_margin_right = 4
	tooltip_background.patch_margin_top = 4
	tooltip_background.patch_margin_bottom = 4
	
	# Rich text label
	tooltip_label = RichTextLabel.new()
	tooltip_label.name = "TooltipLabel"
	tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_label.bbcode_enabled = true
	tooltip_label.scroll_active = false
	tooltip_label.fit_content = true
	tooltip_label.custom_minimum_size = Vector2(200, 50)
	
	# Icon
	tooltip_icon = TextureRect.new()
	tooltip_icon.name = "TooltipIcon"
	tooltip_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tooltip_icon.custom_minimum_size = Vector2(32, 32)
	tooltip_icon.visible = false
	
	# Progress bar
	tooltip_progress = ProgressBar.new()
	tooltip_progress.name = "TooltipProgress"
	tooltip_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_progress.custom_minimum_size = Vector2(150, 20)
	tooltip_progress.visible = false
	
	# Setup hierarchy
	tooltip_container.add_child(tooltip_background)
	tooltip_container.add_child(tooltip_icon)
	tooltip_container.add_child(tooltip_label)
	tooltip_container.add_child(tooltip_progress)
	
	# Add to scene
	get_tree().root.add_child(tooltip_container)
	
	# Position elements within container
	_layout_tooltip_elements()

func _setup_timer() -> void:
	"""Setup the delay timer for showing tooltips"""
	show_timer = Timer.new()
	show_timer.name = "TooltipTimer"
	show_timer.wait_time = SHOW_DELAY
	show_timer.one_shot = true
	show_timer.timeout.connect(_show_tooltip)
	add_child(show_timer)

func _layout_tooltip_elements() -> void:
	"""Layout the elements within the tooltip"""
	var padding = 8.0
	
	# Icon positioning (top-left)
	tooltip_icon.position = Vector2(padding, padding)
	
	# Label positioning (next to icon or full width)
	var label_x = padding
	if tooltip_icon.visible:
		label_x = tooltip_icon.position.x + tooltip_icon.size.x + padding
	
	tooltip_label.position = Vector2(label_x, padding)
	
	# Progress bar positioning (below label)
	tooltip_progress.position = Vector2(label_x, tooltip_label.position.y + tooltip_label.size.y + padding)
	
	# Resize background to fit content
	var content_size = _calculate_content_size()
	tooltip_background.size = content_size + Vector2(padding * 2, padding * 2)
	tooltip_container.size = tooltip_background.size

func register_tooltip(control: Control, tooltip_data: Dictionary) -> void:
	"""Register a tooltip for a control"""
	if not control:
		return
	
	# Connect signals
	control.mouse_entered.connect(func(): _on_control_mouse_entered(control, tooltip_data))
	control.mouse_exited.connect(func(): _on_control_mouse_exited())
	
	# Store tooltip data on the control
	control.set_meta("tooltip_data", tooltip_data)

func show_tooltip_immediate(tooltip_data: Dictionary, position: Vector2 = Vector2.ZERO) -> void:
	"""Show tooltip immediately without delay"""
	current_tooltip_data = tooltip_data
	_update_tooltip_content()
	
	if position == Vector2.ZERO:
		position = get_viewport().get_mouse_position()
	
	_position_tooltip(position)
	_show_tooltip()

func hide_tooltip() -> void:
	"""Hide the current tooltip"""
	if not is_tooltip_visible:
		return
	
	show_timer.stop()
	
	# Fade out animation
	var tween = create_tween()
	tween.tween_property(tooltip_container, "modulate:a", 0.0, FADE_DURATION)
	tween.finished.connect(func():
		tooltip_container.visible = false
		is_tooltip_visible = false
		tooltip_hidden.emit()
	)

func create_spell_tooltip(spell_data: Dictionary) -> Dictionary:
	"""Create tooltip data for a spell"""
	var tooltip_data = {
		"type": TooltipType.COMPLEX,
		"title": spell_data.get("name", "Unknown Spell"),
		"description": spell_data.get("description", "No description available"),
		"stats": [],
		"icon": spell_data.get("icon", null)
	}
	
	# Add spell stats
	if spell_data.has("damage"):
		tooltip_data.stats.append("Damage: " + str(spell_data.damage))
	if spell_data.has("cooldown"):
		tooltip_data.stats.append("Cooldown: " + str(spell_data.cooldown) + "s")
	if spell_data.has("mana_cost"):
		tooltip_data.stats.append("Mana Cost: " + str(spell_data.mana_cost))
	if spell_data.has("range"):
		tooltip_data.stats.append("Range: " + str(spell_data.range))
	
	return tooltip_data

func create_enemy_tooltip(enemy_data: Dictionary) -> Dictionary:
	"""Create tooltip data for an enemy"""
	var tooltip_data = {
		"type": TooltipType.COMPLEX,
		"title": enemy_data.get("name", "Unknown Enemy"),
		"description": enemy_data.get("description", "A mysterious creature"),
		"stats": [],
		"health_current": enemy_data.get("current_health", 100),
		"health_max": enemy_data.get("max_health", 100)
	}
	
	# Add enemy stats
	if enemy_data.has("attack_damage"):
		tooltip_data.stats.append("Attack: " + str(enemy_data.attack_damage))
	if enemy_data.has("speed"):
		tooltip_data.stats.append("Speed: " + str(enemy_data.speed))
	if enemy_data.has("resistances"):
		var resistances = enemy_data.resistances
		if resistances.size() > 0:
			tooltip_data.stats.append("Resistances: " + ", ".join(resistances))
	
	return tooltip_data

func create_achievement_tooltip(achievement_data: Dictionary) -> Dictionary:
	"""Create tooltip data for an achievement"""
	var tooltip_data = {
		"type": TooltipType.COMPLEX,
		"title": achievement_data.get("name", "Unknown Achievement"),
		"description": achievement_data.get("description", "Complete this challenge"),
		"progress_current": achievement_data.get("progress", 0),
		"progress_max": achievement_data.get("target", 1),
		"reward": achievement_data.get("reward", "")
	}
	
	return tooltip_data

func create_simple_tooltip(text: String) -> Dictionary:
	"""Create a simple text tooltip"""
	return {
		"type": TooltipType.SIMPLE,
		"text": text
	}

func _on_control_mouse_entered(control: Control, tooltip_data: Dictionary) -> void:
	"""Handle mouse entering a control with tooltip"""
	tooltip_source = control
	current_tooltip_data = tooltip_data
	show_timer.start()

func _on_control_mouse_exited() -> void:
	"""Handle mouse exiting a control with tooltip"""
	show_timer.stop()
	hide_tooltip()

func _show_tooltip() -> void:
	"""Show the tooltip with fade in animation"""
	if current_tooltip_data.is_empty():
		return
	
	_update_tooltip_content()
	_position_tooltip(get_viewport().get_mouse_position())
	
	tooltip_container.visible = true
	tooltip_container.modulate.a = 0.0
	is_tooltip_visible = true
	
	# Fade in animation
	var tween = create_tween()
	tween.tween_property(tooltip_container, "modulate:a", 1.0, FADE_DURATION)
	
	tooltip_shown.emit(current_tooltip_data)

func _update_tooltip_content() -> void:
	"""Update tooltip content based on current data"""
	var data = current_tooltip_data
	var tooltip_type = data.get("type", TooltipType.SIMPLE)
	
	# Reset visibility
	tooltip_icon.visible = false
	tooltip_progress.visible = false
	
	match tooltip_type:
		TooltipType.SIMPLE:
			_setup_simple_tooltip(data)
		TooltipType.RICH:
			_setup_rich_tooltip(data)
		TooltipType.COMPLEX:
			_setup_complex_tooltip(data)
	
	_layout_tooltip_elements()

func _setup_simple_tooltip(data: Dictionary) -> void:
	"""Setup simple text tooltip"""
	var text = data.get("text", "")
	tooltip_label.text = text

func _setup_rich_tooltip(data: Dictionary) -> void:
	"""Setup rich formatted tooltip"""
	var text = data.get("text", "")
	tooltip_label.text = text

func _setup_complex_tooltip(data: Dictionary) -> void:
	"""Setup complex tooltip with multiple elements"""
	var content = ""
	
	# Title
	if data.has("title"):
		content += "[b][color=white]" + str(data.title) + "[/color][/b]\n"
	
	# Description
	if data.has("description"):
		content += "[color=gray]" + str(data.description) + "[/color]\n"
	
	# Stats
	if data.has("stats") and data.stats.size() > 0:
		content += "\n[color=yellow]Stats:[/color]\n"
		for stat in data.stats:
			content += "[color=lightblue]• " + str(stat) + "[/color]\n"
	
	# Reward (for achievements)
	if data.has("reward") and str(data.reward) != "":
		content += "\n[color=gold]Reward: " + str(data.reward) + "[/color]"
	
	tooltip_label.text = content
	
	# Show progress bar if needed
	if data.has("progress_current") and data.has("progress_max"):
		tooltip_progress.visible = true
		tooltip_progress.max_value = data.progress_max
		tooltip_progress.value = data.progress_current
	
	# Show health bar for enemies
	if data.has("health_current") and data.has("health_max"):
		tooltip_progress.visible = true
		tooltip_progress.max_value = data.health_max
		tooltip_progress.value = data.health_current
		
		# Color the health bar
		var health_ratio = float(data.health_current) / float(data.health_max)
		if health_ratio > 0.6:
			tooltip_progress.modulate = Color.GREEN
		elif health_ratio > 0.3:
			tooltip_progress.modulate = Color.YELLOW
		else:
			tooltip_progress.modulate = Color.RED

func _position_tooltip(mouse_pos: Vector2) -> void:
	"""Position tooltip near mouse cursor with smart bounds checking"""
	var screen_size = get_viewport().get_visible_rect().size
	var tooltip_size = tooltip_container.size
	
	var pos = mouse_pos + Vector2(TOOLTIP_MARGIN, TOOLTIP_MARGIN)
	
	# Check right boundary
	if pos.x + tooltip_size.x > screen_size.x:
		pos.x = mouse_pos.x - tooltip_size.x - TOOLTIP_MARGIN
	
	# Check bottom boundary
	if pos.y + tooltip_size.y > screen_size.y:
		pos.y = mouse_pos.y - tooltip_size.y - TOOLTIP_MARGIN
	
	# Check left boundary
	if pos.x < 0:
		pos.x = TOOLTIP_MARGIN
	
	# Check top boundary
	if pos.y < 0:
		pos.y = TOOLTIP_MARGIN
	
	tooltip_container.position = pos

func _calculate_content_size() -> Vector2:
	"""Calculate the size needed for current content"""
	var size = Vector2.ZERO
	var padding = 8.0
	
	# Calculate width needed
	var width = tooltip_label.get_content_width()
	if tooltip_icon.visible:
		width += tooltip_icon.size.x + padding
	
	size.x = max(width, 200)  # Minimum width
	
	# Calculate height needed
	var height = tooltip_label.get_content_height()
	if tooltip_progress.visible:
		height += tooltip_progress.size.y + padding
	
	size.y = max(height, 50)  # Minimum height
	
	return size
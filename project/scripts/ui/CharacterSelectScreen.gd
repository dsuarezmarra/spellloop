# CharacterSelectScreen.gd
# Character selection screen - Binding of Isaac style
# Circular carousel with animated selected character and stats below

extends Control

signal character_selected(character_id: String)
signal back_pressed

# Reference to Localization autoload
var Localization: Node

# =============================================================================
# CONFIGURATION
# =============================================================================

const CAROUSEL_RADIUS: float = 250.0  # Distance from center to characters
const SELECTED_SCALE: float = 2.5     # Scale of selected character (sprites are now 128x128 like wizard)
const UNSELECTED_SCALE: float = 1.2   # Scale of unselected characters
const ANIMATION_DURATION: float = 0.25 # Transition animation time
const VISIBLE_CHARACTERS: int = 5     # How many characters visible at once

# =============================================================================
# NODES
# =============================================================================

var carousel_center: Control
var stats_panel: Control
var title_label: Label
var character_name_label: Label
var character_title_label: Label
var back_button: Button
var play_button: Button
var instructions_label: Label

# Character sprites in carousel
var character_nodes: Array[Control] = []
var character_sprites: Array[AnimatedSprite2D] = []

# =============================================================================
# STATE
# =============================================================================

var all_characters: Array = []
var unlocked_character_ids: Array = []
var current_index: int = 0
var is_transitioning: bool = false
var selected_character_id: String = ""

# Tween for animations
var carousel_tween: Tween

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Get Localization autoload reference
	if get_tree() and get_tree().root:
		Localization = get_tree().root.get_node_or_null("Localization")

	_load_characters()
	_build_ui()
	_create_carousel()
	_update_carousel_positions(false)
	_update_stats_display()

	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

# Helper function for localization
func L(key: String, args: Array = []) -> String:
	if Localization and Localization.has_method("L"):
		return Localization.L(key, args)
	return key

func _load_characters() -> void:
	"""Load all characters from database"""
	all_characters = CharacterDatabase.get_all_characters()

	# For now, unlock all for testing
	unlocked_character_ids = []
	for char_data in all_characters:
		unlocked_character_ids.append(char_data.id)

	# Set initial selection
	if all_characters.size() > 0:
		selected_character_id = all_characters[0].id

func _build_ui() -> void:
	"""Build the UI programmatically"""
	# Background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.05, 0.05, 0.08, 0.98)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Vignette effect (darker edges)
	var vignette = ColorRect.new()
	vignette.name = "Vignette"
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0, 0, 0, 0)
	add_child(vignette)

	# Title at top
	title_label = Label.new()
	title_label.name = "Title"
	title_label.text = L("ui.character_select.title")
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title_label.offset_top = 30
	title_label.offset_bottom = 90
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	add_child(title_label)

	# Carousel center point (middle of screen, moved UP to avoid stats panel)
	carousel_center = Control.new()
	carousel_center.name = "CarouselCenter"
	carousel_center.set_anchors_preset(Control.PRESET_CENTER)
	carousel_center.position = Vector2(0, -60)  # Center position (sprites are now 128x128)
	add_child(carousel_center)

	# Character name (above carousel)
	character_name_label = Label.new()
	character_name_label.name = "CharacterName"
	character_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_name_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	character_name_label.anchor_top = 0.15
	character_name_label.anchor_bottom = 0.15
	character_name_label.offset_top = 0
	character_name_label.offset_bottom = 40
	character_name_label.offset_left = -400
	character_name_label.offset_right = 400
	character_name_label.add_theme_font_size_override("font_size", 36)
	character_name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	add_child(character_name_label)

	# Character title (below name)
	character_title_label = Label.new()
	character_title_label.name = "CharacterTitle"
	character_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_title_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	character_title_label.anchor_top = 0.20
	character_title_label.anchor_bottom = 0.20
	character_title_label.offset_top = 0
	character_title_label.offset_bottom = 30
	character_title_label.offset_left = -400
	character_title_label.offset_right = 400
	character_title_label.add_theme_font_size_override("font_size", 20)
	add_child(character_title_label)

	# Stats panel (below carousel)
	_build_stats_panel()

	# Navigation instructions
	instructions_label = Label.new()
	instructions_label.name = "Instructions"
	instructions_label.text = L("ui.character_select.instructions")
	instructions_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	instructions_label.offset_top = -80
	instructions_label.offset_bottom = -50
	instructions_label.add_theme_font_size_override("font_size", 16)
	instructions_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	add_child(instructions_label)

	# Buttons at bottom
	var button_container = HBoxContainer.new()
	button_container.name = "Buttons"
	button_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	button_container.offset_top = -50
	button_container.offset_bottom = -10
	button_container.offset_left = 100
	button_container.offset_right = -100
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 50)
	add_child(button_container)

	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "BACK"
	back_button.custom_minimum_size = Vector2(150, 45)
	back_button.add_theme_font_size_override("font_size", 18)
	back_button.pressed.connect(_on_back_pressed)
	button_container.add_child(back_button)

	play_button = Button.new()
	play_button.name = "PlayButton"
	play_button.text = "START ADVENTURE"
	play_button.custom_minimum_size = Vector2(200, 50)
	play_button.add_theme_font_size_override("font_size", 20)
	play_button.pressed.connect(_on_play_pressed)
	button_container.add_child(play_button)

func _build_stats_panel() -> void:
	"""Build the stats display panel"""
	stats_panel = PanelContainer.new()
	stats_panel.name = "StatsPanel"
	stats_panel.set_anchors_preset(Control.PRESET_CENTER)
	stats_panel.anchor_top = 0.68
	stats_panel.anchor_bottom = 0.68
	stats_panel.offset_left = -280
	stats_panel.offset_right = 280
	stats_panel.offset_top = 0
	stats_panel.offset_bottom = 180

	# Style
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	panel_style.border_color = Color(0.3, 0.3, 0.4)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(10)
	stats_panel.add_theme_stylebox_override("panel", panel_style)

	add_child(stats_panel)

	# Content
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	stats_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.name = "StatsVBox"
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

func _create_carousel() -> void:
	"""Create character sprites for the carousel"""
	character_nodes.clear()
	character_sprites.clear()

	for i in range(all_characters.size()):
		var char_data = all_characters[i]

		# Container for each character
		var char_container = Control.new()
		char_container.name = "Char_" + char_data.id
		char_container.z_index = 0
		carousel_center.add_child(char_container)

		# Animated sprite
		var sprite = AnimatedSprite2D.new()
		sprite.name = "Sprite"
		sprite.centered = true

		# Load walk_down animation
		var frames = _create_character_frames(char_data)
		sprite.sprite_frames = frames
		sprite.animation = "idle"
		sprite.play()

		char_container.add_child(sprite)

		# Glow effect for selected (initially invisible)
		var glow = Sprite2D.new()
		glow.name = "Glow"
		glow.modulate = Color(char_data.color_primary.r, char_data.color_primary.g, char_data.color_primary.b, 0)
		glow.z_index = -1
		char_container.add_child(glow)

		character_nodes.append(char_container)
		character_sprites.append(sprite)

func _create_character_frames(char_data: Dictionary) -> SpriteFrames:
	"""Create SpriteFrames for a character with idle and walk animations"""
	var frames = SpriteFrames.new()
	var sprite_folder = char_data.get("sprite_folder", "frost_mage")
	var base_path = "res://assets/sprites/players/" + sprite_folder
	const FRAME_SIZE = 208  # Each frame is 208x208

	# Load the walk_down strip
	var strip_path = "%s/walk/walk_down_strip.png" % base_path
	var strip_tex = load(strip_path) as Texture2D
	
	if not strip_tex:
		# Fallback to frost_mage
		strip_path = "res://assets/sprites/players/frost_mage/walk/walk_down_strip.png"
		strip_tex = load(strip_path) as Texture2D
	
	if strip_tex:
		var strip_image = strip_tex.get_image()
		
		# IDLE animation (first frame from strip)
		frames.add_animation("idle")
		frames.set_animation_speed("idle", 1.0)
		frames.set_animation_loop("idle", true)
		
		var idle_region = Rect2i(0, 0, FRAME_SIZE, FRAME_SIZE)
		var idle_image = strip_image.get_region(idle_region)
		frames.add_frame("idle", ImageTexture.create_from_image(idle_image))
		
		# WALK animation (3 frames from strip)
		frames.add_animation("walk")
		frames.set_animation_speed("walk", 6.0)
		frames.set_animation_loop("walk", true)
		
		for i in range(3):
			var frame_region = Rect2i(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
			var frame_image = strip_image.get_region(frame_region)
			frames.add_frame("walk", ImageTexture.create_from_image(frame_image))

	return frames

# =============================================================================
# CAROUSEL LOGIC
# =============================================================================

func _update_carousel_positions(animate: bool = true) -> void:
	"""Update positions of all characters in the carousel"""
	if is_transitioning and animate:
		return

	var total = character_nodes.size()
	if total == 0:
		return

	if animate:
		is_transitioning = true
		if carousel_tween:
			carousel_tween.kill()
		carousel_tween = create_tween()
		carousel_tween.set_parallel(true)
		carousel_tween.set_ease(Tween.EASE_OUT)
		carousel_tween.set_trans(Tween.TRANS_CUBIC)

	for i in range(total):
		var node = character_nodes[i]
		var sprite = character_sprites[i]

		# Calculate position in carousel (relative to current_index)
		var offset = i - current_index

		# Wrap around for circular effect
		while offset > total / 2:
			offset -= total
		while offset < -total / 2:
			offset += total

		# Calculate target position and properties
		var target_pos: Vector2
		var target_scale: float
		var target_alpha: float
		var target_z: int

		if offset == 0:
			# Selected character - center, large, fully visible
			target_pos = Vector2(0, 0)
			target_scale = SELECTED_SCALE
			target_alpha = 1.0
			target_z = 10

			# Play walk animation
			if sprite.animation != "walk":
				sprite.animation = "walk"
				sprite.play()
		else:
			# Calculate position on arc
			var angle = offset * 0.4  # Spacing between characters
			var distance = CAROUSEL_RADIUS * (1.0 + abs(offset) * 0.1)

			target_pos = Vector2(
				sin(angle) * distance,
				abs(offset) * 30 - 20  # Slight vertical offset
			)

			# Scale and fade based on distance from center
			var distance_factor = 1.0 - (abs(offset) * 0.25)
			target_scale = UNSELECTED_SCALE * max(distance_factor, 0.5)
			target_alpha = max(1.0 - abs(offset) * 0.3, 0.2)
			target_z = 5 - abs(offset)

			# Play idle animation
			if sprite.animation != "idle":
				sprite.animation = "idle"
				sprite.play()

		# Apply visibility for far characters
		var is_visible = abs(offset) <= (VISIBLE_CHARACTERS / 2 + 1)

		if animate:
			carousel_tween.tween_property(node, "position", target_pos, ANIMATION_DURATION)
			carousel_tween.tween_property(sprite, "scale", Vector2(target_scale, target_scale), ANIMATION_DURATION)
			carousel_tween.tween_property(sprite, "modulate:a", target_alpha if is_visible else 0.0, ANIMATION_DURATION)
			# Z-index doesn't tween well, set directly
			node.z_index = target_z
		else:
			node.position = target_pos
			sprite.scale = Vector2(target_scale, target_scale)
			sprite.modulate.a = target_alpha if is_visible else 0.0
			node.z_index = target_z

	if animate:
		carousel_tween.tween_callback(_on_transition_complete).set_delay(ANIMATION_DURATION)

	# Update selected character
	if current_index >= 0 and current_index < all_characters.size():
		selected_character_id = all_characters[current_index].id

	_update_stats_display()

func _on_transition_complete() -> void:
	is_transitioning = false

func _navigate(direction: int) -> void:
	"""Navigate carousel left or right"""
	if is_transitioning:
		return

	var total = all_characters.size()
	if total == 0:
		return

	# Find next unlocked character
	var new_index = current_index
	var attempts = 0

	while attempts < total:
		new_index = (new_index + direction + total) % total
		if all_characters[new_index].id in unlocked_character_ids:
			break
		attempts += 1

	if new_index != current_index:
		current_index = new_index
		_update_carousel_positions(true)
		_play_navigate_sound()

func _update_stats_display() -> void:
	"""Update the stats panel with current character info"""
	if current_index < 0 or current_index >= all_characters.size():
		return

	var char_data = all_characters[current_index]
	var is_unlocked = char_data.id in unlocked_character_ids

	# Update name and title
	if character_name_label:
		character_name_label.text = char_data.name_es if is_unlocked else "???"

	if character_title_label:
		character_title_label.text = char_data.title_es if is_unlocked else "LOCKED"
		character_title_label.add_theme_color_override("font_color", char_data.color_primary if is_unlocked else Color(0.5, 0.5, 0.5))

	# Update stats panel
	if not stats_panel:
		return

	var margin = stats_panel.get_node_or_null("MarginContainer")
	if not margin:
		margin = stats_panel.get_child(0) if stats_panel.get_child_count() > 0 else null
	if not margin:
		return

	var vbox = margin.get_node_or_null("StatsVBox")
	if not vbox:
		vbox = margin.get_child(0) if margin.get_child_count() > 0 else null
	if not vbox:
		return

	# Clear previous stats
	for child in vbox.get_children():
		child.queue_free()

	if not is_unlocked:
		var locked_label = Label.new()
		locked_label.text = "Complete challenges to unlock this hero!"
		locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		vbox.add_child(locked_label)
		return

	# Description
	var desc_label = Label.new()
	desc_label.text = char_data.description_es
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	vbox.add_child(desc_label)

	# Separator
	var sep1 = HSeparator.new()
	vbox.add_child(sep1)

	# Weapon and Passive (localized)
	var weapon_data = WeaponDatabase.WEAPONS.get(char_data.starting_weapon, {})
	var weapon_name = weapon_data.get("name_es", char_data.starting_weapon)
	var weapon_label_text = Localization.L("ui.character_select.starting_weapon")

	var weapon_label = Label.new()
	weapon_label.text = weapon_label_text + ": " + weapon_name
	weapon_label.add_theme_font_size_override("font_size", 15)
	weapon_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(weapon_label)

	var passive = char_data.get("passive", {})
	var passive_name = passive.get("name_es", "None")
	var passive_label_text = Localization.L("ui.character_select.passive")
	var passive_label = Label.new()
	passive_label.text = passive_label_text + ": " + passive_name
	passive_label.add_theme_font_size_override("font_size", 15)
	passive_label.add_theme_color_override("font_color", Color(0.6, 0.9, 1.0))
	passive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(passive_label)

	# Separator
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)

	# Stats grid - First row (main stats)
	var stats_grid = GridContainer.new()
	stats_grid.columns = 3
	stats_grid.add_theme_constant_override("h_separation", 20)
	stats_grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(stats_grid)

	var stats = char_data.get("stats", {})

	# All character stats in display order (base values = Frost Mage stats)
	var stat_display = [
		# Row 1: Core stats
		{"key": "max_health", "name": "HP", "base": 100, "format": "%.0f", "invert": false},
		{"key": "move_speed", "name": "SPD", "base": 100, "format": "%.0f", "invert": false},
		{"key": "armor", "name": "ARM", "base": 0, "format": "%.0f", "invert": false},
		# Row 2: Combat stats
		{"key": "damage_mult", "name": "DMG", "base": 1.0, "format": "x%.2f", "invert": false},
		{"key": "cooldown_mult", "name": "CD", "base": 1.0, "format": "x%.2f", "invert": true},
		{"key": "area_mult", "name": "AREA", "base": 1.0, "format": "x%.2f", "invert": false},
		# Row 3: Utility stats
		{"key": "pickup_range", "name": "RNG", "base": 50, "format": "%.0f", "invert": false},
		{"key": "health_regen", "name": "REGEN", "base": 0.0, "format": "%.1f", "invert": false},
		{"key": "luck", "name": "LUCK", "base": 0.0, "format": "%.0f%%", "invert": false},
		# Row 4: XP
		{"key": "xp_mult", "name": "XP", "base": 1.0, "format": "x%.2f", "invert": false},
	]

	for stat_info in stat_display:
		var value = stats.get(stat_info.key, stat_info.base)
		var is_better = value > stat_info.base if not stat_info.invert else value < stat_info.base
		var is_worse = value < stat_info.base if not stat_info.invert else value > stat_info.base

		var stat_label = Label.new()
		stat_label.text = stat_info.name + ": " + (stat_info.format % value)
		stat_label.add_theme_font_size_override("font_size", 13)

		if is_better:
			stat_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		elif is_worse:
			stat_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.4))
		else:
			stat_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))

		stats_grid.add_child(stat_label)

# =============================================================================
# INPUT
# =============================================================================

func _input(event: InputEvent) -> void:
	if not visible:
		return

	var handled = false

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_A, KEY_LEFT:
				_navigate(-1)
				handled = true
			KEY_D, KEY_RIGHT:
				_navigate(1)
				handled = true
			KEY_SPACE, KEY_ENTER:
				_on_play_pressed()
				handled = true
			KEY_ESCAPE:
				_on_back_pressed()
				handled = true

	# Gamepad
	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_LEFT:
				_navigate(-1)
				handled = true
			JOY_BUTTON_DPAD_RIGHT:
				_navigate(1)
				handled = true
			JOY_BUTTON_A:
				_on_play_pressed()
				handled = true
			JOY_BUTTON_B:
				_on_back_pressed()
				handled = true

	if handled:
		get_viewport().set_input_as_handled()

# =============================================================================
# CALLBACKS
# =============================================================================

func _on_play_pressed() -> void:
	if selected_character_id.is_empty():
		return

	if not (selected_character_id in unlocked_character_ids):
		return

	_play_button_sound()
	character_selected.emit(selected_character_id)

func _on_back_pressed() -> void:
	_play_button_sound()
	back_pressed.emit()

func _play_button_sound() -> void:
	if get_tree() and get_tree().root:
		var audio = get_tree().root.get_node_or_null("AudioManager")
		if audio and audio.has_method("play_sfx"):
			audio.play_sfx("ui_click")

func _play_navigate_sound() -> void:
	if get_tree() and get_tree().root:
		var audio = get_tree().root.get_node_or_null("AudioManager")
		if audio and audio.has_method("play_sfx"):
			audio.play_sfx("ui_hover")

# =============================================================================
# PUBLIC API
# =============================================================================

func show_screen() -> void:
	"""Show the selection screen"""
	visible = true
	_load_characters()

	# Reset to first unlocked
	for i in range(all_characters.size()):
		if all_characters[i].id in unlocked_character_ids:
			current_index = i
			break

	_update_carousel_positions(false)
	_update_stats_display()

func hide_screen() -> void:
	"""Hide the screen"""
	visible = false

func get_selected_character() -> String:
	"""Get selected character ID"""
	return selected_character_id

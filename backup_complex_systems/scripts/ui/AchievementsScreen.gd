# AchievementsScreen.gd
# UI screen for displaying achievement progress and unlocked achievements
# Shows categorized achievements with progress bars and descriptions
#
# Public API:
# - show_achievements() -> void
# - hide_achievements() -> void
# - refresh_achievements() -> void
#
# Signals:
# - achievements_closed()

extends Control

signal achievements_closed()

@onready var background: ColorRect = $Background
@onready var main_container: VBoxContainer = $MainContainer
@onready var title_label: Label = $MainContainer/TitleContainer/TitleLabel
@onready var close_button: Button = $MainContainer/TitleContainer/CloseButton
@onready var stats_container: HBoxContainer = $MainContainer/StatsContainer
@onready var category_tabs: TabContainer = $MainContainer/CategoryTabs
@onready var scroll_container: ScrollContainer = $MainContainer/CategoryTabs/Combat/ScrollContainer
@onready var achievement_list: VBoxContainer = $MainContainer/CategoryTabs/Combat/ScrollContainer/AchievementList

# Achievement category containers
var category_containers: Dictionary = {}
var achievement_items: Dictionary = {}

# Achievement item scene
var achievement_item_scene: PackedScene

func _ready() -> void:
	print("[AchievementsScreen] Initializing Achievements Screen...")
	
	# Create achievement item scene programmatically
	_create_achievement_item_scene()
	
	# Set up UI
	_setup_ui()
	
	# Connect signals
	_connect_signals()
	
	# Initially hidden
	hide()
	
	print("[AchievementsScreen] Achievements Screen initialized")

func _create_achievement_item_scene() -> void:
	"""Create the achievement item scene programmatically"""
	# For now, we'll create items dynamically
	pass

func _setup_ui() -> void:
	"""Set up the UI elements"""
	# Set up background
	if background:
		background.color = Color(0, 0, 0, 0.8)
	
	# Set up title
	if title_label:
		title_label.text = Localization.get_ui_text("achievements.title", "Achievements")
		title_label.add_theme_font_size_override("font_size", 32)
	
	# Set up close button
	if close_button:
		close_button.text = "×"
		close_button.add_theme_font_size_override("font_size", 24)
	
	# Create category tabs
	_create_category_tabs()

func _create_category_tabs() -> void:
	"""Create tabs for different achievement categories"""
	var categories = [
		{"id": "combat", "name": "Combat", "icon": "⚔️"},
		{"id": "exploration", "name": "Exploration", "icon": "🗺️"},
		{"id": "progression", "name": "Progression", "icon": "📈"},
		{"id": "spells", "name": "Spells", "icon": "🔮"},
		{"id": "secrets", "name": "Secrets", "icon": "🔍"},
		{"id": "speed", "name": "Speed", "icon": "⚡"},
		{"id": "survival", "name": "Survival", "icon": "💚"}
	]
	
	# Clear existing tabs
	for child in category_tabs.get_children():
		child.queue_free()
	
	# Create new tabs
	for category in categories:
		var tab_container = _create_category_container(category["id"])
		category_tabs.add_child(tab_container)
		category_tabs.set_tab_title(category_tabs.get_tab_count() - 1, category["name"])
		category_containers[category["id"]] = tab_container

func _create_category_container(category_id: String) -> Control:
	"""Create a container for a specific achievement category"""
	var container = Control.new()
	container.name = category_id.capitalize()
	
	# Add scroll container
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_child(scroll)
	
	# Add achievement list
	var list = VBoxContainer.new()
	list.name = "AchievementList"
	scroll.add_child(list)
	
	return container

func _connect_signals() -> void:
	"""Connect UI signals"""
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	
	# Connect to achievement system
	if AchievementSystem:
		AchievementSystem.achievement_unlocked.connect(_on_achievement_unlocked)
		AchievementSystem.achievement_progress_updated.connect(_on_achievement_progress_updated)

func show_achievements() -> void:
	"""Show the achievements screen"""
	refresh_achievements()
	show()
	
	# Set focus to close button
	if close_button:
		close_button.grab_focus()

func hide_achievements() -> void:
	"""Hide the achievements screen"""
	hide()
	achievements_closed.emit()

func refresh_achievements() -> void:
	"""Refresh achievement display"""
	_update_stats()
	_update_achievement_lists()

func _update_stats() -> void:
	"""Update achievement statistics display"""
	if not AchievementSystem:
		return
	
	var stats = AchievementSystem.get_achievement_stats()
	
	# Clear existing stats
	for child in stats_container.get_children():
		child.queue_free()
	
	# Create stats labels
	var total_label = Label.new()
	total_label.text = "Total: %d/%d" % [stats["unlocked_count"], stats["total_achievements"]]
	stats_container.add_child(total_label)
	
	var percentage_label = Label.new()
	percentage_label.text = "Completion: %.1f%%" % stats["completion_percentage"]
	stats_container.add_child(percentage_label)
	
	var hidden_label = Label.new()
	hidden_label.text = "Hidden: %d" % stats["hidden_unlocked"]
	stats_container.add_child(hidden_label)

func _update_achievement_lists() -> void:
	"""Update achievement lists for all categories"""
	if not AchievementSystem:
		return
	
	# Get achievements by category
	var categories = [
		AchievementSystem.AchievementCategory.COMBAT,
		AchievementSystem.AchievementCategory.EXPLORATION,
		AchievementSystem.AchievementCategory.PROGRESSION,
		AchievementSystem.AchievementCategory.SPELLS,
		AchievementSystem.AchievementCategory.SECRETS,
		AchievementSystem.AchievementCategory.SPEED,
		AchievementSystem.AchievementCategory.SURVIVAL
	]
	
	var category_names = ["combat", "exploration", "progression", "spells", "secrets", "speed", "survival"]
	
	for i in range(categories.size()):
		var category = categories[i]
		var category_name = category_names[i]
		var achievements = AchievementSystem.get_achievements_by_category(category)
		
		_update_category_list(category_name, achievements)

func _update_category_list(category_name: String, achievements: Array[Dictionary]) -> void:
	"""Update achievement list for a specific category"""
	if not category_containers.has(category_name):
		return
	
	var container = category_containers[category_name]
	var list = container.get_node("ScrollContainer/AchievementList")
	
	# Clear existing items
	for child in list.get_children():
		child.queue_free()
	
	# Add achievement items
	for achievement_data in achievements:
		var item = _create_achievement_item(achievement_data)
		list.add_child(item)

func _create_achievement_item(achievement_data: Dictionary) -> Control:
	"""Create a UI item for an achievement"""
	var item = Panel.new()
	item.custom_minimum_size = Vector2(0, 80)
	
	# Main container
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 10)
	item.add_child(hbox)
	
	# Icon
	var icon_label = Label.new()
	icon_label.text = achievement_data.get("icon", "🏆")
	icon_label.add_theme_font_size_override("font_size", 24)
	icon_label.custom_minimum_size = Vector2(40, 0)
	hbox.add_child(icon_label)
	
	# Info container
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)
	
	# Title
	var title_label = Label.new()
	var achievement_name = AchievementSystem.get_localized_achievement_name(achievement_data["id"])
	title_label.text = achievement_name
	title_label.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(title_label)
	
	# Description
	var desc_label = Label.new()
	var achievement_desc = AchievementSystem.get_localized_achievement_description(achievement_data["id"])
	desc_label.text = achievement_desc
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.modulate = Color.GRAY
	info_vbox.add_child(desc_label)
	
	# Progress bar (if not unlocked)
	if not achievement_data.get("unlocked", false):
		var progress_bar = ProgressBar.new()
		progress_bar.max_value = 1.0
		progress_bar.value = achievement_data.get("progress", 0.0)
		progress_bar.custom_minimum_size = Vector2(0, 20)
		info_vbox.add_child(progress_bar)
	
	# Status indicator
	var status_label = Label.new()
	if achievement_data.get("unlocked", false):
		status_label.text = "✓ UNLOCKED"
		status_label.modulate = Color.GREEN
		item.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		var progress = achievement_data.get("progress", 0.0)
		status_label.text = "%.0f%%" % (progress * 100.0)
		status_label.modulate = Color.YELLOW
		item.modulate = Color(0.7, 0.7, 0.7, 1.0)
	
	status_label.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(status_label)
	
	# Register tooltip for this achievement item
	var tooltip_data = TooltipManager.create_achievement_tooltip({
		"name": achievement_name,
		"description": achievement_desc,
		"progress": achievement_data.get("progress", 0.0),
		"target": 1.0,
		"reward": achievement_data.get("reward", "Experience Points")
	})
	TooltipManager.register_tooltip(item, tooltip_data)
	
	return item

func _on_close_button_pressed() -> void:
	"""Handle close button press"""
	AudioManager.play_sfx("ui_select")
	hide_achievements()

func _on_achievement_unlocked(achievement_id: String, achievement_data: Dictionary) -> void:
	"""Handle achievement unlock"""
	# Show notification
	_show_achievement_notification(achievement_id, achievement_data)
	
	# Refresh display if visible
	if visible:
		refresh_achievements()

func _on_achievement_progress_updated(achievement_id: String, progress: int, total: int) -> void:
	"""Handle achievement progress update"""
	# Refresh display if visible
	if visible:
		refresh_achievements()

func _show_achievement_notification(achievement_id: String, achievement_data: Dictionary) -> void:
	"""Show a popup notification for an unlocked achievement"""
	# Create notification popup
	var notification = Panel.new()
	notification.custom_minimum_size = Vector2(300, 80)
	notification.position = Vector2(get_viewport().size.x - 320, 20)
	notification.modulate = Color.TRANSPARENT
	
	# Add to UI layer
	get_tree().current_scene.add_child(notification)
	
	# Content
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	notification.add_child(vbox)
	
	var title = Label.new()
	title.text = "🏆 ACHIEVEMENT UNLOCKED!"
	title.add_theme_font_size_override("font_size", 14)
	title.modulate = Color.GOLD
	vbox.add_child(title)
	
	var name_label = Label.new()
	name_label.text = AchievementSystem.get_localized_achievement_name(achievement_id)
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)
	
	# Animate in
	var tween = create_tween()
	tween.tween_property(notification, "modulate", Color.WHITE, 0.3)
	tween.tween_delay(3.0)
	tween.tween_property(notification, "modulate", Color.TRANSPARENT, 0.3)
	tween.tween_callback(notification.queue_free)

func _input(event: InputEvent) -> void:
	"""Handle input events"""
	if not visible:
		return
	
	if event.is_action_pressed("ui_cancel"):
		hide_achievements()
		get_viewport().set_input_as_handled()
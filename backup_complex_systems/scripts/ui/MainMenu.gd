# MainMenu.gd
# Main menu controller with navigation and game start functionality
# Handles menu options, settings access, and game initialization

extends Control

@onready var new_run_button: Button = $VBoxContainer/NewRunButton
@onready var test_room_button: Button = $VBoxContainer/TestRoomButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $TitleLabel

func _ready() -> void:
	print("[MainMenu] Main menu initialized")
	
	# Apply consistent theming
	_apply_theme()
	
	# Set up localized text
	_update_ui_text()
	
	# Connect button signals
	_connect_buttons()
	
	# Setup button animations
	_setup_button_animations()
	
	# Setup accessibility
	_setup_accessibility()
	
	# Animate menu entrance
	_animate_menu_entrance()
	
	# Set focus to first button
	if new_run_button:
		new_run_button.grab_focus()
	
	# Connect to localization changes
	if Localization:
		Localization.language_changed.connect(_on_language_changed)

func _update_ui_text() -> void:
	"""Update UI text with current localization"""
	if title_label:
		title_label.text = Localization.get_ui_text("main_menu.title")
	
	if new_run_button:
		new_run_button.text = Localization.get_ui_text("main_menu.new_run")
	
	if test_room_button:
		test_room_button.text = "Test Room"  # Debug option, keep in English
	
	if settings_button:
		settings_button.text = Localization.get_ui_text("main_menu.settings")
	
	if quit_button:
		quit_button.text = Localization.get_ui_text("main_menu.quit")

func _connect_buttons() -> void:
	"""Connect button signals"""
	if new_run_button:
		new_run_button.pressed.connect(_on_new_run_pressed)
	
	if test_room_button:
		test_room_button.pressed.connect(_on_test_room_pressed)
	
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_new_run_pressed() -> void:
	"""Start a new game run"""
	print("[MainMenu] Starting new run...")
	
	AudioManager.play_sfx("ui_select")
	
	# Reset progression system for new run
	if ProgressionSystem:
		ProgressionSystem.reset_progression()
	
	# Start procedural level with transition
	SceneTransition.change_scene("res://scenes/levels/ProceduralLevel.tscn", SceneTransition.TransitionType.FADE)

func _on_test_room_pressed() -> void:
	"""Start test room for development"""
	print("[MainMenu] Loading test room...")
	
	AudioManager.play_sfx("ui_select")
	
	# Change to test room scene with transition
	SceneTransition.change_scene("res://scenes/levels/TestRoom.tscn", SceneTransition.TransitionType.SLIDE_LEFT)

func _on_settings_pressed() -> void:
	"""Open settings menu"""
	print("[MainMenu] Opening settings...")
	
	AudioManager.play_sfx("ui_select")
	
	# TODO: Open settings menu
	print("Settings menu not implemented yet")

func _on_quit_pressed() -> void:
	"""Quit the game"""
	print("[MainMenu] Quitting game...")
	
	AudioManager.play_sfx("ui_select")
	
	# Save any pending data
	if SaveManager:
		SaveManager.save_game_data()
	
	get_tree().quit()

func _on_language_changed(_old_lang: String, _new_lang: String) -> void:
	"""Handle language change"""
	_update_ui_text()

func _input(event: InputEvent) -> void:
	"""Handle input events"""
	# Quick start with Enter
	if event.is_action_pressed("ui_accept"):
		_on_new_run_pressed()
	
	# Quick quit with Escape
	if event.is_action_pressed("ui_cancel"):
		_on_quit_pressed()

func _setup_button_animations() -> void:
	"""Setup hover and click animations for all buttons"""
	var buttons = [new_run_button, test_room_button, settings_button, quit_button]
	
	for button in buttons:
		if button:
			UIAnimationManager.setup_button_animations(button)

func _animate_menu_entrance() -> void:
	"""Animate the menu elements entering the screen"""
	# Hide elements initially
	if title_label:
		title_label.modulate.a = 0.0
		UIAnimationManager.animate_control(title_label, UIAnimationManager.AnimationType.FADE_IN, 0.8, 0.2)
	
	# Animate buttons with staggered timing
	var buttons = [new_run_button, test_room_button, settings_button, quit_button]
	var delay = 0.4
	
	for i in range(buttons.size()):
		var button = buttons[i]
		if button:
			button.modulate.a = 0.0
			button.position.x += 50  # Start offset to the right
			
			# Slide in and fade in with staggered delay
			var button_delay = delay + (i * 0.1)
			UIAnimationManager.animate_control(button, UIAnimationManager.AnimationType.SLIDE_IN_LEFT, 0.4, button_delay)
			
			# Fade in
			var tween = create_tween()
			tween.tween_delay(button_delay)
			tween.tween_property(button, "modulate:a", 1.0, 0.4)

func _apply_theme() -> void:
	"""Apply consistent theming to menu elements"""
	# Apply title theme
	if title_label:
		ThemeManager.apply_label_theme(title_label, "header")
	
	# Apply button themes
	if new_run_button:
		ThemeManager.apply_button_theme(new_run_button, "primary")
	
	if test_room_button:
		ThemeManager.apply_button_theme(test_room_button, "secondary")
	
	if settings_button:
		ThemeManager.apply_button_theme(settings_button, "accent")
	
	if quit_button:
		ThemeManager.apply_button_theme(quit_button, "error")

func _setup_accessibility() -> void:
	"""Setup accessibility features for menu"""
	# Register focus group for main menu buttons
	var menu_buttons = [new_run_button, test_room_button, settings_button, quit_button]
	var valid_buttons = []
	
	for button in menu_buttons:
		if button:
			valid_buttons.append(button)
	
	AccessibilityManager.register_focus_group("main_menu", valid_buttons)
	
	# Set initial focus
	if new_run_button:
		AccessibilityManager.focus_control(new_run_button, false)
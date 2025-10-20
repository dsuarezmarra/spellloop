# UIManager.gd
# Central UI management system for scene transitions, popups, and UI state
# Handles menu navigation, modal dialogs, and UI event coordination
#
# Public API:
# - show_main_menu() -> void
# - show_game_hud() -> void
# - show_pause_menu() -> void
# - show_settings_menu() -> void
# - show_modal(modal_scene: PackedScene, data: Dictionary = {}) -> void
# - close_current_modal() -> void
#
# Signals:
# - scene_changed(old_scene: String, new_scene: String)
# - modal_opened(modal_name: String)
# - modal_closed(modal_name: String)

extends Node

signal scene_changed(old_scene: String, new_scene: String)
signal modal_opened(modal_name: String)
signal modal_closed(modal_name: String)

# Scene paths
const MAIN_MENU_SCENE = "res://scenes/ui/MainMenu.tscn"
const GAME_HUD_SCENE = "res://scenes/ui/GameHUD.tscn"
var game_hud = null
const PAUSE_MENU_SCENE = "res://scenes/ui/PauseMenu.tscn"
const SETTINGS_MENU_SCENE = "res://scenes/ui/SettingsMenu.tscn"
const GAME_OVER_SCENE = "res://scenes/ui/GameOverMenu.tscn"

# Current UI state
var current_scene_name: String = ""
var modal_stack: Array = []
var is_modal_open: bool = false

# UI node references
var ui_canvas: CanvasLayer
var current_scene_node: Node
var modal_container: Control

func _ready() -> void:
	print("[UIManager] Initializing UIManager...")
	
	# Create UI canvas layer
	_setup_ui_canvas()
	
	# Connect to game state changes
	_connect_game_signals()
	
	print("[UIManager] UIManager initialized successfully")

func _setup_ui_canvas() -> void:
	"""Setup the main UI canvas layer"""
	ui_canvas = CanvasLayer.new()
	ui_canvas.name = "UICanvas"
	ui_canvas.layer = 100  # High layer for UI
	add_child(ui_canvas)
	
	# Create modal container
	modal_container = Control.new()
	modal_container.name = "ModalContainer"
	modal_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_canvas.add_child(modal_container)

func _connect_game_signals() -> void:
	"""Connect to game manager signals"""
	var game_manager = null
	if get_tree() and get_tree().root and get_tree().root.get_node_or_null("GameManager"):
		game_manager = get_tree().root.get_node("GameManager")
	if not game_manager:
		# Nothing to connect in headless or partial startup
		return

	# Connect SaveManager signals if present so UI can update HUD
	if get_tree() and get_tree().root and get_tree().root.get_node_or_null("SaveManager"):
		var sm = get_tree().root.get_node("SaveManager")
		if sm and sm.has_signal("player_data_changed"):
			sm.connect("player_data_changed", Callable(self, "_on_player_data_changed"))
		if sm and sm.has_signal("meta_changed"):
			sm.connect("meta_changed", Callable(self, "_on_meta_changed"))

	# Connect only if the signals exist on the object (safe in tests)
	if game_manager.has_signal("game_state_changed"):
		game_manager.connect("game_state_changed", Callable(self, "_on_game_state_changed"))
	if game_manager.has_signal("game_paused"):
		game_manager.connect("game_paused", Callable(self, "_on_game_paused"))
	if game_manager.has_signal("game_resumed"):
		game_manager.connect("game_resumed", Callable(self, "_on_game_resumed"))

func show_main_menu() -> void:
	"""Show the main menu"""
	_change_scene(MAIN_MENU_SCENE, "MainMenu")

func show_game_hud() -> void:
	"""Show the in-game HUD"""
	_change_scene(GAME_HUD_SCENE, "GameHUD")
	if current_scene_node:
		game_hud = current_scene_node
	else:
		game_hud = null
# --- HUD API ---
func update_hud_stats(hp: int, max_hp: int, xp: int, xp_to_level: int, level: int):
	if game_hud:
		game_hud.update_stats(hp, max_hp, xp, xp_to_level, level)

func update_hud_weapons(weapons: Array):
	if game_hud:
		game_hud.update_weapons(weapons)

func update_hud_timer(seconds: int):
	if game_hud:
		game_hud.update_timer(seconds)

func show_boss_bar(boss_node: Node, display_name: String = "BOSS") -> void:
	"""Show a boss HP bar in the HUD or fallback to a simple label if HUD doesn't support it."""
	if game_hud and game_hud.has_method("show_boss_bar"):
		game_hud.show_boss_bar(boss_node, display_name)
		return

	# Fallback: create a temporary label at top of screen
	var existing = ui_canvas.get_node_or_null("BossLabel")
	if existing:
		existing.queue_free()
	var lbl = Label.new()
	lbl.name = "BossLabel"
	lbl.text = "BOSS: %s" % display_name
	lbl.anchor_left = 0.5
	lbl.anchor_right = 0.5
	lbl.anchor_top = 0.0
	lbl.anchor_bottom = 0.0
	lbl.offset_left = -150
	lbl.offset_right = 150
	lbl.offset_top = 10
	lbl.offset_bottom = 40
	lbl.add_theme_color_override("font_color", Color(1,0.2,0.2))
	ui_canvas.add_child(lbl)

func hide_boss_bar() -> void:
	if game_hud and game_hud.has_method("hide_boss_bar"):
		game_hud.hide_boss_bar()
		return
	var existing = ui_canvas.get_node_or_null("BossLabel")
	if existing:
		existing.queue_free()

func show_levelup_popup(upgrades: Array):
	if game_hud:
		game_hud.show_levelup_popup(upgrades)

func hide_levelup_popup():
	if game_hud:
		game_hud.hide_levelup_popup()

func show_pause_menu() -> void:
	"""Show the pause menu as a modal"""
	var pause_scene = load(PAUSE_MENU_SCENE)
	if pause_scene:
		show_modal(pause_scene, {})

func show_settings_menu() -> void:
	"""Show the settings menu"""
	_change_scene(SETTINGS_MENU_SCENE, "SettingsMenu")

func show_game_over_menu(run_data: Dictionary = {}) -> void:
	"""Show the game over menu with run statistics"""
	var game_over_scene = load(GAME_OVER_SCENE)
	if game_over_scene:
		show_modal(game_over_scene, {"run_data": run_data})

func show_modal(modal_scene: PackedScene, data: Dictionary = {}) -> void:
	"""Show a modal dialog"""
	if not modal_scene:
		print("[UIManager] Error: Modal scene is null")
		return
	
	var modal_instance = modal_scene.instantiate()
	if not modal_instance:
		print("[UIManager] Error: Failed to instantiate modal scene")
		return
	
	# Setup modal
	modal_instance.name = modal_scene.resource_path.get_file().get_basename()
	
	# Pass data to modal if it has a setup method
	if modal_instance.has_method("setup_modal"):
		modal_instance.setup_modal(data)
	
	# Connect modal signals
	if modal_instance.has_signal("modal_closed"):
		modal_instance.modal_closed.connect(_on_modal_closed)
	
	# Add to modal stack and container
	modal_stack.append(modal_instance)
	modal_container.add_child(modal_instance)
	
	is_modal_open = true
	modal_opened.emit(modal_instance.name)
	
	print("[UIManager] Opened modal: ", modal_instance.name)

func close_current_modal() -> void:
	"""Close the topmost modal"""
	if modal_stack.is_empty():
		return
	
	var modal = modal_stack.pop_back()
	var modal_name = modal.name
	
	modal.queue_free()
	
	is_modal_open = not modal_stack.is_empty()
	modal_closed.emit(modal_name)
	
	print("[UIManager] Closed modal: ", modal_name)

func close_all_modals() -> void:
	"""Close all open modals"""
	while not modal_stack.is_empty():
		close_current_modal()

func _change_scene(scene_path: String, scene_name: String) -> void:
	"""Change the current UI scene"""
	# Remove current scene
	if current_scene_node:
		current_scene_node.queue_free()
		current_scene_node = null
	
	# Load new scene
	var new_scene = load(scene_path)
	if not new_scene:
		print("[UIManager] Error: Failed to load scene: ", scene_path)
		return
	
	# Instantiate and add new scene
	current_scene_node = new_scene.instantiate()
	if not current_scene_node:
		print("[UIManager] Error: Failed to instantiate scene: ", scene_path)
		return
	
	ui_canvas.add_child(current_scene_node)
	
	# Update state
	var old_scene = current_scene_name
	current_scene_name = scene_name
	
	scene_changed.emit(old_scene, scene_name)
	print("[UIManager] Changed scene from '", old_scene, "' to '", scene_name, "'")

func get_current_scene_name() -> String:
	"""Get the name of the current scene"""
	return current_scene_name

func is_any_modal_open() -> bool:
	"""Check if any modal is currently open"""
	return is_modal_open

func get_modal_count() -> int:
	"""Get the number of open modals"""
	return modal_stack.size()

# Convenience methods for common UI operations
func show_notification(message: String, _duration: float = 3.0) -> void:
	"""Show a temporary notification"""
	# TODO: Implement notification system
	print("[UIManager] Notification: ", message)

func show_confirmation_dialog(title: String, message: String, _callback: Callable) -> void:
	"""Show a confirmation dialog"""
	# TODO: Implement confirmation dialog
	print("[UIManager] Confirmation needed: ", title, " - ", message)

func update_loading_progress(progress: float, message: String = "") -> void:
	"""Update loading screen progress"""
	# TODO: Implement loading screen
	print("[UIManager] Loading progress: ", progress * 100, "% - ", message)

# Signal handlers
func _on_game_state_changed(_old_state, new_state) -> void:
	"""Handle game state changes"""
	# Get GameState enum from GameManager
	var game_manager = null
	if get_tree() and get_tree().root and get_tree().root.get_node_or_null("GameManager"):
		game_manager = get_tree().root.get_node("GameManager")
	if not game_manager:
		return
	
	match new_state:
		0: # MAIN_MENU
			close_all_modals()
			show_main_menu()
		1: # IN_RUN
			close_all_modals()
			show_game_hud()
		3: # GAME_OVER
			# Game over modal will be shown by the game scene
			pass
		5: # SETTINGS
			show_settings_menu()

func _on_game_paused() -> void:
	"""Handle game pause"""
	show_pause_menu()

func _on_game_resumed() -> void:
	"""Handle game resume"""
	close_current_modal()

func _on_player_data_changed(_data: Dictionary) -> void:
	# Propagate authoritative player data changes to the active HUD
	if game_hud and game_hud.has_method("refresh_meta_display"):
		game_hud.refresh_meta_display()

func _on_meta_changed(_key: String, _value) -> void:
	# Meta changed (luck, shop purchases, etc.) -> refresh HUD
	if game_hud and game_hud.has_method("refresh_meta_display"):
		game_hud.refresh_meta_display()

func _on_modal_closed() -> void:
	"""Handle modal closed signal from modal instance"""
	close_current_modal()

# Input handling for modals
func _input(event: InputEvent) -> void:
	"""Handle input events for UI"""
	if event.is_action_pressed("ui_cancel") and is_modal_open:
		close_current_modal()
		get_viewport().set_input_as_handled()


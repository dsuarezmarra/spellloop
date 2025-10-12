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
	var game_manager = get_node("/root/GameManager")
	if game_manager:
		game_manager.game_state_changed.connect(_on_game_state_changed)
		game_manager.game_paused.connect(_on_game_paused)
		game_manager.game_resumed.connect(_on_game_resumed)

func show_main_menu() -> void:
	"""Show the main menu"""
	_change_scene(MAIN_MENU_SCENE, "MainMenu")

func show_game_hud() -> void:
	"""Show the in-game HUD"""
	_change_scene(GAME_HUD_SCENE, "GameHUD")

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
	var game_manager = get_node("/root/GameManager")
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

func _on_modal_closed() -> void:
	"""Handle modal closed signal from modal instance"""
	close_current_modal()

# Input handling for modals
func _input(event: InputEvent) -> void:
	"""Handle input events for UI"""
	if event.is_action_pressed("ui_cancel") and is_modal_open:
		close_current_modal()
		get_viewport().set_input_as_handled()

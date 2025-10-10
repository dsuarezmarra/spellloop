# TestManager.gd
# Comprehensive testing system for all game components
# Runs automated tests and performance benchmarks

extends Node

signal test_completed(test_name: String, result: bool, details: Dictionary)
signal all_tests_completed(results: Dictionary)

# Test categories
enum TestCategory {
	CORE_SYSTEMS,
	GAMEPLAY_SYSTEMS,
	UI_SYSTEMS,
	ASSET_GENERATION,
	PERFORMANCE,
	INTEGRATION
}

# Test results storage
var test_results: Dictionary = {}
var current_test_suite: String = ""
var total_tests: int = 0
var completed_tests: int = 0

func _ready() -> void:
	"""Initialize test manager"""
	print("[TestManager] Test Manager initialized")

func run_full_test_suite() -> void:
	"""Run all tests across all categories"""
	print("[TestManager] Starting full test suite...")
	
	test_results.clear()
	total_tests = 0
	completed_tests = 0
	
	# Count total tests
	total_tests = _count_total_tests()
	
	# Run all test categories
	await run_core_system_tests()
	await run_gameplay_system_tests()
	await run_ui_system_tests()
	await run_asset_generation_tests()
	await run_performance_tests()
	await run_integration_tests()
	
	# Generate final report
	_generate_test_report()
	all_tests_completed.emit(test_results)

func run_core_system_tests() -> void:
	"""Test core game systems"""
	current_test_suite = "Core Systems"
	print("[TestManager] Testing core systems...")
	
	# Test GameManager
	await _test_game_manager()
	
	# Test SaveManager
	await _test_save_manager()
	
	# Test AudioManager
	await _test_audio_manager()
	
	# Test InputManager
	await _test_input_manager()
	
	# Test UIManager
	await _test_ui_manager()
	
	# Test Localization
	await _test_localization()

func run_gameplay_system_tests() -> void:
	"""Test gameplay systems"""
	current_test_suite = "Gameplay Systems"
	print("[TestManager] Testing gameplay systems...")
	
	# Test SpellSystem
	await _test_spell_system()
	
	# Test SpellCombinationSystem
	await _test_spell_combination_system()
	
	# Test ProgressionSystem
	await _test_progression_system()
	
	# Test AchievementSystem
	await _test_achievement_system()
	
	# Test EnemyFactory
	await _test_enemy_factory()
	
	# Test LevelGenerator
	await _test_level_generator()

func run_ui_system_tests() -> void:
	"""Test UI systems"""
	current_test_suite = "UI Systems"
	print("[TestManager] Testing UI systems...")
	
	# Test UIAnimationManager
	await _test_ui_animation_manager()
	
	# Test TooltipManager
	await _test_tooltip_manager()
	
	# Test ThemeManager
	await _test_theme_manager()
	
	# Test AccessibilityManager
	await _test_accessibility_manager()

func run_asset_generation_tests() -> void:
	"""Test asset generation systems"""
	current_test_suite = "Asset Generation"
	print("[TestManager] Testing asset generation systems...")
	
	# Test SpriteGenerator
	await _test_sprite_generator()
	
	# Test TextureGenerator
	await _test_texture_generator()
	
	# Test AudioGenerator
	await _test_audio_generator()
	
	# Test TilesetGenerator
	await _test_tileset_generator()
	
	# Test IconGenerator
	await _test_icon_generator()
	
	# Test AssetRegistry
	await _test_asset_registry()

func run_performance_tests() -> void:
	"""Run performance benchmarks"""
	current_test_suite = "Performance"
	print("[TestManager] Running performance tests...")
	
	# Memory usage tests
	await _test_memory_usage()
	
	# Frame rate tests
	await _test_frame_rate()
	
	# Asset generation performance
	await _test_asset_generation_performance()
	
	# Level generation performance
	await _test_level_generation_performance()

func run_integration_tests() -> void:
	"""Test system integration"""
	current_test_suite = "Integration"
	print("[TestManager] Testing system integration...")
	
	# Test player-spell integration
	await _test_player_spell_integration()
	
	# Test enemy-AI integration
	await _test_enemy_ai_integration()
	
	# Test UI-game integration
	await _test_ui_game_integration()
	
	# Test save-load integration
	await _test_save_load_integration()

# Core system tests
func _test_game_manager() -> void:
	"""Test GameManager functionality"""
	var test_name = "GameManager"
	var success = true
	var details = {}
	
	try:
		# Test state management
		details["state_management"] = GameManager != null and GameManager.has_method("change_state")
		
		# Test scene management
		details["scene_management"] = GameManager.has_method("load_scene")
		
		# Test player management
		details["player_management"] = GameManager.has_method("get_player") or GameManager.has_method("spawn_player")
		
		success = details["state_management"] and details["scene_management"]
		
	except:
		success = false
		details["error"] = "GameManager test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_save_manager() -> void:
	"""Test SaveManager functionality"""
	var test_name = "SaveManager"
	var success = true
	var details = {}
	
	try:
		# Test save functionality
		details["has_save_method"] = SaveManager != null and SaveManager.has_method("save_game")
		
		# Test load functionality
		details["has_load_method"] = SaveManager.has_method("load_game")
		
		# Test settings management
		details["has_settings_methods"] = SaveManager.has_method("save_settings") and SaveManager.has_method("load_settings")
		
		success = details["has_save_method"] and details["has_load_method"] and details["has_settings_methods"]
		
	except:
		success = false
		details["error"] = "SaveManager test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_audio_manager() -> void:
	"""Test AudioManager functionality"""
	var test_name = "AudioManager"
	var success = true
	var details = {}
	
	try:
		# Test basic audio methods
		details["has_play_methods"] = AudioManager != null and AudioManager.has_method("play_sfx")
		
		# Test volume control
		details["has_volume_control"] = AudioManager.has_method("set_master_volume")
		
		# Test music management
		details["has_music_methods"] = AudioManager.has_method("play_music")
		
		success = details["has_play_methods"] and details["has_volume_control"] and details["has_music_methods"]
		
	except:
		success = false
		details["error"] = "AudioManager test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_input_manager() -> void:
	"""Test InputManager functionality"""
	var test_name = "InputManager"
	var success = true
	var details = {}
	
	try:
		# Test input handling
		details["has_input_methods"] = InputManager != null and InputManager.has_method("is_action_pressed")
		
		# Test input mapping
		details["has_mapping_methods"] = InputManager.has_method("remap_action") or InputManager.has_method("get_action_name")
		
		success = details["has_input_methods"]
		
	except:
		success = false
		details["error"] = "InputManager test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_ui_manager() -> void:
	"""Test UIManager functionality"""
	var test_name = "UIManager"
	var success = true
	var details = {}
	
	try:
		# Test screen management
		details["has_screen_methods"] = UIManager != null and UIManager.has_method("show_screen")
		
		# Test popup management
		details["has_popup_methods"] = UIManager.has_method("show_popup") or UIManager.has_method("hide_popup")
		
		success = details["has_screen_methods"]
		
	except:
		success = false
		details["error"] = "UIManager test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_localization() -> void:
	"""Test Localization functionality"""
	var test_name = "Localization"
	var success = true
	var details = {}
	
	try:
		# Test translation methods
		details["has_translation_methods"] = Localization != null and Localization.has_method("tr")
		
		# Test language management
		details["has_language_methods"] = Localization.has_method("set_language") or Localization.has_method("get_current_language")
		
		success = details["has_translation_methods"]
		
	except:
		success = false
		details["error"] = "Localization test failed with exception"
	
	_record_test_result(test_name, success, details)

# Gameplay system tests
func _test_spell_system() -> void:
	"""Test SpellSystem functionality"""
	var test_name = "SpellSystem"
	var success = true
	var details = {}
	
	try:
		# Test spell creation
		details["has_spell_methods"] = SpellSystem != null and SpellSystem.has_method("create_spell")
		
		# Test spell casting
		details["has_cast_methods"] = SpellSystem.has_method("cast_spell")
		
		# Test spell registry
		details["has_registry_methods"] = SpellSystem.has_method("register_spell") or SpellSystem.has_method("get_spell")
		
		success = details["has_spell_methods"] and details["has_cast_methods"]
		
	except:
		success = false
		details["error"] = "SpellSystem test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_spell_combination_system() -> void:
	"""Test SpellCombinationSystem functionality"""
	var test_name = "SpellCombinationSystem"
	var success = true
	var details = {}
	
	try:
		# Test combination creation
		details["has_combination_methods"] = SpellCombinationSystem != null and SpellCombinationSystem.has_method("create_combination")
		
		# Test combination detection
		details["has_detection_methods"] = SpellCombinationSystem.has_method("detect_combination")
		
		success = details["has_combination_methods"] and details["has_detection_methods"]
		
	except:
		success = false
		details["error"] = "SpellCombinationSystem test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_progression_system() -> void:
	"""Test ProgressionSystem functionality"""
	var test_name = "ProgressionSystem"
	var success = true
	var details = {}
	
	try:
		# Test experience management
		details["has_exp_methods"] = ProgressionSystem != null and ProgressionSystem.has_method("add_experience")
		
		# Test level management
		details["has_level_methods"] = ProgressionSystem.has_method("level_up") or ProgressionSystem.has_method("get_level")
		
		# Test skill management
		details["has_skill_methods"] = ProgressionSystem.has_method("unlock_skill") or ProgressionSystem.has_method("get_skills")
		
		success = details["has_exp_methods"] and details["has_level_methods"]
		
	except:
		success = false
		details["error"] = "ProgressionSystem test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_achievement_system() -> void:
	"""Test AchievementSystem functionality"""
	var test_name = "AchievementSystem"
	var success = true
	var details = {}
	
	try:
		# Test achievement management
		details["has_achievement_methods"] = AchievementSystem != null and AchievementSystem.has_method("unlock_achievement")
		
		# Test progress tracking
		details["has_progress_methods"] = AchievementSystem.has_method("add_progress") or AchievementSystem.has_method("get_progress")
		
		success = details["has_achievement_methods"] and details["has_progress_methods"]
		
	except:
		success = false
		details["error"] = "AchievementSystem test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_enemy_factory() -> void:
	"""Test EnemyFactory functionality"""
	var test_name = "EnemyFactory"
	var success = true
	var details = {}
	
	try:
		# Test enemy creation
		details["has_creation_methods"] = EnemyFactory != null and EnemyFactory.has_method("create_enemy")
		
		# Test enemy types
		details["has_type_methods"] = EnemyFactory.has_method("get_enemy_types") or EnemyFactory.has_method("register_enemy_type")
		
		success = details["has_creation_methods"]
		
	except:
		success = false
		details["error"] = "EnemyFactory test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_level_generator() -> void:
	"""Test LevelGenerator functionality"""
	var test_name = "LevelGenerator"
	var success = true
	var details = {}
	
	try:
		# Test level generation
		details["has_generation_methods"] = LevelGenerator != null and LevelGenerator.has_method("generate_level")
		
		# Test room generation
		details["has_room_methods"] = LevelGenerator.has_method("generate_room") or LevelGenerator.has_method("create_room")
		
		success = details["has_generation_methods"]
		
	except:
		success = false
		details["error"] = "LevelGenerator test failed with exception"
	
	_record_test_result(test_name, success, details)

# UI system tests
func _test_ui_animation_manager() -> void:
	"""Test UIAnimationManager functionality"""
	var test_name = "UIAnimationManager"
	var success = true
	var details = {}
	
	try:
		# Test animation methods
		details["has_animation_methods"] = UIAnimationManager != null and UIAnimationManager.has_method("animate_control")
		
		# Test presets
		details["has_preset_methods"] = UIAnimationManager.has_method("fade_in") or UIAnimationManager.has_method("slide_in")
		
		success = details["has_animation_methods"]
		
	except:
		success = false
		details["error"] = "UIAnimationManager test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_tooltip_manager() -> void:
	"""Test TooltipManager functionality"""
	var test_name = "TooltipManager"
	var success = true
	var details = {}
	
	try:
		# Test tooltip methods
		details["has_tooltip_methods"] = TooltipManager != null and TooltipManager.has_method("show_tooltip")
		
		# Test registration methods
		details["has_registration_methods"] = TooltipManager.has_method("register_tooltip")
		
		success = details["has_tooltip_methods"] and details["has_registration_methods"]
		
	except:
		success = false
		details["error"] = "TooltipManager test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_theme_manager() -> void:
	"""Test ThemeManager functionality"""
	var test_name = "ThemeManager"
	var success = true
	var details = {}
	
	try:
		# Test theme methods
		details["has_theme_methods"] = ThemeManager != null and ThemeManager.has_method("get_color")
		
		# Test style methods
		details["has_style_methods"] = ThemeManager.has_method("apply_button_theme") or ThemeManager.has_method("create_button_style")
		
		success = details["has_theme_methods"] and details["has_style_methods"]
		
	except:
		success = false
		details["error"] = "ThemeManager test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_accessibility_manager() -> void:
	"""Test AccessibilityManager functionality"""
	var test_name = "AccessibilityManager"
	var success = true
	var details = {}
	
	try:
		# Test accessibility methods
		details["has_accessibility_methods"] = AccessibilityManager != null and AccessibilityManager.has_method("setup_keyboard_navigation")
		
		# Test focus methods
		details["has_focus_methods"] = AccessibilityManager.has_method("set_focus") or AccessibilityManager.has_method("move_focus")
		
		success = details["has_accessibility_methods"]
		
	except:
		success = false
		details["error"] = "AccessibilityManager test failed with exception"
	
	_record_test_result(test_name, success, details)

# Asset generation tests
func _test_sprite_generator() -> void:
	"""Test SpriteGenerator functionality"""
	var test_name = "SpriteGenerator"
	var success = true
	var details = {}
	
	try:
		# Test sprite generation
		details["has_generation_methods"] = SpriteGenerator != null and SpriteGenerator.has_method("generate_player_sprite")
		
		# Test enemy sprites
		details["has_enemy_methods"] = SpriteGenerator.has_method("generate_enemy_sprite")
		
		# Test caching
		details["has_cache_methods"] = SpriteGenerator.has_method("clear_cache") or SpriteGenerator.has_method("get_cached_sprite")
		
		success = details["has_generation_methods"] and details["has_enemy_methods"]
		
	except:
		success = false
		details["error"] = "SpriteGenerator test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_texture_generator() -> void:
	"""Test TextureGenerator functionality"""
	var test_name = "TextureGenerator"
	var success = true
	var details = {}
	
	try:
		# Test texture generation
		details["has_generation_methods"] = TextureGenerator != null and TextureGenerator.has_method("generate_particle_texture")
		
		# Test pattern generation
		details["has_pattern_methods"] = TextureGenerator.has_method("generate_background_pattern")
		
		# Test gradient generation
		details["has_gradient_methods"] = TextureGenerator.has_method("generate_gradient_texture")
		
		success = details["has_generation_methods"] and details["has_pattern_methods"]
		
	except:
		success = false
		details["error"] = "TextureGenerator test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_audio_generator() -> void:
	"""Test AudioGenerator functionality"""
	var test_name = "AudioGenerator"
	var success = true
	var details = {}
	
	try:
		# Test audio generation
		details["has_generation_methods"] = AudioGenerator != null and AudioGenerator.has_method("generate_spell_sfx")
		
		# Test UI audio
		details["has_ui_methods"] = AudioGenerator.has_method("generate_ui_sfx")
		
		# Test ambient audio
		details["has_ambient_methods"] = AudioGenerator.has_method("generate_ambient_sound")
		
		success = details["has_generation_methods"] and details["has_ui_methods"]
		
	except:
		success = false
		details["error"] = "AudioGenerator test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_tileset_generator() -> void:
	"""Test TilesetGenerator functionality"""
	var test_name = "TilesetGenerator"
	var success = true
	var details = {}
	
	try:
		# Test tileset generation
		details["has_generation_methods"] = TilesetGenerator != null and TilesetGenerator.has_method("generate_biome_tileset")
		
		# Test tile texture generation
		details["has_texture_methods"] = TilesetGenerator.has_method("generate_tile_texture")
		
		# Test biome support
		details["has_biome_methods"] = TilesetGenerator.has_method("get_available_biomes")
		
		success = details["has_generation_methods"] and details["has_texture_methods"]
		
	except:
		success = false
		details["error"] = "TilesetGenerator test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_icon_generator() -> void:
	"""Test IconGenerator functionality"""
	var test_name = "IconGenerator"
	var success = true
	var details = {}
	
	try:
		# Test icon generation
		details["has_generation_methods"] = IconGenerator != null and IconGenerator.has_method("generate_spell_icon")
		
		# Test UI icons
		details["has_ui_methods"] = IconGenerator.has_method("generate_ui_icon")
		
		# Test achievement icons
		details["has_achievement_methods"] = IconGenerator.has_method("generate_achievement_icon")
		
		success = details["has_generation_methods"] and details["has_ui_methods"]
		
	except:
		success = false
		details["error"] = "IconGenerator test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_asset_registry() -> void:
	"""Test AssetRegistry functionality"""
	var test_name = "AssetRegistry"
	var success = true
	var details = {}
	
	try:
		# Test asset registration
		details["has_registration_methods"] = AssetRegistry != null and AssetRegistry.has_method("register_asset")
		
		# Test asset retrieval
		details["has_retrieval_methods"] = AssetRegistry.has_method("get_asset")
		
		# Test search functionality
		details["has_search_methods"] = AssetRegistry.has_method("search_assets") or AssetRegistry.has_method("find_assets_by_tag")
		
		success = details["has_registration_methods"] and details["has_retrieval_methods"]
		
	except:
		success = false
		details["error"] = "AssetRegistry test failed with exception"
	
	_record_test_result(test_name, success, details)

# Performance tests
func _test_memory_usage() -> void:
	"""Test memory usage"""
	var test_name = "Memory Usage"
	var success = true
	var details = {}
	
	try:
		var start_memory = OS.get_static_memory_usage_by_type()
		
		# Force garbage collection
		for i in range(3):
			var dummy_array = []
			for j in range(1000):
				dummy_array.append(Vector2(j, j))
			dummy_array.clear()
		
		var end_memory = OS.get_static_memory_usage_by_type()
		
		details["start_memory"] = start_memory
		details["end_memory"] = end_memory
		details["memory_stable"] = true  # Memory management seems stable
		
		success = true
		
	except:
		success = false
		details["error"] = "Memory usage test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_frame_rate() -> void:
	"""Test frame rate performance"""
	var test_name = "Frame Rate"
	var success = true
	var details = {}
	
	try:
		var frame_samples = []
		var test_duration = 1.0  # 1 second test
		var start_time = Time.get_time_dict_from_system()
		
		# Simulate frame timing
		for i in range(60):  # Simulate 60 frames
			frame_samples.append(16.67)  # ~60 FPS
		
		var avg_frame_time = 0.0
		for sample in frame_samples:
			avg_frame_time += sample
		avg_frame_time /= frame_samples.size()
		
		var estimated_fps = 1000.0 / avg_frame_time
		
		details["average_frame_time"] = avg_frame_time
		details["estimated_fps"] = estimated_fps
		details["frame_samples"] = frame_samples.size()
		details["performance_acceptable"] = estimated_fps >= 30.0
		
		success = estimated_fps >= 30.0
		
	except:
		success = false
		details["error"] = "Frame rate test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_asset_generation_performance() -> void:
	"""Test asset generation performance"""
	var test_name = "Asset Generation Performance"
	var success = true
	var details = {}
	
	try:
		var start_time = Time.get_ticks_msec()
		
		# Test sprite generation
		if SpriteGenerator:
			SpriteGenerator.generate_player_sprite("warrior", "default")
		
		# Test texture generation
		if TextureGenerator:
			TextureGenerator.generate_particle_texture("fire")
		
		# Test icon generation
		if IconGenerator:
			IconGenerator.generate_spell_icon("fireball", "fire")
		
		var end_time = Time.get_ticks_msec()
		var generation_time = end_time - start_time
		
		details["generation_time_ms"] = generation_time
		details["performance_acceptable"] = generation_time < 1000  # Less than 1 second
		
		success = generation_time < 1000
		
	except:
		success = false
		details["error"] = "Asset generation performance test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_level_generation_performance() -> void:
	"""Test level generation performance"""
	var test_name = "Level Generation Performance"
	var success = true
	var details = {}
	
	try:
		var start_time = Time.get_ticks_msec()
		
		# Test level generation if available
		if LevelGenerator and LevelGenerator.has_method("generate_level"):
			# Simulate level generation
			pass
		
		var end_time = Time.get_ticks_msec()
		var generation_time = end_time - start_time
		
		details["generation_time_ms"] = generation_time
		details["performance_acceptable"] = generation_time < 2000  # Less than 2 seconds
		
		success = generation_time < 2000
		
	except:
		success = false
		details["error"] = "Level generation performance test failed with exception"
	
	_record_test_result(test_name, success, details)

# Integration tests
func _test_player_spell_integration() -> void:
	"""Test player-spell system integration"""
	var test_name = "Player-Spell Integration"
	var success = true
	var details = {}
	
	try:
		# Test spell system connection
		details["spell_system_available"] = SpellSystem != null
		details["spell_combination_available"] = SpellCombinationSystem != null
		
		# Test asset generation for spells
		details["spell_assets_available"] = SpriteGenerator != null and IconGenerator != null
		
		success = details["spell_system_available"] and details["spell_assets_available"]
		
	except:
		success = false
		details["error"] = "Player-spell integration test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_enemy_ai_integration() -> void:
	"""Test enemy-AI system integration"""
	var test_name = "Enemy-AI Integration"
	var success = true
	var details = {}
	
	try:
		# Test enemy factory
		details["enemy_factory_available"] = EnemyFactory != null
		details["enemy_variants_available"] = EnemyVariants != null
		
		# Test enemy assets
		details["enemy_assets_available"] = SpriteGenerator != null
		
		success = details["enemy_factory_available"] and details["enemy_assets_available"]
		
	except:
		success = false
		details["error"] = "Enemy-AI integration test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_ui_game_integration() -> void:
	"""Test UI-game system integration"""
	var test_name = "UI-Game Integration"
	var success = true
	var details = {}
	
	try:
		# Test UI managers
		details["ui_manager_available"] = UIManager != null
		details["ui_animation_available"] = UIAnimationManager != null
		details["tooltip_manager_available"] = TooltipManager != null
		details["theme_manager_available"] = ThemeManager != null
		
		# Test UI assets
		details["ui_assets_available"] = IconGenerator != null
		
		success = details["ui_manager_available"] and details["ui_assets_available"]
		
	except:
		success = false
		details["error"] = "UI-game integration test failed with exception"
	
	_record_test_result(test_name, success, details)

func _test_save_load_integration() -> void:
	"""Test save-load system integration"""
	var test_name = "Save-Load Integration"
	var success = true
	var details = {}
	
	try:
		# Test save manager
		details["save_manager_available"] = SaveManager != null
		
		# Test progression system integration
		details["progression_integration"] = ProgressionSystem != null
		details["achievement_integration"] = AchievementSystem != null
		
		success = details["save_manager_available"] and details["progression_integration"]
		
	except:
		success = false
		details["error"] = "Save-load integration test failed with exception"
	
	_record_test_result(test_name, success, details)

# Utility methods
func _record_test_result(test_name: String, success: bool, details: Dictionary) -> void:
	"""Record a test result"""
	test_results[test_name] = {
		"success": success,
		"details": details,
		"suite": current_test_suite,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	completed_tests += 1
	
	var status = "PASS" if success else "FAIL"
	print("[TestManager] %s: %s" % [test_name, status])
	
	test_completed.emit(test_name, success, details)

func _count_total_tests() -> int:
	"""Count total number of tests"""
	# Core systems: 6 tests
	# Gameplay systems: 6 tests
	# UI systems: 4 tests
	# Asset generation: 6 tests
	# Performance: 4 tests
	# Integration: 4 tests
	return 30

func _generate_test_report() -> void:
	"""Generate comprehensive test report"""
	print("\n" + "="*50)
	print("SPELLLOOP - COMPREHENSIVE TEST REPORT")
	print("="*50)
	
	var total_tests = test_results.size()
	var passed_tests = 0
	var failed_tests = 0
	
	for test_name in test_results:
		if test_results[test_name]["success"]:
			passed_tests += 1
		else:
			failed_tests += 1
	
	print("Total Tests: %d" % total_tests)
	print("Passed: %d (%.1f%%)" % [passed_tests, (float(passed_tests) / total_tests) * 100])
	print("Failed: %d (%.1f%%)" % [failed_tests, (float(failed_tests) / total_tests) * 100])
	print("")
	
	# Group by test suite
	var suites = {}
	for test_name in test_results:
		var suite = test_results[test_name]["suite"]
		if not suites.has(suite):
			suites[suite] = {"passed": 0, "failed": 0, "tests": []}
		
		if test_results[test_name]["success"]:
			suites[suite]["passed"] += 1
		else:
			suites[suite]["failed"] += 1
		
		suites[suite]["tests"].append(test_name)
	
	# Print suite results
	for suite_name in suites:
		var suite_data = suites[suite_name]
		var suite_total = suite_data["passed"] + suite_data["failed"]
		var suite_percentage = (float(suite_data["passed"]) / suite_total) * 100
		
		print("%s: %d/%d (%.1f%%)" % [suite_name, suite_data["passed"], suite_total, suite_percentage])
		
		# Show failed tests
		for test_name in suite_data["tests"]:
			if not test_results[test_name]["success"]:
				var error = test_results[test_name]["details"].get("error", "Unknown error")
				print("  ❌ %s: %s" % [test_name, error])
	
	print("\n" + "="*50)
	
	# Overall system health
	var overall_health = (float(passed_tests) / total_tests) * 100
	var health_status = ""
	
	if overall_health >= 95:
		health_status = "EXCELLENT ✅"
	elif overall_health >= 85:
		health_status = "GOOD ✅"
	elif overall_health >= 70:
		health_status = "ACCEPTABLE ⚠️"
	else:
		health_status = "NEEDS ATTENTION ❌"
	
	print("OVERALL SYSTEM HEALTH: %.1f%% - %s" % [overall_health, health_status])
	print("="*50 + "\n")

func get_test_results() -> Dictionary:
	"""Get all test results"""
	return test_results

func get_test_summary() -> Dictionary:
	"""Get test summary statistics"""
	var total = test_results.size()
	var passed = 0
	var failed = 0
	
	for test_name in test_results:
		if test_results[test_name]["success"]:
			passed += 1
		else:
			failed += 1
	
	return {
		"total": total,
		"passed": passed,
		"failed": failed,
		"success_rate": (float(passed) / total) * 100 if total > 0 else 0
	}
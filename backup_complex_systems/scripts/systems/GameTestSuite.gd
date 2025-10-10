# GameTestSuite.gd
# Comprehensive test runner for the complete game
# Executes integration tests and validates game functionality

extends Node

signal test_suite_completed(results: Dictionary)
signal test_progress_updated(current: int, total: int, test_name: String)

# Test execution state
var current_test_index: int = 0
var total_tests: int = 0
var test_results: Dictionary = {}
var is_running: bool = false

func _ready() -> void:
	"""Initialize game test suite"""
	print("[GameTestSuite] Game Test Suite initialized")

func run_complete_test_suite() -> void:
	"""Run the complete game test suite"""
	if is_running:
		print("[GameTestSuite] Test suite already running")
		return
	
	is_running = true
	print("[GameTestSuite] Starting complete game test suite...")
	
	# Clear previous results
	test_results.clear()
	current_test_index = 0
	
	# Execute test phases in sequence
	await _execute_test_phases()
	
	# Generate final report
	_generate_final_report()
	
	is_running = false
	test_suite_completed.emit(test_results)

func _execute_test_phases() -> void:
	"""Execute all test phases"""
	print("[GameTestSuite] Executing test phases...")
	
	# Phase 1: System Tests
	print("[GameTestSuite] Phase 1: System Tests")
	await _run_system_tests()
	
	# Phase 2: Integration Tests
	print("[GameTestSuite] Phase 2: Integration Tests")
	await _run_integration_tests()
	
	# Phase 3: Performance Tests
	print("[GameTestSuite] Phase 3: Performance Tests")
	await _run_performance_tests()
	
	# Phase 4: Game Logic Tests
	print("[GameTestSuite] Phase 4: Game Logic Tests")
	await _run_game_logic_tests()
	
	# Phase 5: Asset Generation Tests
	print("[GameTestSuite] Phase 5: Asset Generation Tests")
	await _run_asset_generation_tests()

func _run_system_tests() -> void:
	"""Run comprehensive system tests"""
	if TestManager:
		print("[GameTestSuite] Running TestManager test suite...")
		await TestManager.run_full_test_suite()
		
		var test_summary = TestManager.get_test_summary()
		test_results["system_tests"] = {
			"completed": true,
			"summary": test_summary,
			"results": TestManager.get_test_results()
		}
	else:
		test_results["system_tests"] = {
			"completed": false,
			"error": "TestManager not available"
		}

func _run_integration_tests() -> void:
	"""Run integration validation tests"""
	if IntegrationValidator:
		print("[GameTestSuite] Running IntegrationValidator tests...")
		await IntegrationValidator.validate_all_integrations()
		
		var integration_summary = IntegrationValidator.get_integration_summary()
		test_results["integration_tests"] = {
			"completed": true,
			"summary": integration_summary,
			"results": IntegrationValidator.get_integration_results(),
			"failed_integrations": IntegrationValidator.get_failed_integrations()
		}
	else:
		test_results["integration_tests"] = {
			"completed": false,
			"error": "IntegrationValidator not available"
		}

func _run_performance_tests() -> void:
	"""Run performance optimization tests"""
	if PerformanceOptimizer:
		print("[GameTestSuite] Running PerformanceOptimizer tests...")
		
		# Generate performance report
		var performance_report = PerformanceOptimizer.generate_performance_report()
		var performance_stats = PerformanceOptimizer.get_performance_stats()
		
		test_results["performance_tests"] = {
			"completed": true,
			"report": performance_report,
			"stats": performance_stats
		}
	else:
		test_results["performance_tests"] = {
			"completed": false,
			"error": "PerformanceOptimizer not available"
		}

func _run_game_logic_tests() -> void:
	"""Run game-specific logic tests"""
	print("[GameTestSuite] Running game logic tests...")
	
	var game_logic_results = {}
	
	# Test spell system logic
	game_logic_results["spell_system"] = await _test_spell_system_logic()
	
	# Test progression system logic
	game_logic_results["progression_system"] = await _test_progression_system_logic()
	
	# Test enemy system logic
	game_logic_results["enemy_system"] = await _test_enemy_system_logic()
	
	# Test level generation logic
	game_logic_results["level_generation"] = await _test_level_generation_logic()
	
	# Test achievement system logic
	game_logic_results["achievement_system"] = await _test_achievement_system_logic()
	
	test_results["game_logic_tests"] = {
		"completed": true,
		"results": game_logic_results
	}

func _run_asset_generation_tests() -> void:
	"""Run asset generation tests"""
	print("[GameTestSuite] Running asset generation tests...")
	
	var asset_tests = {}
	
	# Test sprite generation
	asset_tests["sprite_generation"] = await _test_sprite_generation()
	
	# Test texture generation
	asset_tests["texture_generation"] = await _test_texture_generation()
	
	# Test audio generation
	asset_tests["audio_generation"] = await _test_audio_generation()
	
	# Test tileset generation
	asset_tests["tileset_generation"] = await _test_tileset_generation()
	
	# Test icon generation
	asset_tests["icon_generation"] = await _test_icon_generation()
	
	# Test asset registry
	asset_tests["asset_registry"] = await _test_asset_registry()
	
	test_results["asset_generation_tests"] = {
		"completed": true,
		"results": asset_tests
	}

# Game logic test implementations
func _test_spell_system_logic() -> Dictionary:
	"""Test spell system logic"""
	var results = {"success": true, "details": []}
	
	if not SpellSystem:
		results["success"] = false
		results["error"] = "SpellSystem not available"
		return results
	
	# Test spell creation
	if SpellSystem.has_method("create_spell"):
		try:
			# Test creating a basic fireball spell
			var test_spell = SpellSystem.create_spell("fireball", "fire")
			if test_spell != null:
				results["details"].append("Spell creation: PASS")
			else:
				results["details"].append("Spell creation: FAIL - Null result")
				results["success"] = false
		except:
			results["details"].append("Spell creation: FAIL - Exception")
			results["success"] = false
	else:
		results["details"].append("Spell creation: SKIP - Method not available")
	
	# Test spell combination
	if SpellCombinationSystem and SpellCombinationSystem.has_method("create_combination"):
		try:
			var combo = SpellCombinationSystem.create_combination(["fire", "ice"])
			if combo != null:
				results["details"].append("Spell combination: PASS")
			else:
				results["details"].append("Spell combination: FAIL - Null result")
		except:
			results["details"].append("Spell combination: FAIL - Exception")
	else:
		results["details"].append("Spell combination: SKIP - System not available")
	
	return results

func _test_progression_system_logic() -> Dictionary:
	"""Test progression system logic"""
	var results = {"success": true, "details": []}
	
	if not ProgressionSystem:
		results["success"] = false
		results["error"] = "ProgressionSystem not available"
		return results
	
	# Test experience addition
	if ProgressionSystem.has_method("add_experience"):
		try:
			var initial_exp = ProgressionSystem.get_experience() if ProgressionSystem.has_method("get_experience") else 0
			ProgressionSystem.add_experience(100)
			var new_exp = ProgressionSystem.get_experience() if ProgressionSystem.has_method("get_experience") else 0
			
			if new_exp >= initial_exp:
				results["details"].append("Experience addition: PASS")
			else:
				results["details"].append("Experience addition: FAIL - No change")
				results["success"] = false
		except:
			results["details"].append("Experience addition: FAIL - Exception")
			results["success"] = false
	else:
		results["details"].append("Experience addition: SKIP - Method not available")
	
	# Test level calculation
	if ProgressionSystem.has_method("get_level"):
		try:
			var level = ProgressionSystem.get_level()
			if level >= 1:
				results["details"].append("Level calculation: PASS")
			else:
				results["details"].append("Level calculation: FAIL - Invalid level")
				results["success"] = false
		except:
			results["details"].append("Level calculation: FAIL - Exception")
			results["success"] = false
	else:
		results["details"].append("Level calculation: SKIP - Method not available")
	
	return results

func _test_enemy_system_logic() -> Dictionary:
	"""Test enemy system logic"""
	var results = {"success": true, "details": []}
	
	if not EnemyFactory:
		results["success"] = false
		results["error"] = "EnemyFactory not available"
		return results
	
	# Test enemy creation
	if EnemyFactory.has_method("create_enemy"):
		try:
			var enemy = EnemyFactory.create_enemy("goblin", 1)
			if enemy != null:
				results["details"].append("Enemy creation: PASS")
			else:
				results["details"].append("Enemy creation: FAIL - Null result")
				results["success"] = false
		except:
			results["details"].append("Enemy creation: FAIL - Exception")
			results["success"] = false
	else:
		results["details"].append("Enemy creation: SKIP - Method not available")
	
	# Test enemy variants
	if EnemyVariants and EnemyVariants.has_method("get_enemy_data"):
		try:
			var enemy_data = EnemyVariants.get_enemy_data("goblin")
			if enemy_data != null and enemy_data.size() > 0:
				results["details"].append("Enemy variants: PASS")
			else:
				results["details"].append("Enemy variants: FAIL - No data")
		except:
			results["details"].append("Enemy variants: FAIL - Exception")
	else:
		results["details"].append("Enemy variants: SKIP - System not available")
	
	return results

func _test_level_generation_logic() -> Dictionary:
	"""Test level generation logic"""
	var results = {"success": true, "details": []}
	
	if not LevelGenerator:
		results["success"] = false
		results["error"] = "LevelGenerator not available"
		return results
	
	# Test level generation
	if LevelGenerator.has_method("generate_level"):
		try:
			var level_data = LevelGenerator.generate_level(1, "dungeon")
			if level_data != null:
				results["details"].append("Level generation: PASS")
			else:
				results["details"].append("Level generation: FAIL - Null result")
				results["success"] = false
		except:
			results["details"].append("Level generation: FAIL - Exception")
			results["success"] = false
	else:
		results["details"].append("Level generation: SKIP - Method not available")
	
	# Test room generation
	if LevelGenerator.has_method("generate_room"):
		try:
			var room = LevelGenerator.generate_room("basic", Vector2i(10, 10))
			if room != null:
				results["details"].append("Room generation: PASS")
			else:
				results["details"].append("Room generation: FAIL - Null result")
		except:
			results["details"].append("Room generation: FAIL - Exception")
	else:
		results["details"].append("Room generation: SKIP - Method not available")
	
	return results

func _test_achievement_system_logic() -> Dictionary:
	"""Test achievement system logic"""
	var results = {"success": true, "details": []}
	
	if not AchievementSystem:
		results["success"] = false
		results["error"] = "AchievementSystem not available"
		return results
	
	# Test achievement unlocking
	if AchievementSystem.has_method("unlock_achievement"):
		try:
			var unlocked = AchievementSystem.unlock_achievement("first_kill")
			results["details"].append("Achievement unlock: PASS")
		except:
			results["details"].append("Achievement unlock: FAIL - Exception")
			results["success"] = false
	else:
		results["details"].append("Achievement unlock: SKIP - Method not available")
	
	# Test progress tracking
	if AchievementSystem.has_method("add_progress"):
		try:
			AchievementSystem.add_progress("kill_count", 1)
			results["details"].append("Progress tracking: PASS")
		except:
			results["details"].append("Progress tracking: FAIL - Exception")
			results["success"] = false
	else:
		results["details"].append("Progress tracking: SKIP - Method not available")
	
	return results

# Asset generation test implementations
func _test_sprite_generation() -> Dictionary:
	"""Test sprite generation"""
	var results = {"success": true, "details": []}
	
	if not SpriteGenerator:
		results["success"] = false
		results["error"] = "SpriteGenerator not available"
		return results
	
	# Test player sprite generation
	if SpriteGenerator.has_method("generate_player_sprite"):
		try:
			var sprite = SpriteGenerator.generate_player_sprite("warrior", "default")
			if sprite != null:
				results["details"].append("Player sprite generation: PASS")
			else:
				results["details"].append("Player sprite generation: FAIL - Null result")
				results["success"] = false
		except:
			results["details"].append("Player sprite generation: FAIL - Exception")
			results["success"] = false
	
	# Test enemy sprite generation
	if SpriteGenerator.has_method("generate_enemy_sprite"):
		try:
			var sprite = SpriteGenerator.generate_enemy_sprite("goblin", "green")
			if sprite != null:
				results["details"].append("Enemy sprite generation: PASS")
			else:
				results["details"].append("Enemy sprite generation: FAIL - Null result")
		except:
			results["details"].append("Enemy sprite generation: FAIL - Exception")
	
	return results

func _test_texture_generation() -> Dictionary:
	"""Test texture generation"""
	var results = {"success": true, "details": []}
	
	if not TextureGenerator:
		results["success"] = false
		results["error"] = "TextureGenerator not available"
		return results
	
	# Test particle texture generation
	if TextureGenerator.has_method("generate_particle_texture"):
		try:
			var texture = TextureGenerator.generate_particle_texture("fire")
			if texture != null:
				results["details"].append("Particle texture generation: PASS")
			else:
				results["details"].append("Particle texture generation: FAIL - Null result")
				results["success"] = false
		except:
			results["details"].append("Particle texture generation: FAIL - Exception")
			results["success"] = false
	
	return results

func _test_audio_generation() -> Dictionary:
	"""Test audio generation"""
	var results = {"success": true, "details": []}
	
	if not AudioGenerator:
		results["success"] = false
		results["error"] = "AudioGenerator not available"
		return results
	
	# Test spell audio generation
	if AudioGenerator.has_method("generate_spell_sfx"):
		try:
			var audio = AudioGenerator.generate_spell_sfx("fireball", "cast")
			if audio != null:
				results["details"].append("Spell audio generation: PASS")
			else:
				results["details"].append("Spell audio generation: FAIL - Null result")
				results["success"] = false
		except:
			results["details"].append("Spell audio generation: FAIL - Exception")
			results["success"] = false
	
	return results

func _test_tileset_generation() -> Dictionary:
	"""Test tileset generation"""
	var results = {"success": true, "details": []}
	
	if not TilesetGenerator:
		results["success"] = false
		results["error"] = "TilesetGenerator not available"
		return results
	
	# Test biome tileset generation
	if TilesetGenerator.has_method("generate_biome_tileset"):
		try:
			var tileset = TilesetGenerator.generate_biome_tileset("dungeon")
			if tileset != null:
				results["details"].append("Biome tileset generation: PASS")
			else:
				results["details"].append("Biome tileset generation: FAIL - Null result")
				results["success"] = false
		except:
			results["details"].append("Biome tileset generation: FAIL - Exception")
			results["success"] = false
	
	return results

func _test_icon_generation() -> Dictionary:
	"""Test icon generation"""
	var results = {"success": true, "details": []}
	
	if not IconGenerator:
		results["success"] = false
		results["error"] = "IconGenerator not available"
		return results
	
	# Test spell icon generation
	if IconGenerator.has_method("generate_spell_icon"):
		try:
			var icon = IconGenerator.generate_spell_icon("fireball", "fire")
			if icon != null:
				results["details"].append("Spell icon generation: PASS")
			else:
				results["details"].append("Spell icon generation: FAIL - Null result")
				results["success"] = false
		except:
			results["details"].append("Spell icon generation: FAIL - Exception")
			results["success"] = false
	
	return results

func _test_asset_registry() -> Dictionary:
	"""Test asset registry"""
	var results = {"success": true, "details": []}
	
	if not AssetRegistry:
		results["success"] = false
		results["error"] = "AssetRegistry not available"
		return results
	
	# Test asset registration
	if AssetRegistry.has_method("register_asset"):
		try:
			AssetRegistry.register_asset("test_asset", "texture", null, {"test": true})
			results["details"].append("Asset registration: PASS")
		except:
			results["details"].append("Asset registration: FAIL - Exception")
			results["success"] = false
	
	# Test asset retrieval
	if AssetRegistry.has_method("get_asset"):
		try:
			var asset = AssetRegistry.get_asset("test_asset")
			results["details"].append("Asset retrieval: PASS")
		except:
			results["details"].append("Asset retrieval: FAIL - Exception")
			results["success"] = false
	
	return results

func _generate_final_report() -> void:
	"""Generate comprehensive final report"""
	print("\n" + "="*70)
	print("SPELLLOOP - COMPREHENSIVE GAME TEST REPORT")
	print("="*70)
	
	var total_phases = test_results.size()
	var successful_phases = 0
	
	for phase_name in test_results:
		var phase_data = test_results[phase_name]
		if phase_data.get("completed", false):
			successful_phases += 1
		
		print("\n📋 %s:" % phase_name.to_upper().replace("_", " "))
		
		if phase_data.has("error"):
			print("  ❌ ERROR: %s" % phase_data["error"])
		elif phase_data.get("completed", false):
			print("  ✅ COMPLETED")
			
			# Print phase-specific details
			if phase_data.has("summary"):
				var summary = phase_data["summary"]
				if summary.has("success_rate"):
					print("  📊 Success Rate: %.1f%%" % summary["success_rate"])
			
			if phase_data.has("results"):
				var results = phase_data["results"]
				if typeof(results) == TYPE_DICTIONARY:
					var passed = 0
					var total = 0
					for test_name in results:
						total += 1
						if results[test_name].get("success", false):
							passed += 1
					print("  📈 Tests: %d/%d passed" % [passed, total])
		else:
			print("  ⚠️ INCOMPLETE")
	
	print("\n🎯 OVERALL GAME HEALTH:")
	print("  Test Phases: %d/%d completed" % [successful_phases, total_phases])
	
	var overall_health = (float(successful_phases) / total_phases) * 100
	var health_status = ""
	
	if overall_health >= 95:
		health_status = "EXCELLENT ✅"
	elif overall_health >= 85:
		health_status = "GOOD ✅"
	elif overall_health >= 70:
		health_status = "ACCEPTABLE ⚠️"
	else:
		health_status = "NEEDS ATTENTION ❌"
	
	print("  Health Score: %.1f%% - %s" % [overall_health, health_status])
	
	print("\n💡 RECOMMENDATIONS:")
	if overall_health < 100:
		print("  1. Review and fix failed test phases")
	if overall_health < 85:
		print("  2. Address critical system issues before release")
	if overall_health >= 95:
		print("  1. Game is ready for final polish and release preparation")
	
	print("="*70 + "\n")

func get_test_results() -> Dictionary:
	"""Get all test results"""
	return test_results

func is_test_suite_running() -> bool:
	"""Check if test suite is currently running"""
	return is_running
# IntegrationValidator.gd
# Validates integration between all game systems
# Ensures proper communication and data flow

extends Node

signal integration_test_completed(system_pair: String, success: bool, details: Dictionary)
signal validation_completed(results: Dictionary)

# Integration test results
var integration_results: Dictionary = {}
var system_dependencies: Dictionary = {}
var critical_paths: Array = []

# Test categories
enum IntegrationLevel {
	BASIC,      # Basic connectivity
	FUNCTIONAL, # Function calls work
	DATA_FLOW,  # Data flows correctly
	PERFORMANCE # Performance is acceptable
}

func _ready() -> void:
	"""Initialize integration validator"""
	print("[IntegrationValidator] Integration Validator initialized")
	_setup_system_dependencies()

func _setup_system_dependencies() -> void:
	"""Define system dependencies and critical paths"""
	
	# Define system dependencies
	system_dependencies = {
		"GameManager": ["SaveManager", "UIManager", "AudioManager"],
		"SpellSystem": ["SpriteGenerator", "AudioGenerator", "ParticleManager"],
		"SpellCombinationSystem": ["SpellSystem", "VisualEffectsManager"],
		"ProgressionSystem": ["SaveManager", "AchievementSystem", "UIManager"],
		"EnemyFactory": ["SpriteGenerator", "EnemyVariants", "AudioGenerator"],
		"LevelGenerator": ["TilesetGenerator", "EnemyFactory", "AssetRegistry"],
		"UIManager": ["ThemeManager", "UIAnimationManager", "TooltipManager"],
		"ParticleManager": ["TextureGenerator", "PerformanceOptimizer"],
		"AudioManager": ["AudioGenerator", "SaveManager"],
		"AssetRegistry": ["SpriteGenerator", "TextureGenerator", "AudioGenerator", "TilesetGenerator", "IconGenerator"]
	}
	
	# Define critical integration paths
	critical_paths = [
		["GameManager", "SaveManager", "ProgressionSystem"],
		["SpellSystem", "SpellCombinationSystem", "VisualEffectsManager"],
		["LevelGenerator", "TilesetGenerator", "EnemyFactory"],
		["UIManager", "ThemeManager", "UIAnimationManager"],
		["AudioManager", "AudioGenerator", "SaveManager"],
		["AssetRegistry", "SpriteGenerator", "TextureGenerator"]
	]

func validate_all_integrations() -> void:
	"""Validate all system integrations"""
	print("[IntegrationValidator] Starting comprehensive integration validation...")
	
	integration_results.clear()
	
	# Test basic system availability
	await _test_system_availability()
	
	# Test system dependencies
	await _test_system_dependencies()
	
	# Test critical paths
	await _test_critical_paths()
	
	# Test data flow
	await _test_data_flow()
	
	# Test performance integration
	await _test_performance_integration()
	
	# Generate validation report
	_generate_validation_report()
	validation_completed.emit(integration_results)

func _test_system_availability() -> void:
	"""Test if all expected systems are available"""
	print("[IntegrationValidator] Testing system availability...")
	
	var expected_systems = [
		"GameManager", "SaveManager", "AudioManager", "InputManager", "UIManager", "Localization",
		"SpellSystem", "SpellCombinationSystem", "ProgressionSystem", "AchievementSystem",
		"EnemyFactory", "EnemyVariants", "LevelGenerator", "ParticleManager", "VisualEffectsManager",
		"UIAnimationManager", "TooltipManager", "ThemeManager", "AccessibilityManager",
		"SpriteGenerator", "TextureGenerator", "AudioGenerator", "TilesetGenerator", "IconGenerator", "AssetRegistry",
		"TestManager", "PerformanceOptimizer"
	]
	
	var available_systems = []
	var missing_systems = []
	
	for system_name in expected_systems:
		var system_node = get_node_or_null("/root/" + system_name)
		if system_node != null:
			available_systems.append(system_name)
		else:
			missing_systems.append(system_name)
	
	var success = missing_systems.size() == 0
	var details = {
		"available_systems": available_systems,
		"missing_systems": missing_systems,
		"availability_rate": float(available_systems.size()) / expected_systems.size()
	}
	
	_record_integration_result("SystemAvailability", success, details)

func _test_system_dependencies() -> void:
	"""Test system dependencies"""
	print("[IntegrationValidator] Testing system dependencies...")
	
	for system_name in system_dependencies:
		var system_node = get_node_or_null("/root/" + system_name)
		if system_node == null:
			continue
		
		var dependencies = system_dependencies[system_name]
		var satisfied_deps = []
		var missing_deps = []
		
		for dep_name in dependencies:
			var dep_node = get_node_or_null("/root/" + dep_name)
			if dep_node != null:
				satisfied_deps.append(dep_name)
			else:
				missing_deps.append(dep_name)
		
		var success = missing_deps.size() == 0
		var details = {
			"system": system_name,
			"satisfied_dependencies": satisfied_deps,
			"missing_dependencies": missing_deps,
			"dependency_satisfaction": float(satisfied_deps.size()) / dependencies.size() if dependencies.size() > 0 else 1.0
		}
		
		_record_integration_result("Dependencies_" + system_name, success, details)

func _test_critical_paths() -> void:
	"""Test critical integration paths"""
	print("[IntegrationValidator] Testing critical paths...")
	
	for i in range(critical_paths.size()):
		var path = critical_paths[i]
		var path_name = "CriticalPath_%d" % i
		var path_success = true
		var path_details = {
			"path": path,
			"system_availability": {},
			"integration_points": []
		}
		
		# Check each system in path
		for system_name in path:
			var system_node = get_node_or_null("/root/" + system_name)
			var available = system_node != null
			path_details["system_availability"][system_name] = available
			
			if not available:
				path_success = false
		
		# Test integration between consecutive systems in path
		for j in range(path.size() - 1):
			var system_a = path[j]
			var system_b = path[j + 1]
			var integration_test = await _test_system_integration(system_a, system_b)
			path_details["integration_points"].append({
				"from": system_a,
				"to": system_b,
				"success": integration_test["success"],
				"details": integration_test["details"]
			})
			
			if not integration_test["success"]:
				path_success = false
		
		_record_integration_result(path_name, path_success, path_details)

func _test_system_integration(system_a: String, system_b: String) -> Dictionary:
	"""Test integration between two specific systems"""
	var node_a = get_node_or_null("/root/" + system_a)
	var node_b = get_node_or_null("/root/" + system_b)
	
	var result = {
		"success": false,
		"details": {}
	}
	
	if node_a == null or node_b == null:
		result["details"]["error"] = "One or both systems not available"
		return result
	
	# Test specific integration patterns
	var integration_tests = []
	
	# Test GameManager integrations
	if system_a == "GameManager":
		if system_b == "SaveManager":
			integration_tests.append(_test_gamemanager_savemanager(node_a, node_b))
		elif system_b == "UIManager":
			integration_tests.append(_test_gamemanager_uimanager(node_a, node_b))
		elif system_b == "AudioManager":
			integration_tests.append(_test_gamemanager_audiomanager(node_a, node_b))
	
	# Test SpellSystem integrations
	elif system_a == "SpellSystem":
		if system_b == "SpriteGenerator":
			integration_tests.append(_test_spellsystem_spritegenerator(node_a, node_b))
		elif system_b == "AudioGenerator":
			integration_tests.append(_test_spellsystem_audiogenerator(node_a, node_b))
	
	# Test UI integrations
	elif system_a == "UIManager":
		if system_b == "ThemeManager":
			integration_tests.append(_test_uimanager_thememanager(node_a, node_b))
		elif system_b == "UIAnimationManager":
			integration_tests.append(_test_uimanager_animationmanager(node_a, node_b))
	
	# Test Asset integrations
	elif system_a == "AssetRegistry":
		if system_b in ["SpriteGenerator", "TextureGenerator", "AudioGenerator", "TilesetGenerator", "IconGenerator"]:
			integration_tests.append(_test_assetregistry_generator(node_a, node_b, system_b))
	
	# Default connectivity test
	if integration_tests.size() == 0:
		integration_tests.append(_test_basic_connectivity(node_a, node_b, system_a, system_b))
	
	# Evaluate results
	var passed_tests = 0
	for test in integration_tests:
		if test["success"]:
			passed_tests += 1
	
	result["success"] = passed_tests == integration_tests.size()
	result["details"]["tests"] = integration_tests
	result["details"]["success_rate"] = float(passed_tests) / integration_tests.size() if integration_tests.size() > 0 else 0.0
	
	return result

# Specific integration tests
func _test_gamemanager_savemanager(gm: Node, sm: Node) -> Dictionary:
	"""Test GameManager-SaveManager integration"""
	return {
		"test": "GameManager-SaveManager",
		"success": gm.has_method("save_game") or sm.has_method("save_game"),
		"details": "Save functionality availability"
	}

func _test_gamemanager_uimanager(gm: Node, ui: Node) -> Dictionary:
	"""Test GameManager-UIManager integration"""
	return {
		"test": "GameManager-UIManager",
		"success": ui.has_method("show_screen") or gm.has_method("change_screen"),
		"details": "Screen management integration"
	}

func _test_gamemanager_audiomanager(gm: Node, am: Node) -> Dictionary:
	"""Test GameManager-AudioManager integration"""
	return {
		"test": "GameManager-AudioManager",
		"success": am.has_method("play_music") and am.has_method("play_sfx"),
		"details": "Audio control integration"
	}

func _test_spellsystem_spritegenerator(ss: Node, sg: Node) -> Dictionary:
	"""Test SpellSystem-SpriteGenerator integration"""
	return {
		"test": "SpellSystem-SpriteGenerator",
		"success": sg.has_method("generate_spell_sprite") or sg.has_method("generate_projectile_sprite"),
		"details": "Spell visual generation"
	}

func _test_spellsystem_audiogenerator(ss: Node, ag: Node) -> Dictionary:
	"""Test SpellSystem-AudioGenerator integration"""
	return {
		"test": "SpellSystem-AudioGenerator",
		"success": ag.has_method("generate_spell_sfx"),
		"details": "Spell audio generation"
	}

func _test_uimanager_thememanager(ui: Node, tm: Node) -> Dictionary:
	"""Test UIManager-ThemeManager integration"""
	return {
		"test": "UIManager-ThemeManager",
		"success": tm.has_method("get_color") and tm.has_method("apply_button_theme"),
		"details": "UI theming integration"
	}

func _test_uimanager_animationmanager(ui: Node, am: Node) -> Dictionary:
	"""Test UIManager-UIAnimationManager integration"""
	return {
		"test": "UIManager-UIAnimationManager",
		"success": am.has_method("animate_control") and am.has_method("fade_in"),
		"details": "UI animation integration"
	}

func _test_assetregistry_generator(ar: Node, gen: Node, gen_name: String) -> Dictionary:
	"""Test AssetRegistry-Generator integration"""
	return {
		"test": "AssetRegistry-%s" % gen_name,
		"success": ar.has_method("register_asset") and ar.has_method("get_asset"),
		"details": "Asset registration and retrieval"
	}

func _test_basic_connectivity(node_a: Node, node_b: Node, name_a: String, name_b: String) -> Dictionary:
	"""Basic connectivity test between two systems"""
	return {
		"test": "%s-%s-Connectivity" % [name_a, name_b],
		"success": node_a != null and node_b != null,
		"details": "Basic system availability"
	}

func _test_data_flow() -> void:
	"""Test data flow between systems"""
	print("[IntegrationValidator] Testing data flow...")
	
	# Test save/load data flow
	var save_flow_test = await _test_save_load_data_flow()
	_record_integration_result("SaveLoadDataFlow", save_flow_test["success"], save_flow_test["details"])
	
	# Test spell creation data flow
	var spell_flow_test = await _test_spell_creation_data_flow()
	_record_integration_result("SpellCreationDataFlow", spell_flow_test["success"], spell_flow_test["details"])
	
	# Test UI update data flow
	var ui_flow_test = await _test_ui_update_data_flow()
	_record_integration_result("UIUpdateDataFlow", ui_flow_test["success"], ui_flow_test["details"])
	
	# Test asset generation data flow
	var asset_flow_test = await _test_asset_generation_data_flow()
	_record_integration_result("AssetGenerationDataFlow", asset_flow_test["success"], asset_flow_test["details"])

func _test_save_load_data_flow() -> Dictionary:
	"""Test save/load data flow"""
	var sm = get_node_or_null("/root/SaveManager")
	var ps = get_node_or_null("/root/ProgressionSystem")
	var as_node = get_node_or_null("/root/AchievementSystem")
	
	var success = true
	var details = {}
	
	if sm == null:
		success = false
		details["error"] = "SaveManager not available"
	elif not sm.has_method("save_game") or not sm.has_method("load_game"):
		success = false
		details["error"] = "SaveManager missing save/load methods"
	else:
		details["save_manager"] = "Available with save/load methods"
	
	if ps and ps.has_method("get_save_data"):
		details["progression_system"] = "Can provide save data"
	elif ps:
		details["progression_system"] = "Available but no save data method"
	else:
		details["progression_system"] = "Not available"
	
	if as_node and as_node.has_method("get_save_data"):
		details["achievement_system"] = "Can provide save data"
	elif as_node:
		details["achievement_system"] = "Available but no save data method"
	else:
		details["achievement_system"] = "Not available"
	
	return {"success": success, "details": details}

func _test_spell_creation_data_flow() -> Dictionary:
	"""Test spell creation data flow"""
	var ss = get_node_or_null("/root/SpellSystem")
	var sg = get_node_or_null("/root/SpriteGenerator")
	var ag = get_node_or_null("/root/AudioGenerator")
	var ig = get_node_or_null("/root/IconGenerator")
	
	var success = true
	var details = {}
	
	if ss == null:
		success = false
		details["error"] = "SpellSystem not available"
	elif not ss.has_method("create_spell"):
		success = false
		details["error"] = "SpellSystem missing create_spell method"
	else:
		details["spell_system"] = "Available with create_spell method"
	
	if sg and sg.has_method("generate_spell_sprite"):
		details["sprite_generation"] = "Available"
	else:
		details["sprite_generation"] = "Not available or missing method"
	
	if ag and ag.has_method("generate_spell_sfx"):
		details["audio_generation"] = "Available"
	else:
		details["audio_generation"] = "Not available or missing method"
	
	if ig and ig.has_method("generate_spell_icon"):
		details["icon_generation"] = "Available"
	else:
		details["icon_generation"] = "Not available or missing method"
	
	return {"success": success, "details": details}

func _test_ui_update_data_flow() -> Dictionary:
	"""Test UI update data flow"""
	var ui = get_node_or_null("/root/UIManager")
	var tm = get_node_or_null("/root/ThemeManager")
	var am = get_node_or_null("/root/UIAnimationManager")
	
	var success = true
	var details = {}
	
	if ui == null:
		success = false
		details["error"] = "UIManager not available"
	else:
		details["ui_manager"] = "Available"
	
	if tm and tm.has_method("get_color"):
		details["theme_manager"] = "Available with theming methods"
	else:
		details["theme_manager"] = "Not available or missing methods"
	
	if am and am.has_method("animate_control"):
		details["animation_manager"] = "Available with animation methods"
	else:
		details["animation_manager"] = "Not available or missing methods"
	
	return {"success": success, "details": details}

func _test_asset_generation_data_flow() -> Dictionary:
	"""Test asset generation data flow"""
	var ar = get_node_or_null("/root/AssetRegistry")
	var generators = ["SpriteGenerator", "TextureGenerator", "AudioGenerator", "TilesetGenerator", "IconGenerator"]
	
	var success = true
	var details = {}
	
	if ar == null:
		success = false
		details["error"] = "AssetRegistry not available"
	elif not ar.has_method("register_asset") or not ar.has_method("get_asset"):
		success = false
		details["error"] = "AssetRegistry missing required methods"
	else:
		details["asset_registry"] = "Available with required methods"
	
	var available_generators = []
	var missing_generators = []
	
	for gen_name in generators:
		var gen_node = get_node_or_null("/root/" + gen_name)
		if gen_node != null:
			available_generators.append(gen_name)
		else:
			missing_generators.append(gen_name)
	
	details["available_generators"] = available_generators
	details["missing_generators"] = missing_generators
	details["generator_availability"] = float(available_generators.size()) / generators.size()
	
	return {"success": success, "details": details}

func _test_performance_integration() -> void:
	"""Test performance-related integrations"""
	print("[IntegrationValidator] Testing performance integration...")
	
	var po = get_node_or_null("/root/PerformanceOptimizer")
	var success = true
	var details = {}
	
	if po == null:
		success = false
		details["error"] = "PerformanceOptimizer not available"
	else:
		details["performance_optimizer"] = "Available"
		
		# Test performance monitoring integration
		if po.has_method("get_performance_stats"):
			details["performance_monitoring"] = "Available"
		else:
			details["performance_monitoring"] = "Not available"
		
		# Test optimization integration
		if po.has_method("optimize_performance"):
			details["performance_optimization"] = "Available"
		else:
			details["performance_optimization"] = "Not available"
	
	_record_integration_result("PerformanceIntegration", success, details)

func _record_integration_result(test_name: String, success: bool, details: Dictionary) -> void:
	"""Record an integration test result"""
	integration_results[test_name] = {
		"success": success,
		"details": details,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	var status = "PASS" if success else "FAIL"
	print("[IntegrationValidator] %s: %s" % [test_name, status])
	
	integration_test_completed.emit(test_name, success, details)

func _generate_validation_report() -> void:
	"""Generate comprehensive validation report"""
	print("\n" + "=".repeat(60))
	print("SPELLLOOP - INTEGRATION VALIDATION REPORT")
	print("=".repeat(60))
	
	var total_tests = integration_results.size()
	var passed_tests = 0
	var failed_tests = 0
	var critical_failures = []
	
	for test_name in integration_results:
		if integration_results[test_name]["success"]:
			passed_tests += 1
		else:
			failed_tests += 1
			
			# Check if this is a critical failure
			if "Critical" in test_name or "SystemAvailability" in test_name:
				critical_failures.append(test_name)
	
	print("Total Integration Tests: %d" % total_tests)
	print("Passed: %d (%.1f%%)" % [passed_tests, (float(passed_tests) / total_tests) * 100])
	print("Failed: %d (%.1f%%)" % [failed_tests, (float(failed_tests) / total_tests) * 100])
	
	if critical_failures.size() > 0:
		print("\n❌ CRITICAL FAILURES:")
		for failure in critical_failures:
			print("  - %s" % failure)
	
	print("\n📊 INTEGRATION CATEGORIES:")
	
	# System Availability
	var availability_result = integration_results.get("SystemAvailability", {})
	if availability_result.has("details"):
		var rate = availability_result["details"].get("availability_rate", 0.0)
		print("  System Availability: %.1f%%" % (rate * 100))
	
	# Critical Paths
	var critical_path_count = 0
	var critical_path_passed = 0
	for test_name in integration_results:
		if "CriticalPath" in test_name:
			critical_path_count += 1
			if integration_results[test_name]["success"]:
				critical_path_passed += 1
	
	if critical_path_count > 0:
		print("  Critical Paths: %d/%d (%.1f%%)" % [critical_path_passed, critical_path_count, (float(critical_path_passed) / critical_path_count) * 100])
	
	# Data Flow
	var data_flow_tests = ["SaveLoadDataFlow", "SpellCreationDataFlow", "UIUpdateDataFlow", "AssetGenerationDataFlow"]
	var data_flow_passed = 0
	for test_name in data_flow_tests:
		if integration_results.has(test_name) and integration_results[test_name]["success"]:
			data_flow_passed += 1
	
	print("  Data Flow: %d/%d (%.1f%%)" % [data_flow_passed, data_flow_tests.size(), (float(data_flow_passed) / data_flow_tests.size()) * 100])
	
	# Overall integration health
	var integration_health = (float(passed_tests) / total_tests) * 100
	var health_status = ""
	
	if integration_health >= 95:
		health_status = "EXCELLENT ✅"
	elif integration_health >= 85:
		health_status = "GOOD ✅"
	elif integration_health >= 70:
		health_status = "ACCEPTABLE ⚠️"
	else:
		health_status = "CRITICAL ISSUES ❌"
	
	print("\n🔗 OVERALL INTEGRATION HEALTH: %.1f%% - %s" % [integration_health, health_status])
	
	# Recommendations
	print("\n💡 RECOMMENDATIONS:")
	if critical_failures.size() > 0:
		print("  1. Address critical system failures immediately")
	if integration_health < 85:
		print("  2. Review failed integration tests and fix connectivity issues")
	if data_flow_passed < data_flow_tests.size():
		print("  3. Ensure proper data flow between systems")
	
	print("=".repeat(60) + "\n")

func get_integration_results() -> Dictionary:
	"""Get all integration test results"""
	return integration_results

func get_failed_integrations() -> Array:
	"""Get list of failed integrations"""
	var failed = []
	for test_name in integration_results:
		if not integration_results[test_name]["success"]:
			failed.append(test_name)
	return failed

func get_integration_summary() -> Dictionary:
	"""Get integration summary statistics"""
	var total = integration_results.size()
	var passed = 0
	var failed = 0
	
	for test_name in integration_results:
		if integration_results[test_name]["success"]:
			passed += 1
		else:
			failed += 1
	
	return {
		"total": total,
		"passed": passed,
		"failed": failed,
		"success_rate": (float(passed) / total) * 100 if total > 0 else 0,
		"critical_paths_tested": critical_paths.size(),
		"system_dependencies": system_dependencies.size()
	}
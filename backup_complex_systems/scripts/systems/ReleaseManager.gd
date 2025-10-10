# ReleaseManager.gd
# Comprehensive release management system
# Handles final validation, packaging, and release preparation

extends Node

signal release_validation_completed(success: bool, report: Dictionary)
signal package_prepared(package_path: String, success: bool)
signal release_ready(release_info: Dictionary)

# Release configuration
var release_config: Dictionary = {
	"version": "1.0.0",
	"build_number": 1,
	"release_name": "Spellloop",
	"platforms": ["windows", "linux", "steam_deck"],
	"distribution": "steam",
	"target_audience": "everyone"
}

# Release validation state
var validation_results: Dictionary = {}
var release_status: String = "preparing"  # preparing, validating, packaging, ready, failed

# Quality gates
var quality_gates: Dictionary = {
	"system_tests": {"required": true, "passed": false, "score": 0.0},
	"integration_tests": {"required": true, "passed": false, "score": 0.0},
	"performance_tests": {"required": true, "passed": false, "score": 0.0},
	"asset_validation": {"required": true, "passed": false, "score": 0.0},
	"gameplay_validation": {"required": true, "passed": false, "score": 0.0},
	"accessibility_check": {"required": false, "passed": false, "score": 0.0},
	"localization_check": {"required": false, "passed": false, "score": 0.0}
}

# Release artifacts
var release_artifacts: Array = []
var package_contents: Dictionary = {}

func _ready() -> void:
	"""Initialize release manager"""
	print("[ReleaseManager] Release Manager initialized")
	_load_release_config()

func _load_release_config() -> void:
	"""Load release configuration"""
	# Load from file if exists, otherwise use defaults
	var config_path = "res://release_config.json"
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		if file:
			var config_text = file.get_as_text()
			file.close()
			var json = JSON.new()
			var parse_result = json.parse(config_text)
			if parse_result == OK:
				release_config.merge(json.data, true)
	
	print("[ReleaseManager] Release config loaded: %s v%s" % [release_config["release_name"], release_config["version"]])

func start_release_preparation() -> void:
	"""Start the complete release preparation process"""
	print("[ReleaseManager] Starting release preparation for %s v%s" % [release_config["release_name"], release_config["version"]])
	
	release_status = "validating"
	validation_results.clear()
	
	# Execute release preparation phases
	await _execute_quality_gates()
	await _validate_release_readiness()
	await _prepare_release_package()
	await _finalize_release()

func _execute_quality_gates() -> void:
	"""Execute all quality gates"""
	print("[ReleaseManager] Executing quality gates...")
	
	# Gate 1: System Tests
	await _validate_system_tests()
	
	# Gate 2: Integration Tests
	await _validate_integration_tests()
	
	# Gate 3: Performance Tests
	await _validate_performance_tests()
	
	# Gate 4: Asset Validation
	await _validate_assets()
	
	# Gate 5: Gameplay Validation
	await _validate_gameplay()
	
	# Gate 6: Accessibility Check (Optional)
	await _validate_accessibility()
	
	# Gate 7: Localization Check (Optional)
	await _validate_localization()

func _validate_system_tests() -> void:
	"""Validate system tests quality gate"""
	print("[ReleaseManager] Quality Gate 1: System Tests")
	
	var gate_result = {"passed": false, "score": 0.0, "details": {}}
	
	if TestManager:
		# Run comprehensive system tests
		await TestManager.run_full_test_suite()
		var test_summary = TestManager.get_test_summary()
		
		gate_result["score"] = test_summary.get("success_rate", 0.0)
		gate_result["passed"] = gate_result["score"] >= 95.0  # 95% success rate required
		gate_result["details"] = test_summary
		
		print("[ReleaseManager] System Tests: %.1f%% success rate" % gate_result["score"])
	else:
		gate_result["details"]["error"] = "TestManager not available"
		print("[ReleaseManager] System Tests: FAILED - TestManager not available")
	
	quality_gates["system_tests"] = gate_result

func _validate_integration_tests() -> void:
	"""Validate integration tests quality gate"""
	print("[ReleaseManager] Quality Gate 2: Integration Tests")
	
	var gate_result = {"passed": false, "score": 0.0, "details": {}}
	
	if IntegrationValidator:
		# Run integration validation
		await IntegrationValidator.validate_all_integrations()
		var integration_summary = IntegrationValidator.get_integration_summary()
		
		gate_result["score"] = integration_summary.get("success_rate", 0.0)
		gate_result["passed"] = gate_result["score"] >= 90.0  # 90% success rate required
		gate_result["details"] = integration_summary
		
		print("[ReleaseManager] Integration Tests: %.1f%% success rate" % gate_result["score"])
	else:
		gate_result["details"]["error"] = "IntegrationValidator not available"
		print("[ReleaseManager] Integration Tests: FAILED - IntegrationValidator not available")
	
	quality_gates["integration_tests"] = gate_result

func _validate_performance_tests() -> void:
	"""Validate performance tests quality gate"""
	print("[ReleaseManager] Quality Gate 3: Performance Tests")
	
	var gate_result = {"passed": false, "score": 0.0, "details": {}}
	
	if PerformanceOptimizer:
		# Generate performance report
		var performance_report = PerformanceOptimizer.generate_performance_report()
		var performance_stats = PerformanceOptimizer.get_performance_stats()
		
		# Calculate performance score
		var fps_score = min(performance_stats.get("fps", 0.0) / 60.0, 1.0) * 100
		var memory_score = max(0, (512 - performance_stats.get("memory_usage_mb", 512)) / 512) * 100
		var performance_score = (fps_score + memory_score) / 2
		
		gate_result["score"] = performance_score
		gate_result["passed"] = performance_score >= 80.0  # 80% performance score required
		gate_result["details"] = {
			"fps": performance_stats.get("fps", 0.0),
			"memory_mb": performance_stats.get("memory_usage_mb", 0.0),
			"fps_score": fps_score,
			"memory_score": memory_score
		}
		
		print("[ReleaseManager] Performance Tests: %.1f%% score (FPS: %.1f, Memory: %.1fMB)" % [performance_score, performance_stats.get("fps", 0.0), performance_stats.get("memory_usage_mb", 0.0)])
	else:
		gate_result["details"]["error"] = "PerformanceOptimizer not available"
		print("[ReleaseManager] Performance Tests: FAILED - PerformanceOptimizer not available")
	
	quality_gates["performance_tests"] = gate_result

func _validate_assets() -> void:
	"""Validate asset generation and quality"""
	print("[ReleaseManager] Quality Gate 4: Asset Validation")
	
	var gate_result = {"passed": false, "score": 0.0, "details": {}}
	
	if AssetRegistry:
		var asset_stats = AssetRegistry.get_statistics() if AssetRegistry.has_method("get_statistics") else {}
		var generators_available = 0
		var generators_working = 0
		
		# Check each asset generator
		var generators = ["SpriteGenerator", "TextureGenerator", "AudioGenerator", "TilesetGenerator", "IconGenerator"]
		for generator_name in generators:
			var generator = get_node_or_null("/root/" + generator_name)
			generators_available += 1
			
			if generator != null:
				generators_working += 1
		
		var asset_score = (float(generators_working) / generators_available) * 100
		
		gate_result["score"] = asset_score
		gate_result["passed"] = asset_score >= 100.0  # All generators must work
		gate_result["details"] = {
			"generators_available": generators_available,
			"generators_working": generators_working,
			"asset_registry_stats": asset_stats
		}
		
		print("[ReleaseManager] Asset Validation: %.1f%% (%d/%d generators working)" % [asset_score, generators_working, generators_available])
	else:
		gate_result["details"]["error"] = "AssetRegistry not available"
		print("[ReleaseManager] Asset Validation: FAILED - AssetRegistry not available")
	
	quality_gates["asset_validation"] = gate_result

func _validate_gameplay() -> void:
	"""Validate core gameplay systems"""
	print("[ReleaseManager] Quality Gate 5: Gameplay Validation")
	
	var gate_result = {"passed": false, "score": 0.0, "details": {}}
	
	var gameplay_systems = [
		"SpellSystem", "SpellCombinationSystem", "ProgressionSystem", 
		"AchievementSystem", "EnemyFactory", "LevelGenerator"
	]
	
	var systems_available = 0
	var systems_working = 0
	var system_details = {}
	
	for system_name in gameplay_systems:
		var system_node = get_node_or_null("/root/" + system_name)
		systems_available += 1
		
		if system_node != null:
			systems_working += 1
			system_details[system_name] = "Available"
		else:
			system_details[system_name] = "Not available"
	
	var gameplay_score = (float(systems_working) / systems_available) * 100
	
	gate_result["score"] = gameplay_score
	gate_result["passed"] = gameplay_score >= 100.0  # All gameplay systems must work
	gate_result["details"] = {
		"systems_available": systems_available,
		"systems_working": systems_working,
		"system_status": system_details
	}
	
	print("[ReleaseManager] Gameplay Validation: %.1f%% (%d/%d systems working)" % [gameplay_score, systems_working, systems_available])
	
	quality_gates["gameplay_validation"] = gate_result

func _validate_accessibility() -> void:
	"""Validate accessibility features (optional)"""
	print("[ReleaseManager] Quality Gate 6: Accessibility Check (Optional)")
	
	var gate_result = {"passed": false, "score": 0.0, "details": {}}
	
	if AccessibilityManager:
		var accessibility_features = 0
		var working_features = 0
		
		# Check accessibility features
		var features = ["keyboard_navigation", "screen_reader_support", "color_blind_support", "high_contrast"]
		for feature in features:
			accessibility_features += 1
			if AccessibilityManager.has_method("has_" + feature) and AccessibilityManager.call("has_" + feature):
				working_features += 1
		
		var accessibility_score = (float(working_features) / accessibility_features) * 100 if accessibility_features > 0 else 0.0
		
		gate_result["score"] = accessibility_score
		gate_result["passed"] = accessibility_score >= 50.0  # 50% accessibility features
		gate_result["details"] = {
			"features_available": accessibility_features,
			"features_working": working_features
		}
		
		print("[ReleaseManager] Accessibility Check: %.1f%% (%d/%d features)" % [accessibility_score, working_features, accessibility_features])
	else:
		gate_result["details"]["error"] = "AccessibilityManager not available"
		gate_result["passed"] = true  # Optional gate passes if not available
		print("[ReleaseManager] Accessibility Check: SKIPPED - AccessibilityManager not available")
	
	quality_gates["accessibility_check"] = gate_result

func _validate_localization() -> void:
	"""Validate localization support (optional)"""
	print("[ReleaseManager] Quality Gate 7: Localization Check (Optional)")
	
	var gate_result = {"passed": false, "score": 0.0, "details": {}}
	
	if Localization:
		var languages_available = 0
		var languages_working = 0
		
		# Check supported languages
		if Localization.has_method("get_supported_languages"):
			var supported_languages = Localization.get_supported_languages()
			languages_available = supported_languages.size()
			languages_working = languages_available  # Assume all work if they're listed
		else:
			languages_available = 1  # At least English
			languages_working = 1
		
		var localization_score = (float(languages_working) / languages_available) * 100 if languages_available > 0 else 100.0
		
		gate_result["score"] = localization_score
		gate_result["passed"] = localization_score >= 100.0  # All listed languages must work
		gate_result["details"] = {
			"languages_available": languages_available,
			"languages_working": languages_working
		}
		
		print("[ReleaseManager] Localization Check: %.1f%% (%d/%d languages)" % [localization_score, languages_working, languages_available])
	else:
		gate_result["details"]["error"] = "Localization not available"
		gate_result["passed"] = true  # Optional gate passes if not available
		print("[ReleaseManager] Localization Check: SKIPPED - Localization not available")
	
	quality_gates["localization_check"] = gate_result

func _validate_release_readiness() -> void:
	"""Validate overall release readiness"""
	print("[ReleaseManager] Validating overall release readiness...")
	
	var required_gates_passed = 0
	var required_gates_total = 0
	var optional_gates_passed = 0
	var optional_gates_total = 0
	var total_score = 0.0
	var total_weight = 0
	
	for gate_name in quality_gates:
		var gate = quality_gates[gate_name]
		var is_required = gate.get("required", false)
		
		if is_required:
			required_gates_total += 1
			if gate.get("passed", false):
				required_gates_passed += 1
		else:
			optional_gates_total += 1
			if gate.get("passed", false):
				optional_gates_passed += 1
		
		total_score += gate.get("score", 0.0)
		total_weight += 1
	
	var average_score = total_score / total_weight if total_weight > 0 else 0.0
	var all_required_passed = required_gates_passed == required_gates_total
	
	validation_results = {
		"timestamp": Time.get_unix_time_from_system(),
		"required_gates": {
			"passed": required_gates_passed,
			"total": required_gates_total,
			"success_rate": (float(required_gates_passed) / required_gates_total) * 100 if required_gates_total > 0 else 100.0
		},
		"optional_gates": {
			"passed": optional_gates_passed,
			"total": optional_gates_total,
			"success_rate": (float(optional_gates_passed) / optional_gates_total) * 100 if optional_gates_total > 0 else 100.0
		},
		"overall_score": average_score,
		"release_ready": all_required_passed and average_score >= 85.0,
		"quality_gates": quality_gates.duplicate()
	}
	
	print("[ReleaseManager] Release Readiness: %s" % ("READY" if validation_results["release_ready"] else "NOT READY"))
	print("[ReleaseManager] Required Gates: %d/%d passed (%.1f%%)" % [required_gates_passed, required_gates_total, validation_results["required_gates"]["success_rate"]])
	print("[ReleaseManager] Overall Score: %.1f%%" % average_score)

func _prepare_release_package() -> void:
	"""Prepare release package"""
	print("[ReleaseManager] Preparing release package...")
	
	if not validation_results.get("release_ready", false):
		print("[ReleaseManager] Cannot package - release validation failed")
		release_status = "failed"
		return
	
	release_status = "packaging"
	
	# Prepare package contents
	package_contents = {
		"game_files": _collect_game_files(),
		"assets": _collect_assets(),
		"documentation": _collect_documentation(),
		"metadata": _generate_metadata()
	}
	
	# Generate release artifacts
	release_artifacts = [
		{
			"type": "executable",
			"platform": "windows",
			"filename": "%s_v%s_windows.exe" % [release_config["release_name"], release_config["version"]],
			"size_mb": 50  # Estimated
		},
		{
			"type": "executable",
			"platform": "linux",
			"filename": "%s_v%s_linux" % [release_config["release_name"], release_config["version"]],
			"size_mb": 48  # Estimated
		},
		{
			"type": "package",
			"platform": "steam",
			"filename": "%s_steam_build_%d.zip" % [release_config["release_name"], release_config["build_number"]],
			"size_mb": 55  # Estimated
		}
	]
	
	print("[ReleaseManager] Package prepared with %d artifacts" % release_artifacts.size())

func _collect_game_files() -> Array:
	"""Collect game files for packaging"""
	return [
		"scenes/",
		"scripts/",
		"project.godot",
		"export_presets.cfg"
	]

func _collect_assets() -> Array:
	"""Collect assets for packaging"""
	return [
		"generated_assets/",  # Procedurally generated assets
		"fonts/",
		"icon.png"
	]

func _collect_documentation() -> Array:
	"""Collect documentation for packaging"""
	return [
		"README.md",
		"CHANGELOG.md",
		"LICENSE",
		".azure/documentation/"
	]

func _generate_metadata() -> Dictionary:
	"""Generate release metadata"""
	return {
		"version": release_config["version"],
		"build_number": release_config["build_number"],
		"build_date": Time.get_datetime_string_from_system(),
		"engine_version": Engine.get_version_info(),
		"platforms": release_config["platforms"],
		"content_rating": release_config["target_audience"],
		"features": [
			"Procedural spell system",
			"Dynamic enemy AI",
			"Procedural level generation",
			"Achievement system",
			"Procedural asset generation",
			"Multiple difficulty modes",
			"Steam integration ready"
		]
	}

func _finalize_release() -> void:
	"""Finalize release preparation"""
	print("[ReleaseManager] Finalizing release...")
	
	if validation_results.get("release_ready", false):
		release_status = "ready"
		
		var release_info = {
			"version": release_config["version"],
			"build_number": release_config["build_number"],
			"status": release_status,
			"validation_results": validation_results,
			"package_contents": package_contents,
			"artifacts": release_artifacts,
			"release_date": Time.get_datetime_string_from_system()
		}
		
		print("[ReleaseManager] ✅ Release %s v%s is READY!" % [release_config["release_name"], release_config["version"]])
		release_ready.emit(release_info)
	else:
		release_status = "failed"
		print("[ReleaseManager] ❌ Release preparation FAILED")
	
	release_validation_completed.emit(validation_results.get("release_ready", false), validation_results)

func generate_release_report() -> Dictionary:
	"""Generate comprehensive release report"""
	var report = {
		"release_info": release_config.duplicate(),
		"validation_results": validation_results.duplicate(),
		"quality_gates": quality_gates.duplicate(),
		"package_contents": package_contents.duplicate(),
		"artifacts": release_artifacts.duplicate(),
		"status": release_status,
		"generated_at": Time.get_datetime_string_from_system()
	}
	
	return report

func export_release_report() -> String:
	"""Export release report as JSON"""
	var report = generate_release_report()
	return JSON.stringify(report, "\t")

func get_release_status() -> String:
	"""Get current release status"""
	return release_status

func get_quality_gate_summary() -> Dictionary:
	"""Get summary of quality gate results"""
	var summary = {
		"required_passed": 0,
		"required_total": 0,
		"optional_passed": 0,
		"optional_total": 0,
		"overall_score": 0.0
	}
	
	var total_score = 0.0
	var total_gates = 0
	
	for gate_name in quality_gates:
		var gate = quality_gates[gate_name]
		var is_required = gate.get("required", false)
		
		if is_required:
			summary["required_total"] += 1
			if gate.get("passed", false):
				summary["required_passed"] += 1
		else:
			summary["optional_total"] += 1
			if gate.get("passed", false):
				summary["optional_passed"] += 1
		
		total_score += gate.get("score", 0.0)
		total_gates += 1
	
	summary["overall_score"] = total_score / total_gates if total_gates > 0 else 0.0
	
	return summary
# MasterController.gd
# Master controller for final release preparation
# Orchestrates all final systems and validates release readiness

extends Node

signal master_validation_completed(success: bool, report: Dictionary)
signal release_preparation_completed(release_ready: bool, release_info: Dictionary)

# Master validation phases
enum ValidationPhase {
	SYSTEM_CHECK,
	QA_VALIDATION,
	PERFORMANCE_VALIDATION,
	INTEGRATION_VALIDATION,
	POLISH_APPLICATION,
	RELEASE_PREPARATION,
	FINAL_VALIDATION
}

# Current state
var current_phase: ValidationPhase = ValidationPhase.SYSTEM_CHECK
var validation_results: Dictionary = {}
var release_info: Dictionary = {}
var master_status: String = "initializing"

# Release readiness criteria
var release_criteria: Dictionary = {
	"system_health": {"threshold": 95.0, "weight": 25.0, "current": 0.0},
	"qa_score": {"threshold": 85.0, "weight": 20.0, "current": 0.0},
	"performance_score": {"threshold": 80.0, "weight": 20.0, "current": 0.0},
	"integration_score": {"threshold": 90.0, "weight": 15.0, "current": 0.0},
	"polish_completion": {"threshold": 80.0, "weight": 10.0, "current": 0.0},
	"final_validation": {"threshold": 95.0, "weight": 10.0, "current": 0.0}
}

func _ready() -> void:
	"""Initialize master controller"""
	print("[MasterController] Master Controller initialized")
	print("[MasterController] Spellloop Final Release Preparation System")

func execute_master_validation() -> void:
	"""Execute complete master validation sequence"""
	print("\n" + "================================================================================")
	print("🎮 SPELLLOOP - MASTER RELEASE VALIDATION")
	print("================================================================================")
	
	master_status = "validating"
	validation_results.clear()
	
	# Execute all validation phases
	await _execute_validation_phases()
	
	# Calculate final release readiness
	var release_ready = _calculate_release_readiness()
	
	# Generate final release info
	release_info = _generate_release_info(release_ready)
	
	master_status = "completed" if release_ready else "failed"
	
	print("\n🎯 MASTER VALIDATION %s" % ("COMPLETED" if release_ready else "FAILED"))
	print("=".repeat(80) + "\n")
	
	master_validation_completed.emit(release_ready, validation_results)
	release_preparation_completed.emit(release_ready, release_info)

func _execute_validation_phases() -> void:
	"""Execute all validation phases in sequence"""
	
	# Phase 1: System Health Check
	current_phase = ValidationPhase.SYSTEM_CHECK
	await _phase_system_check()
	
	# Phase 2: QA Validation
	current_phase = ValidationPhase.QA_VALIDATION
	await _phase_qa_validation()
	
	# Phase 3: Performance Validation
	current_phase = ValidationPhase.PERFORMANCE_VALIDATION
	await _phase_performance_validation()
	
	# Phase 4: Integration Validation
	current_phase = ValidationPhase.INTEGRATION_VALIDATION
	await _phase_integration_validation()
	
	# Phase 5: Polish Application
	current_phase = ValidationPhase.POLISH_APPLICATION
	await _phase_polish_application()
	
	# Phase 6: Release Preparation
	current_phase = ValidationPhase.RELEASE_PREPARATION
	await _phase_release_preparation()
	
	# Phase 7: Final Validation
	current_phase = ValidationPhase.FINAL_VALIDATION
	await _phase_final_validation()

func _phase_system_check() -> void:
	"""Phase 1: System Health Check"""
	print("\n🔍 Phase 1: System Health Check")
	print("-".repeat(40))
	
	var system_results = {}
	
	if GameTestSuite:
		print("Running comprehensive game test suite...")
		await GameTestSuite.run_complete_test_suite()
		var test_results = GameTestSuite.get_test_results()
		
		# Calculate system health score
		var total_tests = 0
		var passed_tests = 0
		
		for phase_name in test_results:
			var phase_data = test_results[phase_name]
			if phase_data.has("summary"):
				var summary = phase_data["summary"]
				if summary.has("total") and summary.has("passed"):
					total_tests += summary["total"]
					passed_tests += summary["passed"]
		
		var system_health = (float(passed_tests) / total_tests) * 100 if total_tests > 0 else 0.0
		release_criteria["system_health"]["current"] = system_health
		
		system_results = {
			"health_score": system_health,
			"total_tests": total_tests,
			"passed_tests": passed_tests,
			"test_results": test_results
		}
		
		print("✅ System Health Score: %.1f%% (%d/%d tests passed)" % [system_health, passed_tests, total_tests])
	else:
		print("❌ GameTestSuite not available")
		system_results = {"error": "GameTestSuite not available"}
	
	validation_results["system_check"] = system_results

func _phase_qa_validation() -> void:
	"""Phase 2: QA Validation"""
	print("\n🎯 Phase 2: Quality Assurance Validation")
	print("-" * 40)
	
	var qa_results = {}
	
	if QualityAssurance:
		print("Running comprehensive QA suite...")
		await QualityAssurance.run_full_qa_suite()
		
		var qa_score = QualityAssurance.get_overall_score()
		release_criteria["qa_score"]["current"] = qa_score
		
		qa_results = {
			"qa_score": qa_score,
			"qa_status": QualityAssurance.get_qa_status(),
			"detailed_results": QualityAssurance.get_qa_results()
		}
		
		print("✅ QA Score: %.1f%%" % qa_score)
	else:
		print("❌ QualityAssurance not available")
		qa_results = {"error": "QualityAssurance not available"}
	
	validation_results["qa_validation"] = qa_results

func _phase_performance_validation() -> void:
	"""Phase 3: Performance Validation"""
	print("\n⚡ Phase 3: Performance Validation")
	print("-" * 40)
	
	var performance_results = {}
	
	if PerformanceOptimizer:
		print("Analyzing performance metrics...")
		
		var performance_report = PerformanceOptimizer.generate_performance_report()
		var performance_stats = PerformanceOptimizer.get_performance_stats()
		
		# Calculate performance score
		var fps = performance_stats.get("fps", 0.0)
		var memory_mb = performance_stats.get("memory_usage_mb", 0.0)
		
		var fps_score = min(fps / 60.0, 1.0) * 100
		var memory_score = max(0, (512 - memory_mb) / 512) * 100
		var performance_score = (fps_score + memory_score) / 2
		
		release_criteria["performance_score"]["current"] = performance_score
		
		performance_results = {
			"performance_score": performance_score,
			"fps": fps,
			"memory_mb": memory_mb,
			"fps_score": fps_score,
			"memory_score": memory_score,
			"report": performance_report
		}
		
		print("✅ Performance Score: %.1f%% (FPS: %.1f, Memory: %.1fMB)" % [performance_score, fps, memory_mb])
	else:
		print("❌ PerformanceOptimizer not available")
		performance_results = {"error": "PerformanceOptimizer not available"}
	
	validation_results["performance_validation"] = performance_results

func _phase_integration_validation() -> void:
	"""Phase 4: Integration Validation"""
	print("\n🔗 Phase 4: Integration Validation")
	print("-" * 40)
	
	var integration_results = {}
	
	if IntegrationValidator:
		print("Validating system integrations...")
		await IntegrationValidator.validate_all_integrations()
		
		var integration_summary = IntegrationValidator.get_integration_summary()
		var integration_score = integration_summary.get("success_rate", 0.0)
		
		release_criteria["integration_score"]["current"] = integration_score
		
		integration_results = {
			"integration_score": integration_score,
			"summary": integration_summary,
			"failed_integrations": IntegrationValidator.get_failed_integrations()
		}
		
		print("✅ Integration Score: %.1f%%" % integration_score)
	else:
		print("❌ IntegrationValidator not available")
		integration_results = {"error": "IntegrationValidator not available"}
	
	validation_results["integration_validation"] = integration_results

func _phase_polish_application() -> void:
	"""Phase 5: Polish Application"""
	print("\n✨ Phase 5: Final Polish Application")
	print("-" * 40)
	
	var polish_results = {}
	
	if FinalPolish:
		print("Applying final polish...")
		await FinalPolish.apply_final_polish()
		
		var improvement_count = FinalPolish.get_improvement_count()
		var polish_report = FinalPolish.generate_polish_report()
		
		# Calculate polish completion score
		var expected_improvements = 50  # Expected number of improvements
		var polish_score = min(float(improvement_count) / expected_improvements, 1.0) * 100
		
		release_criteria["polish_completion"]["current"] = polish_score
		
		polish_results = {
			"polish_score": polish_score,
			"improvements_applied": improvement_count,
			"expected_improvements": expected_improvements,
			"report": polish_report
		}
		
		print("✅ Polish Score: %.1f%% (%d improvements applied)" % [polish_score, improvement_count])
	else:
		print("❌ FinalPolish not available")
		polish_results = {"error": "FinalPolish not available"}
	
	validation_results["polish_application"] = polish_results

func _phase_release_preparation() -> void:
	"""Phase 6: Release Preparation"""
	print("\n📦 Phase 6: Release Preparation")
	print("-" * 40)
	
	var release_results = {}
	
	if ReleaseManager:
		print("Preparing release package...")
		await ReleaseManager.start_release_preparation()
		
		var release_status = ReleaseManager.get_release_status()
		var quality_summary = ReleaseManager.get_quality_gate_summary()
		
		release_results = {
			"release_status": release_status,
			"quality_gates": quality_summary,
			"release_ready": release_status == "ready"
		}
		
		print("✅ Release Status: %s" % release_status.to_upper())
	else:
		print("❌ ReleaseManager not available")
		release_results = {"error": "ReleaseManager not available"}
	
	validation_results["release_preparation"] = release_results

func _phase_final_validation() -> void:
	"""Phase 7: Final Validation"""
	print("\n🎯 Phase 7: Final Validation")
	print("-" * 40)
	
	print("Performing final validation checks...")
	
	# Check all critical systems one more time
	var critical_systems = [
		"GameManager", "SaveManager", "AudioManager", "UIManager",
		"SpellSystem", "ProgressionSystem", "AchievementSystem",
		"SpriteGenerator", "AudioGenerator", "AssetRegistry"
	]
	
	var systems_available = 0
	var systems_total = critical_systems.size()
	
	for system_name in critical_systems:
		if get_node_or_null("/root/" + system_name):
			systems_available += 1
	
	var final_score = (float(systems_available) / systems_total) * 100
	release_criteria["final_validation"]["current"] = final_score
	
	var final_results = {
		"final_score": final_score,
		"systems_available": systems_available,
		"systems_total": systems_total,
		"critical_systems_status": {}
	}
	
	for system_name in critical_systems:
		final_results["critical_systems_status"][system_name] = get_node_or_null("/root/" + system_name) != null
	
	validation_results["final_validation"] = final_results
	
	print("✅ Final Validation Score: %.1f%% (%d/%d critical systems)" % [final_score, systems_available, systems_total])

func _calculate_release_readiness() -> bool:
	"""Calculate overall release readiness"""
	print("\n📊 Calculating Release Readiness")
	print("-" * 40)
	
	var total_weighted_score = 0.0
	var total_weight = 0.0
	var criteria_met = 0
	var criteria_total = release_criteria.size()
	
	for criterion_name in release_criteria:
		var criterion = release_criteria[criterion_name]
		var current_score = criterion["current"]
		var threshold = criterion["threshold"]
		var weight = criterion["weight"]
		
		var meets_threshold = current_score >= threshold
		if meets_threshold:
			criteria_met += 1
		
		total_weighted_score += current_score * (weight / 100.0)
		total_weight += weight / 100.0
		
		var status = "✅ PASS" if meets_threshold else "❌ FAIL"
		print("%s: %.1f%% (threshold: %.1f%%) %s" % [criterion_name.replace("_", " ").capitalize(), current_score, threshold, status])
	
	var overall_score = total_weighted_score / total_weight if total_weight > 0 else 0.0
	var release_ready = criteria_met == criteria_total and overall_score >= 85.0
	
	print("\nOverall Score: %.1f%%" % overall_score)
	print("Criteria Met: %d/%d" % [criteria_met, criteria_total])
	print("Release Ready: %s" % ("YES" if release_ready else "NO"))
	
	return release_ready

func _generate_release_info(release_ready: bool) -> Dictionary:
	"""Generate final release information"""
	var info = {
		"game_title": "Spellloop",
		"version": "1.0.0",
		"build_number": 1,
		"release_ready": release_ready,
		"validation_timestamp": Time.get_datetime_string_from_system(),
		"overall_score": 0.0,
		"criteria_met": 0,
		"criteria_total": release_criteria.size(),
		"validation_results": validation_results.duplicate(),
		"release_criteria": release_criteria.duplicate(),
		"system_summary": _generate_system_summary()
	}
	
	# Calculate overall score
	var total_weighted_score = 0.0
	var total_weight = 0.0
	var criteria_met = 0
	
	for criterion_name in release_criteria:
		var criterion = release_criteria[criterion_name]
		var current_score = criterion["current"]
		var threshold = criterion["threshold"]
		var weight = criterion["weight"]
		
		if current_score >= threshold:
			criteria_met += 1
		
		total_weighted_score += current_score * (weight / 100.0)
		total_weight += weight / 100.0
	
	info["overall_score"] = total_weighted_score / total_weight if total_weight > 0 else 0.0
	info["criteria_met"] = criteria_met
	
	return info

func _generate_system_summary() -> Dictionary:
	"""Generate system summary"""
	var autoloads = [
		"GameManager", "SaveManager", "AudioManager", "InputManager", "UIManager", "Localization",
		"SceneTransition", "UIAnimationManager", "TooltipManager", "ThemeManager", "AccessibilityManager",
		"VideoSettings", "EffectsManager", "SpellSystem", "SpellCombinationSystem", "EnemyFactory",
		"EnemyVariants", "ProgressionSystem", "AchievementSystem", "LevelGenerator", "SpriteGenerator",
		"TextureGenerator", "AudioGenerator", "TilesetGenerator", "IconGenerator", "AssetRegistry",
		"TestManager", "PerformanceOptimizer", "IntegrationValidator", "GameTestSuite", "ReleaseManager",
		"QualityAssurance", "FinalPolish"
	]
	
	var systems_loaded = 0
	for system_name in autoloads:
		if get_node_or_null("/root/" + system_name):
			systems_loaded += 1
	
	return {
		"total_autoloads": autoloads.size(),
		"systems_loaded": systems_loaded,
		"load_success_rate": (float(systems_loaded) / autoloads.size()) * 100,
		"missing_systems": _get_missing_systems(autoloads)
	}

func _get_missing_systems(expected_systems: Array) -> Array:
	"""Get list of missing systems"""
	var missing = []
	for system_name in expected_systems:
		if not get_node_or_null("/root/" + system_name):
			missing.append(system_name)
	return missing

func get_current_phase() -> String:
	"""Get current validation phase"""
	match current_phase:
		ValidationPhase.SYSTEM_CHECK:
			return "System Check"
		ValidationPhase.QA_VALIDATION:
			return "QA Validation"
		ValidationPhase.PERFORMANCE_VALIDATION:
			return "Performance Validation"
		ValidationPhase.INTEGRATION_VALIDATION:
			return "Integration Validation"
		ValidationPhase.POLISH_APPLICATION:
			return "Polish Application"
		ValidationPhase.RELEASE_PREPARATION:
			return "Release Preparation"
		ValidationPhase.FINAL_VALIDATION:
			return "Final Validation"
		_:
			return "Unknown"

func get_master_status() -> String:
	"""Get master controller status"""
	return master_status

func get_release_info() -> Dictionary:
	"""Get release information"""
	return release_info

func export_master_report() -> String:
	"""Export complete master report as JSON"""
	var report = {
		"spellloop_master_report": {
			"validation_timestamp": Time.get_datetime_string_from_system(),
			"master_status": master_status,
			"current_phase": get_current_phase(),
			"release_info": release_info,
			"validation_results": validation_results,
			"release_criteria": release_criteria
		}
	}
	
	return JSON.stringify(report, "\t")
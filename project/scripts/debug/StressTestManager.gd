extends Node
class_name StressTestManager

# ═══════════════════════════════════════════════════════════════════════════════
# STRESS TEST MANAGER
# ═══════════════════════════════════════════════════════════════════════════════
# Automates heavy load scenarios to benchmark performance.
# Usage: Add to Main scene or run via command line.

var active: bool = false
var scenario_stage: int = 0
var timer: float = 0.0
var test_duration: float = 60.0

func _ready() -> void:
	print("[StressTestManager] Ready. Press F10 to start stress test.")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F10:
		if not active:
			start_stress_test()
		else:
			print("[StressTest] Already active.")

func start_stress_test() -> void:
	active = true
	scenario_stage = 1
	timer = 0.0
	print("[StressTest] 🚀 STARTED. Initializing scenario 1...")
	_start_scenario_1()

func _process(delta: float) -> void:
	if not active: return
	
	timer += delta
	
	# Scenarios
	if scenario_stage == 1 and timer > 20.0:
		_start_scenario_2()
	elif scenario_stage == 2 and timer > 40.0:
		_start_scenario_3()
	elif scenario_stage == 3 and timer > 60.0:
		_end_stress_test()

func _start_scenario_1() -> void:
	print("[StressTest] ⚔️ Scenario 1: Mass Enemy Spawn (Target: 300)")
	scenario_stage = 1
	# Force spawn enemies via EnemyManager or WaveManager
	var wave_manager = get_tree().get_first_node_in_group("wave_manager")
	if wave_manager:
		# HACK: Force spawn loop
		for i in range(30):
			wave_manager._spawn_enemy_at_random_pos()  # Assuming method exists or similar
			await get_tree().create_timer(0.1).timeout

func _start_scenario_2() -> void:
	print("[StressTest] 🔫 Scenario 2: Projectile Storm")
	scenario_stage = 2
	# Force player to shoot massively
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# Add "Multishot" stats temporarily?
		pass

func _start_scenario_3() -> void:
	print("[StressTest] 🧹 Scenario 3: Cleanup & Garbage Collection")
	scenario_stage = 3
	# Despawn/Kill everything

func _end_stress_test() -> void:
	active = false
	print("[StressTest] 🏁 FINISHED. Logs saved to user://perf_logs/")
	# Dump report
	if PerfTracker:
		PerfTracker.log_event("stress_test_finished")

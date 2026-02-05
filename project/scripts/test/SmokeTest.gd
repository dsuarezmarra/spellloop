# SmokeTest.gd
# Integration test for Loopialike Core Systems
# Verifies: GameManager, AttackManager, Enemy instantiation, Damage Logic
extends Node2D

var game_manager: GameManager
var attack_manager: AttackManager
var test_player: CharacterBody2D
var test_enemy: EnemyBase
var test_weapon_id: String = "ice_wand"
var test_duration: float = 3.0
var test_timer: float = 0.0
var step: int = 0
var errors: Array = []

func _ready() -> void:
	print("\n🔥 [SmokeTest] STARTING SMOKE TEST 🔥")
	_setup_environment()
	
func _process(delta: float) -> void:
	test_timer += delta
	
	match step:
		0: # Wait for initialization
			if test_timer > 0.5:
				_phase_1_verify_init()
				step += 1
		1: # Wait for combat simulation
			if test_timer > 2.0:
				_phase_2_simulate_combat()
				step += 1
		2: # Final checks
			if test_timer > test_duration:
				_phase_3_finalize()
				step += 1
				set_process(false)

func _error(msg: String) -> void:
	push_error("[SmokeTest] ❌ " + msg)
	errors.append(msg)
	print("[SmokeTest] ❌ " + msg)

func _success(msg: String) -> void:
	print("[SmokeTest] ✅ " + msg)

func _setup_environment() -> void:
	# 1. Create Managers if not present (AutoLoads usually handle this, but for isolation we check)
	# In a real run, AutoLoads are already there. We just iterate and check.
	game_manager = get_node_or_null("/root/GameManager")
	if not game_manager:
		_error("GameManager AutoLoad not found!")
		return
	
	# 2. Mock Player
	test_player = CharacterBody2D.new()
	test_player.name = "TestPlayer"
	add_child(test_player)
	
	# Add PlayerStats to player (required by logic)
	var stats = PlayerStats.new()
	stats.name = "PlayerStats"
	test_player.add_child(stats)
	
	# 3. Setup AttackManager (usually child of GameManager, or we create one)
	if game_manager.attack_manager:
		attack_manager = game_manager.attack_manager
		print("[SmokeTest] Using existing AttackManager")
	else:
		# If GameManager hasn't initialized it yet (e.g. not in a run)
		# We force initialization or mock it.
		# Note: GameManager initializes AttackManager in _initialize_dungeon_system called in _ready
		# But usually it needs a "Run" to be active.
		_error("AttackManager not found in GameManager")
	
	# 4. Attach Player to AttackManager (Simulates Start Run)
	if attack_manager:
		attack_manager.initialize(test_player)
		# Add a weapon
		game_manager.equip_weapon(BaseWeapon.new(test_weapon_id))
		_success("Environment Setup Complete")

func _phase_1_verify_init() -> void:
	print("\n[SmokeTest] Phase 1: Verification")
	
	if not test_player: return
	if not attack_manager: return
	
	if attack_manager.weapons.size() > 0:
		_success("Weapon equipped: " + str(attack_manager.weapons.size()))
	else:
		_error("No weapons equipped!")

	# Spawn Test Enemy
	var enemy_script = load("res://scripts/enemies/EnemyBase.gd")
	if enemy_script:
		test_enemy = enemy_script.new()
		test_enemy.name = "TestEnemy"
		# Mock data
		var data = {
			"id": "test_dummy",
			"tier": 1,
			"health": 100,
			"speed": 0,
			"damage": 0,
			"base_xp": 10
		}
		test_enemy.initialize(data, test_player)
		test_enemy.position = Vector2(100, 0) # Within range
		add_child(test_enemy)
		_success("Test Enemy Spawned")
	else:
		_error("Could not load EnemyBase.gd")

func _phase_2_simulate_combat() -> void:
	print("\n[SmokeTest] Phase 2: Combat Simulation")
	
	if not is_instance_valid(test_enemy):
		_error("Test Enemy is invalid/died too early")
		return

	# Simulate damage (as if weapon hit)
	# We want to verify HealthComponent works
	if test_enemy.has_node("HealthComponent"):
		var hc = test_enemy.get_node("HealthComponent")
		var initial_hp = hc.current_health
		hc.take_damage(10, "test")
		
		if hc.current_health < initial_hp:
			_success("Enemy took damage: %d -> %d" % [initial_hp, hc.current_health])
		else:
			_error("Enemy took NO damage!")
	else:
		_error("Enemy has no HealthComponent")

func _phase_3_finalize() -> void:
	print("\n[SmokeTest] Phase 3: Final Report")
	
	if errors.size() == 0:
		print("\n✨ SMOKE TEST PASSED ✨")
		_success("System is stable.")
	else:
		print("\n💀 SMOKE TEST FAILED 💀")
		for e in errors:
			print(" - " + e)
	
	# Markup for automation to read
	print("SMOKE_TEST_COMPLETE")

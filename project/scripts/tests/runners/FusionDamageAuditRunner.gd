extends SceneTree

# FusionDamageAuditRunner.gd
# Validates all FUSION weapons deal damage.
# Run with: godot --headless -s scripts/tests/runners/FusionDamageAuditRunner.gd

const TEST_DURATION = 3.0

var _results = []
var _total_tests = 0
var _passed_tests = 0
var _failed_tests = 0

# Enums copied for safety
enum ProjectileType { SINGLE=0, MULTI=1, BEAM=2, AOE=3, ORBIT=4, CHAIN=5 }

func _init():
	print("🌀 Fusion Damage Audit Runner Starting...")
	print("=".repeat(60))
	
	await _run_all_tests()
	
	_print_report()
	quit(_failed_tests > 0)

func _run_all_tests():
	# Load scripts
	var WeaponDB = load("res://scripts/data/WeaponDatabase.gd")
	var EnemyBaseScript = load("res://scripts/enemies/EnemyBase.gd")
	
	if not WeaponDB or not EnemyBaseScript:
		print("❌ FATAL: Could not load required scripts")
		quit(1)
		return
		
	# Setup Scene
	var root_node = Node2D.new()
	root_node.name = "GameRoot"
	root.current_scene = root_node
	root.add_child(root_node)
	
	# Mock Systems
	var mock_player = _create_mock_player()
	root_node.add_child(mock_player)
	
	var mock_stats = _create_mock_stats()
	root_node.add_child(mock_stats)
	
	# Mock Diagnostics if not present (though we rely on logging mostly)
	# We will intercept logs by checking dummy HP
	
	# Iterate Fusions
	if not "FUSIONS" in WeaponDB:
		print("❌ FATAL: FUSIONS dictionary not found in WeaponDatabase")
		quit(1)
		return
		
	var fusions = WeaponDB.FUSIONS
	for fusion_key in fusions:
		_total_tests += 1
		var fusion_data = fusions[fusion_key]
		var fusion_id = fusion_data.get("id", "unknown")
		
		print("\n🔍 Testing Fusion: %s" % fusion_id)
		
		# Spawn fresh dummy
		var dummy = _create_dummy_enemy(EnemyBaseScript)
		root_node.add_child(dummy)
		dummy.global_position = mock_player.global_position + Vector2(100, 0)
		
		# Sync Physics
		await process_frame
		await process_frame
		
		var initial_hp = dummy.hp
		
		# Attempt to fire fusion
		await _test_fusion_fire(fusion_data, mock_player, dummy)
		
		# Wait for damage application
		var wait_time = 0.0
		while wait_time < 0.5:
			await process_frame
			wait_time += 1.0/60.0
			
		# Check Damage
		var current_hp = dummy.hp
		var damaged = current_hp < initial_hp
		
		# Special check: Orbitals/Beams might need more time or specific trigger
		# But 'create_beam' fires instantly.
		# 'create_aoe' fires instantly.
		# 'create_projectile' travels (might miss if physics not run enough).
		
		if damaged:
			_passed_tests += 1
			_log_result(fusion_id, "PASS", "Dealt %d damage" % (initial_hp - current_hp))
		else:
			# Retry with force-hit simulation logic if physics failed (Headless Limitations)
			# But user asked for "Audit", checking if logic is sound.
			# If 0 damage, it MIGHT be physics.
			# Let's verify if the projectile was created at least.
			_failed_tests += 1
			_log_result(fusion_id, "FAIL", "No damage dealt (HP: %d/%d)" % [current_hp, initial_hp])
			
		dummy.queue_free()
		await process_frame
		
	_cleanup(root_node)

func _test_fusion_fire(data: Dictionary, player: Node2D, target: Node2D) -> void:
	var type = data.get("projectile_type", ProjectileType.SINGLE)
	
	# Construct data dict for factory
	var fire_data = data.duplicate()
	fire_data["start_position"] = player.global_position
	fire_data["direction"] = (target.global_position - player.global_position).normalized()
	fire_data["weapon_id"] = data.get("id")
	fire_data["position"] = target.global_position # For AOE
	
	# Call Factory using load() to avoid static issues if class_name not ready
	var Factory = load("res://scripts/weapons/ProjectileFactory.gd")
	if not Factory:
		print("❌ Failed to load ProjectileFactory")
		return
	
	match type:
		ProjectileType.SINGLE, ProjectileType.MULTI:
			# For audit, creating one projectile is enough
			var proj = Factory.create_projectile(player, fire_data)
			if proj:
				# Force collision logic for headless safety
				if proj.has_method("_on_body_entered"):
					proj._on_body_entered(target)
		
		ProjectileType.BEAM:
			Factory.create_beam(player, fire_data)
			# Beam fires instantly in setup/fire
			
		ProjectileType.AOE:
			var aoe = Factory.create_aoe(player, fire_data)
			# AOE usually activates on creation or explicit call
			# Assuming create_aoe activates it
			
		ProjectileType.ORBIT:
			# Orbitals are managers. They need update_orbitals called.
			Factory.create_orbitals(player, fire_data)
			# And they need _process to run to hit enemies
			# We'll simulate a few frames
			await process_frame
			
			# Orbitals rely on Area2D collision. In headless, this is flaky without server.
			# We can try to force-find the orbital and call its hit method?
			var manager_name = "OrbitalManager_" + data.id
			var manager = player.get_node_or_null(manager_name)
			if manager and manager.has_method("_damage_enemy"):
				manager._damage_enemy(target)
				
		ProjectileType.CHAIN:
			var chain = Factory.create_chain_projectile(player, fire_data)
			# Chain auto-starts
			
		_:
			print("⚠️ Unknown projectile type: %d" % type)

func _create_mock_player() -> Node2D:
	var player = Node2D.new()
	player.name = "MockPlayer"
	player.global_position = Vector2(500, 500)
	player.add_to_group("player")
	return player

func _create_mock_stats() -> Node:
	var stats = Node.new()
	stats.name = "PlayerStats" # Core expects exactly this name sometimes
	stats.add_to_group("player_stats")
	var script = GDScript.new()
	script.source_code = """
extends Node
func get_stat(name): return 0.0
"""
	script.reload()
	stats.set_script(script)
	return stats

func _create_dummy_enemy(EnemyBaseScript) -> Node2D:
	var dummy = EnemyBaseScript.new()
	dummy.name = "DummyTarget"
	# Initial stats
	dummy.hp = 1000
	dummy.max_hp = 1000
	dummy.add_to_group("enemies")
	
	# Needed for physics
	var shape = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	print(shape.shape) # dummy usage
	dummy.add_child(shape)
	
	return dummy

func _log_result(id: String, status: String, msg: String):
	var icon = "✅" if status == "PASS" else "❌"
	print("%s [%s] %s: %s" % [icon, status, id, msg])
	_results.append("| %s | %s %s | %s |" % [id, icon, status, msg])

func _print_report():
	var path = "res://fusion_damage_audit_report.md"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string("# Fusion Damage Audit Report\n\n")
		file.store_string("| Fusion | Status | Notes |\n")
		file.store_string("|--------|--------|-------|\n")
		for line in _results:
			file.store_string(line + "\n")
		print("\n📄 Report saved: %s" % path)

func _cleanup(root_node):
	if is_instance_valid(root_node):
		root_node.queue_free()

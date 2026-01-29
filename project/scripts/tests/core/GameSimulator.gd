# GameSimulator.gd
# Test utility for simulating game scenarios
# Note: This is a test file and may have limited functionality

class_name GameSimulator
extends RefCounted

var attack_manager: AttackManager
var player: Node2D
var tree: SceneTree

# Mock player class for testing
class SimMockPlayer extends Node2D:
	var mock_position: Vector2 = Vector2.ZERO
	
	func get_mock_position() -> Vector2:
		return global_position

func setup(scene_tree: SceneTree):
	tree = scene_tree
	player = SimMockPlayer.new()
	player.name = "MockPlayer"
	
	attack_manager = AttackManager.new()
	attack_manager.name = "AttackManager"
	attack_manager.player = player
	
	# Add to tree (using a temporary node if needed, or passing tree root)
	# In `godot -s`, we have a main loop.
	# We'll just assume we can use the root.
	if tree.root:
		tree.root.add_child(player)
		player.add_child(attack_manager)
		
		# Add PlayerStats group/node if needed
		# AttackManager creates GlobalWeaponStats internally.

func teardown():
	if player and is_instance_valid(player):
		player.queue_free()

func equip_weapon(weapon_id: String) -> BaseWeapon:
	# Get weapon data from database and create weapon manually
	var weapon_data = WeaponDatabase.get_weapon_data(weapon_id)
	if weapon_data.is_empty():
		return null
	
	var weapon = BaseWeapon.new()
	weapon.initialize(weapon_data, player)
	if weapon:
		attack_manager.add_weapon(weapon)
	return weapon

func add_global_stat(stat_name: String, value: float):
	if attack_manager.global_weapon_stats:
		attack_manager.global_weapon_stats.add_stat_bonus(stat_name, value)
	else:
		# Fallback legacy - not supported
		pass

func get_weapon_instance(weapon_id_part: String) -> BaseWeapon:
	for w in attack_manager.weapons:
		if weapon_id_part in w.id:
			return w
	return null

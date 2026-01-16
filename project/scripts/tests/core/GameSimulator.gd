class_name GameSimulator
extends RefCounted

var attack_manager: AttackManager
var player: Node2D
var tree: SceneTree

# Mock classes
class MockPlayer extends Node2D:
	var global_position = Vector2.ZERO
	func get_tree():
		return get_node("/root") # Fallback

func setup(scene_tree: SceneTree):
	tree = scene_tree
	player = MockPlayer.new()
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
	var weapon = WeaponDatabase.create_weapon(weapon_id)
	if weapon:
		attack_manager.add_weapon(weapon)
	return weapon

func add_global_stat(stat_name: String, value: float):
	if attack_manager.global_weapon_stats:
		attack_manager.global_weapon_stats.add_stat_bonus(stat_name, value)
	else:
		# Fallback legacy
		if stat_name == "pierce":
			# Not supported in legacy map directly?
			pass
		pass

func get_weapon_instance(weapon_id_part: String) -> BaseWeapon:
	for w in attack_manager.weapons:
		if weapon_id_part in w.id:
			return w
	return null

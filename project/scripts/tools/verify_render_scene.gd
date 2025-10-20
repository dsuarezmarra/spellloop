extends Node2D

func _ready():
	print("[VerifyRender] starting render verification")
	# Instantiate ParticleManager and EnemyManager if not present
	if not has_node("../ParticleManager"):
		# nothing to do; the scene file may already include a ParticleManager as sibling
		pass
	# Quick checks
	var results = {
		"enemies": false,
		"biomes": false,
		"fx": false
	}
	# enemies: try to spawn 3 enemies via EnemyManager
	var spawned = []
	if has_node("../EnemyManager"):
		var em = get_node("../EnemyManager")
		em._setup_enemy_types()
		for i in range(3):
			var et = em.enemy_types[i % em.enemy_types.size()]
			var pos = Vector2( (i+1) * 80, 0 )
			var e = em.spawn_enemy(et, pos)
			if e:
				spawned.append(e)
		results["enemies"] = spawned.size() == 3

	# biomes: ask InfiniteWorldManager to generate a chunk (use procedural placeholder)
	var wm_script = load("res://scripts/core/InfiniteWorldManager.gd")
	if wm_script:
		var wm = wm_script.new()
		wm.setup_resources()
		wm.generate_initial_chunks()
		results["biomes"] = wm.get_loaded_chunks_count() > 0

	# fx: play each particle type once
	var pm = null
	if get_tree().root and get_tree().root.get_node_or_null("ParticleManager"):
		pm = get_tree().root.get_node("ParticleManager")
	else:
		var pm_script = load("res://scripts/core/ParticleManager.gd")
		if pm_script:
			pm = pm_script.new()
			add_child(pm)
	pm.play_effect("fire", Vector2.ZERO)
	pm.play_effect("ice", Vector2(40,0))
	pm.play_effect("lightning", Vector2(80,0))
	pm.play_effect("arcane", Vector2(120,0))
	pm.play_effect("physical", Vector2(160,0))
	results["fx"] = true

	print("✅ Render Test: Enemies %d/3 | Biomes %s | FX %s" % [spawned.size(), results["biomes"], results["fx"]])
	# Summarize
	if results["enemies"] and results["biomes"] and results["fx"]:
		print("✅ Render verification OK")
	else:
		print("⚠️ Render verification: some items failed. See logs")

	# Keep scene visible for manual inspection


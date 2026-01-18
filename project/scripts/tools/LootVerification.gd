@tool
extends SceneTree

func _init():
	print("--- LOOT VERIFICATION START ---")
	
	var user_list = [
		"sharpshooter", "street_brawler", "executioner", "investor", "vital_magnet", 
		"recycling", "heavy_glass", "pacifist", "chaos", "double_or_nothing", 
		"combustion", "plague_bearer", "blood_pact", "turret", "soul_link", 
		"russian_roulette", "chrono_jump", "myopic", "unique_streak_master"
	]
	
	print("Checking availability of %d new items..." % user_list.size())
	
	var missing = []
	var found = []
	
	for id in user_list:
		var data = UpgradeDatabase.get_upgrade_by_id(id)
		if data.is_empty():
			missing.append(id)
		else:
			found.append(id)
			
	if not missing.is_empty():
		print("❌ MISSING ITEMS (%d):" % missing.size())
		for id in missing:
			print(" - " + id)
	else:
		print("✅ All items found in database!")
		
	if not found.is_empty():
		print("\n--- RUNNING SIMULATION (1000 Rolls) ---")
		var frequencies = {}
		for id in user_list:
			frequencies[id] = 0
			
		# Simulate 1000 level ups (3 choices each = 3000 rolls)
		for i in range(1000):
			var choices = UpgradeDatabase.get_random_player_upgrades(3, [], 0, 10.0)
			for item in choices:
				if item.id in frequencies:
					frequencies[item.id] += 1
		
		print("\n--- FREQUENCIES ---")
		for id in user_list:
			if id in found:
				print("%s: %d times" % [id, frequencies.get(id, 0)])
	
	print("--- LOOT VERIFICATION END ---")
	quit()

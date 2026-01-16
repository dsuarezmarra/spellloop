extends SceneTree

func _init():
	print("[LootVerifier] Iniciando prueba de Loot System...")
	
	var LootManager = load("res://scripts/managers/LootManager.gd")
	if not LootManager:
		print("❌ ERROR: No se pudo cargar LootManager.gd")
		quit(1)
		return

	print("\n--- PRUEBA 1: Cofre Normal (Suerte 1.0) ---")
	var items = LootManager.get_chest_loot(LootManager.ChestType.NORMAL, 1.0)
	print_items(items)

	print("\n--- PRUEBA 2: Cofre Elite (Suerte 1.5) ---")
	items = LootManager.get_chest_loot(LootManager.ChestType.ELITE, 1.5)
	print_items(items)

	print("\n--- PRUEBA 3: Cofre Boss (Suerte 2.0) ---")
	# Boss debería dar 2 items (premio + oro)
	items = LootManager.get_chest_loot(LootManager.ChestType.BOSS, 2.0)
	print_items(items)
	
	print("\n✅ Verificación completada.")
	quit(0)

func print_items(items: Array):
	for item in items:
		var type = item.get("type", "unknown")
		var name = item.get("name", "???")
		var rarity = item.get("rarity", 0)
		var amount = item.get("amount", 0)
		
		# Decode upgrades
		var desc = ""
		if type == "upgrade" and item.has("description"):
			desc = " - " + item.description
			
		print(" > [%s] %s (R%d) %s%s" % [type.to_upper(), name, rarity, "(x%d)" % amount if amount > 0 else "", desc])

extends SceneTree

func _init():
	print("[LootSystemVerifier] Iniciando validación de Loot Estructurado...")
	
	var LootManager = load("res://scripts/managers/LootManager.gd")
	var WeaponDatabase = load("res://scripts/data/WeaponDatabase.gd")
	var WeaponFusionManager = load("res://scripts/weapons/WeaponFusionManager.gd")
	
	if not LootManager:
		print("❌ ERROR: No se pudo cargar LootManager")
		quit(1)
		return

	# Mock Context (AttackManager)
	var mock_context = MockAttackManager.new()

	print("\n--- PRUEBA 1: Cofre Élite (Tier 2+) ---")
	var elite_items = LootManager.get_chest_loot(LootManager.ChestType.ELITE, 1.0, mock_context)
	print("Items obtenidos: %d" % elite_items.size())
	for item in elite_items:
		var tier = item.get("data", {}).get("tier", 0) if item.type == "upgrade" else "N/A"
		print(" > [%s] %s (Tier: %s)" % [item.type, item.name, str(tier)])
		if item.type == "upgrade" and tier < 2:
			print("❌ ERROR: Élite dio tier bajo!")

	print("\n--- PRUEBA 2: Boss sin Fusión (Jackpot) ---")
	mock_context.fusions_available = [] # Sin fusiones
	var boss_items = LootManager.get_chest_loot(LootManager.ChestType.BOSS, 1.0, mock_context)
	print("Items obtenidos: %d (Esperado: 4 -> 3 items + 1 oro)" % boss_items.size())
	for item in boss_items:
		print(" > [%s] %s" % [item.type, item.name])
	
	if boss_items.size() >= 3:
		print("✅ ÉXITO: Boss dio múltiples items (Jackpot)")
	else:
		print("❌ FALLO: Boss no dio Jackpot")

	print("\n--- PRUEBA 3: Boss con Fusión ---")
	# Simular fusión disponible
	mock_context.fusions_available = [{
		"weapon_a": null, "weapon_b": null, 
		"result": {"id": "steam_cannon", "name": "Cañón de Vapor", "description": "Op", "icon": "💨"}
	}]
	
	var fusion_items = LootManager.get_chest_loot(LootManager.ChestType.BOSS, 1.0, mock_context)
	var got_fusion = false
	for item in fusion_items:
		print(" > [%s] %s" % [item.type, item.name])
		if item.type == "fusion":
			got_fusion = true
	
	if got_fusion:
		print("✅ ÉXITO: Boss priorizó Fusión.")
	else:
		print("❌ FALLO: Boss ignoró fusión disponible.")

	print("\n✅ Verificación completada.")
	quit(0)

class MockAttackManager:
	var fusions_available = []
	func get_available_fusions() -> Array:
		return fusions_available

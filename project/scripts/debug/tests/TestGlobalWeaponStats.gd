# TestGlobalWeaponStats.gd
# Tests unitarios para validar la semántica de operaciones add/multiply
# Ejecutar: godot --headless --path . --script scripts/debug/tests/TestGlobalWeaponStats.gd

extends SceneTree

func _init():
	print("═══════════════════════════════════════════════════════════════")
	print(" TEST: GlobalWeaponStats - Semántica add/multiply")
	print("═══════════════════════════════════════════════════════════════")
	
	var passed = 0
	var failed = 0
	
	# Test 1: Multiplicadores buffs acumulan aditivamente
	var gws1 = GlobalWeaponStats.new()
	gws1.reset()
	gws1.multiply_stat("damage_mult", 1.10)  # +10%
	gws1.multiply_stat("damage_mult", 1.20)  # +20%
	# Expected: 1.0 + 0.10 + 0.20 = 1.30 (NO 1.1 * 1.2 = 1.32)
	var result1 = gws1.get_stat("damage_mult")
	if absf(result1 - 1.30) < 0.001:
		print("✅ TEST 1 PASS: Buffs acumulan aditivamente (%.3f == 1.30)" % result1)
		passed += 1
	else:
		print("❌ TEST 1 FAIL: Expected 1.30, got %.3f" % result1)
		failed += 1
	
	# Test 2: Debuffs multiplican correctamente
	var gws2 = GlobalWeaponStats.new()
	gws2.reset()
	gws2.multiply_stat("damage_mult", 1.10)  # +10% → 1.10
	gws2.multiply_stat("damage_mult", 0.90)  # -10% debuff → 1.10 * 0.90 = 0.99
	var result2 = gws2.get_stat("damage_mult")
	if absf(result2 - 0.99) < 0.001:
		print("✅ TEST 2 PASS: Debuff reduce correctamente (%.3f == 0.99)" % result2)
		passed += 1
	else:
		print("❌ TEST 2 FAIL: Expected 0.99, got %.3f" % result2)
		failed += 1
	
	# Test 3: Buff + Buff + Debuff combinado
	var gws3 = GlobalWeaponStats.new()
	gws3.reset()
	gws3.multiply_stat("damage_mult", 1.10)  # +10% → 1.10
	gws3.multiply_stat("damage_mult", 1.20)  # +20% → 1.30 (aditivo)
	gws3.multiply_stat("damage_mult", 0.50)  # -50% debuff → 1.30 * 0.50 = 0.65
	var result3 = gws3.get_stat("damage_mult")
	if absf(result3 - 0.65) < 0.001:
		print("✅ TEST 3 PASS: Buff+Buff+Debuff correcto (%.3f == 0.65)" % result3)
		passed += 1
	else:
		print("❌ TEST 3 FAIL: Expected 0.65, got %.3f" % result3)
		failed += 1
	
	# Test 4: add_stat funciona para planos
	var gws4 = GlobalWeaponStats.new()
	gws4.reset()
	gws4.add_stat("extra_projectiles", 2)
	gws4.add_stat("extra_projectiles", 3)
	var result4 = gws4.get_stat("extra_projectiles")
	if int(result4) == 5:
		print("✅ TEST 4 PASS: add_stat plano correcto (%d == 5)" % int(result4))
		passed += 1
	else:
		print("❌ TEST 4 FAIL: Expected 5, got %d" % int(result4))
		failed += 1
	
	# Test 5: apply_upgrade respeta operation type
	var gws5 = GlobalWeaponStats.new()
	gws5.reset()
	var upgrade = {
		"id": "test_upgrade",
		"name": "Test",
		"effects": [
			{"stat": "damage_mult", "value": 1.15, "operation": "multiply"},
			{"stat": "extra_pierce", "value": 2, "operation": "add"}
		]
	}
	gws5.apply_upgrade(upgrade)
	var result5a = gws5.get_stat("damage_mult")
	var result5b = gws5.get_stat("extra_pierce")
	if absf(result5a - 1.15) < 0.001 and int(result5b) == 2:
		print("✅ TEST 5 PASS: apply_upgrade respeta operations (%.3f, %d)" % [result5a, int(result5b)])
		passed += 1
	else:
		print("❌ TEST 5 FAIL: Expected (1.15, 2), got (%.3f, %d)" % [result5a, int(result5b)])
		failed += 1
	
	# Test 6: Caps se aplican correctamente
	var gws6 = GlobalWeaponStats.new()
	gws6.reset()
	for i in range(20):
		gws6.multiply_stat("attack_speed_mult", 1.20)  # +20% cada vez
	var result6 = gws6.get_stat("attack_speed_mult")
	var limit = GlobalWeaponStats.GLOBAL_STAT_LIMITS["attack_speed_mult"]["max"]
	if result6 <= limit + 0.001:
		print("✅ TEST 6 PASS: Cap aplicado correctamente (%.3f <= %.1f)" % [result6, limit])
		passed += 1
	else:
		print("❌ TEST 6 FAIL: Exceeded cap, got %.3f, limit %.1f" % [result6, limit])
		failed += 1
	
	# Test 7: Debuff puro desde base
	var gws7 = GlobalWeaponStats.new()
	gws7.reset()
	gws7.multiply_stat("damage_mult", 0.80)  # -20% debuff desde base 1.0
	var result7 = gws7.get_stat("damage_mult")
	if absf(result7 - 0.80) < 0.001:
		print("✅ TEST 7 PASS: Debuff desde base correcto (%.3f == 0.80)" % result7)
		passed += 1
	else:
		print("❌ TEST 7 FAIL: Expected 0.80, got %.3f" % result7)
		failed += 1
	
	# Resumen
	print("")
	print("═══════════════════════════════════════════════════════════════")
	print(" RESULTADO: %d/%d tests pasados" % [passed, passed + failed])
	if failed > 0:
		print(" ❌ %d TESTS FALLARON" % failed)
	else:
		print(" ✅ TODOS LOS TESTS PASARON")
	print("═══════════════════════════════════════════════════════════════")
	
	# Limpiar
	gws1.free()
	gws2.free()
	gws3.free()
	gws4.free()
	gws5.free()
	gws6.free()
	gws7.free()
	
	quit(failed)

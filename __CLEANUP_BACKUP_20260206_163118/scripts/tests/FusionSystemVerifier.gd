extends SceneTree

func _init():
	print("--- INICIANDO VERIFICACIÓN DE FUSIÓN Y STATS DINÁMICOS ---")
	
	test_dynamic_stats_calculation()
	test_omni_upgrades()
	
	print("\n--- ¡VERIFICACIÓN COMPLETADA! ---")
	quit()

func test_dynamic_stats_calculation():
	print("\n[TEST] Cálculo de Stats Dinámicos (Fusion)")
	
	# Simular armas base
	var weapon_a = BaseWeapon.new("ice_wand")
	weapon_a.damage = 10
	weapon_a.cooldown = 1.0
	weapon_a.level = 8
	weapon_a.max_level = 8
	
	var weapon_b = BaseWeapon.new("fire_wand")
	weapon_b.damage = 10
	weapon_b.cooldown = 1.0
	weapon_b.level = 8
	weapon_b.max_level = 8
	
	# Instanciar manager
	var fusion_manager = load("res://scripts/weapons/WeaponFusionManager.gd").new()
	
	# Mockear WeaponDatabase para que la fusión sea válida
	print("  > Probando _calculate_dynamic_stats...")
	var stats = fusion_manager._calculate_dynamic_stats(weapon_a, weapon_b)
	
	# Verificar Daño: (10 + 10) * 2 = 40
	if is_equal_approx(stats.damage, 40.0):
		print("  ✅ Damage OK: ", stats.damage)
	else:
		print("  ❌ Damage FALLÓ: ", stats.damage, " (Esperado: 40.0)")
		
	# Verificar Cooldown: ((1.0 + 1.0) / 2) * 0.5 = 0.5
	if is_equal_approx(stats.cooldown, 0.5):
		print("  ✅ Cooldown OK: ", stats.cooldown)
	else:
		print("  ❌ Cooldown FALLÓ: ", stats.cooldown, " (Esperado: 0.5)")

	print("  > Probando fuse_weapons (Nivel 1)...")
	# Simular override de can_fuse_weapons para el test (ya que requiere WeaponDatabase real)
	# Como es difícil mockear el singleton sin frameworks, confiaremos en la unit logic de _calculate 
	# y probaremos la integración parcial si es posible.
	# Pero podemos probar si override_stats funciona en BaseWeapon
	
	var fused = BaseWeapon.new("steam_cannon", true)
	fused.override_stats(stats)
	
	if fused.level == 1:
		print("  ✅ Fused Weapon Level es 1")
	else:
		print("  ❌ Fused Weapon Level NO es 1: ", fused.level)
		
	if fused.damage == 40.0:
		print("  ✅ Fused Weapon Stats Aplicados")
	else:
		print("  ❌ Fused Weapon Stats NO Aplicados")


func test_omni_upgrades():
	print("\n[TEST] Omni-Upgrades en WeaponDatabase")
	
	var WeaponDB = load("res://scripts/data/WeaponDatabase.gd")
	
	# ID de un arma fusionada (ej: steam_cannon)
	var fusion_id = "steam_cannon" 
	
	# Verificar upgrade nivel 2 (Debería ser Omni: +25% daño, etc)
	var upgrade_lvl_2 = WeaponDB.get_level_upgrade(2, fusion_id)
	
	if upgrade_lvl_2.has("damage_mult") and upgrade_lvl_2.damage_mult == 1.25:
		print("  ✅ Level 2 Upgrade es Omni (Damage 1.25): ", upgrade_lvl_2)
	else:
		print("  ❌ Level 2 Upgrade FALLÓ: ", upgrade_lvl_2)
		
	# Verificar upgrade nivel 8 (Mastery)
	var upgrade_lvl_8 = WeaponDB.get_level_upgrade(8, fusion_id)
	
	if upgrade_lvl_8.has("all_mult") and upgrade_lvl_8.all_mult == 1.4:
		print("  ✅ Level 8 Upgrade es Omni Mastery (All 1.4): ", upgrade_lvl_8)
	else:
		print("  ❌ Level 8 Upgrade FALLÓ: ", upgrade_lvl_8)

	# Verificar fallback normal (Ice Wand nivel 2)
	var normal_upgrade = WeaponDB.get_level_upgrade(2, "ice_wand")
	# Ice Wand lvl 2 es pierce_add: 1
	if normal_upgrade.has("pierce_add"):
		print("  ✅ Normal Weapon usa su árbol específico")
	else:
		print("  ❌ Normal Weapon no usó su árbol: ", normal_upgrade)

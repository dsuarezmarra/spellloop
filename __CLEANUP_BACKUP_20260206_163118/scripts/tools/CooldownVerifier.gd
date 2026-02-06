extends SceneTree

func _init():
	print("[Verifier] Iniciando prueba de Cooldown...")
	
	# 1. Crear Mock de GlobalWeaponStats
	var global_stats = Node.new()
	global_stats.set_script(preload("res://scripts/core/GlobalWeaponStats.gd"))
	root.add_child(global_stats)
	
	# 2. Inicializar GlobalStats con Attack Speed aumentado
	# 100% bonus speed = 2.0x multiplier => Cooldown debe ser la mitad
	global_stats.set_stat("attack_speed_mult", 2.0)
	print("[Verifier] Attack Speed Global configurado a: 2.0 (+100%)")
	
	# 3. Crear Arma
	# Usamos 'magic_wand' o 'ice_wand' si existe, si no, fallará el init pero veremos errores
	var weapon = BaseWeapon.new("ice_wand")
	if weapon.id == "":
		print("[Verifier] ERROR: No se pudo crear arma 'ice_wand'. Intentando 'lightning_wand'...")
		weapon = BaseWeapon.new("lightning_wand")
	
	print("[Verifier] Arma creada: %s (Base Cooldown: %.2fs)" % [weapon.id, weapon.cooldown])
	
	# 4. Probar Cooldown Bug Fix
	print("[Verifier] Ejecutando start_cooldown()...")
	weapon.start_cooldown()
	
	var expected_cooldown = weapon.cooldown / 2.0
	var actual_cooldown = weapon.current_cooldown
	
	print("[Verifier] Cooldown Actual: %.4f" % actual_cooldown)
	print("[Verifier] Cooldown Esperado: %.4f" % expected_cooldown)
	
	if is_equal_approx(actual_cooldown, expected_cooldown):
		print("[Verifier] ✅ ÉXITO: El cooldown se redujo correctamente por Stats Globales.")
		quit(0)
	else:
		print("[Verifier] ❌ FALLO: El cooldown no coincide con el valor esperado.")
		print("[Verifier] Diferencia: %.4f" % (actual_cooldown - expected_cooldown))
		quit(1)

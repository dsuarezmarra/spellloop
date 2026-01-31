extends SceneTree

func _init():
	print("=== INICIANDO TEST DE GROWTH Y CAPS ===")
	
	# 1. Cargar PlayerStats
	# PlayerStats es un Autoload, pero en Headless test necesitamos asegurarnos que esté limpio
	# o instanciar uno nuevo
	var player_stats_script = load("res://scripts/core/PlayerStats.gd")
	var ps = player_stats_script.new()
	# Mockear referencias necesarias si hay crashes
	
	print("Estado inicial:")
	print("Growth: ", ps.get_stat("growth"))
	print("XP Mult: ", ps.get_stat("xp_mult"))
	
	# 2. Simular obtener objeto Growth (Rate 2% / min)
	print("\n--- Adquiriendo Growth (2%/min) ---")
	ps.stats["growth"] = 0.02
	
	# 3. Simular el paso del tiempo
	# Minuto 1
	ps._update_growth(60.0)
	print("Minuto 1 - XP Mult (Esperado ~1.02): ", ps.get_stat("xp_mult"))
	
	# Minuto 10
	ps._update_growth(9 * 60.0) # +9 min = 10 total
	print("Minuto 10 - XP Mult (Esperado ~1.20): ", ps.get_stat("xp_mult"))
	
	# Minuto 100 (Debería ser 3.0 por CAP, normal sería 1.0 + 2.0 = 3.0)
	ps._update_growth(90 * 60.0) # +90 min = 100 total
	print("Minuto 100 - XP Mult (Esperado 3.0): ", ps.get_stat("xp_mult"))
	
	# Minuto 200 (Explosión - Debería mantenerse en 3.0 por CAP)
	ps._update_growth(100 * 60.0) # +100 min = 200 total
	print("Minuto 200 - XP Mult (Esperado 3.0 [CAP]): ", ps.get_stat("xp_mult"))
	
	var raw_bonus = ps._game_time_minutes * ps.get_stat("growth")
	print("Raw Bonus calculado: +%d%%" % (raw_bonus * 100))
	
	if ps.get_stat("xp_mult") > 3.0:
		print("❌ FALLO: El cap de XP Mult (3.0) fue ignorado!")
	else:
		print("✅ ÉXITO: El cap de XP Mult fue respetado.")
		
	quit()

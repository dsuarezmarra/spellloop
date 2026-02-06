@tool
extends SceneTree

# CompatibilityAnalysis.gd
# Herramienta para analizar compatibilidad EXHAUSTIVA entre armas (incluyendo fusiones) y mejoras
# Ejecutar con: godot -s scripts/tools/CompatibilityAnalysis.gd

func _init():
	print("════════════════════════════════════════════════════════════")
	print("🔍 ANÁLISIS COMPLETO DE COMPATIBILIDAD (FUSIONES INCLUIDAS)")
	print("════════════════════════════════════════════════════════════")
	
	# 1. Cargar bases de datos
	var weapon_db_script = load("res://scripts/data/WeaponDatabase.gd")
	if not weapon_db_script:
		print("❌ Error: No se pudo cargar WeaponDatabase.gd")
		quit()
		return

	var weapon_db = weapon_db_script.new()
	var weapons = weapon_db.WEAPONS.duplicate()
	
	# Añadir fusiones al análisis
	if "FUSIONS" in weapon_db:
		for fusion_id in weapon_db.FUSIONS:
			weapons[fusion_id] = weapon_db.FUSIONS[fusion_id]
			weapons[fusion_id]["is_fusion"] = true
	
	print("📋 Total Armas a analizar: %d (Base + Fusiones)" % weapons.size())
	print("────────────────────────────────────────────────────────────")

	# 2. Definir Heurísticas de Compatibilidad
	# Reglas: Si un arma tiene X característica, entonces Y mejora es INÚTIL.
	# Generaremos los tags "no_X" basados en esto.
	
	var suggestions = {}
	
	for weapon_id in weapons:
		var w = weapons[weapon_id]
		var w_name = w.get("name", "Unknown")
		var w_proj = w.get("projectile_type", -1)
		var w_target = w.get("target_type", -1)
		var w_pierce = w.get("pierce", 0)
		var w_speed = w.get("projectile_speed", 0)
		var w_duration = w.get("duration", 0)
		var w_area = w.get("area", 0)
		var w_cooldown = w.get("cooldown", 0)
		
		var suggested_tags = []
		
		# --- ANÁLISIS DE PIERCE ---
		# Inútil si: Pierce infinito OR es tipo Ara/Orbit/Beam (generalmente)
		if w_pierce >= 100 or \
		   w_proj == weapon_db_script.ProjectileType.ORBIT or \
		   w_proj == weapon_db_script.ProjectileType.AOE or \
		   w_proj == weapon_db_script.ProjectileType.BEAM or \
		   w_proj == weapon_db_script.ProjectileType.CHAIN: # Chain usa chain_count, no pierce
			suggested_tags.append("no_pierce")

		# --- ANÁLISIS DE VELOCIDAD DE PROYECTIL ---
		# Inútil si: Estático (AOE centrado), Instantáneo (Beam, aunque a veces afecta speed de aparición), o Orbital (speed afecta rotación?)
		# Asumimos que AOE puro (pico de tierra) no usa speed.
		if w_speed <= 0 or w_speed >= 999:
			# Ojo: Algunos beams instantaneos usan 999 pero no se benefician de más speed.
			# Algunos AOE estáticos tienen speed 0.
			suggested_tags.append("no_projectile_speed")
			
		# --- ANÁLISIS DE ÁREA ---
		# Inútil si: Single Target sin explosión?
		# La mayoría de armas aceptan área (hitbox size).
		# Excepción: Quizás armas muy puntería? Pero casi todo en VS-like tiene Area.
		# Dejamos Area como generalmente valido, salvo que sea explícitamente "point" damage.
		
		# --- ANÁLISIS DE DURACIÓN ---
		# Inútil si: Disparo instantáneo sin persistencia.
		# Ej: Disparo básico que desaparece al hit (duration 0).
		# Ej: Beam instantaneo (duration > 0 suele ser cuanto dura el beam).
		if w_duration <= 0 and w_proj != weapon_db_script.ProjectileType.BEAM: 
			# Beams suelen tener duracion. Proyectiles normales (hit and die) tienen duration 0 en data?
			# Revisar data: Ice Wand tiene duration 0.0 -> no se beneficia de duration_mult.
			suggested_tags.append("no_duration")

		# --- ANÁLISIS DE COOLDOWN ---
		# Casi todas usan cooldown. Excepción: Armas pasivas siempre activas (Orbit? No, Orbit suele tener cooldown de respawn/orbit speed).
		# Arcane Orb tiene cooldown 0.0?
		if w_cooldown <= 0:
			suggested_tags.append("no_cooldown")
			
		# --- ANÁLISIS DE MULTI-PROYECTIL (Amount) ---
		# Inútil si: Arma única fija? (Ej: escudo corporal único).
		# Generalmente valido para todos. 
		
		# --- TAGS POSITIVOS (Requisitos) ---
		if w_proj == weapon_db_script.ProjectileType.CHAIN:
			suggested_tags.append("chain")
			
		
		if not suggested_tags.is_empty():
			suggestions[weapon_id] = suggested_tags

	# 3. Reporte
	print("\n📊 REPORTE DE TAGS SUGERIDOS:")
	print("Copiar estos tags a WeaponDatabase.gd para filtrar mejoras inútiles.")
	
	for id in suggestions:
		var w = weapons[id]
		var type_str = "FUSION" if w.get("is_fusion", false) else "BASE"
		print("%-25s [%s] -> %s" % [w.name, type_str, str(suggestions[id])])
		
	print("\n════════════════════════════════════════════════════════════")
	quit()

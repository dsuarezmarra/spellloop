@tool
extends SceneTree

# CompatibilityAnalysis.gd
# Herramienta para analizar compatibilidad entre armas y mejoras
# Ejecutar con: godot -s scripts/tools/CompatibilityAnalysis.gd

func _init():
	print("════════════════════════════════════════════════════════════")
	print("🔍 INICIANDO ANÁLISIS DE COMPATIBILIDAD ARMAS-MEJORAS")
	print("════════════════════════════════════════════════════════════")
	
	# Cargar bases de datos
	var weapon_db = load("res://scripts/data/WeaponDatabase.gd").new()
	var passive_db = load("res://scripts/data/PassiveDatabase.gd").new()
	
	var weapons = weapon_db.WEAPONS
	var passives = passive_db.PASSIVES
	
	print("📋 Armas encontradas: %d" % weapons.size())
	print("📋 Mejoras encontradas: %d" % passives.size())
	print("────────────────────────────────────────────────────────────")

	# Definir reglas de incompatibilidad conocidas para detectar problemas
	# Formato: { "stat_upgrade": ["incompatible_weapon_type", "incompatible_projectile_type"] }
	var weapon_db_script = load("res://scripts/data/WeaponDatabase.gd")
	var incompatibility_rules = {
		"pierce": {
			"projectile_type": [weapon_db_script.ProjectileType.ORBIT, weapon_db_script.ProjectileType.CHAIN, weapon_db_script.ProjectileType.AOE, weapon_db_script.ProjectileType.BEAM],
			"target_type": [weapon_db_script.TargetType.ORBIT, weapon_db_script.TargetType.AREA]
		},
		"projectile_speed": {
			"projectile_type": [weapon_db_script.ProjectileType.BEAM, weapon_db_script.ProjectileType.AOE], # Beam suele ser instantaneo, AOE estático
			"target_type": [weapon_db_script.TargetType.AREA]
		},
		"area": {
			"projectile_type": [weapon_db_script.ProjectileType.SINGLE, weapon_db_script.ProjectileType.BEAM] # A veces beam no escala con área, single simple tampoco
		},
		"amount": { # Extra projectiles
			"projectile_type": [weapon_db_script.ProjectileType.BEAM] # A veces no funciona bien en beams si no está programado
		}
	}
	
	print("\n🚨 DETECTANDO INCOMPATIBILIDADES POTENCIALES ACTUALES:")
	
	var issues_found = 0
	
	for weapon_id in weapons:
		var weapon = weapons[weapon_id]
		var w_name = weapon.name
		var w_proj_type = weapon.get("projectile_type", -1)
		var w_target_type = weapon.get("target_type", -1)
		var w_pierce = weapon.get("pierce", 0)
		
		# Chequear contra stats de mejoras comunes
		
		# CASO 1: Pierce
		if w_pierce > 100: # Infinito (Orbit, etc)
			print("  ⚠️  [PIERCE RECUNDANTE] %-15s tiene pierce infinito (%d). Mejoras de 'Pierce +1' son inútiles." % [w_name, w_pierce])
			issues_found += 1
		elif w_proj_type in incompatibility_rules["pierce"]["projectile_type"]:
			print("  ⚠️  [PIERCE INÚTIL]     %-15s es tipo %s. Pierce no suele tener efecto." % [w_name, str(w_proj_type)])
			issues_found += 1
			
		# CASO 2: Chain
		if w_proj_type == weapon_db_script.ProjectileType.CHAIN:
			# Chain suele usar "saltos", no pierce.
			pass 

	print("\n────────────────────────────────────────────────────────────")
	print("💡 SUGERENCIA DE SISTEMA DE TAGS:")
	print("Para solucionar esto, se recomienda añadir los siguientes tags a las armas:")
	
	for weapon_id in weapons:
		var weapon = weapons[weapon_id]
		var recommended_tags = []
		var w_proj_type = weapon.get("projectile_type", -1)
		
		# Lógica de tags sugeridos
		if w_proj_type == weapon_db_script.ProjectileType.ORBIT or weapon.get("pierce", 0) > 100:
			recommended_tags.append("no_pierce")
			
		if w_proj_type == weapon_db_script.ProjectileType.CHAIN:
			recommended_tags.append("chain")
			recommended_tags.append("no_pierce") # Generalmente chain reemplaza pierce
			
		if w_proj_type == weapon_db_script.ProjectileType.AOE:
			recommended_tags.append("aoe")
			recommended_tags.append("no_pierce")
			recommended_tags.append("no_speed") # Speed suele no afectar AOE estáticos
			
		if w_proj_type == weapon_db_script.ProjectileType.BEAM:
			recommended_tags.append("beam")
			recommended_tags.append("no_pierce")
			
		if recommended_tags.size() > 0:
			print("  🔸 %-15s -> Tags sugeridos: %s" % [weapon.name, str(recommended_tags)])
			
	print("\n════════════════════════════════════════════════════════════")
	print("ANÁLISIS COMPLETADO. %d Problemas potenciales detectados." % issues_found)
	quit()

func _get_enum_string(enum_dict, value):
	for key in enum_dict.keys():
		if enum_dict[key] == value:
			return key
	return "UNKNOWN"

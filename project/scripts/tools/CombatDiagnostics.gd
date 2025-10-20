# CombatDiagnostics.gd
# Diagnóstico del sistema de combate para debugging
# Se ejecuta automáticamente al iniciar el juego

extends Node

func _ready() -> void:
	# Esperar un frame para que todo esté inicializado
	await get_tree().process_frame
	run_diagnostics()

func run_diagnostics() -> void:
	"""Ejecutar diagnóstico completo del sistema de combate"""
	var sep = "="
	for i in range(60):
		sep += "="
	print("\n" + sep)
	print("🔍 COMBAT SYSTEM DIAGNOSTICS")
	print(sep + "\n")
	
	var all_good = true
	
	# 1. Verificar GameManager
	print("1️⃣  Checking GameManager...")
	var gm = get_tree().root.get_node_or_null("GameManager")
	if gm:
		print("  ✓ GameManager found")
		print("  - is_run_active:", gm.is_run_active)
		print("  - attack_manager exists:", gm.attack_manager != null)
		if gm.attack_manager:
			print("  - attack_manager type:", gm.attack_manager.get_class())
	else:
		print("  ✗ GameManager NOT found")
		all_good = false
	
	# 2. Verificar SpellloopGame
	print("\n2️⃣  Checking SpellloopGame...")
	var sg = get_tree().root.get_node_or_null("SpellloopGame")
	if sg:
		print("  ✓ SpellloopGame found")
	else:
		print("  ✗ SpellloopGame NOT found")
		all_good = false
	
	# 3. Verificar Player
	print("\n3️⃣  Checking Player...")
	var player = null
	if sg:
		# Intentar varias rutas
		player = sg.get_node_or_null("WorldRoot/Player")
		if not player:
			player = sg.get_node_or_null("Player")
	
	if player:
		print("  ✓ Player found at:", player.get_path())
		print("  - Type:", player.get_class())
		print("  - HealthComponent exists:", player.has_node("HealthComponent"))
		if player.has_node("HealthComponent"):
			var hc = player.get_node("HealthComponent")
			print("    - Current HP:", hc.get_current_health() if hc.has_method("get_current_health") else "N/A")
			print("    - Max HP:", hc.max_health if hc.has_property("max_health") else "N/A")
	else:
		print("  ✗ Player NOT found")
		all_good = false
	
	# 4. Verificar AttackManager
	print("\n4️⃣  Checking AttackManager...")
	if gm and gm.attack_manager:
		var am = gm.attack_manager
		print("  ✓ AttackManager found")
		print("  - is_active:", am.is_active)
		print("  - player ref:", am.player != null)
		print("  - weapons count:", am.get_weapon_count())
		print("  - has _process:", am.has_method("_process"))
		
		if am.get_weapon_count() > 0:
			print("  - Weapons:")
			for w in am.get_weapons():
				print("    • %s (damage=%d, cooldown=%.2f)" % [w.name, w.damage, w.base_cooldown])
				print("      - projectile_scene:", w.projectile_scene != null)
				print("      - is_active:", w.is_active)
		else:
			print("  ⚠️  No weapons equipped!")
			all_good = false
	else:
		print("  ✗ AttackManager NOT accessible")
		all_good = false
	
	# 5. Verificar ProjectileBase.tscn
	print("\n5️⃣  Checking ProjectileBase.tscn...")
	if ResourceLoader.exists("res://scripts/entities/ProjectileBase.tscn"):
		var proj_scene = load("res://scripts/entities/ProjectileBase.tscn")
		if proj_scene:
			print("  ✓ ProjectileBase.tscn loaded successfully")
			if proj_scene is PackedScene:
				print("  - Is PackedScene: true")
				# Try to instantiate to check for errors
				var test_proj = proj_scene.instantiate()
				if test_proj:
					print("  - Can instantiate: true")
					test_proj.queue_free()
				else:
					print("  - Can instantiate: false")
					all_good = false
		else:
			print("  ✗ ProjectileBase.tscn failed to load")
			all_good = false
	else:
		print("  ✗ ProjectileBase.tscn NOT found at res://scripts/entities/ProjectileBase.tscn")
		all_good = false
	
	# 6. Verificar WeaponBase.gd
	print("\n6️⃣  Checking WeaponBase.gd...")
	if ResourceLoader.exists("res://scripts/entities/WeaponBase.gd"):
		var wb_script = load("res://scripts/entities/WeaponBase.gd")
		if wb_script:
			print("  ✓ WeaponBase.gd loaded")
			# Try to instantiate
			var test_weapon = wb_script.new()
			if test_weapon:
				print("  - Can instantiate: true")
				print("  - Has perform_attack:", test_weapon.has_method("perform_attack"))
				print("  - Has initialize:", test_weapon.has_method("initialize"))
				# Note: Don't call free() on Resource objects, they are RefCounted
		else:
			print("  ✗ WeaponBase.gd failed to load")
			all_good = false
	else:
		print("  ✗ WeaponBase.gd NOT found")
		all_good = false
	
	# 7. Verificar si el juego está en RUN
	print("\n7️⃣  Checking Game State...")
	if gm:
		print("  - Game state:", gm.GameState.keys()[gm.current_state])
		print("  - is_run_active:", gm.is_run_active)
		print("  - player_ref:", gm.player_ref != null)
		if gm.player_ref == null and gm.is_run_active:
			print("  ⚠️  Run is active but player_ref is null!")
			all_good = false
	
	# Final report
	var sep2 = "="
	for i in range(60):
		sep2 += "="
	print("\n" + sep2)
	if all_good:
		print("✅ All combat systems OK - ready to fight!")
	else:
		print("❌ Some issues detected - check above")
	print(sep2 + "\n")

# Helper to check if object has property
func has_property(obj: Object, prop: String) -> bool:
	return obj.get_property_list().any(func(p): return p.name == prop)

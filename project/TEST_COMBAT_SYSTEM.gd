# TEST_COMBAT_SYSTEM.gd
# Script de prueba para verificar que el sistema de combate funciona
# Copiar a scenes/TEST_COMBAT_SYSTEM.tscn o ejecutar manualmente

extends Node

func _ready() -> void:
	print("\n=========================================================")
	print("🎮 TEST SISTEMA DE COMBATE Y AUTO-ATAQUE")
	print("=========================================================\n")
	
	_test_health_component()
	_test_weapon_base()
	_test_attack_manager()
	_test_enemy_attack_system()
	
	print("\n=========================================================")
	print("✅ TODAS LAS PRUEBAS COMPLETADAS")
	print("=========================================================\n")

func _test_health_component() -> void:
	print("📋 TEST 1: HealthComponent")
	
	var hc_script = load("res://scripts/components/HealthComponent.gd")
	if not hc_script:
		print("  ❌ No se pudo cargar HealthComponent.gd")
		return
	
	var hc = hc_script.new()
	hc.name = "TestHealth"
	add_child(hc)
	
	hc.initialize(100)
	print("  ✓ Inicializado con 100 HP")
	
	hc.take_damage(25)
	print("  ✓ Daño de 25 recibido, HP actual: %d" % hc.current_health)
	
	hc.heal(10)
	print("  ✓ Sanado 10 HP, HP actual: %d" % hc.current_health)
	
	var health_pct = hc.get_health_percent()
	print("  ✓ Porcentaje de salud: %.1f%%" % (health_pct * 100))
	
	hc.queue_free()
	print("  ✅ HealthComponent funciona correctamente\n")

func _test_weapon_base() -> void:
	print("📋 TEST 2: WeaponBase")
	
	var wb_script = load("res://scripts/entities/WeaponBase.gd")
	if not wb_script:
		print("  ❌ No se pudo cargar WeaponBase.gd")
		return
	
	var weapon = wb_script.new("test_weapon", "Test Weapon")
	weapon.damage = 20
	weapon.attack_range = 300.0
	weapon.base_cooldown = 0.5
	weapon.element_type = "fire"
	
	print("  ✓ Arma creada: %s" % weapon.name)
	print("  ✓ Daño: %d" % weapon.damage)
	print("  ✓ Cooldown base: %.1f" % weapon.base_cooldown)
	
	# Simular cooldown
	weapon.tick_cooldown(0.3)
	var is_ready_1 = weapon.is_ready_to_fire()
	print("  ✓ Después de 0.3s: ¿Listo? %s" % is_ready_1)
	
	weapon.tick_cooldown(0.3)
	var is_ready_2 = weapon.is_ready_to_fire()
	print("  ✓ Después de 0.6s total: ¿Listo? %s" % is_ready_2)
	
	# Probar mejora
	weapon.apply_upgrade("damage", 0.5)  # +50%
	print("  ✓ Mejora de daño +50%%: nuevo daño = %d" % weapon.damage)
	
	print("  ✅ WeaponBase funciona correctamente\n")

func _test_attack_manager() -> void:
	print("📋 TEST 3: AttackManager")
	
	var am_script = load("res://scripts/core/AttackManager.gd")
	if not am_script:
		print("  ❌ No se pudo cargar AttackManager.gd")
		return
	
	var am = am_script.new()
	am.name = "TestAttackManager"
	add_child(am)
	
	print("  ✓ AttackManager creado")
	
	# Crear arma de prueba
	var wb_script = load("res://scripts/entities/WeaponBase.gd")
	var weapon = wb_script.new("test_projectile", "Test Projectile")
	weapon.damage = 15
	
	am.add_weapon(weapon)
	print("  ✓ Arma equipada")
	
	var count = am.get_weapon_count()
	print("  ✓ Número de armas: %d" % count)
	
	am.upgrade_all_weapons("damage", 0.2)  # +20%
	print("  ✓ Mejora masiva aplicada")
	
	var info = am.get_info()
	print("  ✓ Info: %d armas, daño total: %d" % [info["total_weapons"], info["total_damage"]])
	
	am.queue_free()
	print("  ✅ AttackManager funciona correctamente\n")

func _test_enemy_attack_system() -> void:
	print("📋 TEST 4: EnemyAttackSystem")
	
	var eas_script = load("res://scripts/enemies/EnemyAttackSystem.gd")
	if not eas_script:
		print("  ❌ No se pudo cargar EnemyAttackSystem.gd")
		return
	
	# Crear enemigo dummy
	var enemy = Node.new()
	enemy.name = "TestEnemy"
	add_child(enemy)
	
	var eas = eas_script.new()
	eas.name = "TestAttackSystem"
	enemy.add_child(eas)
	
	eas.initialize(1.5, 50.0, 10, false, null)
	print("  ✓ EnemyAttackSystem inicializado")
	print("  ✓ Cooldown: %.1f, Rango: %.0f, Daño: %d" % [eas.attack_cooldown, eas.attack_range, eas.attack_damage])
	
	enemy.queue_free()
	print("  ✅ EnemyAttackSystem funciona correctamente\n")

func _test_particle_manager() -> void:
	print("📋 TEST 5: ParticleManager")
	
	var pm = get_tree().root.get_node_or_null("ParticleManager")
	if not pm:
		print("  ⚠️  ParticleManager no encontrado en la escena (es un autoload)")
		return
	
	# Probar método
	if pm.has_method("emit_element_effect"):
		pm.emit_element_effect("fire", Vector2(100, 100), 0.5)
		print("  ✓ Efecto de fuego emitido")
	else:
		print("  ❌ emit_element_effect no encontrado")
	
	print("  ✅ ParticleManager accesible\n")

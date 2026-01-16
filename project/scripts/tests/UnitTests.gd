extends SceneTree

# Cargar GameSimulator
const GameSimulator = preload("res://scripts/tests/core/GameSimulator.gd")

func _init():
	print("🚀 Iniciando SpellLoop Test Bench...")
	
	var sim = GameSimulator.new()
	sim.setup(self)
	
	# Asegurar que hay una escena actual para que ProjectileFactory funcione
	if root.get_child_count() > 0:
		current_scene = root.get_child(0)
	else:
		# Crear una escena dummy si no hay
		var scene = Node2D.new()
		scene.name = "TestScene"
		root.add_child(scene)
		current_scene = scene
	
	test_storm_caller_pierce_conversion(sim)
	
	print("\n✅ Todas las pruebas completadas.")
	quit()

func test_storm_caller_pierce_conversion(sim: GameSimulator):
	print("\n🧪 Test: Conversión de Penetración a Cadenas (Storm Caller)")
	
	# 1. Equipar Storm Caller
	var weapon = sim.equip_weapon("storm_caller")
	if not weapon:
		printerr("❌ Error: No se pudo equipar Storm Caller")
		return
	
	# 2. Verificar estado base
	print("   Estado Base: Effect Value = %d, Pierce = %d" % [weapon.effect_value, weapon.pierce])
	# Storm Caller base: effect_value 2, pierce 0.
	
	# 3. Añadir Penetración Global +1
	sim.add_global_stat("extra_pierce", 1.0)
	print("   >>> Añadida mejora: Penetración +1")
	
	# 4. Forzar creación de proyectil (simular ataque)
	# Necesitamos un target simulado para _create_chain_projectile
	var target = Node2D.new()
	target.name = "EnemyTarget"
	current_scene.add_child(target)
	
	# Llamar _create_chain_projectile directamente si es accesible, o attack()
	# attack() requiere enemigos cercanos para weapons con target auto.
	# Storm Caller es target_type: AREA? No, check DB.
	# WeaponDatabase: "target_type": TargetType.AREA (lines 585)
	# Pero attack logic para AREA usa _create_chain_projectile?
	# Storm Caller tags: ["chain"].
	# En BaseWeapon.attack():
	# Si projectile_type == ProjectileType.CHAIN -> llama _spawn_chain()
	
	# _spawn_chain busca target?
	# code: var target = _get_nearest_enemy()
	# Si no hay target, no dispara.
	
	# Mockear _get_nearest_target? O poner un enemigo en el grupo "enemies".
	target.add_to_group("enemies")
	target.global_position = sim.player.global_position + Vector2(100, 0)
	
	# Necesitamos que AttackManager.get_tree() funcione y tenga nodos.
	# Ya está en el tree mockeado.
	
	# weapon.attack()
	weapon.attack(0.1) # Delta
	
	# 5. Inspeccionar el proyectil creado
	# ProjectileFactory añade hijos a current_scene.
	# Buscar ChainProjectile en current_scene
	var created_chains = []
	for child in current_scene.get_children():
		# ChainProjectile es una clase interna o script.
		# Verificamos properties.
		if "chain_count" in child and child != target:
			created_chains.append(child)
	
	if created_chains.size() == 0:
		printerr("❌ Fallo: No se creó ningún proyectil de cadena.")
		return
		
	var projectile = created_chains[-1] # Último creado
	var chain_count = projectile.chain_count
	
	print("   Proyectil creado. Chain Count = %d" % chain_count)
	
	# 6. Aserción
	# Base 2 + 1 Pierce = 3
	if chain_count == 3:
		print("✅ PASÓ: Penetración se convirtió en rebote extra.")
	else:
		printerr("❌ FALLÓ: Se esperaban 3 rebotes, se obtuvieron %d." % chain_count)


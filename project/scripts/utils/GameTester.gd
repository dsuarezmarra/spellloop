extends Node
# Sistema de Testing para Spellloop - Verificar enemigos, spawns y balance

var test_results: Dictionary = {}
var is_testing: bool = false

func _ready():
	print("🧪 Sistema de Testing iniciado")
	
	# Esperar un frame para que todos los sistemas se inicialicen
	await get_tree().process_frame
	
	# Ejecutar tests automáticamente si estamos en debug
	if OS.is_debug_build():
		run_all_tests()

func run_all_tests():
	"""Ejecutar todos los tests del sistema"""
	print("🚀 Ejecutando tests del sistema...")
	is_testing = true
	
	test_autoloads()
	test_enemy_scripts()
	test_magic_system()
	test_items_system()
	test_spawn_system()
	
	print_test_results()
	is_testing = false

func test_autoloads():
	"""Verificar que todos los autoloads estén cargados"""
	print("📋 Testing autoloads...")
	
	var autoloads = [
		"GameManager",
		"SpawnTable", 
		"MagicDefinitions",
		"ItemsDefinitions",
		"ScaleManager"
	]
	
	for autoload_name in autoloads:
		var node = get_node_or_null("/root/" + autoload_name)
		test_results[autoload_name + "_loaded"] = node != null
		
		if node:
			print("✅ " + autoload_name + " cargado correctamente")
		else:
			print("❌ " + autoload_name + " NO encontrado")

func test_enemy_scripts():
	"""Verificar que los scripts de enemigos existan y sean válidos"""
	print("🐛 Testing enemy scripts...")
	
	var enemy_scripts = [
		"res://scripts/enemies/enemy_tier_1_slime_novice.gd",
		"res://scripts/enemies/enemy_tier_1_goblin_scout.gd",
		"res://scripts/enemies/enemy_tier_1_skeleton_warrior.gd",
		"res://scripts/enemies/enemy_tier_1_shadow_bat.gd",
		"res://scripts/enemies/enemy_tier_1_poison_spider.gd"
	]
	
	for script_path in enemy_scripts:
		var script = load(script_path)
		var script_name = script_path.get_file().get_basename()
		test_results[script_name + "_valid"] = script != null
		
		if script:
			print("✅ " + script_name + " válido")
		else:
			print("❌ " + script_name + " no se puede cargar")

func test_magic_system():
	"""Verificar sistema de magias"""
	print("🔮 Testing magic system...")
	
	if not MagicDefinitions:
		test_results["magic_system"] = false
		print("❌ MagicDefinitions no disponible")
		return
	
	# Test obtener magia base
	var fire_magic = MagicDefinitions.get_base_magic(MagicDefinitions.MagicType.FUEGO)
	test_results["fire_magic_valid"] = fire_magic != null and "name" in fire_magic
	
	if fire_magic:
		print("✅ Magia de fuego: ", fire_magic.name)
	else:
		print("❌ No se pudo obtener magia de fuego")
	
	# Test combinación
	var types = [MagicDefinitions.MagicType.FUEGO, MagicDefinitions.MagicType.HIELO]
	var combination = MagicDefinitions.can_combine(types)
	test_results["magic_combination"] = combination != ""
	
	if combination != "":
		var combo_data = MagicDefinitions.get_combination(combination)
		print("✅ Combinación encontrada: ", combo_data.name)
	else:
		print("❌ No se encontró combinación Fuego+Hielo")

func test_items_system():
	"""Verificar sistema de items"""
	print("💎 Testing items system...")
	
	if not ItemsDefinitions:
		test_results["items_system"] = false
		print("❌ ItemsDefinitions no disponible")
		return
	
	# Test obtener item
	var basic_wand = ItemsDefinitions.get_item("basic_wand")
	test_results["basic_item_valid"] = basic_wand != null and "name" in basic_wand
	
	if basic_wand:
		print("✅ Item básico: ", basic_wand.name)
	else:
		print("❌ No se pudo obtener basic_wand")
	
	# Test items por rareza
	var white_items = ItemsDefinitions.get_items_by_rarity(ItemsDefinitions.ItemRarity.WHITE)
	test_results["white_items_count"] = white_items.size()
	print("✅ Items blancos encontrados: ", white_items.size())
	
	# Test item aleatorio
	var random_item = ItemsDefinitions.get_weighted_random_item(1, 1.0)
	test_results["random_item_valid"] = random_item != null
	
	if random_item:
		print("✅ Item aleatorio: ", random_item.name)
	else:
		print("❌ No se pudo generar item aleatorio")

func test_spawn_system():
	"""Verificar sistema de spawneo"""
	print("🎯 Testing spawn system...")
	
	if not SpawnTable:
		test_results["spawn_system"] = false
		print("❌ SpawnTable no disponible")
		return
	
	# Test obtener info de tier
	var tier_info = SpawnTable.get_current_tier_info()
	test_results["tier_info_valid"] = tier_info.size() > 0
	
	if tier_info.size() > 0:
		print("✅ Tier info: ", tier_info.get("enemies", []).size(), " enemigos")
	else:
		print("❌ No se pudo obtener info de tier")
	
	# Test lista de enemigos
	var enemies = SpawnTable.get_enemy_list_for_tier(1)
	test_results["tier_1_enemies"] = enemies.size()
	print("✅ Enemigos Tier 1: ", enemies.size())
	
	# Test estimación de XP
	var xp_estimate = SpawnTable.get_estimated_xp_per_minute()
	test_results["xp_estimate"] = xp_estimate
	print("✅ XP estimada por minuto: ", xp_estimate)

func print_test_results():
	"""Mostrar resumen de todos los tests"""
	print("\n" + "="*50)
	print("🧪 RESUMEN DE TESTS")
	print("="*50)
	
	var total_tests = test_results.size()
	var passed_tests = 0
	
	for test_name in test_results.keys():
		var result = test_results[test_name]
		var status = "✅ PASS" if result else "❌ FAIL"
		
		if typeof(result) == TYPE_INT:
			status = "📊 " + str(result)
		elif typeof(result) == TYPE_BOOL and result:
			passed_tests += 1
		
		print("%s: %s" % [test_name, status])
	
	print("-" * 50)
	print("Resultado: %d/%d tests pasaron" % [passed_tests, total_tests])
	
	if passed_tests == total_tests:
		print("🎉 ¡TODOS LOS TESTS PASARON!")
	else:
		print("⚠️  Algunos tests fallaron. Revisar configuración.")
	
	print("="*50)

# Funciones para testing manual
func spawn_test_enemy():
	"""Spawear enemigo de prueba"""
	if SpawnTable:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var spawn_pos = player.global_position + Vector2(100, 0)
			SpawnTable.force_spawn_enemy("enemy_tier_1_slime_novice", spawn_pos)
			print("🐛 Enemigo de prueba spawneado")

func clear_test_enemies():
	"""Limpiar enemigos de prueba"""
	if SpawnTable:
		SpawnTable.clear_all_enemies()
		print("🧹 Enemigos limpiados")

func simulate_boss_spawn():
	"""Simular spawn de boss"""
	if SpawnTable:
		SpawnTable.spawn_boss("boss_5min_archmage_corrupt")
		print("👑 Boss de prueba spawneado")

func test_player_damage():
	"""Probar sistema de daño del jugador"""
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("take_damage"):
		player.take_damage(10)
		print("💔 Daño de prueba aplicado al jugador")

func test_player_xp():
	"""Probar sistema de XP del jugador"""
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("gain_experience"):
		player.gain_experience(50)
		print("⭐ XP de prueba otorgada al jugador")

# Input para testing manual (solo en debug)
func _input(event):
	if not OS.is_debug_build():
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				run_all_tests()
			KEY_F2:
				spawn_test_enemy()
			KEY_F3:
				clear_test_enemies()
			KEY_F4:
				simulate_boss_spawn()
			KEY_F5:
				test_player_damage()
			KEY_F6:
				test_player_xp()
			KEY_F12:
				print_debug_info()

func print_debug_info():
	"""Mostrar información de debug del estado actual"""
	print("\n" + "="*40)
	print("🔍 DEBUG INFO")
	print("="*40)
	
	if GameManager:
		print("GameManager - Estado: ", GameManager.current_state)
		print("GameManager - Minutos: ", GameManager.get_elapsed_minutes())
	
	if SpawnTable:
		print("SpawnTable - Tier: ", SpawnTable.current_tier)
		print("SpawnTable - Entidades: ", SpawnTable.entities_on_screen)
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		print("Player - Vida: ", player.current_health, "/", player.max_health)
		print("Player - Nivel: ", player.level)
		print("Player - XP: ", player.experience)
	
	print("="*40)
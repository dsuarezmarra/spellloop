extends Node

func _ready():
	print("=== INICIANDO TESTS DE SPELLLOOP ===")
	var total_tests = 0
	var passed_tests = 0
	
	# Test 1: Verificar GameManager
	total_tests += 1
	if test_game_manager():
		passed_tests += 1
		print("✅ Test GameManager: PASADO")
	else:
		print("❌ Test GameManager: FALLIDO")
	
	# Test 2: Verificar DungeonSystem
	total_tests += 1
	if test_dungeon_system():
		passed_tests += 1
		print("✅ Test DungeonSystem: PASADO")
	else:
		print("❌ Test DungeonSystem: FALLIDO")
	
	# Test 3: Verificar generación de dungeons
	total_tests += 1
	if test_dungeon_generation():
		passed_tests += 1
		print("✅ Test Generación Dungeon: PASADO")
	else:
		print("❌ Test Generación Dungeon: FALLIDO")
	
	# Test 4: Verificar sistema de recompensas
	total_tests += 1
	if test_reward_system():
		passed_tests += 1
		print("✅ Test Sistema Recompensas: PASADO")
	else:
		print("❌ Test Sistema Recompensas: FALLIDO")
	
	print("\n=== RESULTADOS FINALES ===")
	var executed_text = "Tests ejecutados: " + str(total_tests)
	var passed_text = "Tests pasados: " + str(passed_tests)
	var failed_text = "Tests fallidos: " + str(total_tests - passed_tests)
	
	print(executed_text)
	print(passed_text)
	print(failed_text)
	
	if passed_tests == total_tests:
		print("🎉 TODOS LOS TESTS PASARON 🎉")
	else:
		print("⚠️ Algunos tests fallaron. Revisar errores arriba.")

func test_game_manager() -> bool:
	if not GameManager:
		print("  Error: GameManager no está disponible")
		return false
	
	print("  GameManager encontrado correctamente")
	return true

func test_dungeon_system() -> bool:
	if not DungeonSystem:
		print("  Error: DungeonSystem no está disponible")
		return false
	
	print("  DungeonSystem encontrado correctamente")
	return true

func test_dungeon_generation() -> bool:
	var generator = DungeonGenerator.new()
	var dungeon_data = generator.generate_dungeon()
	
	if not dungeon_data:
		print("  Error: No se pudo generar dungeon")
		return false
	
	if dungeon_data["rooms"].size() == 0:
		print("  Error: Dungeon generado sin rooms")
		return false
	
	var rooms_text = "  Dungeon generado con " + str(dungeon_data["rooms"].size()) + " rooms"
	print(rooms_text)
	return true

func test_reward_system() -> bool:
	var reward_system = RewardSystem.new()
	
	# Test experiencia
	var exp_reward = reward_system.calculate_experience_reward(5, 1.0)
	if exp_reward <= 0:
		print("  Error: Experiencia calculada incorrecta")
		return false
	
	var exp_text = "  Sistema de recompensas funcionando (exp: " + str(exp_reward) + ")"
	print(exp_text)
	return true
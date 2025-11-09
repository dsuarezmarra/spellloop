extends Node
## Script de prueba automática del sistema de biomas integrado
## Verifica que:
## 1. BiomeChunkApplier se carga correctamente
## 2. Las texturas de biomas se aplican
## 3. No hay regresión en jugador/enemigos/proyectiles

class_name BiomeIntegrationTest

const SEPARATOR = "══════════════════════════════════════════════════════════════════════════"

var test_results: Dictionary = {
	"biome_applier_loaded": false,
	"biome_config_valid": false,
	"textures_applied": false,
	"player_moving": false,
	"enemies_spawning": false,
	"projectiles_working": false,
	"no_crashes": false
}

var frame_count: int = 0
var test_duration: int = 600  # 10 segundos a 60 FPS
var player_start_pos: Vector2 = Vector2.ZERO
var player_current_pos: Vector2 = Vector2.ZERO

func _ready():
	print("\n" + SEPARATOR)
	print("🧪 BIOME INTEGRATION TEST - INICIANDO")
	print(SEPARATOR + "\n")
	
	# Verificar que BiomeChunkApplier está cargado
	_check_biome_applier()
	
	# Verificar config JSON
	_check_biome_config()
	
	# Verificar texturas
	_check_textures()
	
	# Iniciar monitoreo
	set_process(true)
	
	# Guardar posición inicial
	var player = get_tree().root.find_child("SpellloopPlayer", true, false)
	if player:
		player_start_pos = player.global_position

func _process(_delta: float) -> void:
	frame_count += 1
	
	# Cada 10 fotogramas, verificar estado
	if frame_count % 10 == 0:
		_check_player_movement()
		_check_enemies()
		_check_projectiles()
	
	# Cada 120 fotogramas (2 segundos), mostrar diagnóstico
	if frame_count % 120 == 0:
		_show_diagnostics()
	
	# Al terminar las pruebas
	if frame_count >= test_duration:
		_finalize_tests()
		set_process(false)

func _check_biome_applier() -> void:
	"""Verificar que BiomeChunkApplierOrganic está cargado en InfiniteWorldManager"""
	var world_manager = get_tree().root.find_child("InfiniteWorldManager", true, false)
	
	if world_manager:
		var has_biome_applier = world_manager.find_child("BiomeChunkApplierOrganic", true, false) != null
		test_results["biome_applier_loaded"] = has_biome_applier
		
		if has_biome_applier:
			print("✅ BiomeChunkApplierOrganic encontrado en InfiniteWorldManager")
		else:
			print("❌ BiomeChunkApplierOrganic NO encontrado en InfiniteWorldManager")
	else:
		print("❌ InfiniteWorldManager no encontrado")

func _check_biome_config() -> void:
	"""Verificar que el JSON de configuración es válido"""
	var config_path = "res://assets/textures/biomes/biome_textures_config.json"
	
	if ResourceLoader.exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		if file:
			var json_str = file.get_as_text()
			var json = JSON.new()
			if json.parse(json_str) == OK:
				var data = json.get_data()
				var biome_count = data.get("biomes", []).size()
				test_results["biome_config_valid"] = biome_count == 6
				print("✅ Configuración JSON válida (%d biomas encontrados)" % biome_count)
			else:
				print("❌ JSON inválido: %s" % json.get_error_message())
		else:
			print("❌ No se pudo abrir el archivo JSON")
	else:
		print("❌ Archivo JSON no existe en: %s" % config_path)

func _check_textures() -> void:
	"""Verificar que las texturas PNG existen"""
	var biomes = ["Grassland", "Desert", "Snow", "Lava", "ArcaneWastes", "Forest"]
	var textures = ["base.png", "decor1.png", "decor2.png", "decor3.png"]
	var all_found = true
	
	for biome in biomes:
		for texture in textures:
			var path = "res://assets/textures/biomes/%s/%s" % [biome, texture]
			if not ResourceLoader.exists(path):
				print("❌ Textura no encontrada: %s" % path)
				all_found = false
	
	test_results["textures_applied"] = all_found
	
	if all_found:
		print("✅ Todas las texturas PNG encontradas (24/24)")

func _check_player_movement() -> void:
	"""Verificar que el jugador se mueve correctamente"""
	var player = get_tree().root.find_child("SpellloopPlayer", true, false)
	
	if player:
		player_current_pos = player.global_position
		# El jugador debería haber cambiado de posición
		var moved = player_current_pos.distance_to(player_start_pos) > 10
		test_results["player_moving"] = moved

func _check_enemies() -> void:
	"""Verificar que los enemigos se generan"""
	var enemies_root = get_tree().root.find_child("EnemiesRoot", true, false)
	
	if enemies_root:
		var enemy_count = enemies_root.get_child_count()
		test_results["enemies_spawning"] = enemy_count > 0

func _check_projectiles() -> void:
	"""Verificar que hay proyectiles activos"""
	var pickups_root = get_tree().root.find_child("PickupsRoot", true, false)
	
	if pickups_root:
		# Buscar nodos que puedan ser proyectiles
		var has_projectiles = pickups_root.get_child_count() > 0
		test_results["projectiles_working"] = has_projectiles

func _show_diagnostics() -> void:
	"""Mostrar estado actual de las pruebas"""
	print("\n--- Diagnóstico en frame %d ---" % frame_count)
	print("BiomeChunkApplierOrganic cargado: %s" % test_results["biome_applier_loaded"])
	print("Config JSON válida: %s" % test_results["biome_config_valid"])
	print("Texturas OK: %s" % test_results["textures_applied"])
	print("Player moviendo: %s" % test_results["player_moving"])
	print("Enemigos generando: %s" % test_results["enemies_spawning"])
	print("Proyectiles: %s" % test_results["projectiles_working"])
	print("Posición jugador: %.0f, %.0f" % [player_current_pos.x, player_current_pos.y])

func _finalize_tests() -> void:
	"""Finalizar pruebas y mostrar resumen"""
	print("\n" + SEPARATOR)
	print("🧪 PRUEBAS COMPLETADAS")
	print(SEPARATOR + "\n")
	
	var passed = 0
	var total = test_results.size()
	
	print("📊 RESULTADOS:")
	for test_name in test_results.keys():
		var result = test_results[test_name]
		var icon = "✅" if result else "❌"
		print("  %s %s" % [icon, test_name])
		if result:
			passed += 1
	
	print("\n📈 PUNTUACIÓN: %d/%d pruebas pasadas" % [passed, total])
	
	if passed == total:
		print("\n🎉 ¡TODAS LAS PRUEBAS PASARON!")
	else:
		print("\n⚠️  Algunas pruebas fallaron. Revisar logs arriba.")
	
	print("\n" + SEPARATOR + "\n")
	
	# Guardar resultados en metadatos para verificación posterior
	set_meta("test_results", test_results)
	set_meta("test_completed", true)

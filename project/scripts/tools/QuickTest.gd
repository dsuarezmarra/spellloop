"""
⚡ QUICK TEST - Verificación rápida de sistemas
Ejecutar: godot --headless --script QuickTest.gd
"""

extends SceneTree

var results: Array = []

func _init() -> void:
	print("\n🔍 INICIANDO QUICK TEST...\n")
	
	test_loads()
	test_class_names()
	
	print_results()
	quit(0)

func test_loads():
	"""Probar que los archivos se cargan correctamente"""
	print("[TEST] Probando carga de scripts...")
	
	var scripts = [
		"res://scripts/core/InfiniteWorldManager.gd",
		"res://scripts/core/BiomeGenerator.gd",
		"res://scripts/core/ChunkCacheManager.gd",
		"res://scripts/core/ItemManager.gd",
		"res://scripts/core/EnemyBase.gd",
		"res://scripts/core/IceProjectile.gd",
	]
	
	for script_path in scripts:
		if ResourceLoader.exists(script_path):
			var script = load(script_path)
			if script:
				results.append({
					"name": script_path.split("/")[-1],
					"status": "✅ CARGADO",
					"error": ""
				})
			else:
				results.append({
					"name": script_path.split("/")[-1],
					"status": "❌ NO CARGÓ",
					"error": "load() retornó null"
				})
		else:
			results.append({
				"name": script_path.split("/")[-1],
				"status": "❌ NO EXISTE",
				"error": "Archivo no encontrado"
			})

func test_class_names():
	"""Probar que los class_name existen"""
	print("[TEST] Probando class_names...")
	
	var classes = [
		"InfiniteWorldManager",
		"BiomeGenerator",
		"ChunkCacheManager",
		"ItemManager",
		"EnemyBase",
		"IceProjectile"
	]
	
	for class_name in classes:
		var cls = ClassDB.class_exists(class_name)
		if cls:
			results.append({
				"name": "class_name:" + class_name,
				"status": "✅ EXISTE",
				"error": ""
			})
		else:
			results.append({
				"name": "class_name:" + class_name,
				"status": "⚠️ NO REGISTRADO",
				"error": "No está en ClassDB (normal si es script personalizado)"
			})

func print_results():
	print("\n" + "=".repeat(80))
	print("📊 RESULTADOS DEL TEST")
	print("=".repeat(80) + "\n")
	
	var passed = 0
	var failed = 0
	var warned = 0
	
	for result in results:
		print("%s | %s | %s" % [result["status"], result["name"], result["error"]])
		
		if result["status"].contains("✅"):
			passed += 1
		elif result["status"].contains("❌"):
			failed += 1
		elif result["status"].contains("⚠️"):
			warned += 1
	
	print("\n" + "=".repeat(80))
	print("✅ PASARON: %d | ❌ FALLARON: %d | ⚠️ ADVERTENCIAS: %d" % [passed, failed, warned])
	print("=".repeat(80) + "\n")
	
	if failed > 0:
		print("❌ PROBLEMAS DETECTADOS - Revisar arriba")
	else:
		print("✅ TODO OK - Sistema listo para testing")

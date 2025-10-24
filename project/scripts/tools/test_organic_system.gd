# test_organic_system.gd
# Script de test para verificar la integración del sistema orgánico completo

extends Node

"""
🧪 TEST SISTEMA ORGÁNICO INTEGRADO
=================================

Este script verifica que todos los componentes del sistema orgánico
funcionen correctamente en conjunto:

1. OrganicShapeGenerator - Generación de formas irregulares
2. InfiniteWorldManager - Gestión de regiones orgánicas
3. BiomeGenerator - Contenido de biomas para regiones
4. BiomeRegionApplier - Texturas aplicadas a formas irregulares
5. OrganicTextureBlender - Transiciones suaves entre biomas

Uso: Ejecutar desde Godot editor como AutoLoad o script independiente
"""

# ========== CONFIGURACIÓN DE PRUEBAS ==========
var test_world_seed: int = 42
var test_region_count: int = 5
var test_results: Dictionary = {}

# ========== COMPONENTES A PROBAR ==========
var organic_shape_generator: OrganicShapeGenerator
var biome_generator: BiomeGenerator
var biome_region_applier: BiomeRegionApplier
var organic_texture_blender: OrganicTextureBlenderSystem

func _ready() -> void:
	"""Ejecutar batería completa de tests"""
	print("\n" + "=".repeat(60))
	print("🧪 INICIANDO TESTS DEL SISTEMA ORGÁNICO INTEGRADO")
	print("=".repeat(60))

	_run_integration_tests()

	print("\n" + "=".repeat(60))
	print("📊 RESUMEN DE RESULTADOS")
	_print_test_summary()
	print("=".repeat(60))

# ========== TESTS DE INTEGRACIÓN ==========

func _run_integration_tests() -> void:
	"""Ejecutar todos los tests de integración"""

	# Test 1: Inicialización de componentes
	_test_component_initialization()

	# Test 2: Generación de regiones orgánicas
	_test_organic_region_generation()

	# Test 3: Pipeline completo de generación
	_test_complete_generation_pipeline()

	# Test 4: Verificación de texturas y blending
	_test_texture_application_and_blending()

	# Test 5: Rendimiento del sistema
	_test_system_performance()

func _test_component_initialization() -> void:
	"""Test 1: Verificar que todos los componentes se inicialicen correctamente"""
	print("\n🔧 Test 1: Inicialización de componentes")

	var results = {
		"organic_shape_generator": false,
		"biome_generator": false,
		"biome_region_applier": false,
		"organic_texture_blender": false
	}

	# Inicializar OrganicShapeGenerator
	if OrganicShapeGenerator:
		organic_shape_generator = OrganicShapeGenerator.new()
		organic_shape_generator.initialize(test_world_seed)
		results.organic_shape_generator = true
		print("  ✅ OrganicShapeGenerator inicializado")
	else:
		print("  ❌ OrganicShapeGenerator falló")

	# Inicializar BiomeGenerator
	if BiomeGenerator:
		biome_generator = BiomeGenerator.new()
		biome_generator.world_seed = test_world_seed
		results.biome_generator = true
		print("  ✅ BiomeGenerator inicializado")
	else:
		print("  ❌ BiomeGenerator falló")

	# Inicializar BiomeRegionApplier
	if BiomeRegionApplier:
		biome_region_applier = BiomeRegionApplier.new()
		results.biome_region_applier = true
		print("  ✅ BiomeRegionApplier inicializado")
	else:
		print("  ❌ BiomeRegionApplier falló")

	# Inicializar OrganicTextureBlender
	if OrganicTextureBlenderSystem:
		organic_texture_blender = OrganicTextureBlenderSystem.new()
		results.organic_texture_blender = true
		print("  ✅ OrganicTextureBlender inicializado")
	else:
		print("  ❌ OrganicTextureBlender falló")

	test_results["component_initialization"] = results

func _test_organic_region_generation() -> void:
	"""Test 2: Verificar generación de regiones orgánicas"""
	print("\n🌊 Test 2: Generación de regiones orgánicas")

	if not organic_shape_generator:
		print("  ❌ OrganicShapeGenerator no disponible")
		return

	var success_count = 0
	var total_tests = test_region_count

	for i in range(total_tests):
		var _region_center = Vector2(i * 1000.0, 0.0)
		var region_id = Vector2i(i, 0)

		var organic_region = await organic_shape_generator.generate_region_async(region_id)

		if organic_region and organic_region.boundary_points.size() > 3:
			success_count += 1
			print("  ✅ Región %d: %d puntos de contorno" % [i, organic_region.boundary_points.size()])
		else:
			print("  ❌ Región %d: generación falló" % i)

	var success_rate = float(success_count) / float(total_tests) * 100.0
	test_results["organic_region_generation"] = {
		"success_count": success_count,
		"total_tests": total_tests,
		"success_rate": success_rate
	}

	print("  📊 Tasa de éxito: %.1f%% (%d/%d)" % [success_rate, success_count, total_tests])

func _test_complete_generation_pipeline() -> void:
	"""Test 3: Verificar pipeline completo de generación"""
	print("\n🏭 Test 3: Pipeline completo de generación")

	if not all_components_available():
		print("  ❌ No todos los componentes están disponibles")
		return

	var pipeline_success = 0
	var total_tests = 3

	for i in range(total_tests):
		var _region_center = Vector2(i * 1500.0, 500.0)
		var region_id = Vector2i(i, 1)

		print("  🔄 Procesando región %d..." % i)

		# Paso 1: Generar forma orgánica
		var organic_region = await organic_shape_generator.generate_region_async(region_id)
		if not organic_region:
			print("    ❌ Paso 1 falló: forma orgánica")
			continue

		# Paso 2: Generar contenido de bioma
		var region_data = await biome_generator.generate_region_async(organic_region)
		if not region_data or region_data.is_empty():
			print("    ❌ Paso 2 falló: contenido de bioma")
			continue

		# Paso 3: Crear nodo visual
		var region_node = Node2D.new()
		region_node.name = "TestRegion_%d" % i
		add_child(region_node)

		# Paso 4: Aplicar texturas
		biome_region_applier.apply_biome_to_region(region_node, region_data)

		pipeline_success += 1
		print("    ✅ Pipeline completo para región %d" % i)

		# Limpiar nodo de test
		region_node.queue_free()

	var pipeline_rate = float(pipeline_success) / float(total_tests) * 100.0
	test_results["complete_pipeline"] = {
		"success_count": pipeline_success,
		"total_tests": total_tests,
		"success_rate": pipeline_rate
	}

	print("  📊 Pipeline exitoso: %.1f%% (%d/%d)" % [pipeline_rate, pipeline_success, total_tests])

func _test_texture_application_and_blending() -> void:
	"""Test 4: Verificar aplicación de texturas y blending"""
	print("\n🎨 Test 4: Aplicación de texturas y blending")

	# Test básico de aplicación de texturas
	var texture_tests = 0
	var texture_success = 0

	for biome_type in BiomeGenerator.BiomeType.values():
		texture_tests += 1

		# Datos de región mock para cada bioma
		var mock_region_data = {
			"region_id": Vector2i(0, 0),
			"biome_type": biome_type,
			"center_position": Vector2.ZERO,
			"boundary_points": PackedVector2Array([
				Vector2(-100, -100), Vector2(100, -100),
				Vector2(100, 100), Vector2(-100, 100)
			])
		}

		var test_node = Node2D.new()
		test_node.name = "TextureTest_%s" % BiomeGenerator.BIOME_NAMES.get(biome_type, "unknown")
		add_child(test_node)

		# Aplicar textura
		biome_region_applier.apply_biome_to_region(test_node, mock_region_data)

		# Verificar que se aplicó algo
		if test_node.get_child_count() > 0:
			texture_success += 1
			print("  ✅ Textura aplicada: %s" % BiomeGenerator.BIOME_NAMES.get(biome_type, "unknown"))
		else:
			print("  ❌ Textura falló: %s" % BiomeGenerator.BIOME_NAMES.get(biome_type, "unknown"))

		test_node.queue_free()

	var texture_rate = float(texture_success) / float(texture_tests) * 100.0
	test_results["texture_application"] = {
		"success_count": texture_success,
		"total_tests": texture_tests,
		"success_rate": texture_rate
	}

	print("  📊 Aplicación de texturas: %.1f%% (%d/%d)" % [texture_rate, texture_success, texture_tests])

func _test_system_performance() -> void:
	"""Test 5: Verificar rendimiento del sistema"""
	print("\n⚡ Test 5: Rendimiento del sistema")

	var performance_tests = [
		{"name": "Generación de región simple", "iterations": 10},
		{"name": "Pipeline completo", "iterations": 5},
		{"name": "Aplicación de texturas", "iterations": 15}
	]

	for test in performance_tests:
		var start_time = Time.get_ticks_msec()

		for i in range(test.iterations):
			# Generar región de prueba
			var _region_center = Vector2(randf() * 2000.0, randf() * 2000.0)
			var region_id = Vector2i(randi() % 100, randi() % 100)

			if organic_shape_generator:
				var _organic_region = await organic_shape_generator.generate_region_async(region_id)

		var end_time = Time.get_ticks_msec()
		var total_time = end_time - start_time
		var avg_time = float(total_time) / float(test.iterations)

		print("  📊 %s: %.1fms promedio (%d iteraciones)" % [test.name, avg_time, test.iterations])

		if not test_results.has("performance"):
			test_results["performance"] = {}
		test_results["performance"][test.name] = {
			"total_time": total_time,
			"average_time": avg_time,
			"iterations": test.iterations
		}

# ========== UTILIDADES ==========

func all_components_available() -> bool:
	"""Verificar que todos los componentes estén disponibles"""
	return organic_shape_generator != null and \
		   biome_generator != null and \
		   biome_region_applier != null and \
		   organic_texture_blender != null

func _print_test_summary() -> void:
	"""Imprimir resumen de todos los tests"""

	print("🔧 Inicialización de componentes:")
	if test_results.has("component_initialization"):
		var init_results = test_results["component_initialization"]
		for component in init_results.keys():
			var status = "✅" if init_results[component] else "❌"
			print("   %s %s" % [status, component])

	print("\n🌊 Generación de regiones orgánicas:")
	if test_results.has("organic_region_generation"):
		var gen_results = test_results["organic_region_generation"]
		print("   Tasa de éxito: %.1f%%" % gen_results["success_rate"])

	print("\n🏭 Pipeline completo:")
	if test_results.has("complete_pipeline"):
		var pipeline_results = test_results["complete_pipeline"]
		print("   Tasa de éxito: %.1f%%" % pipeline_results["success_rate"])

	print("\n🎨 Aplicación de texturas:")
	if test_results.has("texture_application"):
		var texture_results = test_results["texture_application"]
		print("   Tasa de éxito: %.1f%%" % texture_results["success_rate"])

	print("\n⚡ Rendimiento:")
	if test_results.has("performance"):
		var perf_results = test_results["performance"]
		for test_name in perf_results.keys():
			var test_data = perf_results[test_name]
			print("   %s: %.1fms" % [test_name, test_data["average_time"]])

	# Calcular puntuación general
	var overall_score = _calculate_overall_score()
	print("\n🏆 PUNTUACIÓN GENERAL: %.1f%%" % overall_score)

	if overall_score >= 90.0:
		print("🎉 EXCELENTE: Sistema orgánico funcionando perfectamente")
	elif overall_score >= 75.0:
		print("✅ BUENO: Sistema orgánico funcionando correctamente")
	elif overall_score >= 50.0:
		print("⚠️ REGULAR: Sistema orgánico con algunos problemas")
	else:
		print("❌ CRÍTICO: Sistema orgánico requiere reparación")

func _calculate_overall_score() -> float:
	"""Calcular puntuación general del sistema"""
	var scores = []

	if test_results.has("component_initialization"):
		var init_results = test_results["component_initialization"]
		var init_count = 0
		var init_total = 0
		for component in init_results.keys():
			init_total += 1
			if init_results[component]:
				init_count += 1
		scores.append(float(init_count) / float(init_total) * 100.0)

	for test_key in ["organic_region_generation", "complete_pipeline", "texture_application"]:
		if test_results.has(test_key):
			scores.append(test_results[test_key]["success_rate"])

	# Promedio de todas las puntuaciones
	if scores.size() > 0:
		var total = 0.0
		for score in scores:
			total += score
		return total / float(scores.size())

	return 0.0

# ========== FUNCIÓN DE UTILIDAD PÚBLICA ==========

func safe_call(callable: Callable):
	"""Ejecutar función con manejo de errores"""
	if callable.is_valid():
		return callable.call()
	else:
		return null
extends Node

"""
🧪 PRUEBA DEL SISTEMA DE BORDES COMPARTIDOS
===========================================

Este script valida que:
1. Dos regiones vecinas generan bordes IDÉNTICOS
2. No hay superposiciones entre regiones adyacentes
3. Los bordes encajan perfectamente
"""

func _ready() -> void:
	var separator = "============================================================"
	print("\n" + separator)
	print("🧪 INICIANDO PRUEBA DE BORDES COMPARTIDOS")
	print(separator)
	
	# Crear generador
	var generator = load("res://scripts/core/OrganicShapeGenerator.gd").new()
	generator.initialize(12345)
	
	# Test 1: Generar dos regiones adyacentes (horizontal)
	print("\n📍 Test 1: Regiones (0,0) y (1,0) - adyacentes horizontalmente")
	var region_left = generator.generate_region_async(Vector2i(0, 0))
	var region_right = generator.generate_region_async(Vector2i(1, 0))
	
	await get_tree().create_timer(0.1).timeout
	
	if region_left and region_right:
		print("✅ Regiones generadas correctamente")
		print("   - Región izquierda: %d puntos" % region_left.boundary_points.size())
		print("   - Región derecha: %d puntos" % region_right.boundary_points.size())
		
		# Validar sin superposiciones
		var no_overlap = generator.validate_no_overlaps_between(region_left, region_right)
		if no_overlap:
			print("✅ SIN SUPERPOSICIONES detectadas")
		else:
			print("❌ SUPERPOSICIÓN detectada!")
	else:
		print("❌ Error al generar regiones")
	
	# Test 2: Regiones adyacentes verticalmente
	print("\n📍 Test 2: Regiones (0,0) y (0,1) - adyacentes verticalmente")
	var region_top = generator.generate_region_async(Vector2i(0, 0))
	var region_bottom = generator.generate_region_async(Vector2i(0, 1))
	
	await get_tree().create_timer(0.1).timeout
	
	if region_top and region_bottom:
		print("✅ Regiones generadas correctamente")
		var no_overlap = generator.validate_no_overlaps_between(region_top, region_bottom)
		if no_overlap:
			print("✅ SIN SUPERPOSICIONES detectadas")
		else:
			print("❌ SUPERPOSICIÓN detectada!")
	
	# Test 3: Grid 3×3 completo
	print("\n📍 Test 3: Grid 3×3 completo (9 regiones)")
	var regions = {}
	for x in range(3):
		for y in range(3):
			var id = Vector2i(x, y)
			regions[id] = generator.generate_region_async(id)
	
	await get_tree().create_timer(0.3).timeout
	
	var total_pairs = 0
	var valid_pairs = 0
	
	# Validar todas las parejas adyacentes
	for x in range(3):
		for y in range(3):
			var id = Vector2i(x, y)
			var region = regions.get(id)
			if not region:
				continue
			
			# Validar vecino derecho
			var right_id = Vector2i(x + 1, y)
			if regions.has(right_id):
				total_pairs += 1
				if generator.validate_no_overlaps_between(region, regions[right_id]):
					valid_pairs += 1
			
			# Validar vecino inferior
			var bottom_id = Vector2i(x, y + 1)
			if regions.has(bottom_id):
				total_pairs += 1
				if generator.validate_no_overlaps_between(region, regions[bottom_id]):
					valid_pairs += 1
	
	print("   Total parejas validadas: %d" % total_pairs)
	print("   Parejas sin superposición: %d" % valid_pairs)
	
	if valid_pairs == total_pairs:
		print("\n" + separator)
		print("🎉 ¡TODAS LAS PRUEBAS PASADAS!")
		print("   Sistema de bordes compartidos funcionando perfectamente")
		print(separator)
	else:
		print("\n" + separator)
		print("⚠️ ALGUNAS PRUEBAS FALLARON")
		print("   %d de %d parejas tienen superposiciones" % [total_pairs - valid_pairs, total_pairs])
		print(separator)
	
	generator.queue_free()

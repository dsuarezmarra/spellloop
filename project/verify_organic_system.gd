# verify_organic_system.gd
# Script de verificación rápida del sistema orgánico

extends Node

func _ready():
	var separator = "=".repeat(60)
	print(separator)
	print("🔍 VERIFICACIÓN RÁPIDA DEL SISTEMA ORGÁNICO")
	print(separator)
	
	var results = verify_system()
	
	print("\n📊 RESULTADOS:")
	for key in results.keys():
		var status = "✅" if results[key] else "❌"
		print("  %s %s" % [status, key])
	
	var success_count = 0
	for value in results.values():
		if value:
			success_count += 1
	
	var success_rate = float(success_count) / float(results.size()) * 100.0
	print("\n🏆 TASA DE ÉXITO: %.0f%% (%d/%d)" % [success_rate, success_count, results.size()])
	
	if success_rate >= 80:
		print("🎉 SISTEMA ORGÁNICO FUNCIONAL")
	else:
		print("⚠️ SISTEMA ORGÁNICO NECESITA ATENCIÓN")
	
	print(separator)

func verify_system() -> Dictionary:
	var results = {}
	
	# Verificar archivos
	results["OrganicShapeGenerator.gd existe"] = ResourceLoader.exists("res://scripts/core/OrganicShapeGenerator.gd")
	results["BiomeGenerator.gd existe"] = ResourceLoader.exists("res://scripts/core/BiomeGenerator.gd")
	results["BiomeRegionApplier.gd existe"] = ResourceLoader.exists("res://scripts/core/BiomeRegionApplier.gd")
	results["OrganicTextureBlender.gd existe"] = ResourceLoader.exists("res://scripts/core/OrganicTextureBlender.gd")
	results["InfiniteWorldManager.gd existe"] = ResourceLoader.exists("res://scripts/core/InfiniteWorldManager.gd")
	
	# Verificar carga de scripts
	if results["OrganicShapeGenerator.gd existe"]:
		var script = load("res://scripts/core/OrganicShapeGenerator.gd")
		results["OrganicShapeGenerator se carga"] = script != null
		
		if script:
			var instance = script.new()
			results["OrganicShapeGenerator se instancia"] = instance != null
			if instance:
				results["OrganicShapeGenerator tiene initialize()"] = instance.has_method("initialize")
	
	if results["BiomeGenerator.gd existe"]:
		var script = load("res://scripts/core/BiomeGenerator.gd")
		results["BiomeGenerator se carga"] = script != null
		
		if script:
			var instance = script.new()
			results["BiomeGenerator se instancia"] = instance != null
			if instance:
				results["BiomeGenerator tiene generate_region_async()"] = instance.has_method("generate_region_async")
	
	if results["InfiniteWorldManager.gd existe"]:
		var script = load("res://scripts/core/InfiniteWorldManager.gd")
		results["InfiniteWorldManager se carga"] = script != null
		
		if script:
			var instance = script.new()
			results["InfiniteWorldManager se instancia"] = instance != null
			if instance:
				results["InfiniteWorldManager tiene active_regions"] = "active_regions" in instance
				results["InfiniteWorldManager tiene set_regions_root()"] = instance.has_method("set_regions_root")
	
	return results
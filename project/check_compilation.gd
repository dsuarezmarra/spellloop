# check_compilation.gd
# Script para verificar que todos los archivos del sistema orgánico compilen correctamente

extends SceneTree

func _init():
	print("🔍 VERIFICANDO COMPILACIÓN DE ARCHIVOS DEL SISTEMA ORGÁNICO")
	print("="*60)
	
	var files_to_check = [
		"res://scripts/core/OrganicShapeGenerator.gd",
		"res://scripts/core/BiomeGenerator.gd", 
		"res://scripts/core/BiomeRegionApplier.gd",
		"res://scripts/core/OrganicTextureBlender.gd",
		"res://scripts/core/InfiniteWorldManager.gd"
	]
	
	var compilation_errors = 0
	
	for file_path in files_to_check:
		print("\n📄 Verificando: %s" % file_path)
		
		if not ResourceLoader.exists(file_path):
			print("  ❌ Archivo no encontrado")
			compilation_errors += 1
			continue
		
		var script = load(file_path)
		if script == null:
			print("  ❌ Error cargando script")
			compilation_errors += 1
			continue
		
		# Intentar instanciar la clase
		var instance = null
		var error_occurred = false
		
		# Usar call_deferred para capturar errores
		if script.can_instantiate():
			instance = script.new()
			if instance:
				print("  ✅ Compilación exitosa - Instancia creada")
				
				# Verificar métodos importantes según el tipo
				check_important_methods(instance, file_path)
				
				# Limpiar instancia
				if instance and is_instance_valid(instance):
					if instance.has_method("queue_free"):
						instance.queue_free()
			else:
				print("  ❌ Error instanciando clase")
				compilation_errors += 1
		else:
			print("  ❌ Script no se puede instanciar")
			compilation_errors += 1
	
	print("\n" + "="*60)
	if compilation_errors == 0:
		print("🎉 TODOS LOS ARCHIVOS COMPILARON CORRECTAMENTE")
	else:
		print("⚠️ SE ENCONTRARON %d ERRORES DE COMPILACIÓN" % compilation_errors)
	print("="*60)
	
	quit(0)

func check_important_methods(instance, file_path: String):
	"""Verificar que los métodos importantes estén presentes"""
	
	if "OrganicShapeGenerator" in file_path:
		check_methods(instance, ["initialize", "generate_region_async"], "OrganicShapeGenerator")
	
	elif "BiomeGenerator" in file_path:
		check_methods(instance, ["generate_region_async", "get_biome_color"], "BiomeGenerator")
	
	elif "BiomeRegionApplier" in file_path:
		check_methods(instance, ["apply_biome_to_region", "apply_blended_region"], "BiomeRegionApplier")
	
	elif "OrganicTextureBlender" in file_path:
		check_methods(instance, ["blend_region_with_neighbors"], "OrganicTextureBlender")
	
	elif "InfiniteWorldManager" in file_path:
		check_methods(instance, ["initialize", "move_world", "set_regions_root"], "InfiniteWorldManager")

func check_methods(instance, methods: Array, class_name: String):
	"""Verificar que los métodos existan en la instancia"""
	var methods_found = 0
	
	for method_name in methods:
		if instance.has_method(method_name):
			methods_found += 1
		else:
			print("    ⚠️ Método faltante: %s" % method_name)
	
	if methods_found == methods.size():
		print("    ✅ Todos los métodos encontrados (%d/%d)" % [methods_found, methods.size()])
	else:
		print("    ❌ Métodos faltantes en %s (%d/%d)" % [class_name, methods_found, methods.size()])
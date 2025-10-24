extends Node

func _ready():
	print("=== VERIFICACIÓN DE INFINITE WORLD MANAGER ===")
	
	# Verificar carga de InfiniteWorldManager
	var manager_script = preload("res://scripts/core/InfiniteWorldManager.gd")
	if manager_script:
		print("✅ InfiniteWorldManager.gd cargado exitosamente")
		
		var manager = manager_script.new()
		if manager:
			print("✅ InfiniteWorldManager instanciado exitosamente")
			
			# Verificar métodos principales
			if manager.has_method("_region_id_to_world_pos"):
				print("✅ Método _region_id_to_world_pos disponible")
			
			if manager.has_method("_instantiate_chunk_from_cache"):
				print("✅ Método _instantiate_chunk_from_cache disponible")
				
		else:
			print("❌ Error al instanciar InfiniteWorldManager")
	else:
		print("❌ Error al cargar InfiniteWorldManager.gd")
	
	print("🎉 VERIFICACIÓN COMPLETADA")
	get_tree().quit()
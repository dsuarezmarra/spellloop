# TestSpriteRobust.gd - Prueba robusta de carga de sprites con múltiples métodos
extends Node2D

func _ready():
	print("🛠️ PRUEBA ROBUSTA DE SPRITES")
	print("===========================")
	
	# Crear título
	var title = Label.new()
	title.text = "DIAGNÓSTICO ROBUSTO - MÚLTIPLES MÉTODOS DE CARGA"
	title.position = Vector2(50, 10)
	title.add_theme_font_size_override("font_size", 20)
	add_child(title)
	
	# Probar diferentes métodos de carga
	test_preload_method()
	test_load_method()
	test_resource_loader_method()
	test_file_system_method()

func test_preload_method():
	print("\n🔍 MÉTODO 1: PRELOAD (compilación)")
	var y_pos = 60
	
	# Intentar preload (esto falla si los archivos no están importados correctamente)
	# Nota: preload() no funciona en tiempo de ejecución con rutas dinámicas
	print("  ⚠️ Preload requiere rutas estáticas - saltando")
	
	add_status_label("MÉTODO 1: PRELOAD - Requiere compilación", y_pos)

func test_load_method():
	print("\n🔍 MÉTODO 2: LOAD (tiempo de ejecución)")
	var y_pos = 100
	
	var paths = [
		"res://sprites/wizard/wizard_down.png",
		"res://sprites/wizard/wizard_up.png",
		"res://sprites/wizard/wizard_left.png",
		"res://sprites/wizard/wizard_right.png"
	]
	
	var success_count = 0
	
	for i in range(paths.size()):
		var path = paths[i]
		print("  🔄 Probando load(): ", path)
		
		var texture = load(path) as Texture2D
		if texture:
			print("    ✅ ÉXITO: ", texture.get_width(), "x", texture.get_height())
			
			# Crear sprite visual
			var sprite = Sprite2D.new()
			sprite.texture = texture
			sprite.position = Vector2(100 + (i * 120), y_pos + 50)
			sprite.scale = Vector2(1.5, 1.5)
			add_child(sprite)
			
			success_count += 1
		else:
			print("    ❌ FALLÓ")
	
	add_status_label("MÉTODO 2: LOAD - " + str(success_count) + "/4 sprites cargados", y_pos)

func test_resource_loader_method():
	print("\n🔍 MÉTODO 3: RESOURCELOADER")
	var y_pos = 200
	
	var paths = [
		"res://sprites/wizard/wizard_down.png",
		"res://sprites/wizard/wizard_up.png",
		"res://sprites/wizard/wizard_left.png", 
		"res://sprites/wizard/wizard_right.png"
	]
	
	var success_count = 0
	
	for i in range(paths.size()):
		var path = paths[i]
		print("  🔄 Probando ResourceLoader.load(): ", path)
		
		if ResourceLoader.exists(path):
			print("    ✓ Archivo existe")
			var resource = ResourceLoader.load(path)
			if resource:
				print("    ✅ ÉXITO: Recurso cargado")
				var texture = resource as Texture2D
				if texture:
					print("    ✅ Convertido a Texture2D: ", texture.get_width(), "x", texture.get_height())
					
					# Crear sprite visual
					var sprite = Sprite2D.new()
					sprite.texture = texture
					sprite.position = Vector2(100 + (i * 120), y_pos + 50)
					sprite.scale = Vector2(1.5, 1.5)
					add_child(sprite)
					
					success_count += 1
				else:
					print("    ❌ No es una Texture2D válida")
			else:
				print("    ❌ ResourceLoader.load() falló")
		else:
			print("    ❌ Archivo no existe en ResourceLoader")
	
	add_status_label("MÉTODO 3: RESOURCELOADER - " + str(success_count) + "/4 sprites cargados", y_pos)

func test_file_system_method():
	print("\n🔍 MÉTODO 4: FILESYSTEM DIRECTO")
	var y_pos = 300
	
	var file_paths = [
		"user://sprites/wizard/wizard_down.png",
		"res://sprites/wizard/wizard_down.png"
	]
	
	for path in file_paths:
		print("  🔄 Verificando existencia: ", path)
		if FileAccess.file_exists(path):
			print("    ✅ Archivo existe en filesystem")
		else:
			print("    ❌ Archivo no existe en filesystem")
	
	add_status_label("MÉTODO 4: FILESYSTEM - Verificación de archivos", y_pos)

func add_status_label(text: String, y_pos: int):
	var label = Label.new()
	label.text = text
	label.position = Vector2(50, y_pos)
	add_child(label)
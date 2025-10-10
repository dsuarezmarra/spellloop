# TestSpriteLoadingDirect.gd - Test directo de carga sin dependencias
extends Node

func _ready():
	print("🧪 TEST DIRECTO DE CARGA DE SPRITES PNG")
	print("=====================================")
	
	test_sprite_loading_comprehensive()

func test_sprite_loading_comprehensive():
	var sprite_files = [
		"res://sprites/wizard/wizard_down.png",
		"res://sprites/wizard/wizard_up.png",
		"res://sprites/wizard/wizard_left.png",
		"res://sprites/wizard/wizard_right.png"
	]
	
	print("📊 ESTADO DE ARCHIVOS:")
	for path in sprite_files:
		test_single_sprite(path)
	
	print("\n🔄 NOTA: Refresh manual disponible con tecla R")
	print("🔁 SEGUNDO INTENTO INMEDIATO:")
	for path in sprite_files:
		test_single_sprite_post_refresh(path)

func test_single_sprite(path: String):
	print("\n🔍 Probando: ", path)
	
	# Test 1: Verificar existencia
	if FileAccess.file_exists(path):
		print("  ✅ FileAccess.file_exists() = true")
	else:
		print("  ❌ FileAccess.file_exists() = false")
		return
	
	# Test 2: ResourceLoader.exists
	if ResourceLoader.exists(path):
		print("  ✅ ResourceLoader.exists() = true")
	else:
		print("  ❌ ResourceLoader.exists() = false")
		return
	
	# Test 3: load() directo
	var texture = load(path) as Texture2D
	if texture:
		print("  ✅ load() exitoso - Tamaño: ", texture.get_width(), "x", texture.get_height())
	else:
		print("  ❌ load() falló")
	
	# Test 4: ResourceLoader.load()
	var resource = ResourceLoader.load(path)
	if resource:
		print("  ✅ ResourceLoader.load() exitoso - Tipo: ", resource.get_class())
	else:
		print("  ❌ ResourceLoader.load() falló")
	
	# Test 5: Verificar archivo .import
	var import_path = path + ".import"
	if FileAccess.file_exists(import_path):
		print("  ✅ Archivo .import existe")
		check_import_validity(import_path)
	else:
		print("  ❌ Archivo .import no existe")

func test_single_sprite_post_refresh(path: String):
	print("\n🔁 Post-refresh: ", path.get_file())
	var texture = load(path) as Texture2D
	if texture:
		print("  ✅ ÉXITO POST-REFRESH: ", texture.get_width(), "x", texture.get_height())
	else:
		print("  ❌ Aún falla post-refresh")

func check_import_validity(import_path: String):
	var file = FileAccess.open(import_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		if "valid=true" in content:
			print("    ✅ .import válido")
		elif "valid=false" in content:
			print("    ❌ .import inválido")
		else:
			print("    ⚠️ .import sin campo valid")
	else:
		print("    ❌ No se pudo leer .import")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			print("\n🔄 EJECUTANDO REFRESH MANUAL...")
			print("💡 En Godot: Ve a Project → Reload Current Project")
			print("⚠️  O FileSystem dock → Click derecho → Refresh")
		elif event.keycode == KEY_T:
			print("\n🧪 EJECUTANDO TEST NUEVAMENTE...")
			test_sprite_loading_comprehensive()
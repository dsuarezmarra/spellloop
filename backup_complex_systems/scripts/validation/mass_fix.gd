# Script de corrección masiva de errores
# Para usar desde línea de comandos o Godot

extends SceneTree

func _init():
	print("🔧 CORRECCIÓN MASIVA DE ERRORES DE SPELLLOOP")
	print("============================================")
	
	fix_string_multiplication_errors()
	fix_missing_constants()
	fix_class_conflicts()
	
	print("✅ Correcciones aplicadas exitosamente")
	quit(0)

func fix_string_multiplication_errors():
	print("📝 Corrigiendo errores de multiplicación de strings...")
	
	# Función helper para reemplazar multiplicación de strings
	var files_to_fix = [
		"scripts/systems/MasterController.gd",
		"scripts/systems/IntegrationValidator.gd", 
		"scripts/systems/GameTestSuite.gd",
		"scripts/systems/TestManager.gd",
		"scripts/validation/error_check.gd",
		"scripts/validation/final_validation.gd"
	]
	
	for file_path in files_to_fix:
		_fix_string_operators_in_file(file_path)

func _fix_string_operators_in_file(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("  ⚠️ No se pudo abrir:", file_path)
		return
	
	var content = file.get_as_text()
	file.close()
	
	# Reemplazar patrones comunes
	content = content.replace('"="*80', '"================================================================================"')
	content = content.replace('"="*70', '"======================================================================"')
	content = content.replace('"="*60', '"============================================================"')
	content = content.replace('"="*50', '"=================================================="')
	content = content.replace('"-"*40', '"----------------------------------------"')
	content = content.replace('"=" * 80', '"================================================================================"')
	content = content.replace('"=" * 70', '"======================================================================"')
	content = content.replace('"=" * 60', '"============================================================"')
	content = content.replace('"=" * 50', '"=================================================="')
	content = content.replace('"-" * 40', '"----------------------------------------"')
	
	var write_file = FileAccess.open(file_path, FileAccess.WRITE)
	if write_file:
		write_file.store_string(content)
		write_file.close()
		print("  ✅ Corregido:", file_path)

func fix_missing_constants():
	print("📝 Corrigiendo constantes faltantes...")
	
	# Corregir Color.NAVY (no existe en Godot 4)
	_fix_color_navy()

func _fix_color_navy():
	var file_path = "scripts/systems/TextureGenerator.gd"
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return
	
	var content = file.get_as_text()
	file.close()
	
	# Reemplazar Color.NAVY con Color(0, 0, 0.5)
	content = content.replace("Color.NAVY", "Color(0, 0, 0.5)")
	
	var write_file = FileAccess.open(file_path, FileAccess.WRITE)
	if write_file:
		write_file.store_string(content)
		write_file.close()
		print("  ✅ Color.NAVY corregido")

func fix_class_conflicts():
	print("📝 Corrigiendo conflictos de clases...")
	
	# Los autoloads no pueden tener el mismo nombre que la clase
	# Esto se maneja desde project.godot, no desde aquí
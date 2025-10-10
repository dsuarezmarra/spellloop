# ReimportSprites.gd - Fuerza la re-importación de sprites
extends EditorScript

func _run():
	print("🔄 FORZANDO RE-IMPORTACIÓN DE SPRITES")
	print("====================================")
	
	var sprite_paths = [
		"res://sprites/wizard/wizard_down.png",
		"res://sprites/wizard/wizard_up.png", 
		"res://sprites/wizard/wizard_left.png",
		"res://sprites/wizard/wizard_right.png"
	]
	
	# Obtener el EditorInterface
	var editor_interface = EditorInterface
	var resource_filesystem = editor_interface.get_resource_filesystem()
	
	print("📁 Re-importando archivos...")
	
	for path in sprite_paths:
		print("  🔄 Re-importando: ", path)
		resource_filesystem.reimport_files([path])
	
	print("✅ Re-importación solicitada")
	print("💡 Ve a Project -> Reload Current Project para asegurar que se carguen")
	print("📊 Luego ejecuta TestSpriteDirect.tscn de nuevo")
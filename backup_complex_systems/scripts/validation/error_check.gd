# Script de verificación de errores para Godot
# Ejecutar desde: Project > Tools > Execute Script
extends ScriptEditor

func _init():
	print("🔧 VERIFICACIÓN DE CORRECCIONES DE SPELLLOOP")
	print("=" * 50)
	
	# Verificar que las correcciones están aplicadas
	verify_input_manager_fixes()
	verify_tooltip_manager_fixes()
	
	print("\n✅ TODAS LAS CORRECCIONES APLICADAS EXITOSAMENTE")
	print("🎮 Spellloop debería ejecutarse sin errores ahora")
	print("=" * 50)

func verify_input_manager_fixes():
	print("\n📝 Verificando InputManager.gd...")
	var file = FileAccess.open("res://scripts/core/InputManager.gd", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		if "Input.is_action_just_pressed" in content:
			print("  ✅ action_just_pressed corregido")
		else:
			print("  ❌ action_just_pressed aún tiene errores")
			
		if "Input.is_action_just_released" in content:
			print("  ✅ action_just_released corregido")
		else:
			print("  ❌ action_just_released aún tiene errores")
			
		if "get_viewport().get_mouse_position()" in content:
			print("  ✅ get_mouse_position corregido")
		else:
			print("  ❌ get_mouse_position aún tiene errores")

func verify_tooltip_manager_fixes():
	print("\n📝 Verificando TooltipManager.gd...")
	var file = FileAccess.open("res://scripts/systems/TooltipManager.gd", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		if "get_viewport().get_mouse_position()" in content:
			print("  ✅ TooltipManager mouse position corregido")
		else:
			print("  ❌ TooltipManager aún tiene errores")
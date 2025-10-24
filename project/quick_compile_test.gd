extends Node

func _ready():
	print("=== VERIFICACIÓN RÁPIDA DE COMPILACIÓN ===")
	
	# Verificar carga de OrganicTextureBlender
	var blender_script = preload("res://scripts/core/OrganicTextureBlender.gd")
	var blender = blender_script.new()
	print("✅ OrganicTextureBlender cargado y creado")
	
	# Verificar carga de OrganicBlendingIntegration
	var integration_script = preload("res://scripts/core/OrganicBlendingIntegration.gd")  
	var integration = integration_script.new()
	print("✅ OrganicBlendingIntegration cargado y creado")
	
	print("🎉 TODOS LOS SCRIPTS COMPILARON CORRECTAMENTE")
	get_tree().quit()
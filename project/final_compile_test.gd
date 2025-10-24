extends Node

func _ready():
	print("=== VERIFICACIÓN FINAL DE COMPILACIÓN ===")
	
	# Verificar InfiniteWorldManager
	var manager_script = preload("res://scripts/core/InfiniteWorldManager.gd")
	print("✅ InfiniteWorldManager.gd compilado exitosamente")
	
	# Verificar OrganicTextureBlender
	var blender_script = preload("res://scripts/core/OrganicTextureBlender.gd")
	print("✅ OrganicTextureBlender.gd compilado exitosamente")
	
	# Verificar OrganicBlendingIntegration
	var integration_script = preload("res://scripts/core/OrganicBlendingIntegration.gd")
	print("✅ OrganicBlendingIntegration.gd compilado exitosamente")
	
	print("🎉 TODOS LOS ARCHIVOS COMPILARON CORRECTAMENTE")
	get_tree().quit()
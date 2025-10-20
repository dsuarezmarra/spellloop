# OBSOLETE-SCRIPT: este script parece no usarse actualmente. Verificar antes de eliminar.
# Originalmente: test_resource_load.gd - Script de testing de carga de recursos
# Razón: Script de desarrollo (nunca ejecutado en game loop)

extends Node

func _safe_quit(_code: int = 0):
	if get_tree() != null:
		get_tree().quit()

func _init():
	print("TEST_RESOURCE_LOAD start")
	var tex = null
	var path = "res://assets/sprites/chests/chest_closed/chest_closed.png"
	# Try load using ResourceLoader
	tex = ResourceLoader.load(path)
	if tex == null:
		print("FAILED to load:", path)
	else:
		print("Loaded resource type:", typeof(tex), tex)
	# quit safely
	_safe_quit()


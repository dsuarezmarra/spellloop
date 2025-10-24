extends Node

func _ready():
	# Cargar y ejecutar script de prueba
	var test_script = load("res://scripts/tools/test_advanced_blending_final.gd")
	var tester = test_script.new()
	get_tree().root.add_child(tester)
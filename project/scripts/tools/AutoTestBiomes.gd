extends Node
## Auto-testing script que se ejecuta al iniciar la escena
## Verifica la integración de biomas sin intervención manual

func _ready():
	# Crear script de pruebas
	var test_script = load("res://scripts/tools/BiomeIntegrationTest.gd")
	if test_script:
		var tester = test_script.new()
		tester.name = "BiomeIntegrationTester"
		add_child(tester)
	else:
		print("❌ No se pudo cargar BiomeIntegrationTest.gd")

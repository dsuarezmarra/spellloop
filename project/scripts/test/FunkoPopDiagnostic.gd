# Diagnóstico de FunkoPop
# Archivo para probar que las clases FunkoPop funcionan correctamente
extends Node

func _ready():
	print("=== DIAGNÓSTICO FUNKO POP ===")
	
	# Probar que las clases están disponibles globalmente
	if FunkoPopWizard:
		print("✓ FunkoPopWizard disponible globalmente")
		
		# Probar creación de sprite
		var test_sprite = FunkoPopWizard.create_wizard_sprite(FunkoPopWizard.Direction.DOWN, FunkoPopWizard.AnimFrame.IDLE)
		if test_sprite:
			print("✓ Sprite de mago creado correctamente")
		else:
			print("✗ Error creando sprite de mago")
	else:
		print("✗ FunkoPopWizard no disponible")
	
	if FunkoPopEnemy:
		print("✓ FunkoPopEnemy disponible globalmente")
		
		# Probar creación de sprite de enemigo
		var test_enemy_sprite = FunkoPopEnemy.create_enemy_sprite(FunkoPopEnemy.EnemyType.GOBLIN, FunkoPopEnemy.Direction.DOWN, FunkoPopEnemy.AnimFrame.IDLE)
		if test_enemy_sprite:
			print("✓ Sprite de enemigo creado correctamente")
		else:
			print("✗ Error creando sprite de enemigo")
	else:
		print("✗ FunkoPopEnemy no disponible")
	
	print("=== FIN DIAGNÓSTICO ===")
	
	# Cambiar a la escena principal después de 2 segundos
	await get_tree().create_timer(2.0).timeout
	print("Cambiando a escena principal...")
	get_tree().change_scene_to_file("res://scenes/levels/MinimalTestRoom.tscn")
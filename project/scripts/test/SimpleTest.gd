# Test simple de sprites FunkoPop
extends Node2D

func _ready():
	print("=== INICIANDO TEST SIMPLE ===")
	
	# Crear un jugador con sprite Funko Pop
	var player = CharacterBody2D.new()
	player.name = "Player"
	player.position = Vector2(400, 300)
	
	# Agregar sprite al jugador
	var sprite = Sprite2D.new()
	sprite.name = "PlayerSprite"
	
	# Usar FunkoPopWizard global para crear textura
	if FunkoPopWizard:
		print("Creando sprite de mago...")
		var texture = FunkoPopWizard.create_wizard_sprite(FunkoPopWizard.Direction.DOWN, FunkoPopWizard.AnimFrame.IDLE)
		if texture:
			sprite.texture = texture
			print("✓ Sprite del jugador creado exitosamente")
		else:
			print("✗ Error creando textura del jugador")
	
	player.add_child(sprite)
	add_child(player)
	
	# Crear un enemigo
	var enemy = CharacterBody2D.new()
	enemy.name = "Enemy"
	enemy.position = Vector2(600, 300)
	
	# Agregar sprite al enemigo
	var enemy_sprite = Sprite2D.new()
	enemy_sprite.name = "EnemySprite"
	
	# Usar FunkoPopEnemy global para crear textura
	if FunkoPopEnemy:
		print("Creando sprite de enemigo...")
		var enemy_texture = FunkoPopEnemy.create_enemy_sprite(FunkoPopEnemy.EnemyType.GOBLIN, FunkoPopEnemy.Direction.DOWN, FunkoPopEnemy.AnimFrame.IDLE)
		if enemy_texture:
			enemy_sprite.texture = enemy_texture
			print("✓ Sprite del enemigo creado exitosamente")
		else:
			print("✗ Error creando textura del enemigo")
	
	enemy.add_child(enemy_sprite)
	add_child(enemy)
	
	print("=== TEST COMPLETADO ===")
	print("Si ves dos sprites Funko Pop en pantalla, ¡el sistema funciona!")

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC
		get_tree().quit()
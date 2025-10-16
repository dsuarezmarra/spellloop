extends Node

# Script para probar rápidamente el sistema Spellloop
# Ejecutar en Godot para verificar que todos los sistemas funcionan

func _ready():
	print("🧪 INICIANDO PRUEBA SPELLLOOP")
	print("=============================")
	
	# Verificar que los scripts principales existen
	test_script_existence()
	
	# Probar ScaleManager
	test_scale_manager()

func test_script_existence():
	"""Verificar que todos los scripts del sistema existen"""
	print("\n📂 VERIFICANDO SCRIPTS:")
	
	var required_scripts = [
		"res://scripts/core/SpellloopGame.gd",
		"res://scripts/core/InfiniteWorldManager.gd", 
		"res://scripts/entities/SpellloopPlayer.gd",
		"res://scripts/core/WeaponManager.gd",
		"res://scripts/magic/SpellloopMagicProjectile.gd",
		"res://scripts/core/EnemyManager.gd",
		"res://scripts/entities/SpellloopEnemy.gd",
		"res://scripts/core/ExperienceManager.gd",
		"res://scripts/core/ItemManager.gd"
	]
	
	for script_path in required_scripts:
		if ResourceLoader.exists(script_path):
			print("✅ ", script_path, " - OK")
		else:
			print("❌ ", script_path, " - FALTA")

func test_scale_manager():
	"""Probar ScaleManager"""
	print("\n📏 PROBANDO SCALE MANAGER:")
	
	if ScaleManager:
		print("✅ ScaleManager disponible")
		print("📐 Resolución base: ", ScaleManager.BASE_RESOLUTION)
		print("📐 Factor de escala: ", ScaleManager.get_scale_factor())
		print("🚪 Tamaño de puerta escalado: ", ScaleManager.get_scaled_door_size())
		print("🏃‍♂️ Radio de colisión del player: ", ScaleManager.get_scaled_player_collision_radius())
	else:
		print("❌ ScaleManager no disponible")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			print("\n🛑 Prueba terminada")
			get_tree().quit()
		elif event.keycode == KEY_SPACE:
			print("\n🚀 Iniciando juego principal...")
			get_tree().change_scene_to_file("res://scenes/SpellloopMain.tscn")
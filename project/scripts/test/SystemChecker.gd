extends Node

# Script para verificar que todos los sistemas estén correctamente configurados

func _ready():
	print("🔍 Verificando sistemas...")
	
	# Verificar que los scripts principales existan
	verify_file_exists("res://scripts/dungeon/DungeonSystem.gd")
	verify_file_exists("res://scripts/dungeon/RoomScene.gd") 
	verify_file_exists("res://scripts/dungeon/RoomTransitionManager.gd")
	verify_file_exists("res://scripts/entities/Player.gd")
	
	# Verificar que las escenas existan
	verify_file_exists("res://scenes/test/SimpleRoomTest.tscn")
	verify_file_exists("res://scenes/characters/Player.tscn")
	
	# Verificar que los sprites del wizard existan
	verify_file_exists("res://sprites/wizard/wizard_up.png")
	verify_file_exists("res://sprites/wizard/wizard_down.png")
	verify_file_exists("res://sprites/wizard/wizard_left.png")
	verify_file_exists("res://sprites/wizard/wizard_right.png")
	
	print("✅ Verificación completada")

func verify_file_exists(path: String):
	if ResourceLoader.exists(path):
		print("✅ " + path + " - OK")
	else:
		print("❌ " + path + " - NO ENCONTRADO")
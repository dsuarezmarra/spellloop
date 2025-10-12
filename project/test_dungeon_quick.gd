extends Node

# Test rápido para verificar que el sistema de dungeons funciona sin errores de Dictionary

func _ready():
	print("=== TEST RÁPIDO DUNGEON SYSTEM ===")
	test_dungeon_generation()

func test_dungeon_generation():
	"""Test básico de generación de dungeons"""
	
	# Crear una instancia del generador
	var generator = DungeonGenerator.new()
	
	# Generar dungeon
	var dungeon_data = generator.generate_dungeon()
	
	if dungeon_data:
		print("✅ Dungeon generado exitosamente")
		print("📊 Rooms: ", dungeon_data["rooms"].size())
		print("🔗 Connections: ", dungeon_data["connections"].size())
		print("🏁 Start room: ", dungeon_data["start_room_pos"])
		
		# Test de acceso a datos
		for pos in dungeon_data["rooms"]:
			var room = dungeon_data["rooms"][pos]
			print("🏠 Room en ", pos, " - Tipo: ", room.room_type)
			
		print("✅ Test completado sin errores")
	else:
		print("❌ Error generando dungeon")
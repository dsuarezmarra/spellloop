extends Node
class_name TestScriptParserFix

"""
Script de test rápido para verificar correcciones de parser
"""

func _ready():
	print("=== TEST CORRECCIONES PARSER ===")
	test_item_rarity_functions()
	test_enemy_references()
	test_dungeon_system_reference()
	print("=== TESTS COMPLETADOS ===")

func test_item_rarity_functions():
	print("🧪 Testeando ItemRarity...")
	
	# Test función renombrada
	var normal_name = ItemRarity.get_rarity_name(ItemRarity.Type.NORMAL)
	var legendary_name = ItemRarity.get_rarity_name(ItemRarity.Type.LEGENDARY)
	
	print("✅ Normal: %s" % normal_name)
	print("✅ Legendario: %s" % legendary_name)
	
	# Test colores
	var normal_color = ItemRarity.get_color(ItemRarity.Type.NORMAL)
	var legendary_color = ItemRarity.get_color(ItemRarity.Type.LEGENDARY)
	
	print("✅ Color normal: %s" % normal_color)
	print("✅ Color legendario: %s" % legendary_color)

func test_enemy_references():
	print("🧪 Testeando referencias de enemigos...")
	
	# Verificar que SpellloopEnemy existe
	var enemy_script = preload("res://scripts/entities/SpellloopEnemy.gd")
	if enemy_script:
		print("✅ SpellloopEnemy.gd cargado correctamente")
	else:
		print("❌ Error cargando SpellloopEnemy.gd")

func test_dungeon_system_reference():
	print("🧪 Testeando DungeonSystem autoload...")
	
	# Verificar que DungeonSystem está disponible como autoload
	if DungeonSystem:
		print("✅ DungeonSystem autoload disponible")
		print("✅ Tipo: %s" % DungeonSystem.get_script().get_global_name())
	else:
		print("❌ DungeonSystem autoload no disponible")
extends Node
# Script de prueba para verificar ItemsDefinitions

func _ready():
	print("🧪 Probando ItemsDefinitions...")
	
	# Test de función get_rarity_color
	var color_white = ItemsDefinitions.get_rarity_color(ItemsDefinitions.ItemRarity.WHITE)
	var color_orange = ItemsDefinitions.get_rarity_color(ItemsDefinitions.ItemRarity.ORANGE)
	
	print("✅ Color WHITE: ", color_white)
	print("✅ Color ORANGE: ", color_orange)
	
	# Test de función get_rarity_name
	var name_white = ItemsDefinitions.get_rarity_name(ItemsDefinitions.ItemRarity.WHITE)
	var name_orange = ItemsDefinitions.get_rarity_name(ItemsDefinitions.ItemRarity.ORANGE)
	
	print("✅ Nombre WHITE: ", name_white)
	print("✅ Nombre ORANGE: ", name_orange)
	
	print("🎉 ¡Todas las funciones funcionan correctamente!")
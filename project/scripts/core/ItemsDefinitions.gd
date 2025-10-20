# ItemsDefinitions.gd
# Definiciones de items y rarezas para Spellloop
extends Node

# Enum de rareza
enum ItemRarity {
    WHITE,
    BLUE,
    YELLOW,
    ORANGE,
    PURPLE
}

static func get_rarity_color(rarity: int) -> Color:
    match rarity:
        ItemRarity.WHITE:
            return Color("#E0E0E0")  # Blanco
        ItemRarity.BLUE:
            return Color("#3B82F6")  # Azul
        ItemRarity.YELLOW:
            return Color("#FACC15")  # Amarillo
        ItemRarity.ORANGE:
            return Color("#F97316")  # Naranja
        ItemRarity.PURPLE:
            return Color("#8B5CF6")  # Morada
        _:
            return Color.WHITE

static func get_rarity_name(rarity: int) -> String:
    match rarity:
        ItemRarity.WHITE:
            return "Normal"
        ItemRarity.BLUE:
            return "Raro"
        ItemRarity.YELLOW:
            return "Épico"
        ItemRarity.ORANGE:
            return "Legendario"
        ItemRarity.PURPLE:
            return "Mítico"
        _:
            return "?"


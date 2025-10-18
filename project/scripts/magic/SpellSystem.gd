# SpellSystem.gd
# Sistema de magia y hechizos para Spellloop
extends Node

enum SpellType {
	BASIC,    # Proyectil básico (amarillo actual)
	FIRE,     # Fuego - daño continuo
	ICE,      # Hielo - ralentiza enemigos
	LIGHTNING # Rayo - atraviesa enemigos
}

func _ready():
	print("[SpellSystem] Magic system initialized")
	print("[SpellSystem] Available spells: Basic, Fire, Ice, Lightning")

# Datos de cada hechizo
var spell_data = {
	SpellType.BASIC: {
		"name": "Proyectil Básico",
		"color": Color.YELLOW,
		"damage": 10,
		"speed": 500,
		"mana_cost": 0,
		"cooldown": 0.2,
		"effect": "none"
	},
	SpellType.FIRE: {
		"name": "Bola de Fuego",
		"color": Color.RED,
		"damage": 15,
		"speed": 450,
		"mana_cost": 5,
		"cooldown": 0.3,
		"effect": "burn"
	},
	SpellType.ICE: {
		"name": "Fragmento de Hielo",
		"color": Color.CYAN,
		"damage": 8,
		"speed": 400,
		"mana_cost": 4,
		"cooldown": 0.25,
		"effect": "slow"
	},
	SpellType.LIGHTNING: {
		"name": "Rayo",
		"color": Color(1.0, 1.0, 0.0, 1.0),  # Amarillo brillante
		"damage": 12,
		"speed": 600,
		"mana_cost": 6,
		"cooldown": 0.4,
		"effect": "pierce"
	}
}

# Funciones de utilidad
func get_spell_data(spell_type: SpellType) -> Dictionary:
	return spell_data.get(spell_type, spell_data[SpellType.BASIC])

func get_spell_name(spell_type: SpellType) -> String:
	return get_spell_data(spell_type)["name"]

func get_spell_color(spell_type: SpellType) -> Color:
	return get_spell_data(spell_type)["color"]

func get_spell_damage(spell_type: SpellType) -> int:
	return get_spell_data(spell_type)["damage"]

func get_spell_speed(spell_type: SpellType) -> float:
	return get_spell_data(spell_type)["speed"]

func get_spell_mana_cost(spell_type: SpellType) -> int:
	return get_spell_data(spell_type)["mana_cost"]

func get_spell_cooldown(spell_type: SpellType) -> float:
	return get_spell_data(spell_type)["cooldown"]

func get_spell_effect(spell_type: SpellType) -> String:
	return get_spell_data(spell_type)["effect"]

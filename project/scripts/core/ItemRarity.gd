class_name ItemRarity

"""
⭐ SISTEMA DE RAREZA - SPELLLOOP
==============================

Define los diferentes grados de rareza para objetos y cofres.
"""

enum Type {
	NORMAL,     # Gris
	COMMON,     # Azul
	RARE,       # Amarillo
	LEGENDARY   # Morado
}

# Colores para cada rareza
static var colors = {
	Type.NORMAL: Color(0.7, 0.7, 0.7, 1.0),      # Gris
	Type.COMMON: Color(0.3, 0.5, 1.0, 1.0),      # Azul
	Type.RARE: Color(1.0, 0.8, 0.2, 1.0),        # Amarillo
	Type.LEGENDARY: Color(0.8, 0.2, 0.8, 1.0)    # Morado
}

# Nombres para display
static var names = {
	Type.NORMAL: "Normal",
	Type.COMMON: "Común",
	Type.RARE: "Raro", 
	Type.LEGENDARY: "Legendario"
}

# Probabilidades de drop (para generación aleatoria)
static var drop_weights = {
	Type.NORMAL: 70,      # 70%
	Type.COMMON: 20,      # 20%
	Type.RARE: 8,         # 8%
	Type.LEGENDARY: 2     # 2%
}

static func get_color(rarity: Type) -> Color:
	"""Obtener color para una rareza"""
	return colors.get(rarity, colors[Type.NORMAL])

static func get_rarity_name(rarity: Type) -> String:
	"""Obtener nombre para una rareza"""
	return names.get(rarity, names[Type.NORMAL])

static func get_random_rarity() -> Type:
	"""Generar rareza aleatoria basada en probabilidades"""
	var total_weight = 0
	for weight in drop_weights.values():
		total_weight += weight
	
	var random_value = randi() % total_weight
	var current_weight = 0
	
	for rarity in drop_weights:
		current_weight += drop_weights[rarity]
		if random_value < current_weight:
			return rarity
	
	return Type.NORMAL
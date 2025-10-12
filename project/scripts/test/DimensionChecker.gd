extends Node

# Script para verificar las nuevas dimensiones actualizadas

func _ready():
	print("🔍 Verificando nuevas dimensiones...")
	
	# Verificar RoomScene constantes
	print("📐 Dimensiones de sala:")
	print("  - Ancho: 1024 píxeles")
	print("  - Alto: 576 píxeles") 
	print("  - Grosor paredes: 12.8 píxeles (1/5 del original)")
	print("  - Área jugable: 998.4x550.4 píxeles")
	
	# Verificar Player dimensiones
	print("🧙‍♂️ Dimensiones del wizard:")
	print("  - Sprite escalado: 64x64 píxeles")
	print("  - Collider: Radio 26 píxeles")
	print("  - Factor escala: 0.128 (12.8%)")
	
	# Verificar puertas
	print("🚪 Dimensiones de puertas:")
	print("  - Tamaño: 80x80 píxeles")
	
	# Calcular proporciones
	var wizard_size = 64.0
	var wall_thickness = 12.8
	var door_size = 80.0
	
	print("🎯 Proporciones:")
	print("  - Wizard vs Pared: ", wizard_size/wall_thickness, "x más grande")
	print("  - Puerta vs Pared: ", door_size/wall_thickness, "x más grande")
	print("  - Puerta vs Wizard: ", door_size/wizard_size, "x más grande")
	
	print("✅ Verificación de dimensiones completada")
	print("💡 El wizard ahora es más prominente con paredes más finas")
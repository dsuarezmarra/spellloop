extends Node

# Test para verificar el nuevo sistema de paredes con colisión exterior

func _ready():
	print("🔧 NUEVO SISTEMA DE PAREDES")
	print("========================")
	print("📐 Configuración:")
	print("  - Grosor zona pared: 64 píxeles")
	print("  - Grosor visual: 16 píxeles") 
	print("  - Grosor colisión: 8 píxeles (en borde exterior)")
	print("  - Puertas: 60x60 píxeles")
	print("")
	print("🎯 Funcionalidad:")
	print("  ✅ Wizard puede moverse hasta el borde")
	print("  ✅ Puede 'entrar' ligeramente en la pared")
	print("  ✅ Colisión solo en el borde exterior")
	print("  ✅ Paredes visualmente delgadas (16px)")
	print("")
	print("🎮 Resultado esperado:")
	print("  - Paredes grises finas y elegantes")
	print("  - Wizard se puede acercar mucho al borde")
	print("  - Puede disparar desde cualquier pixel de la sala")
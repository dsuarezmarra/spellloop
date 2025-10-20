extends Node

## 🎮 ESCENA DE PRUEBA - Sistema de Biomas
##
## Esta escena ejecuta:
## 1. GenerateDecorPlaceholders.gd (crea texturas placeholder)
## 2. BiomeTextureDebug.gd (verifica tamaños de texturas)
## 3. Luego puedes ver biomas en el juego presionando F5
##
## Al terminar, presiona F5 en SpellloopMain.tscn para ver los biomas en acción

func _ready() -> void:
	print("\n" + "="*70)
	print("🎮 ESCENA DE PRUEBA - SISTEMA DE BIOMAS")
	print("="*70 + "\n")
	
	# Paso 1: Generar placeholders si no existen
	print("📍 PASO 1: Generar placeholders de decoraciones...")
	var placeholder_generator = GenerateDecorPlaceholders.new()
	add_child(placeholder_generator)
	await get_tree().process_frame
	
	# Paso 2: Verificar tamaños de texturas
	print("\n📍 PASO 2: Verificar tamaños de texturas...")
	var texture_debug = BiomeTextureDebug.new()
	add_child(texture_debug)
	await get_tree().process_frame
	
	# Paso 3: Mostrar resumen
	print("\n" + "="*70)
	print("✅ SISTEMA DE BIOMAS LISTO")
	print("="*70)
	print("""
🎯 Próximos pasos:

1. Presiona F5 en SpellloopMain.tscn
2. Verás biomas con texturas base + decoraciones placeholder
3. Comprueba que:
   - Base textures llenan correctamente cada cuadrante
   - Decoraciones están distribuidas aleatoriamente
   - Z-index es correcto (biomas debajo)
   - No hay errores en consola

4. Cuando tengas texturas finales decor:
   - Reemplaza los PNG en assets/textures/biomes/*/
   - El código se adapta automáticamente
   - ¡Sin cambios de código necesarios!

📝 Más info: DECOR_IMPLEMENTATION_GUIDE.md
""")
	
	# Auto-quit después de 1 segundo (ya mostró todo)
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()


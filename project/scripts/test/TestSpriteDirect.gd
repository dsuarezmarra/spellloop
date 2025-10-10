# TestSpriteDirect.gd - Prueba directa de carga de sprites
extends Node2D

func _ready():
	print("🎮 PRUEBA DIRECTA DE CARGA DE SPRITES")
	print("====================================")
	
	# Probar carga directa de cada sprite
	var sprite_paths = [
		"res://sprites/wizard/wizard_down.png",
		"res://sprites/wizard/wizard_up.png", 
		"res://sprites/wizard/wizard_left.png",
		"res://sprites/wizard/wizard_right.png"
	]
	
	var y_offset = 50
	
	for i in range(sprite_paths.size()):
		var path = sprite_paths[i]
		print("🔍 Probando: ", path)
		
		# Verificar si existe
		if ResourceLoader.exists(path):
			print("  ✓ Archivo existe en Godot")
			
			# Intentar cargar
			var texture = load(path) as Texture2D
			if texture:
				print("  ✅ ÉXITO: Textura cargada - Tamaño: ", texture.get_width(), "x", texture.get_height())
				
				# Crear sprite visual
				var sprite = Sprite2D.new()
				sprite.texture = texture
				sprite.position = Vector2(100 + (i * 150), y_offset)
				sprite.scale = Vector2(2.0, 2.0)  # Ampliar para ver mejor
				add_child(sprite)
				
				# Añadir etiqueta
				var label = Label.new()
				label.text = path.get_file().get_basename()
				label.position = Vector2(50 + (i * 150), y_offset + 100)
				add_child(label)
				
			else:
				print("  ❌ ERROR: No se pudo cargar la textura")
		else:
			print("  ❌ ERROR: Archivo no existe en Godot")
		print("")
	
	# Mensaje en pantalla
	var title = Label.new()
	title.text = "PRUEBA DIRECTA - TUS SPRITES REALES"
	title.position = Vector2(50, 10)
	title.add_theme_font_size_override("font_size", 24)
	add_child(title)
	
	var instruction = Label.new()
	instruction.text = "Si ves sprites aquí = archivos OK. Si no = problema de importación Godot"
	instruction.position = Vector2(50, 250)
	add_child(instruction)
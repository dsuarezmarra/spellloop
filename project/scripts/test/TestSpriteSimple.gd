# TestSpriteSimple.gd - Test simple sin APIs de editor
extends Node2D

func _ready():
	print("🧪 TEST SIMPLE DE SPRITES PNG")
	print("============================")
	
	test_sprites_simple()

func test_sprites_simple():
	var sprite_paths = [
		"res://sprites/wizard/wizard_down.png",
		"res://sprites/wizard/wizard_up.png",
		"res://sprites/wizard/wizard_left.png",
		"res://sprites/wizard/wizard_right.png"
	]
	
	var loaded_count = 0
	var y_pos = 50
	
	for i in range(sprite_paths.size()):
		var path = sprite_paths[i]
		print("\n🔍 Probando: ", path.get_file())
		
		# Test directo de carga
		var texture = load(path) as Texture2D
		if texture:
			print("  ✅ ÉXITO: ", texture.get_width(), "x", texture.get_height())
			loaded_count += 1
			
			# Crear sprite visual
			var sprite = Sprite2D.new()
			sprite.texture = texture
			sprite.position = Vector2(100 + (i * 150), y_pos + 50)
			sprite.scale = Vector2(3.0, 3.0)  # Grande para ver bien
			add_child(sprite)
			
			# Etiqueta
			var label = Label.new()
			label.text = path.get_file().get_basename() + "\nCARGADO ✅"
			label.position = Vector2(50 + (i * 150), y_pos + 150)
			add_child(label)
		else:
			print("  ❌ FALLÓ")
			
			# Etiqueta de error
			var error_label = Label.new()
			error_label.text = path.get_file().get_basename() + "\nERROR ❌"
			error_label.position = Vector2(50 + (i * 150), y_pos + 150)
			error_label.modulate = Color.RED
			add_child(error_label)
	
	# Resultado final
	print("\n📊 RESULTADO FINAL:")
	print("✅ Sprites cargados: ", loaded_count, "/4")
	
	if loaded_count == 4:
		print("🎉 ¡TODOS LOS SPRITES FUNCIONAN!")
		print("🎮 Ahora puedes ejecutar IsaacSpriteViewer.tscn")
		create_success_message()
	elif loaded_count > 0:
		print("⚠️  Algunos sprites funcionan, otros no")
		print("🔄 Necesitas Project → Reload Current Project")
	else:
		print("❌ Ningún sprite funciona")
		print("🔄 URGENTE: Project → Reload Current Project")
	
	# Agregar título
	var title = Label.new()
	title.text = "TEST SIMPLE DE SPRITES - " + str(loaded_count) + "/4 CARGADOS"
	title.position = Vector2(50, 10)
	title.add_theme_font_size_override("font_size", 24)
	if loaded_count == 4:
		title.modulate = Color.GREEN
	elif loaded_count > 0:
		title.modulate = Color.YELLOW
	else:
		title.modulate = Color.RED
	add_child(title)

func create_success_message():
	var success_msg = Label.new()
	success_msg.text = "🎉 ¡ÉXITO TOTAL! 🎉\nTodos los sprites cargan correctamente\nAhora ejecuta IsaacSpriteViewer.tscn"
	success_msg.position = Vector2(50, 300)
	success_msg.add_theme_font_size_override("font_size", 20)
	success_msg.modulate = Color.GREEN
	add_child(success_msg)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			print("\n🔄 EJECUTANDO TEST NUEVAMENTE...")
			# Limpiar hijos anteriores
			for child in get_children():
				child.queue_free()
			
			# Esperar un frame y volver a ejecutar
			await get_tree().process_frame
			test_sprites_simple()
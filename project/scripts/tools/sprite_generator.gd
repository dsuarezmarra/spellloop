# sprite_generator.gd - Genera archivos PNG desde los datos del usuario
extends Node

func _ready():
	print("=== GENERANDO SPRITES PNG DESDE DATOS DEL USUARIO ===")
	generate_all_sprites()

func generate_all_sprites():
	"""Genera todos los sprites PNG"""
	
	# Crear directorio
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("sprites"):
		dir.make_dir("sprites")
	if not dir.dir_exists("sprites/wizard"):
		dir.make_dir("sprites/wizard")
	
	# Generar cada sprite
	generate_sprite("wizard_down.png", SpriteData.get_wizard_down_data())
	generate_sprite("wizard_left.png", SpriteData.get_wizard_left_data())
	generate_sprite("wizard_up.png", SpriteData.get_wizard_up_data())
	generate_sprite("wizard_right.png", SpriteData.get_wizard_right_data())
	
	print("✅ Todos los sprites han sido generados en sprites/wizard/")
	print("🎮 Ahora puedes ejecutar el juego!")
	
	# Cerrar automáticamente después de generar
	get_tree().quit()

func generate_sprite(filename: String, data: PackedByteArray):
	"""Genera un archivo PNG desde datos"""
	var image = Image.create_from_data(64, 64, false, Image.FORMAT_RGBA8, data)
	var path = "res://sprites/wizard/" + filename
	image.save_png(path)
	print("✓ ", filename, " generado")

# Test function to verify sprite data
func test_sprite_data():
	"""Prueba los datos de sprites"""
	print("Probando datos de sprites...")
	
	var texture = SpriteData.create_texture_from_data(SpriteData.get_wizard_down_data())
	print("✓ Texture creada: ", texture.get_width(), "x", texture.get_height())
	
	# Crear un sprite para mostrar
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.position = Vector2(100, 100)
	add_child(sprite)
	
	print("✓ Sprite de prueba creado")
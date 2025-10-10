# create_wizard_sprites.gd - Script para crear sprites del mago
extends Node

func _ready():
	print("=== CREANDO SPRITES DEL MAGO ===")
	create_all_wizard_sprites()
	print("Sprites del mago creados!")

func create_all_wizard_sprites():
	"""Crea todos los sprites del mago basados en las imágenes proporcionadas"""
	
	# Crear directorio si no existe
	ensure_sprite_directory()
	
	# Crear cada sprite direccional
	create_wizard_down_sprite()
	create_wizard_up_sprite() 
	create_wizard_left_sprite()
	create_wizard_right_sprite()
	
	print("✓ Todos los sprites del mago han sido creados")

func ensure_sprite_directory():
	"""Asegura que existe el directorio de sprites"""
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("sprites"):
		dir.make_dir("sprites")
	if not dir.dir_exists("sprites/wizard"):
		dir.make_dir("sprites/wizard")

func create_wizard_down_sprite():
	"""Crea sprite del mago mirando hacia abajo (frente)"""
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Basado en tu imagen: mago con sombrero azul, barba blanca, túnica azul, bastón
	
	# Cabeza/cara (estilo Isaac - ovalada y grande)
	draw_oval(image, 20, 15, 24, 20, Color(1.0, 0.9, 0.8))  # Piel
	
	# Ojos grandes estilo Funko Pop
	draw_circle(image, 28, 22, 3, Color.BLACK)  # Ojo izquierdo
	draw_circle(image, 36, 22, 3, Color.BLACK)  # Ojo derecho
	
	# Barba blanca
	draw_oval(image, 24, 28, 16, 12, Color.WHITE)
	
	# Sombrero azul con estrellas
	draw_oval(image, 18, 8, 28, 15, Color(0.3, 0.6, 1.0))  # Base del sombrero
	draw_triangle(image, 32, 8, 12, Color(0.3, 0.6, 1.0))   # Punta
	
	# Banda del sombrero
	draw_rectangle(image, 20, 18, 24, 4, Color(0.2, 0.3, 0.8))
	
	# Estrellas pequeñas en el sombrero
	draw_small_star(image, 25, 12, Color.WHITE)
	draw_small_star(image, 35, 10, Color.WHITE)
	draw_small_star(image, 30, 15, Color.WHITE)
	
	# Túnica azul
	draw_oval(image, 22, 38, 20, 20, Color(0.3, 0.6, 1.0))
	
	# Cinturón marrón
	draw_rectangle(image, 25, 45, 14, 4, Color(0.6, 0.4, 0.2))
	
	# Brazos
	draw_oval(image, 15, 40, 8, 12, Color(0.3, 0.6, 1.0))  # Brazo izquierdo
	draw_oval(image, 41, 40, 8, 12, Color(0.3, 0.6, 1.0))  # Brazo derecho
	
	# Bastón en mano derecha
	draw_rectangle(image, 45, 35, 3, 20, Color(0.6, 0.4, 0.2))  # Mango
	draw_circle(image, 46, 32, 4, Color(0.4, 0.8, 1.0))          # Orbe mágico
	
	# Piernas/pies
	draw_oval(image, 26, 55, 6, 8, Color(0.2, 0.2, 0.2))   # Pie izquierdo
	draw_oval(image, 32, 55, 6, 8, Color(0.2, 0.2, 0.2))   # Pie derecho
	
	# Guardar sprite
	save_sprite(image, "res://sprites/wizard/wizard_down.png")

func create_wizard_up_sprite():
	"""Crea sprite del mago mirando hacia arriba (espaldas)"""
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Vista de espaldas - sombrero prominente, menos cara visible
	
	# Sombrero azul grande (vista desde atrás)
	draw_oval(image, 18, 10, 28, 20, Color(0.3, 0.6, 1.0))
	draw_triangle(image, 32, 5, 15, Color(0.3, 0.6, 1.0))  # Punta más pronunciada
	
	# Banda del sombrero
	draw_rectangle(image, 20, 25, 24, 4, Color(0.2, 0.3, 0.8))
	
	# Estrellas en el sombrero (vistas desde atrás)
	draw_small_star(image, 25, 15, Color.WHITE)
	draw_small_star(image, 35, 12, Color.WHITE)
	draw_small_star(image, 40, 18, Color.WHITE)
	
	# Pelo/barba visible por los lados
	draw_small_oval(image, 16, 20, 4, 8, Color.WHITE)  # Pelo lado izquierdo
	draw_small_oval(image, 44, 20, 4, 8, Color.WHITE)  # Pelo lado derecho
	
	# Túnica azul (vista desde atrás)
	draw_oval(image, 22, 35, 20, 22, Color(0.3, 0.6, 1.0))
	
	# Cinturón
	draw_rectangle(image, 25, 42, 14, 4, Color(0.6, 0.4, 0.2))
	
	# Bastón visible por el lado
	draw_rectangle(image, 42, 30, 3, 25, Color(0.6, 0.4, 0.2))
	draw_circle(image, 43, 27, 3, Color(0.4, 0.8, 1.0))
	
	# Pies
	draw_oval(image, 26, 55, 6, 8, Color(0.2, 0.2, 0.2))
	draw_oval(image, 32, 55, 6, 8, Color(0.2, 0.2, 0.2))
	
	save_sprite(image, "res://sprites/wizard/wizard_up.png")

func create_wizard_left_sprite():
	"""Crea sprite del mago mirando hacia la izquierda"""
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Perfil izquierdo
	
	# Cabeza ovalada (perfil)
	draw_oval(image, 25, 15, 20, 18, Color(1.0, 0.9, 0.8))
	
	# Ojo visible (perfil)
	draw_circle(image, 30, 22, 3, Color.BLACK)
	
	# Barba (perfil)
	draw_oval(image, 20, 25, 15, 10, Color.WHITE)
	
	# Sombrero (perfil inclinado)
	draw_oval(image, 22, 8, 25, 18, Color(0.3, 0.6, 1.0))
	draw_triangle(image, 20, 8, 12, Color(0.3, 0.6, 1.0))  # Punta hacia la izquierda
	
	# Banda del sombrero
	draw_rectangle(image, 25, 20, 20, 3, Color(0.2, 0.3, 0.8))
	
	# Estrellas
	draw_small_star(image, 30, 12, Color.WHITE)
	draw_small_star(image, 38, 15, Color.WHITE)
	
	# Túnica (perfil)
	draw_oval(image, 25, 35, 18, 20, Color(0.3, 0.6, 1.0))
	
	# Cinturón
	draw_rectangle(image, 27, 42, 12, 4, Color(0.6, 0.4, 0.2))
	
	# Bastón en mano derecha (visible)
	draw_rectangle(image, 40, 30, 3, 22, Color(0.6, 0.4, 0.2))
	draw_circle(image, 41, 27, 3, Color(0.4, 0.8, 1.0))
	
	# Pies (perfil)
	draw_oval(image, 28, 55, 8, 8, Color(0.2, 0.2, 0.2))
	draw_oval(image, 34, 55, 6, 8, Color(0.2, 0.2, 0.2))
	
	save_sprite(image, "res://sprites/wizard/wizard_left.png")

func create_wizard_right_sprite():
	"""Crea sprite del mago mirando hacia la derecha"""
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Perfil derecho (espejo del izquierdo)
	
	# Cabeza ovalada (perfil derecho)
	draw_oval(image, 19, 15, 20, 18, Color(1.0, 0.9, 0.8))
	
	# Ojo visible
	draw_circle(image, 31, 22, 3, Color.BLACK)
	
	# Barba (perfil derecho)
	draw_oval(image, 29, 25, 15, 10, Color.WHITE)
	
	# Sombrero (perfil inclinado hacia la derecha)
	draw_oval(image, 17, 8, 25, 18, Color(0.3, 0.6, 1.0))
	draw_triangle(image, 42, 8, 12, Color(0.3, 0.6, 1.0))  # Punta hacia la derecha
	
	# Banda del sombrero
	draw_rectangle(image, 19, 20, 20, 3, Color(0.2, 0.3, 0.8))
	
	# Estrellas
	draw_small_star(image, 24, 12, Color.WHITE)
	draw_small_star(image, 32, 15, Color.WHITE)
	
	# Túnica (perfil)
	draw_oval(image, 21, 35, 18, 20, Color(0.3, 0.6, 1.0))
	
	# Cinturón
	draw_rectangle(image, 25, 42, 12, 4, Color(0.6, 0.4, 0.2))
	
	# Bastón en mano izquierda (visible por la izquierda)
	draw_rectangle(image, 18, 30, 3, 22, Color(0.6, 0.4, 0.2))
	draw_circle(image, 19, 27, 3, Color(0.4, 0.8, 1.0))
	
	# Pies (perfil derecho)
	draw_oval(image, 22, 55, 6, 8, Color(0.2, 0.2, 0.2))
	draw_oval(image, 28, 55, 8, 8, Color(0.2, 0.2, 0.2))
	
	save_sprite(image, "res://sprites/wizard/wizard_right.png")

# Funciones de dibujo auxiliares
func draw_oval(image: Image, x: int, y: int, width: int, height: int, color: Color):
	for py in range(height):
		for px in range(width):
			var dx = px - width/2.0
			var dy = py - height/2.0
			if (dx*dx)/(width*width/4.0) + (dy*dy)/(height*height/4.0) <= 1.0:
				var final_x = x + px
				var final_y = y + py
				if final_x >= 0 and final_x < image.get_width() and final_y >= 0 and final_y < image.get_height():
					image.set_pixel(final_x, final_y, color)

func draw_circle(image: Image, x: int, y: int, radius: int, color: Color):
	draw_oval(image, x-radius, y-radius, radius*2, radius*2, color)

func draw_rectangle(image: Image, x: int, y: int, width: int, height: int, color: Color):
	for py in range(height):
		for px in range(width):
			var final_x = x + px
			var final_y = y + py
			if final_x >= 0 and final_x < image.get_width() and final_y >= 0 and final_y < image.get_height():
				image.set_pixel(final_x, final_y, color)

func draw_triangle(image: Image, x: int, y: int, size: int, color: Color):
	for py in range(size):
		var width = size - py
		for px in range(width):
			var final_x = x + px - width/2
			var final_y = y + py
			if final_x >= 0 and final_x < image.get_width() and final_y >= 0 and final_y < image.get_height():
				image.set_pixel(final_x, final_y, color)

func draw_small_star(image: Image, x: int, y: int, color: Color):
	# Estrella simple de 5 píxeles en forma de +
	var offsets = [Vector2(0,0), Vector2(-1,0), Vector2(1,0), Vector2(0,-1), Vector2(0,1)]
	for offset in offsets:
		var final_x = x + offset.x
		var final_y = y + offset.y
		if final_x >= 0 and final_x < image.get_width() and final_y >= 0 and final_y < image.get_height():
			image.set_pixel(final_x, final_y, color)

func draw_small_oval(image: Image, x: int, y: int, width: int, height: int, color: Color):
	draw_oval(image, x, y, width, height, color)

func save_sprite(image: Image, path: String):
	"""Guarda el sprite como archivo PNG"""
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	# Guardar como PNG
	image.save_png(path)
	print("✓ Sprite guardado: ", path)
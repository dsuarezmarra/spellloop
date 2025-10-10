# create_user_sprites.gd - Creador de sprites basado en las imágenes del usuario
extends Node

func _ready():
	print("=== CREANDO SPRITES DEL USUARIO ===")
	create_sprites_from_user_images()
	print("✓ Sprites del usuario creados en project/sprites/wizard/")

func create_sprites_from_user_images():
	"""Crea sprites basados en las imágenes proporcionadas por el usuario"""
	
	# Asegurar directorio
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("sprites"):
		dir.make_dir("sprites")
	if not dir.dir_exists("sprites/wizard"):
		dir.make_dir("sprites/wizard")
	
	# Crear cada sprite basado en las imágenes del usuario
	create_wizard_down_from_user_image()    # Imagen 1: Frente
	create_wizard_left_from_user_image()    # Imagen 2: Perfil izquierda  
	create_wizard_up_from_user_image()      # Imagen 3: Arriba/frente
	create_wizard_right_from_user_image()   # Imagen 4: Espaldas
	
	print("✓ 4 sprites del mago creados desde las imágenes del usuario")

func create_wizard_down_from_user_image():
	"""Sprite basado en imagen 1: Mago mirando hacia abajo (frente) con bastón"""
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Análisis de tu imagen 1: Mago de frente con sombrero azul estrellado, barba blanca, túnica azul, bastón en mano derecha
	
	# === CABEZA OVALADA GRANDE (estilo Isaac) ===
	draw_oval(image, 18, 12, 28, 24, Color(1.0, 0.9, 0.8))  # Piel rosada
	
	# === SOMBRERO AZUL CON ESTRELLAS ===
	# Base del sombrero (parte que cubre la cabeza)
	draw_oval(image, 16, 5, 32, 20, Color(0.2, 0.5, 0.9))
	# Punta del sombrero inclinada
	draw_triangle_curved(image, 32, 2, 15, Color(0.2, 0.5, 0.9))
	# Banda púrpura del sombrero
	draw_rectangle(image, 18, 18, 28, 4, Color(0.15, 0.2, 0.6))
	# Estrellas blancas en el sombrero
	draw_star(image, 22, 10, Color.WHITE)
	draw_star(image, 30, 8, Color.WHITE)
	draw_star(image, 38, 12, Color.WHITE)
	draw_star(image, 26, 15, Color.WHITE)
	# Estrella flotante
	draw_star(image, 48, 8, Color(0.8, 0.9, 1.0))
	
	# === OJOS GRANDES ESTILO FUNKO POP ===
	draw_circle(image, 26, 20, 4, Color.BLACK)  # Ojo izquierdo
	draw_circle(image, 36, 20, 4, Color.BLACK)  # Ojo derecho
	
	# === BARBA BLANCA ABUNDANTE ===
	draw_oval(image, 22, 26, 20, 16, Color.WHITE)
	# Textura de barba con mechones
	draw_oval(image, 20, 28, 8, 6, Color(0.95, 0.95, 0.95))
	draw_oval(image, 36, 30, 8, 6, Color(0.95, 0.95, 0.95))
	draw_oval(image, 28, 35, 10, 5, Color(0.95, 0.95, 0.95))
	
	# === TÚNICA AZUL ===
	draw_oval(image, 20, 42, 24, 18, Color(0.2, 0.5, 0.9))
	# Detalles de la túnica
	draw_oval(image, 22, 44, 20, 14, Color(0.15, 0.4, 0.8))
	
	# === CINTURÓN MARRÓN CON BOLSAS ===
	draw_rectangle(image, 24, 48, 16, 4, Color(0.4, 0.25, 0.1))
	# Bolsa izquierda
	draw_oval(image, 20, 50, 6, 8, Color(0.35, 0.2, 0.08))
	# Bolsa derecha  
	draw_oval(image, 38, 50, 6, 8, Color(0.35, 0.2, 0.08))
	
	# === BRAZOS ===
	# Brazo izquierdo
	draw_oval(image, 12, 38, 10, 16, Color(0.2, 0.5, 0.9))
	# Brazo derecho (sosteniendo bastón)
	draw_oval(image, 40, 38, 10, 16, Color(0.2, 0.5, 0.9))
	
	# === BASTÓN MÁGICO EN MANO DERECHA ===
	# Mango del bastón
	draw_rectangle(image, 46, 28, 4, 24, Color(0.4, 0.25, 0.1))
	# Orbe mágico azul en la punta
	draw_circle(image, 48, 25, 5, Color(0.3, 0.7, 1.0))
	draw_circle(image, 48, 25, 3, Color(0.6, 0.9, 1.0))  # Brillo interno
	
	# === PIES/BOTAS NEGRAS ===
	draw_oval(image, 26, 58, 8, 6, Color(0.1, 0.1, 0.1))
	draw_oval(image, 32, 58, 8, 6, Color(0.1, 0.1, 0.1))
	
	# Guardar sprite
	save_sprite(image, "res://sprites/wizard/wizard_down.png")
	print("✓ wizard_down.png creado (basado en imagen de frente del usuario)")

func create_wizard_left_from_user_image():
	"""Sprite basado en imagen 2: Mago perfil izquierda con bastón"""
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# === CABEZA EN PERFIL (estilo Isaac ovalada) ===
	draw_oval(image, 24, 12, 22, 24, Color(1.0, 0.9, 0.8))
	
	# === SOMBRERO EN PERFIL ===
	# Base del sombrero
	draw_oval(image, 22, 5, 28, 20, Color(0.2, 0.5, 0.9))
	# Punta curvada hacia la izquierda
	draw_triangle_left(image, 18, 8, 12, Color(0.2, 0.5, 0.9))
	# Banda
	draw_rectangle(image, 24, 18, 24, 4, Color(0.15, 0.2, 0.6))
	# Estrellas
	draw_star(image, 30, 10, Color.WHITE)
	draw_star(image, 38, 12, Color.WHITE)
	draw_star(image, 42, 15, Color.WHITE)
	# Estrella flotante
	draw_star(image, 16, 8, Color(0.8, 0.9, 1.0))
	
	# === OJO VISIBLE EN PERFIL ===
	draw_circle(image, 32, 20, 4, Color.BLACK)
	
	# === BARBA EN PERFIL ===
	draw_oval(image, 20, 26, 18, 14, Color.WHITE)
	# Mechones de barba
	draw_oval(image, 18, 28, 8, 6, Color(0.95, 0.95, 0.95))
	draw_oval(image, 24, 34, 10, 5, Color(0.95, 0.95, 0.95))
	
	# === TÚNICA EN PERFIL ===
	draw_oval(image, 24, 42, 20, 18, Color(0.2, 0.5, 0.9))
	
	# === CINTURÓN Y BOLSA ===
	draw_rectangle(image, 26, 48, 14, 4, Color(0.4, 0.25, 0.1))
	draw_oval(image, 36, 50, 6, 8, Color(0.35, 0.2, 0.08))
	
	# === BRAZOS EN PERFIL ===
	# Brazo visible sosteniendo bastón
	draw_oval(image, 38, 38, 8, 16, Color(0.2, 0.5, 0.9))
	
	# === BASTÓN VISIBLE ===
	draw_rectangle(image, 42, 28, 4, 24, Color(0.4, 0.25, 0.1))
	draw_circle(image, 44, 25, 5, Color(0.3, 0.7, 1.0))
	draw_circle(image, 44, 25, 3, Color(0.6, 0.9, 1.0))
	
	# === PIES EN PERFIL ===
	draw_oval(image, 28, 58, 10, 6, Color(0.1, 0.1, 0.1))
	draw_oval(image, 34, 58, 8, 6, Color(0.1, 0.1, 0.1))
	
	save_sprite(image, "res://sprites/wizard/wizard_left.png")
	print("✓ wizard_left.png creado (basado en imagen perfil izquierda del usuario)")

func create_wizard_up_from_user_image():
	"""Sprite basado en imagen 3: Mago mirando hacia arriba/frente"""
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Similar al sprite down pero con ligeras variaciones para "arriba"
	
	# === CABEZA ===
	draw_oval(image, 18, 12, 28, 24, Color(1.0, 0.9, 0.8))
	
	# === SOMBRERO MÁS PROMINENTE (vista frontal/arriba) ===
	draw_oval(image, 15, 3, 34, 22, Color(0.2, 0.5, 0.9))
	draw_triangle_curved(image, 32, 1, 18, Color(0.2, 0.5, 0.9))
	draw_rectangle(image, 17, 18, 30, 4, Color(0.15, 0.2, 0.6))
	
	# Más estrellas visibles
	draw_star(image, 20, 8, Color.WHITE)
	draw_star(image, 28, 6, Color.WHITE)
	draw_star(image, 36, 9, Color.WHITE)
	draw_star(image, 42, 12, Color.WHITE)
	draw_star(image, 32, 14, Color.WHITE)
	draw_star(image, 50, 6, Color(0.8, 0.9, 1.0))
	
	# === OJOS ===
	draw_circle(image, 26, 20, 4, Color.BLACK)
	draw_circle(image, 36, 20, 4, Color.BLACK)
	
	# === BARBA ===
	draw_oval(image, 22, 26, 20, 16, Color.WHITE)
	draw_oval(image, 20, 28, 8, 6, Color(0.95, 0.95, 0.95))
	draw_oval(image, 36, 30, 8, 6, Color(0.95, 0.95, 0.95))
	
	# === TÚNICA ===
	draw_oval(image, 20, 42, 24, 18, Color(0.2, 0.5, 0.9))
	
	# === CINTURÓN ===
	draw_rectangle(image, 24, 48, 16, 4, Color(0.4, 0.25, 0.1))
	draw_oval(image, 20, 50, 6, 8, Color(0.35, 0.2, 0.08))
	draw_oval(image, 38, 50, 6, 8, Color(0.35, 0.2, 0.08))
	
	# === BASTÓN ===
	draw_rectangle(image, 46, 28, 4, 24, Color(0.4, 0.25, 0.1))
	draw_circle(image, 48, 25, 5, Color(0.3, 0.7, 1.0))
	draw_circle(image, 48, 25, 3, Color(0.6, 0.9, 1.0))
	
	# === PIES ===
	draw_oval(image, 26, 58, 8, 6, Color(0.1, 0.1, 0.1))
	draw_oval(image, 32, 58, 8, 6, Color(0.1, 0.1, 0.1))
	
	save_sprite(image, "res://sprites/wizard/wizard_up.png")
	print("✓ wizard_up.png creado (basado en imagen arriba/frente del usuario)")

func create_wizard_right_from_user_image():
	"""Sprite basado en imagen 4: Mago visto desde espaldas"""
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Vista desde atrás - sombrero prominente, menos cara visible
	
	# === SOMBRERO DESDE ATRÁS ===
	draw_oval(image, 16, 5, 32, 22, Color(0.2, 0.5, 0.9))
	draw_triangle_curved(image, 32, 2, 16, Color(0.2, 0.5, 0.9))
	draw_rectangle(image, 18, 20, 28, 4, Color(0.15, 0.2, 0.6))
	
	# Estrellas visibles desde atrás
	draw_star(image, 22, 10, Color.WHITE)
	draw_star(image, 30, 8, Color.WHITE)
	draw_star(image, 38, 11, Color.WHITE)
	draw_star(image, 26, 14, Color.WHITE)
	draw_star(image, 48, 8, Color(0.8, 0.9, 1.0))
	
	# === CABEZA MENOS VISIBLE (desde atrás) ===
	draw_oval(image, 20, 15, 24, 20, Color(1.0, 0.9, 0.8))
	
	# === PELO/BARBA VISIBLE POR LOS LADOS ===
	draw_oval(image, 16, 22, 6, 10, Color.WHITE)  # Lado izquierdo
	draw_oval(image, 42, 22, 6, 10, Color.WHITE)  # Lado derecho
	
	# === TÚNICA DESDE ATRÁS ===
	draw_oval(image, 20, 40, 24, 20, Color(0.2, 0.5, 0.9))
	# Detalles de la túnica trasera
	draw_oval(image, 22, 42, 20, 16, Color(0.15, 0.4, 0.8))
	
	# === CINTURÓN DESDE ATRÁS ===
	draw_rectangle(image, 24, 48, 16, 4, Color(0.4, 0.25, 0.1))
	# Bolsas visibles desde atrás
	draw_oval(image, 38, 50, 6, 8, Color(0.35, 0.2, 0.08))
	
	# === BASTÓN VISIBLE POR EL LADO ===
	draw_rectangle(image, 42, 30, 4, 22, Color(0.4, 0.25, 0.1))
	draw_circle(image, 44, 27, 4, Color(0.3, 0.7, 1.0))
	draw_circle(image, 44, 27, 2, Color(0.6, 0.9, 1.0))
	
	# === PIES ===
	draw_oval(image, 26, 58, 8, 6, Color(0.1, 0.1, 0.1))
	draw_oval(image, 32, 58, 8, 6, Color(0.1, 0.1, 0.1))
	
	save_sprite(image, "res://sprites/wizard/wizard_right.png")
	print("✓ wizard_right.png creado (basado en imagen espaldas del usuario)")

# === FUNCIONES DE DIBUJO AUXILIARES ===

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
	for py in range(-radius-1, radius+2):
		for px in range(-radius-1, radius+2):
			if px*px + py*py <= radius*radius:
				var final_x = x + px
				var final_y = y + py
				if final_x >= 0 and final_x < image.get_width() and final_y >= 0 and final_y < image.get_height():
					image.set_pixel(final_x, final_y, color)

func draw_rectangle(image: Image, x: int, y: int, width: int, height: int, color: Color):
	for py in range(height):
		for px in range(width):
			var final_x = x + px
			var final_y = y + py
			if final_x >= 0 and final_x < image.get_width() and final_y >= 0 and final_y < image.get_height():
				image.set_pixel(final_x, final_y, color)

func draw_triangle_curved(image: Image, x: int, y: int, size: int, color: Color):
	for py in range(size):
		var width = max(1, size - py)
		for px in range(width):
			var final_x = x + px - width/2
			var final_y = y + py
			if final_x >= 0 and final_x < image.get_width() and final_y >= 0 and final_y < image.get_height():
				image.set_pixel(final_x, final_y, color)

func draw_triangle_left(image: Image, x: int, y: int, size: int, color: Color):
	for py in range(size):
		var width = max(1, py + 1)
		for px in range(width):
			var final_x = x - px
			var final_y = y + py
			if final_x >= 0 and final_x < image.get_width() and final_y >= 0 and final_y < image.get_height():
				image.set_pixel(final_x, final_y, color)

func draw_star(image: Image, x: int, y: int, color: Color):
	# Estrella de 5 puntas simple
	var points = [
		Vector2(0, -2), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0),
		Vector2(0, 1), Vector2(-1, -1), Vector2(1, -1)
	]
	for point in points:
		var final_x = x + point.x
		var final_y = y + point.y
		if final_x >= 0 and final_x < image.get_width() and final_y >= 0 and final_y < image.get_height():
			image.set_pixel(final_x, final_y, color)

func save_sprite(image: Image, path: String):
	"""Guarda el sprite como archivo PNG"""
	image.save_png(path)
	print("💾 Sprite guardado: ", path)
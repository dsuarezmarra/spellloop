extends Resource
class_name MagicWallTextures

# Generador de texturas de ladrillos de castillo para las paredes y suelo de arena

static func create_magic_wall_texture(_wall_type: String, size: Vector2) -> ImageTexture:
	"""Crear textura de ladrillos de castillo uniforme para todas las paredes"""
	var image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	
	# Crear textura base
	var texture = create_castle_brick_texture(image, size)
	
	# Para todas las paredes, el borde profesional ya está aplicado en la posición correcta
	# No necesitamos invertir las texturas ya que el borde se aplica después de los ladrillos
	
	return texture

static func create_sand_floor_texture(size: Vector2) -> ImageTexture:
	"""Crear textura de suelo de arena clara con textura realista"""
	var image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	
	# Colores para arena clara
	var sand_base = Color(0.95, 0.88, 0.75, 1.0)      # Arena base clara
	var sand_light = Color(0.98, 0.92, 0.82, 1.0)     # Arena muy clara
	var sand_medium = Color(0.92, 0.85, 0.72, 1.0)    # Arena media
	var sand_dark = Color(0.88, 0.82, 0.68, 1.0)      # Arena más oscura
	
	# Crear patrón de arena con variación de colores
	for y in range(int(size.y)):
		for x in range(int(size.x)):
			# Usar múltiples ondas para crear textura orgánica de arena
			var noise1 = sin(float(x) * 0.1) * cos(float(y) * 0.1)
			var noise2 = sin(float(x) * 0.03) * cos(float(y) * 0.03)
			var noise3 = sin(float(x) * 0.2) * cos(float(y) * 0.2)
			
			# Combinar ruidos para textura más compleja
			var combined_noise = (noise1 + noise2 * 0.5 + noise3 * 0.3) / 1.8
			
			# Seleccionar color basado en el ruido
			var sand_color = sand_base
			if combined_noise > 0.3:
				sand_color = sand_light
			elif combined_noise > 0.1:
				sand_color = sand_medium
			elif combined_noise < -0.2:
				sand_color = sand_dark
			
			# Añadir pequeñas variaciones aleatorias para más realismo
			var micro_variation = (sin(float(x * 13 + y * 17)) + 1.0) * 0.02
			sand_color.r = clamp(sand_color.r + micro_variation - 0.01, 0.0, 1.0)
			sand_color.g = clamp(sand_color.g + micro_variation - 0.01, 0.0, 1.0)
			sand_color.b = clamp(sand_color.b + micro_variation - 0.01, 0.0, 1.0)
			
			image.set_pixel(x, y, sand_color)
	
	var texture = ImageTexture.new()
	image.generate_mipmaps()
	texture.set_image(image)
	return texture

static func create_magic_door_texture(is_open: bool, size: Vector2) -> ImageTexture:
	"""Crear textura de puerta mágica estilo castillo"""
	var image = Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	
	if is_open:
		return create_open_door_texture(image, size)
	else:
		return create_closed_door_texture(int(size.x), int(size.y))

static func create_closed_door_texture(width: int, height: int) -> ImageTexture:
	"""Crear textura de puerta cerrada con forma de arco - MEJORADA"""
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	
	# Colores mejorados para puerta medieval mágica
	var wood_base = Color(0.45, 0.3, 0.2, 1.0)      # Madera base roble
	var wood_light = Color(0.65, 0.45, 0.3, 1.0)    # Madera clara
	var wood_dark = Color(0.3, 0.2, 0.15, 1.0)      # Madera oscura
	var metal_bronze = Color(0.6, 0.45, 0.25, 1.0)  # Bronce envejecido
	var metal_iron = Color(0.4, 0.4, 0.45, 1.0)     # Hierro forjado
	var rune_glow = Color(0.9, 0.6, 1.0, 0.9)       # Púrpura brillante
	var shadow_color = Color(0.2, 0.15, 0.1, 1.0)   # Sombra profunda
	
	var center_x = width / 2.0
	var arch_radius = width / 2.0 - 1
	var arch_height = arch_radius
	
	# Crear forma de arco con mejor definición
	for y in range(height):
		for x in range(width):
			var dx = x - center_x
			
			# Determinar si está dentro de la puerta
			var is_door = false
			var is_border = false
			
			if y >= arch_height and y < height - 1:
				# Parte rectangular de la puerta
				if x >= 1 and x < width - 1:
					is_door = true
				if x == 1 or x == width - 2:
					is_border = true
			else:
				# Parte del arco
				var dy = arch_height - y
				var distance = sqrt(dx * dx + dy * dy)
				if distance <= arch_radius - 1 and y >= 1:
					is_door = true
				elif distance <= arch_radius and y >= 1:
					is_border = true
			
			if is_door:
				# Textura de madera mejorada con paneles
				var panel_factor = 1.0
				var wood_grain = sin(x * 0.4 + y * 0.1) * 0.15 + sin(y * 0.6) * 0.1
				
				# Crear paneles verticales
				var panel_width = (width - 4) / 2.0
				var panel_x = x - 2
				if panel_x < panel_width:
					# Panel izquierdo
					var panel_center = panel_width / 2.0
					var dist_from_center = abs(panel_x - panel_center)
					panel_factor = 1.0 - (dist_from_center / panel_center) * 0.3
				else:
					# Panel derecho
					var right_panel_x = panel_x - panel_width
					var panel_center = panel_width / 2.0
					var dist_from_center = abs(right_panel_x - panel_center)
					panel_factor = 1.0 - (dist_from_center / panel_center) * 0.3
				
				var base_color = wood_base.lerp(wood_light, panel_factor + wood_grain)
				
				# Vetas de madera más realistas
				if abs(sin(x * 0.8 + y * 0.2)) > 0.6:
					base_color = base_color.lerp(wood_dark, 0.3)
				
				# Bandas metálicas decorativas horizontales
				var metal_band_spacing = max(8, height / 6.0)
				if (y - arch_height) % metal_band_spacing < 2 and y >= arch_height + 4:
					var metal_shine = sin(x * 0.7) * 0.3 + 0.7
					base_color = metal_bronze.lerp(metal_iron, metal_shine)
				
				# Clavos metálicos en las bandas
				if (y - arch_height) % metal_band_spacing == 1 and y >= arch_height + 4:
					if x % 8 == 3 or x % 8 == 5:
						base_color = metal_iron.lerp(shadow_color, 0.3)
				
				# Runas mágicas brillantes en posiciones específicas
				var rune_factor = sin(x * 2.1 + y * 1.7) * sin(x * 1.3 + y * 2.2)
				if rune_factor > 0.85 and y > arch_height + 6 and y < height - 6:
					base_color = base_color.lerp(rune_glow, 0.6)
				
				# Sombras en los bordes para profundidad
				var edge_distance = min(x - 1, width - 2 - x)
				if edge_distance < 2:
					base_color = base_color.lerp(shadow_color, 0.2)
				
				image.set_pixel(x, y, base_color)
			
			elif is_border:
				# Borde de hierro forjado
				var border_color = metal_iron.lerp(shadow_color, 0.4)
				image.set_pixel(x, y, border_color)
	
	var texture = ImageTexture.new()
	image.generate_mipmaps()
	texture.set_image(image)
	return texture

static func create_open_door_texture(image: Image, size: Vector2) -> ImageTexture:
	"""Crear textura de puerta abierta - portal mágico en forma de arco"""
	
	# Colores para portal mágico
	var portal_center = Color(0.8, 0.9, 1.0, 1.0)    # Centro brillante
	var portal_mid = Color(0.4, 0.6, 1.0, 1.0)       # Medio azul
	var portal_edge = Color(0.2, 0.3, 0.8, 1.0)      # Borde azul oscuro
	var frame_color = Color(0.3, 0.2, 0.1, 1.0)      # Marco de madera
	var transparent = Color(0, 0, 0, 0)               # Transparente
	
	var width = int(size.x)
	var height = int(size.y)
	var center_x = width / 2.0
	var arch_height = height * 0.7    # Misma proporción que puerta cerrada
	var arch_radius = width / 2.0 - 2  # Radio ligeramente menor para el marco
	
	# Inicializar con transparente
	image.fill(transparent)
	
	# Crear marco de madera en forma de arco
	for y in range(height):
		for x in range(width):
			var is_frame = false
			
			if y >= arch_height:
				# Parte rectangular inferior - solo los bordes
				if x < 2 or x >= width - 2 or y >= height - 2:
					is_frame = true
			else:
				# Parte del arco - crear marco
				var dx = x - center_x
				var dy = arch_height - y
				var distance = sqrt(dx * dx + dy * dy)
				
				# Marco: está dentro del radio exterior pero fuera del radio interior
				if distance <= arch_radius + 2 and distance >= arch_radius - 1:
					is_frame = true
			
			if is_frame:
				image.set_pixel(x, y, frame_color)
	
	# Portal mágico con forma de arco
	for y in range(height):
		for x in range(width):
			var dx = x - center_x
			
			# Determinar si está dentro del área del portal
			var is_in_portal = false
			
			if y >= arch_height + 2 and y < height - 2:
				# Parte rectangular del portal
				if x >= 2 and x < width - 2:
					is_in_portal = true
			else:
				# Parte del arco del portal
				var dy = arch_height - y
				var distance = sqrt(dx * dx + dy * dy)
				if distance < arch_radius - 1:
					is_in_portal = true
			
			if is_in_portal:
				# Crear gradiente radial múltiple desde el centro
				var center_distance = sqrt(dx * dx + (y - height * 0.6) * (y - height * 0.6))
				var max_distance = min(width, height) / 2.0 - 4
				var factor = clamp(center_distance / max_distance, 0.0, 1.0)
				
				var portal_color
				if factor < 0.15:
					# Centro brillante
					portal_color = portal_center
				elif factor < 0.4:
					# Transición al medio
					portal_color = portal_center.lerp(portal_mid, (factor - 0.15) / 0.25)
				elif factor < 0.8:
					# Medio al borde
					portal_color = portal_mid.lerp(portal_edge, (factor - 0.4) / 0.4)
				else:
					# Borde oscuro
					portal_color = portal_edge
				
				# Añadir ondas mágicas en anillos concéntricos
				var wave_rings = sin(center_distance * 0.8) * 0.12
				var wave_spiral = sin(center_distance * 0.4 + atan2(y - height * 0.6, dx) * 3.0) * 0.08
				var wave_effect = wave_rings + wave_spiral
				
				portal_color.r = clamp(portal_color.r + wave_effect, 0.0, 1.0)
				portal_color.g = clamp(portal_color.g + wave_effect * 0.8, 0.0, 1.0)
				portal_color.b = clamp(portal_color.b + wave_effect * 0.6, 0.0, 1.0)
				
				# Chispas mágicas
				var spark_noise = sin(x * 2.7 + y * 3.1) * sin(x * 1.9 + y * 2.3)
				if spark_noise > 0.82 and factor > 0.25:
					var spark_color = Color(1.0, 0.9, 1.0, 0.7)
					portal_color = portal_color.lerp(spark_color, 0.4)
				
				image.set_pixel(x, y, portal_color)
	
	var texture = ImageTexture.new()
	image.generate_mipmaps()
	texture.set_image(image)
	return texture

static func create_castle_brick_texture(image: Image, size: Vector2) -> ImageTexture:
	"""Crear textura de ladrillos de castillo medieval con borde profesional"""
	
	# Colores para ladrillos de castillo
	var mortar_color = Color(0.45, 0.4, 0.35, 1.0)     # Mortero gris más claro
	var brick_base = Color(0.65, 0.55, 0.45, 1.0)      # Ladrillo base marrón
	var brick_light = Color(0.75, 0.65, 0.55, 1.0)     # Ladrillo claro
	var brick_dark = Color(0.55, 0.45, 0.35, 1.0)      # Ladrillo oscuro
	var border_color = Color(0.3, 0.2, 0.15, 1.0)      # Línea de borde marrón oscura
	
	# Parámetros de los ladrillos - AJUSTADOS para paredes más pequeñas
	var brick_width = 16  # Reducido para paredes más pequeñas
	var brick_height = 8   # Reducido para paredes más pequeñas
	var mortar_thickness = 1  # Reducido para paredes más pequeñas
	
	# Llenar toda la imagen con mortero primero
	image.fill(mortar_color)
	
	# Dibujar ladrillos en patrón alternado
	var rows = int(size.y / (brick_height + mortar_thickness)) + 2
	var cols = int(size.x / (brick_width + mortar_thickness)) + 2
	
	for row in range(rows):
		for col in range(cols):
			# Offset alternado para patrón de ladrillos
			var offset_x = (brick_width / 2.0) if (row % 2 == 1) else 0.0
			
			var brick_x = col * (brick_width + mortar_thickness) + offset_x
			var brick_y = row * (brick_height + mortar_thickness) + mortar_thickness
			
			# Elegir color de ladrillo con variación determinística
			var brick_color = brick_base
			var pattern_factor = (row + col) % 4
			match pattern_factor:
				1:
					brick_color = brick_light
				3:
					brick_color = brick_dark
			
			# Dibujar el ladrillo (asegurar que esté dentro de límites)
			draw_brick_rectangle(image, brick_x, brick_y, brick_width, brick_height, brick_color)
	
	# Añadir línea de borde profesional marrón oscura en el perímetro exterior
	draw_professional_border(image, size, border_color)
	
	var texture = ImageTexture.new()
	image.generate_mipmaps()  # Generar mipmaps para mejor renderizado
	texture.set_image(image)
	return texture

static func draw_brick_rectangle(image: Image, start_x: float, start_y: float, width: int, height: int, color: Color):
	"""Dibujar un rectángulo de ladrillo en la imagen con límites seguros"""
	var img_width = image.get_width()
	var img_height = image.get_height()
	
	# Asegurar que el rectángulo esté completamente dentro de la imagen
	var end_x = min(int(start_x + width), img_width)
	var end_y = min(int(start_y + height), img_height)
	var begin_x = max(int(start_x), 0)
	var begin_y = max(int(start_y), 0)
	
	for y in range(begin_y, end_y):
		for x in range(begin_x, end_x):
			image.set_pixel(x, y, color)

static func draw_professional_border(image: Image, size: Vector2, border_color: Color):
	"""Dibujar una línea fina de borde profesional en el perímetro exterior"""
	var width = int(size.x)
	var height = int(size.y)
	
	# Línea superior (y = 0)
	for x in range(width):
		image.set_pixel(x, 0, border_color)
	
	# Línea inferior (y = height-1)
	for x in range(width):
		image.set_pixel(x, height - 1, border_color)
	
	# Línea izquierda (x = 0)
	for y in range(height):
		image.set_pixel(0, y, border_color)
	
	# Línea derecha (x = width-1)
	for y in range(height):
		image.set_pixel(width - 1, y, border_color)
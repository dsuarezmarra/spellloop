@tool
extends EditorScript

"""
🎨 GENERADOR AUTOMÁTICO DE TILES PARA BIOMAS
================================================

Este script divide las texturas base (512×512) en tiles de 64×64
y genera automáticamente tiles de transición entre biomas.

INSTRUCCIONES:
1. Abrir en el editor de scripts
2. Ejecutar: File → Run
3. Los tiles se generarán en assets/tilesets/tiles/

RESULTADO:
- 8×8 = 64 tiles por bioma de la textura base
- Tiles de transición automáticos (blending entre biomas)
"""

# Configuración
const TILE_SIZE = 64
const INPUT_SIZE = 512
const TILES_PER_ROW = INPUT_SIZE / TILE_SIZE  # 8

# Rutas
const BIOMES_PATH = "res://assets/textures/biomes/"
const OUTPUT_PATH = "res://assets/tilesets/tiles/"

# Biomas a procesar
const BIOMES = [
	{"id": "grassland", "name": "Grassland", "folder": "Grassland"},
	{"id": "desert", "name": "Desert", "folder": "Desert"},
	{"id": "forest", "name": "Forest", "folder": "Forest"},
	{"id": "arcane_wastes", "name": "ArcaneWastes", "folder": "ArcaneWastes"},
	{"id": "lava", "name": "Lava", "folder": "Lava"},
	{"id": "snow", "name": "Snow", "folder": "Snow"}
]

func _run():
	print("======================================================================")
	print("🎨 GENERADOR DE TILES PARA BIOMAS")
	print("======================================================================")

	# Crear directorio de salida
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(OUTPUT_PATH):
		dir.make_dir_recursive(OUTPUT_PATH)
		print("✓ Directorio creado: %s" % OUTPUT_PATH)

	# Procesar cada bioma
	for biome in BIOMES:
		print("\n📦 Procesando: %s" % biome.name)
		_process_biome(biome)

	print("\n======================================================================")
	print("✅ GENERACIÓN COMPLETADA")
	print("======================================================================")
	print("📂 Tiles generados en: %s" % OUTPUT_PATH)
	print("\n🎯 SIGUIENTE PASO:")
	print("   1. Crear TileSet resource en assets/tilesets/world_tileset.tres")
	print("   2. Importar tiles generados al TileSet")
	print("   3. Configurar terrains en el TileSet editor")

func _process_biome(biome: Dictionary):
	"""Procesar un bioma: dividir base.png en tiles de 64×64"""
	var base_path = BIOMES_PATH + biome.folder + "/base.png"

	# Verificar que existe
	if not FileAccess.file_exists(base_path):
		printerr("  ✗ No existe: %s" % base_path)
		return

	# Cargar textura
	var texture = load(base_path) as Texture2D
	if not texture:
		printerr("  ✗ No se pudo cargar: %s" % base_path)
		return

	var image = texture.get_image()
	if not image:
		printerr("  ✗ No se pudo obtener imagen de: %s" % base_path)
		return

	print("  ✓ Textura cargada: %dx%d" % [image.get_width(), image.get_height()])

	# Crear directorio para este bioma
	var biome_output = OUTPUT_PATH + biome.id + "/"
	var dir = DirAccess.open("res://")
	if not dir.dir_exists(biome_output):
		dir.make_dir_recursive(biome_output)

	# Dividir en tiles de 64×64
	var tiles_created = 0
	for row in range(TILES_PER_ROW):
		for col in range(TILES_PER_ROW):
			var tile_image = Image.create(TILE_SIZE, TILE_SIZE, false, image.get_format())

			# Copiar región de la imagen original
			tile_image.blit_rect(
				image,
				Rect2i(col * TILE_SIZE, row * TILE_SIZE, TILE_SIZE, TILE_SIZE),
				Vector2i(0, 0)
			)

			# Guardar tile
			var tile_filename = "%s_%d_%d.png" % [biome.id, col, row]
			var save_path = biome_output + tile_filename
			var err = tile_image.save_png(save_path)

			if err == OK:
				tiles_created += 1
			else:
				printerr("  ✗ Error guardando: %s" % save_path)

	print("  ✓ Tiles creados: %d (8×8 grid)" % tiles_created)

func _create_transition_tile(biome_a: Dictionary, biome_b: Dictionary, side: String) -> Image:
	"""
	Crear tile de transición entre dos biomas.
	side: "top", "bottom", "left", "right", "top_left", "top_right", "bottom_left", "bottom_right"
	"""
	var tile_a_path = BIOMES_PATH + biome_a.folder + "/base.png"
	var tile_b_path = BIOMES_PATH + biome_b.folder + "/base.png"

	var texture_a = load(tile_a_path) as Texture2D
	var texture_b = load(tile_b_path) as Texture2D

	if not texture_a or not texture_b:
		return null

	var image_a = texture_a.get_image()
	var image_b = texture_b.get_image()

	# Crear imagen resultado
	var result = Image.create(TILE_SIZE, TILE_SIZE, false, image_a.get_format())

	# Mezclar según el lado
	for y in range(TILE_SIZE):
		for x in range(TILE_SIZE):
			var alpha = _get_blend_alpha(x, y, side)

			# Obtener colores de ambas texturas (usar tile central)
			var color_a = image_a.get_pixel(
				256 + (x % TILE_SIZE),
				256 + (y % TILE_SIZE)
			)
			var color_b = image_b.get_pixel(
				256 + (x % TILE_SIZE),
				256 + (y % TILE_SIZE)
			)

			# Mezclar colores
			var final_color = color_a.lerp(color_b, alpha)
			result.set_pixel(x, y, final_color)

	return result

func _get_blend_alpha(x: int, y: int, side: String) -> float:
	"""Calcular alpha para blending según posición y lado"""
	var nx = float(x) / TILE_SIZE  # 0.0 a 1.0
	var ny = float(y) / TILE_SIZE

	match side:
		"top":
			return ny  # 0 arriba, 1 abajo
		"bottom":
			return 1.0 - ny
		"left":
			return nx
		"right":
			return 1.0 - nx
		"top_left":
			return (nx + ny) / 2.0
		"top_right":
			return (1.0 - nx + ny) / 2.0
		"bottom_left":
			return (nx + 1.0 - ny) / 2.0
		"bottom_right":
			return (1.0 - nx + 1.0 - ny) / 2.0

	return 0.5

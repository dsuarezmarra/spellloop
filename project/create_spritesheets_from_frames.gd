extends SceneTree

# Script para crear spritesheets desde frames individuales
# Se ejecuta con: godot --headless --script create_spritesheets_from_frames.gd

const FRAME_SIZE_DECOR = 256
const FRAME_SIZE_BASE = 512
const PADDING = 4
const FRAMES_PER_SHEET = 8

func _init():
	print("\\n=================================================")
	print("CREADOR DE SPRITESHEETS DESDE FRAMES INDIVIDUALES")
	print("=================================================")

	var success_count = 0
	var total_count = 0

	# Rutas base - usar rutas absolutas
	var downloads_base = "C:/Users/dsuarez1/Downloads/biomes/"
	var project_base = "C:/Users/dsuarez1/git/spellloop/project/assets/textures/biomes/"

	print("\\nRutas configuradas:")
	print("  Entrada: " + downloads_base)
	print("  Salida: " + project_base)

	# ===== GRASSLAND DECOR (10 decoraciones) =====
	print("\\n================================================")
	print("PROCESANDO GRASSLAND DECOR (10 decoraciones)")
	print("================================================")

	for decor_num in range(1, 11):
		total_count += 1
		var start_frame = decor_num * 10 + 1
		var frame_numbers = []
		for i in range(8):
			frame_numbers.append(start_frame + i)

		var input_folder = downloads_base + "Grassland/decor/"
		var output_path = project_base + "Grassland/decor/grassland_decor%d_sheet_f8_256.png" % decor_num

		print("\\nDecor %d (frames %02d-%02d):" % [decor_num, frame_numbers[0], frame_numbers[-1]])
		print("  Input: " + input_folder)
		print("  Output: " + output_path)

		if create_spritesheet(input_folder, frame_numbers, output_path, FRAME_SIZE_DECOR):
			success_count += 1
			print("  [OK] Creado exitosamente")
		else:
			print("  [ERROR] Fallo al crear")

	# ===== DESERT BASE =====
	print("\\n================================================")
	print("PROCESANDO DESERT BASE")
	print("================================================")
	total_count += 1

	var desert_frames = []
	for i in range(1, 9):
		desert_frames.append(i)

	var desert_input = downloads_base + "Desert/base/"
	var desert_output = project_base + "Desert/base/desert_base_animated_sheet_f8_512.png"

	print("\\nTextura base (frames 01-08):")
	print("  Input: " + desert_input)
	print("  Output: " + desert_output)

	if create_spritesheet(desert_input, desert_frames, desert_output, FRAME_SIZE_BASE):
		success_count += 1
		print("  [OK] Creado exitosamente")
	else:
		print("  [ERROR] Fallo al crear")

	# ===== DEATH BASE =====
	print("\\n================================================")
	print("PROCESANDO DEATH BASE")
	print("================================================")
	total_count += 1

	var death_frames = []
	for i in range(1, 9):
		death_frames.append(i)

	var death_input = downloads_base + "Death/base/"
	var death_output = project_base + "Death/base/death_base_animated_sheet_f8_512.png"

	print("\\nTextura base (frames 1-8):")
	print("  Input: " + death_input)
	print("  Output: " + death_output)

	if create_spritesheet(death_input, death_frames, death_output, FRAME_SIZE_BASE):
		success_count += 1
		print("  [OK] Creado exitosamente")
	else:
		print("  [ERROR] Fallo al crear")

	# ===== RESUMEN =====
	print("\\n================================================")
	print("COMPLETADO: %d/%d spritesheets creados" % [success_count, total_count])
	print("================================================")

	if success_count == total_count:
		print("\\n[EXITO] Todos los spritesheets se crearon exitosamente!")
		quit(0)
	else:
		print("\\n[ADVERTENCIA] %d spritesheets fallaron" % (total_count - success_count))
		quit(1)

func create_spritesheet(input_folder: String, frame_numbers: Array, output_path: String, frame_size: int) -> bool:
	"""Crea un spritesheet desde frames individuales"""

	print("    Iniciando creacion de spritesheet...")

	# Verificar que existen todos los frames
	var frame_images = []
	for num in frame_numbers:
		var frame_path = input_folder + ("%02d.png" % num)

		# Si no existe con ceros, intentar sin ceros
		if not FileAccess.file_exists(frame_path):
			frame_path = input_folder + ("%d.png" % num)

		if not FileAccess.file_exists(frame_path):
			print("    [ERROR] No se encontro frame %d en %s" % [num, input_folder])
			print("    Intentado: %s" % frame_path)
			return false

		# Cargar imagen
		print("    Cargando frame %d: %s" % [num, frame_path])
		var img = Image.load_from_file(frame_path)
		if img == null:
			print("    [ERROR] No se pudo cargar %s" % frame_path)
			return false

		# Convertir a RGBA si es necesario
		if img.get_format() != Image.FORMAT_RGBA8:
			img.convert(Image.FORMAT_RGBA8)

		# Si no es cuadrada, recortar al centro
		var width = img.get_width()
		var height = img.get_height()

		if width != height:
			var min_dim = min(width, height)
			var left = (width - min_dim) / 2
			var top = (height - min_dim) / 2
			var cropped = img.get_region(Rect2i(left, top, min_dim, min_dim))
			img = cropped

		# Redimensionar al tamaño correcto si es necesario
		if img.get_width() != frame_size or img.get_height() != frame_size:
			img.resize(frame_size, frame_size, Image.INTERPOLATE_LANCZOS)

		frame_images.append(img)

	# Crear imagen del spritesheet
	var output_width = (frame_size * FRAMES_PER_SHEET) + PADDING
	var output_height = frame_size
	var output_img = Image.create(output_width, output_height, false, Image.FORMAT_RGBA8)

	# Llenar con transparente
	output_img.fill(Color(0, 0, 0, 0))

	# Copiar cada frame al spritesheet
	for i in range(frame_images.size()):
		var frame = frame_images[i]
		var x_pos = i * frame_size

		# Copiar píxeles
		output_img.blit_rect(frame, Rect2i(0, 0, frame_size, frame_size), Vector2i(x_pos, 0))

	# Crear directorio si no existe
	var dir_path = output_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	# Guardar imagen
	print("    Guardando en: %s" % output_path)
	var err = output_img.save_png(output_path)
	if err != OK:
		print("    [ERROR] al guardar: %s (codigo %d)" % [output_path, err])
		return false

	print("    [OK] Spritesheet guardado: %dx%d px" % [output_width, output_height])
	return true

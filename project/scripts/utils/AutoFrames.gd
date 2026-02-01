# AutoFrames.gd (Godot 4)
# Utilidad para cargar spritesheets horizontales automáticamente
# Convención de nombres: *_sheet_fN_SIZE.png (ej: lava_spout_sheet_f8_256.png)
class_name AutoFrames

extends Node

# Caché global para SpriteFrames interpolados
static var _interpolated_cache: Dictionary = {}

static func load_sprite(base_path: String, default_fps: float = 10.0, duplicate_frames: int = 1) -> Node:
	"""
	Busca y carga un spritesheet animado usando un path base (sin extensión).
	Devuelve un nodo listo para usar (AnimatedSprite2D o Sprite2D).

	Parámetros:
	- base_path: Ruta base SIN extensión (ej: "res://assets/.../lava_base_animated")
	- default_fps: FPS de la animación (default 5.0)

	Retorna:
	- AnimatedSprite2D si encuentra un spritesheet (*_sheet_fN_SIZE.png)
	- Sprite2D si encuentra una imagen estática (*.png)
	- null si no encuentra nada

	Ejemplo:
	  var node = AutoFrames.load_sprite("res://assets/lava_base_animated")
	  # Buscará: lava_base_animated_sheet_f8_512.png, lava_base_animated.png, etc.
	"""
	# Buscar todos los archivos que coincidan con el base_path
	var dir_path = base_path.get_base_dir()
	var file_name = base_path.get_file()

	# Intentar encontrar spritesheet animado primero
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var found_sheet: String = ""
		var found_static: String = ""

		while true:
			var file = dir.get_next()
			if file == "":
				break

			if file.begins_with(file_name):
				if file.contains("_sheet_f") and file.ends_with(".png"):
					found_sheet = dir_path.path_join(file)
					break  # Prioridad a spritesheet animado
				elif file.ends_with(".png") and not file.contains("_sheet_f"):
					found_static = dir_path.path_join(file)

		dir.list_dir_end()

		# Si encontró spritesheet animado, crear AnimatedSprite2D
		if found_sheet != "":
			var frames = from_sheet(found_sheet, default_fps, duplicate_frames)
			if frames:
				var anim = AnimatedSprite2D.new()
				anim.sprite_frames = frames
				anim.animation = "default"
				# CRÍTICO: Desactivar filtro para tiles seamless (elimina líneas entre tiles)
				anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				# CRÍTICO: DESACTIVAR texture_repeat cuando se usa AtlasTexture
				# (el repeat + atlas puede samplear fuera de región y coger frames vecinos)
				anim.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
				return anim
			else:
				push_error("❌ [AutoFrames] Error al cargar spritesheet: %s" % found_sheet)
				return null

		# Si encontró imagen estática, crear Sprite2D
		if found_static != "":
			var tex: Texture2D = load(found_static)
			if tex:
				var spr = Sprite2D.new()
				spr.texture = tex
				# CRÍTICO: Desactivar filtro para tiles seamless
				spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				return spr
			else:
				push_error("❌ [AutoFrames] Error al cargar textura: %s" % found_static)
				return null

	push_warning("⚠️ [AutoFrames] No se encontró archivo para: %s" % base_path)
	return null

static func from_sheet(sheet_path: String, default_fps: float = 10.0, duplicate_frames: int = 1) -> SpriteFrames:
	"""
	Carga un spritesheet horizontal y crea un recurso SpriteFrames.

	Parámetros:
	- sheet_path: Ruta al PNG (debe seguir convención *_sheet_fN_SIZE.png)
	- default_fps: FPS de la animación (default 10.0)
	- duplicate_frames: Cuántas veces duplicar cada frame (1 = sin duplicar, 5 = 8 frames → 40 frames)

	Retorna:
	- SpriteFrames con animación "default" lista para usar
	- null si el archivo no sigue la convención o no se puede cargar
	"""

	# Crear clave de caché única
	var cache_key = "%s_%d_%d" % [sheet_path, int(default_fps), duplicate_frames]

	# Si ya está en caché, retornar copia profunda
	if _interpolated_cache.has(cache_key):
		# if OS.is_debug_build():
		# 	print("[AutoFrames] 🚀 Cargado desde caché: %s" % sheet_path.get_file())
		# Deep copy para evitar compartir animaciones
		return _interpolated_cache[cache_key].duplicate(true)

	var re := RegEx.new()
	re.compile("_sheet_f(\\d+)_([0-9]+)\\.png$")
	var m := re.search(sheet_path)

	if m == null:
		push_warning("⚠️ [AutoFrames] Nombre no sigue la convención *_sheet_fN_SIZE.png: %s" % sheet_path)
		return null

	var frames_count := int(m.get_string(1))  # Número de frames (ej: 8)
	var frame_size := int(m.get_string(2))    # Tamaño por frame (ej: 256, 510, 512)

	# Cargar textura
	var tex: Texture2D = load(sheet_path)
	if tex == null:
		push_error("❌ [AutoFrames] No se pudo cargar %s" % sheet_path)
		return null

	var total_w := tex.get_width()
	var total_h := tex.get_height()

	# Detectar padding automáticamente según dimensiones reales
	var padding_px := 0
	var expected_width_with_padding := (frame_size + 4) * frames_count - 4  # Con 4px padding
	var expected_width_no_padding := frame_size * frames_count               # Sin padding

	if abs(total_w - expected_width_with_padding) <= 4:
		padding_px = 4
		# if OS.is_debug_build():
		# 	print("[AutoFrames] 📐 Spritesheet CON padding de 4px detectado")
	elif abs(total_w - expected_width_no_padding) <= 4:
		padding_px = 0
		# if OS.is_debug_build():
		# 	print("[AutoFrames] 📐 Spritesheet SIN padding detectado")
	else:
		push_warning("⚠️ [AutoFrames] Dimensiones no coinciden. Esperado: %d (padding 4px) o %d (sin padding), Real: %d (%s)" % [
			expected_width_with_padding, expected_width_no_padding, total_w, sheet_path
		])

	# Crear SpriteFrames
	var frames := SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_loop("default", true)
	frames.set_animation_speed("default", default_fps)

	# Cortar frames del spritesheet
	var x := 0
	var original_frames = []

	# Primero extraer todos los frames originales como Image
	for i in frames_count:
		var region := Rect2(x, 0, frame_size, total_h)
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = region
		original_frames.append(atlas)
		x += frame_size + padding_px

	# Si duplicate_frames > 1, interpolar entre frames
	if duplicate_frames > 1:
		for i in frames_count:
			var current_frame = original_frames[i]
			var next_frame = original_frames[(i + 1) % frames_count]  # Loop al primero

			# Añadir frame original
			frames.add_frame("default", current_frame)

			# Crear frames interpolados entre current y next
			for step in range(1, duplicate_frames):
				var blend_factor = float(step) / float(duplicate_frames)
				var interpolated = _create_interpolated_frame(current_frame, next_frame, blend_factor, frame_size, total_h)
				frames.add_frame("default", interpolated)
	else:
		pass  # Bloque else
		# Sin interpolación, añadir frames normalmente
		for atlas in original_frames:
			frames.add_frame("default", atlas)

	var total_frames := frames_count * duplicate_frames
	# if OS.is_debug_build():
	# 	var mode = "interpolados" if duplicate_frames > 1 else "originales"
	# 	print("[AutoFrames] ✅ Cargado: %s (%d frames %s @ %d FPS = %d frames totales)" % [
	# 		sheet_path.get_file(), frames_count, mode, default_fps, total_frames
	# 	])

	# Guardar en caché
	_interpolated_cache[cache_key] = frames

	return frames

# Función auxiliar para crear un frame interpolado entre dos frames (OPTIMIZADO)
static func _create_interpolated_frame(frame1: AtlasTexture, frame2: AtlasTexture, blend_factor: float, width: int, height: int) -> ImageTexture:
	# Extraer regiones directamente como Image usando get_region (mucho más rápido)
	var img1 = frame1.atlas.get_image()
	var img2 = frame2.atlas.get_image()

	var region1 = frame1.region
	var region2 = frame2.region

	# get_region es nativo y muy rápido
	var crop1 = img1.get_region(Rect2i(region1.position.x, region1.position.y, width, height))
	var crop2 = img2.get_region(Rect2i(region2.position.x, region2.position.y, width, height))

	# Crear resultado con formato optimizado
	var result = Image.create(width, height, false, Image.FORMAT_RGBA8)

	# Blend manual optimizado usando get_data/set_data (más rápido que píxel a píxel)
	var data1 = crop1.get_data()
	var data2 = crop2.get_data()
	var result_data = PackedByteArray()
	result_data.resize(data1.size())

	# Interpolar todos los bytes de una vez (RGBA)
	for i in range(0, data1.size()):
		var val1 = data1[i]
		var val2 = data2[i]
		result_data[i] = int(lerp(val1, val2, blend_factor))

	result.set_data(width, height, false, Image.FORMAT_RGBA8, result_data)

	return ImageTexture.create_from_image(result)

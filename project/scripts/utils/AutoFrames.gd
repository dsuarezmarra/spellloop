# AutoFrames.gd (Godot 4)
# Utilidad para cargar spritesheets horizontales automáticamente
# Convención de nombres: *_sheet_fN_SIZE.png (ej: lava_spout_sheet_f8_256.png)
class_name AutoFrames

static func load_sprite(base_path: String, default_fps: float = 5.0) -> Node2D:
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
			var frames = from_sheet(found_sheet, default_fps)
			if frames:
				var anim = AnimatedSprite2D.new()
				anim.sprite_frames = frames
				anim.animation = "default"
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
				return spr
			else:
				push_error("❌ [AutoFrames] Error al cargar textura: %s" % found_static)
				return null
	
	push_warning("⚠️ [AutoFrames] No se encontró archivo para: %s" % base_path)
	return null

static func from_sheet(sheet_path: String, default_fps: float = 10.0) -> SpriteFrames:
	"""
	Carga un spritesheet horizontal y crea un recurso SpriteFrames.
	
	Parámetros:
	- sheet_path: Ruta al PNG (debe seguir convención *_sheet_fN_SIZE.png)
	- default_fps: FPS de la animación (default 10.0)
	
	Retorna:
	- SpriteFrames con animación "default" lista para usar
	- null si el archivo no sigue la convención o no se puede cargar
	"""
	var re := RegEx.new()
	re.compile("_sheet_f(\\d+)_([0-9]+)\\.png$")
	var m := re.search(sheet_path)
	
	if m == null:
		push_warning("⚠️ [AutoFrames] Nombre no sigue la convención *_sheet_fN_SIZE.png: %s" % sheet_path)
		return null

	var frames_count := int(m.get_string(1))  # Número de frames (ej: 8)
	var frame_size := int(m.get_string(2))    # Tamaño por frame (ej: 256)
	var padding_px := 4                        # Padding horizontal entre frames (fijo)

	# Cargar textura
	var tex: Texture2D = load(sheet_path)
	if tex == null:
		push_error("❌ [AutoFrames] No se pudo cargar %s" % sheet_path)
		return null

	var total_w := tex.get_width()
	var total_h := tex.get_height()
	
	# Validar dimensiones esperadas
	var expected_width := (frame_size + padding_px) * frames_count - padding_px
	if abs(total_w - expected_width) > padding_px:
		push_warning("⚠️ [AutoFrames] Dimensiones no coinciden. Esperado: ~%d, Real: %d (%s)" % [
			expected_width, total_w, sheet_path
		])

	# Crear SpriteFrames
	var frames := SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_loop("default", true)
	frames.set_animation_speed("default", default_fps)

	# Cortar frames del spritesheet
	var x := 0
	for i in frames_count:
		var region := Rect2(x, 0, frame_size, total_h)
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = region
		frames.add_frame("default", atlas)
		x += frame_size + padding_px
	
	if OS.is_debug_build():
		print("[AutoFrames] ✅ Cargado: %s (%d frames @ %d FPS)" % [
			sheet_path.get_file(), frames_count, default_fps
		])
	
	return frames

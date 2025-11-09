# AutoFrames.gd (Godot 4)
# Utilidad para cargar spritesheets horizontales automáticamente
# Convención de nombres: *_sheet_fN_SIZE.png (ej: lava_spout_sheet_f8_256.png)
class_name AutoFrames

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

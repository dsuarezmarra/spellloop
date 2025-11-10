# DecorFactory.gd
# Fabricador de decoraciones estáticas y animadas para biomas
# Detecta automáticamente el tipo por nombre de archivo y crea el nodo apropiado
class_name DecorFactory
extends Node

## Crear decoración (estática o animada) desde una ruta de textura
## Detecta automáticamente si es spritesheet por el patrón "_sheet_f"
static func make_decor(tex_path: String, base_fps: float = 5.0) -> Node2D:
	"""
	Crea un nodo de decoración (Sprite2D o AnimatedSprite2D).
	
	Parámetros:
	- tex_path: Ruta a la textura (PNG estático o spritesheet)
	- base_fps: FPS base para animaciones (default 5.0)
	
	Retorna:
	- AnimatedSprite2D si es spritesheet (*_sheet_fN_SIZE.png)
	- Sprite2D si es textura estática
	
	Características:
	- Pivot: bottom-center (para que "planten" en el suelo)
	- Animaciones desincronizadas (frame inicial aleatorio)
	- Speed variado (0.9-1.1x) para naturalidad
	"""
	var is_sheet := tex_path.contains("_sheet_f")
	
	if is_sheet:
		# Decoración animada (spritesheet)
		var frames := AutoFrames.from_sheet(tex_path, base_fps)
		
		if frames == null:
			push_error("❌ [DecorFactory] No se pudo cargar spritesheet: %s" % tex_path)
			return null
		
		var anim := AnimatedSprite2D.new()
		anim.sprite_frames = frames
		anim.play("default")
		
		# Desincronizar animación (frame inicial aleatorio)
		var frame_count := frames.get_frame_count("default")
		if frame_count > 0:
			anim.frame = randi() % frame_count
		
		# Variación de velocidad para naturalidad
		anim.speed_scale = randf_range(0.9, 1.1)
		
		# Pivot bottom-center (AnimatedSprite2D usa offset)
		var first_frame := frames.get_frame_texture("default", 0)
		if first_frame:
			var sz := first_frame.get_size()
			anim.offset = Vector2(0, -sz.y / 2.0)
		
		return anim
		
	else:
		# Decoración estática (PNG normal)
		var spr := Sprite2D.new()
		var tex: Texture2D = load(tex_path)
		
		if tex == null:
			push_error("❌ [DecorFactory] No se pudo cargar textura: %s" % tex_path)
			return null
		
		spr.texture = tex
		
		# Pivot bottom-center (Sprite2D usa offset)
		var sz := tex.get_size()
		spr.offset = Vector2(0, -sz.y / 2.0)
		
		return spr

## Crear decoración con escala y modulación personalizadas
static func make_decor_styled(
	tex_path: String,
	scale_factor: Vector2 = Vector2.ONE,
	modulate_color: Color = Color.WHITE,
	base_fps: float = 5.0
) -> Node2D:
	"""
	Versión extendida de make_decor() con estilo personalizado.
	"""
	var decor := make_decor(tex_path, base_fps)
	
	if decor:
		decor.scale = scale_factor
		decor.modulate = modulate_color
	
	return decor

## Validar si una ruta es un spritesheet válido
static func is_valid_spritesheet(tex_path: String) -> bool:
	"""
	Verifica si un archivo sigue la convención de spritesheet.
	"""
	var re := RegEx.new()
	re.compile("_sheet_f(\\d+)_([0-9]+)\\.png$")
	return re.search(tex_path) != null

## Extraer información del nombre del spritesheet
static func parse_spritesheet_info(tex_path: String) -> Dictionary:
	"""
	Extrae información del nombre del spritesheet.
	
	Retorna:
	{
		"valid": bool,
		"frames": int,
		"size": int,
		"name": String
	}
	"""
	var re := RegEx.new()
	re.compile("_sheet_f(\\d+)_([0-9]+)\\.png$")
	var m := re.search(tex_path)
	
	if m:
		return {
			"valid": true,
			"frames": int(m.get_string(1)),
			"size": int(m.get_string(2)),
			"name": tex_path.get_file().get_basename()
		}
	else:
		return {
			"valid": false,
			"frames": 0,
			"size": 0,
			"name": ""
		}

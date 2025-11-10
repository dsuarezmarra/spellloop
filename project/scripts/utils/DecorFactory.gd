# DecorFactory.gd
# Fabricador de decoraciones estáticas y animadas para biomas
# Detecta automáticamente el tipo por nombre de archivo y crea el nodo apropiado
class_name DecorFactory
extends Node

## Crear decoración (estática o animada) desde una ruta de textura
## Detecta automáticamente si es spritesheet por el patrón "_sheet_f"
static func make_decor(
	tex_path: String, 
	base_fps: float = 5.0, 
	use_integration_shader: bool = true,
	biome_name: String = ""
) -> Node2D:
	"""
	Crea un nodo de decoración (Sprite2D o AnimatedSprite2D).
	
	Parámetros:
	- tex_path: Ruta a la textura (PNG estático o spritesheet)
	- base_fps: FPS base para animaciones (default 5.0)
	- use_integration_shader: Aplicar shader de integración con suelo (default true)
	- biome_name: Nombre del bioma (ej: "Lava", "Snow") para configurar shader
	
	Retorna:
	- AnimatedSprite2D si es spritesheet (*_sheet_fN_SIZE.png)
	- Sprite2D si es textura estática
	
	Características:
	- Pivot: bottom-center (para que "planten" en el suelo)
	- Animaciones desincronizadas (frame inicial aleatorio)
	- Speed variado (0.9-1.1x) para naturalidad
	- Shader de integración: sombra + fundido en base (ajustado por bioma)
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
		
		# Aplicar shader de integración
		if use_integration_shader:
			_apply_integration_shader(anim, biome_name)
		
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
		
		# Aplicar shader de integración
		if use_integration_shader:
			_apply_integration_shader(spr, biome_name)
		
		return spr

## Aplicar shader de integración con el suelo
static func _apply_integration_shader(node: CanvasItem, biome_name: String = "") -> void:
	"""
	Aplica shader para integrar decoración con el suelo:
	- Sombra sutil en la base
	- Fundido gradual en la parte inferior
	- Tinte adaptado al bioma
	
	Configuraciones por bioma:
	- Lava: Naranja cálido (1.0, 0.85, 0.6)
	- Snow: Azul frío (0.85, 0.9, 1.0)
	- Forest: Verde natural (0.8, 0.95, 0.8)
	- Desert: Amarillo arena (1.0, 0.95, 0.7)
	- Default: Blanco neutro (1.0, 1.0, 1.0)
	"""
	var shader_path = "res://assets/shaders/decor_integration.gdshader"
	
	if not ResourceLoader.exists(shader_path):
		push_warning("⚠️ [DecorFactory] Shader de integración no encontrado: %s" % shader_path)
		return
	
	var shader = load(shader_path)
	var material = ShaderMaterial.new()
	material.shader = shader
	
	# Configuración según el bioma
	var tint_color: Color
	var shadow_intensity: float
	var shadow_height: float
	var base_fade: float
	
	match biome_name.to_lower():
		"lava":
			tint_color = Color(1.0, 0.85, 0.6, 1.0)  # Naranja cálido
			shadow_intensity = 0.4
			shadow_height = 0.25
			base_fade = 0.12
		
		"snow", "ice":
			tint_color = Color(0.85, 0.9, 1.0, 1.0)  # Azul frío
			shadow_intensity = 0.25  # Sombra más suave (nieve refleja)
			shadow_height = 0.2
			base_fade = 0.15  # Más fundido en nieve
		
		"forest", "grass":
			tint_color = Color(0.8, 0.95, 0.8, 1.0)  # Verde natural
			shadow_intensity = 0.35
			shadow_height = 0.22
			base_fade = 0.1
		
		"desert", "sand":
			tint_color = Color(1.0, 0.95, 0.7, 1.0)  # Amarillo arena
			shadow_intensity = 0.45  # Sombra más marcada (sol fuerte)
			shadow_height = 0.2
			base_fade = 0.08
		
		"cave", "stone":
			tint_color = Color(0.7, 0.7, 0.75, 1.0)  # Gris piedra
			shadow_intensity = 0.5  # Sombras oscuras
			shadow_height = 0.3
			base_fade = 0.1
		
		_:  # Default / desconocido
			tint_color = Color(1.0, 1.0, 1.0, 1.0)  # Blanco neutro
			shadow_intensity = 0.3
			shadow_height = 0.2
			base_fade = 0.12
	
	material.set_shader_parameter("biome_tint", tint_color)
	material.set_shader_parameter("shadow_intensity", shadow_intensity)
	material.set_shader_parameter("shadow_height", shadow_height)
	material.set_shader_parameter("base_fade", base_fade)
	
	node.material = material

## Crear decoración con escala y modulación personalizadas
static func make_decor_styled(
	tex_path: String,
	scale_factor: Vector2 = Vector2.ONE,
	modulate_color: Color = Color.WHITE,
	base_fps: float = 5.0,
	use_integration_shader: bool = true,
	biome_name: String = ""
) -> Node2D:
	"""
	Versión extendida de make_decor() con estilo personalizado.
	"""
	var decor := make_decor(tex_path, base_fps, use_integration_shader, biome_name)
	
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

class_name WarningIndicator
extends Node2D

## Indicador visual de advertencia para ataques AOE
## Usa los spritesheets de telegraph procesados
##
## Tipos soportados: circle_warning, meteor_warning, charge_line, rune_prison

@export var telegraph_type: String = "circle_warning"

var radius: float = 100.0
var duration: float = 1.0
var warning_color: Color = Color(1.0, 0.2, 0.2, 0.6)
var auto_cleanup: bool = true
var _current_time: float = 0.0

var _sprite: Sprite2D
var _fill_sprite: Sprite2D
var _config: Dictionary

# Configuración de spritesheets de telegraph
const TELEGRAPH_SHEETS = {
	"circle_warning": {
		"path": "res://assets/vfx/abilities/telegraphs/telegraph_circle_warning_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128)
	},
	"meteor_warning": {
		"path": "res://assets/vfx/abilities/telegraphs/telegraph_meteor_warning_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128)
	},
	"charge_line": {
		"path": "res://assets/vfx/abilities/telegraphs/telegraph_charge_line_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128)
	},
	"rune_prison": {
		"path": "res://assets/vfx/abilities/telegraphs/telegraph_rune_prison_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128)
	}
}

func setup(r: float, d: float, c: Color = Color(1.0, 0.2, 0.2, 0.6), type: String = "circle_warning") -> void:
	radius = r
	duration = d
	warning_color = c
	telegraph_type = type

func _ready() -> void:
	z_index = -1
	_setup_visuals()

func _setup_visuals() -> void:
	_config = TELEGRAPH_SHEETS.get(telegraph_type, TELEGRAPH_SHEETS["circle_warning"])
	
	# Cargar textura
	var tex = load(_config["path"])
	
	if tex:
		_setup_sprite_visual(tex)
	else:
		push_warning("[WarningIndicator] Textura no encontrada: %s, usando fallback" % _config["path"])
		_setup_fallback_visual()

func _setup_sprite_visual(tex: Texture2D) -> void:
	# Sprite principal (borde/estático)
	_sprite = Sprite2D.new()
	_sprite.texture = tex
	_sprite.hframes = _config["hframes"]
	_sprite.vframes = _config["vframes"]
	_sprite.centered = true
	_sprite.modulate = warning_color
	
	# Escalar al radio deseado
	var frame_size = _config["frame_size"]
	var scale_factor = (radius * 2) / frame_size.x
	_sprite.scale = Vector2(scale_factor, scale_factor)
	
	add_child(_sprite)
	
	# Sprite de relleno (expande durante el warning)
	_fill_sprite = Sprite2D.new()
	_fill_sprite.texture = tex
	_fill_sprite.hframes = _config["hframes"]
	_fill_sprite.vframes = _config["vframes"]
	_fill_sprite.centered = true
	_fill_sprite.modulate = Color(warning_color.r, warning_color.g, warning_color.b, 0.4)
	_fill_sprite.scale = Vector2.ZERO
	
	add_child(_fill_sprite)

func _setup_fallback_visual() -> void:
	# Fallback: dibujar círculo procedural
	queue_redraw()

func _process(delta: float) -> void:
	_current_time += delta
	if _current_time >= duration:
		if auto_cleanup:
			queue_free()
			return
		_current_time = duration
	
	var progress = clampf(_current_time / duration, 0.0, 1.0)
	
	if _sprite:
		# Animar frame basado en progreso
		var total_frames = _config["hframes"] * _config["vframes"]
		_sprite.frame = int(progress * (total_frames - 1))
		
		# Pulso en el alpha
		var pulse = 0.7 + 0.3 * sin(_current_time * 12.0)
		_sprite.modulate.a = warning_color.a * pulse
	
	if _fill_sprite and _sprite:
		# Expandir el fill
		_fill_sprite.scale = _sprite.scale * progress
		_fill_sprite.frame = _sprite.frame
	
	# Redibujar fallback si no hay sprites
	if not _sprite:
		queue_redraw()

func _draw() -> void:
	# Solo dibujar si no tenemos sprites (fallback)
	if _sprite:
		return
	
	var progress = clampf(_current_time / duration, 0.0, 1.0)
	var pulse = 0.7 + 0.3 * sin(_current_time * 12.0)
	
	# Círculo exterior
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(warning_color.r, warning_color.g, warning_color.b, warning_color.a * pulse), 3.0)
	
	# Círculo interior que crece
	draw_circle(Vector2.ZERO, radius * progress, Color(warning_color.r, warning_color.g, warning_color.b, 0.3 * pulse))

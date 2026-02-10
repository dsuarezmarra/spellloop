class_name VFX_AOE_Impact
extends Node2D

## Efecto visual de impacto AOE
## Usa los spritesheets procesados via VFXManager
## 
## Configurar via: setup(aoe_type, radius, duration)

@export var aoe_type: String = "arcane_nova"
@export var radius: float = 100.0
@export var duration: float = 0.5

var _sprite: Sprite2D
var _config: Dictionary

# Configuración local de spritesheets (fallback si VFXManager no disponible)
const AOE_SHEETS = {
	"arcane_nova": {
		"path": "res://assets/vfx/abilities/aoe/arcane/aoe_arcane_nova_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128)
	},
	"fire_stomp": {
		"path": "res://assets/vfx/abilities/aoe/fire/aoe_fire_stomp_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128)
	},
	"void_explosion": {
		"path": "res://assets/vfx/abilities/aoe/void/aoe_void_explosion_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128)
	},
	"ground_slam": {
		"path": "res://assets/vfx/abilities/aoe/earth/aoe_ground_slam_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128)
	},
	"rune_blast": {
		"path": "res://assets/vfx/abilities/aoe/rune/aoe_rune_blast_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(128, 128)
	},
	"fire_zone": {
		"path": "res://assets/vfx/abilities/aoe/fire/aoe_fire_zone_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(256, 256)
	},
	"freeze_zone": {
		"path": "res://assets/vfx/abilities/aoe/ice/aoe_freeze_zone_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(256, 256)
	},
	"meteor_impact": {
		"path": "res://assets/vfx/abilities/aoe/fire/aoe_meteor_impact_spritesheet.png",
		"hframes": 4, "vframes": 2, "frame_size": Vector2(256, 256)
	}
}

func _ready() -> void:
	z_index = 5
	_setup_visual()

func setup(p_aoe_type: String, p_radius: float = 100.0, p_duration: float = 0.5) -> void:
	"""Configurar el efecto antes de añadir al árbol"""
	aoe_type = p_aoe_type
	radius = p_radius
	duration = p_duration

func _setup_visual() -> void:
	# Obtener configuración
	_config = AOE_SHEETS.get(aoe_type, AOE_SHEETS["arcane_nova"])
	
	# Cargar textura
	var tex = load(_config["path"])
	if not tex:
		push_warning("[VFX_AOE_Impact] Textura no encontrada: %s" % _config["path"])
		_draw_fallback()
		return
	
	# Crear sprite animado
	_sprite = Sprite2D.new()
	_sprite.texture = tex
	_sprite.hframes = _config["hframes"]
	_sprite.vframes = _config["vframes"]
	_sprite.centered = true
	
	# Escalar al radio deseado
	var frame_size = _config["frame_size"]
	var scale_factor = (radius * 2) / frame_size.x
	_sprite.scale = Vector2(scale_factor, scale_factor)
	
	add_child(_sprite)
	
	# Animar frames
	var total_frames = _config["hframes"] * _config["vframes"]
	var tween = create_tween()
	tween.tween_property(_sprite, "frame", total_frames - 1, duration).from(0)
	tween.tween_callback(queue_free)

func _draw_fallback() -> void:
	"""Fallback visual si no hay spritesheet - color neutro, NO púrpura"""
	var visual = Node2D.new()
	add_child(visual)
	
	# Clamp radius to prevent screen-covering effects
	var clamped_r = minf(radius, 150.0)
	
	var anim = 0.0
	visual.draw.connect(func():
		var r = clamped_r * anim
		# Círculos concéntricos - color naranja/blanco neutro en vez de púrpura
		for i in range(2):
			var layer_r = r * (1.0 - i * 0.25)
			var alpha = (1.0 - anim) * (0.4 - i * 0.15)
			visual.draw_circle(Vector2.ZERO, layer_r, Color(1.0, 0.6, 0.3, alpha * 0.15))
			visual.draw_arc(Vector2.ZERO, layer_r, 0, TAU, 32, Color(1.0, 0.8, 0.5, alpha * 0.3), 1.5)
	)
	
	var tween = create_tween()
	tween.tween_method(func(v):
		anim = v
		if is_instance_valid(visual):
			visual.queue_redraw()
	, 0.0, 1.0, duration)
	tween.tween_callback(queue_free)

func _draw() -> void:
	pass

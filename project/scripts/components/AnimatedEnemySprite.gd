# AnimatedEnemySprite.gd
# Componente para animar sprites de enemigos con 3 poses (frente, lado, espalda)
# Usa animación procedural: bobbing, breathing, y flip para dirección
#
# Formato de spritesheet esperado: 1 fila × 3 columnas
# [FRENTE] [LADO_IZQ] [ESPALDA]

extends Sprite2D
class_name AnimatedEnemySprite

# === CONFIGURACIÓN ===
@export var enable_bobbing: bool = true
@export var enable_breathing: bool = true
@export var bobbing_speed: float = 3.0
@export var bobbing_amount: float = 2.0
@export var breathing_speed: float = 2.0
@export var breathing_amount: float = 0.03
@export var sprite_scale: float = 0.2:
	set(value):
		sprite_scale = value
		base_scale = Vector2(value, value)
		scale = base_scale

# === ESTADO INTERNO ===
var spritesheet_texture: Texture2D = null
var frame_textures: Array[Texture2D] = []  # [frente, lado, espalda]
var frame_width: int = 0
var frame_height: int = 0

var current_direction: String = "down"  # down, left, right, up
var base_position: Vector2 = Vector2.ZERO
var base_scale: Vector2 = Vector2.ONE
var animation_time: float = 0.0

# Direcciones mapeadas a frames
# down = frente (0), left = lado (1), right = lado flipped (1), up = espalda (2)
const DIRECTION_TO_FRAME = {
	"down": 0,
	"left": 1,
	"right": 1,
	"up": 2
}

func _ready() -> void:
	base_position = position
	base_scale = scale
	# Randomizar tiempo inicial para que no todos los enemigos estén sincronizados
	animation_time = randf() * TAU

func _process(delta: float) -> void:
	animation_time += delta
	
	if enable_bobbing:
		_apply_bobbing()
	
	if enable_breathing:
		_apply_breathing()

func load_spritesheet(path: String) -> bool:
	"""Cargar un spritesheet de 3 poses y dividirlo en frames"""
	if not ResourceLoader.exists(path):
		push_warning("[AnimatedEnemySprite] Spritesheet no encontrado: %s" % path)
		return false
	
	spritesheet_texture = load(path)
	if not spritesheet_texture:
		push_warning("[AnimatedEnemySprite] Error al cargar: %s" % path)
		return false
	
	# Calcular tamaño de cada frame (3 columnas, 1 fila)
	var img_width = spritesheet_texture.get_width()
	var img_height = spritesheet_texture.get_height()
	
	frame_width = img_width / 3
	frame_height = img_height
	
	# Extraer los 3 frames como texturas separadas
	frame_textures.clear()
	var source_image = spritesheet_texture.get_image()
	
	for i in range(3):
		var frame_rect = Rect2i(i * frame_width, 0, frame_width, frame_height)
		var frame_image = source_image.get_region(frame_rect)
		var frame_tex = ImageTexture.create_from_image(frame_image)
		frame_textures.append(frame_tex)
	
	# Mostrar frame frontal por defecto
	texture = frame_textures[0]
	centered = true
	
	print("[AnimatedEnemySprite] ✓ Cargado: %s (%dx%d por frame)" % [path, frame_width, frame_height])
	return true

func set_direction(direction: Vector2) -> void:
	"""Establecer dirección basada en vector de movimiento"""
	if direction.length() < 0.1:
		return
	
	var new_direction: String
	
	# Determinar dirección predominante
	if abs(direction.x) > abs(direction.y):
		new_direction = "right" if direction.x > 0 else "left"
	else:
		new_direction = "down" if direction.y > 0 else "up"
	
	if new_direction != current_direction:
		current_direction = new_direction
		_update_frame()

func set_direction_string(direction: String) -> void:
	"""Establecer dirección directamente por nombre"""
	if direction in DIRECTION_TO_FRAME and direction != current_direction:
		current_direction = direction
		_update_frame()

func _update_frame() -> void:
	"""Actualizar el frame y flip según la dirección"""
	if frame_textures.is_empty():
		return
	
	var frame_index = DIRECTION_TO_FRAME.get(current_direction, 0)
	texture = frame_textures[frame_index]
	
	# Flip horizontal para dirección derecha
	flip_h = (current_direction == "right")

func _apply_bobbing() -> void:
	"""Aplicar movimiento de bobbing (arriba/abajo)"""
	var bob_offset = sin(animation_time * bobbing_speed) * bobbing_amount
	position.y = base_position.y + bob_offset

func _apply_breathing() -> void:
	"""Aplicar efecto de respiración (escala sutil)"""
	var breath_scale = 1.0 + sin(animation_time * breathing_speed) * breathing_amount
	scale = base_scale * breath_scale

func set_base_scale(new_scale: Vector2) -> void:
	"""Establecer escala base (para que breathing funcione correctamente)"""
	base_scale = new_scale
	scale = new_scale

func get_frame_size() -> Vector2:
	"""Obtener tamaño de un frame individual"""
	return Vector2(frame_width, frame_height)

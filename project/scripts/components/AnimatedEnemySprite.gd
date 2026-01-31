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
@export var enable_squash_stretch: bool = true  # Squash & stretch sincronizado con bobbing
@export var enable_sway: bool = true             # Balanceo lateral sutil
@export var bobbing_speed: float = 4.0           # Velocidad del rebote
@export var bobbing_amount: float = 6.0          # Píxeles de rebote (aumentado)
@export var breathing_speed: float = 2.0         # Velocidad de respiración
@export var breathing_amount: float = 0.05       # 5% de escala (reducido a la mitad)
@export var squash_amount: float = 0.08          # 8% de squash/stretch
@export var sway_speed: float = 2.5              # Velocidad del balanceo
@export var sway_amount: float = 3.0             # Grados de rotación
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
var base_scale: Vector2 = Vector2.ONE
var animation_time: float = 0.0
var direction_locked: bool = false  # Si true, set_direction() no hace nada

# Direcciones mapeadas a frames
# down = frente (0), left = lado (1), right = lado flipped (1), up = espalda (2)
const DIRECTION_TO_FRAME = {
	"down": 0,
	"left": 1,
	"right": 1,
	"up": 2
}

func _ready() -> void:
	base_scale = scale if scale != Vector2.ZERO else Vector2.ONE
	# Randomizar tiempo inicial para que no todos los enemigos estén sincronizados
	animation_time = randf() * TAU

func _process(delta: float) -> void:
	animation_time += delta
	
	# Resetear transformaciones
	offset = Vector2.ZERO
	rotation = 0.0
	scale = base_scale
	
	# Aplicar animaciones
	var bob_phase = sin(animation_time * bobbing_speed)
	
	if enable_bobbing:
		_apply_bobbing(bob_phase)
	
	if enable_squash_stretch:
		_apply_squash_stretch(bob_phase)
	
	if enable_breathing:
		_apply_breathing()
	
	if enable_sway:
		_apply_sway()

func load_spritesheet(path: String) -> bool:
	"""Cargar un spritesheet de 3 poses con gaps de 8px y extraer frames"""
	# VERIFICAR CACHE EN RESOURCE MANAGER
	var rm = null
	var tree = null
	if is_inside_tree():
		tree = get_tree()
	
	if tree:
		rm = tree.get_first_node_in_group("resource_manager")

	var cached_regions = []
	if rm and rm.has_method("get_cached_regions"):
		cached_regions = rm.get_cached_regions(path)
	
	# CARGAR TEXTURA (Usar cache si existe en RM o cargar)
	if rm and rm.has_method("get_resource"):
		spritesheet_texture = rm.get_resource(path)
	
	if not spritesheet_texture:
		if not ResourceLoader.exists(path):
			push_warning("[AnimatedEnemySprite] Spritesheet no encontrado: %s" % path)
			return false
		spritesheet_texture = load(path)
	
	if not spritesheet_texture:
		push_warning("[AnimatedEnemySprite] Error al cargar: %s" % path)
		return false
	
	# OBTENER REGIONES (Cache o Calcular)
	var sprite_regions = []
	
	if not cached_regions.is_empty():
		sprite_regions = cached_regions
		# Debug desactivado: print("⚡ [AnimatedEnemySprite] Usando regiones en caché para %s" % path)
	else:
		# CALCULO COSTOSO (Solo la primera vez)
		var img = spritesheet_texture.get_image()
		var img_width = img.get_width()
		var img_height = img.get_height()
		
		# Encontrar las 3 regiones de sprites detectando columnas con contenido
		sprite_regions = _detect_sprite_regions(img)
		
		# Validar y Cachear
		if sprite_regions.size() != 3:
			push_warning("[AnimatedEnemySprite] No se detectaron 3 sprites, usando división simple")
			var simple_width = float(img_width) / 3.0
			sprite_regions = [
				Rect2(0, 0, simple_width, img_height),
				Rect2(simple_width, 0, simple_width, img_height),
				Rect2(simple_width * 2, 0, simple_width, img_height)
			]
		
		# Guardar en Cache
		if rm and rm.has_method("cache_regions"):
			rm.cache_regions(path, sprite_regions)
			print("💾 [AnimatedEnemySprite] Regiones calculadas y cacheadas para %s" % path)

	# Guardar dimensiones del primer frame como referencia
	frame_width = int(sprite_regions[0].size.x)
	frame_height = int(sprite_regions[0].size.y)
	
	# Usar AtlasTexture para cada frame con las regiones detectadas
	frame_textures.clear()
	
	for region in sprite_regions:
		var atlas = AtlasTexture.new()
		atlas.atlas = spritesheet_texture
		atlas.region = region
		atlas.filter_clip = true  # CLAVE: Evita bleeding en los bordes de la región
		frame_textures.append(atlas)
	
	centered = true
	
	# Inicializar con dirección DOWN y aplicar frame
	current_direction = "down"
	flip_h = false
	_update_frame()
	
	# print("[AnimatedEnemySprite] ✓ Cargado: %s (3 sprites detectados)" % path)
	return true

func _detect_sprite_regions(img: Image) -> Array[Rect2]:
	"""Detectar las 3 regiones de sprites en la imagen analizando el canal alpha"""
	var width = img.get_width()
	var height = img.get_height()
	
	# Encontrar columnas con contenido (alpha > 0)
	var columns_with_content: Array[int] = []
	for x in range(width):
		var has_content = false
		for y in range(height):
			if img.get_pixel(x, y).a > 0.01:
				has_content = true
				break
		if has_content:
			columns_with_content.append(x)
	
	if columns_with_content.is_empty():
		return []
	
	# Agrupar columnas consecutivas en regiones
	var regions: Array[Rect2] = []
	var region_start = columns_with_content[0]
	var region_end = columns_with_content[0]
	var y_bounds_loop = Vector2.ZERO # Variable para uso en loop para evitar shadowing
	
	for i in range(1, columns_with_content.size()):
		var col = columns_with_content[i]
		# Si hay un gap de más de 4 píxeles, es una nueva región
		if col - region_end > 4:
			# Encontrar el bounding box vertical para esta región
			y_bounds_loop = _find_vertical_bounds(img, region_start, region_end)
			regions.append(Rect2(region_start, y_bounds_loop.x, region_end - region_start + 1, y_bounds_loop.y - y_bounds_loop.x + 1))
			region_start = col
		region_end = col
	
	# Agregar la última región
	var y_bounds_final = _find_vertical_bounds(img, region_start, region_end)
	regions.append(Rect2(region_start, y_bounds_final.x, region_end - region_start + 1, y_bounds_final.y - y_bounds_final.x + 1))
	
	return regions

func _find_vertical_bounds(img: Image, col_start: int, col_end: int) -> Vector2:
	"""Encontrar el bounding box vertical para un rango de columnas"""
	var height = img.get_height()
	var min_y = height
	var max_y = 0
	
	for x in range(col_start, col_end + 1):
		for y in range(height):
			if img.get_pixel(x, y).a > 0.01:
				min_y = min(min_y, y)
				max_y = max(max_y, y)
	
	return Vector2(min_y, max_y)

func set_direction(direction: Vector2) -> void:
	"""Establecer dirección basada en vector de movimiento (ignorado si direction_locked)"""
	if direction_locked:
		return  # No actualizar si la dirección está bloqueada
	
	if direction.length() < 0.1:
		return
	
	var new_direction: String
	
	# Determinar dirección predominante
	if abs(direction.x) > abs(direction.y):
		new_direction = "right" if direction.x > 0 else "left"
	else:
		new_direction = "down" if direction.y > 0 else "up"
	
	current_direction = new_direction
	_update_frame()

func set_direction_string(direction: String) -> void:
	"""Establecer dirección directamente por nombre (ignorado si direction_locked)"""
	if direction_locked:
		return
	if direction in DIRECTION_TO_FRAME:
		current_direction = direction
		_update_frame()

func force_direction(direction: Vector2, lock: bool = false) -> void:
	"""Forzar cambio de dirección (siempre actualiza). Si lock=true, bloquea actualizaciones automáticas."""
	var new_direction: String
	if abs(direction.x) > abs(direction.y):
		new_direction = "right" if direction.x > 0 else "left"
	else:
		new_direction = "down" if direction.y > 0 else "up"
	current_direction = new_direction
	if lock:
		direction_locked = true
	_update_frame()

func force_direction_string(direction: String, lock: bool = false) -> void:
	"""Forzar cambio de dirección por nombre (siempre actualiza). Si lock=true, bloquea actualizaciones automáticas."""
	if direction in DIRECTION_TO_FRAME:
		current_direction = direction
		if lock:
			direction_locked = true
		_update_frame()

func unlock_direction() -> void:
	"""Desbloquear la dirección para permitir actualizaciones automáticas"""
	direction_locked = false

func _update_frame() -> void:
	"""Actualizar el frame y flip según la dirección"""
	if frame_textures.is_empty():
		return
	
	var frame_index = DIRECTION_TO_FRAME.get(current_direction, 0)
	
	if frame_index < 0 or frame_index >= frame_textures.size():
		return
	
	var new_texture = frame_textures[frame_index]
	if new_texture == null:
		return
	
	# Asignar la nueva textura
	texture = new_texture
	
	# Flip horizontal para dirección derecha
	flip_h = (current_direction == "right")

func _apply_bobbing(bob_phase: float) -> void:
	"""Aplicar movimiento de bobbing (arriba/abajo) usando offset"""
	offset.y += bob_phase * bobbing_amount

func _apply_squash_stretch(bob_phase: float) -> void:
	"""Aplicar squash & stretch sincronizado con el bobbing"""
	# Cuando sube (bob_phase negativo) = stretch (más alto, más delgado)
	# Cuando baja (bob_phase positivo) = squash (más bajo, más ancho)
	var squash = 1.0 + bob_phase * squash_amount
	var stretch = 1.0 - bob_phase * squash_amount * 0.5
	scale.x *= squash
	scale.y *= stretch

func _apply_breathing() -> void:
	"""Aplicar efecto de respiración (escala sutil)"""
	var breath_scale = 1.0 + sin(animation_time * breathing_speed) * breathing_amount
	scale *= breath_scale

func _apply_sway() -> void:
	"""Aplicar balanceo lateral sutil"""
	var sway_angle = sin(animation_time * sway_speed) * deg_to_rad(sway_amount)
	rotation = sway_angle

func set_base_scale(new_scale: Vector2) -> void:
	"""Establecer escala base (para que breathing funcione correctamente)"""
	base_scale = new_scale
	scale = new_scale

func get_frame_size() -> Vector2:
	"""Obtener tamaño de un frame individual"""
	return Vector2(frame_width, frame_height)

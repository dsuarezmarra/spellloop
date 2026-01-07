extends Camera2D
class_name GameCamera

## Cámara del juego con efectos de screen shake y feedback de daño
## Estilo Binding of Isaac: temblor + partículas rojas en bordes

# Configuración de shake
@export var shake_decay: float = 8.0  # Velocidad de decaimiento del shake
@export var max_shake_offset: float = 16.0  # Máximo offset en píxeles

# Estado interno
var _shake_intensity: float = 0.0
var _trauma: float = 0.0  # Sistema de trauma para shake más natural

# Referencias
var _player: Node2D = null
var _damage_vignette: CanvasLayer = null

func _ready() -> void:
	# Configuración básica
	enabled = true
	position_smoothing_enabled = true
	position_smoothing_speed = 5.0

func _process(delta: float) -> void:
	# Aplicar shake
	if _trauma > 0:
		_trauma = maxf(_trauma - delta * shake_decay, 0.0)
		_shake_intensity = _trauma * _trauma  # Cuadrático para más control
		
		# Offset aleatorio
		var shake_offset = Vector2(
			randf_range(-max_shake_offset, max_shake_offset) * _shake_intensity,
			randf_range(-max_shake_offset, max_shake_offset) * _shake_intensity
		)
		offset = shake_offset
	else:
		offset = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	# Seguir al player
	if is_instance_valid(_player):
		global_position = _player.global_position

## Configurar referencia al player
func set_target(target: Node2D) -> void:
	_player = target

## Añadir trauma al sistema de shake
## amount: valor entre 0.0 y 1.0
func add_trauma(amount: float) -> void:
	_trauma = minf(_trauma + amount, 1.0)

## Hacer shake inmediato (para eventos de daño)
## intensity: fuerza del shake (0.0 - 1.0)
## duration: duración base (afectada por decay)
func shake(intensity: float = 0.5, duration: float = 0.15) -> void:
	# Convertir a trauma basado en duración deseada
	# trauma = duration * shake_decay nos da cuánto trauma necesitamos
	var trauma_needed = duration * shake_decay * intensity
	add_trauma(trauma_needed)

## Shake fuerte para daño recibido
func damage_shake(damage_amount: int = 10) -> void:
	# Escalar intensidad basada en daño
	var intensity = clampf(float(damage_amount) / 30.0, 0.15, 0.8)
	shake(intensity, 0.2)

## Shake pequeño para hits menores
func minor_shake() -> void:
	shake(0.1, 0.1)

## Shake grande para eventos importantes (muerte de boss, etc)
func heavy_shake() -> void:
	shake(0.7, 0.4)

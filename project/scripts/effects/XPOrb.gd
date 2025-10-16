extends Area2D
# Orbe de Experiencia que es atraído hacia el jugador

@export var xp_value: int = 5
@export var attraction_speed: float = 200.0
@export var attraction_range: float = 100.0

var player_reference: Node
var is_attracted: bool = false
var scale_manager: Node

func _ready():
	# Configurar señales
	body_entered.connect(_on_body_entered)
	
	# Obtener referencias
	player_reference = get_tree().get_first_node_in_group("player")
	scale_manager = get_node("/root/ScaleManager")
	
	# Configurar sprite temporal
	var sprite = get_node("Sprite")
	if not sprite.texture:
		sprite.modulate = Color.YELLOW
	
	# Configurar collider
	var shape = CircleShape2D.new()
	shape.radius = 12.0 * scale_manager.current_scale
	$CollisionShape2D.shape = shape
	
	# Añadir a grupo para cleanup
	add_to_group("xp_orbs")

func _physics_process(delta):
	if not player_reference:
		return
	
	var distance_to_player = global_position.distance_to(player_reference.global_position)
	
	# Activar atracción si está cerca
	if distance_to_player <= attraction_range * scale_manager.current_scale:
		is_attracted = true
	
	# Moverse hacia el jugador si está atraído
	if is_attracted:
		var direction = (player_reference.global_position - global_position).normalized()
		var speed = attraction_speed * scale_manager.current_scale
		global_position += direction * speed * delta
		
		# Acelerar cuanto más cerca esté
		var speed_multiplier = 1.0 + (1.0 - distance_to_player / (attraction_range * scale_manager.current_scale))
		global_position += direction * speed * speed_multiplier * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		collect_xp()

func collect_xp():
	# Notificar al jugador que ganó XP
	if player_reference and player_reference.has_method("gain_experience"):
		player_reference.gain_experience(xp_value)
	
	# Efecto visual de recolección
	var tween = create_tween()
	tween.parallel().tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	
	await tween.finished
	queue_free()

func setup(value: int, position: Vector2):
	xp_value = value
	global_position = position
	
	# Escalar visualmente según valor
	var size_multiplier = 1.0 + (value / 20.0)  # Más grande = más XP
	scale = Vector2(size_multiplier, size_multiplier)

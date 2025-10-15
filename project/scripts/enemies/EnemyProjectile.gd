extends Area2D
# Proyectil básico de enemigo

var direction: Vector2
var speed: float
var damage: int
var lifetime: float = 5.0
var effect_type: String = ""

func _ready():
	# Configurar señales
	body_entered.connect(_on_body_entered)
	
	# Configurar sprite temporal
	var sprite = get_node("Sprite")
	if not sprite.texture:
		sprite.modulate = Color.ORANGE
	
	# Configurar collider
	var shape = CircleShape2D.new()
	shape.radius = 8.0
	$CollisionShape2D.shape = shape
	
	# Auto-destruir después del tiempo de vida
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = lifetime
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	timer.start()

func _physics_process(delta):
	# Mover en la dirección establecida
	global_position += direction * speed * delta

func setup(dir: Vector2, dmg: int, spd: float, effect: String = ""):
	direction = dir.normalized()
	damage = dmg
	speed = spd
	effect_type = effect
	
	# Rotar sprite hacia la dirección
	rotation = direction.angle()

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Aplicar daño al jugador
		if body.has_method("take_damage"):
			body.take_damage(damage)
		
		# Aplicar efecto especial si existe
		if effect_type != "" and body.has_method("apply_status_effect"):
			match effect_type:
				"slow":
					body.apply_status_effect("slow", 2.0, 1)
				"burn":
					body.apply_status_effect("burn", 3.0, 2)
				"poison":
					body.apply_status_effect("poison", 4.0, 1)
		
		# Efecto visual de impacto
		impact_effect()
		queue_free()

func impact_effect():
	# Efecto simple de destello
	modulate = Color.WHITE
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.1)
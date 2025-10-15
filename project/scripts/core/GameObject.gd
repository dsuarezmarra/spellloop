extends CharacterBody2D
class_name GameObject

# Sistema básico de objetos del juego
# Base para enemigos, proyectiles, etc.

signal destroyed(object)

var health: float = 100.0
var max_health: float = 100.0
var speed: float = 100.0
var damage: float = 10.0
var is_alive: bool = true
var object_type: String = "generic"

# Referencias a nodos
@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

# Efectos de estado
var status_effects: Dictionary = {}

func _ready():
	# Configuración inicial
	max_health = health
	
func _physics_process(delta):
	if not is_alive:
		return
		
	# Procesar efectos de estado
	process_status_effects(delta)
	
	# Movimiento básico
	move_and_slide()

func take_damage(amount: float, source = null):
	if not is_alive:
		return
		
	health -= amount
	
	# Efecto visual de daño
	flash_damage()
	
	if health <= 0:
		die()

func die():
	is_alive = false
	destroyed.emit(self)
	
	# Animación de muerte básica
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	queue_free()

func flash_damage():
	# Efecto visual básico de daño
	var original_color = sprite.modulate
	sprite.modulate = Color.RED
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", original_color, 0.1)

func apply_status_effect(effect_name: String, duration: float, strength: float = 1.0):
	status_effects[effect_name] = {
		"duration": duration,
		"strength": strength
	}

func process_status_effects(delta: float):
	var effects_to_remove = []
	
	for effect_name in status_effects:
		var effect = status_effects[effect_name]
		effect.duration -= delta
		
		# Aplicar efecto
		match effect_name:
			"poison":
				take_damage(effect.strength * delta)
			"slow":
				speed *= (1.0 - effect.strength * 0.5)
			"burn":
				take_damage(effect.strength * 2.0 * delta)
		
		if effect.duration <= 0:
			effects_to_remove.append(effect_name)
	
	# Limpiar efectos expirados
	for effect_name in effects_to_remove:
		status_effects.erase(effect_name)

func set_sprite_texture(texture: Texture2D):
	if sprite:
		sprite.texture = texture

func set_collision_size(size: Vector2):
	if collision and collision.shape:
		collision.shape.size = size
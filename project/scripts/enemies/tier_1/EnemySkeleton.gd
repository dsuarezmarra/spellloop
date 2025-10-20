extends EnemyBase
class_name EnemyTier1Skeleton

# Esqueleto: movimiento LENTO, ataque cercano cadencioso
# Tier 1, velocidad base 50% reducida (de 80 a 40)

func _ready():
	# Establecer enemy_id y enemy_tier ANTES de llamar a super._ready()
	enemy_id = "skeleton"
	enemy_tier = 1
	speed = 40.0  # 50% = 80, pero reducido más porque es tier 1 y lento
	max_hp = 15
	hp = 15
	damage = 5
	exp_value = 1
	attack_range = 40.0
	attack_cooldown = 1.2
	separation_radius = 45.0
	
	# Llamar a _ready de EnemyBase DESPUÉS de configurar parámetros
	super._ready()

func _attempt_attack() -> void:
	"""Ataque del esqueleto: lento pero contundente"""
	can_attack = false
	attack_timer = attack_cooldown
	
	# Dar daño al player si está en rango
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)
	
	# TODO: Añadir animación de ataque y sonido

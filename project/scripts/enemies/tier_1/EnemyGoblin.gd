extends EnemyBase
class_name EnemyTier1Goblin

# Goblin: movimiento RÁPIDO, ataque ágil pero débil
# Tier 1, velocidad base 50% reducida (de 120 a 60)

func _ready():
	# Establecer enemy_id y enemy_tier ANTES de llamar a super._ready()
	enemy_id = "goblin"
	enemy_tier = 1
	speed = 60.0  # 50% = 120, reducido a 60 para tier 1
	max_hp = 10
	hp = 10
	damage = 3
	exp_value = 1
	attack_range = 35.0
	attack_cooldown = 0.8
	separation_radius = 40.0
	
	# Llamar a _ready de EnemyBase DESPUÉS de configurar parámetros
	super._ready()

func _attempt_attack() -> void:
	"""Ataque del goblin: rápido pero con poco daño"""
	can_attack = false
	attack_timer = attack_cooldown
	
	# Dar daño al player si está en rango
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)
	
	# TODO: Añadir efecto visual de ataque rápido (brillo, sonido agudo)

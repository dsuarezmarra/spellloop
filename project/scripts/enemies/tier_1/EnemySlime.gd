extends EnemyBase
class_name EnemyTier1Slime

# Slime: movimiento MODERADO, ataque envolvente (área de efecto)
# Tier 1, velocidad base 50% reducida (de 60 a 30, es el base)

func _ready():
	# Establecer enemy_id y enemy_tier ANTES de llamar a super._ready()
	enemy_id = "slime"
	enemy_tier = 1
	speed = 30.0  # Base tier 1, no reducido más
	max_hp = 25
	hp = 25
	damage = 4
	exp_value = 2
	attack_range = 50.0  # Rango mayor porque es AoE
	attack_cooldown = 1.5
	separation_radius = 50.0  # Ligeramente mayor por su tamaño
	
	# Llamar a _ready de EnemyBase DESPUÉS de configurar parámetros
	super._ready()

func _attempt_attack() -> void:
	"""Ataque del slime: envolvente con área de efecto"""
	can_attack = false
	attack_timer = attack_cooldown
	
	# Ataque AoE: daña al player y otros enemigos cercanos en radio mayor
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)
	
	# TODO: Añadir efecto visual de AoE (onda de energía)
	# TODO: Añadir sonido de ataque viscoso

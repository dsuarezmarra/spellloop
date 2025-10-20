extends EnemyTier2
class_name EnemyTier2GolemRunico

# Gólem Rúnico: Tier 2 - Lento pero muy fuerte

func _ready():
	# Establecer parámetros ANTES de llamar a super._ready()
	enemy_id = "tier_2_golem_runico"
	enemy_tier = 2
	max_hp = 120
	hp = 120
	speed = 28.0  # Muy lento
	damage = 18
	exp_value = 12
	attack_range = 45.0
	attack_cooldown = 1.8
	separation_radius = 55.0
	
	# Llamar a _ready de EnemyTier2 DESPUÉS de configurar parámetros
	super._ready()

func _attempt_attack() -> void:
	can_attack = false
	attack_timer = attack_cooldown
	
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)

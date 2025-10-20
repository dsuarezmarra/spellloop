extends EnemyTier4
class_name EnemyTier4TitanArcano

# Titán Arcano: Tier 4 - Tanque magistral

func _ready():
	# Establecer parámetros ANTES de llamar a super._ready()
	enemy_id = "tier_4_titan_arcano"
	enemy_tier = 4
	max_hp = 550
	hp = 550
	speed = 40.0
	damage = 48
	exp_value = 55
	attack_range = 50.0
	attack_cooldown = 2.5
	separation_radius = 68.0
	
	# Llamar a _ready de EnemyTier4 DESPUÉS de configurar parámetros
	super._ready()

func _attempt_attack() -> void:
	can_attack = false
	attack_timer = attack_cooldown
	
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)

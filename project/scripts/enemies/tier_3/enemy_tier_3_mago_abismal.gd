extends EnemyTier3
class_name EnemyTier3MagoAbismal

# Mago Abismal: Tier 3 - Caster ofensivo

func _ready():
	# Establecer parámetros ANTES de llamar a super._ready()
	enemy_id = "tier_3_mago_abismal"
	enemy_tier = 3
	max_hp = 140
	hp = 140
	speed = 56.0
	damage = 36
	exp_value = 28
	attack_range = 100.0
	attack_cooldown = 2.0
	separation_radius = 50.0
	
	# Llamar a _ready de EnemyTier3 DESPUÉS de configurar parámetros
	super._ready()

func _attempt_attack() -> void:
	can_attack = false
	attack_timer = attack_cooldown
	
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)

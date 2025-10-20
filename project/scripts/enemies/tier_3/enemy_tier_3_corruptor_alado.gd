extends EnemyTier3
class_name EnemyTier3CorruptorAlado

# Corruptor Alado: Tier 3 - Volador rápido

func _ready():
	# Establecer parámetros ANTES de llamar a super._ready()
	enemy_id = "tier_3_corruptor_alado"
	enemy_tier = 3
	max_hp = 160
	hp = 160
	speed = 84.0
	damage = 24
	exp_value = 24
	attack_range = 100.0
	attack_cooldown = 1.3
	separation_radius = 52.0
	
	# Llamar a _ready de EnemyTier3 DESPUÉS de configurar parámetros
	super._ready()

func _attempt_attack() -> void:
	can_attack = false
	attack_timer = attack_cooldown
	
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)

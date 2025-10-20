extends EnemyTier2
class_name EnemyTier2HechiceroDesgastado

# Hechicero Desgastado: Tier 2 - Caster ofensivo

func _ready():
	# Establecer parámetros ANTES de llamar a super._ready()
	enemy_id = "tier_2_hechicero_desgastado"
	enemy_tier = 2
	max_hp = 45
	hp = 45
	speed = 56.0
	damage = 20
	exp_value = 10
	attack_range = 100.0
	attack_cooldown = 2.2
	separation_radius = 48.0
	
	# Llamar a _ready de EnemyTier2 DESPUÉS de configurar parámetros
	super._ready()

func _attempt_attack() -> void:
	can_attack = false
	attack_timer = attack_cooldown
	
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)

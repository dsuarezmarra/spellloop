extends EnemyTier4
class_name EnemyTier4ReinaDelHielo

# Reina del Hielo: Tier 4 - Controladora de elementos

func _ready():
	# Establecer parámetros ANTES de llamar a super._ready()
	enemy_id = "tier_4_reina_del_hielo"
	enemy_tier = 4
	max_hp = 450
	hp = 450
	speed = 52.0
	damage = 58
	exp_value = 52
	attack_range = 90.0
	attack_cooldown = 2.2
	separation_radius = 62.0
	
	# Llamar a _ready de EnemyTier4 DESPUÉS de configurar parámetros
	super._ready()

func _attempt_attack() -> void:
	can_attack = false
	attack_timer = attack_cooldown
	
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)

extends EnemyTier4
class_name EnemyTier4DragonEtereo

# Dragón Etéreo: Tier 4 - Volador de poder extremo

func _ready():
	# Establecer parámetros ANTES de llamar a super._ready()
	enemy_id = "tier_4_dragon_etereo"
	enemy_tier = 4
	max_hp = 500
	hp = 500
	speed = 68.0
	damage = 52
	exp_value = 55
	attack_range = 100.0
	attack_cooldown = 2.0
	separation_radius = 65.0
	
	# Llamar a _ready de EnemyTier4 DESPUÉS de configurar parámetros
	super._ready()

func _attempt_attack() -> void:
	can_attack = false
	attack_timer = attack_cooldown
	
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)

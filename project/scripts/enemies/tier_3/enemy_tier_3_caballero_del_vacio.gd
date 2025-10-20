extends EnemyTier3
class_name EnemyTier3CaballeroDelVacio

# Caballero del Vacío: Tier 3 - Tank melee

func _ready():
	# Establecer parámetros ANTES de llamar a super._ready()
	enemy_id = "tier_3_caballero_del_vacio"
	enemy_tier = 3
	max_hp = 220
	hp = 220
	speed = 36.0
	damage = 28
	exp_value = 30
	attack_range = 45.0
	attack_cooldown = 1.6
	separation_radius = 55.0
	
	# Llamar a _ready de EnemyTier3 DESPUÉS de configurar parámetros
	super._ready()

func _attempt_attack() -> void:
	can_attack = false
	attack_timer = attack_cooldown
	
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)

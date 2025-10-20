extends EnemyTier4
class_name EnemyTier4ArchmagoPerdido

# Archimago Perdido: Tier 4 - Mago supremo

func _ready():
	# Establecer parámetros ANTES de llamar a super._ready()
	enemy_id = "tier_4_archimago_perdido"
	enemy_tier = 4
	max_hp = 400
	hp = 400
	speed = 48.0
	damage = 55
	exp_value = 50
	attack_range = 120.0
	attack_cooldown = 2.5
	separation_radius = 60.0
	
	# Llamar a _ready de EnemyTier4 DESPUÉS de configurar parámetros
	super._ready()

func _attempt_attack() -> void:
	can_attack = false
	attack_timer = attack_cooldown
	
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)

extends EnemyTier4
class_name EnemyTier4SenorDeLasLlamas

# Señor de las Llamas: Tier 4 - Controlador del fuego

func _ready():
	# Establecer parámetros ANTES de llamar a super._ready()
	enemy_id = "tier_4_senor_de_las_llamas"
	enemy_tier = 4
	max_hp = 420
	hp = 420
	speed = 60.0
	damage = 60
	exp_value = 50
	attack_range = 80.0
	attack_cooldown = 2.0
	separation_radius = 60.0
	
	# Llamar a _ready de EnemyTier4 DESPUÉS de configurar parámetros
	super._ready()

func _attempt_attack() -> void:
	can_attack = false
	attack_timer = attack_cooldown
	
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)

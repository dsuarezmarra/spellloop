extends EnemyTier2
class_name EnemyTier2LoboDeCristal

# Lobo de Cristal: Tier 2 - Rápido y ágil

func _ready():
	# Establecer parámetros ANTES de llamar a super._ready()
	enemy_id = "tier_2_lobo_de_cristal"
	enemy_tier = 2
	max_hp = 70
	hp = 70
	speed = 72.0  # Muy rápido
	damage = 14
	exp_value = 9
	attack_range = 40.0
	attack_cooldown = 1.0
	separation_radius = 45.0
	
	# Llamar a _ready de EnemyTier2 DESPUÉS de configurar parámetros
	super._ready()

func _attempt_attack() -> void:
	can_attack = false
	attack_timer = attack_cooldown
	
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)

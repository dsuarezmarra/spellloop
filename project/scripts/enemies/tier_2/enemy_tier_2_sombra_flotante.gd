extends EnemyTier2
class_name EnemyTier2SombraFlotante

# Sombra Flotante: Tier 2 - Velocidad media-baja con movimiento especial

func _ready():
	# Establecer parámetros ANTES de llamar a super._ready()
	enemy_id = "tier_2_sombra_flotante"
	enemy_tier = 2
	max_hp = 50
	hp = 50
	speed = 64.0 * 0.85  # Movimiento más lento
	damage = 16
	exp_value = 7
	attack_range = 40.0
	attack_cooldown = 1.6
	separation_radius = 48.0
	
	# Llamar a _ready de EnemyTier2 DESPUÉS de configurar parámetros
	super._ready()

func _attempt_attack() -> void:
	can_attack = false
	attack_timer = attack_cooldown
	
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)

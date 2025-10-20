extends EnemyTier3
class_name EnemyTier3SerpienteDeFuego

# Serpiente de Fuego: Tier 3 - DoT ofensivo

func _ready():
	# Establecer parámetros ANTES de llamar a super._ready()
	enemy_id = "tier_3_serpiente_de_fuego"
	enemy_tier = 3
	max_hp = 180
	hp = 180
	speed = 72.0
	damage = 26
	exp_value = 26
	attack_range = 50.0
	attack_cooldown = 1.5
	separation_radius = 50.0
	
	# Llamar a _ready de EnemyTier3 DESPUÉS de configurar parámetros
	super._ready()

func _attempt_attack() -> void:
	can_attack = false
	attack_timer = attack_cooldown
	
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)

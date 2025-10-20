extends EnemyTier3
class_name EnemyTier3ElementalDeHielo

# Elemental de Hielo: Tier 3 - Controlador de campo

func _ready():
	# Establecer parámetros ANTES de llamar a super._ready()
	enemy_id = "tier_3_elemental_de_hielo"
	enemy_tier = 3
	max_hp = 200
	hp = 200
	speed = 48.0
	damage = 32
	exp_value = 32
	attack_range = 70.0
	attack_cooldown = 1.8
	separation_radius = 58.0
	
	# Llamar a _ready de EnemyTier3 DESPUÉS de configurar parámetros
	super._ready()

func _attempt_attack() -> void:
	can_attack = false
	attack_timer = attack_cooldown
	
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)

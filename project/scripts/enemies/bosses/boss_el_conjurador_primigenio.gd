extends EnemyBoss
class_name BossElConjuradorPrimigenio

# El Conjurador Primigenio - Boss supremo de magia caótica

func _ready():
	# Establecer parámetros ANTES de llamar a super._ready()
	enemy_id = "boss_el_conjurador"
	enemy_tier = 5
	max_hp = 1800
	hp = 1800
	speed = 44.0
	damage = 120
	exp_value = 1000
	attack_range = 100.0
	attack_cooldown = 2.5
	separation_radius = 70.0
	
	# Llamar a _ready de EnemyBoss DESPUÉS de configurar parámetros
	super._ready()

func _attempt_attack() -> void:
	can_attack = false
	attack_timer = attack_cooldown
	
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)

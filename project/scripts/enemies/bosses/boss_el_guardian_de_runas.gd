extends EnemyBoss
class_name BossElGuardianDeRunas

# El Guardián de Runas - Boss protector arcano

func _ready():
	# Establecer parámetros ANTES de llamar a super._ready()
	enemy_id = "boss_el_guardian"
	enemy_tier = 5
	max_hp = 1600
	hp = 1600
	speed = 40.0
	damage = 110
	exp_value = 900
	attack_range = 90.0
	attack_cooldown = 2.2
	separation_radius = 72.0
	
	# Llamar a _ready de EnemyBoss DESPUÉS de configurar parámetros
	super._ready()

func _attempt_attack() -> void:
	can_attack = false
	attack_timer = attack_cooldown
	
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)

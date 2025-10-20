extends EnemyBoss
class_name BossElCorazonDelVacio

# El Corazón del Vacío - Boss de entropía pura

func _ready():
	# Establecer parámetros ANTES de llamar a super._ready()
	enemy_id = "boss_el_corazon"
	enemy_tier = 5
	max_hp = 2000
	hp = 2000
	speed = 36.0
	damage = 140
	exp_value = 1200
	attack_range = 80.0
	attack_cooldown = 3.0
	separation_radius = 75.0
	
	# Llamar a _ready de EnemyBoss DESPUÉS de configurar parámetros
	super._ready()

func _attempt_attack() -> void:
	can_attack = false
	attack_timer = attack_cooldown
	
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)

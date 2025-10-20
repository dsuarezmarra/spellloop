extends EnemyBoss
class_name BossMinotauroDeFuego

# Minotauro de Fuego - Boss berserker infernal

func _ready():
	# Establecer parámetros ANTES de llamar a super._ready()
	enemy_id = "boss_minotauro"
	enemy_tier = 5
	max_hp = 1700
	hp = 1700
	speed = 56.0
	damage = 130
	exp_value = 950
	attack_range = 60.0
	attack_cooldown = 1.8
	separation_radius = 70.0
	
	# Llamar a _ready de EnemyBoss DESPUÉS de configurar parámetros
	super._ready()

func _attempt_attack() -> void:
	can_attack = false
	attack_timer = attack_cooldown
	
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)

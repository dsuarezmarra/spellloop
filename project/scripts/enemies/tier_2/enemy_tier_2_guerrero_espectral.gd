extends EnemyTier2
class_name EnemyTier2GuerreroSpectral

# Guerrero Espectral: Tier 2 - Melee agresivo con velocidad moderada

func _ready():
	# Establecer parámetros ANTES de llamar a super._ready()
	enemy_id = "tier_2_guerrero_espectral"
	enemy_tier = 2
	max_hp = 60
	hp = 60
	speed = 48.0
	damage = 12
	exp_value = 8
	attack_range = 40.0
	attack_cooldown = 1.4
	separation_radius = 50.0
	
	# Llamar a _ready de EnemyTier2 DESPUÉS de configurar parámetros
	super._ready()
	
	# Reapply scale
	var enemy_scale = 0.2
	var _gt = get_tree()
	if _gt and _gt.root:
		var visual_calibrator = _gt.root.get_node_or_null("VisualCalibrator")
		if visual_calibrator and visual_calibrator.has_method("get_enemy_scale_for_tier"):
			enemy_scale = visual_calibrator.get_enemy_scale_for_tier(enemy_tier)
	
	var sprite = _find_sprite_node(self)
	if sprite:
		sprite.scale = Vector2(enemy_scale, enemy_scale)
		sprite.centered = true

func _attempt_attack() -> void:
	"""Ataque melee agresivo"""
	can_attack = false
	attack_timer = attack_cooldown
	
	if player_ref and is_instance_valid(player_ref):
		if player_ref.has_method("take_damage"):
			player_ref.take_damage(damage)

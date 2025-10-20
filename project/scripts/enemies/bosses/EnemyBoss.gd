extends EnemyBase
class_name EnemyBoss

# Clase base para enemigos Boss (Tier 5)
# Boss: Stats extremos, velocidad variable, daño muy alto
# Escala: 150% del tamaño base

func _ready():
	super._ready()
	
	# Configuración base para bosses
	enemy_tier = 5
	
	# Reapply scale after setting tier
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

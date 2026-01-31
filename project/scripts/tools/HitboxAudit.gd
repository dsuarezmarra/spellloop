@tool
extends SceneTree

# HitboxAudit.gd
# Analyzes Hitbox (Collision) vs Visual (Sprite) coherence for fairness.

var enemy_db = preload("res://scripts/data/EnemyDatabase.gd")

func _init():
	print("🔍 STARTING HITBOX COHERENCE AUDIT...")
	
	# Mock base sprite size (Average 64x64 for analysis)
	var BASE_SPRITE_SIZE = 64.0
	
	var violations = []
	
	var all_enemies = {}
	all_enemies.merge(enemy_db.TIER_1_ENEMIES)
	all_enemies.merge(enemy_db.TIER_2_ENEMIES)
	all_enemies.merge(enemy_db.TIER_3_ENEMIES)
	all_enemies.merge(enemy_db.TIER_4_ENEMIES)
	all_enemies.merge(enemy_db.BOSSES)
	
	print("| Enemy | Tier | Scale | Visual Radius (est) | Hitbox Radius | Ratio | Verdict |")
	print("|---|---|---|---|---|---|---|")
	
	for key in all_enemies:
		var data = all_enemies[key]
		var tier = int(data.get("tier", 1))
		var is_boss = data.get("is_boss", false)
		
		# Replicate EnemyBase._get_scale_for_tier logic
		var scale = 0.35
		match tier:
			1: scale = 0.35
			2: scale = 0.45
			3: scale = 0.55
			4: scale = 0.65
			5: scale = 1.20
		
		# Bosses logic from EnemyBase
		if is_boss: scale *= 2.5
		
		var visual_radius = (BASE_SPRITE_SIZE * scale) / 2.0
		var hitbox_radius = float(data.get("collision_radius", 16.0))
		
		var ratio = hitbox_radius / visual_radius
		
		var verdict = "OK"
		if ratio > 1.2: verdict = "WARNING: GHOST HIT (Hitbox > Visual)"
		if ratio > 1.5: verdict = "CRITICAL: INVISIBLE HITBOX"
		if ratio < 0.6: verdict = "WARNING: HARD TO HIT (Hitbox < Visual)"
		
		if verdict != "OK":
			print("| %s | %d | %.2f | %.1fpx | %.1fpx | %.2f | %s |" % [
				data.get("name", key), tier, scale, visual_radius, hitbox_radius, ratio, verdict
			])
			
	print("\n🔍 AUDIT COMPLETE")
	quit()

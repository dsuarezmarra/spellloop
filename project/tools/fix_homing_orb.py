#!/usr/bin/env python3
"""Fix the _spawn_homing_orb function in EnemyAttackSystem.gd"""

import re

filepath = r'C:\git\loopialike\project\scripts\enemies\EnemyAttackSystem.gd'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

# Find the function boundaries
start_pattern = r'func _spawn_homing_orb\(pos: Vector2, damage: int, speed: float, duration: float, element: String\) -> void:'
end_pattern = r'\nfunc _spawn_orb_impact_effect'

start_match = re.search(start_pattern, content)
end_match = re.search(end_pattern, content)

if not start_match or not end_match:
    print('Function not found!')
    exit(1)

print(f'Found function from char {start_match.start()} to {end_match.start()}')

new_function = '''func _spawn_homing_orb(pos: Vector2, damage: int, speed: float, duration: float, element: String) -> void:
	"""Crear orbe ÉPICO que persigue al jugador - Usa VFXManager para visual"""
	if not is_instance_valid(enemy) or not is_instance_valid(player):
		return
	
	var orb = Node2D.new()
	orb.name = "HomingOrb"
	orb.top_level = true
	orb.global_position = pos
	orb.z_index = 65
	
	# Variables de visual (declaradas a nivel de función para acceso en lambdas)
	var color = _get_element_color(element)
	var bright_color = Color(min(color.r + 0.4, 1.0), min(color.g + 0.4, 1.0), min(color.b + 0.4, 1.0), 1.0)
	var orb_visual: Node2D = null
	var trail_positions: Array = []
	var max_trail = 12
	var orb_time_ref = {"value": 0.0}
	
	# Intentar usar VFXManager para el visual del orbe
	var vfx_mgr = get_node_or_null("/root/VFXManager")
	var using_vfx = false
	if vfx_mgr and vfx_mgr.has_method("spawn_projectile_attached"):
		var sprite = vfx_mgr.spawn_projectile_attached("homing_orb", orb)
		if sprite:
			using_vfx = true
	
	# Visual fallback procedural
	if not using_vfx:
		orb_visual = Node2D.new()
		orb.add_child(orb_visual)
		
		orb_visual.draw.connect(func():
			var pulse = 1.0 + sin(orb_time_ref.value * 8) * 0.25
			
			# Dibujar trail
			for i in range(trail_positions.size()):
				var trail_pos = trail_positions[i] - orb.global_position
				var trail_alpha = float(i) / max_trail * 0.5
				var trail_size = 8 * (float(i) / max_trail)
				orb_visual.draw_circle(trail_pos, trail_size, Color(color.r, color.g, color.b, trail_alpha))
			
			# Glow exterior
			orb_visual.draw_circle(Vector2.ZERO, 35 * pulse, Color(color.r, color.g, color.b, 0.15))
			orb_visual.draw_circle(Vector2.ZERO, 28 * pulse, Color(color.r, color.g, color.b, 0.25))
			orb_visual.draw_circle(Vector2.ZERO, 22 * pulse, Color(color.r, color.g, color.b, 0.4))
			
			# Cuerpo principal
			orb_visual.draw_circle(Vector2.ZERO, 18 * pulse, color)
			
			# Anillo de energía
			var ring_angle = orb_time_ref.value * 5
			orb_visual.draw_arc(Vector2.ZERO, 22 * pulse, ring_angle, ring_angle + PI * 1.5, 16, bright_color, 2.0)
			
			# Núcleo brillante
			orb_visual.draw_circle(Vector2.ZERO, 12 * pulse, bright_color)
			orb_visual.draw_circle(Vector2.ZERO, 6, Color(1, 1, 1, 0.98))
			
			# Partículas orbitando
			for i in range(4):
				var orbit_angle = orb_time_ref.value * 6 + (TAU / 4) * i
				var orbit_pos = Vector2(cos(orbit_angle), sin(orbit_angle)) * 25 * pulse
				orb_visual.draw_circle(orbit_pos, 4, bright_color)
		)
		orb_visual.queue_redraw()
	
	var parent = enemy.get_parent()
	if parent:
		parent.add_child(orb)
	
	_track_boss_effect(orb)
	
	# Variables para tracking
	var time_alive_ref = {"value": 0.0}
	var player_ref = player
	var has_hit_ref = {"value": false}
	var hit_radius = 28.0
	
	# Timer para movimiento
	var timer = Timer.new()
	timer.wait_time = 0.016
	timer.autostart = true
	orb.add_child(timer)
	
	timer.timeout.connect(func():
		if not is_instance_valid(orb) or has_hit_ref.value:
			return
		if not is_instance_valid(player_ref):
			orb.queue_free()
			return
		
		time_alive_ref.value += 0.016
		orb_time_ref.value += 0.016
		
		# Trail
		trail_positions.push_front(orb.global_position)
		if trail_positions.size() > max_trail:
			trail_positions.pop_back()
		
		# Check duración
		if time_alive_ref.value >= duration:
			var tween = orb.create_tween()
			tween.tween_property(orb, "modulate:a", 0.0, 0.4)
			tween.tween_callback(orb.queue_free)
			return
		
		# Mover hacia player
		var dir = (player_ref.global_position - orb.global_position).normalized()
		var current_speed = speed * (1.0 + time_alive_ref.value * 0.3)
		orb.global_position += dir * current_speed * 0.016
		
		# Actualizar visual
		if orb_visual and is_instance_valid(orb_visual):
			orb_visual.queue_redraw()
		
		# Check colisión
		var dist = orb.global_position.distance_to(player_ref.global_position)
		if dist < hit_radius:
			has_hit_ref.value = true
			if player_ref.has_method("take_damage"):
				player_ref.call("take_damage", damage, element)
			_spawn_orb_impact_effect(orb.global_position, color)
			orb.queue_free()
			return
	)

'''

new_content = content[:start_match.start()] + new_function + content[end_match.start():]

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(new_content)

print('Function replaced successfully!')

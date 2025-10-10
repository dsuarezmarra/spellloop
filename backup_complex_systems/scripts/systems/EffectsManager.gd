# EffectsManager.gd
# Central effects manager for visual effects, particles, and screen effects
# Handles spell effects, damage indicators, screen shake, and particle systems
#
# Public API:
# - play_spell_effect(spell_id: String, position: Vector2) -> void
# - play_damage_effect(damage: int, position: Vector2, color: Color) -> void
# - screen_shake(intensity: float, duration: float) -> void
# - play_explosion_effect(position: Vector2, size: float) -> void
#
# Signals:
# - effect_started(effect_id: String, position: Vector2)
# - effect_finished(effect_id: String)

extends Node

signal effect_started(effect_id: String, position: Vector2)
signal effect_finished(effect_id: String)

# Effect scenes and resources
var effect_scenes: Dictionary = {}
var particle_systems: Dictionary = {}

# Screen effects
var screen_shake_tween: Tween
var current_camera: Camera2D

# Effect pools for performance
var damage_text_pool: Array[Node] = []
var particle_pool: Dictionary = {}

func _ready() -> void:
	print("[EffectsManager] Initializing Effects Manager...")
	
	# Initialize effect scenes
	_create_effect_scenes()
	
	# Initialize particle systems
	_initialize_particle_systems()
	
	# Set up damage text pool
	_initialize_damage_text_pool()
	
	print("[EffectsManager] Effects Manager initialized")

func _create_effect_scenes() -> void:
	"""Create programmatic effect scenes since we don't have asset files"""
	# This creates basic particle effects programmatically
	effect_scenes = {
		"fireball_explosion": _create_fireball_effect(),
		"ice_shatter": _create_ice_effect(),
		"lightning_strike": _create_lightning_effect(),
		"shadow_burst": _create_shadow_effect(),
		"healing_glow": _create_healing_effect(),
		"earth_crack": _create_earth_effect(),
		"wind_swirl": _create_wind_effect(),
		"frost_nova": _create_frost_nova_effect(),
		"flame_wave": _create_flame_wave_effect(),
		"thunder_storm": _create_thunder_storm_effect()
	}

func _create_fireball_effect() -> PackedScene:
	"""Create fireball explosion effect"""
	var scene = PackedScene.new()
	var particles = GPUParticles2D.new()
	
	# Configure particles
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 150.0
	material.gravity = Vector3(0, 98, 0)
	material.scale_min = 0.5
	material.scale_max = 1.5
	material.color = Color.ORANGE_RED
	
	particles.process_material = material
	particles.amount = 50
	particles.lifetime = 2.0
	particles.one_shot = true
	particles.emitting = false
	
	scene.pack(particles)
	return scene

func _create_ice_effect() -> PackedScene:
	"""Create ice shatter effect"""
	var scene = PackedScene.new()
	var particles = GPUParticles2D.new()
	
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 30.0
	material.initial_velocity_max = 100.0
	material.gravity = Vector3(0, 98, 0)
	material.scale_min = 0.3
	material.scale_max = 1.0
	material.color = Color.CYAN
	
	particles.process_material = material
	particles.amount = 30
	particles.lifetime = 1.5
	particles.one_shot = true
	particles.emitting = false
	
	scene.pack(particles)
	return scene

func _create_lightning_effect() -> PackedScene:
	"""Create lightning strike effect"""
	var scene = PackedScene.new()
	var line = Line2D.new()
	
	# Create zigzag lightning pattern
	var points = []
	for i in range(10):
		var x = randf_range(-20, 20)
		var y = i * 10
		points.append(Vector2(x, y))
	
	line.points = PackedVector2Array(points)
	line.width = 3.0
	line.default_color = Color.YELLOW
	
	scene.pack(line)
	return scene

func _create_shadow_effect() -> PackedScene:
	"""Create shadow burst effect"""
	var scene = PackedScene.new()
	var particles = GPUParticles2D.new()
	
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, 0, 0)
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 80.0
	material.gravity = Vector3(0, 0, 0)
	material.scale_min = 0.8
	material.scale_max = 2.0
	material.color = Color.PURPLE
	
	particles.process_material = material
	particles.amount = 25
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.emitting = false
	
	scene.pack(particles)
	return scene

func _create_healing_effect() -> PackedScene:
	"""Create healing glow effect"""
	var scene = PackedScene.new()
	var particles = GPUParticles2D.new()
	
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 10.0
	material.initial_velocity_max = 40.0
	material.gravity = Vector3(0, -20, 0)
	material.scale_min = 0.5
	material.scale_max = 1.2
	material.color = Color.LIGHT_GREEN
	
	particles.process_material = material
	particles.amount = 20
	particles.lifetime = 2.5
	particles.one_shot = true
	particles.emitting = false
	
	scene.pack(particles)
	return scene

func _create_earth_effect() -> PackedScene:
	"""Create earth crack effect"""
	var scene = PackedScene.new()
	var particles = GPUParticles2D.new()
	
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 80.0
	material.initial_velocity_max = 120.0
	material.gravity = Vector3(0, 150, 0)
	material.scale_min = 0.4
	material.scale_max = 1.0
	material.color = Color.SADDLE_BROWN
	
	particles.process_material = material
	particles.amount = 40
	particles.lifetime = 1.8
	particles.one_shot = true
	particles.emitting = false
	
	scene.pack(particles)
	return scene

func _create_wind_effect() -> PackedScene:
	"""Create wind swirl effect"""
	var scene = PackedScene.new()
	var particles = GPUParticles2D.new()
	
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(1, 0, 0)
	material.initial_velocity_min = 60.0
	material.initial_velocity_max = 100.0
	material.gravity = Vector3(0, 0, 0)
	material.scale_min = 0.3
	material.scale_max = 0.8
	material.color = Color.LIGHT_CYAN
	
	particles.process_material = material
	particles.amount = 35
	particles.lifetime = 1.2
	particles.one_shot = true
	particles.emitting = false
	
	scene.pack(particles)
	return scene

func _create_frost_nova_effect() -> PackedScene:
	"""Create frost nova combination effect"""
	var scene = PackedScene.new()
	var container = Node2D.new()
	
	# Ice particles
	var ice_particles = GPUParticles2D.new()
	var ice_material = ParticleProcessMaterial.new()
	ice_material.direction = Vector3(0, 0, 0)
	ice_material.initial_velocity_min = 100.0
	ice_material.initial_velocity_max = 200.0
	ice_material.gravity = Vector3(0, 50, 0)
	ice_material.scale_min = 0.5
	ice_material.scale_max = 1.5
	ice_material.color = Color.CYAN
	
	ice_particles.process_material = ice_material
	ice_particles.amount = 60
	ice_particles.lifetime = 2.0
	ice_particles.one_shot = true
	ice_particles.emitting = false
	
	# Wind swirl
	var wind_particles = GPUParticles2D.new()
	var wind_material = ParticleProcessMaterial.new()
	wind_material.direction = Vector3(1, 0, 0)
	wind_material.initial_velocity_min = 80.0
	wind_material.initial_velocity_max = 150.0
	wind_material.gravity = Vector3(0, 0, 0)
	wind_material.scale_min = 0.3
	wind_material.scale_max = 1.0
	wind_material.color = Color.WHITE
	
	wind_particles.process_material = wind_material
	wind_particles.amount = 40
	wind_particles.lifetime = 1.5
	wind_particles.one_shot = true
	wind_particles.emitting = false
	
	container.add_child(ice_particles)
	container.add_child(wind_particles)
	
	scene.pack(container)
	return scene

func _create_flame_wave_effect() -> PackedScene:
	"""Create flame wave combination effect"""
	var scene = PackedScene.new()
	var particles = GPUParticles2D.new()
	
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(1, 0, 0)
	material.initial_velocity_min = 80.0
	material.initial_velocity_max = 150.0
	material.gravity = Vector3(0, 20, 0)
	material.scale_min = 0.8
	material.scale_max = 2.0
	material.color = Color.ORANGE_RED
	
	particles.process_material = material
	particles.amount = 70
	particles.lifetime = 2.5
	particles.one_shot = true
	particles.emitting = false
	
	scene.pack(particles)
	return scene

func _create_thunder_storm_effect() -> PackedScene:
	"""Create thunder storm combination effect"""
	var scene = PackedScene.new()
	var container = Node2D.new()
	
	# Multiple lightning strikes
	for i in range(3):
		var line = Line2D.new()
		var points = []
		for j in range(8):
			var x = randf_range(-15, 15) + (i * 30)
			var y = j * 8
			points.append(Vector2(x, y))
		
		line.points = PackedVector2Array(points)
		line.width = 2.0
		line.default_color = Color.YELLOW
		container.add_child(line)
	
	# Wind particles
	var wind_particles = GPUParticles2D.new()
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(1, -0.5, 0)
	material.initial_velocity_min = 120.0
	material.initial_velocity_max = 200.0
	material.gravity = Vector3(0, 30, 0)
	material.scale_min = 0.4
	material.scale_max = 1.0
	material.color = Color.LIGHT_CYAN
	
	wind_particles.process_material = material
	wind_particles.amount = 50
	wind_particles.lifetime = 2.0
	wind_particles.one_shot = true
	wind_particles.emitting = false
	
	container.add_child(wind_particles)
	
	scene.pack(container)
	return scene

func _initialize_particle_systems() -> void:
	"""Initialize reusable particle systems"""
	particle_systems = {
		"impact": _create_impact_particles(),
		"sparkles": _create_sparkle_particles(),
		"smoke": _create_smoke_particles(),
		"blood": _create_blood_particles()
	}

func _create_impact_particles() -> GPUParticles2D:
	"""Create generic impact particles"""
	var particles = GPUParticles2D.new()
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 40.0
	material.initial_velocity_max = 80.0
	material.gravity = Vector3(0, 98, 0)
	material.scale_min = 0.2
	material.scale_max = 0.8
	material.color = Color.WHITE
	
	particles.process_material = material
	particles.amount = 15
	particles.lifetime = 1.0
	particles.one_shot = true
	particles.emitting = false
	
	return particles

func _create_sparkle_particles() -> GPUParticles2D:
	"""Create sparkle particles for positive effects"""
	var particles = GPUParticles2D.new()
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 60.0
	material.gravity = Vector3(0, -20, 0)
	material.scale_min = 0.3
	material.scale_max = 0.7
	material.color = Color.GOLD
	
	particles.process_material = material
	particles.amount = 12
	particles.lifetime = 1.5
	particles.one_shot = true
	particles.emitting = false
	
	return particles

func _create_smoke_particles() -> GPUParticles2D:
	"""Create smoke particles"""
	var particles = GPUParticles2D.new()
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 10.0
	material.initial_velocity_max = 30.0
	material.gravity = Vector3(0, -10, 0)
	material.scale_min = 0.5
	material.scale_max = 1.5
	material.color = Color.GRAY
	
	particles.process_material = material
	particles.amount = 20
	particles.lifetime = 3.0
	particles.one_shot = true
	particles.emitting = false
	
	return particles

func _create_blood_particles() -> GPUParticles2D:
	"""Create blood particles for damage"""
	var particles = GPUParticles2D.new()
	var material = ParticleProcessMaterial.new()
	material.direction = Vector3(0, -1, 0)
	material.initial_velocity_min = 50.0
	material.initial_velocity_max = 100.0
	material.gravity = Vector3(0, 120, 0)
	material.scale_min = 0.3
	material.scale_max = 0.8
	material.color = Color.DARK_RED
	
	particles.process_material = material
	particles.amount = 10
	particles.lifetime = 1.2
	particles.one_shot = true
	particles.emitting = false
	
	return particles

func _initialize_damage_text_pool() -> void:
	"""Initialize pool of damage text labels for performance"""
	for i in range(20):
		var label = Label.new()
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color.BLACK)
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.visible = false
		damage_text_pool.append(label)

func play_spell_effect(spell_id: String, position: Vector2) -> void:
	"""Play visual effect for a spell cast"""
	var effect_id = _get_effect_id_for_spell(spell_id)
	
	if effect_scenes.has(effect_id):
		var effect = effect_scenes[effect_id].instantiate()
		_add_effect_to_scene(effect, position)
		_trigger_effect(effect)
		
		effect_started.emit(effect_id, position)
		
		# Auto cleanup after lifetime
		var cleanup_timer = get_tree().create_timer(3.0)
		cleanup_timer.timeout.connect(func(): _cleanup_effect(effect, effect_id))

func _get_effect_id_for_spell(spell_id: String) -> String:
	"""Map spell ID to effect ID"""
	match spell_id:
		"fireball":
			return "fireball_explosion"
		"ice_shard":
			return "ice_shatter"
		"lightning_bolt":
			return "lightning_strike"
		"shadow_blast":
			return "shadow_burst"
		"healing_light":
			return "healing_glow"
		"earth_spike":
			return "earth_crack"
		"wind_slash":
			return "wind_swirl"
		"frost_nova":
			return "frost_nova"
		"flame_wave":
			return "flame_wave"
		"thunder_storm":
			return "thunder_storm"
		_:
			return "impact"

func play_damage_effect(damage: int, position: Vector2, color: Color = Color.WHITE) -> void:
	"""Play damage number effect at position"""
	var damage_text = _get_damage_text_from_pool()
	if not damage_text:
		return
	
	# Set up damage text
	damage_text.text = str(damage)
	damage_text.modulate = color
	damage_text.position = position
	damage_text.visible = true
	
	# Add to scene
	_add_effect_to_scene(damage_text, position)
	
	# Animate damage text
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(damage_text, "position", position + Vector2(0, -50), 1.0)
	tween.tween_property(damage_text, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): _return_damage_text_to_pool(damage_text)).set_delay(1.0)

func play_explosion_effect(position: Vector2, size: float = 1.0) -> void:
	"""Play explosion effect with custom size"""
	var particles = particle_systems["impact"].duplicate()
	particles.scale = Vector2(size, size)
	particles.amount = int(15 * size)
	
	_add_effect_to_scene(particles, position)
	particles.emitting = true
	
	# Cleanup
	var cleanup_timer = get_tree().create_timer(2.0)
	cleanup_timer.timeout.connect(func(): particles.queue_free())

func screen_shake(intensity: float, duration: float) -> void:
	"""Apply screen shake effect"""
	if not current_camera:
		current_camera = get_viewport().get_camera_2d()
	
	if not current_camera:
		return
	
	if screen_shake_tween:
		screen_shake_tween.kill()
	
	screen_shake_tween = create_tween()
	screen_shake_tween.set_loops()
	
	var original_offset = current_camera.offset
	
	for i in range(int(duration * 60)):  # 60 FPS assumption
		var shake_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		screen_shake_tween.tween_property(current_camera, "offset", original_offset + shake_offset, 0.016)
	
	# Return to original position
	screen_shake_tween.tween_property(current_camera, "offset", original_offset, 0.1)

func play_hit_effect(position: Vector2, is_critical: bool = false) -> void:
	"""Play hit effect with optional critical indicator"""
	var color = Color.YELLOW if is_critical else Color.WHITE
	var particles = particle_systems["impact"].duplicate()
	
	if is_critical:
		particles.scale = Vector2(1.5, 1.5)
		particles.amount = 25
	
	particles.process_material.color = color
	_add_effect_to_scene(particles, position)
	particles.emitting = true
	
	# Screen shake for critical hits
	if is_critical:
		screen_shake(5.0, 0.2)
	
	# Cleanup
	var cleanup_timer = get_tree().create_timer(1.5)
	cleanup_timer.timeout.connect(func(): particles.queue_free())

func play_heal_effect(position: Vector2, amount: int) -> void:
	"""Play healing effect with amount"""
	# Healing particles
	var particles = particle_systems["sparkles"].duplicate()
	particles.process_material.color = Color.LIGHT_GREEN
	_add_effect_to_scene(particles, position)
	particles.emitting = true
	
	# Healing text
	play_damage_effect(amount, position, Color.GREEN)
	
	# Cleanup
	var cleanup_timer = get_tree().create_timer(2.0)
	cleanup_timer.timeout.connect(func(): particles.queue_free())

func _add_effect_to_scene(effect: Node, position: Vector2) -> void:
	"""Add effect to current scene at position"""
	var scene = get_tree().current_scene
	if scene:
		scene.add_child(effect)
		if effect.has_method("set_global_position"):
			effect.global_position = position
		elif "position" in effect:
			effect.position = position

func _trigger_effect(effect: Node) -> void:
	"""Trigger the effect to start"""
	if effect is GPUParticles2D:
		effect.emitting = true
	elif effect.has_method("start"):
		effect.start()
	
	# Trigger all child particles if it's a container
	for child in effect.get_children():
		if child is GPUParticles2D:
			child.emitting = true

func _cleanup_effect(effect: Node, effect_id: String) -> void:
	"""Clean up an effect and emit finished signal"""
	if is_instance_valid(effect):
		effect.queue_free()
	effect_finished.emit(effect_id)

func _get_damage_text_from_pool() -> Label:
	"""Get a damage text label from the pool"""
	for label in damage_text_pool:
		if not label.visible:
			return label
	return null

func _return_damage_text_to_pool(label: Label) -> void:
	"""Return damage text label to pool"""
	label.visible = false
	if label.get_parent():
		label.get_parent().remove_child(label)

func set_camera(camera: Camera2D) -> void:
	"""Set the current camera for screen effects"""
	current_camera = camera

# Cleanup functions
func clear_all_effects() -> void:
	"""Clear all active effects"""
	if screen_shake_tween:
		screen_shake_tween.kill()
	
	for label in damage_text_pool:
		_return_damage_text_to_pool(label)
extends Node
class_name ParticleManager

signal particle_effect_created(effect: Node, type: String)

# Tipos de efectos disponibles
enum EffectType {
	FIRE,
	ICE,
	LIGHTNING,
	ARCANE,
	IMPACT,
	HEAL
}

var active_effects: Array = []
var max_simultaneous_effects: int = 150

func _ready() -> void:
	# print("[ParticleManager] Inicializado")
	pass

func create_effect(effect_type: int, position: Vector2, lifetime: float = 1.0):
	"""Crear un efecto de partículas en la posición especificada"""
	# Limitar efectos simultáneos
	if active_effects.size() >= max_simultaneous_effects:
		_cleanup_oldest_effect()
	
	var effect = null
	
	match effect_type:
		EffectType.FIRE:
			effect = _create_fire_effect(position, lifetime)
		EffectType.ICE:
			effect = _create_ice_effect(position, lifetime)
		EffectType.LIGHTNING:
			effect = _create_lightning_effect(position, lifetime)
		EffectType.ARCANE:
			effect = _create_arcane_effect(position, lifetime)
		EffectType.IMPACT:
			effect = _create_impact_effect(position, lifetime)
		EffectType.HEAL:
			effect = _create_heal_effect(position, lifetime)
	
	if effect:
		active_effects.append(effect)
		particle_effect_created.emit(effect, EffectType.keys()[effect_type])
	
	return effect

func _create_fire_effect(position: Vector2, lifetime: float):
	"""Efecto de fuego: humo rojo y chispas"""
	var effect = Node2D.new()
	effect.position = position
	
	# Crear varias partículas de humo
	for i in range(3):
		var particle = CPUParticles2D.new()
		particle.emitting = true
		particle.lifetime = lifetime
		particle.amount = 8
		particle.speed_scale = randf_range(0.8, 1.2)
		
		# Color rojo/naranja
		particle.color = Color(1.0, 0.5, 0.0, 1.0)
		particle.color_ramp = Gradient.new()
		particle.color_ramp.add_point(0.0, Color(1.0, 0.7, 0.0, 1.0))
		particle.color_ramp.add_point(1.0, Color(1.0, 0.0, 0.0, 0.0))
		
		# Velocidad inicial
		particle.initial_velocity_min = 50.0
		particle.initial_velocity_max = 120.0
		particle.angle_min = 0.0
		particle.angle_max = TAU
		
		effect.add_child(particle)
	
	add_child(effect)
	call_deferred("_schedule_effect_cleanup", effect, lifetime)
	
	return effect

func _create_ice_effect(position: Vector2, lifetime: float):
	"""Efecto de hielo: cristales azules y niebla"""
	var effect = Node2D.new()
	effect.position = position
	
	for i in range(2):
		var particle = CPUParticles2D.new()
		particle.emitting = true
		particle.lifetime = lifetime
		particle.amount = 6
		particle.speed_scale = randf_range(0.7, 1.0)
		
		# Color azul
		particle.color = Color(0.0, 0.7, 1.0, 1.0)
		particle.color_ramp = Gradient.new()
		particle.color_ramp.add_point(0.0, Color(0.5, 0.9, 1.0, 0.8))
		particle.color_ramp.add_point(1.0, Color(0.0, 0.5, 1.0, 0.0))
		
		particle.initial_velocity_min = 30.0
		particle.initial_velocity_max = 80.0
		particle.angle_min = 0.0
		particle.angle_max = TAU
		
		effect.add_child(particle)
	
	add_child(effect)
	call_deferred("_schedule_effect_cleanup", effect, lifetime)
	
	return effect

func _create_lightning_effect(position: Vector2, lifetime: float):
	"""Efecto de rayo: descargas amarillas"""
	var effect = Node2D.new()
	effect.position = position
	
	var particle = CPUParticles2D.new()
	particle.emitting = true
	particle.lifetime = lifetime * 0.5  # Más corto para rayo
	particle.amount = 12
	particle.speed_scale = 2.0  # Más rápido
	
	# Color amarillo/blanco
	particle.color = Color(1.0, 1.0, 0.0, 1.0)
	particle.color_ramp = Gradient.new()
	particle.color_ramp.add_point(0.0, Color(1.0, 1.0, 0.5, 1.0))
	particle.color_ramp.add_point(1.0, Color(1.0, 1.0, 0.0, 0.0))
	
	particle.initial_velocity_min = 100.0
	particle.initial_velocity_max = 200.0
	particle.angle_min = 0.0
	particle.angle_max = TAU
	
	effect.add_child(particle)
	add_child(effect)
	call_deferred("_schedule_effect_cleanup", effect, lifetime)
	
	return effect

func _create_arcane_effect(position: Vector2, lifetime: float):
	"""Efecto arcano: pulsos morados"""
	var effect = Node2D.new()
	effect.position = position
	
	for i in range(2):
		var particle = CPUParticles2D.new()
		particle.emitting = true
		particle.lifetime = lifetime
		particle.amount = 8
		particle.speed_scale = randf_range(0.9, 1.3)
		
		# Color morado
		particle.color = Color(0.7, 0.0, 1.0, 1.0)
		particle.color_ramp = Gradient.new()
		particle.color_ramp.add_point(0.0, Color(0.9, 0.5, 1.0, 1.0))
		particle.color_ramp.add_point(1.0, Color(0.5, 0.0, 1.0, 0.0))
		
		particle.initial_velocity_min = 40.0
		particle.initial_velocity_max = 100.0
		particle.angle_min = 0.0
		particle.angle_max = TAU
		
		effect.add_child(particle)
	
	add_child(effect)
	call_deferred("_schedule_effect_cleanup", effect, lifetime)
	
	return effect

func _create_impact_effect(position: Vector2, lifetime: float):
	"""Efecto de impacto: explosión general"""
	var effect = Node2D.new()
	effect.position = position
	
	var particle = CPUParticles2D.new()
	particle.emitting = true
	particle.lifetime = lifetime * 0.3
	particle.amount = 15
	particle.speed_scale = 1.5
	
	# Color blanco amarillento
	particle.color = Color(1.0, 1.0, 0.8, 1.0)
	particle.color_ramp = Gradient.new()
	particle.color_ramp.add_point(0.0, Color(1.0, 0.9, 0.5, 1.0))
	particle.color_ramp.add_point(1.0, Color(1.0, 0.5, 0.0, 0.0))
	
	particle.initial_velocity_min = 80.0
	particle.initial_velocity_max = 150.0
	particle.angle_min = 0.0
	particle.angle_max = TAU
	
	effect.add_child(particle)
	add_child(effect)
	call_deferred("_schedule_effect_cleanup", effect, lifetime)
	
	return effect

func _create_heal_effect(position: Vector2, lifetime: float):
	"""Efecto de sanación: chispas verdes"""
	var effect = Node2D.new()
	effect.position = position
	
	for i in range(2):
		var particle = CPUParticles2D.new()
		particle.emitting = true
		particle.lifetime = lifetime
		particle.amount = 8
		particle.speed_scale = randf_range(0.8, 1.1)
		
		# Color verde
		particle.color = Color(0.0, 1.0, 0.5, 1.0)
		particle.color_ramp = Gradient.new()
		particle.color_ramp.add_point(0.0, Color(0.5, 1.0, 0.7, 1.0))
		particle.color_ramp.add_point(1.0, Color(0.0, 1.0, 0.5, 0.0))
		
		particle.initial_velocity_min = 50.0
		particle.initial_velocity_max = 100.0
		particle.angle_min = 0.0
		particle.angle_max = TAU
		
		effect.add_child(particle)
	
	add_child(effect)
	call_deferred("_schedule_effect_cleanup", effect, lifetime)
	
	return effect

func _schedule_effect_cleanup(effect, lifetime: float) -> void:
	"""Programar limpieza de efecto después de su duración"""
	await get_tree().create_timer(lifetime).timeout
	if effect and is_instance_valid(effect):
		effect.queue_free()
		active_effects.erase(effect)

func _cleanup_oldest_effect() -> void:
	"""Limpiar efecto más antiguo si se alcanza el límite"""
	if not active_effects.is_empty():
		var oldest = active_effects[0]
		active_effects.remove_at(0)
		if oldest and is_instance_valid(oldest):
			oldest.queue_free()

func cleanup_all() -> void:
	"""Limpiar todos los efectos activos"""
	for effect in active_effects:
		if effect and is_instance_valid(effect):
			effect.queue_free()
	active_effects.clear()

# Public APIs
func play_effect(effect_type: String, position: Vector2, _color: Color = Color(1,1,1), lifetime: float = 0.8) -> void:
	"""Compatibilidad con API anterior"""
	match effect_type.to_lower():
		"fire":
			create_effect(EffectType.FIRE, position, lifetime)
		"ice":
			create_effect(EffectType.ICE, position, lifetime)
		"lightning":
			create_effect(EffectType.LIGHTNING, position, lifetime)
		"arcane":
			create_effect(EffectType.ARCANE, position, lifetime)
		"impact":
			create_effect(EffectType.IMPACT, position, lifetime)
		"heal":
			create_effect(EffectType.HEAL, position, lifetime)
		_:
			create_effect(EffectType.IMPACT, position, lifetime)

func emit_element_effect(element_type: String, position: Vector2, lifetime: float = 0.8) -> void:
	"""Emitir efecto visual según tipo de elemento"""
	match element_type.to_lower():
		"fire":
			create_effect(EffectType.FIRE, position, lifetime)
		"ice":
			create_effect(EffectType.ICE, position, lifetime)
		"lightning":
			create_effect(EffectType.LIGHTNING, position, lifetime)
		"arcane":
			create_effect(EffectType.ARCANE, position, lifetime)
		"physical":
			create_effect(EffectType.IMPACT, position, lifetime)
		"heal":
			create_effect(EffectType.HEAL, position, lifetime)
		_:
			create_effect(EffectType.IMPACT, position, lifetime)

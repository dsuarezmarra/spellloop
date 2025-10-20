# ProjectileSystemEnhancer.gd
# Sistema central para mejorar proyectiles: sprites, animaciones, rotación, colisiones

extends Node

class_name ProjectileSystemEnhancer

signal sprites_generated
signal animations_loaded
signal system_ready

var sprites_generated_count: int = 0
var animations_data: Dictionary = {}

func _ready() -> void:
	"""Inicializar sistema de proyectiles mejorado"""
	print("[ProjectileSystemEnhancer] 🚀 Iniciando sistema mejorado de proyectiles...")
	
	# Generar sprites en paralelo (background task)
	_generate_sprites_background()
	
	# Cargar animaciones
	_load_animations()
	
	# Verificar que todo está listo
	await get_tree().create_timer(0.5).timeout
	print("[ProjectileSystemEnhancer] ✓ Sistema listo")
	system_ready.emit()

func _generate_sprites_background() -> void:
	"""Generar sprites de proyectiles en background"""
	var generator_script = load("res://scripts/core/ProjectileSpriteGenerator.gd")
	if not generator_script:
		print("[ProjectileSystemEnhancer] ⚠️ ProjectileSpriteGenerator no disponible")
		return
	
	# Ejecutar generación en thread para no bloquear
	print("[ProjectileSystemEnhancer] 🎨 Generando sprites de proyectiles...")
	
	var success = generator_script.generate_all_projectile_sprites()
	
	if success:
		sprites_generated_count = 120  # 4 × 3 × 10 frames
		print("[ProjectileSystemEnhancer] ✓ 120 frames de proyectiles generados")
		sprites_generated.emit()
	else:
		print("[ProjectileSystemEnhancer] ✗ Error generando sprites")

func _load_animations() -> void:
	"""Cargar configuración de animaciones desde JSON"""
	var loader_script = load("res://scripts/core/ProjectileAnimationLoader.gd")
	if not loader_script:
		print("[ProjectileSystemEnhancer] ⚠️ ProjectileAnimationLoader no disponible")
		return
	
	print("[ProjectileSystemEnhancer] 📋 Cargando configuración de animaciones...")
	
	animations_data = loader_script.load_projectile_animations()
	
	if not animations_data.is_empty():
		print("[ProjectileSystemEnhancer] ✓ %d projectiles con animaciones" % animations_data.size())
		animations_loaded.emit()
		_display_animation_info()
	else:
		print("[ProjectileSystemEnhancer] ⚠️ No animations loaded")

func _display_animation_info() -> void:
	"""Mostrar información de animaciones cargadas"""
	for projectile_name in animations_data.keys():
		var data = animations_data[projectile_name]
		var anim_count = data.get("animations", []).size()
		print("  • %s: %d animaciones (%s)" % [
			projectile_name,
			anim_count,
			data.get("element", "unknown")
		])

func get_projectile_animation_data(projectile_name: String) -> Dictionary:
	"""Obtener datos de animación de un proyectil específico"""
	return animations_data.get(projectile_name, {})

func create_animated_projectile(projectile_name: String, position: Vector2, direction: Vector2) -> Node2D:
	"""
	Crear proyectil con animaciones
	"""
	var data = get_projectile_animation_data(projectile_name)
	
	if data.is_empty():
		print("[ProjectileSystemEnhancer] ✗ No data for projectile: %s" % projectile_name)
		return null
	
	var root = Area2D.new()
	root.name = "%sProjectile" % projectile_name.capitalize()
	root.global_position = position
	
	# Agregar AnimatedSprite2D
	if data.has("animated_sprite"):
		var sprite = data["animated_sprite"].duplicate()
		sprite.name = "AnimatedSprite2D"
		root.add_child(sprite)
		sprite.play("InFlight")  # Comenzar con animación de vuelo
	
	# Agregar CollisionShape2D
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.shape = CircleShape2D.new()
	collision.shape.radius = 4.0
	root.add_child(collision)
	
	# Establecer rotación según dirección
	root.rotation = direction.angle()
	
	# Agregar propiedades del proyectil
	root.set_meta("projectile_name", projectile_name)
	root.set_meta("direction", direction)
	root.set_meta("element", data.get("element", "basic"))
	
	print("[ProjectileSystemEnhancer] ✓ Proyectil animado creado: %s en %s" % [projectile_name, position])
	
	return root

# Métodos auxiliares para integración con sistema existente

func apply_projectile_rotation(projectile: Node2D, direction: Vector2) -> void:
	"""Aplicar rotación a un proyectil basado en dirección"""
	if projectile:
		projectile.rotation = direction.angle()

func get_projectile_element(projectile_name: String) -> String:
	"""Obtener elemento del proyectil"""
	var data = get_projectile_animation_data(projectile_name)
	return data.get("element", "basic")

func play_projectile_animation(projectile: Node2D, animation_type: String) -> void:
	"""Reproducir animación específica de proyectil"""
	var sprite = projectile.get_node_or_null("AnimatedSprite2D")
	if sprite and sprite is AnimatedSprite2D:
		if sprite.sprite_frames.has_animation(animation_type):
			sprite.play(animation_type)

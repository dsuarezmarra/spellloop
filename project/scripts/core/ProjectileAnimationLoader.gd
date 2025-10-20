# ProjectileAnimationLoader.gd
# Carga animaciones de proyectiles desde JSON y crea escenas con AnimatedSprite2D

extends Node

class_name ProjectileAnimationLoader

static func load_projectile_animations() -> Dictionary:
	"""
	Carga configuración de animaciones desde projectile_animations.json
	Retorna: {
		"projectile_name": {
			"animations": [
				{"type": "Launch", "frames": [...], "sprite2d": AnimatedSprite2D},
				...
			],
			"scene": PackedScene
		},
		...
	}
	"""
	var config_path = "res://assets/sprites/projectiles/projectile_animations.json"
	var result = {}
	
	if not ResourceLoader.exists(config_path):
		print("[ProjectileAnimationLoader] ✗ Config no encontrada: %s" % config_path)
		return result
	
	var json_text = FileAccess.get_file_as_string(config_path)
	if json_text.is_empty():
		print("[ProjectileAnimationLoader] ✗ Config vacía")
		return result
	
	var json = JSON.new()
	if json.parse(json_text) != OK:
		print("[ProjectileAnimationLoader] ✗ JSON parse error")
		return result
	
	var config = json.data
	if not config.has("projectiles"):
		print("[ProjectileAnimationLoader] ✗ Config sin clave 'projectiles'")
		return result
	
	# Procesar cada proyectil
	for projectile_data in config["projectiles"]:
		var projectile_name = projectile_data.get("name", "unknown")
		var animations = projectile_data.get("animations", [])
		
		result[projectile_name] = {
			"name": projectile_name,
			"element": projectile_data.get("element", "basic"),
			"color_primary": projectile_data.get("color_primary", "#FFFFFF"),
			"animations": []
		}
		
		# Crear AnimatedSprite2D para este proyectil
		var animated_sprite = AnimatedSprite2D.new()
		var sprite_frames = SpriteFrames.new()
		
		# Procesar cada animación (Launch, InFlight, Impact)
		for anim_data in animations:
			var anim_type = anim_data.get("type", "Launch")
			var frames = anim_data.get("frames", 10)
			var speed = anim_data.get("speed", 12)
			var loop = anim_data.get("loop", true)
			
			# Crear animación en SpriteFrames
			sprite_frames.add_animation(anim_type)
			sprite_frames.set_animation_speed(anim_type, float(speed))
			sprite_frames.set_animation_loop(anim_type, loop)
			
			# Agregar frames a la animación
			for frame_idx in range(frames):
				var frame_name = "%s_%s_%02d.png" % [anim_type, projectile_name, frame_idx]
				var frame_path = "%s%s/%s" % [
					projectile_data.get("path", "res://assets/sprites/projectiles/%s/" % projectile_name),
					projectile_name,
					frame_name
				]
				
				# Intentar cargar la imagen
				if ResourceLoader.exists(frame_path):
					var texture = load(frame_path)
					sprite_frames.add_frame(anim_type, texture)
				else:
					print("[ProjectileAnimationLoader] ⚠️ Frame no encontrado: %s" % frame_path)
					# Crear placeholder blanco como fallback
					var placeholder = Image.create(64, 64, false, Image.FORMAT_RGBA8)
					placeholder.fill(Color.WHITE)
					var placeholder_tex = ImageTexture.create_from_image(placeholder)
					sprite_frames.add_frame(anim_type, placeholder_tex)
			
			result[projectile_name]["animations"].append({
				"type": anim_type,
				"frames": frames,
				"speed": speed,
				"loop": loop
			})
		
		# Configurar AnimatedSprite2D
		animated_sprite.sprite_frames = sprite_frames
		animated_sprite.animation = "InFlight"  # Animación por defecto
		animated_sprite.centered = true
		animated_sprite.scale = Vector2(1.0, 1.0)
		
		result[projectile_name]["animated_sprite"] = animated_sprite
		
		print("[ProjectileAnimationLoader] ✓ Proyectil '%s' cargado con %d animaciones" % [
			projectile_name,
			animations.size()
		])
	
	return result

static func create_projectile_scene(projectile_name: String, animations_data: Dictionary) -> PackedScene:
	"""
	Crea una escena de proyectil con AnimatedSprite2D
	"""
	var root = Area2D.new()
	root.name = "%sProjectile" % projectile_name.capitalize()
	
	# Agregar AnimatedSprite2D
	if animations_data.has("animated_sprite"):
		var sprite = animations_data["animated_sprite"].duplicate()
		sprite.name = "AnimatedSprite2D"
		root.add_child(sprite)
	
	# Agregar CollisionShape2D
	var collision = CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.shape = CircleShape2D.new()
	collision.shape.radius = 4.0
	root.add_child(collision)
	
	# Convertir a PackedScene
	var packed_scene = PackedScene.new()
	packed_scene.pack(root)
	
	return packed_scene

static func preload_all_animations() -> bool:
	"""
	Precarga todas las animaciones de proyectiles
	Retorna true si todas fueron cargadas correctamente
	"""
	var animations = load_projectile_animations()
	
	if animations.is_empty():
		print("[ProjectileAnimationLoader] ✗ No animations loaded")
		return false
	
	print("[ProjectileAnimationLoader] ✓ %d projectile types loaded" % animations.size())
	return true

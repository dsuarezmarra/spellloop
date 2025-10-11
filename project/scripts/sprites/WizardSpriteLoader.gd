# WizardSpriteLoader.gd - Cargador de sprites externos del mago
extends RefCounted
class_name WizardSpriteLoader

# Enums para direcciones y frames (mantenemos compatibilidad)
enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

enum AnimFrame {
	IDLE,
	WALK1,
	WALK2
}

# Rutas de los sprites
static var sprite_paths = {
	Direction.DOWN: "res://sprites/wizard/wizard_down.png",
	Direction.UP: "res://sprites/wizard/wizard_up.png", 
	Direction.LEFT: "res://sprites/wizard/wizard_left.png",
	Direction.RIGHT: "res://sprites/wizard/wizard_right.png"
}

# Cache de texturas cargadas
static var loaded_textures = {}

static func load_wizard_sprite(direction: Direction, frame: AnimFrame = AnimFrame.IDLE) -> ImageTexture:
	"""Carga un sprite del mago desde archivo"""
	
	# Para estos sprites estáticos, usamos solo la dirección
	# (los frames de animación se pueden simular con escalado o efectos)
	var cache_key = str(direction)
	
	# Verificar cache
	if cache_key in loaded_textures:
		return loaded_textures[cache_key]
	
	# Cargar sprite desde archivo
	var texture = load_sprite_from_file(direction)
	
	# Guardar en cache
	loaded_textures[cache_key] = texture
	
	print("[WizardSpriteLoader] Sprite cargado: ", Direction.keys()[direction])
	return texture

static func load_sprite_from_file(direction: Direction) -> ImageTexture:
	"""Carga un sprite desde archivo con fallback a generado"""
	var path = sprite_paths[direction]
	
	print("[WizardSpriteLoader] 🔍 Intentando cargar: ", path)
	
	# MÉTODO 1: Intentar cargar directamente como recurso importado
	var loaded_texture = load(path) as Texture2D
	if loaded_texture:
		print("[WizardSpriteLoader] ✅ ÉXITO: Sprite cargado desde archivo: ", path)
		print("[WizardSpriteLoader] 📏 Tamaño: ", loaded_texture.get_width(), "x", loaded_texture.get_height())
		
		# Convertir a ImageTexture para compatibilidad
		if loaded_texture is ImageTexture:
			return loaded_texture as ImageTexture
		else:
			# Convertir CompressedTexture2D a ImageTexture
			var image_texture = ImageTexture.new()
			var image = loaded_texture.get_image()
			if image:
				image_texture.create_from_image(image)
				print("[WizardSpriteLoader] 🔄 Convertido a ImageTexture exitosamente")
				return image_texture
			else:
				print("[WizardSpriteLoader] ❌ No se pudo obtener Image de la textura")
	
	# MÉTODO 2: Verificar si el archivo existe físicamente
	elif ResourceLoader.exists(path):
		print("[WizardSpriteLoader] ⚠ Archivo existe pero no se puede cargar - Problema de importación")
	else:
		print("[WizardSpriteLoader] ❌ Error: Archivo no existe: ", path)
	
	# Fallback: generar sprite proceduralmente como antes
	print("[WizardSpriteLoader] 🔧 Usando sprite procedural como fallback")
	return generate_fallback_sprite(direction)

static func generate_fallback_sprite(direction: Direction) -> ImageTexture:
	"""Genera sprite de fallback usando el sistema en memoria primero"""
	print("[WizardSpriteLoader] 🔧 Generando sprite fallback...")
	
	# NUEVO: Intentar el sistema en memoria primero
	var direction_name = Direction.keys()[direction]
	print("[WizardSpriteLoader] 🧠 Probando sistema en memoria para: ", direction_name)
	
	# Verificar si el cargador en memoria está disponible
	if SpriteLoaderInMemory and SpriteLoaderInMemory.is_memory_mode_enabled():
		var memory_texture = SpriteLoaderInMemory.get_sprite_for_direction(direction_name)
		if memory_texture:
			print("[WizardSpriteLoader] ✅ Fallback exitoso desde memoria para: ", direction_name)
			return memory_texture
		else:
			print("[WizardSpriteLoader] ❌ Sistema en memoria falló para: ", direction_name)
	else:
		print("[WizardSpriteLoader] ❌ Sistema en memoria no disponible")
	
	# Fallback tradicional: usar datos hardcodeados
	print("[WizardSpriteLoader] 🔧 Usando sprite procedural tradicional como último recurso")
	
	var data: PackedByteArray
	match direction:
		Direction.DOWN:
			data = SpriteData.get_wizard_down_data()
		Direction.LEFT:
			data = SpriteData.get_wizard_left_data()
		Direction.UP:
			data = SpriteData.get_wizard_up_data()
		Direction.RIGHT:
			data = SpriteData.get_wizard_right_data()
		_:
			data = SpriteData.get_wizard_down_data()
	
	return SpriteData.create_texture_from_data(data)

static func create_wizard_sprite(direction: Direction, frame: AnimFrame) -> ImageTexture:
	"""Función principal de compatibilidad"""
	return load_wizard_sprite(direction, frame)

# Función helper para guardar sprites (para desarrollo)
static func save_sprite_template(direction: Direction) -> void:
	"""Guarda un template del sprite para referencia"""
	var path = sprite_paths[direction]
	var dir_path = path.get_base_dir()
	
	# Crear directorio si no existe
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
	
	# Generar sprite template
	var template_texture = generate_fallback_sprite(direction)
	var image = template_texture.get_image()
	
	# Guardar como PNG
	var save_path = path.replace(".png", "_template.png")
	image.save_png(save_path)
	print("[WizardSpriteLoader] Template guardado en: ", save_path)

# Información sobre los sprites esperados
static func get_sprite_info() -> Dictionary:
	"""Devuelve información sobre los sprites esperados"""
	return {
		"format": "PNG con transparencia",
		"size_recommended": "48x64 píxeles o similar",
		"style": "Isaac + Funko Pop + Magia",
		"paths": sprite_paths,
		"directions_count": Direction.size(),
		"description": {
			Direction.DOWN: "Mago mirando hacia abajo/frente - con bastón visible",
			Direction.UP: "Mago mirando hacia arriba/espaldas - sombrero y bastón visibles", 
			Direction.LEFT: "Mago mirando hacia la izquierda - perfil con bastón",
			Direction.RIGHT: "Mago mirando hacia la derecha - perfil con bastón"
		}
	}

# WizardPlayer.gd
# Clase específica del personaje Wizard
# Extiende BasePlayer con características y armas específicas del mago

extends BasePlayer
class_name WizardPlayer

# ========== CARACTERÍSTICAS DEL WIZARD ==========

# Estadísticas específicas del Wizard (más magia, menos defensa)
# Nota: move_speed, hp, max_hp, armor se heredan de BasePlayer

# Bono de magia del Wizard
var spell_power: float = 1.2  # 20% más daño en hechizos
var mana: int = 50
var max_mana: int = 50

# ========== ARMAS DEL WIZARD ==========
var ice_wand = null
var fire_wand = null  # Future

# ========== CICLO DE VIDA ==========

func _ready() -> void:
	"""Inicialización específica del Wizard"""
	print("\n[WizardPlayer] ===== INICIALIZANDO WIZARD =====")
	
	# Asignar valores específicos del Wizard ANTES de llamar a super
	character_class = "Wizard"
	character_sprites_key = "wizard"
	
	# Llamar a inicialización base
	super._ready()
	
	print("[WizardPlayer] ===== WIZARD INICIALIZADO =====\n")

func _setup_animations() -> void:
	"""Configurar animaciones del Wizard - COPIA EXACTA DEL SISTEMA ORIGINAL QUE FUNCIONA"""
	if not animated_sprite:
		print("[WizardPlayer] ⚠️ AnimatedSprite2D no disponible")
		return
	
	# Obtener SpriteDB para cargar sprites reales
	var sprite_db = null
	var _gt = get_tree()
	if _gt and _gt.root:
		sprite_db = _gt.root.get_node_or_null("SpriteDB")
	
	var frames = SpriteFrames.new()
	var dirs = ["down", "up", "left", "right"]
	var player_sprites = sprite_db.get_player_sprites() if sprite_db else {}
	var placeholder_tex: Texture2D = null
	
	for dir in dirs:
		var tex: Texture2D = null
		if player_sprites and player_sprites.has(dir):
			var path = player_sprites[dir]
			if typeof(path) == TYPE_STRING and path != "":
				tex = load(path)
		
		var walk_anim = "walk_%s" % dir
		var idle_anim = "idle_%s" % dir
		
		if not frames.has_animation(walk_anim):
			frames.add_animation(walk_anim)
		if not frames.has_animation(idle_anim):
			frames.add_animation(idle_anim)
		
		if tex:
			frames.add_frame(walk_anim, tex)
			frames.add_frame(walk_anim, tex)
			frames.add_frame(idle_anim, tex)
		else:
			# Crear placeholder si no existe textura
			if not placeholder_tex:
				var size = 16
				var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
				var center = Vector2(size / 2.0, size / 2.0)
				var radius = size / 2.0 - 1.0
				for x in range(size):
					for y in range(size):
						var p = Vector2(x, y)
						var d = p.distance_to(center)
						if d <= radius:
							img.set_pixel(x, y, Color(0.1, 0.8, 0.1, 1.0))
						else:
							img.set_pixel(x, y, Color(0, 0, 0, 0))
				placeholder_tex = ImageTexture.new()
				placeholder_tex.set_image(img)
			
			frames.add_frame(walk_anim, placeholder_tex)
			frames.add_frame(walk_anim, placeholder_tex)
			frames.add_frame(idle_anim, placeholder_tex)
	
	if animated_sprite:
		animated_sprite.sprite_frames = frames
		if frames.has_animation("idle_down"):
			animated_sprite.animation = "idle_down"
		else:
			var anims = frames.get_animation_names()
			if anims.size() > 0:
				animated_sprite.animation = anims[0]
		animated_sprite.centered = true
	
	print("[WizardPlayer] ✓ Animaciones configuradas para Wizard (con sprites reales)")

func _equip_starting_weapons() -> void:
	"""Equipar armas iniciales del Wizard"""
	print("[WizardPlayer] === EQUIPANDO ARMAS INICIALES ===")
	
	if not attack_manager:
		print("[WizardPlayer] ⚠️ AttackManager no disponible")
		return
	
	# Crear Varita de Hielo
	var ice_wand_script = load("res://scripts/entities/weapons/wands/IceWand.gd")
	
	if not ice_wand_script:
		print("[WizardPlayer] ✗ Error: No se pudo cargar IceWand.gd")
		return
	
	ice_wand = ice_wand_script.new()
	if not ice_wand:
		print("[WizardPlayer] ✗ Error: No se pudo instanciar IceWand")
		return
	
	# Configurar propiedades
	ice_wand.name = "Varita de Hielo"
	ice_wand.is_active = true
	
	# Cargar escena de proyectil con verificación
	var ice_proj_scene = load("res://scripts/entities/weapons/projectiles/IceProjectile.tscn")
	print("[WizardPlayer] DEBUG: ice_proj_scene = %s (type: %s)" % [ice_proj_scene, typeof(ice_proj_scene)])
	if ice_proj_scene:
		ice_wand.projectile_scene = ice_proj_scene
		print("[WizardPlayer] ✓ IceProjectile.tscn cargado: %s" % ice_proj_scene)
	else:
		print("[WizardPlayer] ❌ IceProjectile.tscn FALLO - ice_proj_scene es null o inválido")
		# Debug más profundo
		if ResourceLoader.exists("res://scripts/entities/weapons/projectiles/IceProjectile.tscn"):
			print("[WizardPlayer]    - Archivo EXISTE en disco")
		else:
			print("[WizardPlayer]    - ⚠️ Archivo NO existe en disco")
	
	# Equipar arma
	var result = equip_weapon(ice_wand)
	
	if result:
		print("[WizardPlayer] ✓ Arma de Hielo equipada")
		print("[WizardPlayer] Verificación: projectile_scene = %s" % ice_wand.projectile_scene)
	else:
		print("[WizardPlayer] ⚠️ Error al equipar arma")

# ========== HABILIDADES DEL WIZARD ==========

func cast_spell(spell_name: String) -> void:
	"""Lanzar un hechizo"""
	match spell_name:
		"fireball":
			mana -= 10
		"frost_bolt":
			mana -= 8
		_:
			pass

func get_stats() -> Dictionary:
	"""Obtener estadísticas específicas del Wizard"""
	var base_stats = super.get_stats()
	base_stats["spell_power"] = spell_power
	base_stats["mana"] = mana
	base_stats["max_mana"] = max_mana
	return base_stats

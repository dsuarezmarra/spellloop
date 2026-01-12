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
	# print("\n[WizardPlayer] ===== INICIALIZANDO WIZARD =====")
	
	# Asignar valores específicos del Wizard ANTES de llamar a super
	character_class = "Wizard"
	character_sprites_key = "wizard"
	
	# Llamar a inicialización base
	super._ready()
	
	# print("[WizardPlayer] ===== WIZARD INICIALIZADO =====\n")

func set_character_sprites(sprite_folder: String) -> void:
	"""Change the character's sprite folder and reload animations"""
	character_sprites_key = sprite_folder
	_setup_animations()

func _setup_animations() -> void:
	"""Configure animations with spritesheets (uses character_sprites_key for folder)"""
	if not animated_sprite:
		return
	
	var frames = SpriteFrames.new()
	var dirs = ["down", "up", "left", "right"]
	var base_path = "res://assets/sprites/players/" + character_sprites_key
	var prefix = character_sprites_key  # e.g., "wizard", "pyromancer"
	
	# ========== ANIMACIONES DE CAMINAR (4 frames cada una) ==========
	for dir in dirs:
		var walk_anim = "walk_%s" % dir
		var idle_anim = "idle_%s" % dir
		
		frames.add_animation(walk_anim)
		frames.add_animation(idle_anim)
		frames.set_animation_speed(walk_anim, 2.5)  # FPS para walk (lento, natural)
		frames.set_animation_speed(idle_anim, 1.0)  # Idle estático
		frames.set_animation_loop(walk_anim, true)
		frames.set_animation_loop(idle_anim, true)
		
		# Load individual walk frames
		for i in range(1, 5):
			var frame_path = "%s/walk/%s_walk_%s_%d.png" % [base_path, prefix, dir, i]
			var tex = load(frame_path)
			if tex:
				frames.add_frame(walk_anim, tex)
				# Use first frame as idle
				if i == 1:
					frames.add_frame(idle_anim, tex)
			else:
				push_warning("[WizardPlayer] Sprite not found: %s" % frame_path)
	
	# ========== CAST ANIMATION (4 frames) ==========
	frames.add_animation("cast")
	frames.set_animation_speed("cast", 3.0)
	frames.set_animation_loop("cast", false)
	
	for i in range(1, 5):
		var frame_path = "%s/cast/%s_cast_%d.png" % [base_path, prefix, i]
		var tex = load(frame_path)
		if tex:
			frames.add_frame("cast", tex)
	
	# ========== HIT ANIMATION (2 frames) ==========
	frames.add_animation("hit")
	frames.set_animation_speed("hit", 2.0)
	frames.set_animation_loop("hit", false)
	
	for i in range(1, 3):
		var frame_path = "%s/hit/%s_hit_%d.png" % [base_path, prefix, i]
		var tex = load(frame_path)
		if tex:
			frames.add_frame("hit", tex)
	
	# ========== DEATH ANIMATION (4 frames) ==========
	frames.add_animation("death")
	frames.set_animation_speed("death", 2.0)
	frames.set_animation_loop("death", false)
	
	for i in range(1, 5):
		var frame_path = "%s/death/%s_death_%d.png" % [base_path, prefix, i]
		var tex = load(frame_path)
		if tex:
			frames.add_frame("death", tex)
	
	# Asignar frames al sprite
	if animated_sprite:
		animated_sprite.sprite_frames = frames
		if frames.has_animation("idle_down"):
			animated_sprite.animation = "idle_down"
		animated_sprite.centered = true
		animated_sprite.play()

func _equip_starting_weapons() -> void:
	"""Equipar armas iniciales del Wizard"""
	# print("[WizardPlayer] === EQUIPANDO ARMAS INICIALES ===")
	
	if not attack_manager:
		# print("[WizardPlayer] ⚠️ AttackManager no disponible")
		return
	
	# Crear Varita de Hielo
	var ice_wand_script = load("res://scripts/entities/weapons/wands/IceWand.gd")
	
	if not ice_wand_script:
		push_warning("[WizardPlayer] ✗ Error: No se pudo cargar IceWand.gd")
		return
	
	ice_wand = ice_wand_script.new()
	if not ice_wand:
		push_warning("[WizardPlayer] ✗ Error: No se pudo instanciar IceWand")
		return
	
	# Configurar propiedades básicas
	ice_wand.name = "Varita de Hielo"
	ice_wand.is_active = true
	
	# Equipar arma (el IceWand ya carga SimpleProjectile internamente)
	var result = equip_weapon(ice_wand)
	
	if result:
		# print("[WizardPlayer] ✓ Ice Wand equipada correctamente")
		pass
	else:
		pass  # Bloque else
		# print("[WizardPlayer] ⚠️ Error al equipar Ice Wand")
		pass

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

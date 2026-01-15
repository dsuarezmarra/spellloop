# WizardPlayer.gd
# Clase base del jugador - Mantiene el nombre por compatibilidad
# Extiende BasePlayer con características y armas específicas del mago

extends BasePlayer
class_name WizardPlayer

# ========== CARACTERÍSTICAS DEL JUGADOR ==========

# Estadísticas específicas (más magia, menos defensa)
# Nota: move_speed, hp, max_hp, armor se heredan de BasePlayer

# Bono de magia
var spell_power: float = 1.2  # 20% más daño en hechizos
var mana: int = 50
var max_mana: int = 50

# ========== ARMAS ==========
var ice_wand = null
var fire_wand = null  # Future

# ========== CICLO DE VIDA ==========

func _ready() -> void:
	"""Inicialización del jugador"""
	# print("\n[WizardPlayer] ===== INICIALIZANDO PLAYER =====")

	# Asignar valores por defecto ANTES de llamar a super
	character_class = "FrostMage"
	character_sprites_key = "frost_mage"

	# Llamar a inicialización base
	super._ready()

	# print("[WizardPlayer] ===== PLAYER INICIALIZADO =====\n")

func set_character_sprites(sprite_folder: String) -> void:
	"""Change the character's sprite folder and reload animations"""
	character_sprites_key = sprite_folder
	_setup_animations()

func _setup_animations() -> void:
	"""Configure animations using strip spritesheets (3 frames per strip, 208x208 each)"""
	if not animated_sprite:
		return

	var frames = SpriteFrames.new()
	var dirs = ["down", "up", "left", "right"]
	var base_path = "res://assets/sprites/players/" + character_sprites_key
	const FRAME_SIZE = 208  # Each frame is 208x208

	# ========== ANIMACIONES DE CAMINAR (3 frames cada una desde strips) ==========
	for dir in dirs:
		var walk_anim = "walk_%s" % dir
		var idle_anim = "idle_%s" % dir

		frames.add_animation(walk_anim)
		frames.add_animation(idle_anim)
		frames.set_animation_speed(walk_anim, 2.5)  # FPS para walk (lento, natural)
		frames.set_animation_speed(idle_anim, 1.0)  # Idle estático
		frames.set_animation_loop(walk_anim, true)
		frames.set_animation_loop(idle_anim, true)

		# Load strip and extract frames
		var strip_path = "%s/walk/walk_%s_strip.png" % [base_path, dir]
		var strip_tex = load(strip_path) as Texture2D
		if strip_tex:
			var strip_image = strip_tex.get_image()
			for i in range(3):
				var frame_region = Rect2i(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
				var frame_image = strip_image.get_region(frame_region)
				var frame_tex = ImageTexture.create_from_image(frame_image)
				frames.add_frame(walk_anim, frame_tex)
				if i == 0:
					frames.add_frame(idle_anim, frame_tex)
		else:
			push_warning("[WizardPlayer] Strip not found: %s" % strip_path)

	# ========== CAST ANIMATION (3 frames desde strip) ==========
	frames.add_animation("cast")
	frames.set_animation_speed("cast", 3.0)
	frames.set_animation_loop("cast", false)

	var cast_strip_path = "%s/cast/cast_strip.png" % base_path
	var cast_strip = load(cast_strip_path) as Texture2D
	if cast_strip:
		var cast_image = cast_strip.get_image()
		for i in range(3):
			var frame_region = Rect2i(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
			var frame_image = cast_image.get_region(frame_region)
			frames.add_frame("cast", ImageTexture.create_from_image(frame_image))

	# ========== HIT ANIMATION (3 frames desde strip) ==========
	frames.add_animation("hit")
	frames.set_animation_speed("hit", 3.0)
	frames.set_animation_loop("hit", false)

	var hit_strip_path = "%s/hit/hit_strip.png" % base_path
	var hit_strip = load(hit_strip_path) as Texture2D
	if hit_strip:
		var hit_image = hit_strip.get_image()
		for i in range(3):
			var frame_region = Rect2i(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
			var frame_image = hit_image.get_region(frame_region)
			frames.add_frame("hit", ImageTexture.create_from_image(frame_image))

	# ========== DEATH ANIMATION (3 frames desde strip) ==========
	frames.add_animation("death")
	frames.set_animation_speed("death", 2.0)
	frames.set_animation_loop("death", false)

	var death_strip_path = "%s/death/death_strip.png" % base_path
	var death_strip = load(death_strip_path) as Texture2D
	if death_strip:
		var death_image = death_strip.get_image()
		for i in range(3):
			var frame_region = Rect2i(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
			var frame_image = death_image.get_region(frame_region)
			frames.add_frame("death", ImageTexture.create_from_image(frame_image))

	# Asignar frames al sprite
	if animated_sprite:
		animated_sprite.sprite_frames = frames
		if frames.has_animation("idle_down"):
			animated_sprite.animation = "idle_down"
		animated_sprite.centered = true
		animated_sprite.play()

func _equip_starting_weapons() -> void:
	"""Equipar armas iniciales basadas en el personaje seleccionado usando BaseWeapon"""
	if not attack_manager:
		return

	# Obtener el arma inicial del personaje seleccionado
	var weapon_id = "ice_wand"  # Default
	if SessionState:
		var character_id = SessionState.get_character()
		weapon_id = CharacterDatabase.get_starting_weapon(character_id)
		print("[WizardPlayer] Character: %s, Starting weapon: %s" % [character_id, weapon_id])

	# Usar el sistema de BaseWeapon + WeaponDatabase (igual que test_weapons)
	if attack_manager.has_method("add_weapon_by_id"):
		var result = attack_manager.add_weapon_by_id(weapon_id)
		if result:
			print("[WizardPlayer] ✓ Arma equipada: %s" % weapon_id)
		else:
			push_warning("[WizardPlayer] ⚠️ Error al equipar arma: %s" % weapon_id)
	else:
		# Fallback: crear BaseWeapon manualmente
		var weapon = BaseWeapon.new(weapon_id)
		if weapon.id.is_empty():
			push_warning("[WizardPlayer] ✗ Error: Arma no encontrada en WeaponDatabase: %s" % weapon_id)
			return
		var result = equip_weapon(weapon)
		if result:
			print("[WizardPlayer] ✓ Arma equipada (fallback): %s" % weapon_id)
		else:
			push_warning("[WizardPlayer] ⚠️ Error al equipar arma: %s" % weapon_id)

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

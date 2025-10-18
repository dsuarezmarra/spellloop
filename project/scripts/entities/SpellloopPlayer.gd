extends CharacterBody2D
class_name SpellloopPlayer

# Señales de daño y muerte
signal player_damaged(amount: int, hp: int)
signal player_died

func take_damage(amount: int) -> void:
	hp -= amount
	emit_signal("player_damaged", amount, hp)
	_play_damage_animation()
	if hp <= 0:
		hp = 0
		emit_signal("player_died")
		_on_player_death()

func _play_damage_animation():
	if animated_sprite:
		animated_sprite.modulate = Color(2, 0.2, 0.2, 1)
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.3)

func _on_player_death():
	set_physics_process(false)
	if animated_sprite:
		animated_sprite.play("down")
		animated_sprite.modulate = Color(0.5, 0.5, 0.5, 0.7)
	# Aquí se puede emitir señal global o llamar a GameManager para game over

# Métodos para obtener vida
func get_hp() -> int:
	return hp

@export var max_hp: int = 100

func get_max_hp() -> int:
	return max_hp

# Player centrado: emite movement_input para que el mundo se mueva en sentido opuesto
signal movement_input(movement_delta: Vector2)

# Stats base
@export var move_speed: float = 220.0
@export var pickup_radius: float = 64.0
@export var hp: int = 100
@export var armor: int = 0
@export var magnet: float = 1.0

# Visual
var animated_sprite: AnimatedSprite2D
var last_dir: String = "down"

func _ready():
	# Usar el AnimatedSprite2D de la escena si existe
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	# Si no existe (script instanciado sin la escena), crear un AnimatedSprite2D mínimo
	if not animated_sprite:
		animated_sprite = AnimatedSprite2D.new()
		animated_sprite.name = "AnimatedSprite2D"
		add_child(animated_sprite)
	setup_animations()
	# Ensure animated sprite is playing by default
	if animated_sprite:
		animated_sprite.play()
		# Set a sensible animation speed
		var sf = animated_sprite.sprite_frames if animated_sprite.sprite_frames else animated_sprite.frames
		if sf:
			# Godot 4: AnimatedSprite2D uses speed_scale for playback speed
			animated_sprite.speed_scale = 6.0
	set_physics_process(true)
	# Configurar capas/máscaras
	set_collision_layer_value(1, true) # Player
	set_collision_mask_value(2, true)  # Enemy
	set_collision_mask_value(4, true)  # EnemyProjectiles
	set_collision_mask_value(5, true)  # Pickups


func setup_animations():
	# Cargar frames reales del wizard desde SpriteDB (runtime-safe)
	var sprite_db = null
	if get_tree() and get_tree().root and get_tree().root.has_node("SpriteDB"):
		sprite_db = get_tree().root.get_node("SpriteDB")
	var frames = SpriteFrames.new()
	var dirs = ["down", "up", "left", "right"]
	var player_sprites = sprite_db.get_player_sprites() if sprite_db else {}
	# Create one placeholder texture to reuse if needed
	var placeholder_tex: Texture2D = null
	for dir in dirs:
		var tex: Texture2D = null
		if player_sprites and player_sprites.has(dir):
			var path = player_sprites[dir]
			if typeof(path) == TYPE_STRING and path != "":
				tex = load(path)
		# Animation names
		var walk_anim = "walk_%s" % dir
		var idle_anim = "idle_%s" % dir
		# Ensure animations exist
		if not frames.has_animation(walk_anim):
			frames.add_animation(walk_anim)
		if not frames.has_animation(idle_anim):
			frames.add_animation(idle_anim)
		if tex:
			frames.add_frame(walk_anim, tex)
			frames.add_frame(walk_anim, tex)
			frames.add_frame(idle_anim, tex)
		else:
			# Create a small green circle placeholder once
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
			# Add placeholder frames
			frames.add_frame(walk_anim, placeholder_tex)
			frames.add_frame(walk_anim, placeholder_tex)
			frames.add_frame(idle_anim, placeholder_tex)
	# Proteger asignaciones en caso de que el nodo AnimatedSprite2D no exista
	if not animated_sprite:
		animated_sprite = get_node_or_null("AnimatedSprite2D")
	if animated_sprite:
		# Assign SpriteFrames to sprite_frames property (Godot 4)
		animated_sprite.sprite_frames = frames
		# Set a sensible default animation if present
		if frames.has_animation("idle_down"):
			animated_sprite.animation = "idle_down"
		else:
			# fallback to first animation
			var anims = frames.get_animation_names()
			if anims.size() > 0:
				animated_sprite.animation = anims[0]
		animated_sprite.centered = true
	z_index = 50

func _physics_process(delta: float) -> void:
	var move_vec = Vector2.ZERO
	var im = null
	if get_tree() and get_tree().root and get_tree().root.has_node("InputManager"):
		im = get_tree().root.get_node("InputManager")
	if im:
		move_vec = im.get_movement_vector()
	else:
		# Fallback to built-in Input map if InputManager autoload missing
		move_vec = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_vec.length() > 0:
		move_vec = move_vec.normalized()
		var movement_delta = move_vec * move_speed * delta
		emit_signal("movement_input", movement_delta)
		update_animation(move_vec)
	else:
		# idle animation
		if animated_sprite:
			animated_sprite.play("idle_%s" % last_dir)

func update_animation(dir: Vector2) -> void:
	if not animated_sprite:
		animated_sprite = get_node_or_null("AnimatedSprite2D")
	if not animated_sprite:
		return
	var d: String = "down"
	if abs(dir.x) > abs(dir.y):
		d = "right" if dir.x > 0 else "left"
	else:
		d = "down" if dir.y > 0 else "up"
	last_dir = d
	if animated_sprite:
		animated_sprite.play("walk_%s" % d)

# Safe stat mod methods
func increase_max_health(amount: int) -> void:
	hp += amount

func heal(amount: int) -> void:
	hp = min(hp + amount, max_hp)

func modify_stat(stat: String, value):
	match stat:
		"move_speed": move_speed *= value
		"max_health": hp += int(value)
		"magnet": magnet *= value
		_:
			pass

func apply_special_effect(_effect_name: String, _item_data: Dictionary) -> void:
	pass

# TestDummy.gd
# Muñeco de prueba para testing de armas
# Tiene HP infinito y registra todo el daño recibido

extends CharacterBody2D
class_name TestDummy

signal damage_received(amount: int, source: String)

var dummy_id: int = 0
var max_hp: int = 99999
var current_hp: int = 99999
var total_damage_received: int = 0
var hit_count: int = 0
var last_hit_time: float = 0.0
var invincible: bool = false

# Visual
var sprite: AnimatedSprite2D = null
var hp_label: Label = null
var damage_popup_container: Node2D = null

func _ready() -> void:
	add_to_group("enemies")
	_setup_visuals()
	_setup_collision()

func _setup_visuals() -> void:
	# Sprite del dummy (círculo rojo)
	sprite = AnimatedSprite2D.new()
	sprite.name = "AnimatedSprite2D"
	
	var frames = SpriteFrames.new()
	frames.add_animation("idle")
	frames.add_animation("hit")
	
	# Frame idle
	var idle_img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	_draw_dummy_circle(idle_img, Color(0.8, 0.2, 0.2), Color(0.5, 0.1, 0.1))
	frames.add_frame("idle", ImageTexture.create_from_image(idle_img))
	
	# Frame hit (más brillante)
	var hit_img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	_draw_dummy_circle(hit_img, Color(1.0, 0.5, 0.5), Color(0.8, 0.2, 0.2))
	frames.add_frame("hit", ImageTexture.create_from_image(hit_img))
	
	sprite.sprite_frames = frames
	sprite.animation = "idle"
	sprite.play()
	add_child(sprite)
	
	# HP Label
	hp_label = Label.new()
	hp_label.name = "HPLabel"
	hp_label.text = "HP: %d" % current_hp
	hp_label.position = Vector2(-40, -50)
	hp_label.add_theme_font_size_override("font_size", 14)
	hp_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(hp_label)
	
	# ID Label
	var id_label = Label.new()
	id_label.name = "IDLabel"
	id_label.text = "#%d" % dummy_id
	id_label.position = Vector2(-10, 35)
	id_label.add_theme_font_size_override("font_size", 12)
	id_label.add_theme_color_override("font_color", Color.YELLOW)
	add_child(id_label)
	
	# Container para popups de daño
	damage_popup_container = Node2D.new()
	damage_popup_container.name = "DamagePopups"
	add_child(damage_popup_container)

func _draw_dummy_circle(img: Image, fill_color: Color, outline_color: Color) -> void:
	var center = Vector2(32, 32)
	var radius = 28.0
	
	for x in range(64):
		for y in range(64):
			var dist = Vector2(x, y).distance_to(center)
			if dist < radius - 2:
				img.set_pixel(x, y, fill_color)
			elif dist < radius:
				img.set_pixel(x, y, outline_color)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	
	# Dibujar una X en el centro (target)
	for i in range(-8, 9):
		var px1 = int(center.x + i)
		var py1 = int(center.y + i)
		var px2 = int(center.x + i)
		var py2 = int(center.y - i)
		if px1 >= 0 and px1 < 64 and py1 >= 0 and py1 < 64:
			img.set_pixel(px1, py1, Color.WHITE)
		if px2 >= 0 and px2 < 64 and py2 >= 0 and py2 < 64:
			img.set_pixel(px2, py2, Color.WHITE)

func _setup_collision() -> void:
	# Collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 28
	collision.shape = shape
	add_child(collision)
	
	# Layer 2 = enemies
	collision_layer = 2
	collision_mask = 0

func take_damage(amount: int, _damage_type: String = "physical") -> void:
	"""Recibir daño - compatible con el sistema de combate"""
	if invincible:
		return
	
	hit_count += 1
	total_damage_received += amount
	current_hp = max(0, current_hp - amount)
	last_hit_time = Time.get_ticks_msec() / 1000.0
	
	# Actualizar label
	if hp_label:
		hp_label.text = "HP: %d" % current_hp
	
	# Efecto visual de hit
	_play_hit_effect()
	
	# Popup de daño
	_spawn_damage_popup(amount)
	
	# Emitir señal
	damage_received.emit(amount, _damage_type)
	
	print("[TestDummy #%d] Recibió %d daño (%s). HP: %d | Total: %d | Hits: %d" % [
		dummy_id, amount, _damage_type, current_hp, total_damage_received, hit_count
	])

func _play_hit_effect() -> void:
	if not sprite:
		return
	
	sprite.animation = "hit"
	sprite.play()
	
	# Flash blanco
	var original_modulate = sprite.modulate
	sprite.modulate = Color.WHITE
	
	# Volver a normal después de un breve momento
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", original_modulate, 0.1)
	tween.tween_callback(func(): sprite.animation = "idle")

func _spawn_damage_popup(amount: int) -> void:
	var popup = Label.new()
	popup.text = "-%d" % amount
	popup.add_theme_font_size_override("font_size", 16)
	popup.add_theme_color_override("font_color", Color.ORANGE_RED)
	popup.position = Vector2(randf_range(-20, 20), -30)
	
	if damage_popup_container:
		damage_popup_container.add_child(popup)
	else:
		add_child(popup)
	
	# Animación de subir y desaparecer
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 50, 0.8)
	tween.tween_property(popup, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(popup.queue_free)

func apply_knockback(force: Vector2) -> void:
	"""Recibir knockback - dummy no se mueve pero registra"""
	print("[TestDummy #%d] Knockback: %s" % [dummy_id, force])

func reset() -> void:
	"""Resetear el dummy a su estado inicial"""
	current_hp = max_hp
	total_damage_received = 0
	hit_count = 0
	
	if hp_label:
		hp_label.text = "HP: %d" % current_hp
	
	# Limpiar popups
	if damage_popup_container:
		for child in damage_popup_container.get_children():
			child.queue_free()

func get_stats() -> Dictionary:
	return {
		"id": dummy_id,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"total_damage": total_damage_received,
		"hits": hit_count,
		"dps": total_damage_received / max(1.0, last_hit_time) if last_hit_time > 0 else 0
	}

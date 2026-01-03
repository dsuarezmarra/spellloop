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

# Knockback y posición
var _original_position: Vector2 = Vector2.ZERO
var _knockback_velocity: Vector2 = Vector2.ZERO
var _return_to_origin: bool = true  # Si debe volver a su posición original
var _return_speed: float = 100.0    # Velocidad de retorno

# Visual
var sprite: AnimatedSprite2D = null
var hp_label: Label = null
var damage_popup_container: Node2D = null

func _ready() -> void:
	add_to_group("enemies")
	_setup_visuals()
	_setup_collision()
	
	# Guardar posición original para volver después del knockback
	_original_position = global_position

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
	
	# Aplicar bonus de shadow_mark si está marcado
	var final_damage = amount
	if _is_shadow_marked:
		final_damage = int(amount * (1.0 + _shadow_mark_bonus))
		print("[TestDummy #%d] 🎯 Shadow Mark! Daño aumentado: %d → %d" % [dummy_id, amount, final_damage])
	
	hit_count += 1
	total_damage_received += final_damage
	current_hp = max(0, current_hp - final_damage)
	last_hit_time = Time.get_ticks_msec() / 1000.0
	
	# Actualizar label
	if hp_label:
		hp_label.text = "HP: %d" % current_hp
	
	# Efecto visual de hit
	_play_hit_effect()
	
	# Popup de daño
	_spawn_damage_popup(final_damage)
	
	# Emitir señal
	damage_received.emit(final_damage, _damage_type)
	
	print("[TestDummy #%d] Recibió %d daño (%s). HP: %d | Total: %d | Hits: %d" % [
		dummy_id, final_damage, _damage_type, current_hp, total_damage_received, hit_count
	])

func _take_direct_damage(amount: int, _damage_type: String = "physical") -> void:
	"""Daño directo sin aplicar shadow_mark (para DoTs)"""
	if invincible:
		return
	
	hit_count += 1
	total_damage_received += amount
	current_hp = max(0, current_hp - amount)
	last_hit_time = Time.get_ticks_msec() / 1000.0
	
	if hp_label:
		hp_label.text = "HP: %d" % current_hp
	
	_spawn_damage_popup(amount)
	damage_received.emit(amount, _damage_type)

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
	"""Recibir knockback - ahora sí mueve al dummy"""
	print("[TestDummy #%d] 💨 Knockback: %s (magnitud: %.1f)" % [dummy_id, force, force.length()])
	
	# Aplicar la fuerza como velocidad
	_knockback_velocity = force

# ═══════════════════════════════════════════════════════════════════════════════
# SISTEMA DE EFECTOS DE ESTADO (igual que EnemyBase)
# ═══════════════════════════════════════════════════════════════════════════════

var _is_stunned: bool = false
var _is_slowed: bool = false
var _is_burning: bool = false
var _is_blinded: bool = false
var _is_pulled: bool = false
var _is_frozen: bool = false
var _is_bleeding: bool = false
var _is_shadow_marked: bool = false

var _base_speed: float = 0.0
var _slow_amount: float = 0.0
var _burn_damage: float = 0.0
var _burn_timer: float = 0.0
var _burn_tick_timer: float = 0.0
var _stun_timer: float = 0.0
var _stun_flash_timer: float = 0.0  # Timer para parpadeo de stun
var _slow_timer: float = 0.0
var _blind_timer: float = 0.0
var _freeze_timer: float = 0.0
var _pull_target: Vector2 = Vector2.ZERO
var _pull_force: float = 0.0
var _pull_timer: float = 0.0

# Bleed effect
var _bleed_damage: float = 0.0
var _bleed_timer: float = 0.0
var _bleed_tick_timer: float = 0.0
const BLEED_TICK_INTERVAL: float = 0.5

# Shadow Mark effect
var _shadow_mark_timer: float = 0.0
var _shadow_mark_bonus: float = 0.0

var _status_tween: Tween = null
var _current_status_color: Color = Color.WHITE

const BURN_TICK_INTERVAL: float = 0.5

func _process(delta: float) -> void:
	_process_status_effects(delta)

func _physics_process(delta: float) -> void:
	_process_knockback_and_return(delta)

func _process_knockback_and_return(delta: float) -> void:
	"""Procesar el movimiento de knockback y retorno a posición original"""
	# Si hay knockback activo, mover
	if _knockback_velocity.length() > 5.0:
		# Aplicar knockback con fricción
		velocity = _knockback_velocity
		move_and_slide()
		
		# Reducir knockback (fricción)
		_knockback_velocity *= 0.85
	else:
		_knockback_velocity = Vector2.ZERO
		
		# Si debe volver a la posición original
		if _return_to_origin:
			var distance_to_origin = global_position.distance_to(_original_position)
			if distance_to_origin > 2.0:
				# Moverse hacia la posición original
				var direction = (_original_position - global_position).normalized()
				velocity = direction * _return_speed
				move_and_slide()
			else:
				# Ya está en posición
				global_position = _original_position
				velocity = Vector2.ZERO

func apply_slow(amount: float, duration: float) -> void:
	"""Aplicar efecto de ralentización"""
	if _is_stunned:
		return
	
	_slow_amount = clamp(amount, 0.0, 0.95)
	_slow_timer = max(_slow_timer, duration)
	_is_slowed = true
	
	_update_status_visual()
	_log_effect("❄️ SLOW", "%.0f%% por %.1fs" % [amount * 100, duration])

func apply_freeze(amount: float, duration: float) -> void:
	"""Aplicar efecto de congelación"""
	_is_frozen = true
	_freeze_timer = max(_freeze_timer, duration)
	_slow_amount = max(_slow_amount, amount)
	_is_slowed = true
	_slow_timer = max(_slow_timer, duration)
	
	_update_status_visual()
	_log_effect("🧊 FREEZE", "%.0f%% por %.1fs" % [amount * 100, duration])

func apply_burn(damage_per_tick: float, duration: float) -> void:
	"""Aplicar efecto de quemadura (DoT)"""
	if _is_burning:
		_burn_damage = max(_burn_damage, damage_per_tick)
		_burn_timer = max(_burn_timer, duration)
	else:
		_burn_damage = damage_per_tick
		_burn_timer = duration
		_burn_tick_timer = 0.0
		_is_burning = true
	
	_update_status_visual()
	_log_effect("🔥 BURN", "%.1f daño/tick por %.1fs" % [damage_per_tick, duration])

func apply_stun(duration: float) -> void:
	"""Aplicar efecto de aturdimiento"""
	_stun_timer = max(_stun_timer, duration)
	_is_stunned = true
	
	_update_status_visual()
	_log_effect("⭐ STUN", "%.1fs" % duration)

func apply_pull(target_position: Vector2, force: float, duration: float) -> void:
	"""Aplicar efecto de atracción"""
	_pull_target = target_position
	_pull_force = force
	_pull_timer = duration
	_is_pulled = true
	
	_update_status_visual()
	_log_effect("🌀 PULL", "hacia %s, fuerza %.1f por %.1fs" % [target_position, force, duration])

func apply_blind(duration: float) -> void:
	"""Aplicar efecto de ceguera"""
	_blind_timer = max(_blind_timer, duration)
	_is_blinded = true
	
	_update_status_visual()
	_log_effect("👁️ BLIND", "%.1fs" % duration)

func apply_bleed(damage_per_tick: float, duration: float) -> void:
	"""Aplicar efecto de sangrado (DoT)"""
	if _is_bleeding:
		_bleed_damage = max(_bleed_damage, damage_per_tick)
		_bleed_timer = max(_bleed_timer, duration)
	else:
		_bleed_damage = damage_per_tick
		_bleed_timer = duration
		_bleed_tick_timer = 0.0
		_is_bleeding = true
	
	_update_status_visual()
	_log_effect("🩸 BLEED", "%.1f daño/tick por %.1fs" % [damage_per_tick, duration])

func apply_shadow_mark(bonus_damage: float, duration: float) -> void:
	"""Aplicar marca de sombra (daño extra)"""
	if _is_shadow_marked:
		_shadow_mark_bonus = max(_shadow_mark_bonus, bonus_damage)
		_shadow_mark_timer = max(_shadow_mark_timer, duration)
	else:
		_shadow_mark_bonus = bonus_damage
		_shadow_mark_timer = duration
		_is_shadow_marked = true
	
	_update_status_visual()
	_log_effect("👤 SHADOW MARK", "+%.0f%% daño por %.1fs" % [bonus_damage * 100, duration])

func _log_effect(effect_name: String, details: String) -> void:
	"""Log de efectos aplicados"""
	print("[TestDummy #%d] %s: %s" % [dummy_id, effect_name, details])

func _update_status_visual() -> void:
	"""Actualizar el color del sprite según los efectos activos"""
	var target_color: Color = Color.WHITE
	
	if _is_stunned:
		target_color = Color(1.0, 1.0, 1.0, 1.0)  # Blanco brillante (el parpadeo lo hace visible)
	elif _is_frozen:
		target_color = Color(0.4, 0.9, 1.0, 1.0)  # Cyan
	elif _is_burning:
		target_color = Color(1.0, 0.5, 0.2, 1.0)  # Naranja
	elif _is_bleeding:
		target_color = Color(0.8, 0.2, 0.3, 1.0)  # Rojo sangre
	elif _is_shadow_marked:
		target_color = Color(0.5, 0.3, 0.7, 1.0)  # Púrpura oscuro
	elif _is_slowed:
		target_color = Color(0.6, 0.8, 1.0, 1.0)  # Azul claro
	elif _is_pulled:
		target_color = Color(0.8, 0.5, 1.0, 1.0)  # Púrpura
	elif _is_blinded:
		target_color = Color(0.4, 0.4, 0.4, 1.0)  # Gris
	
	if target_color != _current_status_color:
		_current_status_color = target_color
		_apply_persistent_color(target_color)

func _apply_persistent_color(color: Color) -> void:
	"""Aplicar color persistente al sprite"""
	if sprite:
		if _status_tween and _status_tween.is_valid():
			_status_tween.kill()
		_status_tween = create_tween()
		_status_tween.tween_property(sprite, "modulate", color, 0.15)

func _flash_damage() -> void:
	"""Flash rápido de daño de burn"""
	if sprite:
		var original = _current_status_color
		var flash_tween = create_tween()
		flash_tween.tween_property(sprite, "modulate", Color(1.0, 0.2, 0.0), 0.05)
		flash_tween.tween_property(sprite, "modulate", original, 0.1)

func _flash_bleed() -> void:
	"""Flash rápido de daño de bleed (rojo sangre)"""
	if sprite:
		var original = _current_status_color
		var flash_tween = create_tween()
		flash_tween.tween_property(sprite, "modulate", Color(0.9, 0.1, 0.2), 0.05)
		flash_tween.tween_property(sprite, "modulate", original, 0.1)

func _flash_stun(delta: float) -> void:
	"""Parpadeo continuo mientras está stuneado - alterna entre blanco y amarillo"""
	_stun_flash_timer += delta
	if _stun_flash_timer >= 0.15:  # Parpadeo cada 0.15s
		_stun_flash_timer = 0.0
		if sprite:
			# Alternar entre blanco brillante y amarillo dorado
			var is_white = sprite.modulate.g > 0.9 and sprite.modulate.b > 0.9
			if is_white:
				sprite.modulate = Color(1.0, 0.9, 0.2, 1.0)  # Amarillo dorado
			else:
				sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)  # Blanco brillante

func _process_status_effects(delta: float) -> void:
	"""Procesar todos los efectos de estado activos"""
	var status_changed: bool = false
	
	# STUN - con efecto de parpadeo
	if _is_stunned:
		_stun_timer -= delta
		# Parpadeo visual mientras está stuneado
		_flash_stun(delta)
		if _stun_timer <= 0:
			_is_stunned = false
			status_changed = true
	
	# FREEZE
	if _is_frozen:
		_freeze_timer -= delta
		if _freeze_timer <= 0:
			_is_frozen = false
			status_changed = true
	
	# SLOW
	if _is_slowed:
		_slow_timer -= delta
		if _slow_timer <= 0:
			_is_slowed = false
			_slow_amount = 0.0
			status_changed = true
	
	# BURN (DoT)
	if _is_burning:
		_burn_timer -= delta
		_burn_tick_timer += delta
		
		if _burn_tick_timer >= BURN_TICK_INTERVAL:
			_burn_tick_timer = 0.0
			take_damage(int(_burn_damage), "burn")
			_flash_damage()
		
		if _burn_timer <= 0:
			_is_burning = false
			_burn_damage = 0.0
			status_changed = true
	
	# BLIND
	if _is_blinded:
		_blind_timer -= delta
		if _blind_timer <= 0:
			_is_blinded = false
			status_changed = true
	
	# BLEED (DoT)
	if _is_bleeding:
		_bleed_timer -= delta
		_bleed_tick_timer += delta
		
		if _bleed_tick_timer >= BLEED_TICK_INTERVAL:
			_bleed_tick_timer = 0.0
			# Daño directo sin aplicar shadow_mark para evitar loops
			_take_direct_damage(int(_bleed_damage), "bleed")
			_flash_bleed()
		
		if _bleed_timer <= 0:
			_is_bleeding = false
			_bleed_damage = 0.0
			status_changed = true
	
	# SHADOW MARK
	if _is_shadow_marked:
		_shadow_mark_timer -= delta
		if _shadow_mark_timer <= 0:
			_is_shadow_marked = false
			_shadow_mark_bonus = 0.0
			status_changed = true
	
	# PULL - ahora sí mueve al dummy hacia el objetivo
	if _is_pulled:
		_pull_timer -= delta
		
		# Calcular dirección hacia el objetivo
		var direction = (_pull_target - global_position).normalized()
		var distance = global_position.distance_to(_pull_target)
		
		# Solo mover si no está muy cerca del objetivo
		if distance > 20.0:
			# Aplicar fuerza de atracción como knockback inverso
			_knockback_velocity = direction * _pull_force * 0.5
		
		if _pull_timer <= 0:
			_is_pulled = false
			status_changed = true
	
	if status_changed:
		_update_status_visual()

func is_stunned() -> bool:
	return _is_stunned

func is_blinded() -> bool:
	return _is_blinded

func get_info() -> Dictionary:
	"""Para efectos como execute que necesitan saber el HP"""
	return {
		"id": dummy_id,
		"hp": current_hp,
		"max_hp": max_hp
	}

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

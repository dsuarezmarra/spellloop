extends CharacterBody2D
class_name EnemyBase

signal enemy_died(enemy_node, enemy_type_id, exp_value)

# Componentes
var health_component = null
var attack_system = null

var enemy_id: String = "generic"
var enemy_tier: int = 1  # Tier del enemigo (1-4 normal, 5 boss)
var max_hp: int = 10
var hp: int = 10
var speed: float = 30.0  # Base reducida a 50% (era ~60, ahora 30)
var damage: int = 5
var exp_value: int = 1
var player_ref: Node = null

# AI parameters (can be overridden in subclasses)
var attack_range: float = 32.0
var separation_radius: float = 40.0
var attack_cooldown: float = 1.0
var can_attack: bool = true
var attack_timer: float = 0.0

func _ready() -> void:
	"""Inicializar al cargar la escena. Ejecutado ANTES de las subclases."""
	# Capas/máscaras: layer=2 (Enemy), mask=3 (PlayerProjectiles) y 1 (Player)
	set_collision_layer_value(2, true)
	set_collision_mask_value(3, true)
	set_collision_mask_value(1, true)
	
	# CRÍTICO: Crear CollisionShape2D si no existe
	var collision_shape = _find_collision_shape_node(self)
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		collision_shape.shape = CircleShape2D.new()
		collision_shape.shape.radius = 16.0  # Radio base del enemigo
		add_child(collision_shape)
	
	# Crear componente de salud
	var hc_script = load("res://scripts/components/HealthComponent.gd")
	if hc_script:
		health_component = hc_script.new()
		health_component.name = "HealthComponent"
		add_child(health_component)
		health_component.initialize(max_hp)
		if health_component.has_signal("died"):
			health_component.died.connect(_on_health_died)
	
	# Crear sistema de ataque
	var eas_script = load("res://scripts/enemies/EnemyAttackSystem.gd")
	if eas_script:
		attack_system = eas_script.new()
		attack_system.name = "AttackSystem"
		add_child(attack_system)
	
	# Asegurar que hay un Sprite2D y cargar su textura
	var sprite = _find_sprite_node(self)
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	
	# Cargar la textura del sprite desde SpriteDB o sprites_index.json
	_load_enemy_sprite(sprite)
	
	# Añadir a grupo de enemigos para detección
	add_to_group("enemies")
	
	# Aplicar escala del enemigo según tier desde VisualCalibrator
	var enemy_scale = 0.2
	var _gt = get_tree()
	if _gt and _gt.root:
		var visual_calibrator = _gt.root.get_node_or_null("VisualCalibrator")
		if visual_calibrator and visual_calibrator.has_method("get_enemy_scale_for_tier"):
			enemy_scale = visual_calibrator.get_enemy_scale_for_tier(enemy_tier)
	
	# Aplicar escala al sprite
	if sprite:
		sprite.scale = Vector2(enemy_scale, enemy_scale)
		sprite.centered = true
	
	# Configurar z_index
	self.z_index = 0
	
	# Inicializar sistema de ataque
	if attack_system:
		attack_system.initialize(
			attack_cooldown,
			attack_range,
			damage,
			false,  # is_ranged
			null    # projectile_scene
		)
		print("[EnemyBase] ✓ Sistema de ataque inicializado para %s" % name)

func initialize(data: Dictionary, player):
	"""Llamado desde EnemyManager para enemies creados dinámicamente"""
	enemy_id = data.get("id", enemy_id)
	enemy_tier = int(data.get("tier", enemy_tier))  # Obtener tier del diccionario
	max_hp = int(data.get("health", max_hp))
	hp = max_hp
	speed = float(data.get("speed", speed))
	damage = int(data.get("damage", damage))
	exp_value = int(data.get("exp_value", exp_value))
	player_ref = player
	
	# Cargar sprite después de establecer enemy_id y enemy_tier
	var sprite = _find_sprite_node(self)
	if not sprite:
		sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		add_child(sprite)
	_load_enemy_sprite(sprite)
	
	# Reapply scaling if needed for dynamically created enemies
	var enemy_scale = 0.2
	if player and player.get_tree() and player.get_tree().root:
		var visual_calibrator = player.get_tree().root.get_node_or_null("VisualCalibrator")
		if visual_calibrator and visual_calibrator.has_method("get_enemy_scale_for_tier"):
			enemy_scale = visual_calibrator.get_enemy_scale_for_tier(enemy_tier)
	
	if sprite:
		sprite.scale = Vector2(enemy_scale, enemy_scale)
		sprite.centered = true

func _find_sprite_node(node: Node) -> Sprite2D:
	"""Buscar el primer Sprite2D en el árbol del nodo"""
	for child in node.get_children():
		if child is Sprite2D:
			return child
	return null

func _find_collision_shape_node(node: Node) -> CollisionShape2D:
	"""Buscar el primer CollisionShape2D en el árbol del nodo"""
	for child in node.get_children():
		if child is CollisionShape2D:
			return child
	return null

func _load_enemy_sprite(sprite: Sprite2D) -> void:
	"""Cargar la textura del sprite según enemy_id y enemy_tier"""
	if not sprite:
		return
	
	# Mapeo de enemy_id a índice en sprites_index.json
	var sprite_paths = []
	match enemy_tier:
		1:
			sprite_paths = [
				"res://assets/sprites/enemies/tier_1/slime_arcano.png",
				"res://assets/sprites/enemies/tier_1/murcielago_etereo.png",
				"res://assets/sprites/enemies/tier_1/esqueleto_aprendiz.png",
				"res://assets/sprites/enemies/tier_1/arana_venenosa.png",
				"res://assets/sprites/enemies/tier_1/duende_sombrio.png"
			]
		2:
			sprite_paths = [
				"res://assets/sprites/enemies/tier_2/guerrero_espectral.png",
				"res://assets/sprites/enemies/tier_2/lobo_de_cristal.png",
				"res://assets/sprites/enemies/tier_2/golem_runico.png",
				"res://assets/sprites/enemies/tier_2/hechicero_desgastado.png",
				"res://assets/sprites/enemies/tier_2/sombra_flotante.png"
			]
		3:
			sprite_paths = [
				"res://assets/sprites/enemies/tier_3/caballero_del_vacio.png",
				"res://assets/sprites/enemies/tier_3/serpiente_de_fuego.png",
				"res://assets/sprites/enemies/tier_3/elemental_de_hielo.png",
				"res://assets/sprites/enemies/tier_3/mago_abismal.png",
				"res://assets/sprites/enemies/tier_3/corruptor_alado.png"
			]
		4:
			sprite_paths = [
				"res://assets/sprites/enemies/tier_4/titan_arcano.png",
				"res://assets/sprites/enemies/tier_4/senor_de_las_llamas.png",
				"res://assets/sprites/enemies/tier_4/reina_del_hielo.png",
				"res://assets/sprites/enemies/tier_4/archimago_perdido.png",
				"res://assets/sprites/enemies/tier_4/dragon_etereo.png"
			]
		5:  # Boss
			sprite_paths = [
				"res://assets/sprites/enemies/bosses/el_conjurador_primigenio.png",
				"res://assets/sprites/enemies/bosses/el_corazon_del_vacio.png",
				"res://assets/sprites/enemies/bosses/el_guardian_de_runas.png",
				"res://assets/sprites/enemies/bosses/minotauro_de_fuego.png"
			]
	
	# Mapeo de enemy_id a índice
	var sprite_index = 0
	match enemy_id:
		# Tier 1
		"skeleton": sprite_index = 2  # esqueleto_aprendiz
		"goblin": sprite_index = 4    # duende_sombrio
		"slime": sprite_index = 0     # slime_arcano
		"tier_1_murcielago_etereo": sprite_index = 1
		"tier_1_arana_venenosa": sprite_index = 3
		# Tier 2
		"tier_2_guerrero_espectral": sprite_index = 0
		"tier_2_lobo_de_cristal": sprite_index = 1
		"tier_2_golem_runico": sprite_index = 2
		"tier_2_hechicero_desgastado": sprite_index = 3
		"tier_2_sombra_flotante": sprite_index = 4
		# Tier 3
		"tier_3_caballero_del_vacio": sprite_index = 0
		"tier_3_serpiente_de_fuego": sprite_index = 1
		"tier_3_elemental_de_hielo": sprite_index = 2
		"tier_3_mago_abismal": sprite_index = 3
		"tier_3_corruptor_alado": sprite_index = 4
		# Tier 4
		"tier_4_titan_arcano": sprite_index = 0
		"tier_4_senor_de_las_llamas": sprite_index = 1
		"tier_4_reina_del_hielo": sprite_index = 2
		"tier_4_archimago_perdido": sprite_index = 3
		"tier_4_dragon_etereo": sprite_index = 4
		# Bosses
		"boss_el_conjurador": sprite_index = 0
		"boss_el_corazon": sprite_index = 1
		"boss_el_guardian": sprite_index = 2
		"boss_minotauro": sprite_index = 3
	
	# Cargar la textura
	if sprite_index < sprite_paths.size():
		var sprite_path = sprite_paths[sprite_index]
		if ResourceLoader.exists(sprite_path):
			var texture = load(sprite_path)
			if texture:
				sprite.texture = texture
			else:
				print("[EnemyBase] Error cargando textura: ", sprite_path)
		else:
			print("[EnemyBase] Ruta de sprite no existe: ", sprite_path)

func _physics_process(delta: float) -> void:
	# Usar GLOBAL_POSITION para ignorar que el parent se mueve
	# El player SIEMPRE está en (0, 0) globalmente en el viewport
	var player_global_pos = Vector2.ZERO
	if player_ref and is_instance_valid(player_ref):
		player_global_pos = player_ref.global_position
	
	var distance_to_player = global_position.distance_to(player_global_pos)
	
	# Calcular dirección hacia el player en coordenadas GLOBALES
	var direction = (player_global_pos - global_position).normalized() if global_position != player_global_pos else Vector2.ZERO
	
	# Calcular separación de otros enemigos
	var separation = _calculate_separation()
	
	# Combinar movimiento: dirección a player + evitar otros enemigos
	var movement = direction * speed + separation
	
	# Si hay movimiento, normalizarlo a speed
	if movement.length() > 0.1:
		movement = movement.normalized() * speed
	
	# CLAVE: Aplicar movimiento en GLOBAL_POSITION
	# Esto ignora completamente que el parent se mueve
	global_position += movement * delta
	
	# Lógica de ataque si está lo suficientemente cerca
	if distance_to_player <= attack_range:
		if can_attack:
			_attempt_attack()
	
	# Actualizar cooldown de ataque
	if not can_attack:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true
			attack_timer = 0.0

func _calculate_separation() -> Vector2:
	"""Calcular vector de separación respecto a otros enemigos cercanos"""
	var separation = Vector2.ZERO
	var nearby_enemies = 0
	
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self or not is_instance_valid(other):
			continue
		
		var dist = global_position.distance_to(other.global_position)
		if dist < separation_radius and dist > 0:
			# Empujar lejos del otro enemigo
			var push_direction = (global_position - other.global_position).normalized()
			var push_strength = (separation_radius - dist) / separation_radius
			separation += push_direction * push_strength * speed * 0.3
			nearby_enemies += 1
	
	# Promediar si hay múltiples enemigos
	if nearby_enemies > 0:
		separation = separation / nearby_enemies
	
	return separation

func _attempt_attack() -> void:
	"""Intentar atacar al player. Puede ser sobrescrito en subclases"""
	can_attack = false
	attack_timer = attack_cooldown
	# Implementación base: sin efecto visual, solo daño
	# Las subclases pueden añadir animaciones y efectos

func take_damage(amount: int) -> void:
	"""Recibir daño del enemigo"""
	# Aplicar daño a través del HealthComponent
	if health_component:
		health_component.take_damage(amount, "physical")
	else:
		# Fallback si no hay HealthComponent (no debería pasar)
		hp -= amount
		if hp <= 0:
			die()

func apply_knockback(knockback_force: Vector2) -> void:
	"""Aplicar knockback (empujón) al enemigo desde un impacto"""
	# El knockback es un impulso instantáneo que aleja al enemigo
	# Se aplica solo una vez y se disipa gradualmente
	print("[EnemyBase] 💨 Knockback recibido: %s por %.1f" % [name, knockback_force.length()])
	
	# Aplicar el knockback directamente a la posición
	# (alternativa: usar una velocidad temporal)
	global_position += knockback_force * 0.1  # Escalar para que no sea demasiado agresivo
	
	# Reproducir efecto visual: hacer parpadear el sprite
	var sprite = _find_sprite_node(self)
	if sprite:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		var original_color = sprite.modulate
		tween.tween_property(sprite, "modulate", Color.WHITE.lightened(0.2), 0.05)
		tween.tween_property(sprite, "modulate", original_color, 0.05)

func die() -> void:
	emit_signal("enemy_died", self, enemy_id, exp_value)
	queue_free()

func _on_health_died() -> void:
	"""Manejar muerte desde HealthComponent"""
	die()

func get_info() -> Dictionary:
	return {"id": enemy_id, "hp": hp, "max_hp": max_hp}


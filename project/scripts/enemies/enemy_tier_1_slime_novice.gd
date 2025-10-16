extends Node2D
# Enemy: Slime Principiante
# Tier 1 (0-5 minutos) - Enemigo básico gelatinoso

@export var enemy_name = "Slime Principiante"
@export var slug = "enemy_tier_1_slime_novice"
@export var difficulty_tier = 1
@export var base_hp = 35
@export var base_speed = 45.0
@export var base_damage = 4
@export var xp_drop = 3
@export var size_px = 64
@export var collider_radius = 26.0
@export var attack_type = "melee"
@export var attack_rate = 1.5
@export var movement_behavior = "seek"
@export var sprite_path = "res://assets/sprites/enemies/enemy_tier_1_slime_novice.png"
@export var is_special_variant = false

# Variables internas
var current_hp: int
var player_reference: Node
var attack_timer: float = 0.0
var scale_manager: Node

func _ready():
	# Configurar sprite
	if has_node("Sprite"):
		$Sprite.texture = load(sprite_path)
	
	# Obtener referencias
	scale_manager = get_node("/root/ScaleManager")
	player_reference = get_tree().get_first_node_in_group("player")
	
	# Configurar vida según el tiempo transcurrido
	current_hp = calculate_scaled_hp()
	
	# Configurar collider
	if has_node("CollisionShape2D"):
		var shape = CircleShape2D.new()
		shape.radius = collider_radius * scale_manager.current_scale
		$CollisionShape2D.shape = shape

func _physics_process(delta):
	if not player_reference:
		return
	
	# Comportamiento de búsqueda simple
	seek_player(delta)
	
	# Manejar ataque
	handle_attack(delta)

func seek_player(delta):
	var direction = (player_reference.global_position - global_position).normalized()
	var scaled_speed = base_speed * scale_manager.current_scale
	global_position += direction * scaled_speed * delta

func handle_attack(delta):
	attack_timer -= delta
	
	if attack_timer <= 0.0:
		var distance_to_player = global_position.distance_to(player_reference.global_position)
		var attack_range = collider_radius * 1.5
		
		if distance_to_player <= attack_range:
			perform_attack()
			attack_timer = attack_rate

func perform_attack():
	# Implementar ataque básico de contacto
	if player_reference.has_method("take_damage"):
		var damage = calculate_scaled_damage()
		player_reference.take_damage(damage)

func take_damage(amount: int):
	current_hp -= amount
	
	# Efecto visual de daño (opcional)
	modulate = Color.RED
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	if current_hp <= 0:
		_on_death()

func _on_death():
	drop_xp(calculate_scaled_xp())
	maybe_drop_item()
	queue_free()

func drop_xp(amount: int):
	# Crear bolita de experiencia
	var xp_scene = preload("res://scenes/effects/XPOrb.tscn")
	if xp_scene:
		var xp_orb = xp_scene.instance()
		get_parent().add_child(xp_orb)
		xp_orb.global_position = global_position
		xp_orb.xp_value = amount

func maybe_drop_item():
	# Probabilidad básica de drop
	var drop_chance = 0.05  # 5% base
	if is_special_variant:
		drop_chance = 1.0  # Variantes especiales siempre dropean
	
	if randf() < drop_chance:
		var item_manager = get_node("/root/ItemManager")
		if item_manager and item_manager.has_method("spawn_item_drop"):
			var rarity = 0  # ItemsDefinitions.ItemRarity.WHITE
			if is_special_variant:
				rarity = 1  # ItemsDefinitions.ItemRarity.BLUE
			item_manager.spawn_item_drop(global_position, rarity)

# Funciones de cálculo de escalado
func calculate_scaled_hp() -> int:
	var game_manager = get_node("/root/GameManager")
	var minutes_elapsed = 0
	if game_manager and game_manager.has_method("get_elapsed_minutes"):
		minutes_elapsed = game_manager.get_elapsed_minutes()
	
	# Fórmula: hp(tier, minute) = round(base_hp * (1 + 0.12 * minute) * (1 + 0.25*(tier-1)))
	var hp = base_hp * (1 + 0.12 * minutes_elapsed) * (1 + 0.25 * (difficulty_tier - 1))
	return int(round(hp))

func calculate_scaled_damage() -> int:
	var game_manager = get_node("/root/GameManager")
	var minutes_elapsed = 0
	if game_manager and game_manager.has_method("get_elapsed_minutes"):
		minutes_elapsed = game_manager.get_elapsed_minutes()
	
	# Fórmula: damage(tier, minute) = round(base_damage * (1 + 0.09 * minute))
	var damage = base_damage * (1 + 0.09 * minutes_elapsed)
	return int(round(damage))

func calculate_scaled_xp() -> int:
	# Fórmula: xp_drop = round(base_xp * (1 + 0.1 * tier))
	var xp = xp_drop * (1 + 0.1 * difficulty_tier)
	if is_special_variant:
		xp *= 2  # Variantes especiales dan doble XP
	return int(round(xp))

func _on_spawn(spawn_position: Vector2):
	global_position = spawn_position
	
	# Configurar variante especial si aplica
	if is_special_variant:
		name = "Slime Dorado"
		modulate = Color.YELLOW  # Color opuesto de la paleta
		current_hp = int(current_hp * 1.5)  # 50% más vida
		scale *= 1.2  # Ligeramente más grande

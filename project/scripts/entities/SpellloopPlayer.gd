extends CharacterBody2D
class_name SpellloopPlayer

# SpellloopPlayer.gd - Wrapper que carga WizardPlayer dinámicamente
# Mantiene compatibilidad con la escena y otros scripts

var wizard_player = null

signal player_damaged(amount: int, hp: int)
signal player_died

var hp: int = 100
var max_hp: int = 100
var move_speed: float = 220.0
var armor: int = 0
var magnet: float = 1.0
var pickup_radius: float = 64.0

var health_component = null
var animated_sprite: AnimatedSprite2D = null
var last_dir: String = "down"
var health_bar_container: Node2D = null

func _ready() -> void:
	print("\n[SpellloopPlayer] ===== INICIANDO SPELLLOOP PLAYER =====")
	
	var wizard_script = load("res://scripts/entities/players/WizardPlayer.gd")
	if not wizard_script:
		print("[SpellloopPlayer] ERROR: No se pudo cargar WizardPlayer.gd")
		return
	
	print("[SpellloopPlayer] OK: WizardPlayer.gd cargado")
	
	wizard_player = wizard_script.new()
	if not wizard_player:
		print("[SpellloopPlayer] ERROR: No se pudo instanciar WizardPlayer")
		return
	
	# Pasar referencia al AnimatedSprite2D ANTES de add_child() para que _ready() la tenga disponible
	wizard_player.animated_sprite = get_node_or_null("AnimatedSprite2D")
	if not wizard_player.animated_sprite:
		print("[SpellloopPlayer] ERROR: No se pudo encontrar AnimatedSprite2D")
		return
	
	# CRÍTICO: Anexar WizardPlayer como nodo hijo
	# add_child() automáticamente llamará a _ready() del nodo hijo
	# NO llamar explícitamente a wizard_player._ready() para evitar inicialización duplicada
	add_child(wizard_player)
	wizard_player.name = "WizardPlayer"
	
	wizard_player.global_position = global_position
	
	if wizard_player.has_signal("player_damaged"):
		wizard_player.player_damaged.connect(_on_wizard_damaged)
	if wizard_player.has_signal("player_died"):
		wizard_player.player_died.connect(_on_wizard_died)
	
	# Actualizar referencias después de que WizardPlayer ya fue inicializado
	animated_sprite = wizard_player.animated_sprite
	health_component = wizard_player.health_component
	health_bar_container = wizard_player.health_bar_container
	
	hp = wizard_player.hp
	max_hp = wizard_player.max_hp
	move_speed = wizard_player.move_speed
	
	print("[SpellloopPlayer] ===== OK: SPELLLOOP PLAYER LISTO =====\n")

func _physics_process(_delta: float) -> void:
	# Obtener input del jugador
	var input_manager = get_tree().root.get_node_or_null("InputManager")
	if not input_manager:
		return
	
	var movement_input = input_manager.get_movement_vector()
	velocity = movement_input * move_speed
	move_and_slide()
	
	# Sincronizar posición con WizardPlayer (para que sus sistemas funcionen)
	if wizard_player:
		wizard_player.global_position = global_position

func _on_wizard_damaged(amount: int, current_hp: int) -> void:
	hp = current_hp
	player_damaged.emit(amount, current_hp)
	_play_damage_animation()

func _on_wizard_died() -> void:
	player_died.emit()

func take_damage(amount: int) -> void:
	if wizard_player:
		wizard_player.take_damage(amount)
	hp = wizard_player.hp if wizard_player else hp

func heal(amount: int) -> void:
	if wizard_player:
		wizard_player.heal(amount)

func _play_damage_animation() -> void:
	if animated_sprite:
		animated_sprite.modulate = Color(2, 0.2, 0.2, 1)
		var tween = create_tween()
		tween.tween_property(animated_sprite, "modulate", Color(1, 1, 1, 1), 0.3)

func update_health_bar() -> void:
	if not health_bar_container:
		return
	
	var health_bar = health_bar_container.get_node_or_null("HealthBar")
	if health_bar:
		var health_percent = float(hp) / float(max_hp)
		health_bar.size.x = 40.0 * health_percent

func get_hp() -> int:
	return hp

func get_max_hp() -> int:
	return max_hp

func get_health() -> Dictionary:
	## Retorna un diccionario con la salud actual y máxima
	return {"current": hp, "max": max_hp}

func increase_max_health(amount: int) -> void:
	if wizard_player:
		wizard_player.max_hp += amount
	max_hp = wizard_player.max_hp if wizard_player else max_hp
	hp = wizard_player.hp if wizard_player else hp
	update_health_bar()

func modify_stat(stat: String, value) -> void:
	if not wizard_player:
		return
	
	match stat:
		"move_speed":
			wizard_player.move_speed *= value
		"max_health":
			wizard_player.max_hp += int(value)
		"magnet":
			wizard_player.magnet *= value

func apply_special_effect(_effect_name: String, _item_data: Dictionary) -> void:
	pass

func setup_animations() -> void:
	if wizard_player and wizard_player.has_method("_setup_animations"):
		wizard_player._setup_animations()

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

func create_health_bar() -> void:
	if not health_bar_container:
		health_bar_container = Node2D.new()
		health_bar_container.name = "HealthBarContainer"
		add_child(health_bar_container)
		
		var bg_bar = ColorRect.new()
		bg_bar.size = Vector2(40, 4)
		bg_bar.color = Color(0.3, 0.3, 0.3, 0.8)
		bg_bar.position = Vector2(-20, -35)
		health_bar_container.add_child(bg_bar)
		
		var health_bar = ColorRect.new()
		health_bar.name = "HealthBar"
		health_bar.size = Vector2(40, 4)
		health_bar.color = Color(0.0, 1.0, 0.0, 0.9)
		health_bar.position = Vector2(-20, -35)
		health_bar_container.add_child(health_bar)
	
	update_health_bar()

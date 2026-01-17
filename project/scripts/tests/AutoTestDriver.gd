extends Node
class_name AutoTestDriver

# Configuración
var change_dir_interval: float = 2.0
var timer: float = 0.0
var current_dir: Vector2 = Vector2.ZERO
var input_actions = ["move_up", "move_down", "move_left", "move_right"]

func _ready() -> void:
	print("🚗 [AutoTestDriver] Driver initialized. Scanning game context...")
	_randomize_direction()

func _process(delta: float) -> void:
	timer -= delta
	if timer <= 0:
		_randomize_direction()
		timer = change_dir_interval

	_apply_input()
	_log_stats()

func _randomize_direction() -> void:
	_release_all()
	
	# Elegir una dirección aleatoria
	var dirs = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT, Vector2(1,1).normalized(), Vector2(-1,1).normalized()]
	current_dir = dirs[randi() % dirs.size()]
	
	# Simular pulsación de teclas según el vector
	if current_dir.y < -0.1: Input.action_press("move_up")
	if current_dir.y > 0.1: Input.action_press("move_down")
	if current_dir.x < -0.1: Input.action_press("move_left")
	if current_dir.x > 0.1: Input.action_press("move_right")

func _release_all() -> void:
	for action in input_actions:
		if Input.is_action_pressed(action):
			Input.action_release(action)

func _apply_input() -> void:
	# Mantener inputs de disparo siempre activos
	# Asumimos que el juego dispara automáticamente o con click
	# Si dispara con click, pulsamos 'cast_spell' o similar
	# Pero en Vampire Survivors suele ser auto-fire. 
	# Si hay action 'shoot', la pulsamos.
	pass

func _log_stats() -> void:
	# Intentar leer stats del Game
	# Buscamos el nodo 'Game' en los padres
	var game_node = get_parent()
	if game_node and "run_stats" in game_node:
		# Log cada 5 segundos aprox (usando frame count o timer)
		if Engine.get_frames_drawn() % 300 == 0:
			var s = game_node.run_stats
			print("📊 [Sim] Time: %.1f | Lvl: %d | Kills: %d | HP: %s" % [
				s.get("time", 0), 
				s.get("level", 1), 
				s.get("kills", 0),
				_get_player_hp(game_node)
			])

func _get_player_hp(game_node) -> String:
	if game_node.player and is_instance_valid(game_node.player):
		# Intento genérico de sacar HP
		if "health_component" in game_node.player and game_node.player.health_component:
			return "%d/%d" % [game_node.player.health_component.current_health, game_node.player.health_component.max_health]
	return "?/?"

func _exit_tree() -> void:
	_release_all()

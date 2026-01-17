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
	_handle_popups()
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

func _handle_popups() -> void:
	"""Detectar y manejar popups que pausan el juego (Level Up, Cofres, etc)"""
	# Buscar LevelUpPanel en la raíz o en los hijos directos de root
	var level_up_panel = _find_node_by_class(get_tree().root, "LevelUpPanel")
	
	if not level_up_panel:
		# Intentar buscar por nombre si no se encuentra por clase
		level_up_panel = get_tree().root.find_child("LevelUpPanel", true, false)
	
	if level_up_panel and level_up_panel.visible and not level_up_panel.is_queued_for_deletion():
		# Verificar si ya estamos procesando para no spammear
		if not level_up_panel.has_meta("auto_selecting"):
			level_up_panel.set_meta("auto_selecting", true)
			print("[AutoTest] 🆙 LevelUpPanel detectado. Auto-seleccionando opción...")
			
			# Simular pulsación de ENTER si el método directo falla
			if level_up_panel.has_method("_select_option"):
				# Llamar directamente (hack para tests)
				level_up_panel._select_option()
			else:
				_simulate_key_press(KEY_ENTER)

	# Buscar ChestPanel (si existe)
	var chest_panel = get_tree().root.find_child("ChestPanel", true, false)
	if chest_panel and chest_panel.visible and not chest_panel.is_queued_for_deletion():
		if not chest_panel.has_meta("auto_opening"):
			chest_panel.set_meta("auto_opening", true)
			print("[AutoTest] 🎁 ChestPanel detectado. Auto-abriendo...")
			_simulate_key_press(KEY_ENTER)

func _find_node_by_class(root: Node, class_str: String) -> Node:
	if root.is_class(class_str) or (root.get_script() and root.get_script().resource_path.ends_with(class_str + ".gd")):
		return root
	
	for child in root.get_children():
		var res = _find_node_by_class(child, class_str)
		if res: return res
	return null

func _simulate_key_press(key: int) -> void:
	var ev = InputEventKey.new()
	ev.keycode = key
	ev.pressed = true
	Input.parse_input_event(ev)
	# No esperamos aquí porque estamos en _process, solo enviamos el evento
	# El release lo hará el próximo frame o inmediatamente
	Input.action_press("ui_accept") # Generic accept fallback

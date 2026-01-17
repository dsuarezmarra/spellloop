extends Node

func _ready() -> void:
	print("🚀 [SimulationBoot] Starting REAL GAME simulation...")
	
	# 1. Configurar SessionState (Forzar personaje)
	if SessionState:
		SessionState.selected_character_id = "frost_mage" # Asegurar que existe esta propiedad o usar set_character
		# Si SessionState usa un método:
		if SessionState.has_method("set_character"):
			SessionState.set_character("frost_mage")
	
	# 2. Cargar escena del juego real
	# Usamos call_deferred para dar tiempo a que los Autoloads se asienten
	call_deferred("_start_game_scene")

func _start_game_scene() -> void:
	var game_scene = load("res://scenes/game/Game.tscn")
	if not game_scene:
		push_error("❌ Could not load Game.tscn")
		return
		
	var game_instance = game_scene.instantiate()
	get_tree().root.add_child(game_instance)
	
	# 3. Inyectar el Driver
	var driver_script = load("res://scripts/tests/AutoTestDriver.gd")
	var driver = driver_script.new()
	driver.name = "AutoTestDriver"
	game_instance.add_child(driver)
	
	print("✅ Game Scene instantiated and Driver injected.")
	
	# Eliminar este nodo bootstrapper ya que el juego corre en paralelo
	# queue_free() 
	# Mejor no borrarlo por si queremos reiniciar

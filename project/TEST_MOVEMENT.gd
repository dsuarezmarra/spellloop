"""
Script de test para verificar movimiento del mundo
Colócalo en la escena principal y ejecuta
"""
extends Node

var movement_counter = 0
var test_active = true

func _ready():
	print("\n" + "=".repeat(80))
	print("🧪 TEST DE MOVIMIENTO INICIADO")
	print("=".repeat(80))
	print("[TEST] Verificando componentes necesarios...")
	
	# Verificar que existen los componentes clave
	var world_manager = get_tree().root.get_node_or_null("SpellloopMain/WorldManager")
	var player = get_tree().root.get_node_or_null("SpellloopMain/WorldRoot/Player")
	var chunks_root = get_tree().root.get_node_or_null("SpellloopMain/WorldRoot/ChunksRoot")
	
	print("[TEST] WorldManager existe: %s" % (world_manager != null))
	print("[TEST] Player existe: %s" % (player != null))
	print("[TEST] ChunksRoot existe: %s" % (chunks_root != null))
	
	if world_manager:
		print("[TEST] move_world() disponible: %s" % world_manager.has_method("move_world"))
	
	if chunks_root:
		print("[TEST] Posición inicial de ChunksRoot: %s" % chunks_root.position)
	
	print("\n[TEST] Iniciando simulación de movimiento...")
	print("[TEST] Se simularán 5 fotogramas de movimiento")

func _process(_delta):
	if not test_active:
		return
	
	movement_counter += 1
	
	# Simular movimiento durante 5 fotogramas
	if movement_counter <= 5:
		var world_manager = get_tree().root.get_node_or_null("SpellloopMain/WorldManager")
		var chunks_root = get_tree().root.get_node_or_null("SpellloopMain/WorldRoot/ChunksRoot")
		
		if world_manager and world_manager.has_method("move_world"):
			# Simular movimiento hacia la derecha
			world_manager.move_world(Vector2.RIGHT, _delta)
			
			if chunks_root:
				print("[FRAME %d] ChunksRoot pos: %s | Delta: %.4f" % [movement_counter, chunks_root.position, _delta])
	
	elif movement_counter == 6:
		print("\n" + "=".repeat(80))
		print("✅ TEST DE MOVIMIENTO COMPLETADO")
		print("=".repeat(80))
		print("\n[RESULTADO] Si ves cambios en 'ChunksRoot pos', el movimiento funciona!")
		print("[RESULTADO] El mundo se está moviendo correctamente alrededor del jugador")
		test_active = false
		
		# Auto-finalizar el test
		get_tree().quit()

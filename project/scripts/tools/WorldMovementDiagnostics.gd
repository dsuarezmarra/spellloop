# OBSOLETE-SCRIPT: este script parece no usarse actualmente. Verificar antes de eliminar.
# Originalmente: WorldMovementDiagnostics.gd - Script de diagnóstico de movimiento del mundo
# Razón: Cargado dinámicamente desde SpellloopGame pero es principalmente para debugging

extends Node
class_name WorldMovementDiagnostics

"""
Diagnóstico avanzado del sistema de movimiento del mundo
Verifica la jerarquía de nodos, referencias, y estado del movimiento
"""

var frame_count: int = 0
var last_chunks_root_pos: Vector2 = Vector2.ZERO
var last_player_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	var sep = "="
	print("\n" + sep.repeat(70))
	print("🔍 WORLD MOVEMENT DIAGNOSTICS INITIALIZED")
	print(sep.repeat(70) + "\n")
	set_process(true)

func _process(_delta: float) -> void:
	frame_count += 1
	
	# Mostrar diagnóstico cada 120 frames (cada 2 segundos a 60 FPS)
	if frame_count % 120 == 0:
		_run_diagnostics()

func _run_diagnostics() -> void:
	"""Ejecutar diagnóstico completo"""
	var sep = "-"
	print("\n" + sep.repeat(70))
	print("[FRAME %d] 🔍 DIAGNOSTICS CHECK" % frame_count)
	print(sep.repeat(70))
	
	# 1. Verificar estructura de nodos
	_check_node_structure()
	
	# 2. Verificar referencias
	_check_references()
	
	# 3. Verificar movimiento
	_check_movement()
	
	print(sep.repeat(70) + "\n")

func _check_node_structure() -> void:
	"""Verificar la jerarquía de nodos"""
	print("1️⃣  NODE STRUCTURE:")
	
	var root = get_tree().root
	if not root:
		print("  ❌ get_tree().root is null")
		return
	
	# Buscar SpellloopMain
	var spellloop_main = root.get_node_or_null("SpellloopMain")
	if spellloop_main:
		print("  ✓ SpellloopMain found")
		
		# Buscar WorldRoot
		var world_root = spellloop_main.get_node_or_null("WorldRoot")
		if world_root:
			print("  ✓ WorldRoot found")
			
			# Listar hijos de WorldRoot
			var child_names = []
			for child in world_root.get_children():
				child_names.append(child.name)
			print("    Children: %s" % child_names)
			
			# Buscar ChunksRoot
			var chunks_root = world_root.get_node_or_null("ChunksRoot")
			if chunks_root:
				print("  ✓ ChunksRoot found at WorldRoot/ChunksRoot")
				print("    Position: %s" % chunks_root.position)
				print("    Global Position: %s" % chunks_root.global_position)
				print("    Children count: %d" % chunks_root.get_child_count())
			else:
				print("  ❌ ChunksRoot NOT found at WorldRoot/ChunksRoot")
		else:
			print("  ❌ WorldRoot NOT found")
	else:
		print("  ❌ SpellloopMain NOT found")
	
	# Buscar Camera2D
	var camera = root.get_node_or_null("SpellloopMain/WorldRoot/Camera2D")
	if camera:
		print("  ✓ Camera2D found")
		print("    Position: %s" % camera.position)
		print("    Current: %s" % camera.current)
	else:
		print("  ❌ Camera2D NOT found")

func _check_references() -> void:
	"""Verificar referencias del SpellloopGame"""
	print("\n2️⃣  REFERENCES:")
	
	var spellloop_main = get_tree().root.get_node_or_null("SpellloopMain")
	
	if spellloop_main:
		print("  ✓ SpellloopMain found (this IS SpellloopGame)")
		
		# Verificar player
		if spellloop_main.get("player"):
			var player = spellloop_main.get("player")
			if player:
				print("  ✓ player: %s (position: %s)" % [player.name, player.position])
			else:
				print("  ⚠️  player field exists but is null")
		else:
			print("  ❌ player field not found")
		
		# Verificar world_manager
		if spellloop_main.get("world_manager"):
			var wm = spellloop_main.get("world_manager")
			print("  ✓ world_manager: %s" % wm.name)
			
			# Verificar chunks_root en world_manager
			if wm.get("chunks_root"):
				var cr = wm.get("chunks_root")
				if cr:
					print("    ✓ chunks_root assigned: %s" % cr.name)
				else:
					print("    ❌ chunks_root is null")
			else:
				print("    ❌ chunks_root field not found")
		else:
			print("  ❌ world_manager NOT found")
		
		# Verificar world_camera
		if spellloop_main.get("world_camera"):
			var cam = spellloop_main.get("world_camera")
			if cam:
				print("  ✓ world_camera: Camera2D (current: %s)" % cam.current)
			else:
				print("  ❌ world_camera is null")
		else:
			print("  ❌ world_camera field not found")
	else:
		print("  ❌ SpellloopMain NOT found")

func _check_movement() -> void:
	"""Verificar estado del movimiento"""
	print("\n3️⃣  MOVEMENT STATE:")
	
	var root = get_tree().root
	if not root:
		return
	
	var spellloop_main = root.get_node_or_null("SpellloopMain")
	var player = null
	var chunks_root = null
	var world_camera = null
	
	if spellloop_main:
		player = spellloop_main.get("player")
		var wm = spellloop_main.get("world_manager")
		if wm:
			chunks_root = wm.get("chunks_root")
		world_camera = spellloop_main.get("world_camera")
	
	if player:
		print("  Player position: %s" % player.position)
		print("  Player global_position: %s" % player.global_position)
		
		if player.position != last_player_pos:
			print("  ➡️  Player MOVED")
			last_player_pos = player.position
		else:
			print("  ⚠️  Player NOT moving (same position)")
	else:
		print("  ❌ Player not found")
	
	if chunks_root:
		print("  ChunksRoot position: %s" % chunks_root.position)
		
		if chunks_root.position != last_chunks_root_pos:
			print("  ➡️  ChunksRoot MOVED")
			last_chunks_root_pos = chunks_root.position
		else:
			print("  ⚠️  ChunksRoot NOT moving (same position)")
	else:
		print("  ❌ ChunksRoot not found")
	
	if world_camera:
		print("  Camera position: %s" % world_camera.position)
	else:
		print("  ❌ Camera not found")
	
	# Verificar InputManager
	var input_mgr = root.get_node_or_null("InputManager")
	if input_mgr and input_mgr.has_method("get_movement_vector"):
		var dir = input_mgr.get_movement_vector()
		print("  InputManager movement_vector: %s" % dir)
		if dir.length() == 0:
			print("  ⚠️  No input detected!")
	else:
		print("  ❌ InputManager or get_movement_vector not found")
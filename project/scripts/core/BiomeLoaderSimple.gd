extends Node
## Script para cargar BiomeChunkApplier y conectarlo al jugador
## Simplemente adjunta este script a un nodo en tu escena principal
## 
## El script:
## 1. Carga BiomeChunkApplier automáticamente
## 2. Lo conecta al jugador
## 3. Maneja las actualizaciones de posición
## 4. Imprime logs de debug

class_name BiomeLoaderSimple

@export var enable_debug: bool = true
@export var player_node_name: String = "SpellloopPlayer"

var _biome_applier: BiomeChunkApplier = null
var _player: Node2D = null

func _ready():
	print("[BiomeLoader] Iniciando cargador de biomas...")
	
	# Cargar BiomeChunkApplier
	var applier_script = load("res://scripts/core/BiomeChunkApplier.gd")
	if applier_script == null:
		print("[BiomeLoader] ERROR: No se pudo cargar BiomeChunkApplier.gd")
		return
	
	# Crear instancia
	_biome_applier = applier_script.new()
	_biome_applier.config_path = "res://assets/textures/biomes/biome_textures_config.json"
	_biome_applier.enable_debug = enable_debug
	add_child(_biome_applier)
	
	print("[BiomeLoader] BiomeChunkApplier inicializado")
	
	# Buscar jugador
	_player = get_tree().root.find_child(player_node_name, true, false) as Node2D
	if _player:
		print("[BiomeLoader] Jugador encontrado: %s" % player_node_name)
	else:
		print("[BiomeLoader] Advertencia: Jugador no encontrado. Se actualizará por posición del mouse.")

func _process(_delta: float) -> void:
	if _biome_applier == null:
		return
	
	# Actualizar posición desde el jugador o desde la cámara
	var update_pos = Vector2.ZERO
	
	if _player:
		update_pos = _player.global_position
	else:
		# Usar posición de la cámara como fallback
		var camera = get_viewport().get_camera_2d()
		if camera:
			update_pos = camera.global_position
		else:
			# Último recurso: usar posición del mouse
			update_pos = get_viewport().get_mouse_position()
	
	_biome_applier.on_player_position_changed(update_pos)

func get_biome_applier() -> BiomeChunkApplier:
	return _biome_applier

func get_player() -> Node2D:
	return _player

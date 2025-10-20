extends Node
## Script simplificado para validar que el sistema de biomas está funcionando
## Sin depender de texturas específicas

class_name BiomeLoaderDebug

const SEPARATOR = "══════════════════════════════════════════════════════════════════════════"

@export var enable_debug: bool = true
@export var player_node_name: String = "SpellloopPlayer"

var _player: Node2D = null
var _chunk_size: int = 5760
var _last_chunk: Vector2i = Vector2i.ZERO

func _ready():
	print("\n" + SEPARATOR)
	print("🌍 BIOME SYSTEM INITIALIZED")
	print(SEPARATOR)
	print("[BiomeLoader] Starting biome system initialization...")
	
	# Buscar jugador
	_player = get_tree().root.find_child(player_node_name, true, false) as Node2D
	if _player:
		print("[BiomeLoader] ✅ Player found: %s" % player_node_name)
	else:
		print("[BiomeLoader] ⚠️  Player not found, using fallback positions")
	
	# Verificar que la config existe
	var config_path = "res://assets/textures/biomes/biome_textures_config.json"
	if ResourceLoader.exists(config_path):
		print("[BiomeLoader] ✅ Biome config found at: %s" % config_path)
		_load_and_print_config()
	else:
		print("[BiomeLoader] ❌ Config not found at: %s" % config_path)
	
	print(SEPARATOR + "\n")

func _load_and_print_config() -> void:
	"""Cargar y mostrar la configuración de biomas"""
	var config_path = "res://assets/textures/biomes/biome_textures_config.json"
	var file = FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		print("[BiomeLoader] ❌ Could not open config file")
		return
	
	var json_string = file.get_as_text()
	var json = JSON.new()
	var parse_error = json.parse(json_string)
	
	if parse_error != OK:
		print("[BiomeLoader] ❌ JSON parse error: %s" % json.get_error_message())
		return
	
	var config = json.get_data()
	var biomes = config.get("biomes", [])
	
	print("[BiomeLoader] ✅ Available biomes:")
	for biome in biomes:
		var biome_name = biome.get("name", "Unknown")
		var biome_id = biome.get("id", -1)
		print("    - %s (ID: %d)" % [biome_name, biome_id])

func _process(_delta: float) -> void:
	if _player == null:
		return
	
	var player_pos = _player.global_position
	var current_chunk = Vector2i((player_pos / _chunk_size).round())
	
	# Solo mostrar cuando cambia de chunk
	if current_chunk != _last_chunk:
		_last_chunk = current_chunk
		print("[BiomeLoader] Chunk changed: (%d, %d) | Player pos: %.1f, %.1f" % [
			current_chunk.x, current_chunk.y, player_pos.x, player_pos.y
		])

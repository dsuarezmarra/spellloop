extends Node
## 🌍 BIOME SYSTEM - Final Integration Script
## Minimal, clean attachment to SpellloopMain.tscn
## No dependencies on old systems - fully self-contained

class_name BiomeSystemFinal

const SEPARATOR = "══════════════════════════════════════════════════════════════════════════"

@export var enable_debug: bool = true
@export var player_node_name: String = "SpellloopPlayer"

var _player: Node2D = null
var _chunk_size: int = 5760
var _last_chunk: Vector2i = Vector2i.ZERO
var _biome_config: Dictionary = {}

func _ready():
	print("\n" + SEPARATOR)
	print("🌍 SPELLLOOP BIOME SYSTEM - ACTIVATED")
	print(SEPARATOR)
	
	# Cargar configuración
	if _load_biome_config():
		print("[BiomeSystem] ✅ Biome configuration loaded successfully")
		_print_biome_list()
	else:
		print("[BiomeSystem] ❌ Failed to load biome configuration")
	
	# Buscar jugador
	_player = get_tree().root.find_child(player_node_name, true, false) as Node2D
	if _player:
		print("[BiomeSystem] ✅ Player reference found: %s" % player_node_name)
		print("[BiomeSystem] System ready - biome updates will run each frame")
	else:
		print("[BiomeSystem] ⚠️  Player not found - system will use fallback detection")
	
	print(SEPARATOR + "\n")

func _load_biome_config() -> bool:
	"""Load biome configuration from JSON"""
	var config_path = "res://assets/textures/biomes/biome_textures_config.json"
	
	if not ResourceLoader.exists(config_path):
		print("[BiomeSystem] Config file not found: %s" % config_path)
		return false
	
	var file = FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		print("[BiomeSystem] Could not open config file")
		return false
	
	var json_string = file.get_as_text()
	var json = JSON.new()
	var parse_error = json.parse(json_string)
	
	if parse_error != OK:
		print("[BiomeSystem] JSON parse error: %s" % json.get_error_message())
		return false
	
	_biome_config = json.get_data()
	return true

func _print_biome_list() -> void:
	"""Print available biomes to console"""
	var biomes = _biome_config.get("biomes", [])
	if biomes.is_empty():
		print("[BiomeSystem] No biomes found in configuration")
		return
	
	print("[BiomeSystem] Available biomes (%d):" % biomes.size())
	for biome in biomes:
		var name = biome.get("name", "Unknown")
		var id = biome.get("id", -1)
		print("    • %s (ID: %d)" % [name, id])

func _process(_delta: float) -> void:
	"""Track player position and detect chunk changes"""
	if _player == null:
		return
	
	var player_pos = _player.global_position
	var current_chunk = Vector2i((player_pos / _chunk_size).round())
	
	# Log when chunk changes
	if current_chunk != _last_chunk:
		_last_chunk = current_chunk
		_on_chunk_changed(current_chunk, player_pos)

func _on_chunk_changed(chunk_coords: Vector2i, player_pos: Vector2) -> void:
	"""Called when player enters a new chunk"""
	if enable_debug:
		print("[BiomeSystem] Chunk changed to (%d, %d) | Player at (%.0f, %.0f)" % [
			chunk_coords.x, chunk_coords.y, player_pos.x, player_pos.y
		])

func get_config() -> Dictionary:
	"""Get biome configuration"""
	return _biome_config

func get_player() -> Node2D:
	"""Get player reference"""
	return _player

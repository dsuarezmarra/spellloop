
extends Node

# SpriteDB: carga y expone rutas normalizadas a sprites desde assets/sprites/sprites_index.json
# Proporciona helpers para obtener sprites por categoría (player, enemies, projectiles, etc.)

var sprites_index: Dictionary = {}

func _ready():
	load_index()

func load_index():
	var path = "res://assets/sprites/sprites_index.json"
	if not FileAccess.file_exists(path):
		print("[SpriteDB] sprites_index.json no encontrado: ", path)
		return
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("[SpriteDB] Error abriendo sprites_index.json")
		return
	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()
	if parse_result != OK:
		print("[SpriteDB] Error parseando JSON: ", json.get_error_message())
		return
	sprites_index = json.get_data()
	print("[SpriteDB] sprites_index cargado, llaves: ", sprites_index.keys())

func get_player_sprites() -> Dictionary:
	if sprites_index.has("players/wizard"):
		return sprites_index["players/wizard"]
	# Si no existe, buscar por keys que empiecen con players/wizard/
	var out = {}
	for k in sprites_index.keys():
		if k.begins_with("players/wizard/"):
			var dir = k.get_slice("/", 2)
			out[dir] = sprites_index[k]

	# Fallback: si no hay entradas en el index, buscar archivos en disco
	# bajo res://assets/sprites/players/wizard/ y mapear convenciones wizard_up/down/left/right
	if out.is_empty():
		var dir_path = "res://assets/sprites/players/wizard"
		var da = DirAccess.open(dir_path)
		if da:
			var mapping = {"down": "wizard_down.png", "up": "wizard_up.png", "left": "wizard_left.png", "right": "wizard_right.png"}
			for d_key in mapping.keys():
				var f = "%s/%s" % [dir_path, mapping[d_key]]
				if FileAccess.file_exists(f):
					out[d_key] = f

	return out

func get_enemy_sprites_by_tier() -> Dictionary:
	var out = {}
	for tier in ["tier_1", "tier_2", "tier_3", "tier_4", "bosses"]:
		if sprites_index.has(tier):
			out[tier] = sprites_index[tier]
	return out

func get_projectile_sprite(id: String) -> String:
	var key = "projectiles/%s" % id
	if sprites_index.has(key):
		return sprites_index[key]
	return ""

func get_enemy_list(tier: String) -> Array:
	if sprites_index.has(tier):
		return sprites_index[tier]
	return []

func get_boss_list() -> Array:
	if sprites_index.has("bosses"):
		return sprites_index["bosses"]
	return []

func get_sprite(path_key: String) -> String:
	if sprites_index.has(path_key):
		return sprites_index[path_key]
	return ""

func has(path_key: String) -> bool:
	return sprites_index.has(path_key)


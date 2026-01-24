class_name AudioLoader
extends Node

const MANIFEST_PATH = "res://audio_manifest.json"

static func load_manifest() -> Dictionary:
	if not FileAccess.file_exists(MANIFEST_PATH):
		push_warning("[AudioLoader] Manifest not found: " + MANIFEST_PATH)
		return {}
	
	var file = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if not file:
		push_error("[AudioLoader] Failed to open manifest")
		return {}
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		push_error("[AudioLoader] JSON parse error: " + str(error))
		return {}
	
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		push_error("[AudioLoader] Manifest must be a dictionary")
		return {}
	
	return data

class_name AudioLoader
extends Node

const MANIFEST_PATH = "res://audio_manifest.json"

static func load_manifest() -> Dictionary:
	if not FileAccess.file_exists(MANIFEST_PATH):
		push_error("Audio manifest not found at " + MANIFEST_PATH)
		return {}
		
	var file = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	var json_text = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error != OK:
		push_error("Failed to parse audio manifest. Error: " + str(error))
		return {}
		
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Audio manifest root must be a dictionary")
		return {}
		
	return data

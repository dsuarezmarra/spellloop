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
	
	# FILTER AND VALIDATE
	var clean_data = {}
	var empty_count = 0
	
	for id in data:
		# Check 1: Empty ID
		if id == "" or item_id_is_empty(str(id)):
			empty_count += 1
			continue
			
		var entry = data[id]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
			
		# Check 2: Files array
		var files = entry.get("files", [])
		if files.is_empty():
			# push_warning("[AudioLoader] Skipping '%s': No files defined" % id)
			continue
			
		clean_data[id] = entry
		
	if empty_count > 0:
		print("[AudioLoader] Cleaned %d empty IDs during load." % empty_count)
	
	return clean_data
	
static func item_id_is_empty(s: String) -> bool:
	return s == null or s.strip_edges() == ""


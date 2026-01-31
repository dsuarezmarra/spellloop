@tool
extends SceneTree

# DependencyScanner.gd
# Scans runtime directories for forbidden references to debug/QA tools.
# Usage: godot --headless --script scripts/tools/DependencyScanner.gd

const SCAN_DIRS = [
	"res://scripts/core",
	"res://scripts/game",
	"res://scripts/ui",
	"res://scripts/weapons",
	"res://scripts/entities",
	"res://scripts/components",
	"res://scripts/managers"
]

const FORBIDDEN_TOKENS = [
	"res://scripts/debug",
	"scripts/debug/",
	"ItemTestRunner",
	"StructureValidator",
	"TestRunner.tscn",
	"CalibrationSuite"
]

const ALLOWED_FILES = [
	"res://scripts/tools/DependencyScanner.gd", # Self
	"res://scripts/game/Game.gd" # Runtime Guard Rail
]

var violations = []

func _init():
	print("=== RUNTIME DEPENDENCY SCANNER ===")
	print("Scanning for forbidden tokens: ", FORBIDDEN_TOKENS)
	
	for dir_path in SCAN_DIRS:
		_scan_directory(dir_path)
		
	print("\n=== SCAN COMPLETE ===")
	if violations.size() > 0:
		print("❌ FOUND %d VIOLATIONS:" % violations.size())
		for v in violations:
			print("  - %s: Found '%s' at line %d" % [v.file, v.token, v.line])
		print("FAILURE: Runtime code depends on Debug/QA systems.")
		quit(1)
	else:
		print("✅ SUCCESS: No runtime dependencies on debug references found.")
		quit(0)

func _scan_directory(path: String):
	var dir = DirAccess.open(path)
	if not dir:
		print("Warning: Could not open directory: ", path)
		return
		
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if dir.current_is_dir():
			if file_name != "." and file_name != "..":
				_scan_directory(path + "/" + file_name)
		else:
			if file_name.ends_with(".gd") or file_name.ends_with(".tscn"):
				_check_file(path + "/" + file_name)
		
		file_name = dir.get_next()

func _check_file(file_path: String):
	if file_path in ALLOWED_FILES:
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return
		
	var content = file.get_as_text()
	var lines = content.split("\n")
	
	for i in range(lines.size()):
		var line = lines[i]
		# Skip comments (simple check)
		var comment_idx = line.find("#")
		if comment_idx != -1:
			line = line.substr(0, comment_idx)
			
		for token in FORBIDDEN_TOKENS:
			if line.find(token) != -1:
				violations.append({
					"file": file_path,
					"token": token,
					"line": i + 1
				})

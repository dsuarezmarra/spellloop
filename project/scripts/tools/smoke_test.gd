extends Node

func _safe_quit(_code: int = 0):
	if get_tree() != null:
		get_tree().quit()

func _init():
	# Simple smoke test: check that core scripts exist and can be loaded without instantiation
	var start_marker = "C:/git/spellloop/project/smoke_started.txt"
	var smf = FileAccess.open(start_marker, FileAccess.WRITE)
	if smf:
		smf.store_string("started\n")
		smf.close()

	print("SMOKE_SCRIPTS: smoke_test (loader checks) starting")

	var scripts_to_check = [
		"res://scripts/core/SpellloopGame.gd",
		"res://scripts/core/GameManager.gd",
		"res://scripts/core/SaveManager.gd",
		"res://scripts/core/InputManager.gd",
		"res://scripts/core/UIManager.gd",
		"res://scripts/ui/MinimapSystem.gd",
		"res://scripts/core/ExperienceManager.gd",
		"res://scripts/core/EnemyManager.gd",
		"res://scripts/core/WeaponManager.gd",
		"res://scripts/core/ItemManager.gd",
	]

	var report_lines: Array = []
	for path in scripts_to_check:
		var res = ResourceLoader.load(path)
		var ok = res != null
		var status = "OK" if ok else "MISSING/ERROR"
		report_lines.append("%s : %s" % [path, status])

	# Manual join for Godot4
	var out_lines = ""
	for i in range(report_lines.size()):
		out_lines += str(report_lines[i])
		if i < report_lines.size() - 1:
			out_lines += "\n"
	var out = "SMOKE TEST REPORT:\n" + out_lines
	print(out)

	# Write to absolute fallback file
	var abs_sm = "C:/git/spellloop/project/smoke_out.txt"
	var f3 = FileAccess.open(abs_sm, FileAccess.WRITE)
	if f3:
		f3.store_string(out)
		f3.close()
	else:
		push_error("Could not write absolute smoke report to %s" % abs_sm)

	_safe_quit()


# OBSOLETE-SCRIPT: este script parece no usarse actualmente. Verificar antes de eliminar.
# Originalmente: verify_scenes_verbose.gd - Script de verificación verbose de escenas
# Razón: Script de desarrollo (nunca ejecutado en game loop; versión verbose deprecated)

extends Node

func _safe_quit(_code: int = 0):
	if get_tree() != null:
		get_tree().quit()

var SCENES := [
	"res://scenes/player/SpellloopPlayer.tscn",
	"res://scenes/pickups/XPOrb.tscn",
	"res://scenes/items/TreasureChest.tscn",
	"res://scenes/projectiles/chaos_wave.tscn",
	"res://scenes/ui/LevelUpPanel.tscn",
	"res://scenes/ui/SimpleChestPopup.tscn",
]

func _init():
	var out = "--- VERIFY VERBOSE ---\n"
	for s in SCENES:
		out += "Checking: %s\n" % s
		var exists = ResourceLoader.exists(s)
		out += "  exists: %s\n" % exists
		var res = ResourceLoader.load(s)
		if res == null:
			out += "  load: FAILED (null)\n"
			# Attempt to parse file contents to find line with syntax issue
			var abs_path = ProjectSettings.globalize_path(s)
			var f = FileAccess.open(abs_path, FileAccess.READ)
			if f:
				var txt = f.get_as_text()
				f.close()
				out += "  file_length: %d chars\n" % txt.length()
			else:
				out += "  could not open file at filesystem path: %s\n" % abs
		else:
			out += "  load: OK -> %s\n" % res
		# separator
		out += "\n"
	# write to project root
	var path = "C:/git/spellloop/project/verify_verbose_out.txt"
	var f2 = FileAccess.open(path, FileAccess.WRITE)
	if f2:
		f2.store_string(out)
		f2.close()
	print(out)
	_safe_quit()


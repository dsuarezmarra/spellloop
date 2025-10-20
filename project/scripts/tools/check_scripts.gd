extends Node

func _safe_quit(_code: int = 0):
	if get_tree() != null:
		get_tree().quit()

var SCRIPTS := [
	"res://scripts/entities/SpellloopPlayer.gd",
	"res://scripts/magic/SpellloopMagicProjectile.gd",
	"res://scripts/magic/SpellloopMagicProjectile.gd",
]

func _init():
	var out = "--- CHECK SCRIPTS ---\n"
	for s in SCRIPTS:
		out += "Checking: %s\n" % s
		var exists = ResourceLoader.exists(s)
		out += "  exists: %s\n" % exists
		var res = ResourceLoader.load(s)
		if res == null:
			out += "  load: FAILED (null)\n"
		else:
			out += "  load: OK -> %s\n" % str(res)
		# try to create an instance if script is a Class
		if res and res is Script:
			var _ok_inst = true
			# try new()
			var inst = null
			# Protect instantiation
			var _success = false
			# GDScript scripts can be constructed via res.new()
			if res.has_method("new"):
				# try
				inst = res.new()
				if inst:
					out += "  instantiate: OK -> %s\n" % inst
				else:
					out += "  instantiate: FAILED\n"
			else:
				out += "  instantiate: not applicable\n"
		out += "\n"
	# write out
	var path = "C:/git/spellloop/project/check_scripts_out.txt"
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(out)
		f.close()
	print(out)
	_safe_quit()


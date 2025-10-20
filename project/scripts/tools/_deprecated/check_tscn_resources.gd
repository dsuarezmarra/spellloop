# OBSOLETE-SCRIPT: este script parece no usarse actualmente. Verificar antes de eliminar.
# Originalmente: check_tscn_resources.gd - Script de verificación de recursos TSCN
# Razón: Script de desarrollo para auditoría de escenas (nunca ejecutado en game loop)

extends Node

func _safe_quit(_code: int = 0):
	if get_tree() != null:
		get_tree().quit()

func _init():
	var out = "--- TSCN RESOURCE CHECK ---\n"
	var files = []
	# gather all tscn files under res://scenes
	var dir = DirAccess.open("res://scenes")
	if not dir:
		out += "Could not open res://scenes\n"
		print(out)
		_safe_quit()
	# recursive
	gather(dir, "res://scenes", files)
	for f in files:
		out += "File: %s\n" % f
		# open actual file
		var abs_path = ProjectSettings.globalize_path(f)
		var fa = FileAccess.open(abs_path, FileAccess.READ)
		if not fa:
			out += "  could not open file on filesystem: %s\n" % abs_path
			continue
		var txt = fa.get_as_text()
		fa.close()
		# scan for ext_resource path="..."
		var lines = txt.split('\n')
		for l in lines:
			if l.find("ext_resource") != -1 and l.find("path=") != -1:
				# crude parse
				var m = l
				var pstart = m.find("path=")
				var sub = m.substr(pstart)
				var quote1 = sub.find('"')
				var quote2 = sub.rfind('"')
				if quote1 == -1 or quote2 == -1 or quote2 <= quote1:
					continue
				var path = sub.substr(quote1+1, quote2-quote1-1)
				var abs2 = ProjectSettings.globalize_path(path)
				var exists = FileAccess.file_exists(abs2)
				out += "  ext_resource: %s -> exists: %s\n" % [path, exists]
		out += "\n"
	# write report
	var path_out = "C:/git/spellloop/project/check_tscn_resources_out.txt"
	var f2 = FileAccess.open(path_out, FileAccess.WRITE)
	if f2:
		f2.store_string(out)
		f2.close()
	print(out)
	_safe_quit()

func gather(dir: DirAccess, base: String, files: Array):
	var childs = dir.get_children()
	for c in childs:
		var p = base + "/" + c
		if c.ends_with('.tscn'):
			files.append(p)
		elif dir.current_is_dir():
			var nd = DirAccess.open(p)
			if nd:
				gather(nd, p, files)


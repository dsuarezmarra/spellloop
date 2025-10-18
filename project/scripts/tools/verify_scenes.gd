extends SceneTree

func _safe_quit(_code: int = 0):
	# When running as SceneTree, call quit on self
	if self:
		self.quit()

var _report: Array = []

func _enter_tree():
	# Ejecutar automáticamente cuando se usa con --script para generar salida en terminal
	# Escribir un marcador temprano para confirmar que el script se ha iniciado
	var start_marker = "C:/git/spellloop/project/verify_started.txt"
	var smf = FileAccess.open(start_marker, FileAccess.WRITE)
	if smf:
		smf.store_string("started\n")
		smf.close()
	print("VERIFY_SCRIPTS: verify_scenes starting")
	run_checks()
	var report = get_report()
	var final = "--- VERIFY SCENES REPORT ---\n" + report
	print(final)
	# Also write to user:// so we can inspect even if stdout redirection fails
	var user_path = "user://verify_report.txt"
	var abs_user = ProjectSettings.globalize_path(user_path)
	var f1 = FileAccess.open(abs_user, FileAccess.WRITE)
	if f1:
		f1.store_string(final)
		f1.close()
	else:
		push_error("Could not write verify report to %s" % abs_user)
	# Additionally write to an absolute path in the project root for tooling
	var abs_path = "C:/git/spellloop/project/verify_out.txt"
	var f2 = FileAccess.open(abs_path, FileAccess.WRITE)
	if f2:
		f2.store_string(final)
		f2.close()
	else:
		push_error("Could not write absolute verify report to %s" % abs_path)
	# Salir inmediatamente para que el proceso termine (útil en ejecuciones headless)
	_safe_quit()

func run_checks() -> void:
	_report.clear()
	var to_check = [
		"res://scenes/player/SpellloopPlayer.tscn",
		"res://scenes/pickups/XPOrb.tscn",
		"res://scenes/items/TreasureChest.tscn",
		"res://scenes/projectiles/chaos_wave.tscn",
		"res://scenes/ui/LevelUpPanel.tscn",
		"res://scenes/ui/SimpleChestPopup.tscn",
	]

	for s in to_check:
		var ok = _check_scene(s)
		_report.append({"scene": s, "ok": ok})
		# Additional canvas checks for UI/world separation if scene loaded
		if ok:
			var res = ResourceLoader.load(s)
			if res and res is PackedScene:
				var inst = res.instantiate()
				# Check CanvasItem visible_layers and modulate/scale on root children
				for child in inst.get_children():
					if child is CanvasItem:
						# Godot 4: Node does not expose has_property; use get_property_list() fallback
						var has_visible_layers_prop = false
						if child.has_method("get_visible_layers"):
							has_visible_layers_prop = true
						else:
							# Inspect property list for 'visible_layers'
							var props = []
							if child.has_method("get_property_list"):
								props = child.get_property_list()
								for p in props:
									if typeof(p) == TYPE_DICTIONARY and p.get("name", "") == "visible_layers":
										has_visible_layers_prop = true
							var vl = child.visible_layers if has_visible_layers_prop else null
							if vl != null and vl != 1:
								_report.append({"scene": s + ":" + child.name, "ok": false, "reason": "visible_layers!=1"})
				# Camera check
				if inst.has_node("Camera2D"):
					var cam = inst.get_node("Camera2D")
					if cam and cam is Camera2D and not cam.current:
						_report.append({"scene": s + ":Camera2D", "ok": false, "reason": "Camera2D.current!=true"})

	# Check enemies directory for at least one enemy scene
	var enemy_exists = false
	var enemy_files = []
	var dir = DirAccess.open("res://scenes/enemies")
	if dir:
		dir.list_dir_begin()
		var fname = dir.get_next()
		while fname != "":
			if not dir.current_is_dir():
				if fname.ends_with(".tscn"):
					enemy_exists = true
					enemy_files.append("res://scenes/enemies/" + fname)
			fname = dir.get_next()
		dir.list_dir_end()

	_report.append({"scene": "res://scenes/enemies/*", "ok": enemy_exists, "examples": enemy_files})

	# Extended check: ensure player and at least one enemy have sprite textures assigned
	var player_has_texture = false
	if ResourceLoader.exists("res://scenes/player/SpellloopPlayer.tscn"):
		var pres = ResourceLoader.load("res://scenes/player/SpellloopPlayer.tscn")
		if pres and pres is PackedScene:
			var pinst = pres.instantiate()
			if pinst.has_node("AnimatedSprite2D"):
				var anim = pinst.get_node("AnimatedSprite2D")
				if anim and (anim.sprite_frames or anim.frames):
					# check any animation has at least one frame
					var sf = anim.sprite_frames if anim.sprite_frames else anim.frames
					for anim_name in sf.get_animation_names():
						if sf.get_frame_count(anim_name) > 0:
							player_has_texture = true
							break
	_report.append({"scene": "res://scenes/player/SpellloopPlayer.tscn:has_texture", "ok": player_has_texture})

	var enemy_with_texture = false
	for ef in enemy_files:
		var eres = ResourceLoader.load(ef)
		if eres and eres is PackedScene:
			var einst = eres.instantiate()
			# check AnimatedSprite2D or Sprite2D nodes
			if einst.has_node("AnimatedSprite2D"):
				var a = einst.get_node("AnimatedSprite2D")
				var sf = a.sprite_frames if a.sprite_frames else a.frames
				if a and sf:
					for n in sf.get_animation_names():
						if sf.get_frame_count(n) > 0:
							enemy_with_texture = true
							break
			if einst.has_node("Sprite2D") and not enemy_with_texture:
				var s = einst.get_node("Sprite2D")
				if s and s.texture:
					enemy_with_texture = true
		if enemy_with_texture:
			break

	_report.append({"scene": "res://scenes/enemies/*:has_texture", "ok": enemy_with_texture})

func get_report() -> String:
	var lines: Array = []
	for r in _report:
		if typeof(r) == TYPE_DICTIONARY:
			var s = r.get("scene", "?")
			var ok = r.get("ok", false)
			var status = "OK" if ok else "MISSING/ERROR"
			lines.append("%s : %s" % [s, status])
		else:
			lines.append(str(r))
	# Manual join for Godot4 compatibility
	var out = ""
	for i in range(lines.size()):
		out += str(lines[i])
		if i < lines.size() - 1:
			out += "\n"
	return out

func _check_scene(path: String) -> bool:
	var res = ResourceLoader.load(path)
	if res == null:
		push_error("Failed to load scene: %s" % path)
		return false
	return true

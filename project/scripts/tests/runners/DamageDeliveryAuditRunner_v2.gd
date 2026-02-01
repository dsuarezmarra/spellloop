extends SceneTree

func _init():
	var f = FileAccess.open("res://audit_v2_trace.txt", FileAccess.WRITE)
	f.store_string("TRACE: V2 Proj Test Start\n")
	
	var path = "res://scripts/entities/weapons/projectiles/SimpleProjectile.gd"
	if FileAccess.file_exists(path):
		f.store_string("TRACE: File Exists\n")
		var s = load(path)
		if s:
			f.store_string("TRACE: Loaded\n")
			var inst = s.new() # POTENTIAL CRASH
			f.store_string("TRACE: Instantiated\n")
			inst.queue_free()
			
	f.store_string("TRACE: Proj Pass\n")
	f.close()
	quit()

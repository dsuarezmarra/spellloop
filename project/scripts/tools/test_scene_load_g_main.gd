extends Node

var SCENE_PATH := "res://scenes/SpellloopMain.tscn"

func _safe_quit(_code: int = 0):
	if get_tree() != null:
		get_tree().quit()

func _init():
	print("TEST_SCENE_LOAD: loading "+SCENE_PATH)
	var res = ResourceLoader.load(SCENE_PATH)
	if not res:
		print("FAILED: could not load scene: "+SCENE_PATH)
		_safe_quit()
		return
	var inst = res.instantiate()
	if not inst:
		print("FAILED: could not instantiate scene: "+SCENE_PATH)
		_safe_quit()
		return
	print("OK: scene instantiated: "+SCENE_PATH)
	# give a short moment for autoloads to run, then quit
	OS.delay_msec(50)
	_safe_quit()


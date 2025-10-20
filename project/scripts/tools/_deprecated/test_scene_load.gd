# OBSOLETE-SCRIPT: este script parece no usarse actualmente. Verificar antes de eliminar.
# Originalmente: test_scene_load.gd - Script de testing de carga de escenas
# Razón: Script de desarrollo (nunca ejecutado en game loop)

extends Node

func _safe_quit(_code: int = 0):
    if get_tree() != null:
        get_tree().quit()

func _init():
    print("TEST_SCENE_LOAD start")
    var path = "res://scenes/items/TreasureChest.tscn"
    var res = ResourceLoader.load(path)
    if res == null:
        print("FAILED to load:", path)
    else:
        print("Loaded scene resource:", res)
    _safe_quit()


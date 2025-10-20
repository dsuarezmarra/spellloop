# OBSOLETE-SCRIPT: este script parece no usarse actualmente. Verificar antes de eliminar.
# Originalmente: auto_run.gd - Script para ejecutar automáticamente main scene
# Razón: Script de desarrollo (testing manual via --script flag)

extends SceneTree

# Carga la escena principal, espera N segundos y sale.
const RUN_SECONDS := 6.0
const MAIN_SCENE := "res://scenes/SpellloopMain.tscn"

func _ready():
    print("[auto_run] Starting main scene: ", MAIN_SCENE)
    if ResourceLoader.exists(MAIN_SCENE):
        var ps = load(MAIN_SCENE)
        if ps and ps is PackedScene:
            var root = ps.instantiate()
            root.name = "AutoRunRoot"
            # Add to root viewport
            var root_node = get_root()
            if root_node:
                root_node.add_child(root)
                # Set current scene via SceneTree API
                set_current_scene(root)
                print("[auto_run] Scene instantiated and set as current_scene")
            else:
                print("[auto_run] Could not get root to add scene")
        else:
            print("[auto_run] Failed to load PackedScene: ", MAIN_SCENE)
    else:
        print("[auto_run] Main scene not found: ", MAIN_SCENE)

    # Defer quit to let initialization happen
    call_deferred("_wait_and_quit")

func _wait_and_quit() -> void:
    print("[auto_run] Running for %s seconds..." % RUN_SECONDS)
    await create_timer(RUN_SECONDS).timeout
    print("[auto_run] Time elapsed, quitting")
    quit()


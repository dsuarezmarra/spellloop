# OBSOLETE-SCRIPT: este script parece no usarse actualmente. Verificar antes de eliminar.
# Originalmente: parse_check.gd - Script de verificación de parsing
# Razón: Script de desarrollo para auditoría de parseo (nunca ejecutado en game loop)

extends SceneTree

# Script de ayuda para verificar parseo de scripts críticos.
# Ejecutar con: godot --path <project> -s scripts/tools/parse_check.gd

var check_paths := [
	"res://scripts/core/EnemyManager.gd",
	"res://scripts/core/AudioManager.gd",
	"res://scripts/core/SpellloopGame.gd",
	"res://scripts/ui/MinimapSystem.gd",
	"res://scripts/core/WeaponManager.gd",
]

func _ready():
	# Defer to allow SceneTree initialization
	call_deferred("_run_checks")

func _run_checks():
	print("[parse_check] Running parse checks...")
	for p in check_paths:
		print("[parse_check] Checking:", p)
		print("  ResourceLoader.exists:", ResourceLoader.exists(p))
		var res = load(p)
		print("  load returned:", res)
		if res and res is GDScript:
			print("  is GDScript, trying to instantiate...")
			var inst = res.new()
			print("  instantiated:", inst)

	print("[parse_check] Done; quitting")
	quit()


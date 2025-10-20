# OBSOLETE-SCRIPT: este script parece no usarse actualmente. Verificar antes de eliminar.
# Originalmente: Shim minimal para AudioManagerSimple (autoload)
# Razón: AudioManager.gd es la versión completa y utilizada. Este es un fallback deprecated.

extends Node

# Shim minimal para AudioManagerSimple (autoload)
var volume_db: float = 0.0
func play_sound(_name: String):
    # no-op shim
    pass
func stop_all():
    pass


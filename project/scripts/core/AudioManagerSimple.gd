extends Node

# Shim minimal para AudioManagerSimple (autoload)
var volume_db: float = 0.0
func play_sound(_name: String):
    # no-op shim
    pass
func stop_all():
    pass


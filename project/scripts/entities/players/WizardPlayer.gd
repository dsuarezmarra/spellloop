# WizardPlayer.gd
# Instanciado dinámicamente por LoopiaLikePlayer como nodo hijo.
# Toda la lógica de sprites, armas y stats está en BasePlayer.
# Este stub solo establece los valores por defecto del personaje inicial.

extends BasePlayer
class_name WizardPlayer

func _ready() -> void:
	# Defaults del personaje inicial (si no hay SessionState, usa frost_mage)
	character_class = "FrostMage"
	character_sprites_key = "frost_mage"
	super._ready()

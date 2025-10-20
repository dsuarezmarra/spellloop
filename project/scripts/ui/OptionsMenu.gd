extends Control

func _ready():
	# Wire sliders to AudioManager if available
	var am = null
	if get_tree() and get_tree().root and get_tree().root.get_node_or_null("AudioManager"):
		am = get_tree().root.get_node("AudioManager")
	if am:
		$MusicSlider.value = am.get_music_volume()
		$SFXSlider.value = am.get_sfx_volume()
		$MusicSlider.connect("value_changed", Callable(self, "_on_music_volume_changed"))
		$SFXSlider.connect("value_changed", Callable(self, "_on_sfx_volume_changed"))

func _on_music_volume_changed(v: float) -> void:
	if get_tree() and get_tree().root and get_tree().root.get_node_or_null("AudioManager"):
		var am = get_tree().root.get_node("AudioManager")
		am.set_music_volume(v)
		am.save_volume_settings()

func _on_sfx_volume_changed(v: float) -> void:
	if get_tree() and get_tree().root and get_tree().root.get_node_or_null("AudioManager"):
		var am = get_tree().root.get_node("AudioManager")
		am.set_sfx_volume(v)
		am.save_volume_settings()


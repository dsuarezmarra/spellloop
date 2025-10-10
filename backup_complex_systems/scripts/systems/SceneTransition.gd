# SceneTransition.gd
# Manages smooth scene transitions with visual effects
# Provides fade in/out, slide, and other transition effects between scenes

extends Node

signal transition_started(transition_type: String)
signal transition_finished(transition_type: String)

# Transition types
enum TransitionType {
	FADE,
	SLIDE_LEFT,
	SLIDE_RIGHT,
	SLIDE_UP,
	SLIDE_DOWN,
	WIPE,
	CIRCLE
}

# Transition settings
var transition_duration: float = 0.5
var transition_color: Color = Color.BLACK

# UI elements
var overlay: ColorRect
var animation_player: AnimationPlayer

func _ready() -> void:
	"""Initialize transition system"""
	_create_overlay()
	print("[SceneTransition] Scene transition system initialized")

func _create_overlay() -> void:
	"""Create the transition overlay"""
	# Create overlay
	overlay = ColorRect.new()
	overlay.name = "TransitionOverlay"
	overlay.color = transition_color
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 100
	overlay.visible = false
	
	# Make overlay cover the entire screen
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Add to scene tree
	get_tree().root.add_child(overlay)
	
	# Create animation player
	animation_player = AnimationPlayer.new()
	animation_player.name = "TransitionAnimationPlayer"
	overlay.add_child(animation_player)
	
	# Create animations
	_create_animations()

func _create_animations() -> void:
	"""Create transition animations"""
	var library = AnimationLibrary.new()
	
	# Fade in animation
	var fade_in = Animation.new()
	fade_in.length = transition_duration
	var fade_in_track = fade_in.add_track(Animation.TYPE_VALUE)
	fade_in.track_set_path(fade_in_track, "../:modulate:a")
	fade_in.track_insert_key(fade_in_track, 0.0, 0.0)
	fade_in.track_insert_key(fade_in_track, transition_duration, 1.0)
	library.add_animation("fade_in", fade_in)
	
	# Fade out animation
	var fade_out = Animation.new()
	fade_out.length = transition_duration
	var fade_out_track = fade_out.add_track(Animation.TYPE_VALUE)
	fade_out.track_set_path(fade_out_track, "../:modulate:a")
	fade_out.track_insert_key(fade_out_track, 0.0, 1.0)
	fade_out.track_insert_key(fade_out_track, transition_duration, 0.0)
	library.add_animation("fade_out", fade_out)
	
	# Slide left animation
	var slide_left = Animation.new()
	slide_left.length = transition_duration
	var slide_left_track = slide_left.add_track(Animation.TYPE_VALUE)
	slide_left.track_set_path(slide_left_track, "../:position:x")
	slide_left.track_insert_key(slide_left_track, 0.0, get_viewport().size.x)
	slide_left.track_insert_key(slide_left_track, transition_duration, 0.0)
	library.add_animation("slide_left", slide_left)
	
	# Add library to animation player
	animation_player.add_animation_library("transitions", library)

func change_scene(scene_path: String, transition_type: TransitionType = TransitionType.FADE) -> void:
	"""Change scene with specified transition"""
	var transition_name = _get_transition_name(transition_type)
	
	print("[SceneTransition] Changing scene to: ", scene_path, " with transition: ", transition_name)
	
	transition_started.emit(transition_name)
	
	# Start transition in
	await _transition_in(transition_type)
	
	# Change scene
	var result = get_tree().change_scene_to_file(scene_path)
	if result != OK:
		print("[SceneTransition] Error changing scene: ", result)
		return
	
	# Wait a frame for new scene to load
	await get_tree().process_frame
	
	# Start transition out
	await _transition_out(transition_type)
	
	transition_finished.emit(transition_name)

func _transition_in(transition_type: TransitionType) -> void:
	"""Start transition in effect"""
	overlay.visible = true
	
	match transition_type:
		TransitionType.FADE:
			overlay.modulate.a = 0.0
			animation_player.play("transitions/fade_in")
		TransitionType.SLIDE_LEFT:
			overlay.position.x = get_viewport().size.x
			animation_player.play("transitions/slide_left")
		_:
			# Default to fade
			overlay.modulate.a = 0.0
			animation_player.play("transitions/fade_in")
	
	await animation_player.animation_finished

func _transition_out(transition_type: TransitionType) -> void:
	"""Start transition out effect"""
	match transition_type:
		TransitionType.FADE:
			animation_player.play("transitions/fade_out")
		_:
			# Default to fade
			animation_player.play("transitions/fade_out")
	
	await animation_player.animation_finished
	overlay.visible = false

func _get_transition_name(transition_type: TransitionType) -> String:
	"""Get transition name from type"""
	match transition_type:
		TransitionType.FADE:
			return "fade"
		TransitionType.SLIDE_LEFT:
			return "slide_left"
		TransitionType.SLIDE_RIGHT:
			return "slide_right"
		TransitionType.SLIDE_UP:
			return "slide_up"
		TransitionType.SLIDE_DOWN:
			return "slide_down"
		TransitionType.WIPE:
			return "wipe"
		TransitionType.CIRCLE:
			return "circle"
		_:
			return "fade"

func fade_to_black(duration: float = 0.5) -> void:
	"""Quick fade to black effect"""
	overlay.visible = true
	overlay.modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, duration)
	await tween.finished

func fade_from_black(duration: float = 0.5) -> void:
	"""Quick fade from black effect"""
	if not overlay.visible:
		return
		
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, duration)
	await tween.finished
	overlay.visible = false

func flash_screen(color: Color = Color.WHITE, duration: float = 0.1) -> void:
	"""Flash the screen with a color"""
	overlay.color = color
	overlay.visible = true
	overlay.modulate.a = 0.8
	
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, duration)
	await tween.finished
	
	overlay.visible = false
	overlay.color = transition_color

func set_transition_duration(duration: float) -> void:
	"""Set the duration for transitions"""
	transition_duration = duration
	_create_animations()  # Recreate animations with new duration

func set_transition_color(color: Color) -> void:
	"""Set the color for transitions"""
	transition_color = color
	if overlay:
		overlay.color = color
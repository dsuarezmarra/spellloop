extends Node

func _ready():
	print("Testing property access...")
	
	var iwm = InfiniteWorldManager.new()
	add_child(iwm)
	
	# These should not cause errors now
	print("chunk_width: ", iwm.chunk_width)
	print("chunk_height: ", iwm.chunk_height)
	
	print("Properties accessible successfully!")
	get_tree().quit()
extends Node

"""Utility fallbacks for missing assets (XP orb, chests, etc.).
Provides safe spawn helpers that try to load real scenes and otherwise create simple placeholders.
"""

static func spawn_xp_orb(parent: Node, position: Vector2, xp_value: int = 1) -> Node:
	var xp_path = "res://scenes/pickups/XPOrb.tscn"
	if ResourceLoader.exists(xp_path):
		var sc = load(xp_path)
		if sc and sc is PackedScene:
			var inst = sc.instantiate()
			if parent:
				parent.add_child(inst)
			inst.global_position = position
			# Try set xp_value safely
			if inst.has_method("set") and inst.has_method("get"):
				if inst.has("xp_value"):
					inst.set("xp_value", int(xp_value))
			if inst.has_method("set") and inst.has("xp_value"):
				inst.set("xp_value", int(xp_value))
			elif inst.has("xp_value"):
				# direct set if property exists
				inst.xp_value = int(xp_value)
			return inst

	# Fallback: create a tiny Node2D with a colored sprite
	var orb = Node2D.new()
	orb.name = "XPOrbFallback"
	var spr = Sprite2D.new()
	# Create a small circular image texture
	var size = 8
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size / 2.0, size / 2.0)
	for x in range(size):
		for y in range(size):
			var p = Vector2(x, y)
			var d = p.distance_to(center)
			if d <= float(size) / 2.0 - 1.0:
				img.set_pixel(x, y, Color(1.0, 0.85, 0.2, 1.0))
			else:
				img.set_pixel(x, y, Color(0,0,0,0))
	var tex = ImageTexture.create_from_image(img)
	spr.texture = tex
	spr.centered = true
	orb.add_child(spr)
	if orb.has_method("set"):
		orb.set("xp_value", int(xp_value))
	if parent:
		parent.add_child(orb)
	orb.global_position = position
	return orb


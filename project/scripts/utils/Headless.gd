extends Node
class_name Headless

static func is_headless() -> bool:
	return DisplayServer.get_name() == "headless" or OS.has_feature("headless") or "--headless" in OS.get_cmdline_args()

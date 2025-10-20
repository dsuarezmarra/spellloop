# Shim minimal para RoomData usado por MinimapUI
class_name RoomData

enum RoomType {
	NORMAL,
	TREASURE,
	BOSS,
	SECRET,
	SHOP
}

var room_type: RoomType = RoomType.NORMAL
var is_cleared: bool = false
var is_visited: bool = false


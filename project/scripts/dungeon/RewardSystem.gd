extends Node
class_name RewardSystem

signal experience_gained(amount)
signal item_obtained(item_data)

# Configuración de recompensas
@export var base_experience: int = 10
@export var treasure_multiplier: float = 2.0
@export var boss_multiplier: float = 5.0

func give_treasure_room_reward():
	var exp = randi_range(50, 100)
	experience_gained.emit(exp)
	
	var item = {"name": "Magic Scroll", "rarity": "rare"}
	item_obtained.emit(item)

func calculate_dungeon_completion_reward(dungeon_data: Dictionary) -> Dictionary:
	return {
		"experience": 500,
		"gold": 100,
		"items": ["Dungeon Key"]
	}

func calculate_experience_reward(enemies_defeated: int, difficulty: float) -> int:
	return int(base_experience * enemies_defeated * difficulty)

func give_room_clear_reward(room_type: RoomData.RoomType):
	var exp_amount = base_experience
	
	match room_type:
		RoomData.RoomType.TREASURE:
			exp_amount = int(base_experience * treasure_multiplier)
		RoomData.RoomType.BOSS:
			exp_amount = int(base_experience * boss_multiplier)
	
	experience_gained.emit(exp_amount)

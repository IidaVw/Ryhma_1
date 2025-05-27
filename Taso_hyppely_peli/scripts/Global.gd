extends Node

var current_room_center: Vector2 = Vector2.ZERO
var current_room_size: Vector2 = Vector2.ZERO
var last_checkpoint: Vector2 = Vector2.ZERO

func set_checkpoint(position: Vector2):
	last_checkpoint = position

# Updated to pass custom zoom value
func change_room(room_position: Vector2, room_size: Vector2, custom_zoom: float = -1.0) -> void:
	current_room_center = room_position
	current_room_size = room_size
	
	var camera = get_tree().current_scene.get_node_or_null("RoomCamera")
	if camera:
		camera.change_room(room_position, room_size, custom_zoom)
	else:
		print("Warning: Camera not found!")

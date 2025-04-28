extends Node
# Global variables to store current room center and size
var current_room_center: Vector2 = Vector2.ZERO
var current_room_size: Vector2 = Vector2.ZERO
var last_checkpoint: Vector2 = Vector2.ZERO

# Room transition variables
@export var room_pause_time: float = 0.3

# Method to update checkpoint
func set_checkpoint(position: Vector2):
	last_checkpoint = position

# Method to change the room (called from RoomDetector)
func change_room(room_position: Vector2, room_size: Vector2) -> void:
	# Update global room center and size
	current_room_center = room_position
	current_room_size = room_size
	
	# Find camera in the scene
	var camera = get_tree().current_scene.get_node_or_null("RoomCamera")
	if camera:
		camera.change_room(room_position, room_size)
	else:
		print("Warning: Camera not found!")

extends CharacterBody2D

@onready var global_script: Node = get_tree().get_node("/root/Global")

func _on_room_detector_area_entered(area: Area2D) -> void:
	# Debug print to see what area we're entering
	print("\n=== ENTERING AREA ===")
	print("Area name: ", area.name)
	print("Area path: ", area.get_path())
	
	# Check if this is a room area
	if area.name.begins_with("room"):
		var collision_shape = area.get_node("CollisionShape2D")
		
		if collision_shape:
			var shape = collision_shape.shape
			var shape_position = collision_shape.global_position
			var size = Vector2.ZERO
			
			# Get size based on shape type
			if shape is RectangleShape2D:
				size = shape.extents * 2
			else:
				size = Vector2(500, 400)
			
			var room_name = area.name
			var force_follow = false
			
			# Check if this is room7
			if room_name == "room7":
				force_follow = true
				print(">>> ROOM7 DETECTED! Camera will follow player.")
			
			print("Room: ", room_name)
			print("Force follow: ", force_follow)
			print("====================\n")
			
			# Call Global script with the follow flag
			global_script.change_room(shape_position, size, force_follow)

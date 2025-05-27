extends Camera2D

# Configuration
@export var follow_smoothing: float = 0.1
@export var transition_speed: float = 4.0

# References
var current_room_center: Vector2 = Vector2.ZERO
var current_room_size: Vector2 = Vector2.ZERO
var smoothing: float = 0.1
var player: Node2D = null

# Cache viewport size for calculations  
var view_size: Vector2
var zoom_view_size: Vector2

func _ready():
	position_smoothing_enabled = false
	view_size = get_viewport_rect().size
	make_current()
	
	# Find the player
	if get_tree().get_nodes_in_group("player").size() > 0:
		player = get_tree().get_nodes_in_group("player")[0]
		print("Player found: ", player.name)
	else:
		print("ERROR: No player found!")
	
	# Set smoothing to 1 initially for instant positioning
	smoothing = 1.0
	
	# Reset smoothing after a short delay
	await get_tree().create_timer(0.1).timeout
	smoothing = follow_smoothing
	
	# Try to find initial room
	if get_parent().has_node("Rooms/room1/CollisionShape2D"):
		var initial_room = get_parent().get_node("Rooms/room1/CollisionShape2D")
		current_room_center = initial_room.global_position
		current_room_size = initial_room.shape.extents * 2
		change_room(current_room_center, current_room_size)

func _physics_process(_delta):
	# Get target position
	var target_position = calculate_target_position(current_room_center, current_room_size)
	
	# Interpolate camera position to target position by the smoothing
	global_position = global_position.lerp(target_position, smoothing)

func calculate_target_position(room_center: Vector2, room_size: Vector2) -> Vector2:
	# Calculate the actual viewable area at current zoom
	zoom_view_size = view_size / zoom
	
	# The distance from the center of the room to the camera boundary on one side
	var x_margin: float = (room_size.x - zoom_view_size.x) / 2
	var y_margin: float = (room_size.y - zoom_view_size.y) / 2
	
	var return_position: Vector2 = Vector2.ZERO
	
	# If the room fits within the view, center on the room
	if x_margin <= 0:
		return_position.x = room_center.x
	# If room is bigger than view, follow the player
	else:
		if player:
			var left_limit: float = room_center.x - x_margin
			var right_limit: float = room_center.x + x_margin
			return_position.x = clamp(player.global_position.x, left_limit, right_limit)
		else:
			return_position.x = room_center.x
	
	if y_margin <= 0:
		return_position.y = room_center.y
	else:
		if player:
			var top_limit: float = room_center.y - y_margin  
			var bottom_limit: float = room_center.y + y_margin
			return_position.y = clamp(player.global_position.y, top_limit, bottom_limit)
		else:
			return_position.y = room_center.y
	
	return return_position

# Updated to accept custom zoom value
func change_room(new_room_center: Vector2, new_room_size: Vector2, custom_zoom: float = -1.0):
	current_room_center = new_room_center
	current_room_size = new_room_size
	
	var new_zoom: float
	
	# If custom_zoom is provided (not -1), use it
	if custom_zoom > 0:
		new_zoom = custom_zoom
		zoom = Vector2(new_zoom, new_zoom)
	else:
		# Use your normal zoom calculation
		var zoom_x = view_size.x / new_room_size.x
		var zoom_y = view_size.y / new_room_size.y
		new_zoom = max(zoom_x, zoom_y)
		if new_zoom > 3.0:
			new_zoom = 3.0
		new_zoom *= 0.90
		zoom = Vector2(new_zoom, new_zoom)
	
	# Debug output
	#print("========== Room Change ==========")
	#print("Room center: ", new_room_center)
	#print("Room size: ", new_room_size)
	#print("Custom zoom: ", custom_zoom if custom_zoom > 0 else "Auto")
	#print("Viewport size: ", view_size)
	#print("New zoom: ", new_zoom)
	
	# Calculate actual view size at this zoom
	var actual_view_size = view_size / zoom
	#print("Actual view size at zoom: ", actual_view_size)
	
	# Check if room is bigger than view
	var x_margin = (new_room_size.x - actual_view_size.x) / 2
	var y_margin = (new_room_size.y - actual_view_size.y) / 2
	
	#print("X margin: ", x_margin, " (positive = follow player)")
	#print("Y margin: ", y_margin, " (positive = follow player)")
	#print("================================")

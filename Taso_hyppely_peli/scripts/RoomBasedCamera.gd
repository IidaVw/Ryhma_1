extends Camera2D

# Configuration
@export var transition_speed: float = 4.0
@export var default_zoom: Vector2 = Vector2(1.5, 1.5)

# References
var current_room_center: Vector2 = Vector2.ZERO
var current_room_size: Vector2 = Vector2.ZERO
var target_position: Vector2 = Vector2.ZERO
var transitioning: bool = false

# Cache viewport size for calculations
var viewport_size: Vector2

func _ready():
	# Reset everything on scene load
	zoom = default_zoom
	position_smoothing_enabled = false
	viewport_size = get_viewport_rect().size
	make_current()
	
	# Try to find initial room
	if get_parent().has_node("Rooms/room1/CollisionShape2D"):
		var initial_room = get_parent().get_node("Rooms/room1/CollisionShape2D")
		current_room_center = initial_room.global_position
		current_room_size = initial_room.shape.extents * 2
		global_position = current_room_center
		auto_match_room_size(current_room_size)

func _physics_process(delta):
	if transitioning:
		global_position = global_position.lerp(target_position, transition_speed * delta)
		if global_position.distance_to(target_position) < 1.0:
			transitioning = false
			global_position = target_position

func change_room(new_room_center: Vector2, new_room_size: Vector2):
	current_room_center = new_room_center
	current_room_size = new_room_size
	target_position = current_room_center
	auto_match_room_size(new_room_size)
	transitioning = true

func auto_match_room_size(room_size: Vector2):
	viewport_size = get_viewport_rect().size
	var margin_factor = 0.9
	var zoom_x = viewport_size.x / (room_size.x * margin_factor)
	var zoom_y = viewport_size.y / (room_size.y * margin_factor)
	var new_zoom = min(zoom_x, zoom_y)
	zoom = Vector2(new_zoom, new_zoom)

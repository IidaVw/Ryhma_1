extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const JUMP_GRAVITY = 1.0 # Gravity applied during jump
const FALL_GRAVITY = 1.7 # Gravity multiplier during fall
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") as float
var jump_buffer_time = 0.1
var jump_buffer_timer = 0.0
var coyote_time = 0.2
var coyote_timer = 0.0
var jump_pressed = false # Track whether the jump button is held
var invulnerable = false # New variable for invulnerability

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	# Make sure the player is in the "player" group
	add_to_group("player")

func _physics_process(delta):
	# Check if player is in respawn state
	var is_respawning = has_meta("respawning")
	
	# Update jump buffer time
	if Input.is_action_just_pressed("jump") and not is_respawning:
		jump_buffer_timer = jump_buffer_time
		jump_pressed = true
	if Input.is_action_just_released("jump"):
		jump_pressed = false
	jump_buffer_timer -= delta
	
	# Update coyote timer
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta
	
	# Apply gravity (always allow this)
	if not is_on_floor():
		if velocity.y > 0:
			velocity.y += gravity * FALL_GRAVITY * delta # Apply stronger gravity when falling
		else:
			velocity.y += gravity * JUMP_GRAVITY * delta # Apply normal gravity when jumping
	else:
		velocity.y = 0
	
	# Skip horizontal movement and jumping if respawning
	if is_respawning:
		velocity.x = 0  # No horizontal movement during respawn
		animated_sprite_2d.play("idle")  # Always play idle animation during respawn
		move_and_slide()
		return
	
	# Jump logic with variable jump height
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0
		coyote_timer = 0
	if not jump_pressed and velocity.y < 0:
		velocity.y *= 0.5 # If jump button is released early, decrease the vertical velocity
	
	# Movement direction
	var direction := Input.get_axis("move_left", "move_right")
	
	# Sprite flip
	if direction > 0:
		animated_sprite_2d.flip_h = false
	elif direction < 0:
		animated_sprite_2d.flip_h = true
	
	# Animations
	if is_on_floor():
		if direction == 0:
			animated_sprite_2d.play("idle")
		else:
			animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("jump")
	
	# Movement
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	# Correct method for move_and_slide() in Godot 4
	move_and_slide()

# ROOM DETECTOR SIGNAL FUNCTION
func _on_room_detector_area_entered(area: Area2D) -> void:
	var collision_shape = area.get_node("CollisionShape2D")
	if collision_shape:
		var size = collision_shape.shape.extents * 2
		Global.change_room(collision_shape.global_position, size)

# New method for temporary invulnerability
func temporarily_invulnerable():
	invulnerable = true
	# Flash the sprite to show invulnerability
	var tween = create_tween()
	tween.tween_property(animated_sprite_2d, "modulate:a", 0.5, 0.1)
	tween.tween_property(animated_sprite_2d, "modulate:a", 1.0, 0.1)
	tween.set_loops(5)
	await tween.finished
	invulnerable = false

# Prevent falling forever
func _process(_delta):
	if global_position.y > 5000:  # Adjust this value based on your level size
		var spawn_position = Global.last_checkpoint
		if spawn_position == Vector2.ZERO:
			spawn_position = Global.current_room_center
		global_position = spawn_position

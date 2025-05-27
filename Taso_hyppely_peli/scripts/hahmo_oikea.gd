extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0
const DOUBLE_JUMP_VELOCITY = -470.0
const JUMP_GRAVITY = 1.0
const FALL_GRAVITY = 1.7

# Wall jump constants - IMPROVED MARIO-STYLE
const WALL_JUMP_VELOCITY_X = 170.0  # Reduced horizontal push (Mario style)
const WALL_JUMP_VELOCITY_Y = -400.0  # Stronger upward boost 
const WALL_SLIDE_FACTOR = 5.0
const WALL_SLIDE_MAX_SPEED = 120.0
const WALL_JUMP_CONTROL_TIME = 0.1  # Shorter control restriction

# NEW - Same wall jump constants
const SAME_WALL_HEIGHT_REDUCTION = 0.8  # Each jump on same wall gives 80% of previous height
const MIN_WALL_JUMP_HEIGHT = -100.0    # Minimum wall jump height to prevent too small jumps

# ABILITY SYSTEM - NEW
var has_boots = false     # Kengät antavat tuplahypyn
var has_gloves = false    # Hanskat antavat seinäkiipeämisen

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") as float
var jump_buffer_time = 0.1
var jump_buffer_timer = 0.0
var coyote_time = 0.2
var coyote_timer = 0.0
var jump_pressed = false
var invulnerable = false

# Double jump variables
var can_double_jump = false
var has_double_jumped = false

# Wall jump variables
var wall_direction = 0  # -1 for left wall, 1 for right wall
var last_wall_direction = 0  # Track the last wall direction
var can_wall_jump = true     # Whether player can wall jump
var input_monitoring = Vector2(true, true)
var is_wall_jumping = false
var wall_jump_control_timer = 0.0
var wall_jump_control_time = 0.2
var wall_jump_particle_timer = 0.0  # For dust particles

# NEW - Same wall jump variables
var same_wall_jump_count = 0  # Track consecutive jumps on same wall
var current_wall_jump_height = WALL_JUMP_VELOCITY_Y  # Current height of wall jump

# Footstep variables
var footstep_timer = 0.0
var footstep_interval = 0.3  # Aika askelten välillä (sekunteina)
var is_moving_on_ground = false
var footstep_sounds = []  # Array useille askelääneille

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var double_jump_sound: AudioStreamPlayer2D = $DoubleJumpSound
@onready var footstep_sound: AudioStreamPlayer2D = $FootstepSound
@onready var wall_jump_sound: AudioStreamPlayer2D = $WallJumpSound

# Room zoom configuration
var room_zoom_config = {
	"room1": 1.4,
	"room2": 1.6,
	"room2_1": 1.7,
	"room3": 1.8,
	"room4": 1.4,
	"room5": 1.4,
	"room6": 1.8,
	"room6_1": 1.8,
	"room6_2": 1.85,
	"room6_3": 1.8,
	"room7": 1.6,
	"room8": 1,
	"room9": 1.65,
	"room9_1": 1.6,
	"room9_2": 1.7,
	"room10": 1.4,
	"room11": 1.3,
	"room12": 1.2,
	"room13": 0.9,
}

# ABILITY SYSTEM FUNCTIONS - NEW
func unlock_boots():
	has_boots = true
	print("Boots unlocked! Double jump available!")

func unlock_gloves():
	has_gloves = true
	print("Gloves unlocked! Wall climbing available!")

func _ready():
	add_to_group("player")
	
	# Collect all footstep sounds
	if has_node("FootstepSound"):
		footstep_sounds.append($FootstepSound)
	if has_node("FootstepSound2"):
		footstep_sounds.append($FootstepSound2)
	if has_node("FootstepSound3"):
		footstep_sounds.append($FootstepSound3)

func _physics_process(delta):
	var is_respawning = has_meta("respawning")
	
	# Input handling
	var input_dir = Input.get_axis("move_left", "move_right")
	
	# Wall detection - using get_wall_normal for consistency
	var on_wall = is_on_wall() and not is_on_floor()
	var current_wall_direction = 0
	
	if on_wall:
		var wall_normal = get_wall_normal()
		if wall_normal.x > 0:
			current_wall_direction = -1  # Wall is to the left
		else:
			current_wall_direction = 1   # Wall is to the right
			
		# Only update wall_direction if we're on a wall
		wall_direction = current_wall_direction
	
	# Update wall jump control timer
	if wall_jump_control_timer > 0:
		wall_jump_control_timer -= delta
	else:
		is_wall_jumping = false
	
	# Update wall jump particle timer
	if wall_jump_particle_timer > 0:
		wall_jump_particle_timer -= delta
	
	# Jump input
	if Input.is_action_just_pressed("jump") and not is_respawning:
		jump_buffer_timer = jump_buffer_time
		jump_pressed = true
	if Input.is_action_just_released("jump"):
		jump_pressed = false
	jump_buffer_timer -= delta
	
	# Floor detection for resets
	if is_on_floor():
		coyote_timer = coyote_time
		# MODIFIED: Only allow double jump if has boots
		if has_boots:
			can_double_jump = true
			has_double_jumped = false
		is_wall_jumping = false
		wall_jump_control_timer = 0.5
		last_wall_direction = 0  # Reset last wall direction
		same_wall_jump_count = 0  # Reset same wall jump counter
		current_wall_jump_height = WALL_JUMP_VELOCITY_Y  # Reset jump height
	else:
		coyote_timer -= delta
	
	# NEW - Reset same wall counter if not on same wall anymore
	if on_wall and wall_direction != 0 and wall_direction != last_wall_direction and last_wall_direction != 0:
		same_wall_jump_count = 0
		current_wall_jump_height = WALL_JUMP_VELOCITY_Y  # Reset jump height
	
	# Apply gravity with wall sliding
	if not is_on_floor():
		# MODIFIED: Wall sliding only with gloves
		if on_wall and velocity.y > 0 and has_gloves:
			# Mario-style wall slide - always slide down wall
			velocity.y += gravity * WALL_SLIDE_FACTOR * delta
			velocity.y = min(velocity.y, WALL_SLIDE_MAX_SPEED)
			
			# Wall dust particles periodically (visual effect)
			if velocity.y > WALL_SLIDE_MAX_SPEED * 0.5 and wall_jump_particle_timer <= 0:
				_spawn_wall_dust_particles()
				wall_jump_particle_timer = 0.2  # Every 0.2 seconds
		elif velocity.y > 0:
			velocity.y += gravity * FALL_GRAVITY * delta
		else:
			velocity.y += gravity * JUMP_GRAVITY * delta
	else:
		velocity.y = 0
	
	# Respawn state
	if is_respawning:
		velocity.x = 0
		animated_sprite_2d.play("idle")
		move_and_slide()
		return
	
	# Jump logic
	if jump_buffer_timer > 0:
		# MODIFIED: Wall jump only with gloves
		if on_wall and not is_on_floor() and has_gloves:
			var can_perform_wall_jump = true  # Always allow wall jumps
			
			if wall_direction == last_wall_direction:
				# Same wall jump - increment counter for debugging
				same_wall_jump_count += 1
				
				# Reduce jump height for consecutive same-wall jumps
				current_wall_jump_height *= SAME_WALL_HEIGHT_REDUCTION
				
				# Ensure jump height doesn't get too small
				if current_wall_jump_height > MIN_WALL_JUMP_HEIGHT:
					current_wall_jump_height = MIN_WALL_JUMP_HEIGHT
			else:
				# Different wall - reset counter and height
				same_wall_jump_count = 0
				current_wall_jump_height = WALL_JUMP_VELOCITY_Y
			
			if can_perform_wall_jump:
				_wall_jump_mario_style(current_wall_jump_height)
				jump_buffer_timer = 0
				last_wall_direction = wall_direction  # Update last wall
		# Normal jump
		elif coyote_timer > 0:
			velocity.y = JUMP_VELOCITY
			jump_buffer_timer = 0
			coyote_timer = 0
			
			# Play jump sound
			if jump_sound:
				jump_sound.pitch_scale = 1.0  # Normaali sävy
				jump_sound.play()
			
			# MODIFIED: Only allow double jump if has boots
			if has_boots:
				can_double_jump = true
		# MODIFIED: Double jump only with boots
		elif can_double_jump and not has_double_jumped and not is_on_floor() and has_boots:
			velocity.y = DOUBLE_JUMP_VELOCITY
			jump_buffer_timer = 0
			has_double_jumped = true
			can_double_jump = false
			
			# Play double jump sound (higher pitch)
			if double_jump_sound:
				double_jump_sound.pitch_scale = 1.3  # Korkeampi sävy
				double_jump_sound.play()
	
	# Variable jump height
	if not jump_pressed and velocity.y < 0 and not is_wall_jumping:
		velocity.y *= 0.5
	
	# Sprite flipping
	if velocity.x > 0:
		animated_sprite_2d.flip_h = false
	elif velocity.x < 0:
		animated_sprite_2d.flip_h = true
	
	# Animations
	if is_on_floor():
		if input_dir == 0:
			animated_sprite_2d.play("idle")
			is_moving_on_ground = false
		else:
			animated_sprite_2d.play("run")
			is_moving_on_ground = true
	else:
		is_moving_on_ground = false
		# MODIFIED: Wall slide animation only with gloves
		if on_wall and velocity.y > 0 and has_gloves:
			animated_sprite_2d.play("jump")  # Use "wall_slide" if available
		else:
			animated_sprite_2d.play("jump")
	
	# Footstep sound logic
	if is_moving_on_ground and not is_respawning:
		footstep_timer += delta
		if footstep_timer >= footstep_interval:
			# Play random footstep sound for variety
			if footstep_sounds.size() > 0:
				var random_sound = footstep_sounds[randi() % footstep_sounds.size()]
				random_sound.pitch_scale = randf_range(0.9, 1.1)
				random_sound.play()
			elif footstep_sound:  # Fallback to single sound
				footstep_sound.pitch_scale = randf_range(0.9, 1.1)
				footstep_sound.play()
			footstep_timer = 0.0
	else:
		footstep_timer = 0.0  # Reset timer kun ei liiku
	
	# Movement with wall jump momentum preservation
	if input_dir != 0:
		if is_wall_jumping and wall_jump_control_timer > 0:
			# Mario-style: limited control during wall jump
			if sign(input_dir) == sign(velocity.x):
				# Allow acceleration in same direction
				velocity.x = move_toward(velocity.x, input_dir * SPEED, SPEED * delta)
			else:
				# Limited control against momentum
				velocity.x = move_toward(velocity.x, velocity.x + (input_dir * SPEED * 0.2), SPEED * delta)
		else:
			# Normal movement
			velocity.x = input_dir * SPEED
	else:
		# Immediate stop on ground, gradual stop in air
		if is_on_floor() and not is_wall_jumping:
			velocity.x = 0  # Instant stop on ground
		else:
			# In air or during wall jump - gradual deceleration
			if not is_wall_jumping or wall_jump_control_timer <= 0:
				velocity.x = move_toward(velocity.x, 0, SPEED * delta * 3)
	
	move_and_slide()

# MODIFIED WALL JUMP FUNCTION - only works with gloves
func _wall_jump_mario_style(jump_height = WALL_JUMP_VELOCITY_Y):
	if not has_gloves:
		return  # Can't wall jump without gloves
		
	# Calculate velocities - Mario has more upward boost
	velocity.x = WALL_JUMP_VELOCITY_X * -wall_direction
	velocity.y = jump_height  # Use the passed jump height (will be reduced for same wall)
	
	# Set wall jump state
	is_wall_jumping = true
	wall_jump_control_timer = WALL_JUMP_CONTROL_TIME
	
	# Spawn kick-off dust particles (visual effect)
	_spawn_wall_jump_particles()
	
	# Play wall jump sound
	if wall_jump_sound:
		wall_jump_sound.play()
	elif jump_sound:  # Varaplan jos ei ole omaa wall jump soundia
		jump_sound.pitch_scale = 0.8  # Matalampi sävy seinähyppyyn
		jump_sound.play()
		# Palauta normaali sävy seuraavaa hyppyä varten
		await jump_sound.finished
		jump_sound.pitch_scale = 1.0

# For wall dust particles when sliding down
func _spawn_wall_dust_particles():
	# This would be implemented if you have a particle system
	# You could instance a particle effect at the player's position
	pass

# For kick-off particles when wall jumping
func _spawn_wall_jump_particles():
	# This would be implemented if you have a particle system
	# Position the particles at the wall contact point
	var particle_position = global_position
	particle_position.x += 10 * wall_direction  # Offset toward the wall
	
	# You could instance a particle effect at this position
	pass

# ROOM DETECTOR SIGNAL FUNCTION
func _on_room_detector_area_entered(area: Area2D) -> void:
	if area.name.begins_with("room"):
		var collision_shape = area.get_node("CollisionShape2D")
		if collision_shape:
			var size = collision_shape.shape.extents * 2
			var room_name = area.name
			var custom_zoom = -1.0
			
			if room_zoom_config.has(room_name):
				custom_zoom = room_zoom_config[room_name]
			
			Global.change_room(collision_shape.global_position, size, custom_zoom)

func temporarily_invulnerable():
	invulnerable = true
	var tween = create_tween()
	tween.tween_property(animated_sprite_2d, "modulate:a", 0.5, 0.1)
	tween.tween_property(animated_sprite_2d, "modulate:a", 1.0, 0.1)
	tween.set_loops(5)
	await tween.finished
	invulnerable = false

func _process(_delta):
	if global_position.y > 5000:
		var spawn_position = Global.last_checkpoint
		if spawn_position == Vector2.ZERO:
			spawn_position = Global.current_room_center
		global_position = spawn_position

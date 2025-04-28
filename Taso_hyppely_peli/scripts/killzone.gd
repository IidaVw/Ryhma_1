extends Area2D

var death_timer: Timer
var respawn_timer: Timer
var respawning_player: CharacterBody2D = null

func _ready():
	# Create death timer (delay before respawn)
	death_timer = Timer.new()
	death_timer.one_shot = true
	death_timer.wait_time = 0.6  # 0.6 second delay before respawning
	death_timer.connect("timeout", Callable(self, "_on_death_timer_timeout"))
	add_child(death_timer)
	
	# Create respawn timer (delay before player can move)
	respawn_timer = Timer.new()
	respawn_timer.one_shot = true
	respawn_timer.wait_time = 1  # 1 second delay before player can move
	respawn_timer.connect("timeout", Callable(self, "_on_respawn_timer_timeout"))
	add_child(respawn_timer)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body is CharacterBody2D and death_timer.is_stopped():
		GameManager.add_death()
		respawning_player = body
		
		# Disable physics processing during death delay
		body.set_physics_process(false)
		
		# Start death timer
		death_timer.start()

func _on_death_timer_timeout() -> void:
	if respawning_player:
		# Check if we have a checkpoint, otherwise use room center
		var spawn_position = Global.last_checkpoint
		if Global.last_checkpoint == Vector2.ZERO:
			spawn_position = Global.current_room_center
		
		# Reset player position and velocity
		respawning_player.global_position = spawn_position
		respawning_player.velocity = Vector2.ZERO
		
		# Re-enable physics but restrict movement
		respawning_player.set_physics_process(true)
		respawning_player.set_meta("respawning", true)
		
		# Force camera update to follow player to new position
		var camera = respawning_player.get_viewport().get_camera_2d()
		if camera:
			camera.global_position = spawn_position
		
		# Make player blink - always do this instead of checking for the method
		make_player_blink(respawning_player)
		
		# Start respawn timer (player can fall but not move horizontally)
		respawn_timer.start()

func _on_respawn_timer_timeout() -> void:
	if respawning_player:
		# Remove the respawning flag
		respawning_player.remove_meta("respawning")
		respawning_player = null

# Function to make player blink
func make_player_blink(player: CharacterBody2D):
	player.invulnerable = true
	var sprite = player.get_node("AnimatedSprite2D")
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.3, 0.1)
		tween.tween_property(sprite, "modulate:a", 1.0, 0.1) #Each complete cycle takes 0.2 seconds
		tween.set_loops(5)  # Blink 10 times = 2s  Blink 5 times = 1s 
		tween.connect("finished", Callable(self, "_on_blink_finished").bind(player))

# When blinking finishes
func _on_blink_finished(player: CharacterBody2D):
	player.invulnerable = false

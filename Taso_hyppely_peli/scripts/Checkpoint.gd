extends Area2D

func _ready():
	# If this is the first checkpoint and no other checkpoint is set,
	# set it as the default checkpoint
	if Global.last_checkpoint == Vector2.ZERO:
		Global.set_checkpoint(global_position)

func _on_body_entered(body: Node2D) -> void:
	# Only detect the player, not TileMap
	if body.is_in_group("player"):
		Global.set_checkpoint(global_position)

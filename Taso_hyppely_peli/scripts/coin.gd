extends Area2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("+1 coin!")
		GameManager.set_coin(GameManager.coin_counter + 1)
		animation_player.play("pickup")

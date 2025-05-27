extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Gloves collected! Wall climbing unlocked!")
		
		# Anna pelaajalle seinäkiipeäminen
		body.unlock_gloves()
		
		# Poista hanskat
		queue_free()

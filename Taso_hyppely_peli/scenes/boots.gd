extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Boots collected! Double jump unlocked!")
		
		# Anna pelaajalle tuplahyppy
		body.unlock_boots()
		
		# Poista kengät
		queue_free()

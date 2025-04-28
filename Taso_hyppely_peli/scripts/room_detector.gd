extends CharacterBody2D

@onready var global_script: Node = get_tree().get_node("/root/Global")

func _on_room_detector_area_entered(area: Area2D) -> void:
	# Hakee huoneen CollisionShape2D:n ja sen koon
	var collision_shape: CollisionShape2D = area.get_node("CollisionShape2D")
	var size: Vector2 = collision_shape.shape.extents * 2  # Laskee huoneen koon
	# Kutsutaan Global-skriptiä ja annetaan huoneen sijainti ja koko
	global_script.change_room(collision_shape.global_position, size)

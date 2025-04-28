extends Node

signal player_died

var score = 0
var deaths = 0

func add_point():
	score += 1
	print("Score: ", score)

func add_death():
	deaths += 1
	print("Deaths: ", deaths)
	emit_signal("player_died")  # Emit signal when player dies
	

# ===== GAMEMANAGER.GD (Signaalien kanssa) =====
extends Node

# Signaalit jotka lähetetään kun arvot muuttuvat
signal coins_changed(new_count)
signal deaths_changed(new_count)

var score = 0
var deaths = 0
var coin_counter = 0

func add_death():
	deaths += 1
	print("Deaths: ", deaths)
	emit_signal("deaths_changed", deaths)  # Lähettää kaikille UI:lle

func set_coin(new_coin_count: int) -> void:
	coin_counter = new_coin_count
	print("Coins: ", coin_counter)
	emit_signal("coins_changed", coin_counter)  # Lähettää kaikille UI:lle

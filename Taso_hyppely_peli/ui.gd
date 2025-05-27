extends Control

@onready var coin_label: Label = $CoinLabe
@onready var death_label: Label = $DeathLabel

func _ready():
	# Kuuntele GameManagerin signaaleja
	GameManager.connect("coins_changed", _on_coins_changed)
	GameManager.connect("deaths_changed", _on_deaths_changed)
	
	# Aseta alkuarvot
	_on_coins_changed(GameManager.coin_counter)
	_on_deaths_changed(GameManager.deaths)

func _on_coins_changed(new_count: int):
	if coin_label:
		coin_label.text = "Coins: " + str(new_count)

func _on_deaths_changed(new_count: int):
	if death_label:
		death_label.text = "Deaths: " + str(new_count)

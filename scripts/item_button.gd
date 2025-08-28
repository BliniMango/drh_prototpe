extends VBoxContainer

signal item_purchased(item_key: String)

@onready var item_name_label: Label = $ItemNameLabel
@onready var item_description_label: Label = $ItemDescriptionLabel
@onready var price_label: Label = $PriceLabel
@onready var buy_button: Button = $BuyButton

var item_key: String
var item_data: Dictionary
var player_money: float 

func setup_item(key: String, data: Dictionary, money: float) -> void:
	item_key = key
	item_data = data
	player_money = money

	item_name_label.text = data["name"]
	item_description_label.text = data["description"]
	price_label.text = "${0}".format([data.price])

	update_affordability(money)

	buy_button.pressed.connect(_on_buy_pressed)

func update_affordability(money: float):
	player_money = money
	buy_button.disabled = money < item_data.price

	if money < item_data.price:
		modulate = Color(0.7, 0.7, 0.7)
	else:
		modulate = Color.WHITE
	
func _on_buy_pressed() -> void:
	if player_money >= item_data.price:
		item_purchased.emit(item_key)

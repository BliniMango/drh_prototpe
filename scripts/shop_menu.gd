extends Control
@onready var money_label: Label = $MoneyLabel
@onready var item_container: HBoxContainer = $ItemContainer
@onready var close_button: Button = $ItemContainer/CloseButton

const item_button_prefab : PackedScene = preload("res://scenes/item_button.tscn")

var current_shop: Shop
var player : Player

func setup_shop(shop: Shop) -> void:
	current_shop = shop
	player = GameManager.player
	update_money_display()
	populate_items()
	show()

func populate_items() -> void:
	for child in item_container.get_children():
		child.queue_free()
	
	for item_key in current_shop.shop_items:
		var item_data = current_shop.shop_items[item_key]
		var item_button = item_button_prefab.instantiate()

		item_button.item_purchased.connect(_on_item_purchased)
		
		item_container.add_child(item_button)
		item_button.setup_item(item_key, item_data, player.money)

func update_money_display() -> void:
	money_label.text = "Money: ${0}".format([player.money])

func _on_item_purchased(item_key: String) -> void:
	var item_data = current_shop.shop_items[item_key]

	player.money -= item_data.price
	player.apply_item_effect(item_key)

	update_money_display()
	for child in item_container.get_children():
		child.update_affordability(player.money)

extends Control
@onready var money_label: Label = $ColorRect/MoneyLabel
@onready var item_container: GridContainer = $ColorRect/ItemContainer
@onready var close_button: Button = $ColorRect/CloseButton

const item_button_prefab : PackedScene = preload("res://scenes/item_button.tscn")

var current_shop: Shop
var player : Player

func setup_shop(shop: Shop) -> void:
	current_shop = shop
	player = GameManager.player
	update_money_display()
	populate_items()
	show()
	player.set_physics_process(false)
	player.set_process(false)
	close_button.pressed.connect(_on_close_button_pressed)

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
	player.update_ammo_ui()
	player.update_dynamite_ui()
	player.update_health_ui()
	player.update_money_ui()

	update_money_display()
	for child in item_container.get_children():
		child.update_affordability(player.money)

func _on_close_button_pressed() -> void:
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player.set_physics_process(true)
	player.set_process(true)

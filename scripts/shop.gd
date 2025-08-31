class_name Shop
extends StaticBody3D

signal shop_interaction_requested(shop: Shop)

@onready var interact_area: Area3D = $InteractArea
@onready var interact_text: Label3D = $InteractText

var player_nearby : bool
var shop_items = {
	"deposit": {
		"price": 100,
		"name": "Deposit",
		"description": "Risk more? Earn more?"
	},
	"health_pack": {
		"price": 150, 
		"name": "Health Pack",
		"description": "Heal"
	},
	"ammo_refill": {
		"price": 250, 
		"name": "Ammo Refill",
		"description": "Reload"
	},
	"speed_demon": {
		"price": 2000, 
		"name": "Speed Demon",
		"description": "Speed+"
	},
	"trigger_happy": {
		"price": 3000, 
		"name": "Trigger Happy",
		"description": "Fire Rate+"
	},
	"tank_mode": {
		"price": 5000, 
		"name": "Tank Mode",
		"description": "Health+"
	},
	"dash_master": {
		"price": 3000, 
		"name": "Dash Master",
		"description": "Dash+"
	},
	"dynamite_cache": {
		"price": 400, 
		"name": "Dynamite Cache",
		"description": "Bombs"
	},
	"gunslinger": {
		"price": 5000, 
		"name": "Gunslinger",
		"description": "Quick Reload"
	}
}

func _input(event) -> void:
	if player_nearby and event.is_action_pressed("interact"):
		open_shop()

func _ready() -> void:
	add_to_group("shop")
	interact_area.area_entered.connect(_on_player_entered)
	interact_area.area_exited.connect(_on_player_exited)

func _on_player_entered(area: Area3D):
	var entity = area.get_parent()
	if entity.is_in_group("player"):
		player_nearby = true
	interact_text.visible = true

func _on_player_exited(area: Area3D):
	if area.is_in_group("player"):
		player_nearby = false
	interact_text.visible = false


func open_shop():
	if GameManager.current_wave_state == GameManager.WaveState.SHOP:
		shop_interaction_requested.emit(self)

func can_purchase(item_key: String, money: float) -> bool:
	if shop_items.has(item_key):
		return money >= shop_items[item_key].price
	return false

func get_item_price(item_key: String) -> int:
	if shop_items.has(item_key):
		return shop_items[item_key].price
	return 0

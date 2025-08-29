class_name Shop
extends StaticBody3D

signal shop_interaction_requested(shop: Shop)

@onready var interact_area: Area3D = $InteractArea

var player_nearby : bool
var shop_items = {
	"health_pack": {
		"price": 50, 
		"name": "Health Pack",
		"description": "Heal"
	},
	"ammo_refill": {
		"price": 30, 
		"name": "Ammo Refill",
		"description": "Reload"
	},
	"speed_demon": {
		"price": 75, 
		"name": "Speed Demon",
		"description": "Speed+"
	},
	"trigger_happy": {
		"price": 100, 
		"name": "Trigger Happy",
		"description": "Fire Rate+"
	},
	"tank_mode": {
		"price": 125, 
		"name": "Tank Mode",
		"description": "Health+"
	},
	"dash_master": {
		"price": 80, 
		"name": "Dash Master",
		"description": "Dash+"
	},
	"dynamite_cache": {
		"price": 60, 
		"name": "Dynamite Cache",
		"description": "Bombs"
	},
	"gunslinger": {
		"price": 90, 
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


func _on_player_exited(area: Area3D):
	if area.is_in_group("player"):
		player_nearby = false

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

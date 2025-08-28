class_name Shop
extends StaticBody3D

signal shop_interaction_requested(shop: Shop)

@onready var interact_area: Area3D = $InteractArea

var player_nearby : bool
var shop_items = {
	"health_pack": {
		"price": 50, 
		"name": "Health Pack",
		"description": "Restore full health"
	},
	"ammo_refill": {
		"price": 30, 
		"name": "Ammo Refill",
		"description": "Reload current weapon"
	},
	"speed_demon": {
		"price": 75, 
		"name": "Speed Demon",
		"description": "+40% movement speed"
	},
	"trigger_happy": {
		"price": 100, 
		"name": "Trigger Happy",
		"description": "Double fire rate"
	},
	"tank_mode": {
		"price": 125, 
		"name": "Tank Mode",
		"description": "+25 max health, -20% speed"
	},
	"dash_master": {
		"price": 80, 
		"name": "Dash Master",
		"description": "50% faster dash cooldown"
	},
	"dynamite_cache": {
		"price": 60, 
		"name": "Dynamite Cache",
		"description": "Gain 3 dynamite"
	},
	"gunslinger": {
		"price": 90, 
		"name": "Gunslinger",
		"description": "Near-instant revolver reload"
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
		print("yo")


func _on_player_exited(area: Area3D):
	if area.is_in_group("player"):
		player_nearby = false

func open_shop():
	print("trying to open shop")
	if GameManager.current_wave_state == GameManager.WaveState.SHOP:
		shop_interaction_requested.emit(self)
		print("opening shop")

func can_purchase(item_key: String, money: float) -> bool:
	if shop_items.has(item_key):
		return money >= shop_items[item_key].price
	return false

func get_item_price(item_key: String) -> int:
	if shop_items.has(item_key):
		return shop_items[item_key].price
	return 0

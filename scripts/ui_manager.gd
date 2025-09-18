extends CanvasLayer

@onready var announce_label: Label = $HUD/AnnounceLabel
@onready var shop_timer_label: Label = $HUD/ShopTimerLabel
@onready var bank_money_label: Label = $HUD/BankMoneyLabel
@onready var shop_menu: Control = $Menus/ShopMenu

var _prev_bank_money: int = -1

func _ready():
	add_to_group("ui")
	update_announce_text("Shop")  # Show initial text
	GameManager.start_game()  # Start the wave system

func _process(delta):
	
	# Update shop timer when in shop state
	if GameManager.current_wave_state == GameManager.WaveState.SHOP:
		update_shop_timer(GameManager.shop_timer)
		if shop_timer_label: shop_timer_label.show()
	else:
		if shop_timer_label: shop_timer_label.hide()
	
	# Update announce label based on game state
	match GameManager.current_wave_state:
		GameManager.WaveState.COMBAT:
			update_announce_text("Wave %d" % GameManager.current_wave)
		GameManager.WaveState.SHOP:
			update_announce_text("Shop")
		GameManager.WaveState.TRANSITION:
			update_announce_text("Wave %d Complete!" % (GameManager.current_wave))

func update_announce_text(text: String):
	if announce_label:
		announce_label.text = text

func update_shop_timer(time: float):
	if shop_timer_label:
		var total = int(ceil(max(0.0, time)))
		var m = total / 60
		var s = total % 60
		shop_timer_label.text = "%02d:%02d" % [m, s]

func show_shop(shop: Shop):
	if shop_menu:
		if shop_menu.has_method("setup_shop"):
			shop_menu.setup_shop(shop)
		shop_menu.show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_music_finished() -> void:
	pass # Replace with function body.

extends Node3D

enum WaveState { COMBAT, SHOP, TRANSITION }

var current_num_enemies: int
var current_shop: Shop
var bank: Bank
var player: Player

var current_wave : int = 1
var current_wave_state : WaveState = WaveState.SHOP
var shop_timer : float = 30.0

var wave_start_time : float = 0.0
var current_wave_time : float = 0.0
var wave_events_completed : Array[int] = []

# --- Configure your wave timelines here ---
var wave_timelines := {
	1: [
		{"time": 0.0, "spawner": "left",  "enemy": "gunner", "count": 2},
		{"time": 3.0, "spawner": "right", "enemy": "gunner", "count": 2},
		{"time": 8.0, "spawner": "left",  "enemy": "brute",  "count": 1}
	],
	2: [
		{"time": 0.0, "spawner": "left",  "enemy": "gunner", "count": 3},
		{"time": 2.0, "spawner": "right", "enemy": "gunner", "count": 2},
		{"time": 5.0, "spawner": "left",  "enemy": "gunner", "count": 2},
		{"time": 10.0,"spawner": "right", "enemy": "brute",  "count": 1}
	],
	3: [
		{"time": 0.0,  "spawner": "left",  "enemy": "gunner", "count": 2},
		{"time": 1.0,  "spawner": "right", "enemy": "gunner", "count": 2},
		{"time": 4.0,  "spawner": "left",  "enemy": "bomber", "count": 1},
		{"time": 8.0,  "spawner": "right", "enemy": "brute",  "count": 1},
		{"time": 12.0, "spawner": "left",  "enemy": "brute",  "count": 1}
	],
	4: [
		{"time": 0.0, "spawner": "left",  "enemy": "gunner", "count": 3},
		{"time": 0.5,"spawner": "right", "enemy": "gunner", "count": 3},
		{"time": 3.0, "spawner": "left",  "enemy": "bomber", "count": 2},
		{"time": 7.0, "spawner": "right", "enemy": "brute",  "count": 2},
		{"time": 12.0,"spawner": "left",  "enemy": "gunner", "count": 2}
	],
	5: [
		{"time": 0.0,  "spawner": "left",  "enemy": "gunner", "count": 4},
		{"time": 1.0,  "spawner": "right", "enemy": "bomber", "count": 2},
		{"time": 3.0,  "spawner": "left",  "enemy": "gunner", "count": 3},
		{"time": 6.0,  "spawner": "right", "enemy": "brute",  "count": 2},
		{"time": 10.0, "spawner": "left",  "enemy": "brute",  "count": 1},
		{"time": 10.5,"spawner": "right", "enemy": "brute",  "count": 1},
		{"time": 15.0, "spawner": "left",  "enemy": "bomber", "count": 1}
	],
	6: [
		{"time": 0.0, "spawner": "left",  "enemy": "bomber", "count": 2},
		{"time": 0.5,"spawner": "right", "enemy": "bomber", "count": 2},
		{"time": 2.0, "spawner": "left",  "enemy": "gunner", "count": 4},
		{"time": 5.0, "spawner": "right", "enemy": "brute",  "count": 2},
		{"time": 8.0, "spawner": "left",  "enemy": "gunner", "count": 3},
		{"time": 8.5,"spawner": "right", "enemy": "gunner", "count": 3},
		{"time": 13.0,"spawner": "left",  "enemy": "brute",  "count": 2}
	],
	7: [
		{"time": 0.0, "spawner": "left",  "enemy": "gunner", "count": 3},
		{"time": 0.5,"spawner": "right", "enemy": "gunner", "count": 3},
		{"time": 1.0, "spawner": "left",  "enemy": "gunner", "count": 3},
		{"time": 3.0, "spawner": "right", "enemy": "bomber", "count": 3},
		{"time": 6.0, "spawner": "left",  "enemy": "brute",  "count": 2},
		{"time": 6.5,"spawner": "right", "enemy": "brute",  "count": 2},
		{"time": 10.0,"spawner": "left",  "enemy": "bomber", "count": 2},
		{"time": 15.0,"spawner": "right", "enemy": "brute",  "count": 1}
	],
	8: [
		{"time": 0.0, "spawner": "left",  "enemy": "bomber", "count": 3},
		{"time": 1.0, "spawner": "right", "enemy": "bomber", "count": 3},
		{"time": 2.0, "spawner": "left",  "enemy": "gunner", "count": 5},
		{"time": 4.0, "spawner": "right", "enemy": "brute",  "count": 3},
		{"time": 7.0, "spawner": "left",  "enemy": "gunner", "count": 4},
		{"time": 7.5,"spawner": "right", "enemy": "gunner", "count": 4},
		{"time": 11.0,"spawner": "left",  "enemy": "brute",  "count": 2},
		{"time": 16.0,"spawner": "right", "enemy": "bomber", "count": 2}
	],
	9: [
		{"time": 0.0, "spawner": "left",  "enemy": "gunner", "count": 4},
		{"time": 0.5,"spawner": "right", "enemy": "gunner", "count": 4},
		{"time": 1.0, "spawner": "left",  "enemy": "bomber", "count": 4},
		{"time": 3.0, "spawner": "right", "enemy": "brute",  "count": 3},
		{"time": 6.0, "spawner": "left",  "enemy": "brute",  "count": 2},
		{"time": 6.5,"spawner": "right", "enemy": "brute",  "count": 2},
		{"time": 9.0, "spawner": "left",  "enemy": "gunner", "count": 5},
		{"time": 13.0,"spawner": "right", "enemy": "bomber", "count": 3},
		{"time": 18.0,"spawner": "left",  "enemy": "brute",  "count": 1},
		{"time": 18.5,"spawner": "right", "enemy": "brute",  "count": 1}
	],
	10: [
		{"time": 0.0, "spawner": "left",  "enemy": "bomber", "count": 4},
		{"time": 0.5,"spawner": "right", "enemy": "bomber", "count": 4},
		{"time": 1.5,"spawner": "left",  "enemy": "gunner", "count": 6},
		{"time": 2.0, "spawner": "right", "enemy": "gunner", "count": 6},
		{"time": 4.0, "spawner": "left",  "enemy": "brute",  "count": 3},
		{"time": 4.5,"spawner": "right", "enemy": "brute",  "count": 3},
		{"time": 7.0, "spawner": "left",  "enemy": "bomber", "count": 4},
		{"time": 10.0,"spawner": "right", "enemy": "brute",  "count": 4},
		{"time": 14.0,"spawner": "left",  "enemy": "gunner", "count": 5},
		{"time": 14.5,"spawner": "right", "enemy": "gunner", "count": 5},
		{"time": 18.0,"spawner": "left",  "enemy": "brute",  "count": 2},
		{"time": 22.0,"spawner": "right", "enemy": "bomber", "count": 3}
	]
}

func _ready() -> void:
	set_player()
	current_wave_state = WaveState.SHOP
	shop_timer = 30.0
	
	call_deferred("setup_shop_connection")

func setup_shop_connection():
	var shops := get_tree().get_nodes_in_group("shop")
	
	if shops.size() > 0:
		current_shop = shops[0]
		current_shop.shop_interaction_requested.connect(_on_shop_requested)
	else:
		await get_tree().create_timer(1.0).timeout
		setup_shop_connection()

func _process(delta: float) -> void:
	match current_wave_state:
		WaveState.COMBAT:
			check_wave_completion()
			current_wave_time += delta
			var current_timeline: Array = wave_timelines.get(current_wave, [])
			for i in current_timeline.size():
				var event: Dictionary = current_timeline[i]
				if current_wave_time >= float(event["time"]) and not i in wave_events_completed:
					execute_spawn_event(event)
					wave_events_completed.append(i)
		WaveState.SHOP:
			shop_timer -= delta
			if shop_timer <= 0.0:
				change_state(WaveState.COMBAT)
		WaveState.TRANSITION:
			pass


func change_state(state: WaveState) -> void:
	current_wave_state = state
	
	match state:
		WaveState.COMBAT:
			current_wave_time = 0.0
			wave_events_completed.clear()
			start_spawners()

		WaveState.SHOP:
			stop_spawners()
			shop_timer = 30.0
			
		WaveState.TRANSITION:
			stop_spawners()
			cash_out_bank()
			await get_tree().create_timer(3.0).timeout
			current_wave += 1  # Advance wave BEFORE going to shop
			change_state(WaveState.SHOP)

# -------------------- Spawning & Wave Helpers --------------------

func is_wave_timeline_complete() -> bool:
	var total_events := (wave_timelines.get(current_wave, []) as Array).size()
	return wave_events_completed.size() >= total_events

func check_wave_completion() -> void:
	var timeline_complete = is_wave_timeline_complete()
	var no_enemies = get_total_enemies() == 0
	var spawners_done = all_spawners_finished()
	
	if timeline_complete and no_enemies and spawners_done:
		change_state(WaveState.TRANSITION)

func all_spawners_finished() -> bool:
	var spawners = get_tree().get_nodes_in_group("spawner")
	for spawner in spawners:
		if spawner.is_spawning:  
			return false
	return true

func execute_spawn_event(event: Dictionary) -> void:
	var spawner := get_spawner_by_id(String(event["spawner"]))
	if spawner:
		spawner.enabled = true
		spawner.spawn_enemies(String(event["enemy"]), int(event["count"]))

func get_spawner_by_id(id: String) -> Node:
	var spawners := get_tree().get_nodes_in_group("spawner")
	for spawner in spawners:
		if spawner.spawn_id == id:
			return spawner
	return null

func start_spawners() -> void:
	var spawners: Array[Node] = get_tree().get_nodes_in_group("spawner")
	for spawner in spawners:
		spawner.enabled = true

func stop_spawners() -> void:
	var spawners: Array[Node] = get_tree().get_nodes_in_group("spawner")
	for spawner in spawners:
		spawner.enabled = false
		spawner.spawn_queue.clear()
		spawner.is_spawning = false

func get_total_enemies() -> int:
	return get_tree().get_nodes_in_group("enemy").size()

func set_player() -> void:
	player = get_tree().get_first_node_in_group("player")

func get_enemies_in_scene() -> Array[Node]:
	return get_tree().get_nodes_in_group("enemy")

# -------------------- Shop --------------------

func _on_shop_requested(shop: Shop) -> void:
	if current_wave_state != WaveState.SHOP:
		return
		
	var ui = get_tree().get_first_node_in_group("ui")

	if ui:
		ui.show_shop(shop)

func register_bank(bank_instance: Bank) -> void:
	bank = bank_instance

func get_bank() -> Bank:
	return bank

func cash_out_bank() -> void:
	if bank and player:
		var bank_amount = bank.bank_money
		if bank_amount > 0:
			player.money += bank_amount
			bank.bank_money = int(bank_amount * 1.2)

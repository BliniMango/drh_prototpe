extends Node3D

@onready var announce_label: Label = $UICanvas/HUD/AnnounceLabel
@onready var shop_menu: Control = $UICanvas/Menus/ShopMenu

enum WaveState {
	COMBAT,
	SHOP,
	TRANSITION,
}

var current_shop: Shop

var player: Player

var max_num_enemies : int = 50
var current_num_enemies : int = 0
var current_wave : int = 0
var current_wave_state : WaveState = WaveState.SHOP
var shop_timer : float = 30

var wave_start_time : float = 0.0
var current_wave_time : float = 0.0

var wave_timelines = {
	1: [
		{"time": 0.0, "spawner": "left", "enemy": "gunner", "count": 2},
		{"time": 3.0, "spawner": "right", "enemy": "gunner", "count": 2},
		{"time": 8.0, "spawner": "left", "enemy": "brute", "count": 1}
	],
	2: [
		{"time": 0.0, "spawner": "left", "enemy": "gunner", "count": 3},
		{"time": 2.0, "spawner": "right", "enemy": "gunner", "count": 2},
		{"time": 5.0, "spawner": "left", "enemy": "gunner", "count": 2},
		{"time": 10.0, "spawner": "right", "enemy": "brute", "count": 1}
	],
	3: [
		{"time": 0.0, "spawner": "left", "enemy": "gunner", "count": 2},
		{"time": 1.0, "spawner": "right", "enemy": "gunner", "count": 2},
		{"time": 4.0, "spawner": "left", "enemy": "bomber", "count": 1},
		{"time": 8.0, "spawner": "right", "enemy": "brute", "count": 1},
		{"time": 12.0, "spawner": "left", "enemy": "brute", "count": 1}
	],
	4: [
		{"time": 0.0, "spawner": "left", "enemy": "gunner", "count": 3},
		{"time": 0.5, "spawner": "right", "enemy": "gunner", "count": 3},
		{"time": 3.0, "spawner": "left", "enemy": "bomber", "count": 2},
		{"time": 7.0, "spawner": "right", "enemy": "brute", "count": 2},
		{"time": 12.0, "spawner": "left", "enemy": "gunner", "count": 2}
	],
	5: [
		{"time": 0.0, "spawner": "left", "enemy": "gunner", "count": 4},
		{"time": 1.0, "spawner": "right", "enemy": "bomber", "count": 2},
		{"time": 3.0, "spawner": "left", "enemy": "gunner", "count": 3},
		{"time": 6.0, "spawner": "right", "enemy": "brute", "count": 2},
		{"time": 10.0, "spawner": "left", "enemy": "brute", "count": 1},
		{"time": 10.5, "spawner": "right", "enemy": "brute", "count": 1},
		{"time": 15.0, "spawner": "left", "enemy": "bomber", "count": 1}
	],
	6: [
		{"time": 0.0, "spawner": "left", "enemy": "bomber", "count": 2},
		{"time": 0.5, "spawner": "right", "enemy": "bomber", "count": 2},
		{"time": 2.0, "spawner": "left", "enemy": "gunner", "count": 4},
		{"time": 5.0, "spawner": "right", "enemy": "brute", "count": 2},
		{"time": 8.0, "spawner": "left", "enemy": "gunner", "count": 3},
		{"time": 8.5, "spawner": "right", "enemy": "gunner", "count": 3},
		{"time": 13.0, "spawner": "left", "enemy": "brute", "count": 2}
	],
	7: [
		{"time": 0.0, "spawner": "left", "enemy": "gunner", "count": 3},
		{"time": 0.5, "spawner": "right", "enemy": "gunner", "count": 3},
		{"time": 1.0, "spawner": "left", "enemy": "gunner", "count": 3},
		{"time": 3.0, "spawner": "right", "enemy": "bomber", "count": 3},
		{"time": 6.0, "spawner": "left", "enemy": "brute", "count": 2},
		{"time": 6.5, "spawner": "right", "enemy": "brute", "count": 2},
		{"time": 10.0, "spawner": "left", "enemy": "bomber", "count": 2},
		{"time": 15.0, "spawner": "right", "enemy": "brute", "count": 1}
	],
	8: [
		{"time": 0.0, "spawner": "left", "enemy": "bomber", "count": 3},
		{"time": 1.0, "spawner": "right", "enemy": "bomber", "count": 3},
		{"time": 2.0, "spawner": "left", "enemy": "gunner", "count": 5},
		{"time": 4.0, "spawner": "right", "enemy": "brute", "count": 3},
		{"time": 7.0, "spawner": "left", "enemy": "gunner", "count": 4},
		{"time": 7.5, "spawner": "right", "enemy": "gunner", "count": 4},
		{"time": 11.0, "spawner": "left", "enemy": "brute", "count": 2},
		{"time": 16.0, "spawner": "right", "enemy": "bomber", "count": 2}
	],
	9: [
		{"time": 0.0, "spawner": "left", "enemy": "gunner", "count": 4},
		{"time": 0.5, "spawner": "right", "enemy": "gunner", "count": 4},
		{"time": 1.0, "spawner": "left", "enemy": "bomber", "count": 4},
		{"time": 3.0, "spawner": "right", "enemy": "brute", "count": 3},
		{"time": 6.0, "spawner": "left", "enemy": "brute", "count": 2},
		{"time": 6.5, "spawner": "right", "enemy": "brute", "count": 2},
		{"time": 9.0, "spawner": "left", "enemy": "gunner", "count": 5},
		{"time": 13.0, "spawner": "right", "enemy": "bomber", "count": 3},
		{"time": 18.0, "spawner": "left", "enemy": "brute", "count": 1},
		{"time": 18.5, "spawner": "right", "enemy": "brute", "count": 1}
	],
	10: [
		{"time": 0.0, "spawner": "left", "enemy": "bomber", "count": 4},
		{"time": 0.5, "spawner": "right", "enemy": "bomber", "count": 4},
		{"time": 1.5, "spawner": "left", "enemy": "gunner", "count": 6},
		{"time": 2.0, "spawner": "right", "enemy": "gunner", "count": 6},
		{"time": 4.0, "spawner": "left", "enemy": "brute", "count": 3},
		{"time": 4.5, "spawner": "right", "enemy": "brute", "count": 3},
		{"time": 7.0, "spawner": "left", "enemy": "bomber", "count": 4},
		{"time": 10.0, "spawner": "right", "enemy": "brute", "count": 4},
		{"time": 14.0, "spawner": "left", "enemy": "gunner", "count": 5},
		{"time": 14.5, "spawner": "right", "enemy": "gunner", "count": 5},
		{"time": 18.0, "spawner": "left", "enemy": "brute", "count": 2},
		{"time": 22.0, "spawner": "right", "enemy": "bomber", "count": 3}
	]
}

func _ready() -> void:
	var shop = get_tree().get_nodes_in_group("shop")
	if shop.size() > 0:
		current_shop = shop[0]
		current_shop.shop_interaction_requested.connect(_on_shop_requested)
		print("Shop is setup")
	change_state(WaveState.COMBAT)

func enter_state(state: WaveState) -> void:
	match state:
		WaveState.COMBAT:
			current_wave_time = 0.0
			wave_events_completed.clear()
			if announce_label:
				announce_label.text = "Wave {0}".format([current_wave])
		WaveState.SHOP:
			if announce_label: 
				announce_label.text = "Shop".format([current_wave])
		WaveState.TRANSITION:
			if announce_label: 
				announce_label.text = "Wave {0} Complete!".format([current_wave])
			await get_tree().create_timer(3.0).timeout
			change_state(WaveState.SHOP)

func exit_state(state: WaveState) -> void:
	match state:
		WaveState.COMBAT:
			current_wave += 1
		WaveState.SHOP:
			stop_spawners()
		WaveState.TRANSITION:
			pass

func change_state(state: WaveState) -> void:
	exit_state(state)
	enter_state(state)
	current_wave_state = state

var wave_events_completed : Array[int] = []

func start_wave() -> void:
	wave_start_time = Time.get_ticks_msec()

func start_spawners() -> void:
	var spawners : Array[Node] = get_tree().get_nodes_in_group("spawner")
	for spawner in spawners:
		spawner.enabled = true
		
func stop_spawners() -> void:
	var spawners : Array[Node] = get_tree().get_nodes_in_group("spawner")
	for spawner in spawners:
		spawner.enabled = false

func get_total_enemies() -> int:
	return get_tree().get_nodes_in_group("enemy").size()

func set_player():
	player = get_tree().get_first_node_in_group("player")

func get_enemies_in_scene() -> Array[Node]:
	return get_tree().get_nodes_in_group("enemy")

func _process(delta: float) -> void:
	match current_wave_state:
		WaveState.COMBAT:
			check_wave_completion()
			current_wave_time += delta
			var current_timeline = wave_timelines[current_wave]
			for i in range(current_timeline.size()):
				var event = current_timeline[i]

				if current_wave_time >= event["time"] and not i in wave_events_completed:
					execute_spawn_event(event)
					wave_events_completed.append(i)
		WaveState.SHOP:
			shop_timer -= delta
			if shop_timer <= 0:
				change_state(WaveState.COMBAT)
		WaveState.TRANSITION:
			pass

func is_wave_timeline_complete() -> bool:
	var total_events = wave_timelines[current_wave].size()
	return wave_events_completed.size() >= total_events

func check_wave_completion() -> void:
	if is_wave_timeline_complete() and get_total_enemies() == 0:
		change_state(WaveState.TRANSITION)

func execute_spawn_event(event: Dictionary) -> void:
	var spawner = get_spawner_by_id(event.spawner)
	if spawner:
		spawner.spawn_enemies(event.enemy, event.count)

func get_spawner_by_id(id: String) -> Node:
	var spawners = get_tree().get_nodes_in_group("spawner")
	for spawner in spawners:
		if spawner.spawn_id == id:
			return spawner

	return null

func _on_shop_requested(shop: Shop) -> void:
	if current_wave_state != WaveState.SHOP:
		return
	
	shop_menu.setup_shop(shop)
	shop_menu.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

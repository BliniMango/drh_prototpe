extends Node3D

signal start_wave
signal stop_wave

var player: Player
var max_num_enemies = 20
var current_num_enemies = 0

func _ready() -> void:
	start_spawners()

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

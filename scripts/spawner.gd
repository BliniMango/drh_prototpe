extends Node3D

@export var entities : Array[PackedScene] = [Prefabs.GUNNER, Prefabs.DYNAMITE_BANDIT, Prefabs.BRUTE]

var next_spawn_time : float = Time.get_ticks_msec()
var spawn_cooldown : float = 2000.0

var enabled : bool = false

func _ready() -> void:
	add_to_group("spawner")
	
func _process(_delta: float) -> void:
	if enabled and Time.get_ticks_msec() > next_spawn_time:
		next_spawn_time = Time.get_ticks_msec() + spawn_cooldown
		attempt_spawn()
	

func attempt_spawn() -> void:
	if GameManager.current_num_enemies < GameManager.max_num_enemies:
		var entity = entities.pick_random().instantiate()
		add_child(entity)
		entity.global_position = global_position
		GameManager.current_num_enemies += 1

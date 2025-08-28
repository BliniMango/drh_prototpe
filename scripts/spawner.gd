extends Node3D

@export var entities : Array[PackedScene] = [Prefabs.GUNNER, Prefabs.DYNAMITE_BANDIT, Prefabs.BRUTE]
@export var spawn_id : String = "left" # possible values in wave config in the game_manager.gd

var spawn_queue : Array = []
var spawn_rate : float = 1.0
var spawn_timer : float = 0.0

var enabled : bool = false

func _ready() -> void:
	add_to_group("spawner")
	
func _process(delta: float) -> void:
	if spawn_queue.size() > 0:
		spawn_timer += delta
		if spawn_timer >= spawn_rate:
			spawn_next_enemy()
			spawn_timer = 0

	

func attempt_spawn() -> void:
	if GameManager.current_num_enemies < GameManager.max_num_enemies:
		var entity = entities.pick_random().instantiate()
		add_child(entity)
		entity.global_position = global_position
		GameManager.current_num_enemies += 1

func spawn_next_enemy() -> void:
	if spawn_queue.size() == 0:
		return

	var enemy = spawn_queue.pop_front()
	var enemy_prefab: PackedScene
	match enemy:
		"gunner":
			enemy_prefab = Prefabs.GUNNER
		"brute":
			enemy_prefab = Prefabs.BRUTE
		"bomber":
			enemy_prefab = Prefabs.DYNAMITE_BANDIT
	
	if enemy_prefab:
		var e = enemy_prefab.instantiate()
		add_child(e)
		e.global_position = global_position
		GameManager.current_num_enemies += 1

func spawn_enemies(enemy: String, count: int) -> void:
	for i in count:
		spawn_queue.append(enemy)

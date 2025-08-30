extends Node3D

@export var entities : Array[PackedScene] = [Prefabs.GUNNER, Prefabs.DYNAMITE_BANDIT, Prefabs.BRUTE]
@export var spawn_id : String = "left"
@export var spawn_radius : float = 8.0

var spawn_queue : Array = []
var spawn_rate : float = 1.0
var spawn_timer : float = 0.0

var enabled : bool = false
var is_spawning : bool = false

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("spawner")
	rng.randomize()

func _process(delta: float) -> void:
	if spawn_queue.size() == 0 and is_spawning:
		is_spawning = false
	if not enabled:
		return
	if spawn_queue.size() > 0:
		spawn_timer += delta
		if spawn_timer >= spawn_rate:
			spawn_next_enemy()
			spawn_timer = 0

func attempt_spawn() -> void:
	if GameManager.current_num_enemies < GameManager.max_num_enemies:
		var entity_scene = entities.pick_random()
		if entity_scene:
			var entity = entity_scene.instantiate()
			add_child(entity)
			entity.global_position = _random_point_in_radius()
			GameManager.current_num_enemies += 1

func spawn_next_enemy() -> void:
	if spawn_queue.size() == 0:
		is_spawning = false
		return
	var enemy = spawn_queue.pop_front()
	var enemy_prefab : PackedScene = null
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
		e.global_position = _random_point_in_radius()
		GameManager.current_num_enemies += 1

func spawn_enemies(enemy: String, count: int) -> void:
	for i in count:
		spawn_queue.append(enemy)
	is_spawning = true

func _random_point_in_radius() -> Vector3:
	var angle = rng.randf() * TAU
	var dist = sqrt(rng.randf()) * spawn_radius
	var offset = Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
	return global_position + offset

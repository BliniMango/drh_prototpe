extends Node3D

@onready var spawn_timer: Timer = $SpawnTimer

@export var entity_scene : PackedScene = Prefabs.ENEMY

func _ready() -> void:
	add_to_group("spawner")
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func attempt_spawn() -> void:
	if GameManager.current_num_enemies < GameManager.max_num_enemies:
		var entity = entity_scene.instantiate()
		add_child(entity)
		entity.global_position = global_position
		GameManager.current_num_enemies += 1

func start() -> void:
	spawn_timer.start()
	
func stop() -> void:
	spawn_timer.stop()

func _on_spawn_timer_timeout() -> void:
	attempt_spawn()

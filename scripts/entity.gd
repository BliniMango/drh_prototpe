class_name Entity
extends CharacterBody3D

@export var entity_sprite : Sprite3D

@export var speed = 5.0
@export var max_health = 100
@export var current_health = 100

var dash_decay_speed : float = 2.0
var max_dash_speed : float = 40.0
var dash_speed : float = max_dash_speed
var next_dash_time : float = Time.get_ticks_msec()
var dash_cooldown : float = 1000.0
var dash_direction : Vector3 = Vector3.ZERO

var is_dead : bool = false
var spawn_position : Vector3

func _ready() -> void:
	spawn_position = global_position

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	move_and_slide()

func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_health -= amount
	current_health = max(0, current_health)
	
	if current_health <= 0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector3.ZERO

func _reset_sprite():
	pass  # Override in child classes

func respawn():
	queue_free()
	# leaving this stuff here in case we need to do object pooling
	global_position = spawn_position
	current_health = max_health
	is_dead = false
	_reset_sprite()

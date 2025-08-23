class_name Enemy
extends CharacterBody3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hurt_box: Area3D = $HurtBox
@onready var sprite_3d: Sprite3D = $Sprite3D

var current_health : float = max_health
var is_dead : bool = false
var max_health : float = 100.0
var speed : float = 1.0
var spawn_position

signal enemy_died

func _ready() -> void:
	add_to_group("enemy")
	spawn_position = global_position

func _physics_process(_delta: float) -> void:
	if not is_dead:
		if GameManager.player != null:
			var dir = global_position.direction_to(GameManager.player.global_position)
			velocity = dir * speed
		
		if velocity.length() > 0:
			animation_player.play("walk")
	move_and_slide()

func take_damage(amount: float):
	current_health -= amount
	print("Enemy Health: {0}/{1}".format([current_health, max_health]))
	if current_health <= 0:
		die()
	
func die():
	if is_dead:
		return
	is_dead = true
	enemy_died.emit()
	animation_player.play("die")

func respawn():
	current_health = max_health
	is_dead = false
	sprite_3d.modulate.a = 1.0
	global_position = spawn_position
	

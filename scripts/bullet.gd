class_name Bullet
extends RigidBody3D

@onready var hit_box: Area3D = $HitBox

var damage : float = 10.0
var knockback_force : float = 3.0
var shooter : Node = null
var target_group : String = ""
var speed : float = 8.0
var dir : Vector3 = Vector3.ZERO

func _ready() -> void:
	add_to_group("bullet")
		
	if shooter and shooter.is_in_group("player"):
		target_group = "enemy"
		hit_box.collision_mask = 32
	elif shooter and shooter.is_in_group("enemy"):
		target_group = "player"
		hit_box.collision_mask = 8

	hit_box.area_entered.connect(_on_area_entered)

func _physics_process(_delta: float) -> void:
	linear_velocity = speed * dir
	
# on impact effects
func _on_area_entered(area: Area3D) -> void:
	var entity = area.get_parent()
	entity.take_damage(damage)
	queue_free()

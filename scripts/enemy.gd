class_name Enemy
extends Entity

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hit_box: Area3D = $HitBox


signal enemy_died

func _ready() -> void:
	super._ready()
	add_to_group("enemy")

func _physics_process(delta: float) -> void:
	if not is_dead:
		if GameManager.player != null:
			var dir = global_position.direction_to(GameManager.player.global_position)
			velocity = dir * speed
		
		if velocity.length() > 0:
			animation_player.play("walk")
	
	super._physics_process(delta)
	
func die() -> void:
	super.die()
	animation_player.play("die")
	GameManager.current_num_enemies -= 1
	

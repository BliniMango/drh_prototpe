class_name Brute
extends Entity

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var dash_range : float = 7.0

func _ready() -> void:
	super._ready()
	add_to_group("enemy")
	dash_cooldown = 5000.0 # 5 seconds

func _physics_process(_delta: float) -> void:
	var player_vec =GameManager.player.global_position - global_position
	var direction = player_vec.normalized()
	if dash_range > player_vec.length() and next_dash_time < Time.get_ticks_msec():
		dash_speed = max_dash_speed
		dash_direction = direction
		next_dash_time = Time.get_ticks_msec() + dash_cooldown
	
	if dash_speed > 0:
		velocity.x = dash_direction.x * dash_speed
		velocity.z = dash_direction.z * dash_speed
		dash_speed -= dash_decay_speed
	else:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	
	super._physics_process(_delta)

func die() -> void:
	super.die()
	animation_player.play("die")
	GameManager.current_num_enemies -= 1

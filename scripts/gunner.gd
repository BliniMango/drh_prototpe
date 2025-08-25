class_name Gunner
extends Entity

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var dash_range : float = 7.0
var current_state : State
var windup_time = 1.5
enum State { APPROACH, WINDUP, DASH, EXHAUSTED }

func _ready() -> void:
	super._ready()
	add_to_group("enemy")
	dash_cooldown = 5000.0 # 5 seconds
	enter_state(State.APPROACH)

func _physics_process(_delta: float) -> void:
	if not is_dead:
		match current_state:
			State.APPROACH: handle_approach()
			State.WINDUP: handle_windup()
			State.DASH: handle_dash()
			State.EXHAUSTED: handle_exhausted()
	
	super._physics_process(_delta)

func die() -> void:
	super.die()
	animation_player.play("die")
	GameManager.current_num_enemies -= 1

# state machine
func change_state(new_state: State) -> void:
	if not is_dead:
		exit_state(current_state)
		current_state = new_state
		enter_state(new_state)

func exit_state(state: State) -> void: # cleanup
	match state:
		State.APPROACH: 
			animation_player.stop()
		State.DASH: dash_speed = 0.0
		
func enter_state(state: State) -> void: # setup
	#print("Entering {0} State".format([state]))
	match state:
		State.APPROACH: 
			animation_player.play("walk")
		State.WINDUP: 
			animation_player.play("windup")
			velocity = Vector3.ZERO
			await get_tree().create_timer(windup_time).timeout
			change_state(State.DASH)
		State.DASH:
			animation_player.play("dash")
			var player_vec = GameManager.player.global_position - global_position
			var direction = player_vec.normalized()
			dash_speed = max_dash_speed
			dash_direction = direction
			next_dash_time = Time.get_ticks_msec() + dash_cooldown
		State.EXHAUSTED: 
			animation_player.play("exhausted")
			velocity = Vector3.ZERO
			await get_tree().create_timer(windup_time).timeout
			change_state(State.APPROACH)
		
func handle_approach() -> void:
	if GameManager.player == null:
		printerr("[brute.gd] player is null")
		return
	var player_vec = GameManager.player.global_position - global_position
	var direction = player_vec.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if dash_range > player_vec.length() and next_dash_time < Time.get_ticks_msec():
		change_state(State.WINDUP)
		
func handle_windup() -> void:
	pass # handled in enter state setup once

func handle_dash() -> void:
	if dash_speed > 0:
		velocity.x = dash_direction.x * dash_speed
		velocity.z = dash_direction.z * dash_speed
		dash_speed -= dash_decay_speed
	else:
		change_state(State.EXHAUSTED)

func handle_exhausted() -> void:
	pass # handled in enter state setup once
	

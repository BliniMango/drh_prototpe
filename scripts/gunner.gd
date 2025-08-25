class_name Gunner
extends Entity

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hit_box: Area3D = $HitBox

var shoot_range : float = 7.0
var current_state : State
var aim_time = 1.5
var reload_time = 1.5
enum State { APPROACH, AIM, SHOOT, RELOAD }

func _ready() -> void:
	super._ready()
	add_to_group("enemy")
	hit_box.add_to_group("gunner")

	dash_cooldown = 5000.0 # 5 seconds
	enter_state(State.APPROACH)

func _physics_process(_delta: float) -> void:
	if not is_dead:
		match current_state:
			State.APPROACH: handle_approach()
			State.AIM: handle_aim()
			State.SHOOT: handle_shoot()
			State.RELOAD: handle_reload()
	
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
			pass
		State.AIM:
			pass
		State.SHOOT: 
			pass
		State.RELOAD:
			pass
		
func enter_state(state: State) -> void: # setup
	#print("Entering {0} State".format([state]))
	match state:
		State.APPROACH: 
			animation_player.play("walk")
		State.AIM: 
			velocity = Vector3.ZERO
			await get_tree().create_timer(aim_time).timeout
			change_state(State.SHOOT)
		State.SHOOT:
			pass
		State.RELOAD: 
			velocity = Vector3.ZERO
			await get_tree().create_timer(reload_time).timeout
			change_state(State.APPROACH)
		
func handle_approach() -> void:
	if GameManager.player == null:
		printerr("[brute.gd] player is null")
		return
	var player_vec = GameManager.player.global_position - global_position
	var direction = player_vec.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if shoot_range > player_vec.length():
		change_state(State.AIM)
		
func handle_aim() -> void:
	pass # handled in enter state setup once

func handle_shoot() -> void:
	pass # TODO

func handle_reload() -> void:
	pass # handled in enter state setup once
	

class_name Gunner
extends Entity

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hit_box: Area3D = $HitBox
@onready var muzzle: Marker3D = $Muzzle

var shoot_range : float = 18.0
var current_state : State
var aim_time = 1.5
var reload_time = 1.5

var shoot_cooldown : float = 5000.0 # milisecond
var next_shoot_time : float = Time.get_ticks_msec()
enum State { APPROACH, SHOOT }

func _ready() -> void:
	super._ready()
	super.setup_nav_agent()
	add_to_group("enemy")
	hit_box.add_to_group("gunner")
	enter_state(State.APPROACH)

func _physics_process(delta: float) -> void:
	if not is_dead:
		super.update_sprite_direction()
		match current_state:
			State.APPROACH: handle_approach(delta)
			State.SHOOT: handle_shoot()
	
	super._physics_process(delta)

func die() -> void:
	super.die()
	animation_player.play("die")
	GameManager.current_num_enemies -= 1
	SFXManager.play_spatial_sfx(SFXManager.Type.GUNNER_DIE, global_position)
	if randf() < .3:
		var pickup : Pickup = Prefabs.PICKUP.instantiate()
		pickup.set_pickup_type(Pickup.Type.AMMO)
		pickup.global_position = global_position
		get_tree().current_scene.add_child(pickup)
	super.create_death_effect()

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
		State.SHOOT: 
			pass
		
func enter_state(state: State) -> void: # setup
	#print("Entering {0} State".format([state]))
	match state:
		State.APPROACH: 
			animation_player.play("walk")
		State.SHOOT: 
			velocity = Vector3.ZERO
			animation_player.play("idle")
		
func handle_approach(delta) -> void:
	update_target()

	if current_target == null:
		return

	var target_vec = current_target.global_position - global_position
	super.move_forward_and_rotate_toward_player(delta, target_vec)

	if shoot_range > target_vec.length():
		change_state(State.SHOOT)
		
func handle_shoot() -> void:
	update_target()

	if current_target == null:
		change_state(State.APPROACH)
		return

	var target_vec = current_target.global_position - global_position

	var direction = target_vec.normalized()
	var target_angle = atan2(direction.x, direction.z)
	rotation.y = target_angle

	if shoot_range <= target_vec.length():
		change_state(State.APPROACH)
		return

	if Time.get_ticks_msec() > next_shoot_time:
		animation_player.play("attack")
	else:
		animation_player.play("idle")
	
func shoot() -> void:
	SFXManager.play_spatial_sfx(SFXManager.Type.GUNNER_SHOOT, global_position)
	var bullet = Prefabs.BULLET.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.shooter = self
	var bullet_dir : Vector3 = current_target.global_position - muzzle.global_position
	bullet.dir = Vector3(bullet_dir.x, 0.0, bullet_dir.z)
	get_tree().current_scene.add_child(bullet)
	next_shoot_time = Time.get_ticks_msec() + shoot_cooldown

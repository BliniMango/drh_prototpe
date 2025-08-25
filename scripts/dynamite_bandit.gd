class_name DynamiteBandit
extends Entity

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hit_box: Area3D = $HitBox
@onready var muzzle: Marker3D = $Muzzle

var suicide_range = abs(throw_range - 10.0)
var current_state : State

enum State { APPROACH, THROW, SUICIDE_CHARGE, EXPLODE }

func _ready() -> void:
	super._ready()
	add_to_group("enemy")
	hit_box.add_to_group("bomber")
	dash_cooldown = 5000.0 # 5 seconds
	enter_state(State.APPROACH)

func _physics_process(_delta: float) -> void:
	if not is_dead:
		match current_state:
			State.APPROACH: handle_approach()
			State.THROW: handle_throw()
			State.SUICIDE_CHARGE: handle_suicide_charge()
			State.EXPLODE: handle_explode()
	
	super._physics_process(_delta)

func die() -> void:
	super.die()
	animation_player.play("die")
	GameManager.current_num_enemies -= 1

func throw_dynamite() -> void:
	if GameManager.player == null:
		printerr("[dynamite_bandit.gd] player is null")
		return

	var target = GameManager.player.global_position
	var start  = muzzle.global_position
	var to     = target - start
	var dxz    = Vector3(to.x, 0, to.z)
	var dist   = dxz.length()

	var g = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))

	var base_speed      = 10.0
	var arc_multiplier  = 1.5          # 0 = flattest, higher = more arc
	var T = (dist / base_speed) * (1.0 + arc_multiplier)

	var vxz = dxz / T
	var vy  = (to.y + 0.5 * g * T * T) / T   # solves y(T) = to.y under gravity

	var dynamite = Prefabs.DYNAMITE.instantiate()
	dynamite.global_position = start
	dynamite.linear_velocity = vxz + Vector3(0, vy, 0)
	dynamite.thrower = self
	dynamite.fuse_duration = T
	get_tree().current_scene.add_child(dynamite)
	next_throw_time = Time.get_ticks_msec() + throw_cooldown

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
		State.SUICIDE_CHARGE: dash_speed = 0.0
		
func enter_state(state: State) -> void: # setup
	#print("Entering {0} State".format([state]))
	match state:
		State.APPROACH: 
			animation_player.play("walk")
		State.THROW: 
			#animation_player.play("throw") # maybe keyframe animation to spawn a projectile to throw at the player?
			velocity = Vector3.ZERO
		State.SUICIDE_CHARGE:
			#animation_player.play("dash")
			pass
		State.EXPLODE: 
			#animation_player.play("exhausted")
			velocity = Vector3.ZERO
			# spawn an instant dynamite and blow it 
			var d = Prefabs.DYNAMITE.instantiate()
			d.global_position = muzzle.global_position
			d.thrower = self
			d.fuse_duration = 1.0
			d.kill_thrower_on_explode = true
			get_tree().current_scene.add_child(d)

		
func handle_approach() -> void:
	if GameManager.player == null:
		printerr("[dynamite_bandit.gd] player is null")
		return
	var player_vec = GameManager.player.global_position - global_position
	var direction = player_vec.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if throw_range > player_vec.length():
		change_state(State.THROW)
		
func handle_throw() -> void:
	if GameManager.player == null:
		printerr("[dynamite_bandit.gd] player is null")
		return
	var player_vec = GameManager.player.global_position - global_position
	var direction = player_vec.normalized()
	
	if player_vec.length() <= suicide_range:
		change_state(State.SUICIDE_CHARGE)
		return
		
	if throw_range > player_vec.length():
		if next_throw_time < Time.get_ticks_msec():
			throw_dynamite()
	else:
		change_state(State.APPROACH)
	
func handle_suicide_charge() -> void:
	if GameManager.player == null:
		change_state(State.EXPLODE)
		return

	var player_vec = GameManager.player.global_position - global_position
	var direction = player_vec.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	# explode when close
	if player_vec.length() <= suicide_range:
		change_state(State.EXPLODE)

func handle_explode() -> void:
	pass

class_name Brute
extends Entity

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hit_box: Area3D = $HitBox

var dash_range : float = 7.0
var current_state : State
var windup_time = 1.5
enum State { APPROACH, WINDUP, DASH, EXHAUSTED }

func _ready() -> void:
	super._ready()
	# Randomize strength
	var is_strong = randf() < 0.15 # 15% chance to be strong
	if is_strong:
		max_health = int(max_health * randf_range(1.5, 2.2))
		current_health = max_health
		damage = int(damage * randf_range(1.3, 1.7))
		speed *= randf_range(1.1, 1.3)
		# Color modulation for strong enemies
		if entity_sprite:
			entity_sprite.modulate = Color(1.0, randf_range(0.2, 0.5), randf_range(0.2, 0.5))
		var scale_factor = randf_range(1.2, 1.5)
		scale = Vector3.ONE * scale_factor
	else:
		# Slight randomization for normal enemies
		max_health = int(max_health * randf_range(0.9, 1.1))
		current_health = max_health
		damage = int(damage * randf_range(0.9, 1.1))
		speed *= randf_range(0.95, 1.05)
	super.setup_nav_agent()
	add_to_group("enemy")
	hit_box.add_to_group("brute")
	dash_cooldown = 5000.0 # 5 seconds
	enter_state(State.APPROACH)
	damage = 12

func _physics_process(delta: float) -> void:
	if not is_dead:
		super.update_sprite_direction()
		match current_state:
			State.APPROACH: handle_approach(delta)
			State.WINDUP: handle_windup()
			State.DASH: handle_dash()
			State.EXHAUSTED: handle_exhausted()
	
	super._physics_process(delta)

func die() -> void:
	super.die()
	animation_player.play("die")
	GameManager.current_num_enemies -= 1

	SFXManager.play_spatial_sfx(SFXManager.Type.BRUTE_DIE, global_position)
	if randf() < .2:
		var pickup : Pickup = Prefabs.PICKUP.instantiate()
		pickup.set_pickup_type(Pickup.Type.HEALTH)
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
			animation_player.stop()
		State.DASH: dash_speed = 0.0
		
func enter_state(state: State) -> void: # setup
	#print("Entering {0} State".format([state]))
	match state:
		State.APPROACH: 
			animation_player.play("walk")
		State.WINDUP: 
			animation_player.play("idle")
			velocity = Vector3.ZERO
			await get_tree().create_timer(windup_time).timeout
			change_state(State.DASH)
		State.DASH:
			animation_player.play("attack")
			var player_vec = GameManager.player.global_position - global_position
			var direction = player_vec.normalized()
			dash_speed = max_dash_speed
			dash_direction = direction
			next_dash_time = Time.get_ticks_msec() + dash_cooldown
			SFXManager.play_spatial_sfx(SFXManager.Type.BRUTE_ATTACK, global_position)
		State.EXHAUSTED: 
			animation_player.play("idle")
			velocity = Vector3.ZERO
			await get_tree().create_timer(windup_time).timeout
			change_state(State.APPROACH)
		
func handle_approach(delta: float) -> void:
	update_target()

	if current_target == null:
		return

	var target_vec = current_target.global_position - global_position

	super.move_forward_and_rotate_toward_player(delta, target_vec)

	if current_target == GameManager.player and dash_range > target_vec.length() and next_dash_time < Time.get_ticks_msec():
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
	

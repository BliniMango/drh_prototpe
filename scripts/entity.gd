class_name Entity
extends CharacterBody3D

@export var bank_target_distance : float = 8.0
@export var entity_sprite : Sprite3D
@export var front_texture : Texture2D
@export var back_texture : Texture2D
@export var side_texture : Texture2D

@export var speed = 5.0

@export var max_health = 100
@export var current_health = 100
@export var damage = 10.0 # collision damage

var current_target : Node3D
var bank_ref : Bank
var sprite_locked : bool = false

# dash
var dash_decay_speed : float = 2.0
var max_dash_speed : float = 40.0
var dash_speed : float = 0.0
var next_dash_time : float = Time.get_ticks_msec()
var dash_cooldown : float = 1000.0 # miliseconds
var dash_direction : Vector3 = Vector3.ZERO

# throwable
var throwable_inventory : Array[PackedScene]
var throw_cooldown : float = 5000.0 # miliseconds
var next_throw_time : float = Time.get_ticks_msec()
var throw_range : float = 17.0

# knockback
var knockback_velocity : Vector3 = Vector3.ZERO
var knockback_decay : float = 50.0
var knockback_force : float = 25.0
var is_stunned : bool = false
var stun_duration : float = 0.0

var is_dead : bool = false
var spawn_position : Vector3

var nav_agent : NavigationAgent3D = null

func _ready() -> void:
	spawn_position = global_position

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
		
	if knockback_velocity.length() > 0:
		velocity += knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, knockback_decay * delta)
		#print_debug("knockback_velocity {0}".format([knockback_velocity.length()]))
	move_and_slide()

func heal(amount: float) -> void:
	current_health = clamp(amount + max_health, 0, max_health)

func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_health -= amount
	current_health = max(0, current_health)
	flash_red()
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

func create_death_effect():
	set_collision_layer(0)
	set_collision_mask(0)

	var bounce_direction = Vector3(1, 1, 0).normalized()
	velocity = bounce_direction + Vector3(0, 3, 0)

	var tween = create_tween()
	tween.tween_property(entity_sprite, "modulate:a", 0.0, .8)
	tween.tween_callback(queue_free)

func flash_red() -> void:
	if entity_sprite == null:
		return

	var original_color = entity_sprite.modulate

	entity_sprite.modulate = Color.RED
	
	var tween = create_tween()
	tween.tween_property(entity_sprite, "modulate", original_color, 0.2)

func update_sprite_direction() -> void:
	if GameManager.player == null or entity_sprite == null:
		return

	var enemy_fwd: Vector3  = (-global_transform.basis.z).normalized()
	var enemy_right: Vector3 = (global_transform.basis.x).normalized()
	var to_player: Vector3 = (GameManager.player.global_position - global_position)
	to_player.y = 0.0
	if to_player.length_squared() == 0.0:
		return
	to_player = to_player.normalized()

	const FRONT_COS := cos(deg_to_rad(45.0))  # within 45° = "front"
	const BACK_COS  := cos(deg_to_rad(135.0)) # beyond 135° = "back"

	var facing_dot := enemy_fwd.dot(to_player)  # 1 = looking straight at player, -1 = away

	if facing_dot >= FRONT_COS:
		entity_sprite.texture = back_texture
	elif facing_dot <= -FRONT_COS:
		entity_sprite.texture = front_texture
	else:
		entity_sprite.texture = side_texture

	var side_dot := enemy_right.dot(to_player)

	entity_sprite.flip_h = (side_dot > 0.0) 

func move_forward_and_rotate_toward_player(delta: float, player_vec: Vector3):
	if nav_agent != null and current_target != null:
		var target_pos = current_target.global_position
		if current_target.is_in_group("bank"):
			var bank_radius = 3.0  # Adjust to match your bank's size
			var angle = randf() * TAU
			var r = sqrt(randf()) * bank_radius
			var offset = Vector3(cos(angle), 0, sin(angle)) * r
			target_pos += offset
		nav_agent.target_position = target_pos

		var next_position = nav_agent.get_next_path_position()
		var direction = (next_position - global_position).normalized()
		var target_angle = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 3.0 * delta)

		var forward = global_transform.basis.z
		velocity.x = forward.x * speed
		velocity.z = forward.z * speed
	else:
		var direction = player_vec.normalized()
		var target_angle = atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 3.0 * delta)

		var forward = global_transform.basis.z
		velocity.x = forward.x * speed
		velocity.z = forward.z * speed

func setup_nav_agent():
	nav_agent = NavigationAgent3D.new()
	nav_agent.radius = 0.5
	nav_agent.path_desired_distance = 0.5
	add_child(nav_agent)

func update_target() -> void:
	if not bank_ref and GameManager:
		bank_ref = GameManager.get_bank()
	
	if not bank_ref or bank_ref.is_destroyed:
		current_target = GameManager.player
		return
	
	if not GameManager.player:
		current_target = bank_ref
		return

	var distance_to_player = global_position.distance_to(GameManager.player.global_position)

	if distance_to_player <= bank_target_distance:
		current_target = GameManager.player
	else:
		current_target = bank_ref

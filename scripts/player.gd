class_name Player
extends CharacterBody3D

signal player_died

@export var speed = 5.0
@export var mouse_sensitivity = 0.002
@export var max_health = 100
@export var current_health = 100

@onready var camera = $Camera3D
@onready var health_bar = $UICanvas/HealthBar
@onready var shoot_anim = $UICanvas/ShootAnim
@onready var crosshair = $UICanvas/Crosshair

var dash_decay_speed : float = 2.0
var max_dash_speed : float = 40.0
var dash_speed : float = max_dash_speed
var next_dash_time : float = Time.get_ticks_msec()
var dash_cooldown : float = 1000.0
var dash_direction : Vector3 = Vector3.ZERO

var fire_rate : float = 5.0
var is_dead : bool = false
var shoot_cone_threshold : float = deg_to_rad(3)
var shoot_timer : float = 0.0

func _ready():
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	update_health_ui()
	GameManager.set_player() # player needs to be accessible to enemies
	#crosshair.position = Vector2(
		#get_viewport().size.x / 2 - crosshair.size.x / 2,
		#get_viewport().size.y / 2 - crosshair.size.y / 2
	#)

func _input(event):
	if is_dead:
		return
	# mouse perspective
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity) #rotate horz
		
		camera.rotate_x(-event.relative.y * mouse_sensitivity) #rotate vert
		camera.rotation.x = clamp(camera.rotation.y, -PI/2, PI/2)
		
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 

func _physics_process(delta):
	if is_dead:
		return
	
	var input_dir = Vector2.ZERO
	if dash_speed == 0:
		# only update input_dir and dash_direction if not dashing
		if Input.is_action_pressed("move_left"):
			input_dir.x -= 1
		if Input.is_action_pressed("move_right"):
			input_dir.x += 1
		if Input.is_action_pressed("move_foward"):
			input_dir.y -= 1
		if Input.is_action_pressed("move_backward"):
			input_dir.y += 1

		if Input.is_action_just_pressed("dash") and input_dir.length() > 0 and next_dash_time < Time.get_ticks_msec():
			if input_dir.x == -1:
				dash_direction = -transform.basis.x
			elif input_dir.x == 1:
				dash_direction = transform.basis.x
			elif input_dir.y == -1:
				dash_direction = -transform.basis.z
			elif input_dir.y == 1:
				dash_direction = transform.basis.z
			dash_speed = max_dash_speed
			next_dash_time = Time.get_ticks_msec() + dash_cooldown

		# normal movement
		var direction = Vector3.ZERO
		if input_dir != Vector2.ZERO:
			direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		# lock movement while dashing
		velocity.x = dash_direction.x * dash_speed
		velocity.z = dash_direction.z * dash_speed

	if dash_speed > 0:
		dash_speed -= dash_decay_speed
		if dash_speed <= 0:
			dash_speed = 0

	if not is_on_floor():
		velocity.y += get_gravity().y * delta

	move_and_slide()
	
func _process(delta):
	if shoot_anim.animation == "shoot" and !shoot_anim.is_playing():
		shoot_anim.play("idle")
		
	if Input.is_action_pressed("shoot"):  # mouse held
		shoot_timer += delta
		if shoot_timer >= (1.0 / fire_rate):
			shoot()
			shoot_timer = 0.0
			

func shoot():
	if shoot_anim.animation != "shoot":
		shoot_anim.play("shoot")
		
	var camera_forward : Vector3 = -camera.global_transform.basis.z
	var enemies : Array[Node] = GameManager.get_enemies_in_scene()
	
	var closest_enemy : Enemy = null
	var smallest_distance : float = INF
	for enemy in enemies:
		var distance : Vector3 = enemy.global_position - global_position
		var enemy_dir : Vector3 = distance.normalized()
		var angle : float = camera_forward.angle_to(enemy_dir)
		
		if angle < shoot_cone_threshold:
			if distance.length() < smallest_distance:
				closest_enemy = enemy
				smallest_distance = distance.length()
	
	if closest_enemy != null:
		print("Shot {0}".format([closest_enemy]))
		closest_enemy.take_damage(50.0)

func take_damage(amount: int):
	if is_dead:
		return
	current_health -= amount
	current_health = max(0, current_health)
	update_health_ui()
	
	if current_health <= 0:
		die()

func update_health_ui():
	if health_bar:
		health_bar.value = current_health

func die():
	if is_dead:
		return
	is_dead = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	player_died.emit()

func respawn():
	current_health = max_health
	is_dead = false
	update_health_ui()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

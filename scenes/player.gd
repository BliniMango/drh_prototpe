# player
extends CharacterBody3D

@export var speed = 5.0
@export var mouse_sensitivity = 0.002
@export var max_health = 100
@export var current_health = 100

@onready var camera = $Camera3D
@onready var health_bar = $UICanvas/HealthBar
@onready var shoot_anim = $UICanvas/ShootAnim
@onready var crosshair = $UICanvas/Crosshair


#var velocity = Vector3.ZERO

var is_dead = false

signal player_died

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	update_health_ui()
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
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		shoot()

func _physics_process(delta):
	if is_dead:
		return
	
	var input_dir = Vector2.ZERO
	
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("move_foward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1
		
	var direction = Vector3.ZERO
	if input_dir != Vector2.ZERO:
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
		
	move_and_slide()
	
func _process(delta):
	if shoot_anim.animation == "shoot" and !shoot_anim.is_playing():
		shoot_anim.play("idle")
	
func shoot():
	if shoot_anim.animation != "shoot":
		shoot_anim.play("shoot")

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

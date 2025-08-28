class_name Player
extends Entity

signal player_died

@export var mouse_sensitivity = 0.002
@export var revolver : Weapon
@export var shotgun : Weapon

@onready var camera = $Camera3D
@onready var crosshair = $UICanvas/Crosshair
@onready var health_bar = $UICanvas/HUDRoot/HBoxContainer/VBoxContainer/HealthBar
@onready var ammo_bar = $UICanvas/HUDRoot/HBoxContainer/VBoxContainer2/AmmoBar
@onready var hurt_box: Area3D = $HurtBox
@onready var muzzle: Marker3D = $Muzzle
@onready var shoot_anim = $UICanvas/ShootAnim

var dash_input_pressed : bool = false
var movement_input : Vector2 = Vector2.ZERO
var money : float = 0.0
var fire_rate : float = 2.0
var shoot_cone_threshold : float = deg_to_rad(5.6)
var shoot_timer : float = 0.0
var current_weapon : Weapon
var is_reloading : bool = false
var reload_timer : float = 0.0

# weapon sway and recoil and bobbing
var _base_ui_pos := Vector2.ZERO
var _yaw_prev := 0.0
var bob_amt := Vector2(3, 5)
var bob_speed := 5.0
var _bob_t := 0.0
var sway_amt_x := 8.0        
var sway_lerp := 12.0
var _sway_x := 0.0
var recoil_kick := Vector2(0, 16)  
var recoil_recover := 14.0
var _recoil := Vector2.ZERO


func _ready() -> void:
	super._ready()
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	revolver = Weapon.create_revolver()
	shotgun = Weapon.create_shotgun()
	current_weapon = revolver


	apply_weapon_anim()                 
	_base_ui_pos = shoot_anim.position  
	_yaw_prev = rotation.y
	
	update_health_ui()
	GameManager.set_player() # player needs to be accessible to enemies
	#crosshair.position = Vector2(
		#get_viewport().size.x / 2 - crosshair.size.x / 2,
		#get_viewport().size.y / 2 - crosshair.size.y / 2
	#)
	hurt_box.area_entered.connect(_on_hurt_box_entered)

func _input(event) -> void:
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

func _physics_process(delta) -> void:
	if is_dead:
		return
	
	if dash_speed == 0:
		if Input.is_action_just_pressed("dash") and movement_input.length() > 0 and next_dash_time < Time.get_ticks_msec():
			if movement_input.x == -1:
				dash_direction = -transform.basis.x
			elif movement_input.x == 1:
				dash_direction = transform.basis.x
			elif movement_input.y == -1:
				dash_direction = -transform.basis.z
			elif movement_input.y == 1:
				dash_direction = transform.basis.z
			SFXManager.play_player_sfx(SFXManager.Type.PLAYER_DASH)
			dash_speed = max_dash_speed
			next_dash_time = Time.get_ticks_msec() + dash_cooldown

		# normal movement
		var direction = Vector3.ZERO
		if movement_input != Vector2.ZERO:
			direction = (transform.basis * Vector3(movement_input.x, 0, movement_input.y)).normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		# lock movement while dashing
		velocity.x = dash_direction.x * dash_speed
		velocity.z = dash_direction.z * dash_speed

	dash_input_pressed = false

	if dash_speed > 0:
		dash_speed -= dash_decay_speed
		if dash_speed <= 0:
			dash_speed = 0

	super._physics_process(delta)
	
func _process(delta) -> void:
	if is_stunned:
		stun_duration -= delta
		if stun_duration <= 0:
			is_stunned = false
		dash_input_pressed = false
		movement_input = Vector2.ZERO
		return

	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0:
			current_weapon.reload()
			is_reloading = false
			update_ammo_ui()

	movement_input = Vector2.ZERO
	# only update input_dir and dash_direction if not dashing
	if Input.is_action_pressed("move_left"):
		movement_input.x -= 1
	if Input.is_action_pressed("move_right"):
		movement_input.x += 1
	if Input.is_action_pressed("move_foward"):
		movement_input.y -= 1
	if Input.is_action_pressed("move_backward"):
		movement_input.y += 1

	if shoot_anim.animation == "shoot" and !shoot_anim.is_playing():
		shoot_anim.play("idle")
		
	if Input.is_action_pressed("shoot") and not is_reloading:  # mouse held
		if current_weapon.current_ammo == 0:
			start_reload()
			return
		if Input.is_action_just_pressed("shoot"):
			shoot()
			shoot_timer = 0.0
		else:
			shoot_timer += delta
			if shoot_timer >= (1.0 / fire_rate):
				shoot()
				shoot_timer = 0.0
		
	if Input.is_action_just_pressed("weapon_1"):
		cancel_reload()
		current_weapon = revolver
		SFXManager.play_player_sfx(SFXManager.Type.PLAYER_WEAPON_SWAP)
		update_ammo_ui()
		apply_weapon_anim()
	elif Input.is_action_just_pressed("weapon_2"):
		cancel_reload()
		current_weapon = shotgun
		SFXManager.play_player_sfx(SFXManager.Type.PLAYER_WEAPON_SWAP)
		update_ammo_ui()
		apply_weapon_anim()

	if Input.is_action_just_pressed("reload"):
		start_reload()

	if throwable_inventory.size() > 0 and Input.is_action_just_pressed("throw"):
		var throwable : PackedScene = throwable_inventory.pop_back()
		var dynamite = throwable.instantiate()
		var fwd = -camera.global_transform.basis.z
		var throw_dir = (fwd + Vector3.UP * .35).normalized()
		var throw_speed = 3.0
		dynamite.linear_velocity = throw_dir * throw_speed
		dynamite.linear_velocity += Vector3(velocity.x , 0.0, velocity.z) * 0.4
		dynamite.global_position = muzzle.global_position + fwd
		dynamite.thrower = self
		dynamite.fuse_duration = 2.0
		dynamite.look_at(dynamite.global_position + throw_dir, Vector3.UP)

		get_tree().current_scene.add_child(dynamite)

	# weapon sway stuff
	var spd := Vector2(velocity.x, velocity.z).length()
	_bob_t += delta * (bob_speed * clamp(spd / max(1.0, speed), 0.0, 1.0))
	var bob := Vector2(sin(_bob_t) * bob_amt.x, abs(sin(_bob_t * 2.0)) * bob_amt.y)

	var yaw_now := rotation.y
	var yaw_delta := wrapf(yaw_now - _yaw_prev, -PI, PI)
	_yaw_prev = yaw_now
	_sway_x = lerp(_sway_x, -yaw_delta * sway_amt_x * 60.0, delta * sway_lerp) 

	_recoil = _recoil.lerp(Vector2.ZERO, delta * recoil_recover)

	shoot_anim.rotation = 0.0  
	shoot_anim.position = _base_ui_pos + Vector2(_sway_x, 0) + bob + _recoil

func apply_weapon_anim():
	if not current_weapon: return
	match current_weapon.weapon_type:
		Weapon.Type.REVOLVER:
			shoot_anim.play("pistol_idle")
		Weapon.Type.SHOTGUN:
			shoot_anim.play("double_barrel_idle")

func start_reload():
	if is_reloading:
		return
	if current_weapon and current_weapon.current_ammo < current_weapon.max_ammo:
		SFXManager.play_player_sfx(SFXManager.Type.PLAYER_RELOAD)
		is_reloading = true
		reload_timer = current_weapon.reload_time

func cancel_reload():
	if is_reloading:
		is_reloading = false
		reload_timer = 0.0
		SFXManager.stop_player_sfx(SFXManager.Type.PLAYER_RELOAD)

func shoot():
	if not current_weapon.can_shoot():
		return

	if shoot_anim.animation != "shoot":
		shoot_anim.play("shoot")

	var camera_forward : Vector3 = -camera.global_transform.basis.z
	var enemies : Array[Node] = GameManager.get_enemies_in_scene()
	
	# Different behavior for shotgun vs revolver
	if current_weapon.weapon_type == Weapon.Type.SHOTGUN:
		# Shotgun: wider cone, hits multiple enemies
		var shotgun_cone = deg_to_rad(20.0)  # Much wider cone for shotgun
		var hit_any_enemy = false
		
		for enemy in enemies:
			var distance_vec : Vector3 = enemy.global_position - global_position
			var enemy_dir : Vector3 = distance_vec.normalized()
			var angle : float = camera_forward.angle_to(enemy_dir)
			
			# Check if enemy is in front and within shotgun cone
			if angle < shotgun_cone and camera_forward.dot(enemy_dir) > 0:
				enemy.take_damage(calculate_damage(distance_vec.length()))
				hit_any_enemy = true
		
		if hit_any_enemy:
			SFXManager.play_player_sfx(SFXManager.Type.PLAYER_BULLET_HIT)
	else:
		# Revolver: narrow cone, hits closest enemy only
		var closest_enemy : Node = null
		var smallest_distance : float = INF
		
		for enemy in enemies:
			var distance_vec : Vector3 = enemy.global_position - global_position
			var enemy_dir : Vector3 = distance_vec.normalized()
			var angle : float = camera_forward.angle_to(enemy_dir)

			# Check if enemy is in front and within revolver cone
			if angle < shoot_cone_threshold and camera_forward.dot(enemy_dir) > 0:
				if distance_vec.length() < smallest_distance:
					closest_enemy = enemy
					smallest_distance = distance_vec.length()
		
		if closest_enemy != null:
			closest_enemy.take_damage(calculate_damage(smallest_distance))
			SFXManager.play_player_sfx(SFXManager.Type.PLAYER_BULLET_HIT)
	
	# weapon recoil
	if current_weapon.weapon_type == Weapon.Type.SHOTGUN:
		_recoil += recoil_kick * 1.3
	else:
		_recoil += recoil_kick

	current_weapon.shoot()
	update_ammo_ui()

func calculate_damage(distance: float) -> float:
	if distance > current_weapon.close_range:
		return current_weapon.damage_far
	else:
		return current_weapon.damage_close

func take_damage(amount: float) -> void:
	super.take_damage(amount)
	SFXManager.play_player_sfx(SFXManager.Type.PLAYER_HURT)
	update_health_ui()

func update_ammo_ui() -> void:
	if ammo_bar: 
		ammo_bar.max_value = current_weapon.max_ammo
		ammo_bar.value = current_weapon.current_ammo

		if current_weapon.current_ammo == 0:
			ammo_bar.modulate = Color.RED
		elif current_weapon.current_ammo <= 1:
			ammo_bar.modulate = Color.ORANGE
		else:
			ammo_bar.modulate = Color.WHITE
		

func update_health_ui() -> void:
	if health_bar:
		health_bar.value = current_health
		
func die() -> void:
	super.die()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	player_died.emit()
	
# TODO: Refactor this
func _on_hurt_box_entered(area: Area3D) -> void:
	if area.is_in_group("brute"):
		var enemy = area.get_parent()
		var knockback_direction = (global_position - enemy.global_position).normalized()
		var knockback_force = enemy.knockback_force
		knockback_velocity = knockback_direction * knockback_force
		
		take_damage(enemy.damage)
		if not is_stunned:
			is_stunned = true
			stun_duration = 1.5

	elif area.is_in_group("gunner"):
		var enemy = area.get_parent()
		var knockback_direction = (global_position - enemy.global_position).normalized()
		var knockback_force = enemy.knockback_force
		knockback_velocity = knockback_direction * knockback_force

		take_damage(enemy.damage)
		# Gunner melee contact - no stun

	elif area.is_in_group("dynamite_bandit"):
		var enemy = area.get_parent()
		var knockback_direction = (global_position - enemy.global_position).normalized()
		var knockback_force = enemy.knockback_force
		knockback_velocity = knockback_direction * knockback_force

		take_damage(enemy.damage)
		# Trigger suicide explosion
		if enemy.has_method("trigger_suicide_explosion"):
			enemy.trigger_suicide_explosion()

	elif area.is_in_group("bullet"):
		var bullet = area.get_parent()
		var knockback_direction = (global_position - bullet.global_position).normalized()
		var knockback_force = bullet.knockback_force
		knockback_velocity = knockback_direction * knockback_force

		take_damage(bullet.damage)
		# Bullet gets destroyed on hit (handled in bullet script)
		bullet.impact()

func apply_item_effect(item_key):
	match item_key:
		"health_pack":
			heal(max_health - current_health)
		"ammo_refill":
			current_weapon.reload()
		"speed_demon":
			speed *= 1.4
		"trigger_happy":
			fire_rate *= 2.0
		"tank_mode":
			max_health += 25
			current_health += 25
			speed *= .8
			update_health_ui()
		"dash_master":
			dash_cooldown = int(dash_cooldown * 0.5)
		"dynamite_cache":
			for i in range(3):
				throwable_inventory.append(Prefabs.DYNAMITE)
		"gunslinger":
			if revolver:
				revolver.reload_time = 0.1
		

class_name Player
extends Entity

signal player_died

@export var mouse_sensitivity = 0.002
@export var revolver : Weapon
@export var shotgun : Weapon

@onready var camera = $Camera3D
@onready var crosshair = $UICanvas/Crosshair
@onready var health_label: Label = $UICanvas/HUDRoot/HBoxContainer/VBoxContainer/HealthLabel
@onready var ammo_label: Label = $UICanvas/HUDRoot/HBoxContainer/VBoxContainer2/AmmoLabel
@onready var dynamite_label: Label = $UICanvas/HUDRoot/HBoxContainer/VBoxContainer3/DynamiteLabel
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

# UI sway/bob/recoil
var _base_ui_pos = Vector2.ZERO
var _yaw_prev = 0.0
var bob_amt = Vector2(3, 5)
var bob_speed = 5.0
var _bob_t = 0.0
var sway_amt_x = 8.0
var sway_lerp = 12.0
var _sway_x = 0.0
var recoil_kick = Vector2(0, 16)
var recoil_recover = 14.0
var _recoil = Vector2.ZERO

# FOV effects
var base_fov : float = 70.0
var fov_move_add : float = 6.0
var fov_dash_add : float = 10.0
var fov_recover : float = 10.0
var _target_fov : float = 70.0

# Damage camera shake
var shake_time : float = 0.0
var shake_mag : float = 0.0
var shake_decay : float = 5.0
var shake_freq : float = 28.0
var _shake_phase_x : float = 0.0
var _shake_phase_y : float = 0.0

# Pendulum-on-parabola gun path
var pendulum_amp_x : float = 10.0
var pendulum_scale_y : float = 6.0
var pendulum_speed : float = 6.0
var _pend_t : float = 0.0


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

	if camera and "fov" in camera:
		base_fov = camera.fov
		_target_fov = base_fov

	update_health_ui()
	update_ammo_ui()
	update_dynamite_ui()
	GameManager.set_player()
	hurt_box.area_entered.connect(_on_hurt_box_entered)


func _input(event) -> void:
	if is_dead:
		return
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotation.x = 0.0  # hard lock

	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta) -> void:
	if is_dead:
		return

	# Dash start
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
			_target_fov = base_fov + fov_dash_add

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
		_update_visual_effects(delta)
		return

	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0:
			current_weapon.reload()
			is_reloading = false
			update_ammo_ui()

	movement_input = Vector2.ZERO
	# only update input_dir if not dashing
	if Input.is_action_pressed("move_left"):
		movement_input.x -= 1
	if Input.is_action_pressed("move_right"):
		movement_input.x += 1
	if Input.is_action_pressed("move_foward"):
		movement_input.y -= 1
	if Input.is_action_pressed("move_backward"):
		movement_input.y += 1

	if shoot_anim.animation == "shoot" and not shoot_anim.is_playing():
		shoot_anim.play("idle")

	if Input.is_action_pressed("shoot") and not is_reloading:
		if current_weapon.current_ammo == 0:
			start_reload()
			_update_visual_effects(delta)
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
		var throw_dir = (fwd + Vector3.UP * 0.35).normalized()
		var throw_speed = 3.0
		dynamite.linear_velocity = throw_dir * throw_speed
		dynamite.linear_velocity += Vector3(velocity.x, 0.0, velocity.z) * 0.4
		dynamite.global_position = muzzle.global_position + fwd
		dynamite.thrower = self
		dynamite.fuse_duration = 2.0
		dynamite.look_at(dynamite.global_position + throw_dir, Vector3.UP)
		get_tree().current_scene.add_child(dynamite)

	_update_visual_effects(delta)


func _update_visual_effects(delta: float) -> void:
	# --- Motion FOV ---
	var flat_speed = Vector2(velocity.x, velocity.z).length()
	var move_ratio = clamp(flat_speed / max(1.0, speed), 0.0, 1.0)
	var move_target = base_fov + fov_move_add * move_ratio
	_target_fov = max(_target_fov, move_target)
	if camera and "fov" in camera:
		camera.fov = lerp(camera.fov, _target_fov, delta * fov_recover)
		if abs(camera.fov - _target_fov) < 0.05:
			_target_fov = base_fov

	# --- Bob & sway (yaw-based) ---
	_bob_t += delta * (bob_speed * move_ratio)
	var bob_x = sin(_bob_t) * bob_amt.x
	var bob_y = abs(sin(_bob_t * 2.0)) * bob_amt.y

	var yaw_now = rotation.y
	var yaw_delta = wrapf(yaw_now - _yaw_prev, -PI, PI)
	_yaw_prev = yaw_now
	_sway_x = lerp(_sway_x, -yaw_delta * sway_amt_x * 60.0, delta * sway_lerp)

	# --- Recoil recovery ---
	_recoil = _recoil.lerp(Vector2.ZERO, delta * recoil_recover)

	# --- Pendulum-on-parabola path for the gun sprite ---
	_pend_t += delta * pendulum_speed * (0.5 + move_ratio)
	var pend_x = sin(_pend_t) * pendulum_amp_x
	var xn = pend_x / max(1.0, pendulum_amp_x)
	# y is highest (negative = up) at ends, lowest (down) at center:
	# py = -((x^2 - 0.5) * 2) * scale => ends up, middle down
	var pend_y = -((xn * xn - 0.5) * 2.0) * pendulum_scale_y

	# --- Damage camera shake ---
	var cam_off = Vector3.ZERO
	var cam_rot = Vector3.ZERO
	if shake_time > 0.0:
		shake_time -= delta * shake_decay
		shake_time = max(shake_time, 0.0)
		_shake_phase_x += delta * shake_freq
		_shake_phase_y += delta * shake_freq * 1.13
		var sx = sin(_shake_phase_x)
		var sy = cos(_shake_phase_y)
		var k = shake_mag * (shake_time * shake_time)
		cam_off = Vector3(sx, sy, 0.0) * 0.03 * k
		cam_rot = Vector3(0.0, 0.0, sx * 0.015 * k)

	# apply shake to camera (position + slight roll), keep vertical aim locked
	if camera:
		var t = camera.transform
		t.origin += cam_off
		camera.transform = t
		camera.rotation.x = 0.0
		camera.rotation.z = cam_rot.z

	# --- Final gun UI transform ---
	shoot_anim.rotation = 0.0
	shoot_anim.position = _base_ui_pos + Vector2(_sway_x + pend_x + bob_x, 0) + Vector2(0, pend_y + bob_y) + _recoil


func apply_weapon_anim():
	if not current_weapon:
		return
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
	var space_state = get_world_3d().direct_space_state

	if current_weapon.weapon_type == Weapon.Type.SHOTGUN:
		# Shotgun: multiple rays can hit multiple enemies (spread damage)
		var shotgun_cone = deg_to_rad(20.0)
		var ray_count = 15
		var hit_enemies = {}  # Track unique enemies hit
		
		for i in range(ray_count):
			var angle_offset = (float(i) / float(ray_count - 1) - 0.5) * shotgun_cone
			var ray_direction = camera_forward.rotated(Vector3.UP, angle_offset)

			var query = PhysicsRayQueryParameters3D.create(
				camera.global_position,
				camera.global_position + ray_direction * 50.0
			)
			query.exclude = [self]

			var result = space_state.intersect_ray(query)
			if result and result.collider.is_in_group("enemy"):
				# Only hit each enemy once, even if multiple rays hit them
				if not hit_enemies.has(result.collider):
					var distance = camera.global_position.distance_to(result.position)
					result.collider.take_damage(calculate_damage(distance))
					hit_enemies[result.collider] = true
		
		if hit_enemies.size() > 0:
			SFXManager.play_player_sfx(SFXManager.Type.PLAYER_BULLET_HIT)
	else:
		# Pistol: find the single closest enemy across all rays
		var pistol_cone = deg_to_rad(5.6)
		var ray_count = 10
		var closest_enemy = null
		var closest_distance = INF
		
		for i in range(ray_count):
			var angle_offset = (float(i) / float(ray_count - 1) - 0.5) * pistol_cone
			var ray_direction = camera_forward.rotated(Vector3.UP, angle_offset)

			var query = PhysicsRayQueryParameters3D.create(
				camera.global_position,
				camera.global_position + ray_direction * 50.0
			)
			query.exclude = [self]

			var result = space_state.intersect_ray(query)
			if result and result.collider.is_in_group("enemy"):
				var distance = camera.global_position.distance_to(result.position)
				if distance < closest_distance:
					closest_enemy = result.collider
					closest_distance = distance
		
		# Only damage the closest enemy
		if closest_enemy:
			closest_enemy.take_damage(calculate_damage(closest_distance))
			SFXManager.play_player_sfx(SFXManager.Type.PLAYER_BULLET_HIT)

	# recoil
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
	# start a shake proportional to damage
	shake_time = 1.0
	shake_mag = clamp(amount / 40.0, 0.3, 1.2)
	_shake_phase_x = randf() * TAU
	_shake_phase_y = randf() * TAU


func update_dynamite_ui() -> void:
	dynamite_label.text = str(throwable_inventory.size())


func update_ammo_ui() -> void:
	ammo_label.text = str(current_weapon.current_ammo) + "/" + str(current_weapon.ammo_stock)
	if current_weapon.current_ammo == 0:
		ammo_label.modulate = Color.RED
	elif current_weapon.current_ammo <= 1:
		ammo_label.modulate = Color.ORANGE
	else:
		ammo_label.modulate = Color.WHITE


func update_health_ui() -> void:
	health_label.text = str(current_health)


func die() -> void:
	super.die()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	player_died.emit()


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
		var enemy2 = area.get_parent()
		var knockback_direction2 = (global_position - enemy2.global_position).normalized()
		var knockback_force2 = enemy2.knockback_force
		knockback_velocity = knockback_direction2 * knockback_force2
		take_damage(enemy2.damage)

	elif area.is_in_group("dynamite_bandit"):
		var enemy3 = area.get_parent()
		var knockback_direction3 = (global_position - enemy3.global_position).normalized()
		var knockback_force3 = enemy3.knockback_force
		knockback_velocity = knockback_direction3 * knockback_force3
		take_damage(enemy3.damage)
		if enemy3.has_method("trigger_suicide_explosion"):
			enemy3.trigger_suicide_explosion()

	elif area.is_in_group("bullet"):
		var bullet = area.get_parent()
		var knockback_direction4 = (global_position - bullet.global_position).normalized()
		var knockback_force4 = bullet.knockback_force
		knockback_velocity = knockback_direction4 * knockback_force4
		take_damage(bullet.damage)
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
			speed *= 0.8
			update_health_ui()
		"dash_master":
			dash_cooldown = int(dash_cooldown * 0.5)
		"dynamite_cache":
			for i in range(3):
				throwable_inventory.append(Prefabs.DYNAMITE)
		"gunslinger":
			if revolver:
				revolver.reload_time = 0.1

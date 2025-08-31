class_name Player
extends Entity

signal player_died

@export var mouse_sensitivity = 0.002
@export var revolver : Weapon
@export var shotgun : Weapon
@export var pistol_icon : CompressedTexture2D
@export var shotgun_icon : CompressedTexture2D

@onready var camera = $Camera3D
@onready var crosshair = $UICanvas/Crosshair
@onready var health_label: Label = $UICanvas/HUDRoot/HBoxContainer/VBoxContainer/HealthLabel
@onready var ammo_label: Label = $UICanvas/HUDRoot/HBoxContainer/VBoxContainer2/AmmoLabel
@onready var dynamite_label: Label = $UICanvas/HUDRoot/HBoxContainer/VBoxContainer3/DynamiteLabel
@onready var player_money_label: Label = $UICanvas/HUDRoot/HBoxContainer/VBoxContainer4/PlayerMoneyLabel
@onready var hurt_box: Area3D = $HurtBox
@onready var muzzle: Marker3D = $Muzzle
@onready var shoot_anim = $UICanvas/ShootAnim
@onready var grenade_rethrow_label: Label = $UICanvas/GrenadeRethrowLabel
@onready var muzzle_flash: AnimatedSprite2D = $UICanvas/MuzzleFlash
@onready var ammo_texture: TextureRect = $UICanvas/HUDRoot/HBoxContainer/VBoxContainer2/AmmoTexture

var grenade_prompt_timer: float = 0.0

var dash_input_pressed : bool = false
var movement_input : Vector2 = Vector2.ZERO
var money : float = 0.0
var fire_rate : float = 2.0
var shoot_cone_threshold : float = deg_to_rad(5.6)
var shoot_timer : float = 0.0
var current_weapon : Weapon
var is_reloading : bool = false
var reload_timer : float = 0.0
var overlapping_dynamite_areas: Array = []
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
var fov_stun_reduce : float = 15.0 

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

# Hacky work around
var _prev_player_money: float = -1.0

func _ready() -> void:
	super._ready()
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	revolver = Weapon.create_revolver()
	shotgun = Weapon.create_shotgun()
	current_weapon = revolver
	GameManager.unpause_game()

	apply_weapon_anim()
	_base_ui_pos = shoot_anim.position
	_yaw_prev = rotation.y

	if camera and "fov" in camera:
		base_fov = camera.fov
		_target_fov = base_fov

	update_health_ui()
	update_ammo_ui()
	update_dynamite_ui()
	update_money_ui()
	GameManager.set_player()
	hurt_box.area_entered.connect(_on_hurt_box_entered)


func _input(event) -> void:
	if is_dead:
		return
	
	# Always try to capture mouse if it's not captured (unless dead)
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
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
	if grenade_prompt_timer > 0.0:
		grenade_prompt_timer -= delta
		if grenade_prompt_timer <= 0.0:
			grenade_rethrow_label.visible = false
			
	if player_money_label:
		player_money_label.text = "$" + str(int(money))
		if _prev_player_money != -1.0:
			if money > _prev_player_money:
				# Flash green for increase
				player_money_label.modulate = Color(0, 1, 0)
				var tween = create_tween()
				tween.tween_property(player_money_label, "modulate", Color(1, 1, 1), 0.4)
			elif money < _prev_player_money:
				# Flash red for decrease
				player_money_label.modulate = Color(1, 0, 0)
				var tween = create_tween()
				tween.tween_property(player_money_label, "modulate", Color(1, 1, 1), 0.4)
		_prev_player_money = money
	update_health_ui()
	update_ammo_ui()
	update_dynamite_ui()
	update_money_ui()
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
			if current_weapon.ammo_stock > 0:
				start_reload()
			else:
				SFXManager.play_player_sfx(SFXManager.Type.NO_AMMO)
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

	if Input.is_action_just_pressed("interact") and overlapping_dynamite_areas.size() > 0:
		var closest_dynamite = overlapping_dynamite_areas[0]
		if closest_dynamite and is_instance_valid(closest_dynamite):
			closest_dynamite.throw_dynamite(self)
			overlapping_dynamite_areas.erase(closest_dynamite)

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
	if is_stunned:
		# Worst FOV when stunned - tunnel vision
		_target_fov = base_fov - fov_stun_reduce
	elif dash_speed > 0:
		# Best FOV when dashing
		_target_fov = base_fov + fov_dash_add
	elif movement_input.length() > 0:
		# Medium FOV when moving
		_target_fov = base_fov + fov_move_add
	else:
		# Base FOV when standing still
		_target_fov = base_fov

	if camera and "fov" in camera:
		camera.fov = lerp(camera.fov, _target_fov, delta * fov_recover)
	var flat_speed = Vector2(velocity.x, velocity.z).length()
	var move_ratio = clamp(flat_speed / max(1.0, speed), 0.0, 1.0)

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

	_pend_t += delta * pendulum_speed * (0.5 + move_ratio)
	var pend_x = sin(_pend_t) * pendulum_amp_x
	var xn = pend_x / max(1.0, pendulum_amp_x)

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
		if current_weapon.ammo_stock > 0:
			SFXManager.play_player_sfx(SFXManager.Type.PLAYER_RELOAD)
			is_reloading = true
			reload_timer = current_weapon.reload_time
		else:
			SFXManager.play_player_sfx(SFXManager.Type.NO_AMMO)

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
			if result:
				# Bullet decal for any hit
				if Prefabs.BULLET_DECAL:
					var decal = Prefabs.BULLET_DECAL.instantiate()
					decal.global_position = result.position
					decal.look_at(result.position + result.normal, Vector3.UP)
					
					# Color the decal based on what was hit
					var decal_color = Color(0.1, 0.1, 0.1)  # Black for surfaces
					if result.collider.is_in_group("enemy"):
						decal_color = Color(0.8, 0.1, 0.1)  # Red for enemies
					
					if decal.has_method("set_modulate"):
						decal.set_modulate(decal_color)
					elif "modulate" in decal:
						decal.modulate = decal_color
					get_tree().current_scene.add_child(decal)
				
				if result.collider.is_in_group("enemy"):
					if not hit_enemies.has(result.collider):
						var distance = camera.global_position.distance_to(result.position)
						var enemy = result.collider
						var hit_pos = result.position
						var hit_normal = result.normal
						
						var knockback_dir = (enemy.global_position - camera.global_position).normalized()
						knockback_dir.y = 0  
						enemy.knockback_velocity = knockback_dir * 2.0  
						
						var travel_time = distance * 0.002  
						get_tree().create_timer(travel_time).timeout.connect(func():
							enemy.take_damage(calculate_damage(distance))
							if Prefabs.BULLET_DECAL:
								var decal = Prefabs.BULLET_DECAL.instantiate()
								decal.global_position = hit_pos
								decal.look_at(hit_pos + hit_normal, Vector3.UP)
								decal.modulate = Color(0.8, 0.1, 0.1)
								get_tree().current_scene.add_child(decal)
						)
						hit_enemies[enemy] = true
		
		if hit_enemies.size() > 0:
			SFXManager.play_player_sfx(SFXManager.Type.PLAYER_BULLET_HIT)
	else:
		var pistol_cone = deg_to_rad(5.6)
		var ray_count = 10
		var closest_enemy = null
		var closest_distance = INF
		var closest_hit_pos = null
		var closest_hit_normal = null
		
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
					closest_hit_pos = result.position
					closest_hit_normal = result.normal
		
		if closest_enemy:
			var knockback_dir = (closest_enemy.global_position - camera.global_position).normalized()
			knockback_dir.y = 0  
			closest_enemy.knockback_velocity = knockback_dir * 2.0  
			var travel_time = closest_distance * 0.002  
			get_tree().create_timer(travel_time).timeout.connect(func():
				closest_enemy.take_damage(calculate_damage(closest_distance))
				SFXManager.play_player_sfx(SFXManager.Type.PLAYER_BULLET_HIT)
				
				if Prefabs.BULLET_DECAL and closest_hit_pos and closest_hit_normal:
					var decal = Prefabs.BULLET_DECAL.instantiate()
					decal.global_position = closest_hit_pos
					decal.look_at(closest_hit_pos + closest_hit_normal, Vector3.UP)
					decal.modulate = Color(0.8, 0.1, 0.1)
					get_tree().current_scene.add_child(decal)
			)

	if muzzle_flash:
		muzzle_flash.visible = true
		
		if current_weapon.weapon_type == Weapon.Type.SHOTGUN:
			muzzle_flash.scale = Vector2(8, 8)
			muzzle_flash.play("shotgun") 
		else:  
			muzzle_flash.scale = Vector2(6, 6)
			muzzle_flash.play("revolver")  
		
		get_tree().create_timer(0.1).timeout.connect(func(): muzzle_flash.visible = false)

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

	# Create red flash effect
	var flash_overlay = ColorRect.new()
	flash_overlay.color = Color(1, 0, 0, 0.3)
	flash_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$UICanvas.add_child(flash_overlay)
	var tween = create_tween()
	tween.tween_property(flash_overlay, "modulate:a", 0.0, 0.3)
	tween.tween_callback(flash_overlay.queue_free)


func update_dynamite_ui() -> void:
	dynamite_label.text = str(throwable_inventory.size())


func update_ammo_ui() -> void:
	ammo_label.text = str(current_weapon.current_ammo) + " | " + str(current_weapon.ammo_stock)
	
	# Update weapon icon based on current weapon
	if current_weapon.weapon_type == Weapon.Type.REVOLVER:
		ammo_texture.texture = pistol_icon
	elif current_weapon.weapon_type == Weapon.Type.SHOTGUN:
		ammo_texture.texture = shotgun_icon
	
	if current_weapon.current_ammo == 0:
		ammo_label.modulate = Color.RED
	elif current_weapon.current_ammo <= 1:
		ammo_label.modulate = Color.ORANGE
	else:
		ammo_label.modulate = Color.WHITE


func update_health_ui() -> void:
	health_label.text = str(current_health)

func update_money_ui() -> void:	if player_money_label:
	player_money_label.text = "$" + str(int(money))
	if _prev_player_money != -1.0:
		if money > _prev_player_money:
			# Flash green for increase
			player_money_label.modulate = Color(0, 1, 0)
			var tween = create_tween()
			tween.tween_property(player_money_label, "modulate", Color(1, 1, 1), 0.4)
		elif money < _prev_player_money:
			# Flash red for decrease
			player_money_label.modulate = Color(1, 0, 0)
			var tween = create_tween()
			tween.tween_property(player_money_label, "modulate", Color(1, 1, 1), 0.4)
	_prev_player_money = money

func die() -> void:
	super.die()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	player_died.emit()
	# Reset game state before reloading
	GameManager.reset_game()
	get_tree().reload_current_scene()


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
			# Create yellow stun flash effect
			var stun_overlay = ColorRect.new()
			stun_overlay.color = Color(1, 1, 0, 0.4)  # Yellow flash
			stun_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			$UICanvas.add_child(stun_overlay)
			var stun_tween = create_tween()
			stun_tween.tween_property(stun_overlay, "modulate:a", 0.0, 0.5)
			stun_tween.tween_callback(stun_overlay.queue_free)

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
			heal(20)
		"ammo_refill":
			current_weapon.ammo_stock += 10
		"speed_demon":
			speed = speed * 1.1
		"trigger_happy":
			fire_rate = fire_rate * 1.2
		"tank_mode":
			max_health += 5
			current_health += 5
			speed *= 0.95
			update_health_ui()
		"dash_master":
			dash_cooldown = int(dash_cooldown * 0.5)
		"dynamite_cache":
			for i in range(3):
				throwable_inventory.append(Prefabs.DYNAMITE)
		"gunslinger":
			current_weapon.reload_time /= 2
		"deposit":
			GameManager.bank.deposit_money(100)
			update_money_ui()

func pickup_flash() -> void:
	# create green pickup flash effect
	var pickup_overlay = ColorRect.new()
	pickup_overlay.color = Color(0, 1, 0, 0.3)  # Green flash
	pickup_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$UICanvas.add_child(pickup_overlay)
	var pickup_tween = create_tween()
	pickup_tween.tween_property(pickup_overlay, "modulate:a", 0.0, 0.4)
	pickup_tween.tween_callback(pickup_overlay.queue_free)
	
func show_grenade_prompt(show: bool, grenade_position: Vector3 = Vector3.ZERO) -> void:
	if show:
		grenade_rethrow_label.visible = true
		grenade_prompt_timer = 1.0

class_name Dynamite
extends RigidBody3D

@onready var explosion_area : Area3D = $ExplosionArea
@onready var pickup_area: Area3D = $PickupArea
@onready var fuse_audio : AudioStreamPlayer3D = $FuseAudio
@onready var explosion: AnimatedSprite3D = $Explosion

@export var damage : float = 25.0
var fuse_duration : float = 2.5
var fuse_timer : float = 0.0
var has_exploded : bool = false
var is_fuse_lit : bool = false
var knockback_force : float = 20.0
var thrower : Node = null
var target_group := ""
var kill_thrower_on_explode : bool = false


func _ready() -> void:
	add_to_group("dynamite")
	is_fuse_lit = true
	fuse_audio.play()

	SFXManager.play_spatial_sfx(SFXManager.Type.FUSE, global_position)
		
	set_collision_stuff()
	explosion.visible = false

func set_collision_stuff() -> void:
	if thrower.is_in_group("player"):
		target_group = "enemy"
		explosion_area.collision_mask = 32
	elif thrower.is_in_group("enemy"):
		target_group = "player"
		explosion_area.collision_mask = 8

func _process(delta: float) -> void:
	if has_exploded: return
	if is_fuse_lit:
		fuse_timer += delta
		if fuse_timer >= fuse_duration:
			#print_debug("Exploding")
			explode()
		
func explode() -> void:
	if has_exploded: return
	has_exploded = true
	fuse_audio.stop()
	SFXManager.play_spatial_sfx(SFXManager.Type.EXPLOSION, global_position)
	for area in explosion_area.get_overlapping_areas():
		var e := area.get_parent()
		if e == thrower: 
			continue
		if e.is_in_group(target_group):
			e.take_damage(damage)
			var dir = (e.global_position - global_position).normalized()
			e.knockback_velocity = dir * knockback_force

	if kill_thrower_on_explode:
		thrower.die()
		
	explosion.visible = true
	explosion.play("explosion")
	explosion.animation_finished.connect(queue_free)


func _on_pickup_area_area_entered(area: Area3D) -> void:
	var player = area.get_parent()
	if player.is_in_group("player") and thrower != player and not has_exploded:
		player.show_grenade_prompt(true, global_position)
		player.overlapping_dynamite_areas.append(self)


func _on_pickup_area_area_exited(area: Area3D) -> void:
	var player = area.get_parent()
	if player.is_in_group("player") and thrower != player and not has_exploded:
		player.show_grenade_prompt(false)
		player.overlapping_dynamite_areas.erase(self)

func throw_dynamite(player: Node) -> void:
	if has_exploded:
		return
	thrower = player
	set_collision_stuff()
	if player.has_node("Muzzle"):
		global_position = player.get_node("Muzzle").global_position
	linear_velocity = Vector3.ZERO
	var camera = player.get_node("Camera3D") if player.has_node("Camera3D") else null
	var fwd = -camera.global_transform.basis.z if camera else -global_transform.basis.z
	fwd.y = 0
	fwd = fwd.normalized()
	var throw_speed = 8.0  
	var upward_velocity = 6.0
	linear_velocity = fwd * throw_speed
	linear_velocity.y = upward_velocity
	linear_velocity += Vector3(player.velocity.x, 0.0, player.velocity.z) * 0.4
	look_at(global_position + fwd, Vector3.UP)
	SFXManager.play_player_sfx(SFXManager.Type.PLAYER_PICKUP)
	player.show_grenade_prompt(false)

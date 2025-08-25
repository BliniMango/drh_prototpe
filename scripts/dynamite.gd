class_name Dynamite
extends RigidBody3D

@onready var explosion_area: Area3D = $ExplosionArea

var damage : float = 20.0
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
	
	queue_free()

class_name Weapon
extends Node

@export var weapon_type: Type
@export var max_ammo : int
@export var damage_close : float
@export var damage_far : float
@export var close_range : float
@export var fire_rate : float
@export var reload_time : float

var current_ammo : int

enum Type {
	REVOLVER,
	SHOTGUN,
}

static func create_revolver() -> Weapon:
	var weapon = Weapon.new()
	weapon.weapon_type = Type.REVOLVER
	weapon.max_ammo = 6
	weapon.current_ammo = 6
	weapon.damage_close = 50.0
	weapon.damage_far = 50.0
	weapon.close_range = 999.0
	weapon.fire_rate = 2.0
	weapon.reload_time = 2.0
	return weapon

static func create_shotgun() -> Weapon:
	var weapon = Weapon.new()
	weapon.weapon_type = Type.SHOTGUN
	weapon.max_ammo = 2
	weapon.current_ammo = 2
	weapon.damage_close = 100.0
	weapon.damage_far = 50.0
	weapon.close_range = 50.0
	weapon.fire_rate = 1.0
	weapon.reload_time = 3.0
	return weapon


func _init():
	current_ammo = max_ammo

func can_shoot() -> bool:
	return current_ammo > 0

func shoot() -> void:
	match weapon_type:
		Weapon.Type.REVOLVER:
			SFXManager.play_player_sfx(SFXManager.Type.PLAYER_REVOLVER_SHOOT)
		Weapon.Type.SHOTGUN:
			SFXManager.play_player_sfx(SFXManager.Type.PLAYER_SHOTGUN_SHOOT)
	if can_shoot():
		current_ammo -= 1

func reload() -> void:
	current_ammo = max_ammo

func is_empty() -> bool:
	return current_ammo <= 0